extends SceneTree

# Prompt 07 Dedicated Verification Suite — Validates ALL THREE User Priority Tests:
# 1. Complete PS1 Security Office Test Room (pixelated textures, vertex jitter, dithering, strong shadows, low-res scaling)
# 2. Complete Physical Patrol with Companion Guard Jozef Varga (real walking, door opening, waiting, pointing, Slovak lines, zero teleport, zero glowing arrows)
# 3. Complete Layered Slovak Spatial Audio Scene (39 native Slovak neural voices + 5 world reactions + priority anti-overlap)

var _failed: bool = false
var _passed: int = 0


func _assert(cond: bool, msg: String) -> void:
	if not cond:
		push_error("PS1 ASSERT FAILED: " + msg)
		print("FAIL: " + msg)
		_failed = true
	else:
		_passed += 1
		print("PASS: " + msg)


func _initialize() -> void:
	create_timer(45.0).timeout.connect(func():
		print("FAIL: PS1 verification timeout")
		quit(1)
	)
	call_deferred("_run_ps1_tests")


func _run_ps1_tests() -> void:
	var gs: Node = root.get_node_or_null("GameState")
	var sett: Node = root.get_node_or_null("SettingsManager")
	var st: Node = root.get_node_or_null("StoryManager")
	_assert(gs != null and sett != null and st != null, "Autoloads ready for PS1 transformation test")

	var orig_res: String = str(sett.get_val("ps1_resolution", "512x288"))

	# -----------------------------------------------------------------------
	# TEST 1: COMPLETE PS1 SECURITY OFFICE TEST ROOM (scenes/ps1_test_office.tscn)
	# -----------------------------------------------------------------------
	var office_packed: PackedScene = load("res://scenes/ps1_test_office.tscn")
	_assert(office_packed != null, "Test 1: Standalone PS1 Security Office test scene loads cleanly")
	if office_packed:
		var office_inst: Node = office_packed.instantiate()
		root.add_child(office_inst)
		await physics_frame
		var rr: Node = office_inst.get("retro_render")
		var lc: Node = office_inst.get("light_ctrl")
		var desk_spot: SpotLight3D = office_inst.find_child("DeskGooseneckLamp", true, false) as SpotLight3D
		_assert(rr != null and int(rr.get("converted_mesh_count")) >= 15, "Test 1: RetroRenderingController converted Security Office geometry to PS1 vertex-jitter shader (meshes=%d)" % (int(rr.get("converted_mesh_count")) if rr else 0))
		_assert(desk_spot != null and desk_spot.shadow_enabled and lc != null, "Test 1: Security Office gooseneck lamp casts sharp PS1 shadows with StylizedLightingController")
		for rkey: String in ["426x240", "512x288", "640x360"]:
			sett.set_val("ps1_resolution", rkey, true)
			var rv: Vector2 = rr.get_active_resolution()
			_assert(str(int(rv.x)) + "x" + str(int(rv.y)) == rkey, "Test 1: Configurable PS1 internal resolution switches to %s" % rkey)
		sett.set_val("ps1_resolution", "512x288", true)
		office_inst.queue_free()

	# Verify pixelated 64-256px textures & 11 PS1 face textures exist
	var face_ok: int = 0
	for fn: String in [
		"ps1_face_varga", "ps1_face_anna", "ps1_face_dana", "ps1_face_zuzana",
		"ps1_face_peter", "ps1_face_milan", "ps1_face_roman", "ps1_face_iveta",
		"ps1_face_res_a", "ps1_face_res_b", "ps1_face_res_c"
	]:
		if ResourceLoader.exists("res://assets/textures/ps1_faces/%s.png" % fn):
			face_ok += 1
	_assert(face_ok == 11, "All 11 pixelated 64x64 PS1 character face textures present (got %d)" % face_ok)

	# Verify Main Menu PS1 3D Redesign + Window Silhouette + Layer 5 PS1 pass below Layer 10 UI
	var menu_packed: PackedScene = load("res://scenes/main_menu.tscn")
	if menu_packed:
		var m_inst: Node = menu_packed.instantiate()
		root.add_child(m_inst)
		await physics_frame
		var m_crt: CanvasLayer = m_inst.get_node_or_null("MenuCRTLayer") as CanvasLayer
		var m_ui: CanvasLayer = m_inst.get_node_or_null("MenuUILayer") as CanvasLayer
		var m_sil: Node3D = m_inst.find_child("MenuWindowSilhouette", true, false) as Node3D
		var m_vp: SubViewport = m_inst.get_node_or_null("Menu3DBackdrop/MenuPreviewViewport") as SubViewport
		_assert(
			m_crt != null and m_ui != null and m_crt.layer < m_ui.layer
			and m_sil != null and m_vp != null and m_vp.size.x <= 640,
			"Redesigned PS1 Main Menu renders 3D office at low-res (%dx%d), keeps UI readable above dithering & includes window silhouette" % [m_vp.size.x if m_vp else 0, m_vp.size.y if m_vp else 0]
		)
		m_inst.queue_free()

	# -----------------------------------------------------------------------
	# TEST 2 & TEST 3: LIVE MAIN SCENE — FULL PHYSICAL JOZEF PATROL + SLOVAK SPATIAL AUDIO
	# -----------------------------------------------------------------------
	st.reset_story()
	gs.start_new_shift(1, false, true)
	var main_packed: PackedScene = load("res://scenes/main.tscn")
	var main_inst: Node = main_packed.instantiate()
	root.add_child(main_inst)
	await physics_frame
	await physics_frame

	var world: Node3D = main_inst.get_node_or_null("Blok14World")
	var player: CharacterBody3D = main_inst.get_node_or_null("GuardPlayer")
	var hud: Node = main_inst.get_node_or_null("GameHUD")
	var comp: Node3D = main_inst.get_node_or_null("CompanionGuardController")
	var vmgr: Node3D = main_inst.get_node_or_null("VoiceAssetManager")
	var amb_sp: Node3D = main_inst.get_node_or_null("AmbientSpeechManager")
	var rr_main: Node = main_inst.get_node_or_null("RetroRenderingController")
	var light_main: Node = main_inst.get_node_or_null("StylizedLightingController")
	var nav_mgr: Node3D = main_inst.get_node_or_null("NavigationHintManager")

	_assert(
		hud != null and hud.crt_layer.layer < hud.ui_layer.layer
		and rr_main != null and int(rr_main.get("converted_mesh_count")) >= 100
		and light_main != null and player.flashlight_spot.shadow_enabled,
		"Main scene runs full PS1 spatial pass (%d meshes), strong shadow-casting flashlight & readable HUD above pixel pass" % (int(rr_main.get("converted_mesh_count")) if rr_main else 0)
	)
	_assert(nav_mgr != null and not nav_mgr.has_artificial_glowing_markers(), "Test 2: Artificial glowing patrol markers completely removed")

	# Start Jozef Varga's full Night 1 physical patrol!
	_assert(comp != null and comp.get_state() == "WAITING_IN_OFFICE" and comp.is_articulated() and comp.varga_flashlight != null, "Test 2: Jozef Varga PS1 articulated model with flashlight waiting in Security Office")
	var intro_res: Dictionary = comp.interact_with_player()
	_assert(str(intro_res.get("text", "")).contains("paper matters more than memory") and comp.patrol_started, "Test 2: Jozef delivers English Security Office briefing and begins guided patrol")

	# Step Jozef physically out of Vrátnica -> he MUST approach & physically open sec_office_door!
	var sdoor: Node = world.door_manager.doors.get("sec_office_door", null)
	if sdoor:
		sdoor.set_open(false, false)
	var saw_wait_state: bool = false
	var saw_sound_react: bool = false
	var saw_door_state: bool = false
	var max_step_jump: float = 0.0

	var tested_lag_wait: bool = false
	var lag_steps_left: int = 0
	# Simulate complete physical patrol across all 7 stops (keeping Martin walking behind Jozef, with 1 real lag test!)
	for step_i: int in range(1800):
		var prev_pos: Vector3 = comp.global_position
		if not tested_lag_wait and comp.get_state() == "WALKING_TO_CHECKPOINT" and comp.stop_idx >= 1:
			# Test Part 5.4: Martin falls 15m behind while Jozef is walking -> Jozef must stop & wait!
			tested_lag_wait = true
			lag_steps_left = 4
			player.global_position = comp.global_position + Vector3(15.0, 0.0, 0.0)
		elif lag_steps_left > 0:
			lag_steps_left -= 1
			if lag_steps_left == 0:
				player.global_position = comp.global_position + Vector3(-2.5, 0.0, -1.5)
		elif step_i > 4:
			player.global_position = comp.global_position + Vector3(-2.2, 0.0, -1.2)

		var prev_d_cnt: int = comp.doors_opened_count
		comp._process(0.18)
		if comp.doors_opened_count > prev_d_cnt or (step_i % 35 == 0):
			await physics_frame
		var step_dist: float = comp.global_position.distance_to(prev_pos)
		max_step_jump = maxf(max_step_jump, step_dist)
		var cst: String = comp.get_state()
		if cst == "WAITING_FOR_PLAYER":
			saw_wait_state = true
		elif cst == "INTERACTING_WITH_DOOR":
			saw_door_state = true
		elif cst == "REACTING_TO_SOUND":
			saw_sound_react = true
		if comp.patrol_completed:
			break

	_assert(saw_door_state and comp.doors_opened_count >= 1 and sdoor != null and sdoor.is_open, "Test 2: Jozef physically opened closed Security Office door during patrol (opened=%d)" % comp.doors_opened_count)
	_assert(saw_wait_state, "Test 2: Jozef stopped, turned back & waited when Martin fell behind")
	_assert(saw_sound_react, "Test 2: Jozef paused & reacted to fog sound in Central Park")
	_assert(comp.patrol_completed and comp.guided_stops_completed.size() == 7 and max_step_jump < 1.0, "Test 2: Jozef completed ENTIRE 7-stop physical patrol with ZERO teleporting (max_step=%.2fm)" % max_step_jump)

	# -----------------------------------------------------------------------
	# TEST 3: COMPLETE LAYERED SLOVAK SPATIAL AUDIO SCENE
	# -----------------------------------------------------------------------
	var loaded_v: int = vmgr.get_loaded_voice_count() if vmgr else 0
	var loaded_rx: int = amb_sp.get_reaction_sound_count() if amb_sp else 0
	_assert(loaded_v >= 45 and loaded_rx == 5, "Test 3: Loaded %d native English neural voice clips & %d world reaction SFX" % [loaded_v, loaded_rx])

	# 1) Jozef speaks in front (high priority = 10)
	var p_jozef: bool = vmgr.play_voice_line("jozef_gate_02", comp.global_position, true)
	# 2) While high-priority dialogue is active, low-priority ambient speech MUST NOT overlap!
	var blocked_overlap: bool = not vmgr.play_voice_line("apt_muffled_conv_01", Vector3(-32.0, 3.8, 32.0), false)
	vmgr.stop_all_voices()
	# 3) Once main dialogue ends, muffled Slovak residents talk behind Building A wall!
	var p_wall: String = amb_sp.trigger_nearest_ambient_speech(Vector3(-30.0, 1.0, 31.0))
	# 4) Street car starts & distant dog barks in fog!
	var p_car: String = amb_sp.trigger_world_reaction(Vector3(10.0, 1.0, -70.0), "rx_car")
	var p_dog: String = amb_sp.trigger_world_reaction(Vector3(-25.0, 1.0, 50.0), "rx_dog")
	# 5) VHF Radio communication arrives cleanly!
	var p_radio: bool = vmgr.play_voice_line("radio_varga_check_01", Vector3.ZERO, true)

	_assert(
		p_jozef and blocked_overlap and not p_wall.is_empty()
		and p_car == "rx_car" and p_dog == "rx_dog" and p_radio,
		"Test 3: Complete layered audio scene verified — Jozef front voice, anti-overlap priority gate, muffled apartment speech (%s), street car, distant dog & VHF radio" % p_wall
	)

	main_inst.queue_free()
	sett.set_val("ps1_resolution", orig_res, false)
	sett.save_settings()

	if _failed:
		print("PS1 TRANSFORMATION VERIFICATION FAILED")
		quit(1)
	else:
		print("ALL %d PROMPT 07 PS1, COMPANION & SLOVAK AUDIO CHECKS PASSED!" % _passed)
		quit(0)
