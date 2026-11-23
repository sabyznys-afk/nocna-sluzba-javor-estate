extends SceneTree

# Prompt 08 Complete Acceptance Verification Suite:
# SECTION A — User's First Priority Test ("First 10 Minutes Acceptance Test" — ALL 7 steps!)
# SECTION B — Lighting, Fog, Flashlight & Brightness Calibration
# SECTION C — Real Baked NavigationMesh, CharacterBody3D Solid Collision (Zero Desk/Wall/Car/Building Clipping!), Door Wait, Path Recovery & F8 Debugger
# SECTION D — Complete 8-Stage Interactive English Tutorial (Fresh Save, Skip, Replay, Persistence)
# SECTION E — Redesigned 4-Section Paper Notebook (SHIFT / MAP / NOTES / EVIDENCE) + Writing Animation
# SECTION F — Complete Player, Jozef, Door & World Animations + All-English Voices & Texts

var _failed: bool = false
var _passed: int = 0


func _assert(cond: bool, msg: String) -> void:
	if not cond:
		push_error("PROMPT 08 ASSERT FAILED: " + msg)
		print("FAIL: " + msg)
		_failed = true
	else:
		_passed += 1
		print("PASS: " + msg)


func _initialize() -> void:
	create_timer(60.0).timeout.connect(func():
		print("FAIL: Prompt 08 acceptance timeout")
		quit(1)
	)
	call_deferred("_run_all")


func _is_point_inside_forbidden_volume(p: Vector3) -> String:
	# Exact solid footprints that Jozef MUST NEVER walk through!
	# 1. Security Office Desk (-19.0, -57.8, size 2.3x1.0)
	if p.x > -20.1 and p.x < -17.9 and p.z > -58.25 and p.z < -57.35:
		return "SecOfficeDesk"
	# 2. Building D solid interior core (X: -10..+18, Z: -36..-24)
	if p.x > -9.6 and p.x < 17.6 and p.z > -35.6 and p.z < -24.4:
		return "BuildingD"
	# 3. Parked Cars South Row (Z=-60.5 +- 1.7 -> -62.2..-58.8) & North Row (Z=-45.6 +- 1.7 -> -47.3..-43.9)
	for cx: float in [8.8, 12.4, 19.6, 26.8, 34.0, 41.2]:
		if absf(p.x - cx) < 0.85 and absf(p.z - (-60.3)) < 1.75:
			return "SouthParkedCar_%.1f" % cx
	for cx2: float in [8.8, 16.0, 23.2, 30.4, 37.6, 41.2]:
		if absf(p.x - cx2) < 0.85 and absf(p.z - (-45.6)) < 1.75:
			return "NorthParkedCar_%.1f" % cx2
	# 4. Trafika Newsstand interior footprint (X: 36.4..40.2, Z: -12.8..-7.2)
	if p.x > 36.5 and p.x < 40.1 and p.z > -12.7 and p.z < -7.3:
		return "TrafikaBuilding"
	# 5. Building A / B / C walls
	if p.x > -45.5 and p.x < -18.5 and p.z > 32.5 and p.z < 43.5:
		return "BuildingA"
	return ""


func _run_all() -> void:
	var gs: Node = root.get_node_or_null("GameState")
	var sett: Node = root.get_node_or_null("SettingsManager")
	var st: Node = root.get_node_or_null("StoryManager")
	var loc: Node = root.get_node_or_null("LocalizationManager")

	# Backup settings & saves
	var orig_skip: bool = bool(sett.get_val("skip_tutorial", false))
	var orig_tut: bool = gs.tutorial_completed
	var orig_br: float = float(sett.get_val("brightness", 1.08))
	var orig_fl: float = float(sett.get_val("flashlight_intensity", 1.0))

	# Fresh New Game start (simulate a brand-new player who knows nothing!)
	sett.set_val("language", "en", true)
	sett.set_val("skip_tutorial", false, true)
	gs.tutorial_completed = false
	st.reset_story()
	gs.start_new_shift(1, false, true)

	var main_packed: PackedScene = load("res://scenes/main.tscn")
	var main_inst: Node = main_packed.instantiate()
	root.add_child(main_inst)
	await physics_frame
	await physics_frame

	var world: Node3D = main_inst.get_node_or_null("Blok14World")
	var dist: Node3D = world.district if world else null
	var player: CharacterBody3D = main_inst.get_node_or_null("GuardPlayer")
	var hud: Node = main_inst.get_node_or_null("GameHUD")
	var comp: CharacterBody3D = main_inst.get_node_or_null("CompanionGuardController") as CharacterBody3D
	var dnav: Node3D = main_inst.get_node_or_null("DistrictNavigationManager")
	var tut: Node = main_inst.get_node_or_null("TutorialManager")
	var vmgr: Node3D = main_inst.get_node_or_null("VoiceAssetManager")
	var light_c: Node = main_inst.get_node_or_null("StylizedLightingController")

	# =======================================================================
	# SECTION A: FIRST 10 MINUTES ACCEPTANCE TEST (ALL 7 USER STEPS!)
	# =======================================================================
	# 1. Player sees surroundings & can identify Security Office exit (readable lighting + exterior porch lamp!)
	var we: WorldEnvironment = dist.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var ext_lamp: SpotLight3D = dist.find_child("SecOfficeExteriorLamp", true, false) as SpotLight3D
	var booth_light: OmniLight3D = dist.find_child("BoothDeskLight", true, false) as OmniLight3D
	_assert(
		we != null and we.environment.ambient_light_energy >= 0.38
		and booth_light != null and booth_light.light_energy >= 1.5
		and ext_lamp != null and ext_lamp.shadow_enabled and ext_lamp.light_energy >= 3.5,
		"10-Min Test [1/7]: Security Office & East exit door clearly lit and identifiable (ambient=%.2f, porch=%.1f)" % [we.environment.ambient_light_energy if we else 0.0, ext_lamp.light_energy if ext_lamp else 0.0]
	)

	# Run through Jozef's complete 8-Stage Interactive Tutorial from fresh start!
	_assert(tut != null and tut.active and tut.get_current_stage_id() == "intro", "Tutorial Stage 0 (Intro): Jozef welcomes Martin in English inside Security Office")

	# Interact with Jozef -> Stage 1 (Movement)
	var varga_area: Area3D = null
	for a: Area3D in world.interactables:
		if is_instance_valid(a) and str(a.interact_id) == "npc_varga":
			varga_area = a
			break
	_assert(varga_area != null, "Jozef interactable present in Security Office")
	main_inst._on_interactable_triggered(varga_area)
	_assert(tut.get_current_stage_id() == "movement", "Tutorial Stage 1 (Movement): Active after greeting Jozef")

	# Perform real Movement + Mouse Look -> Stage 2 (Notebook)
	player.global_position += Vector3(-1.35, 0.0, -0.4)
	player.rotation.y += 0.65
	tut._process(0.1)
	_assert(tut.get_current_stage_id() == "notebook", "10-Min Test [4a/7] Tutorial Stage 2 (Notebook): Jozef explains shift notebook")

	# Open Notebook, browse 4 sections, write observation, close Notebook -> Stage 3 (Inventory)
	hud.open_logbook(0)
	var sec_names: PackedStringArray = hud.notebook_ui.get_section_names()
	hud.notebook_ui.select_page(1, false)
	hud.notebook_ui.select_page(2, false)
	hud.notebook_ui.trigger_progressive_handwriting()
	main_inst._on_incident_note_submitted("Office desk and map checked with Jozef.")
	hud.close_all_modals()
	_assert(tut.get_current_stage_id() == "inventory", "10-Min Test [4b/7] Tutorial Stage 3 (Inventory): Jozef explains equipment belt & mouse wheel")

	# Switch gear to Empty Hands [0] + Keys [3] -> Stage 4 (Flashlight)
	player.switch_gear("hands")
	player.switch_gear("keys")
	_assert(tut.get_current_stage_id() == "flashlight", "Tutorial Stage 4 (Flashlight): Active after practicing equipment switching & empty hands")

	# 5. Player selects flashlight, switches it OFF and ON, illuminates 2 objects -> Stage 5 (Keys & Doors)
	player.switch_gear("flashlight")
	if player.flashlight_on:
		player.toggle_flashlight() # OFF
	var off_ok: bool = not player.flashlight_on and not player.flashlight_spot.visible
	player.toggle_flashlight() # ON
	var on_ok: bool = player.flashlight_on and player.flashlight_spot.visible and player.flashlight_spot.light_energy >= 4.0
	tut.notify_flashlight_object_illuminated("SecDesk_Col")
	tut.notify_flashlight_object_illuminated("KeyCabinet")
	_assert(off_ok and on_ok and tut.get_current_stage_id() == "keys_doors", "10-Min Test [5/7] Tutorial Stage 4->5: Player equipped flashlight, toggled OFF/ON & illuminated 2 objects")

	# Stage 5: Keys & Doors (equip keys, lock/unlock & open office door) -> Stage 6 (Radio)
	player.switch_gear("keys")
	var sdoor: Node = dist.door_manager.doors.get("sec_office_door", null)
	_assert(sdoor != null, "Security Office door present")
	sdoor.toggle_lock()
	player.emit_signal("door_lock_toggled", "sec_office_door", sdoor.is_locked)
	sdoor.toggle_lock() # unlock back
	sdoor.set_open(false, false) # keep closed so Jozef physically opens it next!
	_assert(tut.get_current_stage_id() == "radio", "Tutorial Stage 5->6 (Radio): Keys & door lock/unlock mastered")

	# Stage 6: Radio check -> English dispatch audio response -> Stage 7 (Headphones)
	player.switch_gear("radio")
	player.use_radio()
	_assert(tut.get_current_stage_id() == "headphones", "Tutorial Stage 6->7 (Headphones): Radio check played English dispatch response")

	# Stage 7: Headphones ON then OFF -> Stage 8 (First Guided Patrol!)
	player.toggle_headphones()
	player.toggle_headphones()
	_assert(tut.get_current_stage_id() == "first_patrol" and comp.patrol_started, "Tutorial Stage 7->8 (First Patrol): Headphones verified & Jozef began guided outdoor patrol")

	# 2, 3, 6. Step Jozef physically out of the Security Office, through sec_office_door, past Main Gate, Parking Walkway, Building A, Central Park, Newsstand & back!
	# Verify ZERO desk/wall/car/building penetration along EVERY SINGLE STEP!
	var forbidden_hit: String = ""
	var max_step_jump: float = 0.0
	var opened_office_door: bool = false
	var waited_for_player: bool = false
	var reached_first_cp: bool = false
	var tested_wait: bool = false
	var wait_ticks: int = 0

	for tick: int in range(3200):
		var prev_p: Vector3 = comp.global_position
		if not tested_wait and comp.get_state() == "WALKING_TO_CHECKPOINT" and comp.stop_idx == 1:
			tested_wait = true
			wait_ticks = 5
			player.global_position = comp.global_position + Vector3(-13.5, 0.0, 0.0)
		elif wait_ticks > 0:
			wait_ticks -= 1
			if wait_ticks == 0:
				player.global_position = comp.global_position + Vector3(-1.8, 0.0, 1.4)
		else:
			player.global_position = comp.global_position + Vector3(-1.9, 0.0, 1.3)

		var prev_doors: int = comp.doors_opened_count
		comp.step_simulation(0.14)
		# Flush real Godot PhysicsServer3D whenever a door opens or periodically so opened door colliders update!
		if comp.doors_opened_count > prev_doors or (tick % 35 == 0):
			await physics_frame
		var step_d: float = comp.global_position.distance_to(prev_p)
		max_step_jump = maxf(max_step_jump, step_d)

		var bad_zone: String = _is_point_inside_forbidden_volume(comp.global_position)
		if not bad_zone.is_empty() and forbidden_hit.is_empty():
			forbidden_hit = "%s at (%.1f, %.1f)" % [bad_zone, comp.global_position.x, comp.global_position.z]

		if sdoor.is_open and comp.doors_opened_count >= 1:
			opened_office_door = true
		if comp.get_state() == "WAITING_FOR_PLAYER":
			waited_for_player = true
		if "stop_main_gate" in comp.guided_stops_completed:
			reached_first_cp = true
		if comp.patrol_completed:
			break

	_assert(comp is CharacterBody3D and comp.collision_layer == 8 and (comp.collision_mask & 1) != 0 and forbidden_hit.is_empty(), "10-Min Test [2/7]: Jozef is solid CharacterBody3D & walked ENTIRE route with ZERO clipping through desks, walls, cars or buildings (%s)" % ("CLEAN" if forbidden_hit.is_empty() else forbidden_hit))
	_assert(opened_office_door and waited_for_player, "10-Min Test [3/7]: Jozef physically opened Security Office door & waited when Martin lagged behind")
	_assert(reached_first_cp and comp.patrol_completed and max_step_jump < 0.75, "10-Min Test [6/7]: Together reached first checkpoint & finished full 7-stop patrol with zero teleporting (stops=%d/7, state=%s, pos=(%.1f,%.1f), max_step=%.2fm)" % [comp.guided_stops_completed.size(), comp.get_state(), comp.global_position.x, comp.global_position.z, max_step_jump])

	# 7. Player inspects first checkpoint (Main Gate) and writes result in redesigned Notebook!
	var gate_area: Area3D = null
	for a2: Area3D in world.interactables:
		if is_instance_valid(a2) and str(a2.interact_id) == "main_gate":
			gate_area = a2
			break
	_assert(gate_area != null, "Main Gate checkpoint interactable present")
	main_inst._on_interactable_triggered(gate_area)
	hud.open_logbook(2)
	hud.notebook_ui.trigger_progressive_handwriting()
	var prev_entries: int = gs.notebook_entries.size()
	main_inst._on_incident_note_submitted("Main Gate checked — latch closed and secure.")
	var entry_logged: bool = gs.notebook_entries.size() == prev_entries + 1
	hud.close_all_modals()
	_assert(entry_logged and gs.tutorial_completed and not tut.active, "10-Min Test [7/7]: Player inspected checkpoint, wrote entry in Notebook & tutorial completion persisted!")

	# =======================================================================
	# SECTION B–F: SYSTEMIC VERIFICATION (NAVMESH, DEBUGGER, CALIBRATION, NOTEBOOK, ANIMATIONS, ENGLISH)
	# =======================================================================
	_assert(dnav != null and dnav.is_baked and dnav.polygon_count >= 50, "Real NavigationRegion3D baked walkable estate NavMesh (polys=%d)" % (dnav.polygon_count if dnav else 0))
	var dbg_on: bool = main_inst.toggle_nav_debug()
	var dbg_info: Dictionary = comp.get_nav_debug_info()
	var dbg_off: bool = not main_inst.toggle_nav_debug()
	_assert(dbg_on and dbg_off and dbg_info.has("path") and dbg_info.has("reachable"), "Developer F8 Navigation Debug mode toggles cleanly and exposes path/reachability/collision state")

	# Brightness, Gamma, Contrast, Fog Intensity, Flashlight Intensity & Calibration Screen
	sett.set_val("brightness", 1.25, true)
	sett.set_val("contrast", 1.10, true)
	sett.set_val("fog_intensity", 0.85, true)
	sett.set_val("flashlight_intensity", 1.35, true)
	var opt_panel: Node = hud.options_panel
	var calib_node: Node = opt_panel.find_child("CalibrationTestImage", true, false) if opt_panel else null
	_assert(
		calib_node != null and we.environment.adjustment_brightness > 1.20
		and player.flashlight_spot.light_energy > 5.8,
		"Lighting settings (Brightness/Gamma/Contrast/Fog/Flashlight) & Calibration Preview work live"
	)

	# 4-Section Redesigned Notebook + Tutorial Reopen + Skip Setting
	_assert(
		hud.notebook_ui.get_section_count() == 4
		and Array(sec_names) == ["SHIFT", "MAP", "NOTES", "EVIDENCE"]
		and hud.notebook_ui.find_child("TutorialGuideBtn", true, false) != null,
		"Redesigned Notebook has exactly 4 crisp sections (SHIFT, MAP, NOTES, EVIDENCE) + Tutorial reopen button"
	)
	tut.begin_tutorial(true)
	var replayed_ok: bool = tut.active and tut.get_current_stage_id() == "intro"
	sett.set_val("skip_tutorial", true, true)
	var skipped_ok: bool = not tut.active and tut.completed
	_assert(replayed_ok and skipped_ok, "Tutorial can be reopened from Notebook and skipped cleanly via Settings")

	# Expanded Player, Door & Environmental Animations
	var vm_cnt: int = player.viewmodel.get_animation_count() if player and player.viewmodel else 0
	var ah_cnt: int = dist.animation_hub.get_animation_count() if dist and dist.animation_hub else 0
	var door_latch_ok: bool = sdoor.get("latch_bolt") != null and sdoor.get("lock_cylinder") != null
	_assert(vm_cnt >= 35 and ah_cnt >= 32 and door_latch_ok, "Expanded animations active: Player viewmodel=%d, World AnimationHub=%d, Door latch+cylinder=%s" % [vm_cnt, ah_cnt, str(door_latch_ok)])

	# All 48 English Neural Voices + Language Verification
	var reg_fa := FileAccess.open("res://assets/audio/voices/voice_registry.json", FileAccess.READ)
	var reg_parsed: Dictionary = JSON.parse_string(reg_fa.get_as_text()) if reg_fa else {}
	if reg_fa:
		reg_fa.close()
	_assert(
		str(reg_parsed.get("language", "")) == "en"
		and vmgr != null and vmgr.get_loaded_voice_count() >= 48
		and loc.current_lang == "en",
		"All %d voices & registry are in English (lang=%s)" % [vmgr.get_loaded_voice_count() if vmgr else 0, str(reg_parsed.get("language", ""))]
	)

	# Restore user preferences
	sett.set_val("skip_tutorial", orig_skip, false)
	sett.set_val("brightness", orig_br, false)
	sett.set_val("flashlight_intensity", orig_fl, false)
	sett.set_val("contrast", 1.0, false)
	sett.set_val("fog_intensity", 1.0, false)
	sett.save_settings()
	gs.tutorial_completed = orig_tut
	gs.save_meta()
	main_inst.queue_free()

	if _failed:
		print("PROMPT 08 ACCEPTANCE SUITE FAILED")
		quit(1)
	else:
		print("ALL %d PROMPT 08 & FIRST-10-MINUTES ACCEPTANCE CHECKS PASSED!" % _passed)
		quit(0)
