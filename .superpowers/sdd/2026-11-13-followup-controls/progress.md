# SDD ledger — plan: docs/superpowers/plans/2026-11-13-followup-controls.md

Base: a6d64219eee189610e9df88c464a4e5e66dfa930

Task 1: in progress

Task 1: complete (tests: Lua 5.1 tests/run.lua -> 62 tests, 0 failures; luac syntax check -> pass; git diff --check -> pass)
Task 2: in progress

Task 2: Ruling: Mend Pet uses a secure [@pet,exists,nodead] macro and Revive Pet uses [@pet,dead], not a forced unit=pet Spell action — Classic Hunter macros use pet-state conditionals and Revive Pet may not accept a living/dead unit target; direct spell actions remain for aspects. Cost if wrong: pet actions may not cast on the intended pet state; manual game checks are required.
Task 2: complete (tests: Lua 5.1 tests/run.lua -> 67 tests, 0 failures; luac syntax check -> pass; git diff --check -> pass)

Final review: Important findings fixed in one pass — stable action slots, scaled button anchors and non-overlapping action/tool rows; tests in hunter_actions_test.lua and food_test.lua pass (69/69).
Final: minor (deferred): Preview XP labels do not rerender immediately when switching units; main in-game XP labels do. Cost if wrong: preview may show the previous unit until rebuilt.
Final: minor (deferred): A known pet spell without a returned localized name may not produce its macro button until a later spell refresh. Cost if wrong: pet helper button can be absent temporarily.
Final: minor (deferred): Pet-state availability is shown in hover text only rather than changing the button face. Cost if wrong: availability is less visible at a glance.

User finding: normal XP panel hidden at level 21 after preview closes. Ruling: XP.Init previously waited for PLAYER_ENTERING_WORLD to create state and render. Initialize synchronously from snapshot; a mocked Controller test reproduces the frame hidden before and shown after. Cost if wrong: negligible duplicate observation when the event subsequently arrives; model already deduplicates unchanged samples.
Regression test: XP panel initializes from a live snapshot even before the world event — RED before fix, GREEN after. Updated suite: 70/70.

User runtime finding: both Hunter and XP were absent after restart and only Hunter appeared after manual toggle. Root cause confirmed: Forever rejects `LEARNED_SPELL_IN_TAB`; exception in Hunter.Init aborted the shared PLAYER_LOGIN callback before XP.Init. Replaced with Forever-supported `LEARNED_SPELL_IN_SKILL_LINE` and retained `SPELLS_CHANGED`. `spell refresh listeners use Forever event names only`: RED before / GREEN after.
Ruling: rely on the documented Forever `LEARNED_SPELL_IN_SKILL_LINE` event alongside `SPELLS_CHANGED` for learned spell updates — the rejected legacy event raises at registration and prevents module initialization; the cost if the new event differs in-game is missing immediate refresh until SPELLS_CHANGED, though startup still works.
71 tests pass; final install is Alpha 0.1.7.
