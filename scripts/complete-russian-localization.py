#!/usr/bin/env python3
"""Build the complete Russian locale from a cached draft and reviewed overrides.

Existing hand-written translations are always preserved.  The generated locale is
static Lua, so the game never needs network access at runtime.  A cache under
build/ keeps repeated runs deterministic and avoids retranslating unchanged text.
Context-sensitive corrections live in ru_editorial_overrides.py.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request

from ru_editorial_overrides import OVERRIDES


PROJECT_ROOT = Path(__file__).resolve().parent.parent
CACHE_PATH = PROJECT_ROOT / "build" / "ru-translation-cache.json"
OUTPUT_PATH = PROJECT_ROOT / "src" / "locales" / "ru.lua"
TRANSLATE_URL = "https://translate.googleapis.com/translate_a/single"
BATCH_LIMIT = 12_000
STATIC_COPY_PATHS = {'["achi","gui",2]'}

TOKEN_PATTERN = re.compile(
    r"\{#[0-9a-fA-F]+\}|_\d+_|%%|#[A-Za-z][A-Za-z0-9_]*|"
    r"_[A-Za-z][A-Za-z0-9_]*_|<[^>\n]+>|%[-+#0]*\d*\.?\d*[cdeEfgGiouxXqs]"
)
EDGE_SPACE_PATTERN = re.compile(r"^(\s*)(.*?)(\s*)$", re.DOTALL)


def flatten_locale(module: str) -> list[dict[str, object]]:
    lua_program = r'''
local json = require("src.json")
local root = require(assert(os.getenv("SARCOPHAGUS_LOCALE_MODULE")))
local output = {}

local function key_less(left, right)
    if type(left) == type(right) then
        return left < right
    end
    return type(left) == "number"
end

local function walk(value, path)
    if type(value) == "string" then
        output[#output + 1] = { path = path, value = value }
        return
    end
    if type(value) ~= "table" then
        return
    end

    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = key
    end
    table.sort(keys, key_less)

    for _, key in ipairs(keys) do
        local child_path = {}
        for index, component in ipairs(path) do
            child_path[index] = component
        end
        child_path[#child_path + 1] = key
        walk(value[key], child_path)
    end
end

walk(root, {})
io.write(json.encode(output))
'''
    environment = os.environ.copy()
    environment["SARCOPHAGUS_LOCALE_MODULE"] = module
    result = subprocess.run(
        ["lua", "-e", lua_program],
        cwd=PROJECT_ROOT,
        env=environment,
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def path_id(path: list[object]) -> str:
    return json.dumps(path, ensure_ascii=False, separators=(",", ":"))


def protect(value: str) -> tuple[str, list[str]]:
    protected: list[str] = []

    def replace(match: re.Match[str]) -> str:
        protected.append(match.group(0))
        return f"ZXPH{len(protected) - 1:04d}QXZ"

    return TOKEN_PATTERN.sub(replace, value), protected


def restore(value: str, protected: list[str]) -> str:
    for index, token in enumerate(protected):
        placeholder = f"ZXPH{index:04d}QXZ"
        value = value.replace(placeholder, token)
        value = value.replace(placeholder.lower(), token)
    if re.search(r"ZXPH\d{4}QXZ", value, re.IGNORECASE):
        raise RuntimeError(f"translation service altered a protected token: {value!r}")
    return value


def request_translation(value: str) -> str:
    payload = urllib.parse.urlencode(
        {
            "client": "gtx",
            "sl": "en",
            "tl": "ru",
            "dt": "t",
            "q": value,
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        TRANSLATE_URL,
        data=payload,
        headers={"User-Agent": "Sarcophagus-localization/1.0"},
    )

    for attempt in range(5):
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                document = json.loads(response.read().decode("utf-8"))
            return "".join(fragment[0] for fragment in document[0] if fragment[0])
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
            if attempt == 4:
                raise
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError("translation request exhausted retries")


def translate_batch(entries: list[dict[str, object]]) -> dict[str, str]:
    prepared: list[tuple[str, str, list[str] | None, str, str]] = []
    for entry in entries:
        identifier = path_id(entry["path"])
        source = str(entry["value"])
        edge_match = EDGE_SPACE_PATTERN.match(source)
        assert edge_match
        leading, core, trailing = edge_match.groups()

        translatable_text = TOKEN_PATTERN.sub("", core)
        if (
            not core
            or identifier in STATIC_COPY_PATHS
            or not re.search(r"[A-Za-z]{2,}", translatable_text)
        ):
            prepared.append((identifier, core, None, leading, trailing))
            continue

        masked, tokens = protect(core)
        prepared.append((identifier, masked, tokens, leading, trailing))

    result: dict[str, str] = {}
    pending = [entry for entry in prepared if entry[1] and entry[2] is not None]
    cursor = 0
    while cursor < len(pending):
        batch: list[tuple[str, str, list[str] | None, str, str]] = []
        batch_size = 0
        while cursor < len(pending):
            candidate = pending[cursor]
            projected = batch_size + len(candidate[1].encode("utf-8")) + 40
            if batch and projected > BATCH_LIMIT:
                break
            batch.append(candidate)
            batch_size = projected
            cursor += 1

        separators = [f"ZXQSEP{index:04d}QXZ" for index in range(len(batch) - 1)]
        combined_parts: list[str] = []
        for index, entry in enumerate(batch):
            combined_parts.append(entry[1])
            if index < len(separators):
                combined_parts.append("\n" + separators[index] + "\n")

        translated = request_translation("".join(combined_parts))
        pieces = [translated]
        for separator in separators:
            next_pieces: list[str] = []
            for piece in pieces:
                next_pieces.extend(piece.split(separator))
            pieces = next_pieces

        if len(pieces) != len(batch):
            # A service may alter a separator in an unusually large batch.  Retry
            # individual strings so a malformed response can never enter the game.
            pieces = [request_translation(entry[1]) for entry in batch]

        for entry, translated_piece in zip(batch, pieces):
            identifier, _masked, tokens, leading, trailing = entry
            assert tokens is not None
            translated_piece = translated_piece.strip()
            result[identifier] = leading + restore(translated_piece, tokens) + trailing

    for identifier, core, tokens, leading, trailing in prepared:
        if identifier not in result:
            result[identifier] = leading + core + trailing
    return result


def lua_key(component: object) -> str:
    if isinstance(component, int):
        return f"[{component}]"
    return "[" + json.dumps(str(component), ensure_ascii=False) + "]"


def lua_path(path: list[object]) -> str:
    return "msg" + "".join(lua_key(component) for component in path)


def render_locale(entries: list[dict[str, object]], translations: dict[str, str]) -> str:
    parent_paths: set[str] = set()
    parents: list[list[object]] = []
    for entry in entries:
        path = entry["path"]
        assert isinstance(path, list)
        for depth in range(1, len(path)):
            parent = path[:depth]
            identifier = path_id(parent)
            if identifier not in parent_paths:
                parent_paths.add(identifier)
                parents.append(parent)

    lines = [
        "-- Complete Russian overlay for src/locales/en.lua.",
        "-- Machine-assisted draft with reviewed corrections from scripts/ru_editorial_overrides.py.",
        "local msg = {}",
        "",
    ]
    for parent in parents:
        lines.append(f"{lua_path(parent)} = {{}}")
    lines.append("")

    for entry in entries:
        path = entry["path"]
        assert isinstance(path, list)
        identifier = path_id(path)
        value = translations[identifier]
        encoded = json.dumps(value, ensure_ascii=False)
        lines.append(f"{lua_path(path)} = {encoded}")

    lines.extend(["", "return msg", ""])
    return "\n".join(lines)


def main() -> None:
    english = flatten_locale("src.locales.en")
    russian = flatten_locale("src.locales.ru")
    existing = {path_id(entry["path"]): str(entry["value"]) for entry in russian}

    cache: dict[str, str] = {}
    if CACHE_PATH.exists():
        cache = json.loads(CACHE_PATH.read_text(encoding="utf-8"))

    missing = [
        entry
        for entry in english
        if path_id(entry["path"]) not in existing
        and path_id(entry["path"]) not in cache
    ]
    print(
        f"English strings: {len(english)}; existing Russian: {len(existing)}; "
        f"to translate: {len(missing)}"
    )

    if missing:
        cache.update(translate_batch(missing))
        CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
        CACHE_PATH.write_text(
            json.dumps(cache, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    translations = dict(cache)
    translations.update(existing)
    known_paths = {path_id(entry["path"]) for entry in english}
    editorial = {path_id(list(path)): value for path, value in OVERRIDES.items()}
    unknown_editorial_paths = sorted(set(editorial) - known_paths)
    if unknown_editorial_paths:
        raise RuntimeError(
            "editorial overrides refer to missing English paths: "
            + ", ".join(unknown_editorial_paths)
        )
    translations.update(editorial)
    absent = [entry for entry in english if path_id(entry["path"]) not in translations]
    if absent:
        raise RuntimeError(f"missing {len(absent)} translated strings")

    OUTPUT_PATH.write_text(render_locale(english, translations), encoding="utf-8")
    print(f"Wrote {OUTPUT_PATH} with {len(english)} translated strings")


if __name__ == "__main__":
    main()
