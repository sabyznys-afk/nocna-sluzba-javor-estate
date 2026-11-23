# AI AGENT INSTRUCTIONS — READ `TODO.md` IMMEDIATELY!

When you open, inspect, or start working on this repository (**NIGHT SHIFT: THE JAVOR ESTATE / Nočná Služba**), **your FIRST action MUST be to read [`TODO.md`](./TODO.md)** in full and immediately begin executing the unchecked tasks in priority order (Task 1 -> Task 6).

## Mandatory Project Rules
1. **Continue development directly in this existing Godot 4.x project.** Never restart, never replace the 6-night campaign, never delete working assets or mechanics.
2. **All in-game text, UI, subtitles, notebook entries, and voices MUST stay in English.**
3. **Preserve the PS1-inspired 3D pixelated visual aesthetic** (low-poly organic anatomy, nearest-neighbor textures, Bayer dithering, crisp shadows, balanced readable night lighting).
4. **Do NOT use fake placeholders or dummy files.** Build real audio assets, real 3D world state changes, real NavMesh + `CharacterBody3D` collision, and verify with automated Godot tests + visual screenshot inspection.
5. **Critical Rendering & Physics Rules:**
   - Do NOT re-enable `vertex_lighting` in `shaders/ps1_spatial.gdshader`.
   - Keep `DistrictNavigationManager` NavMesh voxel parameters aligned (`cell_size = 0.20`, `cell_height = 0.25`, `agent_radius = 0.40`).
   - Keep `CompanionGuardController` and all NPCs as solid `CharacterBody3D` actors with zero wall/desk/car clipping.
6. **Before finishing any task:** Run `--import --quit`, all existing test suites in `tests/`, and update the `[x]` checkboxes in `TODO.md` as you complete each item.
