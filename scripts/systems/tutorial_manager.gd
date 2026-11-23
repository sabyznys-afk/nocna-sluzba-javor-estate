class_name TutorialManager
extends Node

# Prompt 08 Part 3 — Complete 8-Stage First-Time Interactive English Tutorial Guided by Jozef Varga
# - Teaches ONE mechanic at a time, requiring actual player action before advancing
# - Displays only tiny, temporary, keybinding-aware control hints (never covers screen)
# - Skippable in SettingsManager ('skip_tutorial') and reopenable anytime from the Notebook!
# - Persists completion cleanly to GameState so it never repeats on reload!

signal stage_changed(stage_idx: int, stage_id: String, hint_text: String)
signal tutorial_finished

const STAGES: Array[Dictionary] = [
	{
		"id": "intro",
		"title": "ARRIVAL & OFFICE INTRODUCTION",
		"voice_id": "jozef_tut_welcome",
		"dialogue": "So you're Martin. Come inside, I'll show you what you'll be doing here. It's nothing complicated. Just watch the doors, write down your rounds, and never leave anything unlocked.",
		"hint_fmt": "TALK TO JOZEF: [{interact}]  •  MOVE: WASD",
	},
	{
		"id": "movement",
		"title": "STAGE 1 — MOVEMENT & LOOKING AROUND",
		"voice_id": "jozef_tut_move",
		"dialogue": "Step over here by the desk and take a good look around the office so you know where everything sits.",
		"hint_fmt": "MOVE: WASD  •  LOOK: MOUSE  •  SPRINT: SHIFT",
	},
	{
		"id": "notebook",
		"title": "STAGE 2 — SHIFT NOTEBOOK",
		"voice_id": "jozef_tut_notebook",
		"dialogue": "Everything important is written down in here. I don't expect you to remember the whole estate from memory. Open your notebook, check the map, and try logging an observation.",
		"hint_fmt": "NOTEBOOK: [{notebook_key} / TAB]  •  CHECK SECTIONS & CLOSE",
	},
	{
		"id": "inventory",
		"title": "STAGE 3 — BELT EQUIPMENT & INVENTORY",
		"voice_id": "jozef_tut_inventory",
		"dialogue": "Your belt holds your torch, keys, radio, notebook, and taser. Scroll the mouse wheel or use keys 0 to 6 to switch equipment, and keep empty hands when you don't need tools.",
		"hint_fmt": "SWITCH GEAR: MOUSE WHEEL / 0–6  •  EMPTY HANDS: 0",
	},
	{
		"id": "flashlight",
		"title": "STAGE 4 — FLASHLIGHT",
		"voice_id": "jozef_tut_flashlight",
		"dialogue": "When something breaks down, your flashlight will save you. Take it out, switch it on and off, and shine it across at least two objects in here.",
		"hint_fmt": "TORCH: 1  •  ON / OFF: [{flashlight}]  •  ILLUMINATE 2 OBJECTS",
	},
	{
		"id": "keys_doors",
		"title": "STAGE 5 — KEYS & DOORS",
		"voice_id": "jozef_tut_keys_doors",
		"dialogue": "Opening a door and unlocking it aren't the same thing. Select your keys, look at the office door handle, unlock or lock it, and open the door.",
		"hint_fmt": "KEYS: 3  •  OPEN/CLOSE: [{interact}]  •  LOCK/UNLOCK: [L]",
	},
	{
		"id": "radio",
		"title": "STAGE 6 — VHF GUARD RADIO",
		"voice_id": "jozef_tut_radio",
		"dialogue": "Grab your handheld radio and run a quick channel check so dispatch knows you're on shift.",
		"hint_fmt": "RADIO: 4  •  SPEAK / CHECK DISPATCH: LMB",
	},
	{
		"id": "headphones",
		"title": "STAGE 7 — WALKMAN HEADPHONES",
		"voice_id": "jozef_tut_headphones",
		"dialogue": "I see you brought a Walkman. Music helps calm your nerves on a long night, but remember: with headphones on, you won't hear approaching footsteps or warnings. Try putting them on and taking them off.",
		"hint_fmt": "HEADPHONES ON / OFF: [{toggle_headphones}]",
	},
	{
		"id": "first_patrol",
		"title": "STAGE 8 — FIRST GUIDED PATROL",
		"voice_id": "jozef_office_intro_01",
		"dialogue": "Now step outside with me. Follow along the main gate, parking walkway, Building A, Central Park, and the newsstand. Inspect each door and log your patrol in the notebook.",
		"hint_fmt": "FOLLOW JOZEF  •  INSPECT: [{interact}]  •  MAP: [{notebook_key} / TAB]",
	},
]

var active: bool = false
var completed: bool = false
var current_stage_idx: int = 0
var companion_ref: Node3D = null
var player_ref: Node3D = null
var hud_ref: Node = null
var voice_mgr_ref: Node = null
var patrol_mgr_ref: Node = null

# Per-stage action verification flags (player MUST perform the real action!)
var _moved_ok: bool = false
var _looked_ok: bool = false
var _sprinted_ok: bool = false
var _nb_opened_ok: bool = false
var _nb_browsed_ok: bool = false
var _nb_closed_ok: bool = false
var _inv_slots_seen: Array[String] = []
var _inv_empty_hands_ok: bool = false
var _fl_equipped_ok: bool = false
var _fl_toggled_on_ok: bool = false
var _fl_toggled_off_ok: bool = false
var _fl_lit_objects: Array[String] = []
var _keys_equipped_ok: bool = false
var _door_opened_ok: bool = false
var _door_locked_ok: bool = false
var _radio_used_ok: bool = false
var _hp_on_ok: bool = false
var _hp_off_ok: bool = false
var _patrol_cp_logged_ok: bool = false

var _start_pos: Vector3 = Vector3.ZERO
var _start_yaw: float = 0.0
var _ray_accum: float = 0.0


func _gs() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("GameState") if ml is SceneTree else null


func _sett() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("SettingsManager") if ml is SceneTree else null


func _loc() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("LocalizationManager") if ml is SceneTree else null


func setup_tutorial(p_player: Node3D, p_companion: Node3D, p_hud: Node, p_voice: Node, p_patrol: Node) -> void:
	name = "TutorialManager"
	player_ref = p_player
	companion_ref = p_companion
	hud_ref = p_hud
	voice_mgr_ref = p_voice
	patrol_mgr_ref = p_patrol
	var sett := _sett()
	if sett and sett.has_signal("settings_changed"):
		if not sett.settings_changed.is_connected(_on_settings_changed):
			sett.settings_changed.connect(_on_settings_changed)


func _on_settings_changed() -> void:
	var sett := _sett()
	if active and sett and bool(sett.get_val("skip_tutorial", false)):
		skip_tutorial()


func start_if_needed(night_num: int) -> void:
	var gs := _gs()
	var sett := _sett()
	if night_num != 1:
		active = false
		return
	if (gs and gs.tutorial_completed) or (sett and bool(sett.get_val("skip_tutorial", false))):
		active = false
		completed = true
		if gs and not gs.tutorial_completed:
			gs.mark_tutorial_completed()
		return
	begin_tutorial(false)


func begin_tutorial(is_replay: bool = false) -> void:
	active = true
	completed = false
	current_stage_idx = 0
	_reset_stage_flags()
	if player_ref:
		_start_pos = player_ref.global_position
		_start_yaw = player_ref.rotation.y
	if is_replay and companion_ref and companion_ref.has_method("refresh_for_night"):
		companion_ref.refresh_for_night(1)
	_enter_stage(0)


func skip_tutorial() -> void:
	active = false
	completed = true
	var gs := _gs()
	if gs:
		gs.mark_tutorial_completed()
	if hud_ref and hud_ref.has_method("show_tutorial_hint"):
		hud_ref.show_tutorial_hint("")
	emit_signal("tutorial_finished")


func get_current_stage_id() -> String:
	if not active or current_stage_idx < 0 or current_stage_idx >= STAGES.size():
		return "completed" if completed else "inactive"
	return str(STAGES[current_stage_idx]["id"])


func get_current_hint_text() -> String:
	if not active or current_stage_idx < 0 or current_stage_idx >= STAGES.size():
		return ""
	var raw: String = str(STAGES[current_stage_idx].get("hint_fmt", ""))
	var loc := _loc()
	if loc and loc.has_method("get_key_label"):
		raw = raw.replace("{interact}", loc.get_key_label("interact"))
		raw = raw.replace("{notebook_key}", loc.get_key_label("notebook_key"))
		raw = raw.replace("{flashlight}", loc.get_key_label("flashlight"))
		raw = raw.replace("{toggle_headphones}", loc.get_key_label("toggle_headphones"))
	return raw


func _reset_stage_flags() -> void:
	_moved_ok = false
	_looked_ok = false
	_sprinted_ok = false
	_nb_opened_ok = false
	_nb_browsed_ok = false
	_nb_closed_ok = false
	_inv_slots_seen.clear()
	_inv_empty_hands_ok = false
	_fl_equipped_ok = false
	_fl_toggled_on_ok = false
	_fl_toggled_off_ok = false
	_fl_lit_objects.clear()
	_keys_equipped_ok = false
	_door_opened_ok = false
	_door_locked_ok = false
	_radio_used_ok = false
	_hp_on_ok = false
	_hp_off_ok = false
	_patrol_cp_logged_ok = false


func _enter_stage(idx: int) -> void:
	if idx >= STAGES.size():
		_finish_tutorial()
		return
	current_stage_idx = idx
	var st: Dictionary = STAGES[idx]
	var sid: String = str(st["id"])
	var dlg: String = str(st["dialogue"])
	var vid: String = str(st["voice_id"])
	var hint: String = get_current_hint_text()

	if player_ref:
		_start_pos = player_ref.global_position
		_start_yaw = player_ref.rotation.y

	# Direct Jozef Varga physically inside the office to match each lesson!
	if companion_ref and is_instance_valid(companion_ref):
		match sid:
			"intro":
				companion_ref.speak_tutorial_line(dlg, vid)
			"movement":
				companion_ref.walk_to_local_spot(Vector3(-17.2, 0.06, -55.4), Vector3(-19.0, 1.0, -57.8))
				companion_ref.speak_tutorial_line(dlg, vid)
			"notebook":
				companion_ref.speak_tutorial_line(dlg, vid, Vector3(-19.0, 1.0, -57.8))
			"inventory":
				companion_ref.speak_tutorial_line(dlg, vid)
			"flashlight":
				companion_ref.walk_to_local_spot(Vector3(-19.8, 0.06, -55.0), Vector3(-21.6, 1.2, -53.6))
				companion_ref.speak_tutorial_line(dlg, vid)
			"keys_doors":
				companion_ref.walk_to_local_spot(Vector3(-14.4, 0.06, -54.6), Vector3(-13.5, 1.1, -54.6))
				companion_ref.speak_tutorial_line(dlg, vid)
			"radio":
				companion_ref.speak_tutorial_line(dlg, vid)
			"headphones":
				companion_ref.speak_tutorial_line(dlg, vid)
			"first_patrol":
				if not companion_ref.patrol_started:
					companion_ref.start_guided_patrol()
				else:
					companion_ref.speak_tutorial_line(dlg, vid)
	elif hud_ref and hud_ref.has_method("show_dialogue"):
		hud_ref.show_dialogue("JOZEF VARGA", dlg, 7.5, "Senior Security Guard — Mentor")

	if hud_ref and hud_ref.has_method("show_tutorial_hint"):
		hud_ref.show_tutorial_hint(hint)
	emit_signal("stage_changed", idx, sid, hint)


func _finish_tutorial() -> void:
	active = false
	completed = true
	var gs := _gs()
	if gs:
		gs.mark_tutorial_completed()
		gs.save_run()
	if companion_ref and companion_ref.has_method("speak_tutorial_line"):
		companion_ref.speak_tutorial_line("Right, that's everything. You can handle the next rounds on your own.", "jozef_return_08")
	if hud_ref and hud_ref.has_method("show_tutorial_hint"):
		hud_ref.show_tutorial_hint("")
	emit_signal("tutorial_finished")


func _process(delta: float) -> void:
	if not active or not player_ref or not is_instance_valid(player_ref):
		return
	var sid: String = get_current_stage_id()
	if sid == "movement":
		if player_ref.global_position.distance_to(_start_pos) > 1.0:
			_moved_ok = true
		if absf(wrapf(player_ref.rotation.y - _start_yaw, -PI, PI)) > 0.30:
			_looked_ok = true
		if Input.is_action_pressed("sprint") or (player_ref.stamina_mgr and player_ref.stamina_mgr.stamina < 98.5):
			_sprinted_ok = true
		if _moved_ok and _looked_ok:
			if patrol_mgr_ref:
				patrol_mgr_ref.complete_tutorial_step("move")
				patrol_mgr_ref.complete_tutorial_step("look")
			_enter_stage(2)
	elif sid == "flashlight":
		_ray_accum += delta
		if _ray_accum >= 0.20:
			_ray_accum = 0.0
			if player_ref.has_method("get_flashlight_illuminated_object"):
				var hit_nm: String = player_ref.get_flashlight_illuminated_object()
				if not hit_nm.is_empty() and not (hit_nm in _fl_lit_objects):
					_fl_lit_objects.append(hit_nm)
					_check_flashlight_done()


# --- Event Hooks Called by main_scene.gd / player / HUD ---

func notify_player_interacted(interact_id: String, interact_type: String) -> void:
	if not active:
		return
	var sid: String = get_current_stage_id()
	if sid == "intro" and (interact_id == "npc_varga" or interact_type in ["companion_varga", "phone", "desk"]):
		_enter_stage(1)
	elif sid == "keys_doors" and interact_type == "physical_door":
		_door_opened_ok = true
		_check_keys_doors_done()
	elif sid == "first_patrol" and interact_id in ["main_gate", "clock_gate", "n1_open_car", "n1_blocka_mailboxes", "npc_anna"]:
		_patrol_cp_logged_ok = true


func notify_notebook_opened(opened: bool) -> void:
	if not active:
		return
	var sid: String = get_current_stage_id()
	if sid == "notebook":
		if opened:
			_nb_opened_ok = true
		elif _nb_opened_ok:
			_nb_closed_ok = true
			if patrol_mgr_ref:
				patrol_mgr_ref.complete_tutorial_step("notebook_map")
			_enter_stage(3)


func notify_notebook_section_viewed(_section_idx: int) -> void:
	if not active:
		return
	if get_current_stage_id() == "notebook":
		_nb_browsed_ok = true


func notify_notebook_note_written() -> void:
	if not active:
		return
	var sid: String = get_current_stage_id()
	if sid == "notebook":
		_nb_browsed_ok = true
	elif sid == "first_patrol" and _patrol_cp_logged_ok:
		if companion_ref and companion_ref.patrol_completed:
			_finish_tutorial()


func notify_gear_switched(slot: String) -> void:
	if not active:
		return
	var sid: String = get_current_stage_id()
	if sid == "inventory":
		if not (slot in _inv_slots_seen):
			_inv_slots_seen.append(slot)
		if slot == "hands":
			_inv_empty_hands_ok = true
		if _inv_slots_seen.size() >= 2 and _inv_empty_hands_ok:
			if patrol_mgr_ref:
				patrol_mgr_ref.complete_tutorial_step("inventory")
			_enter_stage(4)
	elif sid == "flashlight" and slot == "flashlight":
		_fl_equipped_ok = true
		_check_flashlight_done()
	elif sid == "keys_doors" and slot == "keys":
		_keys_equipped_ok = true
		_check_keys_doors_done()


func notify_flashlight_toggled(is_on: bool) -> void:
	if not active:
		return
	if get_current_stage_id() == "flashlight":
		_fl_equipped_ok = true
		if is_on:
			_fl_toggled_on_ok = true
		else:
			_fl_toggled_off_ok = true
		_check_flashlight_done()


func notify_flashlight_object_illuminated(obj_name: String) -> void:
	if not active or obj_name.is_empty():
		return
	if get_current_stage_id() == "flashlight" and not (obj_name in _fl_lit_objects):
		_fl_lit_objects.append(obj_name)
		_check_flashlight_done()


func _check_flashlight_done() -> void:
	if _fl_equipped_ok and _fl_toggled_on_ok and _fl_toggled_off_ok and _fl_lit_objects.size() >= 2:
		if patrol_mgr_ref:
			patrol_mgr_ref.complete_tutorial_step("flashlight")
		_enter_stage(5)


func notify_door_lock_toggled() -> void:
	if not active:
		return
	if get_current_stage_id() == "keys_doors":
		_door_locked_ok = true
		_check_keys_doors_done()


func _check_keys_doors_done() -> void:
	if _keys_equipped_ok and (_door_opened_ok or _door_locked_ok):
		if patrol_mgr_ref:
			patrol_mgr_ref.complete_tutorial_step("keys_doors")
		_enter_stage(6)


func notify_radio_used() -> void:
	if not active:
		return
	if get_current_stage_id() == "radio":
		_radio_used_ok = true
		if voice_mgr_ref and voice_mgr_ref.has_method("play_voice_line"):
			voice_mgr_ref.play_voice_line("radio_dispatch_02", Vector3.ZERO, true)
		if hud_ref and hud_ref.has_method("show_dialogue"):
			hud_ref.show_dialogue("NOVY BROD DISPATCH — CH-04", "Loud and clear, Martin. Next routine status check at 02:00 hours.", 6.0, "Central Dispatch")
		if patrol_mgr_ref:
			patrol_mgr_ref.complete_tutorial_step("radio")
		_enter_stage(7)


func notify_headphones_toggled(wearing: bool) -> void:
	if not active:
		return
	if get_current_stage_id() == "headphones":
		if wearing:
			_hp_on_ok = true
			if hud_ref and hud_ref.has_method("show_toast"):
				hud_ref.show_toast("Headphones ON — Notice how outdoor audio dims! Press [H] again to remove.")
		else:
			_hp_off_ok = true
		if _hp_on_ok and _hp_off_ok:
			if patrol_mgr_ref:
				patrol_mgr_ref.complete_tutorial_step("headphones")
			_enter_stage(8)


func notify_companion_patrol_completed() -> void:
	if active and get_current_stage_id() == "first_patrol":
		_finish_tutorial()
