# Developer Guide: AI Navigation Layer

This file is for human developers.

It explains how to attach an AI agent to this repository's navigation layer so the agent starts from the existing repository mapping instead of rescanning the whole codebase.

## English

### What This Is

This repository has an AI navigation layer:

- `ai_navigation/AGENTS.md`
- `ai_navigation/*.md`

This layer is a repository-orientation system for AI agents.

It is not:

- in-game maps
- `_maps/**`
- `code/modules/mapping/**`
- `SSmapping`

### Start Modes

There are 3 startup modes:

- `Fast Start`
  default for normal work
- `Guided Start`
  when you want full repository guidance first
- `Maintenance Start`
  for refreshes and migrations of the navigation layer

Use the cheapest mode that fits the task.

If the correct mode or first helper is still unclear, use:

- `ai_navigation/start_matrix.md`

### Minimum Handoff

Default recommendation: use `Fast Start`, not `Guided Start`.

Use this 2-message pattern:

1. message 1: the goal
2. message 2: the repository and the instruction to start with `ai_navigation/router.md`

Recommended wording:

```text
Here is the goal:
<your task>

Here is the repository with guidance.
Start with ai_navigation/router.md.
```

If you explicitly want the full guided bootstrap:

```text
Here is the goal:
<your task>

Here is the repository with guidance.
Start with ai_navigation/AGENTS.md.
```

### What The Agent Should Do

The expected `Fast Start` path is:

1. open `ai_navigation/router.md`
2. choose exactly one small helper
3. open up to 2 source files
4. escalate only if still ambiguous

The expected `Guided Start` path is:

1. open `ai_navigation/AGENTS.md`
2. open `ai_navigation/router.md`
3. choose exactly one small helper
4. open up to 2 source files
5. escalate only if still ambiguous

This is the main cost-saving rule.

### Which File To Mention For Special Cases

- startup mode choice by task shape:
  `ai_navigation/start_matrix.md`
- bug investigation:
  `ai_navigation/debug_routes.md`
- new content or mechanics:
  `ai_navigation/content_creation.md`
- fuzzy content request:
  `ai_navigation/content_breakdown.md`
- unclear implementation shape:
  `ai_navigation/content_patterns.md`
- signals / indirect behavior:
  `ai_navigation/signal_map.md`
- spells:
  `ai_navigation/spell_signal_map.md`
- combat:
  `ai_navigation/combat_signal_map.md`
- doll movement / moveloops:
  `ai_navigation/movement_signal_map.md`
- refresh or migration of the AI navigation layer:
  `ai_navigation/update_policy.md`

### Good Task Brief Pattern

```text
Goal:
<what should be fixed / added / explained>

Context:
<feature / type path / subsystem / likely directory>

Constraints:
<what not to touch>

Verification:
<what must be true in the end>

Repository guidance:
Start with ai_navigation/router.md.
```

If the task is broad, risky, or scope is unclear, the agent is expected to classify risk with `ai_navigation/human_checking.md` before edits.

### For Refreshes And Migrations

If you want the agent to rebuild or port the navigation layer, say so explicitly and tell it to open:

- `ai_navigation/update_policy.md`

Recommended wording:

```text
Refresh the AI navigation layer for this repository.
Start with ai_navigation/update_policy.md.
Docs only unless explicitly approved otherwise.
```

Or:

```text
Migrate this AI navigation layer to another repository.
Start with ai_navigation/update_policy.md.
Preserve the navigation model, not the exact paths.
```

### Important Expectation

The navigation layer is a routing aid, not source of truth.

The agent must still verify conclusions against source code.

## Русский

### Что Это Такое

В репозитории есть AI navigation layer:

- `ai_navigation/AGENTS.md`
- `ai_navigation/*.md`

Это надстройка над кодовой базой, которая помогает ИИ быстро ориентироваться в репозитории.

Это не:

- игровые карты
- `_maps/**`
- `code/modules/mapping/**`
- `SSmapping`

### Режимы Старта

Есть 3 режима входа:

- `Fast Start`
  режим по умолчанию для обычной работы
- `Guided Start`
  если нужно сначала пройти полное руководство по репозиторию
- `Maintenance Start`
  для апдейтов и миграций navigation layer

Используй самый дешёвый режим, который подходит задаче.

### Минимальный Handoff

Рекомендуемый вариант по умолчанию: `Fast Start`, а не `Guided Start`.

Используй схему из 2 сообщений:

1. сообщение 1: цель
2. сообщение 2: репозиторий и указание начать с `ai_navigation/router.md`

Рекомендуемая формулировка:

```text
Вот цель:
<твоя задача>

Вот репозиторий с руководством.
Начни с ai_navigation/router.md.
```

Если тебе нужен полный guided bootstrap:

```text
Вот цель:
<твоя задача>

Вот репозиторий с руководством.
Начни с ai_navigation/AGENTS.md.
```

### Что Должен Делать Агент

Ожидаемый маршрут для `Fast Start` такой:

1. открыть `ai_navigation/router.md`
2. выбрать ровно один маленький helper
3. открыть до 2 исходников
4. эскалировать только если всё ещё неясно

Ожидаемый маршрут для `Guided Start` такой:

1. открыть `ai_navigation/AGENTS.md`
2. открыть `ai_navigation/router.md`
3. выбрать ровно один маленький helper
4. открыть до 2 исходников
5. эскалировать только если всё ещё неясно

Это главное правило экономии ресурсов.

### Какой Файл Указывать Для Частных Случаев

- выбор режима старта по типу задачи:
  `ai_navigation/start_matrix.md`
- баги:
  `ai_navigation/debug_routes.md`
- новый контент или механика:
  `ai_navigation/content_creation.md`
- расплывчатый контент-запрос:
  `ai_navigation/content_breakdown.md`
- неясна форма реализации:
  `ai_navigation/content_patterns.md`
- сигналы / непрямое поведение:
  `ai_navigation/signal_map.md`
- спеллы:
  `ai_navigation/spell_signal_map.md`
- боёвка:
  `ai_navigation/combat_signal_map.md`
- движение куклы / moveloops:
  `ai_navigation/movement_signal_map.md`
- апдейт или миграция AI navigation layer:
  `ai_navigation/update_policy.md`

### Хороший Шаблон Постановки Задачи

```text
Задача:
<что нужно исправить / добавить / объяснить>

Контекст:
<фича / type path / subsystem / вероятная директория>

Ограничения:
<что не трогать>

Проверка:
<что должно быть верно в конце>

Руководство по репозиторию:
Начни с ai_navigation/router.md.
```

Если задача широкая, рискованная или неясен blast radius, агент должен сначала прогнать `ai_navigation/human_checking.md`, а уже потом править код.

### Для Апдейтов И Миграций

Если нужно пересобрать navigation layer или перенести его на другой репозиторий, скажи это явно и направь агента в:

- `ai_navigation/update_policy.md`

Рекомендуемая формулировка:

```text
Обнови AI navigation layer этого репозитория.
Начни с ai_navigation/update_policy.md.
Только документация, если отдельно не согласовано иное.
```

Или:

```text
Мигрируй этот AI navigation layer на другой репозиторий.
Начни с ai_navigation/update_policy.md.
Сохраняй модель навигации, а не буквальные пути.
```

### Важное Ожидание

Navigation layer помогает быстро локализовать работу, но не заменяет чтение исходников.

Если navigation layer и код расходятся, верить нужно коду.
