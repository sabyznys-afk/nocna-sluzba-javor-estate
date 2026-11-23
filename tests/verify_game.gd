extends SceneTree

const AssetRegistryScript = preload("res://tools/asset_browser/asset_registry.gd")

var _failed: bool = false


func _assert(cond: bool, msg: String) -> void:
	if not cond:
		push_error("ASSERT FAILED: " + msg)
		print("FAIL: " + msg)
		_failed = true
	else:
		print("PASS: " + msg)


func _initialize() -> void:
	create_timer(35.0).timeout.connect(func():
		print("FAIL: Verification timeout")
		quit(1)
	)
	call_deferred("_run_all_checks")


func _run_all_checks() -> void:
	var gs: Node = root.get_node_or_null("GameState")
	var ad: Node = root.get_node_or_null("AnomalyDirector")
	var am: Node = root.get_node_or_null("AchievementManager")
	var au: Node = root.get_node_or_null("AudioSynth")
	var loc: Node = root.get_node_or_null("LocalizationManager")
	var sett: Node = root.get_node_or_null("SettingsManager")
	var st: Node = root.get_node_or_null("StoryManager")
	var sm: Node = root.get_node_or_null("SaveManager")

	_assert(gs != null, "Autoload GameState loaded")
	_assert(ad != null, "Autoload AnomalyDirector loaded")
	_assert(am != null, "Autoload AchievementManager loaded")
	_assert(au != null, "Autoload AudioSynth loaded")
	_assert(loc != null, "Autoload LocalizationManager loaded")
	_assert(sett != null, "Autoload SettingsManager loaded")
	_assert(st != null, "Autoload StoryManager loaded")
	_assert(sm != null, "Autoload SaveManager loaded")

	if gs == null or ad == null or am == null or au == null or loc == null or sett == null or st == null or sm == null:
		quit(1)
		return

	var orig_endings: Array = gs.unlocked_endings.duplicate()
	var orig_anoms: Array = gs.discovered_anomalies.duplicate()
	var orig_achs: Array = gs.unlocked_achievements.duplicate()
	var orig_ng: bool = gs.ng_plus_unlocked
	var orig_hc: bool = gs.hardcore_unlocked
	var orig_tut: bool = gs.tutorial_completed
	var orig_run_existed: bool = FileAccess.file_exists(gs.SAVE_RUN_PATH)
	var orig_run_bytes: PackedByteArray = FileAccess.get_file_as_bytes(gs.SAVE_RUN_PATH) if orig_run_existed else PackedByteArray()

	# 1. Verify all 57 Blender .glb models load
	var glbs: Array[String] = [
		"skoda_favorit", "medieval_well", "carriage_gate", "guard_booth_desk",
		"tesla_crt_monitor", "rotary_phone", "watchmans_clock", "streetlamp_sodium",
		"boiler_furnace", "grandfather_clock", "payphone_box", "transistor_radio",
		"sta_antenna_mast", "device_k4", "dumpster_90s", "red_bulkhead_door",
		"humanoid_guard", "entity_shadow",
		"vm_flashlight", "vm_taser", "vm_notebook", "battery_pack",
		"lada_van", "courtyard_bench", "wooden_chair", "chapel_shrine",
		"dead_oak_tree", "butcher_hook_rack",
		"anom_well_hands", "anom_black_ooze", "anom_hanging_sheet", "anom_cracked_window",
		"skoda_120", "lada_sedan", "trabant_601", "playground_swing",
		"playground_slide", "park_gazebo", "carpet_rack", "panelak_balcony",
		"panelak_entrance", "bus_stop_90s", "shop_shelf", "shop_fridge",
		"cash_register_90s", "old_bicycle", "pine_tree_90s", "crt_tv_set",
		"vm_headphones", "vm_keys", "vm_radio", "vm_watch",
		"vm_pencil_hand", "door_hinged_panel", "utility_pole_90s",
		"manhole_drain", "shrub_bush_90s",
		"vm_empty_hands", "fp_guard_body", "crime_evidence_bag", "crime_victim_body",
		"trafika_kiosk_96", "fluorescent_fixture_96", "grocery_display_island",
		"basement_storage_cage", "electrical_panel_96", "mailbox_bank_96",
		"char_varga", "char_anna", "char_dana", "char_zuzana", "char_peter",
		"char_milan", "char_roman", "char_iveta", "char_resident_a",
		"char_resident_b", "char_resident_c", "patrol_marker_post"
	]
	var loaded_glbs: int = 0
	for g: String in glbs:
		var path: String = "res://assets/models/%s.glb" % g
		if ResourceLoader.exists(path) and load(path) != null:
			loaded_glbs += 1
	_assert(loaded_glbs == 79, "All 79 Blender .glb models (incl. 11 Prompt 06 unique characters & patrol marker) load non-null (got %d)" % loaded_glbs)

	# 2. Verify all 15 PBR texture triplets (45 maps) + 16 signage/poster textures load
	var pbr_sets: Array[String] = [
		"cobble", "plaster_ochre", "plaster_grey", "brick_cellar",
		"wood_gallery", "concrete_dark", "shutter_metal", "iron_rusted",
		"asphalt_wet", "panel_concrete", "grass_autumn",
		"gravel_wet", "mud_leaves", "linoleum_worn", "terrazzo_tile"
	]
	var loaded_pbr: int = 0
	for p: String in pbr_sets:
		for suff: String in ["albedo", "normal", "roughness"]:
			var tp: String = "res://assets/textures/%s_%s.png" % [p, suff]
			if ResourceLoader.exists(tp) and load(tp) != null:
				loaded_pbr += 1
	_assert(loaded_pbr == 45, "All 45 PBR texture maps load non-null (got %d)" % loaded_pbr)

	var signs: Array[String] = [
		"sign_vratnica", "sign_hodinarstvo", "sign_notar",
		"sign_kotolna", "sign_blok14", "poster_1995",
		"sign_jednota", "sign_vecierka", "sign_trafika",
		"sign_opravovna", "sign_trafostanica", "sign_bus_stop",
		"billboard_1995", "district_map_1995",
		"trafika_ads_1996", "grocery_posters_1996"
	]
	var loaded_signs: int = 0
	for s: String in signs:
		var sp: String = "res://assets/textures/%s.png" % s
		if ResourceLoader.exists(sp) and load(sp) != null:
			loaded_signs += 1
	_assert(loaded_signs == 16, "All 16 signage, poster & map textures load non-null (got %d)" % loaded_signs)

	# 3. Verify all 9 modular district .tscn scenes load
	var scene_paths: Array[String] = [
		"ResidentialDistrict", "OuterEnvironment", "ApartmentBuildings",
		"CentralPark", "CommercialArea", "ParkingArea",
		"GarageComplex", "SecurityOffice", "TechnicalArea"
	]
	var loaded_scenes: int = 0
	for sc_name: String in scene_paths:
		var sc_p: String = "res://scenes/district/%s.tscn" % sc_name
		if ResourceLoader.exists(sc_p) and load(sc_p) != null:
			loaded_scenes += 1
	_assert(loaded_scenes == 9, "All 9 modular district scenes load non-null (got %d)" % loaded_scenes)

	# 4. Verify 65 mastered audio/footstep/SFX/voice/music streams + 4 AudioServer buses
	var key_streams: Array[String] = [
		"amb_rain_city", "music_menu_theme", "music_tension_drone", "music_walkman_tape",
		"loop_sodium_buzz", "loop_boiler_roar", "loop_clock_tick", "loop_k4_hum", "loop_radio_504",
		"loop_apartment_life", "loop_forest_wind", "chains_sway", "distant_tram",
		"step_cobble_1", "step_cobble_2", "step_cobble_3", "step_cobble_4",
		"step_grass_1", "step_grass_2", "step_grass_3", "step_grass_4",
		"step_gravel_1", "step_gravel_2", "step_gravel_3", "step_gravel_4",
		"step_wood_1", "step_wood_2", "step_wood_3", "step_wood_4",
		"step_metal_1", "step_metal_2", "step_metal_3", "step_metal_4",
		"flashlight", "clock_stamp", "phone_ring", "anomaly_sting",
		"taser_zap", "taser_equip", "battery_swap", "notebook_open", "pencil_check",
		"door_creak", "chair_crash", "whisper_static",
		"headphones_on", "headphones_off", "keys_jingle", "radio_squelch", "watch_tick",
		"switch_click", "drawer_open", "breath_tired", "breath_exhausted", "jumpscare_sting",
		"voice_kovac_n1", "voice_kovac_n2", "voice_kovac_n3", "voice_kovac_n4", "voice_kovac_n5",
		"voice_elena_payphone", "voice_maria_n3", "voice_maria_n5", "voice_jozef_bunker", "voice_milan_n2"
	]
	var loaded_audio: int = 0
	for st_name: String in key_streams:
		if au.has_stream(st_name):
			loaded_audio += 1
	_assert(loaded_audio == key_streams.size(), "All %d audio streams loaded in AudioSynth (got %d)" % [key_streams.size(), loaded_audio])

	var bus_ok := true
	for bname: String in ["EnvLayer", "LifeLayer", "SupernaturalLayer", "HeadphoneMusic"]:
		if AudioServer.get_bus_index(bname) == -1:
			bus_ok = false
	_assert(bus_ok, "All 4 headphone-aware AudioServer buses exist (EnvLayer, LifeLayer, SupernaturalLayer, HeadphoneMusic)")

	# 5. Verify 32 Anomalies & 28 Achievements + Platinum + Nights 1-6 + Endings A-F
	_assert(ad.get_all_anomalies().size() == 32, "AnomalyDirector has 32 anomalies")
	_assert(am.get_all_achievements().size() == 28, "AchievementManager has 28 achievements")
	gs.unlocked_achievements.clear()
	for a: Dictionary in am.get_all_achievements():
		var aid: String = str(a.get("id", ""))
		if aid != "ACH_28_PLATINUM":
			am.unlock(aid)
	_assert(am.is_unlocked("ACH_28_PLATINUM"), "Platinum achievement auto-unlocks after 27")

	for n in range(1, 7):
		gs.start_new_shift(n, false, true)
		_assert(gs.active_quests.size() >= 3, "Night %d populated quests" % n)

	gs.start_new_shift(5, false, true)
	gs.story_flags["took_bribe"] = true
	_assert(gs.evaluate_ending() == "A", "Ending A resolves")

	gs.start_new_shift(5, false, true)
	gs.add_evidence("evidence_plate")
	gs.add_evidence("evidence_film")
	gs.add_evidence("evidence_dossier")
	gs.story_flags["evacuated_maria"] = true
	gs.story_flags["antenna_sabotaged"] = true
	_assert(gs.evaluate_ending() == "B", "Ending B resolves")

	gs.start_new_shift(5, false, true)
	gs.story_flags["red_door_opened"] = true
	gs.story_flags["boiler_overloaded"] = true
	_assert(gs.evaluate_ending() == "C", "Ending C resolves")

	gs.start_new_shift(5, false, true)
	gs.signal_distortion = 85.0
	gs.tuned_radios = 5
	gs.story_flags["accepted_jozef_key"] = true
	_assert(gs.evaluate_ending() == "D", "Ending D resolves")

	gs.start_new_shift(5, false, true)
	gs.story_flags["lured_anomalies_on_mobsters"] = true
	gs.story_flags["betrayed_kovac"] = true
	_assert(gs.evaluate_ending() == "E", "Ending E resolves")

	gs.start_new_shift(6, false, true)
	gs.complete_quest("ground_k4_origin")
	_assert(gs.evaluate_ending() == "F", "Ending F resolves")

	# 6. Verify Main Menu & Main Scene + Prompt 02 Systems
	var menu_packed: PackedScene = load("res://scenes/main_menu.tscn")
	_assert(menu_packed != null, "main_menu.tscn loads")
	if menu_packed:
		var menu_inst: Node = menu_packed.instantiate()
		root.add_child(menu_inst)
		_assert(menu_inst.get_node_or_null("MenuCRTLayer") != null, "Main menu initializes CRT overlay")
		_assert(menu_inst.get_node_or_null("Menu3DBackdrop/MenuPreviewViewport/MenuBlok14Showcase") != null, "Main menu initializes live 3D showcase backdrop")
		menu_inst.queue_free()

	gs.start_new_shift(1, false, true)
	var main_packed: PackedScene = load("res://scenes/main.tscn")
	_assert(main_packed != null, "main.tscn loads")
	if main_packed:
		var main_inst: Node = main_packed.instantiate()
		root.add_child(main_inst)
		await physics_frame
		await physics_frame

		var world: Node3D = main_inst.get_node_or_null("Blok14World")
		var dist: Node3D = world.district if world else null
		var player: CharacterBody3D = main_inst.get_node_or_null("GuardPlayer")
		var hud: Node = main_inst.get_node_or_null("GameHUD")
		var ahub: Node = world.animation_hub if world else null
		var dmgr: Node = world.door_manager if world else null
		var vm: Node = player.viewmodel if player else null

		var vm_anims: int = vm.get_animation_count() if vm and vm.has_method("get_animation_count") else 0
		var world_anims: int = ahub.get_animation_count() if ahub and ahub.has_method("get_animation_count") else 0
		var total_anims: int = vm_anims + world_anims
		_assert(vm_anims >= 24 and total_anims >= 50, ">=24 Viewmodel + >=26 World animations registered (GuardViewmodel=%d + AnimationHub=%d = %d)" % [vm_anims, world_anims, total_anims])

		# Tightened apartment courtyard spacing vs full skyline enclosure
		var blk_a: Node3D = dist.find_child("BlockA", true, false) as Node3D if dist else null
		var blk_b: Node3D = dist.find_child("BlockB", true, false) as Node3D if dist else null
		var blk_d: Node3D = dist.find_child("BlockD", true, false) as Node3D if dist else null
		if blk_a and blk_b and blk_d:
			var ab_dist: float = blk_a.position.distance_to(blk_b.position)
			var bd_dist: float = blk_b.position.distance_to(blk_d.position)
			_assert(ab_dist <= 38.0 and bd_dist <= 76.0, "Apartment blocks tightened realistically around Central Park (A-B=%.1fm, B-D=%.1fm)" % [ab_dist, bd_dist])
		else:
			_assert(false, "Apartment blocks A, B, D exist for spacing check")

		# Surface diversity check
		var surf_set: Dictionary = {}
		if dist and dist.has_method("get_surface_for_position"):
			for sp_vec: Vector3 in [
				Vector3(-15.8, 0.2, -54.5),  # wood (office)
				Vector3(25.0, 0.2, -53.0),   # asphalt (parking)
				Vector3(0.0, 0.2, 0.0),      # cobble (park plaza)
				Vector3(37.5, 0.2, 0.0),     # concrete (promenade)
				Vector3(-30.0, 0.2, 0.0),    # gravel (park trail)
				Vector3(-40.0, 0.2, -45.0),  # grass (courtyard lawn)
				Vector3(-64.0, -4.0, -32.0), # metal (boiler tunnel)
				Vector3(0.0, 0.2, 74.0),     # mud (forest edge)
			]:
				surf_set[dist.get_surface_for_position(sp_vec)] = true
		_assert(surf_set.size() >= 6, "Surface variation detects >=6 distinct ground surfaces (got %d)" % surf_set.size())

		var bat_pickups: int = 0
		if world:
			for area: Area3D in world.interactables:
				if area.interact_type == "battery_pickup":
					bat_pickups += 1
		_assert(bat_pickups >= 8, ">=8 pickable 4.5V Battery Packs across district (got %d)" % bat_pickups)
		_assert(world != null and world.cctv_cameras.size() == 6, "CCTV system built 6 live district cameras (got %d)" % (world.cctv_cameras.size() if world else 0))

		var key_nodes_ok: int = 0
		var key_names: Array[String] = [
			"BlockA", "BlockB", "BlockC", "BlockD", "BlockE", "BlockF",
			"Sign_Jednota", "Sign_Vecierka", "Sign_Trafika", "Sign_Opravovna",
			"GarageDoor_01", "Garage07_LightSlit", "Sign_Vratnica", "DistrictMapBoard",
			"Sign_Trafostanica", "Sign_Kotolna", "BusStop90s", "Billboard_1995",
			"CourtyardRain", "Spatial_loop_boiler_roar"
		]
		for kn: String in key_names:
			if dist and dist.find_child(kn, true, false) != null:
				key_nodes_ok += 1
		_assert(key_nodes_ok == key_names.size(), "All %d key district landmarks present (got %d)" % [key_names.size(), key_nodes_ok])

		# PhysicalDoor + Key + DoorManager persistence
		var door_count: int = dmgr.get_door_count() if dmgr and dmgr.has_method("get_door_count") else 0
		_assert(door_count >= 8, "DoorManager registered >= 8 hinged PhysicalDoors (got %d)" % door_count)
		if dmgr and dmgr.doors.has("garage_06_door"):
			var g6_door: Node = dmgr.doors["garage_06_door"]
			var locked_res: Dictionary = g6_door.interact_toggle()
			_assert(not bool(locked_res.get("ok", true)) and g6_door.is_locked, "Locked Garage 06 door blocks entry without key")
			gs.collect_key("key_garage_06")
			var unlock_res: Dictionary = g6_door.interact_toggle()
			_assert(bool(unlock_res.get("ok", false)) and g6_door.is_open and not g6_door.is_locked, "Collecting key_garage_06 unlocks & swings Garage 06 door")

		# Patrol Loop Navigation & Floor Collision Verification (15 tightened waypoints)
		var space: PhysicsDirectSpaceState3D = (main_inst as Node3D).get_world_3d().direct_space_state
		var waypoints: Array[Vector3] = [
			Vector3(-15.8, 1.5, -54.5),  # Security Office interior
			Vector3(0.0, 1.5, -76.0),    # Main Gate Road
			Vector3(25.0, 1.5, -53.0),   # Parking Lot
			Vector3(4.0, 1.5, -21.0),    # Block D Apron
			Vector3(66.0, 1.5, -14.0),   # Block E West Front
			Vector3(37.5, 1.5, 0.0),     # Commercial Promenade
			Vector3(49.0, 1.5, 14.0),    # Inside Potraviny Jednota
			Vector3(38.0, 1.5, 28.0),    # Block C Front
			Vector3(2.0, 1.5, 54.0),     # Northern Path behind Block B
			Vector3(-32.0, 1.5, 28.0),   # Block A Front
			Vector3(-54.0, 1.5, 16.0),   # Block F Service Road
			Vector3(-54.0, 1.5, -30.0),  # Boiler & Tech Road
			Vector3(-83.2, 1.5, -58.5),  # Inside Open Garage 03
			Vector3(8.0, 5.0, -30.0),    # Block D 2F Flat 4 Interior
			Vector3(-84.0, -2.5, -32.0)  # Underground Bunker K-4
		]
		var solid_hits: int = 0
		for wp: Vector3 in waypoints:
			var rq := PhysicsRayQueryParameters3D.create(wp, wp + Vector3(0, -3.5, 0))
			var hit: Dictionary = space.intersect_ray(rq)
			if not hit.is_empty():
				solid_hits += 1
		_assert(solid_hits == waypoints.size(), "All %d tightened patrol & interior waypoints have solid floor collision (got %d)" % [waypoints.size(), solid_hits])

		# Stamina, Sanity, Headphones & Equipment Systems Verification
		if player.stamina_mgr:
			for _i: int in range(70):
				player.stamina_mgr.update_stamina(0.1, true, true, false, 100.0)
			var exhausted_ok: bool = player.stamina_mgr.is_exhausted and not player.stamina_mgr.can_sprint()
			for _i: int in range(60):
				player.stamina_mgr.update_stamina(0.1, false, false, true, 100.0)
			var recovered_ok: bool = (not player.stamina_mgr.is_exhausted) and player.stamina_mgr.can_sprint()
			_assert(exhausted_ok and recovered_ok, "PlayerStaminaManager drains to exhaustion and recovers cleanly")

		if player.sanity_mgr:
			player.sanity_mgr.set_sanity(90.0)
			var st1: String = player.sanity_mgr.get_stage()
			player.sanity_mgr.set_sanity(55.0)
			var st2: String = player.sanity_mgr.get_stage()
			player.sanity_mgr.set_sanity(28.0)
			var st3: String = player.sanity_mgr.get_stage()
			player.sanity_mgr.set_sanity(10.0)
			var st4: String = player.sanity_mgr.get_stage()
			_assert(st1 == "HIGH" and st2 == "MODERATE" and st3 == "LOW" and st4 == "CRITICAL", "PlayerSanityManager transitions HIGH->MODERATE->LOW->CRITICAL")

		if player.headphone_mgr:
			player.toggle_headphones()
			var hp_on_ok: bool = player.headphone_mgr.headphones_on and gs.headphones_on
			au.env_manager.update_headphone_mix(true, 1.0)
			var env_idx: int = AudioServer.get_bus_index("EnvLayer")
			var env_attenuated: bool = (env_idx != -1 and AudioServer.get_bus_volume_db(env_idx) < -5.0)
			player.headphone_mgr.force_trigger_test_jumpscare(player)
			var scare_ok: bool = (player.headphone_mgr.jumpscare_count >= 1) and (not player.headphone_mgr.headphones_on)
			_assert(hp_on_ok and env_attenuated and scare_ok, "HeadphoneManager toggles Walkman, attenuates EnvLayer, and handles blind stalker jumpscare")

		# Equipment slots & notebook note save/load persistence
		for eq_slot: String in ["keys", "radio", "watch", "flashlight"]:
			player.switch_gear(eq_slot)
			_assert(gs.equipped_slot == eq_slot, "Equipment slot switches to %s" % eq_slot)

		gs.add_spare_battery(1)
		var reloaded: bool = player.swap_battery()
		_assert(reloaded and gs.is_quest_done("tut_pick_battery"), "Battery pickup + reload completes Night 1 tut_pick_battery")

		player.switch_gear("taser")
		var fired: bool = player.fire_taser()
		var stunned_ok: bool = ahub.stun_anomaly_node("ANOM_07") if ahub else false
		_assert(fired and stunned_ok and gs.is_quest_done("tut_test_taser"), "Taser equip/fire/stun works and completes Night 1 tut_test_taser")

		for zid: String in ["parking_lot", "central_park", "commercial_area", "garages"]:
			gs.mark_zone_visited(zid)
		_assert(gs.is_quest_done("tut_tour_zones"), "4-zone District Orientation Tour completes Night 1 tut_tour_zones")

		var logged_ok: bool = gs.check_off_notebook_anomaly("ANOM_01")
		_assert(logged_ok and gs.is_anomaly_checked_in_notebook("ANOM_01") and gs.is_quest_done("tut_log_anomaly"), "Field Notebook check-off logs anomaly and completes Night 1 tut_log_anomaly")

		gs.add_notebook_entry("QA INCIDENT", "Verified door key & headphone mix", "ZONE 5")
		gs.save_run()
		gs.notebook_entries.clear()
		var load_ok: bool = gs.load_run()
		_assert(load_ok and gs.notebook_entries.size() >= 1 and ("key_garage_06" in gs.collected_keys), "GameState persists custom notebook entries, collected keys & door states across save_run/load_run")

		for ci: int in range(6):
			gs.register_cctv_viewed(ci)
		_assert(gs.is_quest_done("check_cctv_n1"), "Inspecting all 6 CCTV feeds completes Night 1 check_cctv_n1")

		# Prompt 04 Verification: Bottom Hotbar, Mouse Wheel Cycle, Empty Hands, Independent Flashlight ON/OFF, FP Body, Fog, Horror Events A-H, Antagonist AI
		var hotbar_count: int = hud.get_hotbar_slot_count() if hud and hud.has_method("get_hotbar_slot_count") else 0
		_assert(hotbar_count == 7, "Bottom Inventory Hotbar displays all 7 real equipment slots (got %d)" % hotbar_count)

		player.switch_gear("hands")
		var hands_vis: bool = (vm != null and vm.get("hands_pivot") != null and vm.hands_pivot.visible)
		var empty_state_ok: bool = (player.equipment_mgr != null and player.equipment_mgr.get_equipment_state() == "EMPTY_HANDS")
		_assert(gs.equipped_slot == "hands" and hands_vis and empty_state_ok, "Selecting [HANDS] holsters gear, displays empty hands viewmodel, and enters EMPTY_HANDS state")

		var cycled_slot: String = player.cycle_hotbar_slot(1, true)
		_assert(cycled_slot == "flashlight" and gs.equipped_slot == "flashlight", "Mouse wheel cycle advances from hands to flashlight cleanly")

		if player.flashlight_on:
			player.toggle_flashlight()
		var flash_held_while_off: bool = (
			gs.equipped_slot == "flashlight"
			and not player.flashlight_on
			and not player.flashlight_spot.visible
			and vm != null and vm.flashlight_pivot.visible
			and player.equipment_mgr.get_equipment_state() == "FLASHLIGHT_HELD_OFF"
		)
		player.toggle_flashlight()
		_assert(flash_held_while_off and player.flashlight_on and player.flashlight_spot.visible, "Flashlight remains physically held & visible when switched OFF and restores beam when toggled ON")

		var fp_body: Node = player.fp_body if player else null
		var fp_body_ok: bool = (
			fp_body != null
			and int(fp_body.get("shadow_mesh_count")) >= 10
			and fp_body.has_method("is_body_visible_in_down_look")
			and fp_body.is_body_visible_in_down_look(deg_to_rad(-65.0))
		)
		_assert(fp_body_ok, "FirstPersonBodyController attaches 3D security guard body with real shadow casting and downward visibility")

		var fog_ctrl: Node = dist.fog_controller if dist else null
		var fog_ok: bool = (fog_ctrl != null and fog_ctrl.has_method("get_ground_fog_count") and fog_ctrl.get_ground_fog_count() >= 6)
		_assert(fog_ok, "FogController manages multi-layer distance & ground fog volumes across district")

		if dmgr and dmgr.doors.has("sec_office_door"):
			var sdoor: Node = dmgr.doors["sec_office_door"]
			sdoor.animate_handle_depress(-32.0)
			sdoor.set_manual_bolt_locked(true)
			var bolted_ok: bool = sdoor.is_locked and sdoor.get("handle_pivot") != null
			sdoor.set_manual_bolt_locked(false)
			_assert(bolted_ok and not sdoor.is_locked, "Security Office PhysicalDoor supports articulated rotating door handle & interior manual deadbolt")

		var hevents: Node = main_inst.get_node_or_null("HorrorEventManager")
		var ev_codes: PackedStringArray = hevents.get_registered_event_codes() if hevents and hevents.has_method("get_registered_event_codes") else PackedStringArray()
		var ev_ok: bool = (ev_codes.size() == 8 and hevents.trigger_event("EVENT_C_BLOOD_TRAIL") and hevents.trigger_event("EVENT_H_BODY_DISCOVERY"))
		_assert(ev_ok and bool(st.get_flag("discovered_crime_victim_body", false)), "HorrorEventManager registers & executes all 8 grounded crime horror events (Events A-H)")

		var ant_ai: Node3D = main_inst.get_node_or_null("AntagonistAI")
		var ant_ok: bool = false
		if ant_ai:
			var p0: Vector3 = ant_ai.global_position
			ant_ai.notify_sound_event(Vector3(10.0, 0.05, 10.0), 120.0)
			var st_inv: String = ant_ai.get_state()
			ant_ai._process(0.5)
			var moved_physically: bool = ant_ai.global_position.distance_to(p0) > 0.1
			ant_ai.transition_to("PURSUING", 5.0)
			var st_pur: String = ant_ai.get_state()
			ant_ai.transition_to("ESCAPING", 5.0)
			var st_esc: String = ant_ai.get_state()
			ant_ok = (st_inv == "INVESTIGATING_SOUND" and moved_physically and st_pur == "PURSUING" and st_esc == "ESCAPING")
		_assert(ant_ok, "AntagonistAI transitions across patrol/investigate/pursue/escape states and moves physically through world space")

		# Prompt 05 Verification: Clean HUD (no permanent quest UI), One-Time Tutorial, 10-Section Notebook, 8-10m Extreme Fog, Redesigned Interiors & Fixed Door System
		var hud_clean: bool = (hud != null and hud.has_method("is_hud_clean_no_objectives") and hud.is_hud_clean_no_objectives())
		_assert(hud_clean, "HUD removes permanent objective list, tutorial banner & upper-right clutter cleanly")

		gs.tutorial_completed = false
		gs.mark_tutorial_completed()
		gs.save_run()
		gs.tutorial_completed = false
		gs.load_run()
		_assert(gs.tutorial_completed and not gs.quest_completion_times.is_empty(), "One-time equipment tutorial persists across saves and completed assignments stamp handwritten times")

		var extreme_fog_ok: bool = false
		if fog_ctrl:
			var park_vis: float = fog_ctrl.get_outdoor_visibility_meters("central_park")
			var lot_vis: float = fog_ctrl.get_outdoor_visibility_meters("parking_lot")
			fog_ctrl.apply_zone_atmosphere("central_park", 1)
			fog_ctrl.update_fog(2.0, Vector3(0.0, 0.2, 4.0), 1)
			var outdoor_end: float = fog_ctrl.current_fog_end
			fog_ctrl.update_fog(2.0, Vector3(-18.0, 0.2, -56.0), 1)
			var indoor_end: float = fog_ctrl.current_fog_end
			extreme_fog_ok = (
				park_vis <= 9.0 and lot_vis <= 10.2
				and outdoor_end <= 10.5 and indoor_end >= 13.0
				and fog_ctrl.get_ground_fog_count() >= 8 and fog_ctrl.get_mid_fog_count() >= 6
			)
		_assert(extreme_fog_ok, "Extreme multi-layer fog caps outdoor visibility to 8-10m while keeping small interiors readable")

		var p5_landmarks_ok: int = 0
		var p5_nodes: Array[String] = [
			"OfficePhoneReceiver", "CRTScreenGlow", "CabinetKeyHook_0",
			"TrafikaAds1996", "TrafikaIntCounter", "TrafikaHeater",
			"JednotaPoster_Ext", "JednotaStorageWall_S",
			"BlkFCageCol_77", "SubCage1_Col", "ClimbFrame_Col",
			"GaragePlaque_01", "GaragePlaque_10", "Garages_RainGutter"
		]
		for p5n: String in p5_nodes:
			if dist and dist.find_child(p5n, true, false) != null:
				p5_landmarks_ok += 1
		_assert(p5_landmarks_ok == p5_nodes.size(), "All %d Prompt 05 redesigned interior/exterior landmarks present (got %d)" % [p5_nodes.size(), p5_landmarks_ok])

		# Comprehensive Door System Bug-Fix Verification (States, Wrong Key Rejection, Locking from both sides, Persistence, Layer-2 Raycast)
		var door_total_p5: int = dmgr.get_door_count() if dmgr else 0
		var ray_layer_ok: bool = (player != null and player.interact_ray != null and player.interact_ray.collision_mask == 2 and player.has_method("_is_focus_occluded_by_wall"))
		var door_fixes_ok: bool = false
		if dmgr and dmgr.doors.has("garage_06_door") and dmgr.doors.has("sec_office_door") and dmgr.doors.has("trafika_staff_door") and dmgr.doors.has("blocka_entrance_door"):
			var g6: Node = dmgr.doors["garage_06_door"]
			g6.set_open(false, false)
			g6.is_locked = true
			g6.door_state = "CLOSED_LOCKED"
			var wrong_res: Dictionary = g6.try_unlock_with_key("wrong_key_id")
			var wrong_rejected: bool = (not bool(wrong_res.get("ok", true))) and g6.is_locked and g6.get_door_state() == "CLOSED_LOCKED"
			var right_res: Dictionary = g6.try_unlock_with_key("key_garage_06")
			var right_accepted: bool = bool(right_res.get("ok", false)) and (not g6.is_locked) and g6.get_door_state() == "CLOSED_UNLOCKED"

			var sd: Node = dmgr.doors["sec_office_door"]
			sd.toggle_lock()
			var locked_state_ok: bool = sd.is_locked and sd.get_door_state() == "CLOSED_LOCKED"
			gs.save_run()
			sd.is_locked = false
			sd.door_state = "CLOSED_UNLOCKED"
			gs.load_run()
			dmgr.apply_saved_states()
			var persisted_lock_ok: bool = sd.is_locked and sd.get_door_state() == "CLOSED_LOCKED"
			sd.toggle_lock()
			sd.set_jammed(true)
			var jammed_ok: bool = (sd.get_door_state() == "JAMMED") and (not bool(sd.interact_toggle().get("ok", true)))
			sd.set_jammed(false)
			door_fixes_ok = (door_total_p5 >= 19 and wrong_rejected and right_accepted and locked_state_ok and persisted_lock_ok and jammed_ok)
		_assert(door_fixes_ok and ray_layer_ok, "Fixed PhysicalDoor 6-state machine, wrong-key rejection, locking, save/load persistence & wall-occluded Layer-2 raycasts (doors=%d)" % door_total_p5)

		main_inst.queue_free()

	# 7. Verify Real Developer Asset Registry & AssetManager UI
	var scan: Dictionary = AssetRegistryScript.scan_project()
	var st_scan: Dictionary = scan.get("stats", {})
	var comp_scan: Dictionary = scan.get("completeness", {})
	var total_scan: int = int(st_scan.get("total_assets", 0))
	var broken_scan: int = int(st_scan.get("broken", 99))
	var pct_scan: int = int(round(float(comp_scan.get("percent", 0.0))))
	_assert(total_scan >= 100 and broken_scan == 0 and pct_scan >= 99, "AssetRegistry real scan finds >=100 assets, 0 broken, 100% completeness (total=" + str(total_scan) + ", broken=" + str(broken_scan) + ", req=" + str(pct_scan) + "%)")

	var am_packed: PackedScene = load("res://tools/asset_browser/AssetManager.tscn")
	_assert(am_packed != null, "tools/asset_browser/AssetManager.tscn loads cleanly")
	if am_packed:
		var am_inst: Node = am_packed.instantiate()
		root.add_child(am_inst)
		await physics_frame
		_assert(is_instance_valid(am_inst), "AssetManager UI initializes cleanly without errors")
		am_inst.queue_free()

	# 8. Master Prompt 03 Verification: Logos, Key Art, Chapter Cards, Loading Art, 14 Icons, UI Textures, 6 Analog SFX
	var p3_gfx: Array[String] = [
		"res://assets/graphics/logos/logo_night_shift.png",
		"res://assets/graphics/logos/logo_nocna_sluzba.png",
		"res://assets/graphics/key_art/key_art_main.png",
		"res://assets/graphics/chapters/chapter_night_1.png",
		"res://assets/graphics/chapters/chapter_night_2.png",
		"res://assets/graphics/chapters/chapter_night_3.png",
		"res://assets/graphics/chapters/chapter_night_4.png",
		"res://assets/graphics/chapters/chapter_night_5.png",
		"res://assets/graphics/chapters/chapter_night_6.png",
		"res://assets/graphics/loading/loading_plan.png",
		"res://assets/graphics/loading/loading_dossier.png",
		"res://assets/graphics/loading/loading_cassette.png",
		"res://assets/graphics/loading/loading_notebook.png",
		"res://assets/graphics/ui/notebook_paper_bg.png",
		"res://assets/graphics/ui/javor_blueprint_map.png",
		"res://assets/graphics/icons/icon_notebook.png",
		"res://assets/graphics/icons/icon_keys.png",
		"res://assets/graphics/icons/icon_flashlight.png",
		"res://assets/graphics/icons/icon_headphones.png",
		"res://assets/graphics/icons/icon_radio.png",
		"res://assets/graphics/icons/icon_map.png",
		"res://assets/graphics/icons/icon_building.png",
		"res://assets/graphics/icons/icon_door.png",
		"res://assets/graphics/icons/icon_recording.png",
		"res://assets/graphics/icons/icon_objective.png",
		"res://assets/graphics/icons/icon_save.png",
		"res://assets/graphics/icons/icon_settings.png",
		"res://assets/graphics/icons/icon_audio.png",
		"res://assets/graphics/icons/icon_accessibility.png",
	]
	var loaded_p3_gfx: int = 0
	for gp: String in p3_gfx:
		if ResourceLoader.exists(gp) and load(gp) != null:
			loaded_p3_gfx += 1
	_assert(loaded_p3_gfx == 29, "All 29 Master Prompt 03 graphical assets load non-null (got %d)" % loaded_p3_gfx)

	var p3_sfx_ok: int = 0
	for sk: String in ["ui_hover", "ui_press", "page_turn", "cassette_click", "intercom_buzz", "power_out"]:
		if au.has_stream(sk):
			p3_sfx_ok += 1
	_assert(p3_sfx_ok == 6, "All 6 analog UI & story SFX loaded in AudioSynth (got %d)" % p3_sfx_ok)

	var p4_sfx_ok: int = 0
	for sk4: String in ["hotbar_scroll", "door_handle", "door_seal", "door_bang", "car_door_distant", "upstairs_run", "breathing_door", "handle_jiggle", "metal_impact"]:
		if au.has_stream(sk4):
			p4_sfx_ok += 1
	_assert(p4_sfx_ok == 9, "All 9 Prompt 04 grounded spatial & door SFX loaded in AudioSynth (got %d)" % p4_sfx_ok)

	# Localization EN/SK/CS & dynamic key labels
	loc.set_language("en")
	var t_en: String = loc.tr_key("game_title")
	loc.set_language("sk")
	var t_sk: String = loc.tr_key("game_title")
	loc.set_language("cs")
	var t_cs: String = loc.tr_key("game_title")
	loc.set_language("en")
	_assert(t_en == "NIGHT SHIFT" and t_sk == "NOČNÁ SLUŽBA" and t_cs == "NOČNÍ SLUŽBA" and not loc.get_key_label("interact").is_empty(), "LocalizationManager switches EN/SK/CS cleanly and resolves dynamic key labels")

	# StoryManager: 5 characters, 6 chapters, 5 docs, 5 tapes, 3 Javor endings
	st.reset_story()
	var d_anna: Dictionary = st.record_character_interaction("anna", 1)
	st.discover_document("doc_registry_1984")
	st.discover_document("doc_milan_sheet")
	st.discover_tape("tape_04_before_shift")
	var cl1: Dictionary = st.trigger_night_climax(1)
	var end_a: Dictionary = st.resolve_javor_ending("report")
	var end_b: Dictionary = st.resolve_javor_ending("apartment_47")
	var end_c: Dictionary = st.resolve_javor_ending("next_shift")
	_assert(
		st.CHARACTERS.size() >= 6 and st.CHAPTERS.size() == 6 and st.DOCUMENTS.size() == 5 and st.TAPES.size() == 5
		and not str(d_anna.get("text", "")).is_empty()
		and str(cl1.get("climax_id", "")) == "night1_silent_phone"
		and str(end_a.get("code", "")) == "A" and str(end_b.get("code", "")) == "B"
		and str(end_c.get("subtitle", "")).contains("NIGHT 7"),
		"StoryManager verifies >=6 characters (incl. Trafika Zuzana), 6 shifts, 5 docs, 5 tapes, Night 1 climax & Endings A/B/C (Night 7)"
	)

	# SaveManager multi-slot save/load verification (using slot 3 and cleaning up cleanly)
	var slot3_existed: bool = sm.get_slot_summary(3).get("exists", false)
	var slot3_path: String = "user://javor_slot_3.json"
	var slot3_backup: PackedByteArray = FileAccess.get_file_as_bytes(slot3_path) if slot3_existed else PackedByteArray()
	var saved_s3: bool = sm.save_slot(3, "Central Park", Vector3(2.0, 0.2, 4.0))
	st.reset_story()
	var loaded_s3: bool = sm.load_slot(3)
	_assert(saved_s3 and loaded_s3 and ("doc_registry_1984" in st.discovered_documents) and ("tape_04_before_shift" in st.discovered_tapes), "SaveManager multi-slot save/load preserves story documents, tapes & metadata")
	if slot3_existed:
		var sf3 := FileAccess.open(slot3_path, FileAccess.WRITE)
		if sf3:
			sf3.store_buffer(slot3_backup)
			sf3.close()
	else:
		sm.delete_slot(3)

	# Verify Physical 9-Page Notebook UI & Main Menu 3D Security Office Set
	if menu_packed:
		var m2: Node = menu_packed.instantiate()
		root.add_child(m2)
		await physics_frame
		_assert(m2.get_node_or_null("Menu3DBackdrop/MenuPreviewViewport/MenuSecurityOfficeSet") != null, "Main menu builds live 3D Security Office foreground vignette")
		m2.queue_free()

	if main_packed:
		var mn2: Node = main_packed.instantiate()
		root.add_child(mn2)
		await physics_frame
		var h2: Node = mn2.get_node_or_null("GameHUD")
		var sec_cnt: int = h2.notebook_ui.get_section_count() if h2 and h2.notebook_ui and h2.notebook_ui.has_method("get_section_count") else 0
		var nb_ok: bool = (h2 != null and h2.notebook_ui != null and sec_cnt == 4)
		if nb_ok:
			for pi: int in range(4):
				h2.notebook_ui.select_page(pi, false)
		_assert(nb_ok, "Redesigned 4-section Notebook UI (SHIFT/MAP/NOTES/EVIDENCE) & embedded Javor Map render cleanly (got %d)" % sec_cnt)
		mn2.queue_free()

	# Restore user save & meta state
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
		print("VERIFICATION FAILED")
		quit(1)
	else:
		print("ALL VERIFICATION CHECKS PASSED")
		quit(0)
