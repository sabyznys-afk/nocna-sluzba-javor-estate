# TODO — PROMPT 09: MAJOR IMMERSION UPDATE (AGENT HANDOFF LIST)

> **ATTENTION AI AGENT / DEVELOPER:**
> Start here immediately! This repository contains **NIGHT SHIFT: THE JAVOR ESTATE (*Nočná Služba*)**, a playable 6-night PS1-inspired 3D pixelated psychological horror game built in **Godot 4.7.2 (`GL Compatibility`)**, set in a Central European residential estate in November 1996.
>
> **STRICT RULES — READ BEFORE EDITING:**
> 1. **DO NOT** restart the project, replace the existing 6-night campaign, delete existing assets, or build a disconnected prototype. Extend the existing architecture directly.
> 2. **LANGUAGE:** ALL in-game dialogue, UI text, tutorials, notebook entries, subtitles, and generated voice audio MUST be in **English** (do NOT revert to Slovak).
> 3. **ART DIRECTION:** Preserve the **PS1-inspired low-poly 3D pixelated aesthetic** (nearest-neighbor textures, Bayer 4×4 dithering, crisp shadows, balanced readable night lighting).
> 4. **NO FAKE PLACEHOLDERS:** Generate real audio files, real 3D world changes, real NavMesh + `CharacterBody3D` collision, and verify every feature with automated Godot tests + live visual screenshots.
> 5. **TECHNICAL GOTCHAS (CRITICAL):**
>    - `shaders/ps1_spatial.gdshader`: NEVER re-enable `vertex_lighting` (breaks flashlight illumination on large `BoxMesh` surfaces). Keep per-pixel Lambertian diffuse + `use_triplanar`.
>    - `scripts/systems/district_navigation.gd`: Keep NavMesh voxel settings aligned (`cell_size = 0.20`, `cell_height = 0.25`, `agent_radius = 0.40`, `agent_height = 1.75`, `agent_max_climb = 0.50`) for 0 warnings.
>    - `CharacterBody3D.move_and_slide()` always steps by `get_physics_process_delta_time()`. Any `step_simulation(delta)` helper MUST sub-step in `phys_dt` increments and tests opening doors must `await physics_frame` so `StaticBody3D` colliders update.
>    - Maintain 100% compatibility with existing verification suites in `tests/` (`verify_game.gd`, `verify_campaign.gd`, `verify_ps1_transformation.gd`, `verify_prompt08_acceptance.gd`).

---

## CURRENT BASELINE STATUS

### ALREADY COMPLETED & VERIFIED
- [x] **Prompts 01–08 (Full Playable Baseline)**:
  - Complete 6-night campaign across the Javor Estate (Security Office, Buildings A/B/C/D/F, Central Park, Parking & Garages, Night Shop, Newsstand, Substation, Basements, Hidden Maintenance Corridor & Apartment 47, 3 endings).
  - Readable PS1 lighting, fog, flashlight (`energy = 4.6`, dynamic shadows), brightness/gamma/contrast/fog/flashlight calibration settings.
  - Baked `NavigationRegion3D` (`DistrictNavigationManager`, 2,006 walkable polygons), solid `CharacterBody3D` collision on Jozef Varga and all estate NPCs, physical doors with hinges/latches/locks, developer `F8` nav debugger.
  - Complete 8-stage interactive English tutorial (`TutorialManager`) with skip/replay & persistence.
  - Simplified 4-section readable paper Notebook (`SHIFT | MAP | NOTES | EVIDENCE`) with progressive handwriting animation.
  - 48 English neural voice clips (Piper TTS) + 5 world reaction SFX + priority non-overlapping `VoiceAssetManager`.
- [x] **Prompt 09 — Part 2 (Organic Low-Poly PS1 Character Redesign & Detailed Pixel Face Textures)**:
  - `tools/build_p9_face_textures.py` generated 14 detailed cylindrical-mapped pixel face textures (`256×256` for Jozef, Martin, Anna, Dana, Milan, Roman, Iveta; `128×128` for Zuzana, Peter, Residents A/B/C; `64×64` for distant figures) + 6 hair strand textures + 6 fabric weaves in `assets/textures/ps1_faces/`.
  - `tools/build_ps1_characters.py` rebuilt all 14 character `.glb` models in Blender (`char_varga.glb`, `char_martin.glb`, `char_anna.glb`, `char_dana.glb`, `char_zuzana.glb`, `char_peter.glb`, `char_milan.glb`, `char_roman.glb`, `char_resident_a/b/c.glb`, `char_distant_figure.glb`, `char_iveta.glb`, `fp_guard_body.glb`) with sculpted organic low-poly heads (rounded skull, brow ridge, cheekbones, jawline, chin, 3D protruding nose, 3D ears, organic neck — NO box heads!), sculpted 3D hairstyles (NO box hair!), and contoured bodies/elbows/hands/boots, preserving all articulated pivots (`TorsoPivot`, `HeadPivot`, `ArmL_Pivot`, `ArmR_Pivot`, `LegL_Pivot`, `LegR_Pivot`, `VargaFlashlightTip`).
  - **NOTE FOR NEXT AGENT:** Visually audit close-up renders of the new organic models in Godot (front, side, 3/4, flashlight lit) during verification and polish if any UV/hair alignment tweaks are needed!

---

## REMAINING PROMPT 09 TASKS (EXECUTE IN THIS ORDER)

### TASK 1 (HIGHEST PRIORITY): Jozef Varga Patient Companion Waiting & Pacing Rework (Prompt 09 Part 8)
**Target files:** `scripts/systems/companion_guard_controller.gd`, `scripts/world/main_scene.gd`, `scripts/systems/tutorial_manager.gd`
- [ ] **2–4m Lead Pacing (`CompanionPacingController` logic inside `CompanionGuardController`)**:
  - Jozef walks slowly (`1.55–1.85 m/s`), keeping **2–4 metres** ahead of Martin during guided patrols.
  - Smoothly matches Martin's slower walking pace and occasionally glances back.
- [ ] **Immediate Stop & Indefinite Waiting (`CompanionWaitController` logic — ZERO abandonment timeout!)**:
  - If Martin stops moving (`player_speed < 0.15`), Jozef stops smoothly, turns slightly toward Martin, and waits.
  - If Martin falls behind (`> 4.2m`), Jozef stops in a **safe visible location** (never blocking doorways or standing in the middle of a road) and waits.
  - If Martin opens the **Notebook** (even for 5+ minutes!), inspects an object, or opens an optional menu (`hud.is_modal_open()`), Jozef **MUST wait indefinitely** and NEVER walk off or abandon him.
- [ ] **Varied Natural Waiting Idle Animations**:
  - Cycle naturally through: looking around, checking his watch, adjusting his jacket, holding/sweeping flashlight, looking toward the street/fog, shifting weight, glancing back to check if Martin is coming, listening nods, speaking gestures.
- [ ] **Checkpoint Explain -> Demonstrate -> Wait-for-Action -> Confirm -> Resume Flow**:
  - At every guided patrol checkpoint: Jozef arrives -> stops -> faces Martin -> waits until Martin approaches (`<= 3.8m`) -> delivers concise explanation (never lecturing while walking away!) -> demonstrates/points where appropriate -> **waits in checkpoint-wait state until Martin performs the actual checkpoint inspection/interaction** -> confirms completion -> ONLY THEN resumes walking.
- [ ] **6-Night Companion Story Progression**:
  - **Night 1:** Confident, patient, helpful mentor.
  - **Night 2:** Occasionally distracted (glancing into shadows, brief pauses).
  - **Night 3:** More observant and quieter (brief handoff, watches corridors warily).
  - **Night 4:** Explicitly avoids certain buildings (Building B / basements) and explains why.
  - **Night 5:** Clear discomfort around maintenance corridors.
  - **Night 6:** Scripted and clearly explained unavailability/unreliability (e.g., desk note + radio dispatch context — NEVER vanishing silently without explanation).

---

### TASK 2: Human Mumbling, Multi-Profile Ambient Voices & Detailed Horror Audio Library (Prompt 09 Parts 1 & 7)
**Target files:** Create `tools/generate_p9_audio_library.py`, upgrade `scripts/systems/ambient_speech_manager.gd`, create `scripts/systems/horror_audio_manager.gd`, wire in `scripts/world/main_scene.gd` & `scripts/systems/audio_environment_manager.gd`
- [ ] **Original Human Mumbling & Voice Profile Library (`assets/audio/voices/Mumbling/` + `voice_profiles.json`)**:
  - At minimum: **8 distinct male voice profiles**, **8 distinct female voice profiles**, **3 elderly voice variations**, multiple short recordings per profile + **several two-person conversation recordings**.
  - Must vary through distinct performances, speaking speeds, vocal textures, distances, and formant/room/wall acoustics — **NOT pitch-shifting alone**.
  - Include: quiet mumbling, indistinct conversations (mostly unintelligible words for realism!), short whispers, distant talking, speaking behind doors, two residents talking, quiet walking comments, muttering to self, elderly quiet talk, muffled TV speech, occasional coughing, quiet laughing, telephone talk, occasional quiet argument.
- [ ] **3D Spatial Placement & Wall Occlusion (`AmbientVoiceManager` / `VoiceProfileDatabase` / `SpatialDialogueManager` integrated cleanly into `ambient_speech_manager.gd`)**:
  - Place emitters across: **Apartment Buildings** (elevated 2nd/3rd floor windows, behind doors, TV, arguments), **Courtyard** (entrances, shopping, telephone, fog voices), **Newsstand** (muttering, customer, interior phone), **Park** (distant talk, behind vegetation, footsteps+voices), **Basements** (faint behind walls, quiet cough, distant room), **Security Office** (radio, telephone, muffled outside window).
  - Implement true 3D distance attenuation, directional audio, **dynamic raycast wall occlusion muffling** (dedicated occluded low-pass + interior reverb audio bus vs open exterior ambience bus), volume variation, randomized spatial positions within zones, time-of-night schedules (silent on Night 6).
- [ ] **Anti-Repetition Voice Cooldowns & `HumanConversationGenerator`**:
  - Per-clip cooldown (`>= 45s`) and per-profile cooldown (`>= 24s`) so identical clips NEVER play back-to-back.
  - Multi-turn `HumanConversationGenerator` chaining Resident A mumbling -> short pause -> Resident B short indistinct reply -> Resident A brief response at the same 3D spot.
- [ ] **Detailed Horror & Environmental Audio Library (`assets/audio/horror/` + `scripts/systems/horror_audio_manager.gd`)**:
  - Distinct, dedicated `.ogg` clips (no reusing one SFX across unrelated events!) across ALL 5 required categories:
    1. **HUMAN:** mumbling, isolated whisper of player's name ("Martin..."), quiet conversations, distant help call, coughing, nearby/unusual breathing.
    2. **MOVEMENT:** concrete/stairs/gravel/heavy/following/long-distance footsteps, running, door movement/handle behind wall, keys drop, forced door.
    3. **BUILDINGS:** pipes, elevators, electrical hum, fluorescent buzzing, wooden creaking, basement metal impacts, window closing above, lock breaking.
    4. **HORROR:** isolated whisper, callerless unknown radio voice, distant scream, sudden silence drop, unusual breathing, repeated double knocking, empty apartment phone ring, CRT anomaly hum.
    5. **ENVIRONMENT:** wind, rain pause, distant car alarm/door, distant dogs, playground swing creak, leaves rustle, distant television.

---

### TASK 3: Pixelated Inventory Hotbar, Unified Pixel Icons & Pixel Notebook Styling (Prompt 09 Part 3)
**Target files:** Create `tools/generate_pixel_ui_icons.py`, update `assets/graphics/icons/*.png`, `assets/graphics/ui/notebook_paper_bg.png`, `scripts/ui/javor_theme.gd`, `scripts/ui/hud.gd`, `scripts/ui/notebook_ui.gd`
- [ ] **Unified Pixel-Art Icon Set (`assets/graphics/icons/`)**:
  - Redraw all hotbar/equipment icons (`icon_hands`, `icon_flashlight`, `icon_keys`, `icon_radio`, `icon_notebook`, `icon_taser`, `icon_watch`) at one shared crisp pixel scale (e.g., `24×24` or `32×32`, `TEXTURE_FILTER_NEAREST`), deliberate limited 1996 retro palette, consistent 1px dark outlines, unmistakable silhouettes — NO mixing smooth vectors with pixel art.
- [ ] **Compact Pixelated Bottom Inventory Hotbar (`scripts/ui/hud.gd` + `PixelUITheme` helpers in `javor_theme.gd`)**:
  - Compact retro pixel bar at bottom center with stepped pixel border highlight on selected slot, crisp readable typography, subtle retro selection animation (bounce/outline flash), zero smooth gradients or glassmorphism.
  - Preserve ALL working behaviors: mouse wheel switching, mouse click selection, number keys `0–6`, Empty Hands (`0`), draw animations, Flashlight ON/OFF (`F`), non-blocking movement.
- [ ] **Pixelated Notebook Styling (`scripts/ui/notebook_ui.gd`)**:
  - Keep the simplified 4-section layout (`SHIFT | MAP | NOTES | EVIDENCE`) and readable text.
  - Upgrade paper backdrop (`notebook_paper_bg.png`) and accents to crisp nearest-neighbor pixelated paper & pencil aesthetic with subtle page turn feedback, zero excessive decoration.

---

### TASK 4: Controlled 5-Category Anomaly & Horror Event Director (Prompt 09 Parts 4, 5, 6)
**Target files:** Upgrade `scripts/autoload/anomaly_director.gd` (preserving all 32 existing IDs & `get_all_anomalies()` for `verify_game.gd`!), create `scripts/systems/anomaly_event_database.gd`, upgrade `scripts/systems/horror_event_manager.gd`, wire in `scripts/world/main_scene.gd`
- [ ] **Data-Driven Event Schema (`AnomalyEventDatabase`)**:
  - Every event defines: `id`, `category`, `nights`, `severity` (`ordinary`/`suspicious`/`major`), `trigger_condition`, `location`, `audio_id`, `visual_action`, `duration`, `cooldown`, `max_plays`, `story_relevance`, `allow_with_jozef`, `completion_condition`.
- [ ] **All 5 Required Anomaly Categories (Real World Implementations!)**:
  - **Category A — Audio Anomalies (3D Spatial):** following footsteps, footsteps stopping when player stops, door handle moving behind wall, whispering player's name, ringing phone in empty apartment, distant scream, callerless radio transmission, quiet knocking behind closed door, nearby breathing, basement metallic impact, window closing above, distant help call.
  - **Category B — Visual Anomalies (Restrained, Grounded):** figure between two trees, silhouette in apartment window, resident in unusual location, figure at end of corridor, disappearing doorway figure, independent moving shadow, parked car headlights turning on, distant apartment light switching off, previously closed door now open, figure walking behind fog.
  - **Category C — Physical Anomalies (Real World State Changes):** moved chair, keys appearing on floor, open cabinet, displaced rubbish container, fresh footprints, broken lock, blood near basement entrance, left-behind object, opened newspaper, slightly ajar door, missing personal item.
  - **Category D — Human Encounters (Real Navigation — NEVER Teleporting Jumpscares!):** unidentified resident walking away, figure watching from building entrance, person near garage, misplaced resident, unknown maintenance worker, someone quietly entering basement, person running away when approached, window silhouette. Must use real `CharacterBody3D` + NavMesh walking!
  - **Category E — Environmental Anomalies:** mistimed flickering streetlamp, apartment windows going dark, radio signal loss, unusual CRT monitor image, door becoming unlocked, distant car alarm, moving playground swing, sudden courtyard silence, rain pausing briefly, localized dense fog.
- [ ] **6-Night Escalation Curve (Part 5)**:
  - Night 1: Subtle irregularities (mostly normal; max 1 genuinely unsettling moment; no antagonist reveal).
  - Night 2: Unusual activity (still mostly explainable).
  - Night 3: Estate feels different (CCTV figure, basement double knock, damaged lock, distant phone).
  - Night 4: Direct human threat (entering Building B, unlocked door, mud/blood, stairwell runner, office door try, unknown radio voice).
  - Night 5: Evidence & discovery (basement light, maintenance door voice, belongings, metallic impact, hidden service door, body discovery, corridor escape).
  - Night 6: Active pursuit (lights off, CCTV cameras fail, footsteps in office, antagonist roaming, forced door, outside office, final encounter connected to campaign endings).
- [ ] **Pacing & Budget Controls (Part 6)**:
  - Target ~**70% ordinary environment / 20% suspicious atmosphere / 10% major horror encounters**.
  - Context checks: player position, facing direction, story progress, NPC presence, Jozef accompaniment, psychological state, audio conditions.
  - Per-night event budgets, global & per-event cooldowns, one-time persistent major discoveries that NEVER repeat as new.

---

### TASK 5: Living NPC Idle Behaviours & Character Visual Polish
**Target files:** `scripts/systems/npc_character.gd`, `scripts/systems/npc_schedule_manager.gd`
- [ ] Enrich `NPCCharacterController` with varied natural idle routines (shifting weight, glancing around, checking bag/pockets, brief pauses along paths, subtle reactions) so residents feel alive without constantly addressing the player.
- [ ] Capture close-up GPU screenshots of redesigned organic PS1 characters (Jozef, Anna, Dana, Roman — front, side, 3/4, flashlight-lit) and verify silhouettes & face UVs visually.

---

### TASK 6: Complete Prompt 09 Verification Suite & Regression Pass (Prompt 09 Part 10)
**Target files:** Create `tests/verify_prompt09_immersion.gd`, verify all existing suites in `tests/`
- [ ] Run Godot `--import --quit` (0 errors, 0 warnings).
- [ ] Write & pass `tests/verify_prompt09_immersion.gd` covering ALL Part 10 acceptance checkboxes:
  - **Human Audio:** `>=8` male profiles, `>=8` female profiles, `>=3` elderly variations, non-repetitive cooldowns, natural mumbling, 3D spatial positioning, wall occlusion muffling, distinct normal vs horror audio, `HumanConversationGenerator`, no constant repetitive loops.
  - **Characters:** organic non-box heads (`OrganicHeadMesh` vertex/geometry validation), recognizable silhouettes, 3D hair geometry, `128×128`/`256×256` detailed pixel face textures, distinct character appearances, working NPC animations.
  - **UI:** pixelated inventory hotbar, unified pixel icon set, mouse/wheel/keyboard selection, empty hands, readable text, simplified 4-section notebook.
  - **Anomalies:** all 5 categories, 6-night progression, audio/visual/physical/human-encounter/environmental execution, 70/20/10 pacing & cooldowns, non-repeating major events, real navigating human encounter (no teleporting).
  - **Jozef:** stops when player stops, waits indefinitely (test 300s / 5 minutes!) while Notebook is open or player falls behind, does not abandon checkpoints, cycles waiting idle animations, resumes only when player is ready & completes action, Night 1–6 story progression, zero wall/desk/car clipping.
  - **Technical:** clean launch, 0 critical errors, 0 warnings, 0 broken audio/scene references, 0 navigation failures.
- [ ] Run ALL automated suites and verify exit code `0` with `0` errors/warnings:
  ```powershell
  # Replace path with your local Godot 4.x executable
  & "C:\Users\arnos\Godot\Godot.exe" --headless --path . --import --quit
  & "C:\Users\arnos\Godot\Godot.exe" --headless --path . --quit-after 3
  & "C:\Users\arnos\Godot\Godot.exe" --headless --path . --script res://tests/verify_game.gd
  & "C:\Users\arnos\Godot\Godot.exe" --headless --path . --script res://tests/verify_campaign.gd
  & "C:\Users\arnos\Godot\Godot.exe" --headless --path . --script res://tests/verify_ps1_transformation.gd
  & "C:\Users\arnos\Godot\Godot.exe" --headless --path . --script res://tests/verify_prompt08_acceptance.gd
  & "C:\Users\arnos\Godot\Godot.exe" --headless --path . --script res://tests/verify_prompt09_immersion.gd
  ```

---

## KEY REPOSITORY ARCHITECTURE MAP
| Area | Key Files |
|---|---|
| Main Scene & Wiring | `scenes/main.tscn`, `scripts/world/main_scene.gd`, `scripts/world/blok14_builder.gd` |
| Player & First-Person Body | `scripts/player/guard_controller.gd`, `assets/models/fp_guard_body.glb` |
| Companion Jozef & NPCs | `scripts/systems/companion_guard_controller.gd`, `scripts/systems/npc_character.gd`, `scripts/systems/npc_schedule_manager.gd`, `scripts/systems/district_navigation.gd` |
| Tutorial | `scripts/systems/tutorial_manager.gd` |
| Voices & Ambient Audio | `scripts/systems/voice_asset_manager.gd`, `scripts/systems/ambient_speech_manager.gd`, `scripts/autoload/audio_synth.gd`, `scripts/systems/audio_environment_manager.gd`, `tools/generate_english_voices.py` |
| Anomalies & Horror Events | `scripts/autoload/anomaly_director.gd`, `scripts/systems/horror_event_manager.gd`, `scripts/systems/antagonist_ai.gd` |
| UI, Hotbar & Notebook | `scripts/ui/hud.gd`, `scripts/ui/javor_theme.gd`, `scripts/ui/notebook_ui.gd`, `scripts/ui/map_ui.gd`, `assets/graphics/icons/` |
| PS1 Rendering & Lighting | `shaders/ps1_spatial.gdshader`, `shaders/crt_vhs.gdshader`, `scripts/systems/retro_rendering_controller.gd`, `scripts/systems/stylized_lighting_controller.gd` |
| 3D Character & Texture Tools | `tools/build_ps1_characters.py` (Blender), `tools/build_p9_face_textures.py` (PIL/NumPy), `tools/convert_ps1_textures.py` |
| Automated Verification | `tests/verify_game.gd`, `tests/verify_campaign.gd`, `tests/verify_ps1_transformation.gd`, `tests/verify_prompt08_acceptance.gd` |
