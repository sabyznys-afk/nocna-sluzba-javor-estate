# CLAUDE CODE INSTRUCTIONS — START WITH `TODO.md`

**IMMEDIATE FIRST STEP:** Read [`TODO.md`](./TODO.md) completely before taking any other action. It contains the exact active development plan (**Prompt 09 — Major Immersion Update**) with completed status, priority-ordered remaining tasks (Task 1 through Task 6), exact file targets, and acceptance tests.

## Non-Negotiable Constraints
- **Engine:** Godot `4.7.x` (`GL Compatibility` renderer). Do NOT restart or discard existing systems.
- **Language:** 100% **English** across all UI, dialogue, notebook text, and synthesized voices.
- **Art Style:** PS1-inspired low-poly 3D pixelated horror (organic low-poly characters — NO box heads — already rebuilt in `assets/models/char_*.glb` via `tools/build_ps1_characters.py` & `tools/build_p9_face_textures.py`).
- **Top Priority Remaining Work (see `TODO.md` for full specs):**
  1. Jozef Varga patient companion waiting & 2–4m pacing rework (`scripts/systems/companion_guard_controller.gd`).
  2. Human mumbling library (8+ male, 8+ female, 3+ elderly profiles, 3D wall occlusion, `HumanConversationGenerator`) + categorized horror audio library (`scripts/systems/ambient_speech_manager.gd`, `scripts/systems/horror_audio_manager.gd`).
  3. Unified pixelated inventory hotbar, pixel icons & pixel notebook styling (`scripts/ui/hud.gd`, `scripts/ui/javor_theme.gd`, `scripts/ui/notebook_ui.gd`).
  4. Data-driven 5-category Anomaly & Horror Event Director with 6-night escalation & 70/20/10 pacing (`scripts/autoload/anomaly_director.gd`, `scripts/systems/horror_event_manager.gd`).
  5. Living NPC idles & full verification suite (`tests/verify_prompt09_immersion.gd` + all existing suites passing with 0 errors/warnings).
- **Check off completed boxes in `TODO.md`** as you implement and verify them.
