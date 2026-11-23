class_name PatrolRouteManager
extends Node

signal checkpoint_visited(night: int, cp_id: String)
signal checkpoint_completed(night: int, cp_id: String)
signal route_completed(night: int)
signal tutorial_step_completed(step_id: String, next_hint: String)

# Interactive one-time Night 1 onboarding sequence (Part 13.2)
const TUTORIAL_STEPS: Array[Dictionary] = [
	{"id": "move", "label": "Move around the estate entrance", "hint": "Use [W A S D] to walk toward the lit Security Office (Vrátnica)."},
	{"id": "look", "label": "Look around in the night fog", "hint": "Move the Mouse to scan the wet yard and streetlamps."},
	{"id": "interact", "label": "Enter Vrátnica & answer Varga's briefing", "hint": "Approach the Security Office door and phone, then press [E] to interact."},
	{"id": "inventory", "label": "Switch equipment on your belt", "hint": "Scroll the Mouse Wheel or press [0–6] to switch tools."},
	{"id": "flashlight", "label": "Use your flashlight in dense fog", "hint": "Press [1] to hold the flashlight and [F] to toggle its beam ON/OFF."},
	{"id": "keys_doors", "label": "Lock or unlock doors with your keys", "hint": "Pick up the keys or look at a door and press [E] / [L] to test locks."},
	{"id": "notebook_map", "label": "Open your physical Notebook & Patrol Map", "hint": "Press [TAB] or [N] to review tonight's patrol route and map."},
	{"id": "radio", "label": "Check VHF Radio channel", "hint": "Press [4] to equip your Guard Radio and [LMB] to test dispatch."},
	{"id": "headphones", "label": "Test Walkman Headphones", "hint": "Press [H] to put on or take off Walkman headphones (calms stress, muffles footsteps)."},
	{"id": "checkpoint", "label": "Complete your first Patrol Checkpoint", "hint": "Follow the red pencil route on your Map & reflective markers to Checkpoint 1."},
]

# Data-driven 6-Night Campaign Routes matched to exact ResidentialDistrict world coordinates!
const PATROL_ROUTES: Dictionary = {
	1: {
		"shift_id": "SHIFT_01",
		"date": "18.11.1996",
		"title": "NIGHT 1 — THE FIRST SHIFT",
		"start_pos": Vector3(-15.8, 0.2, -54.5),
		"arrival_pos": Vector3(-7.5, 0.2, -62.5),
		"briefing": "First temporary night watch at Sídlisko Javor. Meet Supervisor Jozef Varga at Vrátnica, collect your gear, inspect the Main Gate, Parking Lot, Building A, Central Park, and Newsstand, then log your shift report.",
		"checkpoints": [
			{
				"id": "n1_cp1_gate", "num": 1, "name": "MAIN ENTRANCE & GATE",
				"pos": Vector3(0.0, 0.2, -68.5), "zone": "outer_environment",
				"what": "Inspect the main carriage gate barrier, padlock, and bus-stop perimeter.",
				"where": "Walk east out of Vrátnica, follow reflective post P-01 south along the entrance road to the Main Gate.",
				"why": "Verify the residential district entrance is secure for the 22:00–06:00 night watch.",
				"action": "Look at the Main Gate and press [E] (or stamp Watchman's Clock #1 by Vrátnica).",
				"optional": "Check the wet street toward the old Bus Stop.",
				"triggers": ["main_gate", "clock_gate"],
			},
			{
				"id": "n1_cp2_parking", "num": 2, "name": "SOUTH PARKING LOT",
				"pos": Vector3(22.0, 0.2, -55.0), "zone": "parking_lot",
				"what": "Inspect the resident parking bays, check the slightly open car door, and observe the garage road.",
				"where": "Follow parking lamps east from the entrance spur into the 20-bay South Parking Lot.",
				"why": "Check for suspicious vehicle activity and test your flashlight beam in dense fog.",
				"action": "Inspect the slightly open car door [E] or the abandoned Škoda Favorit.",
				"optional": "Inside the open car sits an ordinary forgotten shopping bag — not everything here is sinister.",
				"triggers": ["n1_open_car", "skoda_car", "clue_1"],
			},
			{
				"id": "n1_cp3_blocka", "num": 3, "name": "BUILDING A ENTRANCE",
				"pos": Vector3(-30.0, 0.2, 31.0), "zone": "apartments",
				"what": "Inspect Building A entrance door, intercom, mailboxes, hallway, and speak with Anna Krížanová.",
				"where": "Walk north along the central park path toward northwest Panelák BLOK A.",
				"why": "Complete your first residential lobby check and introduce yourself to long-term tenants.",
				"action": "Speak with Anna Krížanová [E] or inspect the Building A mailbox bank [E].",
				"optional": "Anna remembers previous guard Milan Švec as a quiet, methodical man.",
				"triggers": ["npc_anna", "n1_blocka_mailboxes", "blocka_entrance_door"],
			},
			{
				"id": "n1_cp4_park", "num": 4, "name": "CENTRAL PARK & PLAYGROUND",
				"pos": Vector3(-11.0, 0.2, 8.5), "zone": "central_park",
				"what": "Inspect playground swings, courtyard benches, park lighting, and investigate a metallic clink in the fog.",
				"where": "Walk south from Building A into the Central Park plaza and playground.",
				"why": "Verify nobody is loitering after midnight and check what fell near the swings.",
				"action": "Investigate the dropped unfamiliar keys in the fog [E] or inspect the playground swing.",
				"optional": "Examine the medieval well and park gazebo bench for spare 4.5V batteries.",
				"triggers": ["n1_dropped_keys", "park_swing", "clock_well"],
			},
			{
				"id": "n1_cp5_newsstand", "num": 5, "name": "NEWSSTAND & VEČIERKA",
				"pos": Vector3(41.5, 0.2, -5.0), "zone": "commercial_area",
				"what": "Check the Trafika kiosk and Večierka night shop before closing; speak with Dana Bieliková.",
				"where": "Follow the east park promenade past the carpet rack to Commercial Square.",
				"why": "Verify commercial entrances and ask whether anyone unfamiliar passed through.",
				"action": "Speak with Dana Bieliková at Večierka [E] or Zuzana at the Trafika window [E].",
				"optional": "Dana mentions someone standing quietly near the northern apartments earlier.",
				"triggers": ["npc_dana", "npc_zuzana"],
			},
			{
				"id": "n1_cp6_return", "num": 6, "name": "RETURN TO SECURITY OFFICE",
				"pos": Vector3(-18.0, 0.2, -56.0), "zone": "security_office",
				"what": "Return to Vrátnica, log your patrol report, and answer the 03:17 telephone call.",
				"where": "Follow reflective markers south along the promenade and west past the Parking Lot to Vrátnica.",
				"why": "Complete Shift 01 paperwork and receive your Night 2 schedule.",
				"action": "Answer the ringing desk telephone [E] and sign the Shift Logbook at the desk [E].",
				"optional": "Bolt the steel office door from inside [E] before reviewing CCTV.",
				"triggers": ["booth_desk", "booth_phone"],
			},
		],
		"optional_spots": [
			{"label": "Open Parked Car", "pos": Vector3(19.6, 0.2, -57.5)},
			{"label": "Trafika Window", "pos": Vector3(35.8, 0.2, -10.0)},
		],
	},
	2: {
		"shift_id": "SHIFT_02",
		"date": "19.11.1996",
		"title": "NIGHT 2 — THE RESIDENTS",
		"start_pos": Vector3(-15.8, 0.2, -54.5),
		"briefing": "Varga logged a noise complaint in Building C. Inspect the Building C stairwell and ajar door, question Anna and Dana about the stranger, check the Northern Path, and inspect Building B's intercom.",
		"checkpoints": [
			{
				"id": "n2_cp1_blockc", "num": 1, "name": "BUILDING C NOISE COMPLAINT",
				"pos": Vector3(38.0, 0.2, 30.0), "zone": "apartments",
				"what": "Check Building C main entrance, walk into the stairwell, listen for upper-floor footsteps, and examine the ajar 2F door & muddy marks.",
				"where": "Walk through the Central Park north-east courtyard to neglected dark Panelák BLOK C.",
				"why": "A resident reported heavy footsteps on an upper floor where the flat should be empty.",
				"action": "Inspect the fresh muddy boot marks & ajar door in Building C [E] or listen at the stairwell.",
				"optional": "Check Flat 9's static television and Watchman's Clock #4 on the 2F landing.",
				"triggers": ["n2_blockc_mud", "blockc_stair_sound", "door_flat9"],
			},
			{
				"id": "n2_cp2_anna", "num": 2, "name": "SPEAK WITH ANNA (BLOCK A)",
				"pos": Vector3(-28.5, 0.2, 30.8), "zone": "apartments",
				"what": "Walk west across the residential front apron to Building A and speak with Anna Krížanová.",
				"where": "Follow the concrete walkway west past Building B to Building A entrance.",
				"why": "Anna watched the courtyard at midnight and can describe the man's clothing.",
				"action": "Speak with Anna Krížanová [E].",
				"optional": "She describes a dark, worn maintenance coat rather than a clear face.",
				"triggers": ["npc_anna"],
			},
			{
				"id": "n2_cp3_newsstand", "num": 3, "name": "NEWSSTAND & DELIVERY LEAD",
				"pos": Vector3(45.2, 0.2, -2.0), "zone": "commercial_area",
				"what": "Check in with Dana Bieliková at Večierka / Newsstand regarding rear commercial alley activity.",
				"where": "Cross east toward Commercial Square and enter Večierka.",
				"why": "Dana noticed an outsider slipping repeatedly into the rear delivery alley without buying anything.",
				"action": "Speak with Dana Bieliková [E].",
				"optional": "Ask Zuzana at Trafika about the man requesting 1984 directories.",
				"triggers": ["npc_dana", "npc_zuzana"],
			},
			{
				"id": "n2_cp4_northpath", "num": 4, "name": "NORTHERN PEDESTRIAN PATH",
				"pos": Vector3(2.0, 0.2, 54.0), "zone": "northern_forest",
				"what": "Patrol the dark northern pedestrian path behind Blocks A–C; examine cigarette remains and fresh boot impressions.",
				"where": "Walk north between Blocks B and C onto the cobblestone perimeter loop beside the pines.",
				"why": "Someone has been watching the estate from the northern treeline.",
				"action": "Inspect the cigarette butts and fresh muddy boot impression [E] and log evidence.",
				"optional": "Scan the forest edge carefully with your flashlight.",
				"triggers": ["n2_north_bootprint", "shadow_stalker"],
			},
			{
				"id": "n2_cp5_blockb", "num": 5, "name": "BUILDING B INTERCOM (47)",
				"pos": Vector3(-1.4, 0.2, 35.2), "zone": "apartments",
				"what": "Inspect Building B's entrance door and aluminum intercom panel.",
				"where": "Walk around the west flank of tall 8-storey Building B to its south entrance.",
				"why": "Residents mentioned an unlisted apartment buzzer number.",
				"action": "Inspect Building B Intercom Panel [E] — notice the scratched '47' mark.",
				"optional": "Check Building B's lobby elevator and notice board.",
				"triggers": ["intercom_b47"],
			},
			{
				"id": "n2_cp6_return", "num": 6, "name": "OFFICE DEBRIEF & VARGA WARNING",
				"pos": Vector3(-18.0, 0.2, -56.0), "zone": "security_office",
				"what": "Return to Vrátnica, record Varga's warning about ignoring old maintenance doors, and sign Night 2 report.",
				"where": "Follow the central park walkway south back to Vrátnica.",
				"why": "Conclude Night 2 and document Varga's unusual evasiveness.",
				"action": "Interact with the Guard Desk Logbook [E] or answer the office phone.",
				"optional": "Check the filing cabinet memo inside Vrátnica.",
				"triggers": ["booth_desk", "booth_phone"],
			},
		],
		"optional_spots": [
			{"label": "Park Playground (Peter)", "pos": Vector3(-13.8, 0.2, 10.6)},
			{"label": "Delivery Alley Rear", "pos": Vector3(58.0, 0.2, 10.0)},
		],
	},
	3: {
		"shift_id": "SHIFT_03",
		"date": "20.11.1996",
		"title": "NIGHT 3 — THE RECORDINGS",
		"start_pos": Vector3(-15.8, 0.2, -54.5),
		"briefing": "Review all six CCTV security feeds for unauthorized courtyard movement, investigate Garage 07, inspect the rear delivery alley storage room, and recover Milan Švec's cassette dated 12.11.96.",
		"checkpoints": [
			{
				"id": "n3_cp1_cctv", "num": 1, "name": "SECURITY OFFICE CCTV REVIEW",
				"pos": Vector3(-18.0, 0.2, -57.4), "zone": "security_office",
				"what": "Inspect all 6 TESLA CCTV camera feeds inside Vrátnica.",
				"where": "At your workstation desk inside the Security Office.",
				"why": "One camera caught a person in old maintenance clothing crossing the yard at an irregular timestamp.",
				"action": "Use the CCTV Monitor [E] and cycle through all 6 cameras.",
				"optional": "Check Milan's Patrol Cassette #02 on the office shelf.",
				"triggers": ["booth_cctv"],
			},
			{
				"id": "n3_cp2_garage07", "num": 2, "name": "GARAGE COMPLEX — GARAGE 07",
				"pos": Vector3(-68.8, 0.2, -54.0), "zone": "garages",
				"what": "Inspect Garage 07 and surrounding bays for the old cigarette packet, maintenance key, handwritten number, and disturbed dust.",
				"where": "Walk west from Vrátnica along the south cross-road to Concrete Garages 01–10.",
				"why": "CCTV showed movement disappearing toward the garage apron.",
				"action": "Inspect the Garage 07 evidence stash [E] (and check open Garage 03 for Milan's log sheet).",
				"optional": "Unlock Garage 06 with the locker key from Garage 03.",
				"triggers": ["n3_garage07_clues", "garage_07", "pickup_doc_milan"],
			},
			{
				"id": "n3_cp3_alley", "num": 3, "name": "DELIVERY ALLEY SERVICE ROOM",
				"pos": Vector3(58.0, 0.2, 2.0), "zone": "commercial_area",
				"what": "Walk behind the newsstand and Večierka into the delivery alley; inspect the unlocked service nook and recover Milan's cassette.",
				"where": "Cross the courtyard east past the shops and slip behind the rear delivery containers.",
				"why": "Dana saw the stranger using the rear service alley after midnight.",
				"action": "Pick up Cassette M. ŠVEC / 12.11.96 [E] inside the delivery storage alcove.",
				"optional": "Check Watchman's Clock #3 mounted along the rear shop wall.",
				"triggers": ["n3_milan_cassette", "pickup_tape_03", "alley_rustle"],
			},
			{
				"id": "n3_cp4_office", "num": 4, "name": "PLAY RECORDING & OFFICE ALERT",
				"pos": Vector3(-18.0, 0.2, -56.0), "zone": "security_office",
				"what": "Return to Vrátnica, review Milan's recording (cuts out at 03:17), check the office window after CCTV motion, and file Night 3 report.",
				"where": "Return to Security Office desk.",
				"why": "Milan mentions Apartment 47, a hidden maintenance corridor, and someone shadowing his rounds.",
				"action": "Inspect the Guard Desk [E] / CCTV to log the 03:17 recording and finish Night 3.",
				"optional": "Listen to collected cassettes inside Notebook -> Discovered Evidence.",
				"triggers": ["booth_desk", "booth_phone"],
			},
		],
		"optional_spots": [
			{"label": "Open Garage 03", "pos": Vector3(-83.2, 0.2, -59.0)},
			{"label": "Locked Garage 06", "pos": Vector3(-72.4, 0.2, -55.0)},
		],
	},
	4: {
		"shift_id": "SHIFT_04",
		"date": "21.11.1996",
		"title": "NIGHT 4 — THE WRONG FLOOR",
		"start_pos": Vector3(-15.8, 0.2, -54.5),
		"briefing": "A tenant reported someone repeatedly forcing the Building B basement door. Inspect Building B, document basement crime evidence, question residents, and watch Vrátnica closely at 03:17.",
		"checkpoints": [
			{
				"id": "n4_cp1_blockb", "num": 1, "name": "BUILDING B STAIRWELL & SIGHTING",
				"pos": Vector3(2.0, 0.2, 36.0), "zone": "apartments",
				"what": "Check Building B entrance, elevator, and stairwell landing. Observe the man in the dark maintenance jacket walking away through a physical corridor door.",
				"where": "Walk north straight across Central Park to 8-storey Building B.",
				"why": "Investigate the repeated basement door complaint in Building B.",
				"action": "Inspect Building B's unlisted Door 47 alcove / sighting point [E].",
				"optional": "Take the elevator to the 8F Rooftop to inspect the STA antenna and maintenance hatch.",
				"triggers": ["door_47_int", "n4_blockb_sighting", "elevator_b_roof"],
			},
			{
				"id": "n4_cp2_basement", "num": 2, "name": "BASEMENT CRIME EVIDENCE",
				"pos": Vector3(-82.0, -4.0, 16.0), "zone": "apartments",
				"what": "Descend into the Block F / estate basement corridor; inspect disturbed storage boxes, broken padlock, torn dark jacket fabric, and small wall blood trace.",
				"where": "Follow the west connector path to Building F (`BLOK F`) and descend the concrete basement ramp.",
				"why": "Track where the intruder went and collect physical evidence for your report.",
				"action": "Inspect and document the basement evidence bundle [E].",
				"optional": "Check the sealed dead-end steel door at the far west end of the 34m basement.",
				"triggers": ["n4_basement_evidence", "blockf_basement_end"],
			},
			{
				"id": "n4_cp3_resident", "num": 3, "name": "QUESTION RESIDENT WITNESS",
				"pos": Vector3(-28.5, 0.2, 30.8), "zone": "apartments",
				"what": "Speak with Anna Krížanová or Dana Bieliková about the man in the dark brown maintenance coat.",
				"where": "Building A courtyard entrance (Anna) or Večierka Night Shop (Dana).",
				"why": "Compare witness descriptions — someone on the estate recognizes him.",
				"action": "Speak with Anna [E] or Dana [E].",
				"optional": "Note the discrepancy in your Notebook Incident Reports.",
				"triggers": ["npc_anna", "npc_dana"],
			},
			{
				"id": "n4_cp4_office", "num": 4, "name": "CCTV & 03:17 KEY CABINET BREACH",
				"pos": Vector3(-18.0, 0.2, -56.0), "zone": "security_office",
				"what": "Return to Vrátnica, review CCTV (man enters garage side, never leaves), check the unlocked rear door after the 03:17 impact, and inspect the opened Key Cabinet.",
				"where": "Inside Security Office (Vrátnica).",
				"why": "Verify whether the intruder entered the security perimeter.",
				"action": "Inspect the Key Cabinet [E] or CCTV Monitor [E], then sign the Night 4 report at the desk [E].",
				"optional": "Keep the office steel door bolted [E] while reviewing feeds.",
				"triggers": ["office_key_cabinet", "booth_desk"],
			},
		],
		"optional_spots": [
			{"label": "Block B 8F Roof", "pos": Vector3(2.0, 0.2, 42.0)},
			{"label": "Garages West Entry", "pos": Vector3(-62.0, 0.2, -48.0)},
		],
	},
	5: {
		"shift_id": "SHIFT_05",
		"date": "22.11.1996",
		"title": "NIGHT 5 — BELOW THE ESTATE",
		"start_pos": Vector3(-15.8, 0.2, -54.5),
		"briefing": "Electrical fault reported in the Technical Area. Restore power at the Substation, enter the newly unlocked Hidden Service Corridor beneath the estate, document what happened to Iveta Hrončová, and find trace of Milan Švec.",
		"checkpoints": [
			{
				"id": "n5_cp1_substation", "num": 1, "name": "SUBSTATION POWER RESTORATION",
				"pos": Vector3(-68.5, 0.2, -11.0), "zone": "technical_area",
				"what": "Walk to the Electrical Substation (Trafostanica), inspect the power cabinet, and restore the tripped basement maintenance circuit.",
				"where": "Follow the western service road north past the Garages to the brick Substation.",
				"why": "Restoring power unlocks the electromagnetic door to the hidden sub-basement corridor.",
				"action": "Reset the Substation Main Breakers [E].",
				"optional": "Recover the 1984 Municipal Housing Register on the substation table.",
				"triggers": ["arcade_fusebox", "pickup_doc_registry"],
			},
			{
				"id": "n5_cp2_corridor", "num": 2, "name": "HIDDEN SERVICE CORRIDOR & PLAN 47",
				"pos": Vector3(-74.0, -4.4, -20.0), "zone": "technical_area",
				"what": "Enter Boiler House (Kotolňa), descend the stairs, and enter the newly unlocked north Hidden Service Corridor; recover the 1984 plan and maintenance key for 'Apartment 47'.",
				"where": "Just south of Trafostanica inside the Boiler House -> subterranean stairs -> north steel door.",
				"why": "Uncover how the intruder accesses locked buildings unseen through an undocumented maintenance passage.",
				"action": "Inspect the 1984 Hidden Service Plan & Maintenance Key [E].",
				"optional": "Collect the 1986 Sealed Corridor Schematic & Archive Cassette #05 in the boiler tunnel.",
				"triggers": ["n5_hidden_plan_47", "pickup_doc_sealed"],
			},
			{
				"id": "n5_cp3_iveta", "num": 3, "name": "STORAGE ALCOVE — IVETA HRONČOVÁ",
				"pos": Vector3(-82.0, -4.4, -15.5), "zone": "technical_area",
				"what": "Enter the isolated storage section off the hidden corridor. Respectfully examine missing resident Iveta Hrončová, her belongings, damaged telephone, and document, then record an incident report.",
				"where": "West storage bay inside the Hidden Service Corridor.",
				"why": "Major turning point: confirm the fate of missing resident Iveta Hrončová and secure legal evidence.",
				"action": "Inspect Iveta Hrončová's scene & evidence [E] to document the discovery safely.",
				"optional": "Note the damaged telephone handset and dropped housing document.",
				"triggers": ["n5_iveta_discovery"],
			},
			{
				"id": "n5_cp4_milan", "num": 4, "name": "MILAN ŠVEC'S RADIO & TAPE",
				"pos": Vector3(-86.0, -4.4, -18.5), "zone": "technical_area",
				"what": "Inspect Milan Švec's discarded security radio and fresh cassette at the far end of the hidden corridor. Watch the human figure flee through the physical service door.",
				"where": "North-west alcove of the Hidden Service Corridor.",
				"why": "Fresh evidence suggests Milan Švec may still be alive inside the sealed Apartment 47 maintenance room.",
				"action": "Inspect Milan's radio & fresh tape [E].",
				"optional": "Check the physical steel escape door the intruder used.",
				"triggers": ["n5_milan_radio", "pickup_tape_05"],
			},
			{
				"id": "n5_cp5_return", "num": 5, "name": "RETURN TO OFFICE & CONFRONT VARGA",
				"pos": Vector3(-18.0, 0.2, -56.0), "zone": "security_office",
				"what": "Climb back to the surface, return to Vrátnica, confront Varga via phone/radio, and file Night 5 report.",
				"where": "Follow the western service road south to Security Office.",
				"why": "Prepare your evidence dossier before your final night shift.",
				"action": "Use the Security Office telephone [E] and Desk Logbook [E].",
				"optional": "Collect spare 4.5V batteries before Night 6.",
				"triggers": ["booth_phone", "booth_desk"],
			},
		],
		"optional_spots": [
			{"label": "Substation Register", "pos": Vector3(-69.0, 0.2, -15.6)},
			{"label": "Bunker K-4 Bulkhead", "pos": Vector3(-76.0, -4.4, -32.0)},
		],
	},
	6: {
		"shift_id": "SHIFT_06",
		"date": "23.11.1996",
		"title": "NIGHT 6 — THE LAST PATROL",
		"start_pos": Vector3(-15.8, 0.2, -54.5),
		"briefing": "Varga's briefing is strangely short. Residents are absent, the estate is dead quiet, and at 03:17 complete blackout strikes. Survive Roman Král's pursuit, reach the hidden Apartment 47 service room, and determine how your shift ends.",
		"checkpoints": [
			{
				"id": "n6_cp1_prep", "num": 1, "name": "FINAL BRIEFING & PREPARATION",
				"pos": Vector3(-18.0, 0.2, -56.0), "zone": "security_office",
				"what": "Take Varga's terse call, verify your keys, batteries, CCTV feeds, and collected evidence in the Notebook.",
				"where": "Inside Security Office (Vrátnica).",
				"why": "Prepare for the final shift — power and lighting may not hold past 03:00.",
				"action": "Answer the Security Office phone [E] or check CCTV [E].",
				"optional": "Verify you have collected >=4 pieces of evidence if aiming to expose the truth.",
				"triggers": ["booth_phone", "booth_cctv"],
			},
			{
				"id": "n6_cp2_warning", "num": 2, "name": "SILENT PATROL & 01:30 WARNING",
				"pos": Vector3(0.0, 0.2, 2.0), "zone": "central_park",
				"what": "Walk into the eerily empty Central Park. Receive the 01:30 unknown radio transmission: 'Nechodíš sám.'",
				"where": "Central Park plaza — dark apartments, absent residents, thick fog.",
				"why": "Check why every resident has vanished from the courtyards.",
				"action": "Check Central Park well/radio point [E] (or reach Central Park during Night 6).",
				"optional": "Return briefly to Vrátnica CCTV to spot Roman near the hidden service corridor.",
				"triggers": ["n6_radio_warning", "clock_well", "elena_payphone"],
			},
			{
				"id": "n6_cp3_apt47", "num": 3, "name": "03:17 BLACKOUT — APARTMENT 47 ROOM",
				"pos": Vector3(-84.0, -4.4, -12.0), "zone": "technical_area",
				"what": "During the 03:17 complete estate blackout, evade Roman Král through physical doors and reach the hidden Apartment 47 maintenance room off the subterranean corridor.",
				"where": "Boiler House -> Hidden Service Corridor -> Unmarked Door 47 Maintenance Room (or Building B Door 47).",
				"why": "Discover exhausted Milan Švec alive and uncover the final truth behind Apartment 47.",
				"action": "Open the Hidden Apartment 47 room [E] to find Milan Švec and decide whether to rescue him or expose the case.",
				"optional": "You can use locked doors [L] and dark corners to break Roman Král's line of sight.",
				"triggers": ["n6_milan_rescue", "door_47_int"],
			},
			{
				"id": "n6_cp4_ending", "num": 4, "name": "FINAL RESOLUTION (05:00–06:00)",
				"pos": Vector3(-18.0, 0.2, -56.0), "zone": "security_office",
				"what": "Resolve Night 6 via your chosen path: Lock Vrátnica & contact Police (Ending A: Morning Report), Escort Milan to the Outer Service Gate (Ending B: The Last Patrol), or File Routine Report (Ending C: The Next Guard).",
				"where": "Security Office Desk (Ending A / C) OR Outer Service Gate at Main Gate / North Gate (Ending B).",
				"why": "Bring the six-night investigation at Sídlisko Javor to its conclusion.",
				"action": "Interact with the Security Office Desk [E] or Outer Service Gate [E] to conclude your shift.",
				"optional": "All three endings depend on your discovered evidence, Milan rescue, and final choice.",
				"triggers": ["booth_desk", "main_gate", "n6_escape_gate"],
			},
		],
		"optional_spots": [
			{"label": "Outer Service Escape Gate", "pos": Vector3(0.0, 0.2, -68.5)},
			{"label": "Building B Door 47", "pos": Vector3(6.8, 0.2, 41.2)},
		],
	},
}

var visited_checkpoints: Dictionary = {}   # cp_id -> true
var completed_checkpoints: Dictionary = {} # cp_id -> timestamp String
var completed_tutorial_steps: Array[String] = []


func _gs() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("GameState") if ml is SceneTree else null


func _st() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("StoryManager") if ml is SceneTree else null


func _au() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("AudioSynth") if ml is SceneTree else null


func get_route(night_num: int = -1) -> Dictionary:
	var gs := _gs()
	var n: int = (gs.current_night if gs else 1) if night_num < 1 else clampi(night_num, 1, 6)
	return PATROL_ROUTES.get(n, PATROL_ROUTES[1])


func get_checkpoints(night_num: int = -1) -> Array:
	var rt: Dictionary = get_route(night_num)
	return rt.get("checkpoints", [])


func get_active_checkpoint(night_num: int = -1) -> Dictionary:
	var cps: Array = get_checkpoints(night_num)
	for cp_var in cps:
		var cp: Dictionary = cp_var
		var cid: String = str(cp.get("id", ""))
		if not is_checkpoint_completed(cid):
			return cp
	return cps[cps.size() - 1] if not cps.is_empty() else {}


func is_checkpoint_visited(cp_id: String) -> bool:
	return bool(visited_checkpoints.get(cp_id, false)) or is_checkpoint_completed(cp_id)


func is_checkpoint_completed(cp_id: String) -> bool:
	return completed_checkpoints.has(cp_id)


func get_completion_progress(night_num: int = -1) -> Dictionary:
	var cps: Array = get_checkpoints(night_num)
	var done_cnt: int = 0
	for cp_var in cps:
		var cp: Dictionary = cp_var
		if is_checkpoint_completed(str(cp.get("id", ""))):
			done_cnt += 1
	return {"done": done_cnt, "total": cps.size(), "all_done": (done_cnt >= cps.size() and cps.size() > 0)}


func are_field_checkpoints_done(night_num: int = -1) -> bool:
	# Checks if all checkpoints except the final return-to-office / resolution step are completed
	var cps: Array = get_checkpoints(night_num)
	if cps.size() <= 1:
		return true
	for i: int in range(cps.size() - 1):
		var cp: Dictionary = cps[i]
		if not is_checkpoint_completed(str(cp.get("id", ""))):
			return false
	return true


func check_player_proximity(player_pos: Vector3, night_num: int = -1) -> Dictionary:
	var gs := _gs()
	var n: int = (gs.current_night if gs else 1) if night_num < 1 else clampi(night_num, 1, 6)
	var cps: Array = get_checkpoints(n)
	for cp_var in cps:
		var cp: Dictionary = cp_var
		var cid: String = str(cp.get("id", ""))
		if is_checkpoint_visited(cid):
			continue
		var cpos: Vector3 = cp.get("pos", Vector3.ZERO)
		if player_pos.distance_to(cpos) <= 6.2:
			visited_checkpoints[cid] = true
			sync_to_game_state()
			emit_signal("checkpoint_visited", n, cid)
			return cp
	return {}


func register_interaction(interact_id: String, night_num: int = -1) -> Array[Dictionary]:
	var gs := _gs()
	var n: int = (gs.current_night if gs else 1) if night_num < 1 else clampi(night_num, 1, 6)
	var completed_now: Array[Dictionary] = []
	var cps: Array = get_checkpoints(n)
	for cp_var in cps:
		var cp: Dictionary = cp_var
		var cid: String = str(cp.get("id", ""))
		if is_checkpoint_completed(cid):
			continue
		var triggers: Array = cp.get("triggers", [])
		if interact_id in triggers:
			# Prevent completing the final return-to-office checkpoint before at least 1 field checkpoint is done (unless it's Night 6 resolution)
			var is_last: bool = (cid == str((cps[cps.size() - 1] as Dictionary).get("id", "")))
			if is_last and not are_field_checkpoints_done(n) and interact_id in ["booth_desk", "booth_phone"]:
				continue
			if complete_checkpoint(cid, n):
				completed_now.append(cp)
	return completed_now


func complete_checkpoint(cp_id: String, night_num: int = -1) -> bool:
	if cp_id.is_empty() or is_checkpoint_completed(cp_id):
		return false
	var gs := _gs()
	var n: int = (gs.current_night if gs else 1) if night_num < 1 else clampi(night_num, 1, 6)
	visited_checkpoints[cp_id] = true
	var ts: String = gs.get_clock_time_only() if gs and gs.has_method("get_clock_time_only") else "23:00"
	completed_checkpoints[cp_id] = ts
	if gs:
		gs.advance_shift_time(42)
		var cp_data: Dictionary = _find_cp(cp_id, n)
		var cname: String = str(cp_data.get("name", cp_id))
		gs.add_notebook_entry("PATROL CHECKPOINT %d" % int(cp_data.get("num", 1)), "Inspected & verified: %s." % cname, cname)
	var au := _au()
	if au and au.has_method("play_sfx"):
		au.play_sfx("pencil_check", -7.0, randf_range(0.96, 1.04))
	if n == 1:
		complete_tutorial_step("checkpoint")
	sync_to_game_state()
	emit_signal("checkpoint_completed", n, cp_id)
	var prog: Dictionary = get_completion_progress(n)
	if bool(prog.get("all_done", false)):
		emit_signal("route_completed", n)
	return true


func _find_cp(cp_id: String, night_num: int) -> Dictionary:
	for cp_var in get_checkpoints(night_num):
		var cp: Dictionary = cp_var
		if str(cp.get("id", "")) == cp_id:
			return cp
	return {}


# ---------------------------------------------------------------------------
# Interactive First-Time Onboarding Checklist (Part 13.2)
# ---------------------------------------------------------------------------
func complete_tutorial_step(step_id: String) -> bool:
	var gs := _gs()
	if gs and gs.tutorial_completed:
		return false
	if step_id.is_empty() or (step_id in completed_tutorial_steps):
		return false
	completed_tutorial_steps.append(step_id)
	var next_step: Dictionary = get_next_tutorial_step()
	if next_step.is_empty():
		if gs:
			gs.mark_tutorial_completed()
		emit_signal("tutorial_step_completed", step_id, "Orientation complete — follow your Notebook Map for tonight's patrol.")
	else:
		emit_signal("tutorial_step_completed", step_id, str(next_step.get("hint", "")))
	sync_to_game_state()
	return true


func get_next_tutorial_step() -> Dictionary:
	var gs := _gs()
	if gs and gs.tutorial_completed:
		return {}
	for st_item: Dictionary in TUTORIAL_STEPS:
		var sid: String = str(st_item.get("id", ""))
		if not (sid in completed_tutorial_steps):
			return st_item
	return {}


func is_tutorial_step_done(step_id: String) -> bool:
	var gs := _gs()
	return (gs != null and gs.tutorial_completed) or (step_id in completed_tutorial_steps)


# ---------------------------------------------------------------------------
# Persistence into GameState.story_flags (100% SaveManager compatible!)
# ---------------------------------------------------------------------------
func reset_all_progress() -> void:
	visited_checkpoints.clear()
	completed_checkpoints.clear()
	completed_tutorial_steps.clear()
	sync_to_game_state()


func sync_to_game_state() -> void:
	var gs := _gs()
	if not gs:
		return
	gs.story_flags["patrol_visited_cps"] = visited_checkpoints.duplicate(true)
	gs.story_flags["patrol_completed_cps"] = completed_checkpoints.duplicate(true)
	gs.story_flags["patrol_tutorial_steps"] = completed_tutorial_steps.duplicate()


func load_from_game_state() -> void:
	var gs := _gs()
	if not gs:
		return
	visited_checkpoints.clear()
	completed_checkpoints.clear()
	completed_tutorial_steps.clear()
	var v: Variant = gs.story_flags.get("patrol_visited_cps", {})
	if v is Dictionary:
		for k in (v as Dictionary).keys():
			visited_checkpoints[str(k)] = bool(v[k])
	var c: Variant = gs.story_flags.get("patrol_completed_cps", {})
	if c is Dictionary:
		for k in (c as Dictionary).keys():
			completed_checkpoints[str(k)] = str(c[k])
	var ts: Variant = gs.story_flags.get("patrol_tutorial_steps", [])
	if ts is Array:
		for s in (ts as Array):
			completed_tutorial_steps.append(str(s))
