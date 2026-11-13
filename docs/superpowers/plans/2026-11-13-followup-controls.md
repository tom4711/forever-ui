# Forever UI Follow-up Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Replace the XP question mark, make quest/rested values independently configurable as XP or percent, show the Mac Option drag hint, and add direct hunter buttons for learned aspects, Mend Pet, and Revive Pet.

**Architecture:** Keep the XP units in per-character SavedVariables and format only their display labels; preserve XP segment calculations. Add protected spell buttons to the Hunter module, preconfigure learned spells out of combat, and defer any secure updates during combat through the existing CombatQueue.

**Tech Stack:** WoW Forever 1.60.1 Lua 5.1 addon APIs; existing Settings, SecureActionButtonTemplate, tests/run.lua, package.py.

**Spec:** `docs/superpowers/specs/2026-11-13-followup-controls-design.md`

## Global Constraints

- Preserve Lua 5.1 syntax and no runtime dependency on other addons.
- Preserve existing character settings and their independent hunter/XP scale.
- Do not copy code or media from reference addons.
- Protected actions require an explicit user click; no spell is cast automatically.
- Do not change protected button attributes or visibility during combat.
- Package the addon under exactly one `ForeverUI/` folder with its license notices.

## Review Focus

1. Loading a saved character with no display-mode values must keep XP defaults and panel layout usable.
2. A quest or rested reward above one level must show more than 100% without corrupting capped bar segments.
3. A hunter learning/unlearning spells during combat must not trigger protected-frame writes.
4. A missing or dead pet must not make Mend Pet target the player or cast without an explicit click.
5. Preview mode and non-hunter characters must not expose working hunter action buttons.

---

### Task 1: XP labels, display modes, and macOS move hint

**Files:** Modify `ForeverUI/Core/Settings.lua`, `ForeverUI/Locales.lua`, `ForeverUI/Modules/XP/View.lua`, `ForeverUI/UI/Settings.lua`, `ForeverUI/UI/Widgets.lua`, `ForeverUI/UI/Preview.lua`, `ForeverUI/UI/Theme.lua`, `README.md`; tests in `tests/settings_test.lua`, `tests/xp_test.lua`, `tests/run.lua`.

**Interfaces:** `db.xp.questDisplay` and `db.xp.restedDisplay` each contain `"xp"` or `"percent"`, defaulting to `"xp"`. `XPView.Render` displays `round(amount / maximum * 100, 1)` with localized percent text, while `XPModel.Segments` continues using the full XP values. `IsMacClient()` selects the move hint label only.

- [x] Add tests for old SavedVariables defaulting both modes to `xp` and valid/corrupt display values normalizing to `xp`.
- [x] Add tests that absolute values remain exact and percent values use `amount / current-level maximum * 100`, including a value above 100%.
- [x] Implement localized settings selectors with separate persisted modes; refresh XP labels when either changes.
- [x] Replace the question-mark icon with a clear native gold “XP” emblem using the existing panel/icon treatment and no external media.
- [x] Select “Option” (including macOS label) from `IsMacClient()`; keep `IsAltKeyDown()` for movement.
- [x] Run `lua tests/run.lua` and parse all distributed Lua files with `luac -p`.

### Task 2: Direct Hunter spell buttons

**Files:** Modify `ForeverUI/ForeverUI.toc`, `ForeverUI/Modules/Hunter/View.lua`, `ForeverUI/Modules/Hunter/Controller.lua`, `ForeverUI/Modules/Hunter/Model.lua` as needed, `ForeverUI/Core/Bootstrap.lua`, locales, settings/package version, `tests/run.lua`, and focused Hunter tests.

**Interfaces:** The Hunter controller supplies the set of learned supported aspect spell IDs to the view. The view creates fixed `SecureActionButtonTemplate` controls for each learned aspect, plus Mend Pet and Revive Pet secure macro clicks with `@pet,exists,nodead` and `@pet,dead` conditions, respectively; actions are invoked only by button clicks. Use `CombatQueue.Request` for out-of-combat setup and refresh.

- [x] Add model tests for deduplicated supported learned spells and omission of unknown spell IDs.
- [x] Add tests for pet action availability states: Mend requires a living pet; Revive requires a dead pet; neither is available when no pet exists.
- [x] Register relevant pet and spell learning events; refresh learned spells outside combat and retain the last configured set during combat.
- [x] Create fixed secure spell buttons with localized tooltips and original game spell icons; keep their visibility stable through combat; expose pet-state availability in hover tooltips without changing protected attributes.
- [x] Place aspect buttons on a dedicated first row and feeder/menu/settings controls on a separate second row; keep Preview buttons nonfunctional.
- [x] Bump alpha version, update testing and design notes, build the ZIP, and verify its declared file list.
- [x] Run the full Lua 5.1 test suite, syntax-check all TOC Lua files, and review the diff for protected actions, privacy, and package contents.

## Manual Client Checks

After installation, use `/reload`; confirm XP/percent settings persist independently; check Mac Option hint; inspect learned aspect icons and clicks; test Mend Pet with a living pet, Revive Pet with a dead pet, no pet, and during combat. Ensure no Lua errors or protected-action taint.

## Zusatzkorrektur nach Nutzerprüfung

Falls `PLAYER_ENTERING_WORLD` beim ersten Aufruf verspätet eintrifft, bleibt das normale XP-Frame nicht mehr bis dahin leer: `XP.Init` startet es sofort mit einem aktuellen Snapshot. Ein Controller-Test deckt den verzögerten Event-Fall ab.

## Startkorrektur nach Forever-Client-Test

`LEARNED_SPELL_IN_TAB` ist auf Forever unbekannt und unterbrach beim Login den restlichen `PLAYER_LOGIN`-Handler, sodass XP und Hunter nicht initialisiert wurden. Die Spell-Refresh-Liste verwendet jetzt `LEARNED_SPELL_IN_SKILL_LINE` und `SPELLS_CHANGED`; ein Regressionstest pinnt beide Eventnamen.

## Secure-Klickkorrektur nach Spieltest

Hunter-Aktionen registrieren Links-Drücken und Loslassen, aktivieren Mausereignisse ausdrücklich und liegen fünf Frame-Level über dem beweglichen Hunter-Root. Damit werden Forever-spezifische Up-only-Klickausfälle und überdeckende Frames abgefangen.
