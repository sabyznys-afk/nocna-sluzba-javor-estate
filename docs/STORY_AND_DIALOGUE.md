# NOČNÁ ZMENA: BLOK 14 — Story Bible & Dialogue Script

## 1. Cast of Characters
- **Marek Dvořák (32)** *(Protagonist)*: Laid-off precision machinist from an insolvent state factory. Needs 12,000 Sk per month cash-in-hand to cover family debts. Pragmatic, observant, quietly haunted by the crumbling post-1989 reality.
- **Pán Kováč (54)** *(Employer / Dispatcher, SBS Kováč)*: Former VB (police) sergeant turned private security contractor. Speaks through static-ridden rotary calls and recorded cassettes. Always insists: *"Check the locks, keep bums out, stay away from the red cellar door, and if the TVs turn on by themselves — pull the breaker and shut up."*
- **Pani Mária (78)** *(Last Tenant, Flat 4)*: Retired seamstress who survived both 1953 ŠtB arrests and the 1968 occupation in Blok 14. Refuses Hruška's buyout. Gives Marek herbal tea, warnings about the well, and the spare attic padlock code.
- **Milan "Krtko" (29)** *(Courtyard Scavenger)*: Street-smart petty thief sleeping near the passage bins. Trades AA flashlight batteries and intel about Hruška's white Mercedes for quiet passage.
- **Braňo & Igor** *(Enforcers)*: Tracksuit, leather jacket, and gold-chain muscle working for Východná Investičná s.r.o. Grounded, brutal 1995 underworld threats.
- **Ing. Róbert Hruška (46)** *(New Owner)*: Slick privatization shark wearing a wool trench coat and carrying a Nokia brick phone. Orchestrating the demolition of Blok 14 to bury evidence and sell prime Old Town land.
- **Jozef Bartoš (58)** *(Missing Predecessor)*: Guarded Blok 14 until October 1995. Left 8 torn logbook pages and 4 reel/cassette tapes warning Marek before Kováč locked him inside Bunker K-4.
- **Elena Králová (27)** *(Missing Journalist)*: Investigated Hruška's privatization fraud and the 1953 cellar vault. Vanished three weeks ago; left 3 pieces of evidence hidden across the block.

---

## 2. Night-by-Night Script & Quests

### NIGHT 1: *Prvá zmena* *(First Shift — Monday, Nov 13, 1995)*
**Briefing Phone Call (Pán Kováč)**:
> "Dvořák? Kováč here. Welcome to SBS Kováč. Blok 14 is yours from ten to six. Four Watchman's Clocks: Gate, Courtyard Well, 2nd-Floor Gallery, and the Boiler Room. Lock the Passage shutters, check the Watchmaker's alarm — old lock keeps slipping — and shut off a running tap someone reported in vacant Flat 7. One rule: do NOT touch the red iron door in the cellar. Doesn't belong to our contract. Keep your mouth shut and your logbook clean."

**Key Quests**:
1. Stamp all 4 Watchman's Clocks (`clock_gate`, `clock_well`, `clock_gallery`, `clock_boiler`).
2. Check Passage Watchmaker's shutter (`hodinarstvo_door`).
3. Inspect leaking faucet in Flat 7 (`flat7_sink`) — water runs ink-black; bathroom mirror briefly shows an empty hallway behind Marek even with the door shut.
4. Check CCTV in *Vrátnica* (`booth_cctv`) — Camera 3 shows a man in Marek's exact coat standing two meters outside the guard booth. Stepping outside reveals only wet footprints leading to the cellar stairs.
5. Discover **Jozef's Torn Page #1** tucked behind the Boiler Room clock:
   > *"Count the windows on the east wall every night. Tonight there are thirteen. On Tuesday there were twelve."*

---

### NIGHT 2: *Výpalné a šum* *(Racket & Static — Tuesday, Nov 14, 1995)*
**Briefing Phone Call (Pán Kováč)**:
> "Storm's rolling in. At 01:00 sharp, a white Mercedes van will back up to the carriage gate for a private inventory transfer. You stay inside the booth, pull the curtain, and log 'Gate Quiet'. Understand? Also check the Passage fusebox — dampness keeps tripping it — and lock up the Notary Office; someone left the back latch unhooked."

**Key Quests & Branching Choice**:
1. **01:00 Delivery Choice**:
   - `[Obey Kováč]`: Stay inside the booth (`+500 Sk` bribe flag, hides plate).
   - `[Log License Plate via CCTV]`: Zoom CAM-01 on Hruška's crates (`evidence_plate` unlocked).
   - `[Sneak onto Pavlač to Eavesdrop]`: Hear Braňo & Igor dragging heavy oak crates toward the cellar (*"Careful, if the journalist's bag tears..."*).
2. Reset the Passage Main Fusebox (`fusebox_passage`).
3. Secure the Notary Office (`notary_door`) — dot-matrix printer prints continuous eviction orders dated `1954` and `1995`, ending with `MAREK DVOŘÁK — TRVALÝ POBYT: BLOK 14`.
4. Catch a trespasser in the Attic stairs — **Milan "Krtko"** trades a fresh battery pack and warns Marek about the white Mercedes.
5. Check Watchmaker's clock display (`ANOM_04`): hands spin counterclockwise until `02:14`.

---

### NIGHT 3: *Mŕtvy kanál* *(Dead Channel — Wednesday, Nov 15, 1995)*
**Briefing Phone Call (Pán Kováč — heavy static)**:
> "Marek... ignore whatever is on Camera 2 tonight. Old coaxial crosstalk from town cable, that's all. Climb up to the rooftop STA antenna mast and tighten the splitter cable. And if any vacant flats have TVs howling again, pull the corridor breakers. Leave old Mária alone — she has until Friday to sign her eviction papers."

**Key Quests**:
1. Inspect CCTV CAM-02: Shows the inner courtyard **in bright 1953 daylight** with men in heavy wool coats unloading steel cylinders down the cellar stairs.
2. Climb to **Povala & STA Rooftop Mast** (`sta_antenna`): Inspect the massive 1950s amplifier wired straight down an iron conduit into the courtyard well! Find **Jozef's Brass Master Key** and **Tape #2** in the attic rafters.
3. Silence the vacant Flat 7 / Gallery TV signal bleed (`ANOM_09`).
4. **Optional Quest — Pani Mária (Flat 4)**: Deliver heart drops left at the gate (`helped_maria = true`). She gives you **Tape #1** and tells you: *"In 1953 they didn't dig a well down there. They buried voices inside stone."*
5. Answer the unplugged **Passage Payphone** ringing at `03:00` (`payphone_passage`): Elena's desperate voice tells you to check behind the Watchmaker's grandfather clock (`evidence_film` unlocked) before dissolving into a 1953 ŠtB interrogation.

---

### NIGHT 4: *Kotolňa a katakomby* *(Boiler Room & Catacombs — Thursday, Nov 16, 1995)*
**Briefing Phone Call (Pán Kováč — tense, urgent)**:
> "Boiler pressure's through the roof — city steam main warning went off at my office. Get down to Kotolňa and bleed the valves before it blows the foundation. Listen: Hruška's boys are coming in early to clear out the lower storage before tomorrow's municipal inspection. Do NOT get in their way."

**Key Quests & Branching Choice**:
1. Bleed the Boiler Pressure Valve (`boiler_valve`) while dodging **The Boiler Man (*Kurič*)** in the soot-dark cellar.
2. **Braňo & Igor Encounter**:
   - `[Hide & Slip Past]` (preserves `Duch v dvore` stealth achievement).
   - `[Bribe / Cooperate]` (aligns toward Ending A).
   - `[Lock Cellar Grate / Lure Anomaly]` (`lured_anomalies_on_mobsters = true`, feeds Ending E).
3. Use Jozef's Brass Key to open the **Red Iron Door** (`red_door`) and enter **Bunker K-4** (CRT shifts to eerie monochrome green-grey phosphor).
4. Inside K-4:
   - Find **Jozef Bartoš** slumped before a glowing oscilloscope, muttering patrol timestamps — receive his **Archive Key** (`accepted_jozef_key` optional choice).
   - Recover **Elena Králová's Dossier** (`evidence_dossier`) behind fresh wet concrete.
   - Discover **Device K-4** — a humming 1953 ŠtB acoustic/RF resonator bolted to the medieval well shaft, wired up to the rooftop STA mast.

---

### NIGHT 5: *Posledné vysielanie* *(The Final Broadcast — Friday, Nov 17, 1995)*
**Historical Backdrop**: Beyond the iron carriage gate, distant bells and Velvet Revolution anniversary crowds drift through the November fog — a stark contrast to the trapped horror inside Blok 14.

**Briefing Phone Call (Pán Kováč — no pretense left)**:
> "You opened the red door, didn't you, Marek? Hruška knows. He's bringing fifty thousand Deutschmarks and two men at midnight. Lock the gate, sign the final inspection log, and walk away rich — or don't walk out at all."

**Climax Resolution Paths (at Booth / Bunker K-4 / Rooftop STA / Gate)**:
- **Take Hruška's Envelope & Falsify Final Log** → **Ending A (*Nevidel som nič*)**
- **Evacuate Pani Mária via Milan's Passage + Disable STA Amplifier + Escape with Elena's 3 Evidence Pieces** → **Ending B (*Ranné správy*)**
- **Sabotage Boiler Pressure & Overload Device K-4 in Bunker K-4** → **Ending C (*Vypnutý prúd*)**
- **Signal Distortion >= 75% + All 5 Hidden Radios Tuned to 50.4 Hz + Accept Jozef's Key** → **Ending D (*Stála zmena*)**
- **Lure K-4 Manifestations onto Braňo/Igor/Hruška + Cut Kováč's Line** → **Ending E (*Krvavý dvor*)**

---

### SECRET NIGHT 6 (NG+): *Páska 00 — November 1953* *(Unlocked after any Ending + 4 Tapes + 8 Pages)*
Returning to the Rooftop STA Mast with all 4 archival tapes triggers a full frequency reversal. Marek steps down the stairs into **Blok 14 in November 1953** — fresh plaster, coal smoke, ŠtB officers guarding the cellar hatch. Reaching Device K-4 at the moment of its first activation, Marek pulls the master copper grounding bus, shattering the 42-year loop.

When Marek ascends back to the courtyard, the CRT/VHS filter cracks off entirely — revealing crisp, clean November morning light for **Ending F (*Páska 00: Archív*)**.

---

## 3. Collectibles Summary
- **Jozef's 8 Torn Pages**: Found behind the Boiler Clock, inside Flat 7, Watchmaker's counter, Attic rafters, Well rim, Notary desk, Booth drawer, and Bunker K-4 console.
- **4 Archival Tapes**: Given by Pani Mária (`Tape 1`), Attic stash (`Tape 2`), Passage Payphone locker (`Tape 3`), and Jozef himself (`Tape 4`).
- **Elena's 3 Evidence Items**: CCTV van license plate (`evidence_plate`), Film Roll in Watchmaker's Grandfather Clock (`evidence_film`), and Concrete-sealed Dossier (`evidence_dossier`).
