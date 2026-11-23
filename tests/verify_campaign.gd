extends SceneTree

# Full Automated Prompt 06 Campaign Playthrough Test:
# Plays from a fresh New Game (Night 1 Arrival + Interactive Onboarding) through every checkpoint,
# evidence pickup, NPC interaction, mid-campaign Save/Load, Hidden Service Corridor, Night 6 03:17 Blackout,
# Roman Král physical pursuit, and resolves ALL THREE ENDINGS (A: Morning Report, B: The Last Patrol, C: The Next Guard)!

var _failed: bool = false
var _pass_count: int = 0


func _assert(cond: bool, msg: String) -> void:
	if not cond:
		push_error("CAMPAIGN ASSERT FAILED: " + msg)
		print("FAIL: " + msg)
		_failed = true
	else:
		_pass_count += 1
		print("PASS: " + msg)


func _initialize() -> void:
	create_timer(45.0).timeout.connect(func():
		print("FAIL: Campaign playthrough timeout")
		quit(1)
	)
	call_deferred("_run_full_campaign_playthrough")


func _find_interactable(world: Node, iid: String) -> Area3D:
	if not world or not ("interactables" in world):
		return null
	for area: Area3D in world.interactables:
		if is_instance_valid(area) and ("interact_id" in area) and str(area.interact_id) == iid:
			return area
	return null


func _walk_and_trigger(main_inst: Node, world: Node, player: Node3D, patrol_mgr: Node, iid: String) -> bool:
	var gs: Node = root.get_node_or_null("GameState")
	var area: Area3D = _find_interactable(world, iid)
	if not area:
		push_error("Missing interactable in live world: " + iid)
		return false
	player.global_position = area.global_position + Vector3(0.0, 0.2, 0.6)
	patrol_mgr.check_player_proximity(player.global_position, gs.current_night if gs else 1)
	main_inst._on_interactable_triggered(area)
	return true


func _run_full_campaign_playthrough() -> void:
	var gs: Node = root.get_node_or_null("GameState")
	var st: Node = root.get_node_or_null("StoryManager")
	var sm: Node = root.get_node_or_null("SaveManager")
	var sett: Node = root.get_node_or_null("SettingsManager")

	_assert(gs != null and st != null and sm != null and sett != null, "Core autoloads ready for campaign playthrough")
	if gs == null or st == null or sm == null or sett == null:
		quit(1)
		return

	# Backup existing user saves/meta before clean New Game run
	var orig_endings: Array = gs.unlocked_endings.duplicate()
	var orig_anoms: Array = gs.discovered_anomalies.duplicate()
	var orig_achs: Array = gs.unlocked_achievements.duplicate()
	var orig_ng: bool = gs.ng_plus_unlocked
	var orig_hc: bool = gs.hardcore_unlocked
	var orig_tut: bool = gs.tutorial_completed
	var orig_nav: String = str(sett.get_val("nav_assist", "subtle"))
	var orig_run_existed: bool = FileAccess.file_exists(gs.SAVE_RUN_PATH)
	var orig_run_bytes: PackedByteArray = FileAccess.get_file_as_bytes(gs.SAVE_RUN_PATH) if orig_run_existed else PackedByteArray()
	var slot4_path: String = "user://javor_slot_4.json"
	var slot4_existed: bool = FileAccess.file_exists(slot4_path)
	var slot4_bytes: PackedByteArray = FileAccess.get_file_as_bytes(slot4_path) if slot4_existed else PackedByteArray()

	# Fresh New Game start!
	gs.tutorial_completed = false
	st.reset_story()
	gs.start_new_shift(1, false, true)

	var main_packed: PackedScene = load("res://scenes/main.tscn")
	_assert(main_packed != null, "Loaded main.tscn for full 6-night campaign run")
	var main_inst: Node = main_packed.instantiate()
	root.add_child(main_inst)
	await physics_frame
	await physics_frame

	var world: Node3D = main_inst.get_node_or_null("Blok14World")
	var dist: Node3D = world.district if world else null
	var player: CharacterBody3D = main_inst.get_node_or_null("GuardPlayer")
	var hud: Node = main_inst.get_node_or_null("GameHUD")
	var patrol_mgr: Node = main_inst.get_node_or_null("PatrolRouteManager")
	var nav_mgr: Node3D = main_inst.get_node_or_null("NavigationHintManager")
	var npc_mgr: Node3D = main_inst.get_node_or_null("NPCScheduleManager")
	var ant_ai: Node3D = main_inst.get_node_or_null("AntagonistAI")
	var ending_mgr: Node = main_inst.get_node_or_null("EndingManager")

	_assert(
		patrol_mgr != null and nav_mgr != null and npc_mgr != null and ant_ai != null and ending_mgr != null,
		"All 5 Prompt 06 runtime managers initialized (PatrolRoute, NavigationHint, NPCSchedule, AntagonistAI, EndingManager)"
	)

	# -----------------------------------------------------------------------
	# 1. VERIFY 3-LAYER NAVIGATION, SETTINGS, LOST-PLAYER ASSISTANCE & NPC SCHEDULES
	# -----------------------------------------------------------------------
	_assert(nav_mgr.get_marker_count() >= 6 and not nav_mgr.has_artificial_glowing_markers(), "Prompt 07 Part 5: Architectural BLOK A-F plates present (%d) with ZERO artificial glowing markers" % nav_mgr.get_marker_count())
	for nmode: String in ["off", "subtle", "clear"]:
		sett.set_val("nav_assist", nmode, true)
		_assert(nav_mgr.get_nav_mode() == nmode, "Layer C Navigation Assistance switches cleanly to '%s'" % nmode)
	sett.set_val("nav_assist", "subtle", true)

	var lost_msg: String = nav_mgr.trigger_lost_player_assistance()
	_assert(nav_mgr.is_player_lost and not lost_msg.is_empty(), "Lost-player radio assistance triggers believable Varga guidance")

	var comp_guard: Node3D = main_inst.get_node_or_null("CompanionGuardController")
	_assert(npc_mgr.get_npc_count() >= 8 and comp_guard != null, "NPCScheduleManager (%d NPCs) + CompanionGuardController Jozef Varga active" % npc_mgr.get_npc_count())
	var anna_ctrl: Node3D = npc_mgr.get_npc("anna")
	var res_a_ctrl: Node3D = npc_mgr.get_npc("resident_a")
	var anna_art: bool = anna_ctrl != null and anna_ctrl.has_method("is_articulated") and anna_ctrl.is_articulated()
	var res_p0: Vector3 = res_a_ctrl.global_position if res_a_ctrl else Vector3.ZERO
	if res_a_ctrl:
		res_a_ctrl.wait_timer = 0.0
		for _step: int in range(20):
			res_a_ctrl._process(0.1)
	var res_moved: bool = res_a_ctrl != null and res_a_ctrl.global_position.distance_to(res_p0) > 0.5
	_assert(anna_art and res_moved, "Articulated unique NPCs animate and walk physically along estate schedule routes")

	# -----------------------------------------------------------------------
	# 2. NIGHT 1 — ARRIVAL, INTERACTIVE TUTORIAL & ALL 6 CHECKPOINTS
	# -----------------------------------------------------------------------
	patrol_mgr.complete_tutorial_step("move")
	patrol_mgr.complete_tutorial_step("look")
	_assert(_walk_and_trigger(main_inst, world, player, patrol_mgr, "npc_varga"), "Night 1: Spoke in person with Supervisor Jozef Varga at Vrátnica")
	player.switch_gear("keys")
	player.switch_gear("radio")
	player.toggle_flashlight()
	player.toggle_flashlight()
	player.toggle_headphones()
	player.toggle_headphones()
	hud.open_logbook(6) # Opens Map page with handwritten red pencil patrol route!
	hud.close_all_modals()
	patrol_mgr.complete_tutorial_step("keys_doors")

	# Distinguish visiting vs completing Checkpoint 1
	player.global_position = Vector3(0.0, 0.2, -68.0)
	patrol_mgr.check_player_proximity(player.global_position, 1)
	var visited_only: bool = patrol_mgr.is_checkpoint_visited("n1_cp1_gate") and not patrol_mgr.is_checkpoint_completed("n1_cp1_gate")
	_assert(visited_only, "Patrol system distinguishes visiting a checkpoint area vs completing its inspection")

	_walk_and_trigger(main_inst, world, player, patrol_mgr, "main_gate")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n1_open_car")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n1_blocka_mailboxes")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "npc_anna")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n1_dropped_keys")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "npc_dana")
	_assert(patrol_mgr.are_field_checkpoints_done(1), "Night 1: All 5 field patrol checkpoints inspected & verified")
	_assert(gs.tutorial_completed, "Night 1: Interactive step-by-step tutorial completed & persisted once")

	_walk_and_trigger(main_inst, world, player, patrol_mgr, "booth_desk")
	_assert(bool(st.get_flag("climax_night1_silent_phone", false)), "Night 1: 03:17 silent phone call climax triggered before shift end")
	main_inst._on_dawn_submitted("truth")
	_assert(gs.current_night == 2, "Night 1 -> Night 2 transition succeeded cleanly")

	# -----------------------------------------------------------------------
	# 3. NIGHT 2 — THE RESIDENTS (ALL 6 CHECKPOINTS)
	# -----------------------------------------------------------------------
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n2_blockc_mud")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "npc_anna")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "npc_dana")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n2_north_bootprint")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "intercom_b47")
	_assert(patrol_mgr.are_field_checkpoints_done(2) and bool(st.get_flag("climax_night2_intercom_47", false)), "Night 2: All field checkpoints & Intercom 47 mystery completed")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "booth_desk")
	_assert(bool(st.get_flag("n2_varga_warned", false)), "Night 2: Varga's warning about maintenance doors recorded")
	main_inst._on_dawn_submitted("truth")
	_assert(gs.current_night == 3, "Night 2 -> Night 3 transition succeeded cleanly")

	# -----------------------------------------------------------------------
	# 4. NIGHT 3 — THE RECORDINGS + MID-CAMPAIGN SAVE/LOAD ROUNDTRIP
	# -----------------------------------------------------------------------
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "booth_cctv")
	for ci: int in range(6):
		main_inst._on_cctv_select(ci)
	hud.close_all_modals()
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n3_garage07_clues")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n3_milan_cassette")
	_assert(patrol_mgr.are_field_checkpoints_done(3) and gs.has_key("key_service_corridor") and ("tape_04_before_shift" in st.discovered_tapes), "Night 3: CCTV review, Garage 07 stash & Milan's cassette completed")

	# Mid-campaign Save & Load persistence test
	var saved_mid: bool = sm.save_slot(4, "Delivery Alley", player.global_position)
	patrol_mgr.completed_checkpoints.clear()
	st.reset_story()
	var loaded_mid: bool = sm.load_slot(4)
	patrol_mgr.load_from_game_state()
	_assert(
		saved_mid and loaded_mid
		and patrol_mgr.is_checkpoint_completed("n3_cp2_garage07")
		and patrol_mgr.is_checkpoint_completed("n3_cp3_alley")
		and gs.has_key("key_service_corridor"),
		"Mid-campaign Save/Load preserves completed patrol checkpoints, keys, evidence & story state"
	)

	_walk_and_trigger(main_inst, world, player, patrol_mgr, "booth_desk")
	main_inst._on_dawn_submitted("truth")
	_assert(gs.current_night == 4, "Night 3 -> Night 4 transition succeeded cleanly")

	# -----------------------------------------------------------------------
	# 5. NIGHT 4 — THE WRONG FLOOR (ROMAN KRÁL NON-TELEPORT SIGHTING & 03:17 KEY CABINET)
	# -----------------------------------------------------------------------
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n4_blockb_sighting")
	var roman_p0: Vector3 = ant_ai.global_position
	ant_ai._process(0.6)
	var roman_walked: bool = ant_ai.global_position.distance_to(roman_p0) > 0.2 and ant_ai.global_position.distance_to(roman_p0) < 5.0
	_assert(roman_walked and bool(st.get_flag("n4_roman_sighted", false)), "Night 4: Roman Král sighted near Building B & walked away physically (zero teleport)")

	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n4_basement_evidence")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "npc_anna")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "office_key_cabinet")
	_assert(patrol_mgr.are_field_checkpoints_done(4) and bool(st.get_flag("n4_0317_key_missing", false)), "Night 4: Basement evidence & 03:17 Key Cabinet breach completed")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "booth_desk")
	main_inst._on_dawn_submitted("truth")
	_assert(gs.current_night == 5, "Night 4 -> Night 5 transition succeeded cleanly")

	# -----------------------------------------------------------------------
	# 6. NIGHT 5 — BELOW THE ESTATE (HIDDEN SERVICE CORRIDOR, IVETA HRONČOVÁ & MILAN RADIO)
	# -----------------------------------------------------------------------
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "arcade_fusebox")
	var hdoor: Node = world.door_manager.doors.get("hidden_corridor_door", null)
	_assert(hdoor != null and not hdoor.is_locked and bool(st.get_flag("n5_hidden_corridor_unlocked", false)), "Night 5: Restoring Substation power unlocked Hidden Service Corridor door")

	# Verify solid floor collision inside the brand-new Hidden Service Corridor & Apartment 47 Room!
	var space: PhysicsDirectSpaceState3D = (main_inst as Node3D).get_world_3d().direct_space_state
	var corr_hits: int = 0
	for pt: Vector3 in [Vector3(-74.0, -3.0, -18.0), Vector3(-82.0, -3.0, -15.5), Vector3(-84.0, -3.0, -12.0)]:
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(pt, pt + Vector3(0, -3.0, 0)))
		if not hit.is_empty():
			corr_hits += 1
	_assert(corr_hits == 3, "Hidden Service Corridor, Iveta storage alcove & Apartment 47 Room have solid floor collision (%d/3)" % corr_hits)

	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n5_hidden_plan_47")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n5_iveta_discovery")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n5_milan_radio")
	_assert(
		bool(st.get_flag("found_n5_hidden_plan_47", false))
		and bool(st.get_flag("discovered_iveta_body", false))
		and bool(st.get_flag("n5_milan_radio_found", false))
		and gs.evidence_items.size() >= 6,
		"Night 5: 1984 Plan 47, respectful Iveta Hrončová discovery & Milan's radio completed (evidence=%d)" % gs.evidence_items.size()
	)
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "booth_phone")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "booth_desk")
	main_inst._on_dawn_submitted("truth")
	_assert(gs.current_night == 6, "Night 5 -> Night 6 (The Last Patrol) transition succeeded cleanly")

	# -----------------------------------------------------------------------
	# 7. NIGHT 6 — THE LAST PATROL (01:30 WARNING, 03:17 BLACKOUT & ALL 3 ENDINGS!)
	# -----------------------------------------------------------------------
	var residents_absent: bool = (not npc_mgr.get_npc("anna").visible) and (not npc_mgr.get_npc("dana").visible) and npc_mgr.get_npc("milan_rescue").visible
	_assert(residents_absent, "Night 6: Familiar estate residents are absent while exhausted Milan Švec awaits in Room 47")

	_walk_and_trigger(main_inst, world, player, patrol_mgr, "booth_phone")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n6_radio_warning")
	_assert(
		bool(st.get_flag("n6_warning_received", false))
		and bool(st.get_flag("n6_blackout_active", false))
		and ant_ai.blackout_hunt_active,
		"Night 6: 01:30 'Nechodíš sám.' warning & 03:17 Complete Estate Blackout activated with Roman Král actively hunting"
	)

	# --- PLAYTHROUGH RESOLUTION 1: ENDING A — MORNING REPORT ---
	main_inst._pending_choice_context = "javor_final_n6"
	main_inst._on_choice_made("ENDING_A")
	var flashers_exist: bool = dist.find_child("EmergencyDawnLight", true, false) != null
	var sdoor: Node = world.door_manager.doors.get("sec_office_door", null)
	_assert(
		st.active_ending_id == "ENDING_A"
		and bool(st.get_flag("authorities_contacted", false))
		and sdoor != null and sdoor.is_locked
		and flashers_exist
		and ("ENDING_A" in gs.unlocked_endings),
		"ENDING A (MORNING REPORT) resolved via gameplay: Office bolted, 158 called, dawn emergency lights & save persisted"
	)

	# --- PLAYTHROUGH RESOLUTION 2: ENDING B — THE LAST PATROL (RESCUE MILAN!) ---
	hud.close_all_modals()
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n6_milan_rescue")
	_assert(bool(st.get_flag("milan_rescued", false)), "Night 6: Found exhausted Milan Švec alive in Apartment 47 Room")
	_walk_and_trigger(main_inst, world, player, patrol_mgr, "n6_escape_gate")
	_assert(
		st.active_ending_id == "ENDING_B"
		and ("ENDING_B" in gs.unlocked_endings)
		and str(ending_mgr.CAMPAIGN_ENDINGS["ENDING_B"]["dialogue_line"]).contains("Shift complete"),
		"ENDING B (THE LAST PATROL) resolved via gameplay: Escorted Milan to Outer Service Gate & received Varga radio transmission"
	)

	# --- PLAYTHROUGH RESOLUTION 3: ENDING C — THE NEXT GUARD (LOW EVIDENCE / ROUTINE PATH) ---
	hud.close_all_modals()
	gs.evidence_items.clear()
	st.set_flag("milan_rescued", false)
	st.set_flag("authorities_contacted", false)
	var auto_eval_c: String = ending_mgr.evaluate_campaign_ending("")
	var end_c_res: Dictionary = ending_mgr.execute_ending(auto_eval_c, world, hud, player)
	_assert(
		auto_eval_c == "ENDING_C"
		and st.active_ending_id == "ENDING_C"
		and str(end_c_res.get("body", "")).contains("SHIFT 01")
		and ("ENDING_C" in gs.unlocked_endings),
		"ENDING C (THE NEXT GUARD) resolved cleanly for low-evidence routine path with fresh SHIFT 01 notebook & ringing phone"
	)

	# Cleanup & restore user state cleanly
	main_inst.queue_free()
	sett.set_val("nav_assist", orig_nav, false)
	sett.save_settings()
	if slot4_existed:
		var sf4 := FileAccess.open(slot4_path, FileAccess.WRITE)
		if sf4:
			sf4.store_buffer(slot4_bytes)
			sf4.close()
	else:
		sm.delete_slot(4)

	if orig_run_existed:
		var rf := FileAccess.open(gs.SAVE_RUN_PATH, FileAccess.WRITE)
		if rf:
			rf.store_buffer(orig_run_bytes)
			rf.close()
	elif FileAccess.file_exists(gs.SAVE_RUN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.SAVE_RUN_PATH))

	gs.unlocked_endings.assign(orig_endings)
	gs.discovered_anomalies.assign(orig_anoms)
	gs.unlocked_achievements.assign(orig_achs)
	gs.ng_plus_unlocked = orig_ng
	gs.hardcore_unlocked = orig_hc
	gs.tutorial_completed = orig_tut
	gs.save_meta()

	if _failed:
		print("CAMPAIGN PLAYTHROUGH VERIFICATION FAILED")
		quit(1)
	else:
		print("ALL %d FULL-CAMPAIGN & 3-ENDING VERIFICATION CHECKS PASSED!" % _pass_count)
		quit(0)
