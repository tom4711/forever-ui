# SDD ledger — plan: docs/superpowers/plans/2026-11-13-followup-controls.md

Base: a6d64219eee189610e9df88c464a4e5e66dfa930

Task 1: in progress

Task 1: complete (tests: Lua 5.1 tests/run.lua -> 62 tests, 0 failures; luac syntax check -> pass; git diff --check -> pass)
Task 2: in progress

Task 2: Ruling: Mend Pet uses a secure [@pet,exists,nodead] macro and Revive Pet uses [@pet,dead], not a forced unit=pet Spell action — Classic Hunter macros use pet-state conditionals and Revive Pet may not accept a living/dead unit target; direct spell actions remain for aspects. Cost if wrong: pet actions may not cast on the intended pet state; manual game checks are required.
Task 2: complete (tests: Lua 5.1 tests/run.lua -> 67 tests, 0 failures; luac syntax check -> pass; git diff --check -> pass)
