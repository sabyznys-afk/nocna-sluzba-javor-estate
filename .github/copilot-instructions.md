# GitHub Copilot Instructions

Always read `TODO.md` and `AGENTS.md` at the repository root first before proposing or implementing changes.

- Project: **NIGHT SHIFT: THE JAVOR ESTATE** (Godot 4.x `GL Compatibility`, PS1-inspired 3D pixelated psychological horror).
- Continue directly on the unchecked Prompt 09 tasks listed in `TODO.md` in priority order (Task 1 -> Task 6).
- Keep ALL in-game voices, dialogue, UI, and notebook text in **English**.
- Never re-enable `vertex_lighting` in `shaders/ps1_spatial.gdshader`.
- Keep all NPCs and Jozef Varga on real `CharacterBody3D` collision + `DistrictNavigationManager` NavMesh.
- Verify all changes with the Godot headless test suites under `tests/`.
