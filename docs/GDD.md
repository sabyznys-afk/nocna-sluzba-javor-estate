# NIGHT SHIFT: BLOCK 14 — Game Design Document (GDD)

## 1. Overview
- **Title**: *NIGHT SHIFT: BLOCK 14* *(1995 Slovakia)*
- **Genre**: First-Person Atmospheric Psychological Horror / Night-Watch Simulator / Detective Thriller
- **Engine**: Godot 4.7.2 (`GL Compatibility` forward-retro 3D + custom CRT/VHS post-processing)
- **Setting**: November 13–17, 1995 — Historic Old City Quarter (*Blok 14 — Dvor sv. Kataríny*), unnamed Slovak town
- **Target Playtime**: ~3 Hours main campaign (5 Nights, 30–45 min per shift) | ~12 Hours for 100% completion (6 Endings, 32-Anomaly Codex, 28 Achievements, Secret Night 6, Hardcore Mode)

---

## 2. Aesthetic & Tone: "Old TV" Pessimistic 1995 Slovakia
The visual language captures *divoké deväťdesiate* (the Wild 90s): post-split economic disillusionment, shady privatization (*kupónová privatizácia*), wet cobblestones, rotting Austro-Hungarian plaster patched with grey socialist concrete, and fluorescent buzz.

### Rendering & CRT/VHS Pipeline (`shaders/crt_vhs.gdshader`)
- **Curved Tesla CRT Vignette & Bezel**: Subtle barrel curvature framing the player's viewport.
- **Interlaced Scanlines & Aperture Grille**: Crisp horizontal scanlines and subtle phosphor mask.
- **VHS Tracking & Chromatic Aberration**: Horizontal tear waves, RGB channel separation, and static bursts that intensify smoothly as **50Hz Signal Distortion** (`0%–100%`) rises near anomalies or inside Bunker K-4.
- **Pessimistic Chiaroscuro Palette**:
  - Crushed ink-black shadows (`#050709`) where a weak yellow halogen flashlight (`F`) struggles against damp fog.
  - Sickly sodium-vapor streetlamp amber (`#8F6D32`)
  - Wet slate courtyard blue (`#232C33`)
  - Damp plaster grey (`#4B4E4F`)
  - Boiler rust red (`#5A2C22`)
  - Dead-channel CRT blue (`#3A5060`) bleeding out of vacant apartments
  - Bunker K-4 phosphor monochrome green-grey shift (`monochrome_mix -> 0.85`).
- **Diegetic VCR HUD**: Minimal top-right VHS tape stamp (`13.11.1995  22:30  REC ●`), battery percentage, and 50Hz interference bar.

---

## 3. Core Gameplay Loop (22:00 → 06:00)
Each shift takes place within the walled perimeter of **Blok 14**, shifting seamlessly between mundane night-watch duties, real human danger, and creeping broadcast anomalies.

1. **Shift Briefing (22:00)**: Answer the rotary phone in *Vrátnica* (Guard Booth) to hear orders from **Pán Kováč** (SBS Kováč dispatcher) and inspect the *Strážna kniha* (Guard Logbook).
2. **Night Patrol Quests ("What to Check")**:
   - Stamp mechanical **Watchman's Clock** checkpoints (*kontrolné hodiny*) located at Gate, Well, Gallery, and Boiler Room.
   - Check Passage shop shutters, reset tripped fuse boxes, bleed boiler pressure valves, inspect vacant flats, and watch the 4 live CCTV feeds on the booth monitor.
   - Complete optional human errands (helping elderly **Pani Mária** in Flat 4, trading with petty thief **Milan "Krtko"**, or collecting **Jozef Bartoš's** hidden torn pages & cassette tapes).
3. **Human Threats vs. Supernatural Anomalies**:
   - Not every disturbance is paranormal. Mafia enforcers (**Braňo & Igor**) and **Ing. Róbert Hruška** use the block at night to conceal smuggling and murder. Stepping out at the wrong moment or getting spotted ruins stealth runs and shifts ending outcomes.
4. **Anomaly Reaction Matrix**:
   Whenever you encounter an active anomaly, you choose one of four responses (`[1]`–`[4]`):
   - **`[1] Log & Report`**: Document it objectively in the Guard Logbook and radio Kováč. Safe, unlocks Codex data, builds corporate cover-up awareness.
   - **`[2] Contain / Stabilize`**: Cut power, nail/seal the breach, or silence the speaker. Keeps Signal Distortion low (`-4%` to `+2%`) and preserves control.
   - **`[3] Investigate Closer`**: Touch the signal, answer the dead line, or step through the spatial tear. Raises Signal Distortion (`+10%` to `+20%`), uncovers deep lore, keys, or supernatural paths.
   - **`[4] Ignore (*Nevidel som nič*)`**: Look away and walk past. Minimizes short-term risk and fuels the complicit *Nevidel som nič* ending.
5. **Dawn Debrief (06:00)**: Return to the booth desk once required patrol checks are done and submit your morning entry:
   - **Tell the Truth** (logs human crimes and paranormal disturbances honestly; raises Kováč's suspicion).
   - **Falsify Log (*Nevidel som nič*)** (takes Kováč/Hruška's cover-up line).
   - **Redact** (stalls for time while concealing evidence you uncovered).

---

## 4. Six Endings (A–F)
| ID | Title (SK / EN) | Core Requirements | Tone & Fate |
|---|---|---|---|
| **A** | *Nevidel som nič* / **I Saw Nothing** | Falsify logs / obey Kováč (`took_bribe` or high `falsified_logs_count`), never breach Red Door into K-4. | Complicit survival. Blok 14 is torn down, Marek gets a new flat — but every night at 02:14 his TV turns to Channel 3 waiting for his shift. |
| **B** | *Ranné správy* / **Morning News** | Collect all 3 pieces of Elena's evidence, evacuate Pani Mária (`evacuated_maria`), disable the rooftop STA amplifier (`antenna_sabotaged`), submit honest/whistleblower escape at dawn. | Bittersweet expose. Hruška flees and demolition halts, yet Kováč disappears and news footage of the cellar hides an extra silhouette. |
| **C** | *Vypnutý prúd* / **Power Cut** | Breach Bunker K-4 (`red_door_opened`), overload Boiler & Device K-4 simultaneously (`boiler_overloaded`). | Explosive destruction. Steam, fire, and collapsing limestone bury K-4 and Hruška's men forever; the 50Hz hum ceases. |
| **D** | *Stála zmena* / **The Permanent Shift** | Signal Distortion `>= 75%`, tune all 5 hidden radios to `50.4 Hz`, accept Jozef's Brass Key inside Bunker K-4 (`accepted_jozef_key`). | Psychological assimilation. Marek locks the iron gate from the *inside* at 06:00 as a new guard arrives for Night 1. |
| **E** | *Krvavý dvor* / **Bloody Courtyard** | Lure anomalies onto Braňo, Igor, and Hruška (`lured_anomalies_on_mobsters`) and betray Kováč (`betrayed_kovac`). | Dark dominion. Police call it a mob shootout; Marek remains sole keeper of an empty block that now obeys his whistle. |
| **F** | *Páska 00: Archív* / **Tape 00: Archive** *(True Ending — NG+)* | Complete any prior ending to unlock NG+ / Night Select, collect all 4 archival tapes + 8 torn pages, trigger the **Night 6 (1953 Time-Slip)** via the STA Rooftop Mast, and shut off K-4 at its source. | Cathartic freedom. For the first time, the CRT scanline filter dissolves into crisp November morning daylight as Marek steps outside the gate. |

---

## 5. Replayability: Reaching ~12 Hours (100% Completion)
1. **First Blind Campaign (~3.0–3.5 hrs)**: Complete Nights 1–5 once (~40% of anomalies spotted).
2. **Night Select & Ending Hunt (~4.5 hrs)**: Unlocks after first completion; replay specific nights to branch moral paths, save/lose NPCs, and achieve Endings A–E plus Secret Night 6 / Ending F.
3. **Anomaly Codex (*Archív anomálií* — 32 Entries)**: Many anomalies spawn conditionally (CCTV-only at 03:00+, fuses pulled, flashlight off, or high Signal Distortion).
4. **Hardcore Mode (*Zmena bez zľutovania* — ~3.0 hrs)**: Unlocks after first clear — 2× battery drain, lethal distortion thresholds, no objective HUD reminders, and single save per night.

---

## 6. Achievement Blueprint (28 Achievements)
### Progression & Story (6)
1. `ACH_01_FIRST_STAMP` — *Prvá pečiatka* / First Stamp: Complete Night 1.
2. `ACH_02_BLACK_MARKET` — *Čierny trh* / Black Market: Witness or log the Night 2 01:00 delivery.
3. `ACH_03_ON_THE_ROOF` — *Na streche* / On the Roof: Reach the STA Rooftop Antenna Mast on Night 3.
4. `ACH_04_RED_DOOR` — *Za červenými dverami* / Behind the Red Door: Unlock and enter Bunker K-4 on Night 4.
5. `ACH_05_WITNESS` — *Svedok* / The Witness: Recover Elena Králová's hidden dossier & camera film.
6. `ACH_06_NOV_17` — *17. november* / November 17: Survive Night 5 until 06:00.

### Endings (6)
7. `ACH_07_ENDING_A` — *Nevidel som nič* / I Saw Nothing: Unlock Ending A.
8. `ACH_08_ENDING_B` — *Ranné správy* / Morning News: Unlock Ending B.
9. `ACH_09_ENDING_C` — *Vypnutý prúd* / Power Cut: Unlock Ending C.
10. `ACH_10_ENDING_D` — *Stála zmena* / The Permanent Shift: Unlock Ending D.
11. `ACH_11_ENDING_E` — *Krvavý dvor* / Bloody Courtyard: Unlock Ending E.
12. `ACH_12_ENDING_F` — *Páska 00: Archív* / Tape 00: Archive: Unlock Secret Ending F.

### Anomaly Hunting (5)
13. `ACH_13_13TH_WINDOW` — *Trináste okno* / The Thirteenth Window: Discover `ANOM_01` on the east courtyard wall.
14. `ACH_14_DEAD_LINE` — *Mŕtva linka* / Dead Line: Answer the unplugged Passage payphone (`ANOM_08`) and all phantom calls.
15. `ACH_15_ARCHIVIST` — *Archivár* / Archivist: Discover 15 unique anomalies in the Codex.
16. `ACH_16_BLIND_SPOT` — *Slepá škvrna* / Blind Spot: Log 5 CCTV-only anomalies via the guard booth monitor.
17. `ACH_17_FULL_CATALOG` — *Kompletný katalóg* / Complete Catalog: Discover all 32 anomalies in *Archív anomálií*.

### Moral & Character Paths (6)
18. `ACH_18_GOOD_NEIGHBOR` — *Dobrý sused* / Good Neighbor: Deliver Pani Mária's medicine and evacuate her safely.
19. `ACH_19_MOLE_DEAL` — *Dohoda s Krtkom* / Deal with the Mole: Complete Milan "Krtko"'s trading & alley questline.
20. `ACH_20_MODEL_EMPLOYEE` — *Vzorový zamestnanec* / Model Employee: Never falsify a single Guard Logbook entry across 5 nights.
21. `ACH_21_DOUBLE_GAME` — *Dvojitá hra* / Double Game: Falsify all 5 Dawn Reports (*Nevidel som nič*).
22. `ACH_22_JOZEF_LEGACY` — *Jozefov odkaz* / Jozef's Legacy: Collect all 8 torn logbook pages and 4 cassette tapes.
23. `ACH_23_KEYMASTER` — *Kľúčnik* / Keymaster: Unlock Flat 7, Watchmaker's, Notary Office, Attic, and Bunker K-4.

### Skill & Mastery (5)
24. `ACH_24_POWER_SAVER` — *Šetrenie prúdom* / Power Saver: Finish any full shift without swapping flashlight batteries.
25. `ACH_25_GHOST_IN_YARD` — *Duch v dvore* / Ghost in the Yard: Complete a playthrough without ever being spotted by Braňo, Igor, or Hruška.
26. `ACH_26_CLOCKWORK` — *Presný ako hodinky* / Like Clockwork: Stamp all 4 Watchman's Clocks cleanly on every shift.
27. `ACH_27_NO_MERCY` — *Bez zľutovania* / No Mercy: Complete Hardcore Mode (*Zmena bez zľutovania*).
28. `ACH_28_PLATINUM` — *Platinová strážna kniha* / Platinum Logbook: Unlock all other 27 achievements.
