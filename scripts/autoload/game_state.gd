extends Node

signal quest_updated
signal state_changed
signal dialogue_requested(speaker: String, text: String, duration: float)
signal distortion_changed(new_value: float)
signal ending_triggered(ending_id: String)

const SAVE_RUN_PATH: String = "user://blok14_run.json"
const SAVE_META_PATH: String = "user://blok14_meta.json"

var current_night: int = 1
var shift_minutes: int = 0 # 0 = 22:00, 480 = 06:00
var hardcore_mode: bool = false
var flashlight_battery: float = 100.0
var spare_batteries: int = 1
var battery_swaps_this_night: int = 0
var equipped_slot: String = "flashlight"
var taser_charge: float = 100.0
var notebook_checked: Dictionary = {}
var sanity: float = 100.0
var headphones_on: bool = false
var collected_keys: Array[String] = []
var door_states: Dictionary = {}
var notebook_entries: Array[Dictionary] = []
var anomalies_stunned: int = 0
var visited_zones: Dictionary = {}
var inspected_cctv_cams: Array[int] = []
var picked_batteries_count: int = 0
var signal_distortion: float = 8.0
var player_spotted: bool = false
var current_ending: String = ""

var active_quests: Array[Dictionary] = []
var completed_quests: Array[String] = []
var quest_completion_times: Dictionary = {}
var previous_shifts_archive: Array[Dictionary] = []
var collected_pages: Array[String] = []
var collected_tapes: Array[String] = []
var evidence_items: Array[String] = []
var unlocked_doors: Array[String] = []
var tuned_radios: int = 0
var logged_anomalies_this_night: Array[String] = []
var cctv_anomalies_logged: int = 0
var tutorial_completed: bool = false

var story_flags: Dictionary = {}

# Persistent meta progression
var unlocked_endings: Array[String] = []
var discovered_anomalies: Array[String] = []
var unlocked_achievements: Array[String] = []
var ng_plus_unlocked: bool = false
var hardcore_unlocked: bool = false

const NIGHT_DATA: Dictionary = {
	1: {
		"date": "13.11.1995",
		"title_sk": "Prvá zmena — Orientácia",
		"title_en": "Night 1 — Orientation Shift",
		"briefing_speaker": "MR. KOVAC — ROTARY PHONE",
		"briefing": "Kovac here. Welcome to your Night 1 orientation across the Residential District. Pick up the spare 4.5V battery on the Security Office shelf and reload [R], test your Stun Taser [2 + LMB], patrol our core zones (Parking Lot, Central Park, Commercial Square, Concrete Garages), stamp 3 Watchman's Clocks, check off any anomaly in your Field Notebook [TAB/N], and inspect all 6 CCTV feeds.",
		"ambient_fog": 0.014,
		"base_distortion": 6.0,
		"quests": [
			{"id": "answer_briefing", "label": "Answer Security Office rotary phone (Kovac's orientation)", "required": true},
			{"id": "tut_pick_battery", "label": "Pick up a 4.5V Battery Pack and reload gear [R]", "required": true},
			{"id": "tut_test_taser", "label": "Equip Stun Taser [2] and test-fire an arc [LMB]", "required": true},
			{"id": "tut_tour_zones", "label": "Patrol 4 district zones (Parking, Central Park, Shops, Garages)", "required": true},
			{"id": "stamp_clocks", "label": "Stamp any 3 patrol Watchman's Clocks across the district", "required": true},
			{"id": "tut_log_anomaly", "label": "Spot a physical anomaly & check it off in Field Notebook [TAB/N]", "required": true},
			{"id": "check_cctv_n1", "label": "Inspect all 6 CCTV camera feeds in Security Office", "required": true},
			{"id": "find_page_1", "label": "Optional: Collect Jozef's Torn Page #1 on Office Shelf", "required": false}
		]
	},
	2: {
		"date": "14.11.1995",
		"title_sk": "Výpalné a šum",
		"title_en": "Racket & Static",
		"briefing_speaker": "MR. KOVAC — ROTARY PHONE",
		"briefing": "Storm's rolling in. At 01:00 a white Mercedes van backs into the gate for a private delivery — stay inside the Guard Booth and look the other way. Also reset the tripped Arcade Passage fusebox, lock the Notary Office, and chase out any trespassers hiding near the attic stairs.",
		"ambient_fog": 0.045,
		"base_distortion": 14.0,
		"quests": [
			{"id": "answer_briefing", "label": "Answer Kovac's briefing call in Guard Booth", "required": true},
			{"id": "delivery_0100", "label": "Handle the 01:00 White Van Delivery at Main Gate", "required": true},
			{"id": "reset_fusebox", "label": "Reset tripped main fusebox in Arcade Passage", "required": true},
			{"id": "check_notary", "label": "Secure Notary Office door & printer in Arcade Passage", "required": true},
			{"id": "confront_milan", "label": "Investigate trash alcove trespasser (Milan 'The Mole')", "required": true},
			{"id": "stamp_all_n2", "label": "Complete full Watchman's Clock round (Gate, Well, Gallery, Boiler)", "required": true},
			{"id": "check_maria_n2", "label": "Optional: Check on Mrs. Maria at Flat 4", "required": false}
		]
	},
	3: {
		"date": "15.11.1995",
		"title_sk": "Mŕtvy kanál",
		"title_en": "Dead Channel",
		"briefing_speaker": "MR. KOVAC — STATIC LINE",
		"briefing": "Marek... ignore whatever garbage shows up on Camera 2 tonight — coaxial crosstalk, nothing more. Climb up to the rooftop STA antenna mast and inspect the splitter. Pull breakers on any howling TVs in the flats, and stay out of old Maria's business.",
		"ambient_fog": 0.056,
		"base_distortion": 24.0,
		"quests": [
			{"id": "answer_briefing", "label": "Answer Kovac's briefing call in Guard Booth", "required": true},
			{"id": "inspect_cam2_1953", "label": "Inspect CCTV CAM-02 feed in Guard Booth", "required": true},
			{"id": "climb_sta_roof", "label": "Climb to Attic & inspect STA Rooftop Antenna Mast", "required": true},
			{"id": "silence_tv_bleed", "label": "Investigate & silence dead-channel TV bleed in Flat 7", "required": true},
			{"id": "answer_payphone_n3", "label": "Answer the unplugged Arcade Payphone", "required": true},
			{"id": "stamp_all_n3", "label": "Complete full Watchman's Clock round", "required": true},
			{"id": "help_maria_n3", "label": "Optional: Deliver heart drops to Mrs. Maria (Flat 4)", "required": false},
			{"id": "elena_film_n3", "label": "Optional: Inspect Watchmaker's Grandfather Clock", "required": false}
		]
	},
	4: {
		"date": "16.11.1995",
		"title_sk": "Kotolňa a katakomby",
		"title_en": "Boiler Room & Catacombs",
		"briefing_speaker": "MR. KOVAC — URGENT CALL",
		"briefing": "Boiler pressure is red-lining! Get down to the Boiler Room and bleed the steam valve before the pipes blow. Hruska's enforcers Brano and Igor are coming down tonight to clear storage. Stay clear of them — and stay out of the Red Iron Door!",
		"ambient_fog": 0.062,
		"base_distortion": 36.0,
		"quests": [
			{"id": "answer_briefing", "label": "Answer Kovac's urgent call in Guard Booth", "required": true},
			{"id": "bleed_boiler_valve", "label": "Bleed steam pressure valve in Boiler Room", "required": true},
			{"id": "handle_mobsters_n4", "label": "Resolve Brano & Igor encounter in Boiler Room", "required": true},
			{"id": "breach_red_door", "label": "Unlock the Red Iron Door & enter Bunker K-4", "required": true},
			{"id": "inspect_device_k4", "label": "Inspect Device K-4 & find Jozef inside the bunker", "required": true},
			{"id": "recover_dossier_n4", "label": "Optional: Recover Elena Kralova's dossier behind wet concrete", "required": false}
		]
	},
	5: {
		"date": "17.11.1995",
		"title_sk": "Posledné vysielanie",
		"title_en": "The Final Broadcast",
		"briefing_speaker": "MR. KOVAC — BROKEN LINE",
		"briefing": "You broke the cellar seal, Dvorak. Hruska knows. He's bringing 50,000 Deutschmarks and armed men at midnight. Either lock the gate and sign 'I saw nothing' — or survive until 06:00 and decide what happens to Block 14.",
		"ambient_fog": 0.072,
		"base_distortion": 50.0,
		"quests": [
			{"id": "answer_briefing", "label": "Listen to Kovac's final ultimatum", "required": true},
			{"id": "decide_maria_n5", "label": "Check Flat 4 — Mrs. Maria's fate", "required": true},
			{"id": "final_confrontation", "label": "Make your final stand (Booth / Roof / Bunker K-4 / Gate)", "required": true}
		]
	},
	6: {
		"date": "17.11.1953",
		"title_sk": "Páska 00: Archív",
		"title_en": "Tape 00: Archive (1953 Time-Slip)",
		"briefing_speaker": "TAPE 00 — ARCHIVAL REEL",
		"briefing": "November 17, 1953. The plaster is fresh. Secret police technicians are preparing to seal the medieval well under K-4. Reach the sub-cellar core and disconnect the copper grounding bus before the 42-year signal locks in.",
		"ambient_fog": 0.025,
		"base_distortion": 75.0,
		"quests": [
			{"id": "descend_1953", "label": "Descend through the 1953 Courtyard into Bunker K-4", "required": true},
			{"id": "ground_k4_origin", "label": "Pull the copper grounding bus on Device K-4", "required": true},
			{"id": "exit_dawn_gate", "label": "Walk out through the Main Carriage Gate into morning", "required": true}
		]
	}
}

const ENDINGS_DATA: Dictionary = {
	"A": {
		"title_sk": "Nevidel som nič",
		"title_en": "Ending A — I Saw Nothing",
		"subtitle": "Complicit Survival",
		"text": "You took Hruska's envelope, locked the booth curtains, and signed 'Shift Quiet' at 06:00. Weeks later, bulldozers flattened Block 14 into a muddy pit for a new bank. Your debts are paid and your new flat is warm — yet every night at exactly 02:14, your television clicks itself to Channel 3, showing an empty cobblestone courtyard waiting for your patrol."
	},
	"B": {
		"title_sk": "Ranné správy",
		"title_en": "Ending B — Morning News",
		"subtitle": "The Whistleblower",
		"text": "Mrs. Maria slipped safely into the dawn fog with Milan 'The Mole' while you cut the STA rooftop amplifier and escaped past Hruska's men carrying Elena's film, plate log, and dossier. By noon, national radio broke the privatization murder scandal. Demolition was halted. Mr. Kovac vanished without a trace — and in the newspaper photo of the cellar stairs, one extra silhouette still waves from behind the dark glass."
	},
	"C": {
		"title_sk": "Vypnutý prúd",
		"title_en": "Ending C — Power Cut",
		"subtitle": "Martyr / Destruction",
		"text": "With boiler valves jammed at maximum pressure and Device K-4 shorted across the well main, superheated steam ripped through the Boiler Room just as Hruska's crew forced the Red Iron Door. Limestone vaults collapsed inward, burying the 1953 vault and the smuggled crates alike. When fire crews cleared the smoke at dawn, Block 14 stood scorched and silent — free of its 50Hz hum at last."
	},
	"D": {
		"title_sk": "Stála zmena",
		"title_en": "Ending D — The Permanent Shift",
		"subtitle": "Assimilation",
		"text": "Five radios across the courtyard sang in unison at 50.4 Hz. With Jozef's cold brass key warm in your palm and static filling every vein, you walked to the Main Gate at 06:00 and bolted it from the inside. Outside in the fog, a tired young man in a fresh guard coat checks his wristwatch, waiting to start Night 1."
	},
	"E": {
		"title_sk": "Krvavý dvor",
		"title_en": "Ending E — Bloody Courtyard",
		"subtitle": "Vengeance & Dominion",
		"text": "You locked the cellar grates, severed Kovac's booth line, and let the hungry static loose on Brano, Igor, and Hruska. Municipal investigators wrote off the blood-soaked courtyard as a botched gangland ambush. Kovac Security quietly kept you on payroll — sole watchman of a silent, empty block whose shadows now freeze whenever you raise your flashlight."
	},
	"F": {
		"title_sk": "Páska 00: Archív",
		"title_en": "Ending F — Tape 00: Archive",
		"subtitle": "True Ending — Broken Signal",
		"text": "Tearing the copper grounding bus from Device K-4 inside November 1953 severed four decades of trapped grief and surveillance. Climbing back through the courtyard as dawn broke, the interlaced scanlines splintered and dissolved into crisp pale November daylight. You set your guard key on the booth counter, pushed open the iron carriage gate, and stepped onto the street — finally free."
	}
}


func _enter_tree() -> void:
	_ensure_input_map()
	reset_story_flags()
	load_meta()


func _ensure_input_map() -> void:
	var bindings: Dictionary = {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"interact": KEY_E,
		"flashlight": KEY_F,
		"reload_battery": KEY_R,
		"sprint": KEY_SHIFT,
		"crouch": KEY_CTRL,
		"logbook": KEY_TAB,
		"pause": KEY_ESCAPE,
		"choice_1": KEY_1,
		"choice_2": KEY_2,
		"choice_3": KEY_3,
		"choice_4": KEY_4,
		"equip_flashlight": KEY_1,
		"equip_taser": KEY_2,
		"equip_keys": KEY_3,
		"equip_radio": KEY_4,
		"equip_watch": KEY_5,
		"quick_switch": KEY_Q,
		"notebook_key": KEY_N,
		"toggle_headphones": KEY_H,
		"fast_walk": KEY_C,
		"lock_door": KEY_L,
		"dev_asset_browser": KEY_F9
	}
	for action_name: String in bindings.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		if InputMap.action_get_events(action_name).is_empty():
			var ev := InputEventKey.new()
			ev.physical_keycode = int(bindings[action_name])
			InputMap.action_add_event(action_name, ev)

	if not InputMap.has_action("fire_taser"):
		InputMap.add_action("fire_taser")
	if InputMap.action_get_events("fire_taser").is_empty():
		var mev := InputEventMouseButton.new()
		mev.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire_taser", mev)


func reset_story_flags() -> void:
	story_flags = {
		"obeyed_kovac": false,
		"helped_maria": false,
		"evacuated_maria": false,
		"helped_milan": false,
		"falsified_logs_count": 0,
		"truthful_logs_count": 0,
		"redacted_logs_count": 0,
		"red_door_opened": false,
		"boiler_overloaded": false,
		"antenna_sabotaged": false,
		"accepted_jozef_key": false,
		"has_jozef_brass_key": false,
		"lured_anomalies_on_mobsters": false,
		"betrayed_kovac": false,
		"took_bribe": false,
		"all_clocks_on_time": true,
		"night_clocks_stamped": 0,
		"maria_medicine_picked": false
	}


func start_new_shift(night: int = 1, is_hardcore: bool = false, reset_campaign: bool = false) -> void:
	if reset_campaign:
		reset_story_flags()
		collected_pages.clear()
		collected_tapes.clear()
		evidence_items.clear()
		unlocked_doors.clear()
		collected_keys.clear()
		door_states.clear()
		notebook_entries.clear()
		tuned_radios = 0
		player_spotted = false
		cctv_anomalies_logged = 0

	current_night = clampi(night, 1, 6)
	hardcore_mode = is_hardcore
	shift_minutes = 0
	flashlight_battery = 100.0
	taser_charge = 100.0
	sanity = 100.0
	headphones_on = false
	equipped_slot = "flashlight"
	spare_batteries = 1 if is_hardcore else 2
	battery_swaps_this_night = 0
	picked_batteries_count = 0
	notebook_checked.clear()
	visited_zones.clear()
	visited_zones["security_office"] = true
	inspected_cctv_cams.clear()
	logged_anomalies_this_night.clear()
	completed_quests.clear()
	quest_completion_times.clear()
	if reset_campaign:
		previous_shifts_archive.clear()
	current_ending = ""
	story_flags["night_clocks_stamped"] = 0

	var ndata: Dictionary = get_night_data(current_night)
	signal_distortion = float(ndata.get("base_distortion", 8.0))

	active_quests.clear()
	var q_list: Array = ndata.get("quests", [])
	for q_var in q_list:
		var q_dict: Dictionary = q_var
		active_quests.append({
			"id": str(q_dict.get("id", "")),
			"label": str(q_dict.get("label", "")),
			"required": bool(q_dict.get("required", true)),
			"done": false
		})

	if night >= 4 and not bool(story_flags.get("has_jozef_brass_key", false)):
		# Allow Night Select plays on Night 4+ to still obtain key via Attic or fallback
		pass

	AnomalyDirector.prepare_night_anomalies(current_night)
	save_run()
	emit_signal("quest_updated")
	emit_signal("state_changed")
	emit_signal("distortion_changed", signal_distortion)


func get_night_data(night: int) -> Dictionary:
	if NIGHT_DATA.has(night):
		return NIGHT_DATA[night]
	return NIGHT_DATA[1]


func get_clock_time_only() -> String:
	var total_min: int = (22 * 60) + shift_minutes
	var hh: int = (total_min / 60) % 24
	var mm: int = total_min % 60
	return "%02d:%02d" % [hh, mm]


func get_formatted_vhs_time() -> String:
	var ndata: Dictionary = get_night_data(current_night)
	var date_str: String = str(ndata.get("date", "11.11.1996"))
	return "%s  %s  REC ●" % [date_str, get_clock_time_only()]


func mark_tutorial_completed() -> void:
	if tutorial_completed:
		return
	tutorial_completed = true
	save_meta()
	save_run()
	emit_signal("state_changed")


func advance_shift_time(minutes: int) -> void:
	shift_minutes = clampi(shift_minutes + minutes, 0, 480)
	emit_signal("state_changed")


func adjust_distortion(delta: float) -> void:
	var mult: float = 1.25 if hardcore_mode else 1.0
	signal_distortion = clampf(signal_distortion + (delta * mult if delta > 0.0 else delta), 0.0, 100.0)
	emit_signal("distortion_changed", signal_distortion)
	emit_signal("state_changed")


func complete_quest(quest_id: String) -> void:
	if quest_id in completed_quests:
		return
	var found_match: bool = false
	for q: Dictionary in active_quests:
		if str(q.get("id", "")) == quest_id:
			q["done"] = true
			found_match = true
	if found_match or not quest_id.is_empty():
		completed_quests.append(quest_id)
		advance_shift_time(38)
		quest_completion_times[quest_id] = get_clock_time_only()
		var au := get_node_or_null("/root/AudioSynth")
		if au and au.has_method("play_sfx"):
			au.play_sfx("pencil_check", -9.0, randf_range(0.96, 1.04))
		emit_signal("quest_updated")
		emit_signal("state_changed")


func is_quest_done(quest_id: String) -> bool:
	return quest_id in completed_quests


func can_finish_shift() -> bool:
	for q: Dictionary in active_quests:
		if bool(q.get("required", true)) and not bool(q.get("done", false)):
			return false
	return true


func add_page(page_id: String) -> void:
	if not page_id in collected_pages:
		collected_pages.append(page_id)
		AchievementManager.check_collectible_achievements()
		emit_signal("state_changed")


func add_tape(tape_id: String) -> void:
	if not tape_id in collected_tapes:
		collected_tapes.append(tape_id)
		AchievementManager.check_collectible_achievements()
		emit_signal("state_changed")


func add_evidence(ev_id: String) -> void:
	if not ev_id in evidence_items:
		evidence_items.append(ev_id)
		if evidence_items.size() >= 3:
			AchievementManager.unlock("ACH_05_WITNESS")
		emit_signal("state_changed")


func unlock_door_record(door_id: String) -> void:
	if not door_id in unlocked_doors:
		unlocked_doors.append(door_id)
		var required_doors: Array[String] = ["flat7", "watchmaker", "notary", "attic", "red_door"]
		var all_unlocked: bool = true
		for rd: String in required_doors:
			if not rd in unlocked_doors:
				all_unlocked = false
				break
		if all_unlocked:
			AchievementManager.unlock("ACH_23_KEYMASTER")


func register_radio_tuned() -> void:
	tuned_radios = mini(tuned_radios + 1, 5)
	adjust_distortion(6.0)
	emit_signal("state_changed")


func submit_dawn_report(mode: String) -> String:
	shift_minutes = 480
	var st := get_node_or_null("/root/StoryManager")
	var ch_date: String = str(st.get_chapter_data(current_night).get("date", "11.11.1996")) if st else "11.11.1996"
	previous_shifts_archive.append({
		"night": current_night,
		"date": ch_date,
		"report_mode": mode,
		"completed_count": completed_quests.size(),
		"notes_count": notebook_entries.size(),
		"anomalies_logged": notebook_checked.size(),
	})
	if mode == "truth":
		story_flags["truthful_logs_count"] = int(story_flags.get("truthful_logs_count", 0)) + 1
	elif mode == "falsify":
		story_flags["falsified_logs_count"] = int(story_flags.get("falsified_logs_count", 0)) + 1
	elif mode == "redact":
		story_flags["redacted_logs_count"] = int(story_flags.get("redacted_logs_count", 0)) + 1

	if battery_swaps_this_night == 0:
		AchievementManager.unlock("ACH_24_POWER_SAVER")

	AchievementManager.check_night_completion(current_night)

	if current_night < 5:
		save_meta()
		return "NEXT_NIGHT"

	# Night 5 or Night 6 resolves an ending
	var ending_id: String = evaluate_ending()
	trigger_ending(ending_id)
	return ending_id


func evaluate_ending() -> String:
	# Priority order ensures deliberate special endings take precedence over default fallback
	if current_night == 6 and is_quest_done("ground_k4_origin"):
		return "F"
	if bool(story_flags.get("boiler_overloaded", false)) and bool(story_flags.get("red_door_opened", false)):
		return "C"
	if signal_distortion >= 75.0 and tuned_radios >= 5 and bool(story_flags.get("accepted_jozef_key", false)):
		return "D"
	if bool(story_flags.get("lured_anomalies_on_mobsters", false)) and bool(story_flags.get("betrayed_kovac", false)):
		return "E"
	if evidence_items.size() >= 3 and bool(story_flags.get("evacuated_maria", false)) and bool(story_flags.get("antenna_sabotaged", false)):
		return "B"
	if bool(story_flags.get("took_bribe", false)) or (int(story_flags.get("falsified_logs_count", 0)) >= 3 and not bool(story_flags.get("red_door_opened", false))):
		return "A"
	# Sensible narrative fallbacks if mixed choices were made on Night 5
	if bool(story_flags.get("red_door_opened", false)) and evidence_items.size() >= 2:
		return "B"
	if signal_distortion >= 75.0:
		return "D"
	return "A"


func trigger_ending(ending_id: String) -> void:
	current_ending = ending_id
	if not ending_id in unlocked_endings:
		unlocked_endings.append(ending_id)
	ng_plus_unlocked = true
	hardcore_unlocked = true
	AchievementManager.check_ending_achievements(ending_id)
	save_meta()
	emit_signal("ending_triggered", ending_id)


func can_unlock_night_6() -> bool:
	return ng_plus_unlocked and collected_tapes.size() >= 4 and collected_pages.size() >= 8


func has_saved_run() -> bool:
	return FileAccess.file_exists(SAVE_RUN_PATH)


func save_run() -> void:
	var payload: Dictionary = {
		"current_night": current_night,
		"shift_minutes": shift_minutes,
		"hardcore_mode": hardcore_mode,
		"flashlight_battery": flashlight_battery,
		"spare_batteries": spare_batteries,
		"signal_distortion": signal_distortion,
		"sanity": sanity,
		"headphones_on": headphones_on,
		"player_spotted": player_spotted,
		"completed_quests": completed_quests,
		"quest_completion_times": quest_completion_times,
		"previous_shifts_archive": previous_shifts_archive,
		"tutorial_completed": tutorial_completed,
		"collected_pages": collected_pages,
		"collected_tapes": collected_tapes,
		"evidence_items": evidence_items,
		"unlocked_doors": unlocked_doors,
		"collected_keys": collected_keys,
		"door_states": door_states,
		"notebook_entries": notebook_entries,
		"tuned_radios": tuned_radios,
		"cctv_anomalies_logged": cctv_anomalies_logged,
		"story_flags": story_flags
	}
	var f := FileAccess.open(SAVE_RUN_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()


func load_run() -> bool:
	if not FileAccess.file_exists(SAVE_RUN_PATH):
		return false
	var f := FileAccess.open(SAVE_RUN_PATH, FileAccess.READ)
	if not f:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return false
	var data: Dictionary = parsed
	current_night = int(data.get("current_night", 1))
	start_new_shift(current_night, bool(data.get("hardcore_mode", false)), false)
	shift_minutes = int(data.get("shift_minutes", 0))
	flashlight_battery = float(data.get("flashlight_battery", 100.0))
	spare_batteries = int(data.get("spare_batteries", 2))
	signal_distortion = float(data.get("signal_distortion", 10.0))
	sanity = float(data.get("sanity", 100.0))
	headphones_on = bool(data.get("headphones_on", false))
	player_spotted = bool(data.get("player_spotted", false))
	tuned_radios = int(data.get("tuned_radios", 0))
	cctv_anomalies_logged = int(data.get("cctv_anomalies_logged", 0))

	completed_quests.clear()
	for q_str in data.get("completed_quests", []):
		completed_quests.append(str(q_str))
	for q: Dictionary in active_quests:
		if str(q.get("id", "")) in completed_quests:
			q["done"] = true
	quest_completion_times.clear()
	var qct: Variant = data.get("quest_completion_times", {})
	if qct is Dictionary:
		for qk in (qct as Dictionary).keys():
			quest_completion_times[str(qk)] = str(qct[qk])
	previous_shifts_archive.clear()
	for psa in data.get("previous_shifts_archive", []):
		if psa is Dictionary:
			previous_shifts_archive.append(psa)
	if data.has("tutorial_completed"):
		tutorial_completed = bool(data.get("tutorial_completed", false))

	collected_pages.clear()
	for p in data.get("collected_pages", []):
		collected_pages.append(str(p))
	collected_tapes.clear()
	for t in data.get("collected_tapes", []):
		collected_tapes.append(str(t))
	evidence_items.clear()
	for e in data.get("evidence_items", []):
		evidence_items.append(str(e))
	unlocked_doors.clear()
	for d in data.get("unlocked_doors", []):
		unlocked_doors.append(str(d))
	collected_keys.clear()
	for k_str in data.get("collected_keys", []):
		collected_keys.append(str(k_str))
	door_states.clear()
	var saved_doors: Variant = data.get("door_states", {})
	if saved_doors is Dictionary:
		for dk in (saved_doors as Dictionary).keys():
			door_states[str(dk)] = saved_doors[dk]
	notebook_entries.clear()
	for ne in data.get("notebook_entries", []):
		if ne is Dictionary:
			notebook_entries.append(ne)

	var saved_flags: Variant = data.get("story_flags", {})
	if saved_flags is Dictionary:
		for k in (saved_flags as Dictionary).keys():
			story_flags[str(k)] = saved_flags[k]

	emit_signal("quest_updated")
	emit_signal("state_changed")
	return true


func save_meta() -> void:
	var payload: Dictionary = {
		"unlocked_endings": unlocked_endings,
		"discovered_anomalies": discovered_anomalies,
		"unlocked_achievements": unlocked_achievements,
		"ng_plus_unlocked": ng_plus_unlocked,
		"hardcore_unlocked": hardcore_unlocked,
		"tutorial_completed": tutorial_completed
	}
	var f := FileAccess.open(SAVE_META_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()


func load_meta() -> void:
	if not FileAccess.file_exists(SAVE_META_PATH):
		return
	var f := FileAccess.open(SAVE_META_PATH, FileAccess.READ)
	if not f:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return
	var data: Dictionary = parsed
	unlocked_endings.clear()
	for e in data.get("unlocked_endings", []):
		unlocked_endings.append(str(e))
	discovered_anomalies.clear()
	for a in data.get("discovered_anomalies", []):
		discovered_anomalies.append(str(a))
	unlocked_achievements.clear()
	for ach in data.get("unlocked_achievements", []):
		unlocked_achievements.append(str(ach))
	ng_plus_unlocked = bool(data.get("ng_plus_unlocked", false))
	hardcore_unlocked = bool(data.get("hardcore_unlocked", false))
	tutorial_completed = bool(data.get("tutorial_completed", false))


func mark_zone_visited(zone_id: String) -> void:
	if zone_id.is_empty():
		return
	if bool(visited_zones.get(zone_id, false)):
		return
	visited_zones[zone_id] = true
	if current_night == 1:
		var needed := ["parking_lot", "central_park", "commercial_area", "garages"]
		var all_ok := true
		for z in needed:
			if not bool(visited_zones.get(z, false)):
				all_ok = false
				break
		if all_ok:
			complete_quest("tut_tour_zones")
	emit_signal("state_changed")


func register_cctv_viewed(cam_idx: int) -> void:
	if not (cam_idx in inspected_cctv_cams):
		inspected_cctv_cams.append(cam_idx)
	if current_night == 1 and inspected_cctv_cams.size() >= 6:
		complete_quest("check_cctv_n1")
	emit_signal("state_changed")


func add_spare_battery(amount: int = 1) -> void:
	spare_batteries = mini(spare_batteries + amount, 12)
	picked_batteries_count += amount
	emit_signal("state_changed")


func reload_gear_battery() -> bool:
	if spare_batteries <= 0:
		return false
	if flashlight_battery >= 99.0 and taser_charge >= 99.0 and picked_batteries_count == 0:
		return false
	spare_batteries -= 1
	battery_swaps_this_night += 1
	flashlight_battery = 100.0
	taser_charge = 100.0
	if current_night == 1 and picked_batteries_count >= 1:
		complete_quest("tut_pick_battery")
	emit_signal("state_changed")
	return true


func consume_taser_charge(cost: float = 25.0) -> bool:
	if taser_charge < cost:
		return false
	taser_charge = clampf(taser_charge - cost, 0.0, 100.0)
	if current_night == 1:
		complete_quest("tut_test_taser")
	emit_signal("state_changed")
	return true


func check_off_notebook_anomaly(anomaly_id: String) -> bool:
	if anomaly_id.is_empty():
		return false
	var valid_tonight: bool = AnomalyDirector.is_active(anomaly_id) or (anomaly_id in logged_anomalies_this_night) or (anomaly_id in discovered_anomalies)
	if not valid_tonight:
		return false
	if not bool(notebook_checked.get(anomaly_id, false)):
		notebook_checked[anomaly_id] = true
		if not (anomaly_id in logged_anomalies_this_night):
			logged_anomalies_this_night.append(anomaly_id)
		AnomalyDirector.discover_anomaly(anomaly_id)
		AnomalyDirector.resolved_anomalies[anomaly_id] = "logged"
		adjust_distortion(-4.0)
	if current_night == 1:
		complete_quest("tut_log_anomaly")
	emit_signal("state_changed")
	return true


func is_anomaly_checked_in_notebook(anomaly_id: String) -> bool:
	return bool(notebook_checked.get(anomaly_id, false))


func get_tutorial_hint() -> String:
	if current_night != 1:
		return ""
	if not is_quest_done("answer_briefing"):
		return "ORIENTATION 1/7: Answer the ringing Rotary Phone inside the Security Office [E]"
	if not is_quest_done("tut_pick_battery"):
		return "ORIENTATION 2/7: Pick up the 4.5V Battery Pack on the office shelf [E], then press [R] to reload"
	if not is_quest_done("tut_test_taser"):
		return "ORIENTATION 3/7: Press [2] to equip your Stun Taser, then [LMB] to fire an electric arc"
	if not is_quest_done("tut_tour_zones"):
		return "ORIENTATION 4/7: Patrol Parking Lot, Central Park, Shops & Garages (%d/4 toured)" % _count_ground_zones_toured()
	if not is_quest_done("stamp_clocks"):
		var stamped: int = int(story_flags.get("night_clocks_stamped", 0))
		return "ORIENTATION 5/7: Stamp any 3 patrol Watchman's Clocks [E] (%d/3)" % stamped
	if not is_quest_done("tut_log_anomaly"):
		return "ORIENTATION 6/7: Spot a district anomaly (Park Swing / Well Hands / Garage 07 / 13th Window), then open Notebook [TAB/N] & Check Off"
	if not is_quest_done("check_cctv_n1"):
		return "ORIENTATION 7/7: Inspect all 6 CCTV camera feeds on the Security Office Monitor (%d/6)" % inspected_cctv_cams.size()
	return "ORIENTATION COMPLETE: Return to the Security Office Desk [E] to submit your Dawn Report!"


func _count_ground_zones_toured() -> int:
	var c := 0
	for z in ["parking_lot", "central_park", "commercial_area", "garages"]:
		if bool(visited_zones.get(z, false)):
			c += 1
	return c


func collect_key(key_id: String) -> void:
	if key_id.is_empty():
		return
	if not (key_id in collected_keys):
		collected_keys.append(key_id)
		emit_signal("state_changed")


func has_key(key_id: String) -> bool:
	return key_id in collected_keys


func set_door_state(door_id: String, is_open: bool, is_locked: bool) -> void:
	if door_id.is_empty():
		return
	door_states[door_id] = {"open": is_open, "locked": is_locked}
	if not is_locked and not (door_id in unlocked_doors):
		unlocked_doors.append(door_id)
	emit_signal("state_changed")


func add_notebook_entry(title_text: String, note_text: String, zone_label: String = "") -> void:
	var clean_note := note_text.strip_edges()
	if clean_note.is_empty():
		return
	notebook_entries.append({
		"time": get_formatted_vhs_time(),
		"title": title_text.strip_edges(),
		"note": clean_note,
		"zone": zone_label
	})
	emit_signal("state_changed")
