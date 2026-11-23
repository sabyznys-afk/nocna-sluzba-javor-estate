# NOČNÁ SLUŽBA / NIGHT SHIFT: THE JAVOR ESTATE
## Phase 1 Project Audit & Phase 2 Creative Bible (1996 Central European Psychological Horror)

---

### 1. Project Audit Summary (Existing Architecture)
- **Engine & Rendering**: Godot `4.7.2.stable` (`GL Compatibility`, `canvas_items` / `expand` stretch).
- **Existing World**: Modular 3D residential estate (`scenes/district/*.tscn`, 6 panelák blocks A–F, Central Park, Commercial Square, Parking Lot, 10 Garages, Security Office, Substation/Boiler/Basement), 57 Blender `.glb` models, 39 PBR maps, 14 period signage textures, 70 mastered `.ogg` audio files, 52 registered animations (24 viewmodel + 28 world).
- **Existing Systems**: `GameState`, `AudioSynth` (4 headphone-aware audio buses: `EnvLayer`, `LifeLayer`, `SupernaturalLayer`, `HeadphoneMusic`), `AnomalyDirector` (32 anomalies), `AchievementManager` (28 achievements), `GuardController`, `GuardViewmodel`, `PlayerStaminaManager`, `PlayerSanityManager`, `HeadphoneManager`, `PlayerEquipmentManager`, `PhysicalDoor` + `DoorManager` (11 hinged doors), `InteractiveProp`, and debug-only `RESIDENTIAL DISTRICT ASSET MANAGER` (`tools/asset_browser/`).
- **Gaps Addressed by Master Prompt 03**:
  1. Replace generic HUD/menu styling with one centralized 1990s analog administrative `Theme` (`JavorTheme`) + full EN/SK/CS diacritic typography (`bahnschrift.ttf` + `consola.ttf`).
  2. Upgrade Main Menu to a real-time 3D Security Office desk composition with rain-covered window, illuminated distant panelák window, distressed official logo, multi-slot Save/Load cards, Difficulty selector, Options, and Credits.
  3. Build grounded, restrained HUD + interactive 9-page physical aged-paper Notebook + coordinate-accurate Sídlisko Javor Map + full Pause, Options (Display/Graphics/Audio/Gameplay/Accessibility/Language), Dialogue, Cassette Tape Player, Chapter Cards, and Loading Screens.
  4. Integrate the complete 6-Night **Sídlisko Javor / Nový Brod (November 1996)** narrative centered around **Martin Kováč**, **Jozef Varga**, **Anna Krížanová**, **Dana Bieliková**, **Milan Švec**, **Peter**, and the unlisted **Apartment 47**, culminating in **Ending A (The Report)**, **Ending B (The Last Resident)**, and **Ending C (The Next Shift — `SHIFT ASSIGNED: NIGHT 7`)**.

---

### 2. Visual & Typographic Direction
- **Titles**:
  - Original Working Title (SK): `NOČNÁ SLUŽBA — SÍDLISKO JAVOR`
  - English Localization (Primary Default): `NIGHT SHIFT — THE JAVOR ESTATE`
  - Czech Localization (CS): `NOČNÍ SLUŽBA — SÍDLIŠTĚ JAVOR`
- **Colour Palette**:
  - Primary Dark Charcoal: `#121617`
  - Dark Olive Surface: `#1b211f`
  - Faded Grey-Green Panel: `#252d29`
  - Aged Paper (Notebook & Docs): `#d8ceb8` / `#c9bea6`
  - Ink Dark / Pencil Grey: `#23211d` / `#4e4a41`
  - Muted Amber Accent: `#d69e4e`
  - Faded Orange Highlight: `#c9783c`
  - Restrained Warning Red: `#b5443a`
- **Typography**:
  - Primary Sans-Serif (`bahnschrift.ttf`): Menus, dialogues, subtitles, navigation.
  - Secondary Technical Monospace (`consola.ttf` / `consolab.ttf`): Timestamps, shifts, patrol logs, document numbers, cassette labels, system tags.

---

### 3. Story Bible — Sídlisko Javor, Nový Brod (November 1996)
- **Protagonist**: **Martin Kováč** (27) — pragmatic temporary night watchman working 22:00–06:00 shifts to pay rent. Observant, restrained, keeps a worn paper notebook, brass master ring, flashlight, radio, and a cassette Walkman with padded headphones.
- **Supporting Cast**:
  - **Jozef Varga** (51) — Security supervisor. Bureaucratic, calm, communicates by radio/phone/memos. Avoids questions about Milan Švec; gradually reveals prior sealed reports.
  - **Anna Krížanová** (68) — Long-time resident of Building A. Observant and direct; remembers Building B's original 1983 floor plans and Milan's late-night questions.
  - **Dana Bieliková** (39) — Night shopkeeper at Večierka. Practical, tired, notices strange footsteps and saw Milan buying batteries days before he vanished.
  - **Milan Švec** (44) — Former night guard who disappeared before Martin's hiring. Present through torn notebook pages, cassette tapes, and his final warning: *"Keď budeš počuť svoje meno, neodpovedaj."* (*"When you hear your own name, do not answer."*)
  - **Peter** (12) — Local boy sometimes seen near Central Park playground; speaks matter-of-factly about someone standing behind an unlit window in Building B.
- **Central Mystery — Apartment 47**:
  - Official 1984 floor registers list 46 units in Building B. Yet intercom logs show calls from `BYT 47`, the elevator occasionally halts between floors, and a sealed service corridor beneath the estate links to altered maintenance records.
  - **Headphone Connection**: Martin wears his Walkman headphones for comfort during lonely shifts. Listening calms stress, yet hides subtle sounds—and Milan's tapes reveal familiar melodies layered with whispered warnings and recordings dated *before* Martin's first shift.

---

### 4. Six-Shift Campaign & Three Endings
1. **Night 1 — The Routine (11.11.1996)**: Keys, patrol instructions, Varga radio check-in, Dana at Večierka, Anna at Building A, playground sound, lit window, silent office phone -> mystery handwritten notebook line appears.
2. **Night 2 — The Residents (12.11.1996)**: Noise complaint above vacant flat, north entrance check, playground & Peter, Anna's recollections, Dana mentions Milan, intercom rings from **Apartment 47**.
3. **Night 3 — The Recordings (13.11.1996)**: CCTV shows figure behind Martin, find old maintenance key, Garage 03 inspection, Milan's cassette tape -> final playback carries Martin's own voice dated before Night 1.
4. **Night 4 — The Wrong Floor (14.11.1996)**: Building B elevator floor mismatch, electrical failure, extended stairwell corridor, unlocked door, Walkman tape anomaly, landing door **47** disappears on second look.
5. **Night 5 — Below the Estate (15.11.1996)**: Substation circuit restore, basement maintenance tunnel, sealed unit blueprints, Varga admits suppressed reports, disconnected radio speaks Martin's name.
6. **Night 6 — The Last Patrol (16.11.1996)**: Lights extinguish, CCTV fails, residents absent, notebook repeats entries, **03:17 estate blackout**, final choice at Security Office / Building B:
   - **Ending A — The Report**: Gather sufficient evidence & formally file the incident report, refusing to follow the voice. Morning looks ordinary, key pages vanish, and the open notebook remains on an empty desk.
   - **Ending B — The Last Resident**: Follow the voice to Apartment 47 and uncover Milan's final message amidst a subtly altered estate.
   - **Ending C — The Next Shift**: Stay on duty and accept another night. Morning arrives cleanly, Varga thanks Martin—then the phone rings again: **`SHIFT ASSIGNED: NIGHT 7`**.
