<div align="center">
  <img src="docs/assets/sarcophagus-logo.png" alt="Sarcophagus" width="380">

  **A demanding pixel-art sandbox survival game built with Lua and LÖVE**

  [Official page](https://acerbial.itch.io/sarcophagus) ·
  [Download the original release](https://acerbial.itch.io/sarcophagus) ·
  [Modernization plan](plan.md)
</div>

[English](#english) · [Русский](#русский)

---

# English

## About the game

Sarcophagus is a one-person sandbox/survival project by Dmitry Smirnov (`acerbial`). It draws on the story of Sisyphus and the idea that sustained work can transform both a place and its inhabitant.

You begin in a sparse, allegorical cave and gradually turn it into a living garden. Survival depends on digging, building, farming and maintaining the cave ecosystem. The world may initially look empty, but the player can populate and reshape it.

This is not a god game: food must be grown, inventory space is limited, and priorities constantly compete for attention. The design is intentionally demanding and old-school, rewarding experimentation, observation and learning.

The name comes from Greek roots associated with flesh and eating.

## Gameplay

The game combines:

- procedural cave generation;
- exploration and platforming;
- survival systems such as food, water, temperature, health and cleanliness;
- mining, construction and falling blocks;
- farming and ecosystem management;
- crafting, tools and equipment;
- creatures, combat and projectiles;
- water, fire, light and environmental simulation;
- fishing, disasters, quests and achievements;
- item analysis and transformation through **The Machine**.

The current source contains 368 items, 195 block types, 18 creature types, approximately 262 crafting recipes and 41 achievements.

## First steps

- Find Ice Shards.
- Inspect everything: knowledge is one of the main progression systems.
- Watch for the `≈` symbol. It marks objects that may provide information or transformations when brought to The Machine.
- The Machine is your friend.

There is deliberately no complete in-game wiki. Discovery is part of the game.

## Controls

These are the default keyboard and mouse bindings. The contextual panels in
the game show which actions are currently available; most gameplay actions can
also be rebound from the start screen.

### Start screen

| Input | Action |
|---|---|
| `W`, `S` / `↑`, `↓` | Select a save slot |
| `Enter` | Load the selected save or start a new game |
| `Backspace` + `Shift` | Delete the selected save |
| `L` | Start a new game with **Legacy**, when available |
| `F2` | Switch language |
| `C` | Configure keyboard or gamepad bindings |
| `H` / `O` | Open the game homepage / Discord channel |
| `Q` | **Switch worlds** (the current implementation closes the game) |

### Gameplay and inventory

| Input | Action |
|---|---|
| `W`, `A`, `S`, `D` / arrow keys | Move and jump |
| `Shift` | Run / speed up |
| `Space` | Dig, pick up or place a carried block; hold up/down to direct digging |
| `E` / left mouse button | Attack or examine a block |
| `O` | Examine the block shown in the contextual panel |
| `V` | Use the block at the player position or drink water |
| `R` / right mouse button | Throw or empty an item |
| `1`–`9` | Select an inventory item |
| Mouse wheel, `[` / `]`, `-` / `=` (`+`) | Cycle inventory slots; over the journal, scroll its text |
| `0` | Cycle between the inventory and equipped items |
| `Q` / mouse button 5 | Pick up the first ground item |
| `Shift` + `1`–`9` | Pick up a specific ground item |
| `Tab` / middle mouse button | Cycle ground items |
| `M` | Sort the items on the ground at the player position |
| `Z` / mouse button 4 | Put down the selected item or prepare a placeable block |
| `P` | Equip or unequip the selected item |
| `Enter` / `U` | Use or consume the selected item |
| `I` | Inspect the selected item and, for food, show dietary information |
| `C` | Open or close crafting for the selected item |
| `Shift` + `C` | Open crafting with all items available at the current location |
| `Ctrl` | Toggle highlighting of ground items similar to the selected item |
| Right `Alt` | Toggle highlighting of all ground items |
| Left `Alt` (hold) | Show plant problems |
| `/` | Hide or show the journal |
| `Esc` | Close the current contextual screen or open the pause/options menu |

### Information and contextual screens

| Input | Action |
|---|---|
| `F1` | Show quest |
| `F2` | Show diet |
| `F3` | Self-harm |
| `F4` | Show keys |
| `F5` | Screenshot |
| `F7` | Pray |
| `F8` / `N` | Achievements |
| `A`, `D` / `←`, `→` | Change the achievement category |
| `W`, `S` / `↑`, `↓`, then `Enter` | Select and make a recipe in the crafting screen |
| `W`, `S` / `↑`, `↓` | Navigate the pause menu |
| `A`, `D` / `←`, `→`, `Enter` or `Space` | Adjust or activate the selected pause-menu option |
| Numeric keypad `8`, `2`, `4`, `6` | Move the virtual cursor when playing without a mouse |
| `Backspace` / `Esc` in key setup | Skip the current binding / cancel setup |

Keyboard, mouse and gamepads are supported by the original game.

## Releases

The original version `0.10.591` is available for Windows, macOS and Linux from the [official itch.io page](https://acerbial.itch.io/sarcophagus). The itch.io page describes the original project as in development.

The current modernized version in this repository is `0.11.0`.

### Original development log

The [official devlog](https://acerbial.itch.io/sarcophagus/devlog) documents several milestones from 2019:

- **30 November 2019 — version 0.10.53:** chickens, eggs, manure and related recipes were added.
- **15 November 2019 — Butler bot:** the Butler bot became an achievement reward.
- **12 November 2019 — version 0.10.40:** the first published achievement system contained 27 achievements. Early achievements helped introduce new players to the game, while some achievements also provided rewards and acted as an additional quest system.

The imported `0.10.591` source contains 41 achievement definitions, so it includes work completed after those devlog entries.

This repository is a source snapshot currently being modernized. The work includes:

- compatibility with LÖVE 11.5;
- reproducible Windows, macOS and Linux builds;
- a complete English/Russian localization system;
- backward-compatible save loading;
- automated smoke tests and release checks.

See [plan.md](plan.md) for the detailed roadmap.

## Running from source

Requirements:

- [LÖVE 11.5](https://love2d.org/);
- a desktop system with graphics and audio support.

Run the project directory with LÖVE:

```sh
love /absolute/path/to/Sarcophagus
```

During modernization, the verified target runtime is LÖVE 11.5 with its bundled LuaJIT. A separate Lua installation is not required.

## Language

English and Russian are complete locales with matching key coverage. English remains the safe fallback if a future Russian entry is temporarily missing; the locale validator now rejects incomplete committed translations.

- Press `F2` on the start screen to switch languages.
- Choose **Language** in the in-game `Esc` menu to switch while playing.
- The choice is stored in `settings.json`, separately from the nine save slots.
- On first launch, the game uses a supported operating-system language and otherwise falls back to English.

For a deterministic development launch, set `SARCOPHAGUS_LANGUAGE=en` or `SARCOPHAGUS_LANGUAGE=ru`.

Run the automated compatibility checks:

```sh
./scripts/test.sh
```

The suite also performs an actual windowed → fullscreen → windowed transition,
checks double-size rendering, and exercises the complete ten-minute autosave
path (queue, fade deferral, backup, reload, disable option, and failed-save retry).

Validate the localization overlay separately:

```sh
./scripts/check-locales.sh
./scripts/check-ui-strings.sh
```

After adding English strings, rebuild the complete static Russian locale with `./scripts/complete-russian-localization.py`. Context-sensitive, human-reviewed wording is kept in `scripts/ru_editorial_overrides.py`; the game itself never contacts a translation service.

Build a release-mode `.love` archive with a pre-generated sprite atlas:

```sh
./scripts/build-love.sh
```

The resulting file is written to `dist/Sarcophagus.love`. Both scripts use the isolated runtime under `.tools/` by default; set `LOVE_BIN` to use another LÖVE 11.5 executable.

The release builder serializes atlas metadata with sorted keys, normalizes file times through `SOURCE_DATE_EPOCH`, fixes ZIP entry order and strips host-specific ZIP extras. Repeated builds from the same source therefore produce the same `.love` SHA-256; the Linux workflow verifies this by building twice and comparing the archives byte for byte.

The release audit also enforces a 12 MiB `.love` size budget so accidental large
assets cannot enter every platform package unnoticed. Set
`MAX_LOVE_ARCHIVE_BYTES` only when deliberately raising that limit.

### Native packages

Build the universal Intel/Apple Silicon macOS app on macOS:

```sh
./scripts/build-macos.sh
```

The macOS command rebuilds `dist/Sarcophagus.love` first, so an older archive cannot silently enter a new app. Set `LOVE_ARCHIVE=/path/to/game.love` only when packaging an explicitly supplied, already audited archive. The final ZIP preserves executable modes and symlinks but excludes AppleDouble metadata (`__MACOSX/._*`); the extracted app and its code signature are verified again.

The builder removes development-only framework headers from the app. For a
smaller package intended for one CPU architecture, build either variant
explicitly (the universal package remains the default):

```sh
MACOS_ARCH=arm64 ./scripts/build-macos.sh
MACOS_ARCH=x86_64 ./scripts/build-macos.sh
```

Without credentials this creates an ad-hoc-signed package for local testing. A public download that opens normally under Gatekeeper must be signed with a **Developer ID Application** certificate and notarized by Apple:

```sh
MACOS_SIGNING_IDENTITY='Developer ID Application: Name (TEAMID)' \
MACOS_NOTARY_PROFILE='sarcophagus-notary' \
./scripts/build-macos.sh
```

`MACOS_NOTARY_PROFILE` is a Keychain profile previously created with `xcrun notarytool store-credentials`. The script signs the bundled frameworks and app with the hardened runtime, submits the ZIP through `notarytool`, staples the ticket and verifies it. This is what removes the old “unidentified developer” / “app is damaged” workaround; an unsigned or ad-hoc-signed Internet download cannot legitimately promise the same result. See [Apple's notarization guide](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

After `dist/Sarcophagus.love` has been built, create the Windows x64 package on Windows:

```powershell
powershell.exe -NoProfile -File scripts\build-windows.ps1
```

The script downloads the pinned official LÖVE 11.5 runtime, embeds a system-DPI-aware manifest before fusing the game, verifies both the manifest and embedded `.love`, includes the required DLLs and LÖVE license, and creates a ZIP under `dist/`. Users of that package should not need the old Compatibility → High DPI override or `run.bat`.

After `dist/Sarcophagus.love` has been built, create the Linux x86_64 AppImage on an x86_64 Linux host:

```sh
./scripts/build-linux-appimage.sh
```

The script downloads the official LÖVE 11.5 AppImage and pinned AppImage tooling, rejects every binary whose SHA-256 differs from the recorded value, fuses the game into the native runner, installs the project desktop entry and icon, then extracts the result again to verify its contents and embedded `.love`. The output is `dist/Sarcophagus-linux-x86_64-0.11.0.AppImage`.

Make a downloaded build executable and launch it directly:

```sh
chmod +x Sarcophagus-linux-x86_64-0.11.0.AppImage
./Sarcophagus-linux-x86_64-0.11.0.AppImage
```

The `Linux AppImage` GitHub Actions workflow runs the complete test suite with the same pinned LÖVE runtime, builds the `.love`, creates the AppImage and publishes it together with a SHA-256 file as a workflow artifact. The packaging procedure follows the [official LÖVE distribution guidance](https://love2d.org/wiki/Game_Distribution) and the [AppImage AppDir specification](https://docs.appimage.org/reference/appdir.html).

All native packages use the same pixel-art source icon at `packaging/icon.png`. The committed macOS Retina `.icns` and multi-size Windows `.ico` can be regenerated on macOS with ImageMagick and `iconutil`:

```sh
./scripts/generate-platform-icons.sh
```

Normal package builds use the committed derived icons and do not require those icon-generation tools.

## Project layout

| Path | Purpose |
|---|---|
| `main.lua` | Entry point and module loading |
| `src/` | Game runtime and Lua modules |
| `src/mapgen.lua` | Procedural world generation |
| `src/items.lua` | Item definitions and behaviour |
| `src/stones.lua` | Blocks, plants and structures |
| `src/locales/` | English locale and active Russian overlay |
| `assets/maps/` | Map chunks used by world generation |
| `assets/sounds/` | Runtime sound assets |
| `assets/sprites/` | Development sprite sources; replaced by the atlas in releases |
| `archive/` | Legacy code and assets excluded from releases |
| `packaging/` | Shared icon and platform-specific package metadata |
| `scripts/` | Tests, exact release manifest, audit and build scripts |
| `tests/fixtures/9.sav` | Backward-compatibility save fixture |
| `docs/localization-glossary.md` | Russian terminology and translation style |
| `plan.md` | Modernization roadmap |

## Save data

LÖVE stores user data under the `sarcophagus` identity. The game supports nine save slots and writes a screenshot alongside each save. `tests/fixtures/9.sav` is retained as a compatibility fixture during modernization.

## Credits and links

- Original game and design: **Dmitry Smirnov / acerbial**
- Modernized version: **Evgeny Stepanishchev** ([bolknote.ru](https://bolknote.ru/))
- [Official Sarcophagus page and downloads](https://acerbial.itch.io/sarcophagus)
- [LÖVE framework](https://love2d.org/)

## License

Sarcophagus is distributed under the [MIT License](LICENSE.md). Copyright (c)
2019 **Dmitry Smirnov**, the original author. Third-party libraries and assets
retain their own copyright notices and license terms.

---

# Русский

## Об игре

Sarcophagus — авторский sandbox/survival-проект Дмитрия Смирнова (`acerbial`). Игра обращается к образу Сизифа и идее о том, что упорный труд способен преобразить как окружающее пространство, так и самого человека.

Игрок начинает жизнь в пустоватой аллегорической пещере и постепенно превращает её в цветущий сад. Для выживания придётся копать, строить, выращивать пищу и поддерживать экосистему. Сначала мир кажется почти безжизненным, но заселить и изменить его можно собственными усилиями.

Это не симулятор бога: еду необходимо выращивать, инвентарь ограничен, а разные задачи постоянно требуют внимания. Игра намеренно требовательная и старомодная — она вознаграждает наблюдательность, эксперименты и самостоятельное обучение.

Название образовано от греческих корней, связанных с плотью и поеданием.

## Игровые системы

В игре сочетаются:

- процедурная генерация пещеры;
- исследование мира и платформинг;
- голод, жажда, температура, здоровье и чистота;
- добыча ресурсов, строительство и падающие блоки;
- земледелие и управление экосистемой;
- крафт, инструменты и экипировка;
- существа, бой и метательные снаряды;
- симуляция воды, огня, освещения и окружающей среды;
- рыбалка, катастрофы, задания и достижения;
- анализ и преобразование предметов при помощи **Машины**.

В текущих исходниках определено 368 предметов, 195 типов блоков, 18 типов существ, около 262 рецептов и 41 достижение.

## С чего начать

- Найдите осколки льда.
- Осматривайте всё подряд: знания являются одной из основных систем развития.
- Обращайте внимание на знак `≈`. Он отмечает объекты, которые Машина может исследовать или преобразовать.
- Машина — ваш друг.

Полной внутриигровой энциклопедии намеренно нет: самостоятельные открытия являются частью игры.

## Управление

Ниже перечислены стандартные клавиши и кнопки мыши. Контекстные панели игры
показывают доступные в данный момент действия; большинство игровых действий
можно переназначить со стартового экрана.

### Стартовый экран

| Клавиша | Действие |
|---|---|
| `W`, `S` / `↑`, `↓` | Выбрать слот сохранения |
| `Enter` | Загрузить выбранное сохранение или начать новую игру |
| `Backspace` + `Shift` | Удалить выбранное сохранение |
| `L` | Начать новую игру с **наследием**, если оно доступно |
| `F2` | Сменить язык |
| `C` | Настроить клавиши или геймпад |
| `H` / `O` | Открыть страницу игры / канал Discord |
| `Q` | **Сменить мир** (текущая реализация закрывает игру) |

### Игра и инвентарь

| Клавиша | Действие |
|---|---|
| `W`, `A`, `S`, `D` / стрелки | Движение и прыжок |
| `Shift` | Бег / ускорение |
| `Space` | Копать, подобрать или поставить переносимый блок; вверх/вниз задают направление копания |
| `E` / левая кнопка мыши | Атаковать или осмотреть блок |
| `O` | Осмотреть блок, показанный на контекстной панели |
| `V` | Использовать блок в позиции игрока или напиться воды |
| `R` / правая кнопка мыши | Бросить или опустошить предмет |
| `1`–`9` | Выбрать предмет в инвентаре |
| Колесо мыши, `[` / `]`, `-` / `=` (`+`) | Переключать ячейки инвентаря; над журналом — прокручивать его текст |
| `0` | Переключаться между инвентарём и надетыми предметами |
| `Q` / кнопка мыши 5 | Поднять первый предмет с земли |
| `Shift` + `1`–`9` | Поднять с земли конкретный предмет |
| `Tab` / средняя кнопка мыши | Переключать предметы на земле |
| `M` | Отсортировать предметы на земле в позиции игрока |
| `Z` / кнопка мыши 4 | Положить выбранный предмет или подготовить устанавливаемый блок |
| `P` | Надеть или снять выбранный предмет |
| `Enter` / `U` | Использовать или съесть выбранный предмет |
| `I` | Осмотреть выбранный предмет; для еды — показать пищевую ценность |
| `C` | Открыть или закрыть крафт для выбранного предмета |
| `Shift` + `C` | Открыть крафт из всех предметов, доступных в текущем месте |
| `Ctrl` | Включить или выключить подсветку предметов, похожих на выбранный |
| Правый `Alt` | Включить или выключить подсветку всех предметов на земле |
| Левый `Alt` (удерживать) | Показать проблемы растений |
| `/` | Скрыть или показать журнал |
| `Esc` | Закрыть текущий контекстный экран или открыть меню паузы и настроек |

### Справка и контекстные экраны

| Клавиша | Действие |
|---|---|
| `F1` | Показать задание |
| `F2` | Показать рацион |
| `F3` | Укусить себя |
| `F4` | Показать клавиши |
| `F5` | Снимок экрана |
| `F7` | Молитва |
| `F8` / `N` | Достижения |
| `A`, `D` / `←`, `→` | Листать категории достижений |
| `W`, `S` / `↑`, `↓`, затем `Enter` | Выбрать и изготовить рецепт на экране крафта |
| `W`, `S` / `↑`, `↓` | Перемещаться по меню паузы |
| `A`, `D` / `←`, `→`, `Enter` или `Space` | Изменить или активировать выбранную настройку меню паузы |
| Цифровой блок `8`, `2`, `4`, `6` | Перемещать виртуальный курсор при игре без мыши |
| `Backspace` / `Esc` при настройке | Пропустить текущее действие / отменить настройку |

Оригинальная игра поддерживает клавиатуру, мышь и геймпады.

## Версии и состояние проекта

Оригинальная версия `0.10.591` доступна для Windows, macOS и Linux на [официальной странице itch.io](https://acerbial.itch.io/sarcophagus). На itch.io исходный проект по-прежнему обозначен как находящийся в разработке.

Текущая модернизированная версия в этом репозитории — `0.11.0`.

### Оригинальный журнал разработки

В [официальном devlog](https://acerbial.itch.io/sarcophagus/devlog) описаны несколько этапов разработки 2019 года:

- **30 ноября 2019 — версия 0.10.53:** появились куры, яйца, помёт и связанные с ними рецепты.
- **15 ноября 2019 — Butler bot:** робот-дворецкий был добавлен как награда за достижение.
- **12 ноября 2019 — версия 0.10.40:** опубликована первая система из 27 достижений. Ранние достижения помогали новым игрокам освоиться, а часть достижений давала награды и дополняла систему заданий.

В импортированных исходниках `0.10.591` уже определено 41 достижение, то есть они содержат более поздние изменения, не описанные этими записями.

Этот репозиторий представляет собой снимок исходников, который сейчас модернизируется. В план входят:

- совместимость с LÖVE 11.5;
- воспроизводимые сборки для Windows, macOS и Linux;
- полноценная система английской и русской локализации;
- сохранение совместимости со старыми сейвами;
- автоматические smoke-тесты и проверки релиза.

Подробная последовательность работ находится в [plan.md](plan.md).

## Запуск из исходников

Требования:

- [LÖVE 11.5](https://love2d.org/);
- настольная система с поддержкой графики и звука.

Запустите папку проекта через LÖVE:

```sh
love /абсолютный/путь/к/Sarcophagus
```

Целевой и уже проверенный рантайм модернизированной версии — LÖVE 11.5 со встроенным LuaJIT. Отдельно устанавливать Lua не требуется.

## Язык

Английская и русская локали полны и имеют одинаковое покрытие ключей. Английский остаётся безопасным fallback на время разработки, однако проверка локалей теперь не допускает коммит неполного русского перевода.

- На стартовом экране язык переключается клавишей `F2`.
- Во время игры язык можно сменить через пункт **Язык** в меню `Esc`.
- Выбор хранится в `settings.json` отдельно от девяти игровых слотов.
- При первом запуске используется поддерживаемый язык операционной системы, иначе — английский.

Для детерминированного запуска при разработке можно задать `SARCOPHAGUS_LANGUAGE=en` или `SARCOPHAGUS_LANGUAGE=ru`.

Для запуска автоматических проверок совместимости:

```sh
./scripts/test.sh
```

Набор тестов также реально переключает окно → полный экран → окно, проверяет
двойной масштаб и весь путь десятиминутного autosave: постановку в очередь,
ожидание fade, backup, повторную загрузку, отключение и retry после ошибки записи.

Для отдельной проверки структуры локализаций:

```sh
./scripts/check-locales.sh
./scripts/check-ui-strings.sh
```

После добавления английских строк полная статическая русская локаль пересобирается командой `./scripts/complete-russian-localization.py`. Контекстные редакторские варианты закреплены в `scripts/ru_editorial_overrides.py`; сама игра никогда не обращается к сервису перевода.

Для сборки release-архива `.love` с заранее подготовленным атласом спрайтов:

```sh
./scripts/build-love.sh
```

Результат сохраняется в `dist/Sarcophagus.love`. По умолчанию оба сценария используют изолированный runtime из `.tools/`; другой исполняемый файл LÖVE 11.5 можно указать через `LOVE_BIN`.

Release-сборщик сериализует метаданные атласа с сортировкой ключей, нормализует время файлов через `SOURCE_DATE_EPOCH`, закрепляет порядок записей ZIP и удаляет host-specific ZIP extras. Поэтому повторные сборки из одинаковых исходников дают один SHA-256 `.love`; Linux workflow проверяет это двумя сборками и побайтовым сравнением архивов.

Release-аудит также ограничивает размер `.love` значением 12 МиБ, чтобы во все
платформенные пакеты незаметно не попал случайный крупный файл. Переменную
`MAX_LOVE_ARCHIVE_BYTES` следует менять только при осознанном увеличении лимита.

### Нативные пакеты

Для сборки универсального приложения macOS (Intel и Apple Silicon) на macOS:

```sh
./scripts/build-macos.sh
```

Перед этим macOS-сценарий сам пересобирает `dist/Sarcophagus.love`, поэтому старый архив не может незаметно попасть в новое приложение. Переменную `LOVE_ARCHIVE=/путь/к/game.love` следует задавать только для явно выбранного и уже проверенного готового архива. Финальный ZIP сохраняет executable-биты и симлинки, но не содержит AppleDouble-мусора `__MACOSX/._*`; распакованное приложение и его подпись проверяются повторно.

Сборщик удаляет из приложения заголовочные файлы frameworks, нужные только для
разработки. Пакет для одной архитектуры можно сделать заметно меньше; по
умолчанию по-прежнему собирается универсальный вариант:

```sh
MACOS_ARCH=arm64 ./scripts/build-macos.sh
MACOS_ARCH=x86_64 ./scripts/build-macos.sh
```

Без учётных данных получается пакет с локальной ad-hoc-подписью — он предназначен только для проверки на машине разработчика. Публичную загрузку, которую Gatekeeper открывает штатно, необходимо подписать сертификатом **Developer ID Application** и нотарифицировать у Apple:

```sh
MACOS_SIGNING_IDENTITY='Developer ID Application: Имя (TEAMID)' \
MACOS_NOTARY_PROFILE='sarcophagus-notary' \
./scripts/build-macos.sh
```

`MACOS_NOTARY_PROFILE` — заранее созданный в Keychain профиль `xcrun notarytool store-credentials`. Сценарий подписывает frameworks и само приложение с hardened runtime, отправляет ZIP через `notarytool`, прикрепляет нотариальный ticket и проверяет результат. Именно это устраняет старые инструкции про «неизвестного разработчика», «приложение повреждено» и `xattr`; для неподписанного или ad-hoc-подписанного файла из интернета честно устранить Gatekeeper-предупреждение нельзя. Подробности есть в [руководстве Apple по нотарификации](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

После сборки `dist/Sarcophagus.love` Windows x64-пакет создаётся на Windows:

```powershell
powershell.exe -NoProfile -File scripts\build-windows.ps1
```

Сценарий загружает закреплённый официальный runtime LÖVE 11.5, до встраивания игры добавляет системный DPI-aware manifest, проверяет manifest и вложенный `.love`, прикладывает необходимые DLL и лицензию LÖVE, затем создаёт ZIP в `dist/`. Пользователю такого пакета не должны требоваться прежняя настройка Compatibility → High DPI и `run.bat`.

После сборки `dist/Sarcophagus.love` Linux x86_64 AppImage создаётся на Linux-машине с архитектурой x86_64:

```sh
./scripts/build-linux-appimage.sh
```

Сценарий загружает официальный AppImage LÖVE 11.5 и закреплённые инструменты AppImage, отклоняет любой бинарник с несовпадающей SHA-256, встраивает игру в нативный раннер, устанавливает desktop-файл и иконку проекта, а затем повторно извлекает результат и проверяет его состав и вложенный `.love`. Результат сохраняется как `dist/Sarcophagus-linux-x86_64-0.11.0.AppImage`.

Загруженному пакету нужно дать право на запуск:

```sh
chmod +x Sarcophagus-linux-x86_64-0.11.0.AppImage
./Sarcophagus-linux-x86_64-0.11.0.AppImage
```

Workflow `Linux AppImage` в GitHub Actions запускает полный набор тестов с тем же закреплённым LÖVE, собирает `.love` и AppImage и сохраняет AppImage вместе с файлом SHA-256 как артефакт workflow. Схема упаковки следует [официальной инструкции LÖVE](https://love2d.org/wiki/Game_Distribution) и [спецификации AppDir](https://docs.appimage.org/reference/appdir.html).

Все нативные пакеты используют общий пиксельный исходник `packaging/icon.png`. Закреплённые в репозитории Retina-иконку `.icns` для macOS и многоразмерную `.ico` для Windows можно заново получить на macOS при помощи ImageMagick и `iconutil`:

```sh
./scripts/generate-platform-icons.sh
```

Обычная сборка пакетов использует уже готовые производные иконки и не требует этих инструментов.

## Структура проекта

| Путь | Назначение |
|---|---|
| `main.lua` | Точка входа и загрузка модулей |
| `src/` | Игровой рантайм и Lua-модули |
| `src/mapgen.lua` | Процедурная генерация мира |
| `src/items.lua` | Предметы и их поведение |
| `src/stones.lua` | Блоки, растения и сооружения |
| `src/locales/` | Английская локаль и активный русский слой |
| `assets/maps/` | Фрагменты карты для генератора мира |
| `assets/sounds/` | Звуки, используемые игрой |
| `assets/sprites/` | Исходники спрайтов для разработки; в релизе заменяются атласом |
| `archive/` | Старый код и ассеты, исключённые из релиза |
| `packaging/` | Общая иконка и платформенные метаданные пакетов |
| `scripts/` | Тесты, точный манифест, аудит и сборка релиза |
| `tests/fixtures/9.sav` | Контрольный сейв для обратной совместимости |
| `docs/localization-glossary.md` | Терминология и стиль русского перевода |
| `plan.md` | План модернизации |

## Сохранения

LÖVE хранит пользовательские данные под идентификатором `sarcophagus`. Игра поддерживает девять слотов и сохраняет снимок экрана рядом с каждым сейвом. Файл `tests/fixtures/9.sav` оставлен как контрольный пример для проверки обратной совместимости.

## Авторство и ссылки

- Оригинальная игра и дизайн: **Дмитрий Смирнов / acerbial**
- Модернизированная версия: **Евгений Степанищев** ([bolknote.ru](https://bolknote.ru/))
- [Официальная страница Sarcophagus и загрузки](https://acerbial.itch.io/sarcophagus)
- [Игровой фреймворк LÖVE](https://love2d.org/)

## Лицензия

Sarcophagus распространяется по [лицензии MIT](LICENSE.md). Правообладатель —
оригинальный автор игры **Дмитрий Смирнов**, copyright (c) 2019. Сторонние
библиотеки и материалы сохраняют собственные уведомления и условия лицензий.
