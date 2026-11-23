extends Node

signal story_flag_changed(flag_name: String, value: Variant)
signal document_discovered(doc_id: String)
signal tape_discovered(tape_id: String)
signal resident_note_added(char_id: String)
signal chapter_changed(night_num: int)
signal night_climax_triggered(night_num: int, event_id: String)

const CHARACTERS := {
	"varga": {
		"name": "Jozef Varga",
		"age": 51,
		"role": "Security Supervisor — Javor Estate",
		"location": "Radio / Security Office Phone",
		"personality": "Calm, bureaucratic, practical, evasive about former guard Milan Švec.",
		"dialogues": {
			1: "Martin? Varga here. Your full patrol orders and equipment guide are written inside your shift notebook [TAB/N] — use mouse wheel or keys [0–6] to switch between empty hands, flashlight [F], keyring [L to lock/unlock], radio, and Walkman headphones [H]. Check the entrances, stop by the Trafika window and Večierka, patrol the park, and log anything unusual in writing.",
			2: "Noise complaint came in from Building A — footsteps above an empty flat. Probably pipes or teenagers. Check the northern entrance and keep the log brief.",
			3: "Listen carefully, Martin. Leave the old 1984 maintenance binders where they are. Your contract covers gates and locks, not archives.",
			4: "A tripping stairwell breaker in Building B is normal in November rain. Do not ride the service elevator if the floor indicator acts up.",
			5: "Alright... yes, Milan filed two unusual incident reports before he quit. Both mentioned the same unlisted flat number. We sealed the sub-basement hallway for safety — restore the breaker and come back upstairs.",
			6: "Martin... if the estate grid drops around three, stay at the desk. Finish the shift log and I'll have your paperwork cleared by morning."
		}
	},
	"anna": {
		"name": "Anna Krížanová",
		"age": 68,
		"role": "Resident — Apartment Building A",
		"location": "Building A Courtyard Entrance",
		"personality": "Observant, direct, remembers the estate's 1980s construction and Milan Švec.",
		"dialogues": {
			1: "You're the new boy on night watch? Martin, is it? Good. Keep your torch aimed low near the bushes. The lamps near Building B have been dying all autumn.",
			2: "Nobody has lived in the flat above me since 1991, Martin. Yet twice this week I heard slow boots crossing the linoleum right at midnight. Milan asked about the old registry before he left.",
			3: "Wait — show me that name on the maintenance slip. That was the architect who drafted the 1984 addendum for Building B. Everyone pretends unit 47 was struck off the plan.",
			4: "You told me yesterday the stairwell lamp was fixed? No, dear, that lamp's been shattered since October. Look closely at what you write down.",
			5: "Milan left a folded note under my radiator before his last shift. He told me: 'If someone knocks and uses your name from the landing, stay quiet until sunrise.'",
			6: "(Building A's bench stands empty in the cold rain. Anna's wool scarf lies neatly folded on the damp slat.)"
		}
	},
	"dana": {
		"name": "Dana Bieliková",
		"age": 39,
		"role": "Shopkeeper — Večierka Night Shop",
		"location": "Večierka Night Shop (Commercial Square)",
		"personality": "Practical, friendly, exhausted, watches nighttime movement across the square.",
		"dialogues": {
			1: "Evening! You must be Martin — Varga mentioned a new guard. Coffee's burnt, batteries are behind the counter if your torch dies. Quiet estate mostly, just wet.",
			2: "Milan used to buy AA cells for his Walkman right here every Tuesday. Last time I saw him, he kept looking over his shoulder toward Building B's fifth floor.",
			3: "Strange thing — around two in the morning someone stood under the awning outside without coming in. Wearing a guard coat, just like yours. Thought it was you until I saw your torch across the park.",
			4: "Power's been dipping behind my fridges all evening. If you check the substation, tell Varga the compressor won't survive another blackout.",
			5: "I found an unlabeled cassette wedged behind the delivery crate by the alley. Has Milan's handwriting on the spine — take it before the rain ruins the tape.",
			6: "(The Večierka shutters are pulled halfway down. A flickering fluorescent tube hums over an empty counter.)"
		}
	},
	"milan": {
		"name": "Milan Švec",
		"age": 44,
		"role": "Former Night Security Guard (Missing)",
		"location": "Garage Complex / Notebooks & Tapes / Sub-Basement",
		"personality": "Methodical, worn down by sleepless shifts, left warnings in margins and cassettes.",
		"dialogues": {
			1: "(Margin note in worn blue ink: 'Check Building B intercom panel twice. Ignore static on 50.4 Hz.')",
			2: "(Torn patrol card: 'Someone answered the buzzer from 47. The panel only goes to 46.')",
			3: "(Cassette playback — Milan's quiet voice: 'If you hear your own name from the corridor, do not answer. Keep the Walkman tape rolling if you must, just don't answer.')",
			4: "(Scratched inside stairwell frame: 'FLOOR 4½ — DOOR 47 ONLY STAYS WHEN YOU DON'T TURN BACK.')",
			5: "(Final basement recording: 'They sealed the corridor in 1986, Martin — wait... why did I just say your name? Who's taking the next shift?')",
			6: "You found the sealed register, Martin. Now decide: file the report and walk out at dawn... open Door 47... or sit back down at Varga's desk."
		}
	},
	"peter": {
		"name": "Peter",
		"age": 12,
		"role": "Local Child — Sídlisko Javor",
		"location": "Central Park Playground",
		"personality": "Quiet, matter-of-fact, notices shadows inside dark stairwells without dramatics.",
		"dialogues": {
			1: "Hey mister... the swing on the left moves even when the pines aren't blowing.",
			2: "I saw somebody standing inside the dark entrance of Building C earlier. They didn't have a dog or groceries. They were just waiting for the light to go off.",
			3: "My dad says there's no apartment 47 in Building B, but the buzzer plate had a scratched sticker under the glass.",
			4: "Why did you wave at me from the fifth-floor window ten minutes ago? You were downstairs by the garages.",
			5: "Everybody's closing their blinds early tonight. You can hear humming through the manhole grates.",
			6: "(The playground swing rocks gently in the dark rain. Nobody is there.)"
		}
	},
	"zuzana": {
		"name": "Zuzana Horváthová",
		"age": 46,
		"role": "Newsstand Vendor — Trafika",
		"location": "Trafika Newsstand (Commercial Square)",
		"personality": "Sharp-eyed, blunt, keeps the small service window cracked for late shifts, knows every face on the estate.",
		"dialogues": {
			1: "New night watchman? Good, the fog's thick enough to slice tonight. Keep your notebook handy — nobody reminds you twice out here. Stop by the window anytime if you want to know who passed through the square.",
			2: "Strange buyer stopped by at twenty past ten asking for 1984 municipal phone directories. Wore a dark maintenance coat and headed straight toward the garages.",
			3: "Milan used to buy his morning paper right at six sharp. Two mornings before he disappeared he handed me an envelope for the housing office and told me not to drop it in Building B's slot.",
			4: "Someone tried the side shutter latch on my kiosk around midnight when the streetlamp flickered out. When I switched the heater off and listened, boots walked away into the fog toward Block F.",
			5: "I'm closing early tonight, Martin. The fluorescent tube keeps dipping and I heard knocking inside the empty newsstand storage wall — right above the old heating ducts.",
			6: "(The Trafika metal shutter is rolled halfway down. Yesterday's Nový Čas flutters damply in the wire rack outside.)"
		}
	},
	"roman": {
		"name": "Roman Král",
		"age": 46,
		"role": "Former Estate Maintenance Worker (Suspect)",
		"location": "Maintenance Corridors / Garages / Hidden Service Route",
		"personality": "Quiet, methodical, knows every service lock and sub-basement passage in Sídlisko Javor.",
		"dialogues": {
			1: "(Observed briefly in the distance wearing a dark brown maintenance jacket — avoided eye contact and turned behind the garages.)",
			2: "(Fresh muddy boot prints and cigarette butts left along Building C's stairwell and the northern perimeter path.)",
			3: "(Caught on CCTV crossing the courtyard in old maintenance clothing at an unusual timestamp.)",
			4: "(Spotted near Building B stairwell — turned calmly and walked away through a real utility corridor door.)",
			5: "(Silhouette fled down the subterranean hidden service corridor past Iveta Hrončová's storage alcove.)",
			6: "(Actively patrolling the blacked-out estate with utility keys, checking doors and listening for your footsteps.)"
		}
	},
	"iveta": {
		"name": "Iveta Hrončová",
		"age": 34,
		"role": "Missing Resident — Sídlisko Javor",
		"location": "Hidden Subterranean Service Storage Section",
		"personality": "Reported missing earlier in November 1996 after investigating unauthorized maintenance access.",
		"dialogues": {
			1: "(Missing person notice pinned weakly inside Building A's lobby notice board.)",
			2: "(Neighbors mention Iveta vanished without taking her suitcase or winter coat.)",
			3: "(Milan's tape warns that someone followed residents along the rear service paths.)",
			4: "(Small trace near Block F basement door suggests someone was dragged through a lower lock.)",
			5: "(Discovered respectfully in the isolated storage bay off the hidden service corridor beside her handbag, damaged telephone, and housing document.)",
			6: "(Her documented evidence and damaged telephone remain logged inside your shift notebook.)"
		}
	}
}

const CHAPTERS := {
	1: {
		"night": 1,
		"date": "11.11.1996",
		"title_key": "ch_1_title",
		"sub_key": "ch_1_sub",
		"art": "res://assets/graphics/chapters/chapter_night_1.png",
		"summary": "Your first night shift at Sídlisko Javor. Collect the guard keys, inspect entrances, meet Dana and Anna, and finish the patrol log before dawn.",
		"climax_id": "night1_silent_phone",
		"climax_note": "When you hear your own name, do not answer.",
		"objectives": [
			{"id": "j1_keys_radio", "label": "Check Security Office desk drawer & answer Varga's radio check-in"},
			{"id": "j1_patrol_park", "label": "Inspect Building A entrance (Anna) & Central Park playground"},
			{"id": "j1_visit_dana", "label": "Check Parking Lot & visit Dana at Večierka Night Shop"},
			{"id": "j1_return_office", "label": "Return to Security Office desk & complete Night 1 Patrol Report"}
		]
	},
	2: {
		"night": 2,
		"date": "12.11.1996",
		"title_key": "ch_2_title",
		"sub_key": "ch_2_sub",
		"art": "res://assets/graphics/chapters/chapter_night_2.png",
		"summary": "A resident reports footsteps above a vacant flat. Speak with Anna, Dana, and Peter, inspect the northern stairwell, and answer the intercom.",
		"climax_id": "night2_intercom_47",
		"climax_note": "Intercom buzzed from APARTMENT 47 at 02:44. Building B directory ends at 46.",
		"objectives": [
			{"id": "j2_noise", "label": "Investigate noise complaint at Building A & speak to Anna"},
			{"id": "j2_playground", "label": "Check Central Park playground & talk to Peter"},
			{"id": "j2_dana", "label": "Visit Dana at Večierka about Milan Švec"},
			{"id": "j2_intercom", "label": "Inspect Building B intercom panel & file Night 2 report"}
		]
	},
	3: {
		"night": 3,
		"date": "13.11.1996",
		"title_key": "ch_3_title",
		"sub_key": "ch_3_sub",
		"art": "res://assets/graphics/chapters/chapter_night_3.png",
		"summary": "Security cameras catch a figure walking right behind you. Search the Garage Complex, recover Milan's cassette, and uncover the pre-shift recording.",
		"climax_id": "night3_own_voice_tape",
		"climax_note": "Tape #04 plays my own voice reading patrol times — timestamped 09.11.1996, two days before I was hired.",
		"objectives": [
			{"id": "j3_cctv", "label": "Review Security Office CCTV feeds for unauthorized movement"},
			{"id": "j3_garages", "label": "Find the old key & inspect Garage 03 and Garage 06"},
			{"id": "j3_milan_tape", "label": "Recover Milan's storage cassette & maintenance record"},
			{"id": "j3_report", "label": "Log the pre-shift recording incident in your Notebook"}
		]
	},
	4: {
		"night": 4,
		"date": "14.11.1996",
		"title_key": "ch_4_title",
		"sub_key": "ch_4_sub",
		"art": "res://assets/graphics/chapters/chapter_night_4.png",
		"summary": "Building B's elevator stops on unlisted floors, corridors stretch, and a door marked 47 appears on the stairwell landing — then vanishes.",
		"climax_id": "night4_vanishing_door_47",
		"climax_note": "Door marked '47' appeared on Building B's upper landing. Turned away for two seconds — bare plaster.",
		"objectives": [
			{"id": "j4_blockb", "label": "Inspect Building B elevator & 8F rooftop relay"},
			{"id": "j4_breaker", "label": "Investigate electrical failure at the Substation"},
			{"id": "j4_door47", "label": "Inspect the stairwell landing where Door 47 appears"},
			{"id": "j4_return", "label": "Return to Security Office & record floor anomalies"}
		]
	},
	5: {
		"night": 5,
		"date": "15.11.1996",
		"title_key": "ch_5_title",
		"sub_key": "ch_5_sub",
		"art": "res://assets/graphics/chapters/chapter_night_5.png",
		"summary": "Restore the failing sub-basement circuit, explore the maintenance tunnel beneath Sídlisko Javor, and uncover the sealed 1984 building plans.",
		"climax_id": "night5_disconnected_radio",
		"climax_note": "The unplugged desk radio called 'Martin Kováč' clearly through static. Battery pack wasn't even inserted.",
		"objectives": [
			{"id": "j5_substation", "label": "Restore tripped high-voltage circuit at Substation"},
			{"id": "j5_basement", "label": "Descend into the Boiler & Sub-Basement maintenance tunnel"},
			{"id": "j5_plans", "label": "Recover original 1984 Sealed Unit 47 building blueprints"},
			{"id": "j5_varga", "label": "Confront Jozef Varga by Security Office phone/radio"}
		]
	},
	6: {
		"night": 6,
		"date": "16.11.1996",
		"title_key": "ch_6_title",
		"sub_key": "ch_6_sub",
		"art": "res://assets/graphics/chapters/chapter_night_6.png",
		"summary": "At 03:17 the estate power drops. Residents are absent, CCTV fails, and the telephone rings relentlessly. Decide what to trust — and how your shift ends.",
		"climax_id": "night6_blackout_0317",
		"climax_note": "03:17 — Estate blackout. Every clock stopped except the phone ringing on the desk.",
		"objectives": [
			{"id": "j6_blackout", "label": "Endure the 03:17 Sídlisko Javor power interruption"},
			{"id": "j6_decide", "label": "Choose: File the Report (Office), Enter Apartment 47 (Building B), or Accept Next Shift"}
		]
	}
}

const DOCUMENTS := {
	"doc_patrol_order": {
		"title": "Shift Order #114 — Sídlisko Javor",
		"date": "11.11.1996",
		"source": "Jozef Varga, Security Office",
		"body": "GUARD: Martin Kováč (Temp. Contract)\nHOURS: 22:00 – 06:00\nROUTE: Office -> Parking -> Park -> Večierka -> Blocks A–F -> Garages.\nNOTE: Do not engage tenants after midnight unless noise persists. Report burned-out stairwell bulbs in writing. Ignore outdated maintenance doors in Building B."
	},
	"doc_registry_1984": {
		"title": "Municipal Housing Register — Building B (1984)",
		"date": "14.09.1984",
		"source": "Nový Brod Housing Office Archive",
		"body": "PANELÁK BLOCK B — 8 FLOORS — 46 REGISTERED UNITS (FLATS 1–46).\n[HANDWRITTEN MARGIN IN RED PENCIL]: Unit 47 bricked over per Technical Directive 84/K-4. Intercom relay line remains live in cellar junction box. Do not reissue keys."
	},
	"doc_milan_sheet": {
		"title": "Milan Švec — Torn Log Sheet #29",
		"date": "06.11.1996",
		"source": "Garage 03 Workbench",
		"body": "01:40 — Heard someone walking upstairs in Block C while all lights were dead.\n02:15 — CCTV-03 showed my own silhouette standing by the well while I was inside Vrátnica.\n03:17 — Buzzer rang: BYT 47. When you hear your own name, do not answer."
	},
	"doc_sealed_unit_47": {
		"title": "Sealed Corridor Schematic — Sub-Basement",
		"date": "22.10.1986",
		"source": "Boiler Plant Maintenance Tunnel",
		"body": "STRUCTURAL ADDENDUM: Service shaft connects Boiler Tunnel directly beneath Building B elevator pit. Acoustic resonance observed near 50.4 Hz during autumn humidity. Entry sealed by order of Municipal Directorate."
	},
	"doc_varga_memo": {
		"title": "Confidential Memo — Personnel Turnover",
		"date": "10.11.1996",
		"source": "Security Office Filing Cabinet",
		"body": "TO: District Property Board\nRE: Guard Replacement (Švec -> Kováč)\nMilan Švec failed to report after Shift 6. Recommend standard replacement contract with zero briefing on 1986 Building B addendum. Keep night watch continuous."
	}
}

const TAPES := {
	"tape_01_routine": {
		"label": "TAPE 01 — LATE SHIFT CASSETTE (SIDE A)",
		"date": "01.11.1996",
		"duration": "00:32",
		"source": "Martin's Walkman",
		"audio": "music_walkman_tape",
		"flag": "listened_tape_01",
		"transcript": "(Warm 1990s analog electric piano and soft cassette hiss. Halfway through the loop, a faint distant intercom tone bleeds underneath the bassline.)"
	},
	"tape_02_milan_shift": {
		"label": "TAPE 02 — MILAN'S PATROL LOG",
		"date": "05.11.1996",
		"duration": "00:18",
		"source": "Security Office Shelf / Garage 03",
		"audio": "voice_milan_n2",
		"flag": "listened_tape_02",
		"transcript": "MILAN ŠVEC: '02:10, rain again. Someone's standing behind the glass on the fifth floor of Building B. Same coat every night... If you find this tape, check the 1984 register.'"
	},
	"tape_03_stairwell": {
		"label": "TAPE 03 — BUILDING C STAIRWELL",
		"date": "07.11.1996",
		"duration": "00:15",
		"source": "Večierka Delivery Alley",
		"audio": "voice_maria_n3",
		"flag": "listened_tape_03",
		"transcript": "(Wet footsteps echo up concrete stairs, then stop abruptly. A low murmur repeats the number forty-seven beneath 50 Hz mains hum.)"
	},
	"tape_04_before_shift": {
		"label": "TAPE 04 — UNLABELED MAXELL C-60",
		"date": "09.11.1996",
		"duration": "00:21",
		"source": "Garage 06 Locked Stash",
		"audio": "voice_elena_payphone",
		"flag": "listened_tape_04",
		"transcript": "(Familiar melody dissolves into static. A voice matching Martin's own cadence reads patrol timestamps dated two days BEFORE his first shift — then whispers: 'When you hear your own name, do not answer.')"
	},
	"tape_05_unit_47": {
		"label": "TAPE 05 — SUB-BASEMENT ARCHIVE",
		"date": "10.11.1996",
		"duration": "00:24",
		"source": "Sub-Basement Boiler Corridor",
		"audio": "voice_jozef_bunker",
		"flag": "listened_tape_05",
		"transcript": "MILAN ŠVEC: 'The door is open at 03:17. Varga knows it never stays shut. Either file every page and walk out at dawn, step inside 47... or you'll still be sitting at that desk on Night 7.'"
	}
}

const JAVOR_ENDINGS := {
	"ENDING_A": {
		"code": "A",
		"title": "ENDING A — MORNING REPORT",
		"subtitle": "Evidence-Based Investigation",
		"body": "You gathered the physical evidence, locked the Security Office, contacted authorities, and completed the full incident report.\n\nAt 06:10, distant blue and red emergency vehicle lights cut through the thinning November fog. Sídlisko Javor slowly became visible in pale morning light. Inside the empty office, your open notebook rested under the desk lamp — several pages cleanly missing. The investigation had officially begun."
	},
	"ENDING_B": {
		"code": "B",
		"title": "ENDING B — THE LAST PATROL",
		"subtitle": "Survival & Rescue — Milan Švec",
		"body": "You unlocked the hidden Apartment 47 maintenance room, discovered former guard Milan Švec alive but severely exhausted, and guided him past Roman Král to the Outer Service Gate as dawn broke over Nový Brod.\n\nMilan warned that official records would never contain the complete truth. Then your VHF radio crackled with Jozef Varga's calm voice:\n\n\"Zmena ukončená. Vráťte sa do služby.\""
	},
	"ENDING_C": {
		"code": "C",
		"title": "ENDING C — THE NEXT GUARD",
		"subtitle": "SHIFT 01 / NOVEMBER 1996 (NIGHT 7)",
		"body": "You submitted a normal patrol report without exposing the hidden corridor and walked out into the quiet overcast morning.\n\nA short time later, the next temporary security guard enters Vrátnica. On the wooden desk lies a fresh notebook reading:\n\nSHIFT 01 — NOVEMBER 1996\n\nHe picks up the estate keys. The black rotary telephone begins to ring."
	}
}

var current_chapter: int = 1
var discovered_documents: Array[String] = ["doc_patrol_order"]
var discovered_tapes: Array[String] = ["tape_01_routine"]
var met_characters: Array[String] = ["varga"]
var resident_notes: Dictionary = {} # char_id -> Array[String]
var personal_notes: Array[String] = []
var story_flags: Dictionary = {}
var completed_story_objectives: Array[String] = []
var active_ending_id: String = ""
var blackout_active: bool = false


func reset_story() -> void:
	current_chapter = 1
	discovered_documents = ["doc_patrol_order"]
	discovered_tapes = ["tape_01_routine"]
	met_characters = ["varga"]
	resident_notes.clear()
	personal_notes = [
		"11.11.1996 22:00 — First temporary night shift at Sídlisko Javor. Rent is due Friday; keep it simple and finish the patrol."
	]
	story_flags.clear()
	completed_story_objectives.clear()
	active_ending_id = ""
	blackout_active = false
	emit_signal("chapter_changed", current_chapter)


func set_chapter(night_num: int) -> void:
	current_chapter = clampi(night_num, 1, 6)
	blackout_active = false
	emit_signal("chapter_changed", current_chapter)


func get_chapter_data(night_num: int = -1) -> Dictionary:
	var n := current_chapter if night_num < 1 else clampi(night_num, 1, 6)
	return CHAPTERS.get(n, CHAPTERS[1])


func set_flag(flag_name: String, val: Variant = true) -> void:
	story_flags[flag_name] = val
	emit_signal("story_flag_changed", flag_name, val)


func get_flag(flag_name: String, default_val: Variant = false) -> Variant:
	return story_flags.get(flag_name, default_val)


func complete_story_objective(obj_id: String) -> void:
	if obj_id.is_empty() or (obj_id in completed_story_objectives):
		return
	completed_story_objectives.append(obj_id)
	emit_signal("story_flag_changed", "obj_" + obj_id, true)


func is_story_objective_done(obj_id: String) -> bool:
	return obj_id in completed_story_objectives


func discover_document(doc_id: String) -> bool:
	if not DOCUMENTS.has(doc_id):
		return false
	if doc_id in discovered_documents:
		return false
	discovered_documents.append(doc_id)
	set_flag("found_" + doc_id, true)
	emit_signal("document_discovered", doc_id)
	return true


func discover_tape(tape_id: String) -> bool:
	if not TAPES.has(tape_id):
		return false
	if tape_id in discovered_tapes:
		return false
	discovered_tapes.append(tape_id)
	set_flag("found_" + tape_id, true)
	emit_signal("tape_discovered", tape_id)
	return true


func record_character_interaction(char_id: String, night_num: int = -1) -> Dictionary:
	if not CHARACTERS.has(char_id):
		return {}
	var n := current_chapter if night_num < 1 else clampi(night_num, 1, 6)
	if not (char_id in met_characters):
		met_characters.append(char_id)
	var cdata: Dictionary = CHARACTERS[char_id]
	var dlgs: Dictionary = cdata.get("dialogues", {})
	var line: String = str(dlgs.get(n, dlgs.get(1, "")))
	if not resident_notes.has(char_id):
		resident_notes[char_id] = []
	var note_entry := "Night %d: %s" % [n, line]
	if not (note_entry in resident_notes[char_id]):
		(resident_notes[char_id] as Array).append(note_entry)
		emit_signal("resident_note_added", char_id)
	set_flag("talked_%s_n%d" % [char_id, n], true)
	return {
		"speaker": str(cdata.get("name", char_id.capitalize())),
		"role": str(cdata.get("role", "")),
		"text": line,
	}


func add_personal_note(note_text: String) -> void:
	var clean := note_text.strip_edges()
	if clean.is_empty():
		return
	if not (clean in personal_notes):
		personal_notes.append(clean)


func trigger_night_climax(night_num: int = -1) -> Dictionary:
	var n := current_chapter if night_num < 1 else clampi(night_num, 1, 6)
	var ch: Dictionary = get_chapter_data(n)
	var cid: String = str(ch.get("climax_id", ""))
	var cnote: String = str(ch.get("climax_note", ""))
	set_flag("climax_" + cid, true)
	if not cnote.is_empty():
		add_personal_note("[NIGHT %d — UNEXPLAINED] %s" % [n, cnote])
	if n == 6:
		blackout_active = true
	emit_signal("night_climax_triggered", n, cid)
	return {"climax_id": cid, "note": cnote, "night": n}


func resolve_javor_ending(choice_id: String = "") -> Dictionary:
	var eid := "ENDING_C"
	if choice_id == "report" or (choice_id.is_empty() and discovered_documents.size() >= 3 and bool(get_flag("refused_voice", false))):
		eid = "ENDING_A"
	elif choice_id == "apartment_47" or (choice_id.is_empty() and bool(get_flag("entered_apartment_47", false))):
		eid = "ENDING_B"
	else:
		eid = "ENDING_C"
	active_ending_id = eid
	set_flag("ending_" + eid.to_lower(), true)
	return JAVOR_ENDINGS[eid]


func export_state() -> Dictionary:
	return {
		"current_chapter": current_chapter,
		"discovered_documents": discovered_documents.duplicate(),
		"discovered_tapes": discovered_tapes.duplicate(),
		"met_characters": met_characters.duplicate(),
		"resident_notes": resident_notes.duplicate(true),
		"personal_notes": personal_notes.duplicate(),
		"story_flags": story_flags.duplicate(true),
		"completed_story_objectives": completed_story_objectives.duplicate(),
		"active_ending_id": active_ending_id,
		"blackout_active": blackout_active,
	}


func import_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	current_chapter = clampi(int(data.get("current_chapter", 1)), 1, 6)
	discovered_documents.clear()
	for d in data.get("discovered_documents", ["doc_patrol_order"]):
		discovered_documents.append(str(d))
	discovered_tapes.clear()
	for t in data.get("discovered_tapes", ["tape_01_routine"]):
		discovered_tapes.append(str(t))
	met_characters.clear()
	for c in data.get("met_characters", ["varga"]):
		met_characters.append(str(c))
	resident_notes.clear()
	var rn: Variant = data.get("resident_notes", {})
	if rn is Dictionary:
		for k in (rn as Dictionary).keys():
			resident_notes[str(k)] = rn[k]
	personal_notes.clear()
	for pn in data.get("personal_notes", []):
		personal_notes.append(str(pn))
	story_flags.clear()
	var sf: Variant = data.get("story_flags", {})
	if sf is Dictionary:
		for k in (sf as Dictionary).keys():
			story_flags[str(k)] = sf[k]
	completed_story_objectives.clear()
	for obj in data.get("completed_story_objectives", []):
		completed_story_objectives.append(str(obj))
	active_ending_id = str(data.get("active_ending_id", ""))
	blackout_active = bool(data.get("blackout_active", false))
	emit_signal("chapter_changed", current_chapter)
