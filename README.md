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

| Input | Action |
|---|---|
| `W`, `A`, `S`, `D` / arrow keys | Move and jump |
| `Shift` | Run / speed up |
| `Space` | Dig, pick up or drop a carried block |
| `E` / left mouse button | Attack or examine a block |
| `R` / right mouse button | Throw or empty an item |
| `1`–`9` | Select an inventory item |
| `Q` | Pick up an item from the ground |
| `Tab` | Cycle ground items |
| `C` | Open crafting |
| `Enter` | Use or consume the selected item |
| `I` | Inspect the selected item |
| `V` | Use the block at the player position |
| `F1`–`F4` | Quest, diet, self-harm and key help |
| `F8` / `N` | Achievements |

Keyboard, mouse and gamepads are supported by the original game.

## Releases

The original version `0.10.591` is available for Windows, macOS and Linux from the [official itch.io page](https://acerbial.itch.io/sarcophagus). The itch.io page describes the original project as in development.

### Original development log

The [official devlog](https://acerbial.itch.io/sarcophagus/devlog) documents several milestones from 2019:

- **30 November 2019 — version 0.10.53:** chickens, eggs, manure and related recipes were added.
- **15 November 2019 — Butler bot:** the Butler bot became an achievement reward.
- **12 November 2019 — version 0.10.40:** the first published achievement system contained 27 achievements. Early achievements helped introduce new players to the game, while some achievements also provided rewards and acted as an additional quest system.

The local `0.10.591` source contains 41 achievement definitions, so it includes work completed after those devlog entries.

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

English is the complete fallback locale. Russian is being translated incrementally; untranslated text remains available in English instead of breaking the game.

- Press `F2` on the start screen to switch languages.
- Choose **Language** in the in-game `Esc` menu to switch while playing.
- The choice is stored in `settings.json`, separately from the nine save slots.
- On first launch, the game uses a supported operating-system language and otherwise falls back to English.

For a deterministic development launch, set `SARCOPHAGUS_LANGUAGE=en` or `SARCOPHAGUS_LANGUAGE=ru`.

Run the automated compatibility checks:

```sh
./scripts/test.sh
```

Validate the localization overlay separately:

```sh
./scripts/check-locales.sh
./scripts/check-ui-strings.sh
```

Build a release-mode `.love` archive with a pre-generated sprite atlas:

```sh
./scripts/build-love.sh
```

The resulting file is written to `dist/Sarcophagus.love`. Both scripts use the isolated runtime under `.tools/` by default; set `LOVE_BIN` to use another LÖVE 11.5 executable.

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
| `scripts/` | Tests, exact release manifest, audit and build scripts |
| `tests/fixtures/9.sav` | Backward-compatibility save fixture |
| `docs/localization-glossary.md` | Russian terminology and translation style |
| `plan.md` | Modernization roadmap |

## Save data

LÖVE stores user data under the `sarcophagus` identity. The game supports nine save slots and writes a screenshot alongside each save. `tests/fixtures/9.sav` is retained as a compatibility fixture during modernization.

## Credits and links

- Original game and design: **Dmitry Smirnov / acerbial**
- [Official Sarcophagus page and downloads](https://acerbial.itch.io/sarcophagus)
- [LÖVE framework](https://love2d.org/)

## License note

No project-wide license is currently included in this source snapshot. Do not assume that the source code or assets may be redistributed or relicensed beyond the permissions provided by applicable law and the original distribution terms. Third-party libraries and assets may have their own licenses.

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

| Клавиша | Действие |
|---|---|
| `W`, `A`, `S`, `D` / стрелки | Движение и прыжок |
| `Shift` | Бег / ускорение |
| `Space` | Копать, подобрать или положить переносимый блок |
| `E` / левая кнопка мыши | Атаковать или осмотреть блок |
| `R` / правая кнопка мыши | Бросить или опустошить предмет |
| `1`–`9` | Выбрать предмет в инвентаре |
| `Q` | Поднять предмет с земли |
| `Tab` | Переключать предметы на земле |
| `C` | Открыть крафт |
| `Enter` | Использовать или съесть выбранный предмет |
| `I` | Осмотреть выбранный предмет |
| `V` | Использовать блок в позиции игрока |
| `F1`–`F4` | Задание, рацион, самоповреждение и справка |
| `F8` / `N` | Достижения |

Оригинальная игра поддерживает клавиатуру, мышь и геймпады.

## Версии и состояние проекта

Оригинальная версия `0.10.591` доступна для Windows, macOS и Linux на [официальной странице itch.io](https://acerbial.itch.io/sarcophagus). На itch.io исходный проект по-прежнему обозначен как находящийся в разработке.

### Оригинальный журнал разработки

В [официальном devlog](https://acerbial.itch.io/sarcophagus/devlog) описаны несколько этапов разработки 2019 года:

- **30 ноября 2019 — версия 0.10.53:** появились куры, яйца, помёт и связанные с ними рецепты.
- **15 ноября 2019 — Butler bot:** робот-дворецкий был добавлен как награда за достижение.
- **12 ноября 2019 — версия 0.10.40:** опубликована первая система из 27 достижений. Ранние достижения помогали новым игрокам освоиться, а часть достижений давала награды и дополняла систему заданий.

В локальных исходниках `0.10.591` уже определено 41 достижение, то есть они содержат более поздние изменения, не описанные этими записями.

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

Английская локаль полная и используется как fallback. Русский перевод добавляется постепенно: пока строка не переведена, игра безопасно показывает её по-английски.

- На стартовом экране язык переключается клавишей `F2`.
- Во время игры язык можно сменить через пункт **Язык** в меню `Esc`.
- Выбор хранится в `settings.json` отдельно от девяти игровых слотов.
- При первом запуске используется поддерживаемый язык операционной системы, иначе — английский.

Для детерминированного запуска при разработке можно задать `SARCOPHAGUS_LANGUAGE=en` или `SARCOPHAGUS_LANGUAGE=ru`.

Для запуска автоматических проверок совместимости:

```sh
./scripts/test.sh
```

Для отдельной проверки структуры локализаций:

```sh
./scripts/check-locales.sh
./scripts/check-ui-strings.sh
```

Для сборки release-архива `.love` с заранее подготовленным атласом спрайтов:

```sh
./scripts/build-love.sh
```

Результат сохраняется в `dist/Sarcophagus.love`. По умолчанию оба сценария используют изолированный runtime из `.tools/`; другой исполняемый файл LÖVE 11.5 можно указать через `LOVE_BIN`.

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
| `scripts/` | Тесты, точный манифест, аудит и сборка релиза |
| `tests/fixtures/9.sav` | Контрольный сейв для обратной совместимости |
| `docs/localization-glossary.md` | Терминология и стиль русского перевода |
| `plan.md` | План модернизации |

## Сохранения

LÖVE хранит пользовательские данные под идентификатором `sarcophagus`. Игра поддерживает девять слотов и сохраняет снимок экрана рядом с каждым сейвом. Файл `tests/fixtures/9.sav` оставлен как контрольный пример для проверки обратной совместимости.

## Авторство и ссылки

- Оригинальная игра и дизайн: **Дмитрий Смирнов / acerbial**
- [Официальная страница Sarcophagus и загрузки](https://acerbial.itch.io/sarcophagus)
- [Игровой фреймворк LÖVE](https://love2d.org/)

## Примечание о лицензии

В этом снимке исходников нет общей лицензии проекта. Не следует считать, что код или ресурсы разрешено распространять либо перелицензировать сверх того, что допускают закон и условия оригинального распространения. У сторонних библиотек и материалов могут быть собственные лицензии.
