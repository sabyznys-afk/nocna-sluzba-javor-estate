class_name ApartmentBuildingsBuilder
extends DistrictBuilderBase


func build_module(is_showcase: bool = false) -> void:
	if is_showcase:
		_build_showcase_shells()
		return

	var panel_std: StandardMaterial3D = RetroMaterialsLib.get_material("panel_concrete")
	var panel_ren: StandardMaterial3D = RetroMaterialsLib.get_material("panel_renovated")
	var panel_neg: StandardMaterial3D = RetroMaterialsLib.get_material("panel_neglected")
	var dark_plaster: StandardMaterial3D = RetroMaterialsLib.get_material("plaster_dark")
	var wood: StandardMaterial3D = RetroMaterialsLib.get_material("wood_dark")
	var concrete: StandardMaterial3D = RetroMaterialsLib.get_material("concrete")
	var wallp: StandardMaterial3D = RetroMaterialsLib.get_material("wallpaper_90s")
	var iron: StandardMaterial3D = RetroMaterialsLib.get_material("iron")

	# =========================================================================
	# BUILDING A (NW: -32, 0, +38) — 5 Floors, Grey Concrete, Faces South (-Z)
	# =========================================================================
	_build_panelak_accessible(
		"BlockA", Vector3(-32.0, 0.0, 38.0), 28.0, 12.0, 5, 0.0,
		panel_std, dark_plaster, wood, wallp, -1, 19951, true
	)
	spawn_glb("crt_tv_set", Vector3(-38.0, 3.45, 41.2), Vector3(0, 20, 0))
	spawn_glb("wooden_chair", Vector3(-36.2, 3.45, 39.5), Vector3(0, -140, 0))
	add_solid_box("Flat7_SinkCounter", Vector3(-33.0, 3.9, 41.5), Vector3(2.2, 0.9, 0.8), dark_plaster)
	add_interactable("flat7_sink", "clue", "[E] Shut Off Running Tap in Flat 7", Vector3(-33.0, 4.4, 40.8), Vector3(1.5, 1.4, 1.4), "ANOM_06")
	add_interactable("door_flat7", "door", "[E] Inspect Flat 7 Chain Door", Vector3(-30.5, 4.5, 36.0), Vector3(1.5, 2.2, 1.5), "", {"door_id": "flat7"})
	_spawn_battery_pickup("battery_pack_5", Vector3(-38.2, 3.92, 38.0), "Block A Flat 7 Table")
	add_solid_box("Flat7_Table", Vector3(-38.2, 3.68, 38.0), Vector3(1.2, 0.45, 0.9), wood)
	_add_interior_lamp(Vector3(-35.5, 6.2, 39.0), Color(0.86, 0.80, 0.65), 1.4)
	var r3 := spawn_glb("transistor_radio", Vector3(-30.5, 3.92, 40.8))
	if r3:
		register_anim("anom_radio_dial_jitter", r3, {"anomaly_id": "ANOM_18", "seed": 3.0})
	add_interactable("radio_3", "radio", "[E] Tune Flat 7 Transistor Radio (50.4 Hz)", Vector3(-30.5, 4.1, 40.8), Vector3(1.1, 1.1, 1.1), "ANOM_18")
	add_spatial_sound("loop_apartment_life", Vector3(-32.0, 3.0, 33.5), 18.0, -16.0, is_showcase)
	# Anna Krížanová visual & walking routine driven by NPCScheduleManager (char_anna.glb)
	add_interactable("npc_anna", "story_npc", "[E] Talk to Anna Krížanová (Building A)", Vector3(-28.5, 1.1, 30.2), Vector3(1.5, 2.0, 1.5), "", {"char_id": "anna"})
	# Prompt 06 Night 1 CP3: Building A Mailboxes & Intercom inspection
	add_interactable("n1_blocka_mailboxes", "campaign_event", "[E] INSPECT BUILDING A MAILBOXES, INTERCOM & CELLAR ACCESS", Vector3(-37.8, 1.35, 34.4), Vector3(1.8, 1.8, 1.8), "", {"event_id": "n1_blocka_mailboxes"})

	# =========================================================================
	# BUILDING B (North Center: +2, 0, +42) — 8 FLOORS (25.2m Visual Landmark!)
	# =========================================================================
	_build_panelak_accessible(
		"BlockB", Vector3(2.0, 0.0, 42.0), 30.0, 12.0, 8, 0.0,
		panel_std, concrete, wood, wallp, -1, 19952, false
	)
	add_mesh_box("IntercomPanel_B", Vector3(-1.4, 1.35, 35.82), Vector3(0.28, 0.42, 0.08), iron)
	add_interactable("intercom_b47", "story_intercom", "[E] Inspect Building B Intercom Panel (Flats 1–46)", Vector3(-1.4, 1.35, 35.2), Vector3(1.2, 1.4, 1.2))
	var door47 := Node3D.new()
	door47.name = "Story_Door_47"
	door47.position = Vector3(6.8, 0.04, 41.8)
	add_child(door47)
	add_mesh_box("Door47Leaf", Vector3(0, 1.06, 0), Vector3(1.05, 2.12, 0.12), dark_plaster, Vector3.ZERO, door47)
	add_mesh_box("Door47Plate", Vector3(0, 1.55, -0.08), Vector3(0.26, 0.14, 0.04), RetroMaterialsLib.get_material("window_amber"), Vector3.ZERO, door47)
	register_dynamic("story_door_47", door47)
	add_interactable("door_47_int", "story_door_47", "[E] Inspect Unlisted Door Marked '47'", Vector3(6.8, 1.1, 41.1), Vector3(1.4, 2.1, 1.2))
	# Prompt 06 Night 4 CP1: Building B Stairwell Sighting Point (Roman Král walks physically away!)
	add_interactable("n4_blockb_sighting", "campaign_event", "[E] INSPECT BUILDING B STAIRWELL & BASEMENT ACCESS", Vector3(3.8, 1.15, 39.2), Vector3(2.0, 2.0, 2.0), "", {"event_id": "n4_blockb_sighting"})
	add_mesh_box("BlockB_ElevatorDoor", Vector3(-0.8, 1.25, 41.2), Vector3(1.5, 2.4, 0.2), iron)
	add_interactable("elevator_b_roof", "elevator", "[E] Take Elevator to Block B Rooftop (8th Floor)", Vector3(-0.8, 1.2, 40.2), Vector3(1.8, 2.2, 1.6), "", {"target_pos": Vector3(2.0, 25.35, 40.0), "dest_label": "Block B 8F Rooftop"})

	add_solid_box("BlockB_RoofParapet_N", Vector3(2.0, 25.8, 47.8), Vector3(30.0, 1.1, 0.3), concrete)
	add_solid_box("BlockB_RoofParapet_S", Vector3(2.0, 25.8, 36.2), Vector3(30.0, 1.1, 0.3), concrete)
	add_solid_box("BlockB_RoofParapet_W", Vector3(-12.8, 25.8, 42.0), Vector3(0.3, 1.1, 12.0), concrete)
	add_solid_box("BlockB_RoofParapet_E", Vector3(16.8, 25.8, 42.0), Vector3(0.3, 1.1, 12.0), concrete)
	add_solid_box("BlockB_RoofPenthouse", Vector3(-1.0, 26.6, 43.0), Vector3(3.6, 2.8, 3.6), concrete)
	add_interactable("elevator_b_lobby", "elevator", "[E] Take Roof Elevator Down to Block B Lobby", Vector3(-1.0, 26.3, 40.6), Vector3(1.8, 2.2, 1.6), "", {"target_pos": Vector3(-0.8, 0.15, 39.5), "dest_label": "Block B Lobby"})

	spawn_glb("sta_antenna_mast", Vector3(9.0, 25.2, 42.0))
	var sta_light := OmniLight3D.new()
	sta_light.position = Vector3(9.0, 30.2, 42.0)
	sta_light.light_color = Color(0.28, 0.56, 0.94)
	sta_light.light_energy = 2.6
	sta_light.omni_range = 18.0
	add_child(sta_light)
	add_interactable("sta_antenna", "antenna", "[E] Inspect STA Rooftop Antenna Amplifier", Vector3(9.0, 26.2, 42.0), Vector3(2.2, 2.2, 2.2), "ANOM_24")
	var r4 := spawn_glb("transistor_radio", Vector3(5.5, 25.3, 40.5))
	if r4:
		register_anim("anom_radio_dial_jitter", r4, {"anomaly_id": "ANOM_18", "seed": 4.0})
	add_interactable("radio_4", "radio", "[E] Tune Rooftop Transistor Radio (50.4 Hz)", Vector3(5.5, 25.6, 40.5), Vector3(1.1, 1.1, 1.1), "ANOM_18")
	add_interactable("door_attic", "door", "[E] Open Rooftop Maintenance Hatch (Jozef's Stash)", Vector3(-3.2, 26.2, 43.0), Vector3(1.6, 2.0, 1.6), "", {"door_id": "attic"})
	_spawn_battery_pickup("battery_pack_7", Vector3(3.5, 25.25, 44.5), "Block B Rooftop")
	add_interactable("page_7", "page", "[E] Take Torn Logbook Page #7 (Roof Relay)", Vector3(6.5, 25.6, 44.5), Vector3(1.2, 1.2, 1.2), "", {"page_id": "page_7"})

	add_mesh_box("BlockB_5F_BacklitWin", Vector3(4.5, 14.5, 35.82), Vector3(1.4, 1.6, 0.12), RetroMaterialsLib.get_material("window_amber"))
	var b_watcher := spawn_glb("entity_shadow", Vector3(4.5, 13.7, 35.3), Vector3(0, 180, 0), Vector3(0.9, 0.9, 0.9))
	if b_watcher:
		register_dynamic("event_E_watcher", b_watcher)
		register_anim("anom_13th_window_watcher", b_watcher, {"seed": 2.2})
	register_event_hook("event_E_building_b_window", Vector3(4.5, 14.5, 35.5), "Figure watching Park from Block B 5th floor window")

	# =========================================================================
	# BUILDING C (NE: +38, 0, +36) — 5 Floors, Neglected Dark Concrete
	# =========================================================================
	_build_panelak_accessible(
		"BlockC", Vector3(38.0, 0.0, 36.0), 28.0, 12.0, 5, 0.0,
		panel_neg, dark_plaster, wood, wallp, -1, 19953, true
	)
	add_interactable("blockc_stair_sound", "horror_hook", "[E] Listen Up Block C Neglected Stairwell", Vector3(40.5, 1.2, 34.5), Vector3(2.2, 2.0, 2.2), "ANOM_12")
	register_event_hook("event_B_building_c_stairs", Vector3(40.5, 3.4, 37.0), "Upper floor footsteps & scraping inside Building C stairwell")
	# Prompt 06 Night 2 CP1: Fresh muddy boot marks outside slightly ajar 2F door in Building C
	var mud_m: StandardMaterial3D = RetroMaterialsLib.get_material("mud_leaves")
	add_mesh_box("BlockC_MudPrint1", Vector3(39.8, 3.50, 35.2), Vector3(0.22, 0.015, 0.36), mud_m, Vector3(0, 14, 0))
	add_mesh_box("BlockC_MudPrint2", Vector3(39.3, 3.50, 34.6), Vector3(0.22, 0.015, 0.36), mud_m, Vector3(0, -8, 0))
	add_interactable("n2_blockc_mud", "campaign_event", "[E] INSPECT FRESH MUDDY BOOT MARKS BY AJAR DOOR (BLOCK C)", Vector3(39.6, 4.1, 34.9), Vector3(2.0, 1.8, 2.0), "", {"event_id": "n2_blockc_mud"})

	spawn_glb("crt_tv_set", Vector3(31.5, 3.45, 39.2), Vector3(0, 15, 0))
	var tv_glow := OmniLight3D.new()
	tv_glow.position = Vector3(32.0, 4.6, 38.2)
	tv_glow.light_color = Color(0.45, 0.68, 0.96)
	tv_glow.light_energy = 1.6
	tv_glow.omni_range = 7.0
	add_child(tv_glow)
	register_dynamic("flat7_tv_glow", tv_glow)
	add_interactable("door_flat9", "door", "[E] Inspect Suspicious Flat 9 Door & TV Static", Vector3(33.5, 4.5, 34.0), Vector3(1.5, 2.2, 1.5), "ANOM_16", {"door_id": "flat9"})
	spawn_glb("watchmans_clock", Vector3(42.5, 4.55, 34.2), Vector3.ZERO)
	add_interactable("clock_gallery", "clock", "[E] Stamp Watchman's Clock #4 (Block C 2F Landing)", Vector3(42.5, 4.65, 35.0), Vector3(1.2, 1.2, 1.2))
	_spawn_battery_pickup("battery_pack_6", Vector3(35.5, 3.55, 38.0), "Block C Flat 9 Hall")
	add_interactable("page_6", "page", "[E] Take Torn Logbook Page #6 (Flat 9 Desk)", Vector3(31.5, 4.1, 38.2), Vector3(1.1, 1.1, 1.1), "", {"page_id": "page_6"})

	var win13 := spawn_glb("anom_cracked_window", Vector3(52.15, 1.8, 36.0), Vector3(0, -90, 0))
	if win13:
		win13.name = "Anom_13th_Window"
		register_dynamic("anom_13th_window", win13)
		register_anomaly_visual("ANOM_01", win13)
		register_anim("anom_13th_window_watcher", win13, {"anomaly_id": "ANOM_01", "seed": 1.7})
		var w_area := add_interactable("anom_13th_window_int", "anomaly", "[E] Inspect the Impossible 13th Cracked Window", Vector3(53.2, 1.8, 36.0), Vector3(1.8, 2.2, 2.2), "ANOM_01")
		w_area.set_meta("visual_target", win13)

	# =========================================================================
	# BUILDING D (South-Center: +4, 0, -30) — 6 Floors, Renovated Ochre, Faces North (+Z)
	# =========================================================================
	_build_panelak_accessible(
		"BlockD", Vector3(4.0, 0.0, -30.0), 28.0, 12.0, 6, 180.0,
		panel_ren, dark_plaster, wood, wallp, 1, 19954, true
	)
	spawn_glb("old_bicycle", Vector3(-1.5, 0.0, -23.2), Vector3(0, 72, 0))
	spawn_glb("old_bicycle", Vector3(9.2, 0.0, -23.0), Vector3(0, -80, 0))
	spawn_glb("crt_tv_set", Vector3(10.0, 3.45, -32.5), Vector3(0, 180, 0))
	spawn_glb("wooden_chair", Vector3(8.5, 3.45, -30.5), Vector3(0, 35, 0))
	add_solid_box("MariaRug", Vector3(8.0, 3.46, -30.0), Vector3(3.2, 0.03, 2.4), RetroMaterialsLib.get_material("brick_cellar"))
	_add_interior_lamp(Vector3(8.0, 6.2, -30.0), Color(0.96, 0.78, 0.48), 1.7)
	add_interactable("door_flat4", "door", "[E] Inspect Block D Flat 4 Entry", Vector3(1.4, 4.5, -29.5), Vector3(1.5, 2.2, 1.5), "", {"door_id": "flat7"})
	add_interactable("maria_door", "npc_door", "[E] Speak Through Chain Latch with Mrs. Maria (Flat 4)", Vector3(5.5, 4.5, -27.2), Vector3(1.6, 2.2, 1.6), "", {"door_id": "flat7"})
	add_interactable("evidence_film", "evidence", "[E] Recover Elena's 35mm Film Reel (Flat 4 Table)", Vector3(10.0, 4.2, -31.5), Vector3(1.3, 1.3, 1.3), "", {"evidence_id": "evidence_film"})
	add_spatial_sound("loop_apartment_life", Vector3(4.0, 3.0, -24.5), 18.0, -16.0, is_showcase)

	# =========================================================================
	# BUILDING E (East Beside Shops: +74, 0, -14) — 5 Floors, Faces West (-X -> yaw +90)
	# =========================================================================
	_build_panelak_accessible(
		"BlockE", Vector3(74.0, 0.0, -14.0), 28.0, 12.0, 5, 90.0,
		panel_std, dark_plaster, wood, wallp, -1, 19955, false
	)
	spawn_glb("old_bicycle", Vector3(67.2, 0.0, -8.5), Vector3(0, 15, 0))
	spawn_glb("old_bicycle", Vector3(67.2, 0.0, -20.0), Vector3(0, 125, 0))

	# =========================================================================
	# BUILDING F (West Isolated: -68, 0, +16) — 5 Floors, Faces East (+X -> yaw -90)
	# =========================================================================
	_build_panelak_accessible(
		"BlockF", Vector3(-68.0, 0.0, 16.0), 28.0, 12.0, 5, -90.0,
		panel_neg, dark_plaster, wood, wallp, 1, 19956, false
	)
	add_stair_ramp("Stair_BlockF_Basement", Vector3(-66.0, 0.0, 16.0), Vector3(-72.5, -4.0, 16.0), 2.4, concrete)
	add_solid_box("BlkFBase_Floor", Vector3(-85.0, -4.25, 16.0), Vector3(34.0, 0.5, 4.8), concrete)
	add_solid_box("BlkFBase_Ceiling", Vector3(-87.5, -0.8, 16.0), Vector3(29.0, 0.4, 4.8), concrete)
	add_solid_box("BlkFBase_WallN", Vector3(-85.0, -2.5, 18.2), Vector3(34.0, 3.6, 0.4), RetroMaterialsLib.get_material("brick_cellar"))
	add_solid_box("BlkFBase_WallS", Vector3(-85.0, -2.5, 13.8), Vector3(34.0, 3.6, 0.4), RetroMaterialsLib.get_material("brick_cellar"))
	add_solid_box("BlkFBase_WallW", Vector3(-102.0, -2.5, 16.0), Vector3(0.4, 3.6, 4.8), RetroMaterialsLib.get_material("brick_cellar"))
	add_mesh_cyl("BlkFBase_Pipe", Vector3(-85.0, -1.25, 17.5), 0.10, 32.0, iron, Vector3(0, 0, 90))
	# Prompt 05 Part 5.5 — Authentic Central European slatted cellar cages ('latkové pivnice'), drains & electrical panel
	for cage_x: float in [-77.5, -83.0, -92.5]:
		spawn_glb("basement_storage_cage", Vector3(cage_x, -4.0, 14.8), Vector3.ZERO)
		add_invisible_collider("BlkFCageCol_%d" % int(absf(cage_x)), Vector3(cage_x, -2.9, 14.8), Vector3(2.2, 2.2, 1.7))
	spawn_glb("electrical_panel_96", Vector3(-73.0, -2.4, 17.92), Vector3(0, 180, 0))
	spawn_glb("manhole_drain", Vector3(-80.0, -4.0, 16.2), Vector3.ZERO)
	spawn_glb("manhole_drain", Vector3(-94.0, -4.0, 16.0), Vector3.ZERO)
	spawn_glb("wooden_chair", Vector3(-97.0, -4.0, 17.4), Vector3(0, 135, 0))
	var wet_stain := StandardMaterial3D.new()
	wet_stain.albedo_color = Color(0.06, 0.08, 0.09, 0.72)
	wet_stain.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wet_stain.roughness = 0.15
	add_mesh_box("BlkFWaterStain1", Vector3(-80.0, -3.99, 16.2), Vector3(2.8, 0.01, 2.2), wet_stain)
	add_mesh_box("BlkFWaterStain2", Vector3(-94.0, -3.99, 16.0), Vector3(3.2, 0.01, 2.4), wet_stain)
	var bfl1 := OmniLight3D.new()
	bfl1.position = Vector3(-73.0, -1.3, 16.0)
	bfl1.light_color = Color(0.84, 0.88, 0.92)
	bfl1.light_energy = 1.65
	bfl1.omni_range = 11.5
	add_child(bfl1)
	var bfl_mid := OmniLight3D.new()
	bfl_mid.name = "BlkFBase_MidLight"
	bfl_mid.position = Vector3(-84.5, -1.3, 16.0)
	bfl_mid.light_color = Color(0.78, 0.86, 0.88)
	bfl_mid.light_energy = 1.35
	bfl_mid.omni_range = 11.0
	add_child(bfl_mid)
	var bfl2 := OmniLight3D.new()
	bfl2.position = Vector3(-96.0, -1.3, 16.0)
	bfl2.light_color = Color(0.72, 0.86, 0.94)
	bfl2.light_energy = 1.30
	bfl2.omni_range = 11.0
	add_child(bfl2)
	register_anim("anom_stairwell_fog_pulse", bfl2, {"energy": 1.30, "seed": 2.7})
	register_event_hook("event_G_building_f_basement", Vector3(-90.0, -3.2, 16.0), "Unusually long 34m concrete corridor beneath isolated Block F")
	add_interactable("blockf_basement_end", "horror_hook", "[E] Inspect Dead-End Steel Door in Block F Corridor", Vector3(-100.8, -2.9, 16.0), Vector3(1.6, 2.2, 2.2), "ANOM_28")
	add_interactable("page_8", "page", "[E] Take Jozef's Torn Logbook Page #8 (Block F Basement)", Vector3(-98.5, -3.5, 16.0), Vector3(1.2, 1.2, 1.2), "", {"page_id": "page_8"})
	# Prompt 06 Night 4 CP2: Basement Physical Crime Evidence (disturbed boxes, broken padlock, torn brown jacket fabric & wall stain)
	var jacket_scrap_mat := StandardMaterial3D.new()
	jacket_scrap_mat.albedo_color = Color(0.20, 0.13, 0.09)
	jacket_scrap_mat.roughness = 0.88
	var trace_mat := StandardMaterial3D.new()
	trace_mat.albedo_color = Color(0.28, 0.05, 0.04, 0.82)
	trace_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trace_mat.roughness = 0.55
	add_solid_box("BlkF_DisturbedBox1", Vector3(-81.6, -3.72, 17.4), Vector3(0.68, 0.52, 0.55), wood, Vector3(0, 24, 0))
	add_mesh_box("BlkF_TornJacketFabric", Vector3(-82.1, -3.98, 16.8), Vector3(0.24, 0.015, 0.18), jacket_scrap_mat, Vector3(0, -19, 0))
	add_mesh_box("BlkF_BrokenPadlock", Vector3(-82.3, -3.97, 16.4), Vector3(0.08, 0.04, 0.09), iron, Vector3(0, 42, 0))
	add_mesh_box("BlkF_WallBloodTrace", Vector3(-82.0, -3.1, 17.98), Vector3(0.32, 0.24, 0.02), trace_mat)
	add_interactable("n4_basement_evidence", "campaign_event", "[E] DOCUMENT BASEMENT EVIDENCE (BROKEN PADLOCK, TORN JACKET & TRACE)", Vector3(-82.0, -3.3, 16.7), Vector3(2.2, 1.8, 2.2), "", {"event_id": "n4_basement_evidence"})


func _build_showcase_shells() -> void:
	var panel_std: StandardMaterial3D = RetroMaterialsLib.get_material("panel_concrete")
	var panel_ren: StandardMaterial3D = RetroMaterialsLib.get_material("panel_renovated")
	add_mesh_box("ShowcaseBlockA", Vector3(-32.0, 8.0, 38.0), Vector3(26.0, 16.0, 10.0), panel_std)
	add_mesh_box("ShowcaseBlockB", Vector3(2.0, 12.5, 42.0), Vector3(28.0, 25.0, 10.0), panel_std)
	add_mesh_box("ShowcaseBlockD", Vector3(4.0, 9.0, -30.0), Vector3(26.0, 18.0, 10.0), panel_ren)


func _build_panelak_accessible(
	tag: String, center: Vector3, width: float, depth: float, floors: int, yaw_deg: float,
	facade_mat: Material, trim_mat: Material, floor_mat: Material, wallp_mat: Material,
	door_side: int, seed_val: int, has_2f_interior: bool
) -> void:
	var blk := Node3D.new()
	blk.name = tag
	blk.position = center
	blk.rotation_degrees.y = yaw_deg
	add_child(blk)

	var total_h: float = float(floors) * 3.1
	var half_w: float = width * 0.5
	var half_d: float = depth * 0.5
	var front_z: float = -half_d
	var drain_mat: Material = RetroMaterialsLib.get_material("drainpipe_metal")
	var curb_mat: Material = RetroMaterialsLib.get_material("concrete_curb")
	var soil_mat: Material = RetroMaterialsLib.get_material("flowerbed_soil")
	var terrazzo_mat: Material = RetroMaterialsLib.get_material("terrazzo_tile")

	# Distinct per-building lobby identity (wall colour, maintenance state & resident props)
	var lobby_wall_mat: Material = wallp_mat
	match tag:
		"BlockA": lobby_wall_mat = RetroMaterialsLib.get_material("hall_sage")
		"BlockB": lobby_wall_mat = RetroMaterialsLib.get_material("hall_bluegrey")
		"BlockC": lobby_wall_mat = RetroMaterialsLib.get_material("hall_ochre")
		"BlockD": lobby_wall_mat = RetroMaterialsLib.get_material("hall_beige")
		"BlockE": lobby_wall_mat = RetroMaterialsLib.get_material("plaster_dark")
		"BlockF": lobby_wall_mat = RetroMaterialsLib.get_material("panel_neglected")

	var flank_w: float = (width - 14.0) * 0.5
	if flank_w > 1.0:
		_blk_solid(blk, "GroundFlankL", Vector3(-7.0 - flank_w * 0.5, 1.65, 0.0), Vector3(flank_w, 3.3, depth), facade_mat)
		_blk_solid(blk, "GroundFlankR", Vector3(7.0 + flank_w * 0.5, 1.65, 0.0), Vector3(flank_w, 3.3, depth), facade_mat)

	if tag == "BlockF":
		_blk_solid(blk, "LobbyFloorFront", Vector3(0.0, 0.02, -3.25), Vector3(14.0, 0.06, 5.5), terrazzo_mat)
		_blk_solid(blk, "LobbyFloorSideL", Vector3(-4.5, 0.02, 2.75), Vector3(5.0, 0.06, 6.5), terrazzo_mat)
		_blk_solid(blk, "LobbyFloorSideR", Vector3(4.5, 0.02, 2.75), Vector3(5.0, 0.06, 6.5), terrazzo_mat)
	else:
		_blk_solid(blk, "LobbyFloor", Vector3(0.0, 0.02, 0.0), Vector3(14.0, 0.06, depth), terrazzo_mat)

	_blk_solid(blk, "LobbyFrontL", Vector3(-4.2, 1.65, front_z), Vector3(5.6, 3.3, 0.35), facade_mat)
	_blk_solid(blk, "LobbyFrontR", Vector3(4.2, 1.65, front_z), Vector3(5.6, 3.3, 0.35), facade_mat)
	_blk_solid(blk, "LobbyFrontHdr", Vector3(0.0, 2.95, front_z), Vector3(2.8, 0.7, 0.35), facade_mat)
	# Vestibule sidelight mullions framing a hinged, lockable 1.15m apartment entrance PhysicalDoor
	_blk_solid(blk, "VestibuleSideL", Vector3(-1.02, 1.10, front_z + 0.04), Vector3(0.76, 2.2, 0.14), trim_mat)
	_blk_solid(blk, "VestibuleSideR", Vector3(1.02, 1.10, front_z + 0.04), Vector3(0.76, 2.2, 0.14), trim_mat)
	add_physical_door(tag.to_lower() + "_entrance_door", "steel", Vector3(-0.58, 0.04, front_z + 0.04), 0.0, 88.0, false, "", 1.15, blk)

	_blk_solid(blk, "LobbyBackWall", Vector3(0.0, 1.65, half_d), Vector3(14.0, 3.3, 0.35), lobby_wall_mat)
	_blk_solid(blk, "LobbySideL", Vector3(-7.0, 1.65, 0.0), Vector3(0.35, 3.3, depth), lobby_wall_mat)
	_blk_solid(blk, "LobbySideR", Vector3(7.0, 1.65, 0.0), Vector3(0.35, 3.3, depth), lobby_wall_mat)

	# Front Concrete Planters framing Entrance
	_blk_solid(blk, "EntrancePlanterL", Vector3(-3.8, 0.25, front_z - 0.6), Vector3(1.8, 0.5, 0.8), curb_mat)
	add_mesh_box("EntranceSoilL", Vector3(-3.8, 0.51, front_z - 0.6), Vector3(1.6, 0.04, 0.6), soil_mat, Vector3.ZERO, blk)
	_blk_solid(blk, "EntrancePlanterR", Vector3(3.8, 0.25, front_z - 0.6), Vector3(1.8, 0.5, 0.8), curb_mat)
	add_mesh_box("EntranceSoilR", Vector3(3.8, 0.51, front_z - 0.6), Vector3(1.6, 0.04, 0.6), soil_mat, Vector3.ZERO, blk)

	spawn_glb("panelak_entrance", Vector3(0.0, 0.0, front_z - 0.1), Vector3.ZERO, Vector3.ONE, blk)
	# Real 1996 Aluminum Lobby Mailboxes, Intercom Nameplate, Electrical Panel & Ceiling Fluorescent
	spawn_glb("mailbox_bank_96", Vector3(-6.68, 1.38, front_z + 2.2), Vector3(0, 90, 0), Vector3.ONE, blk)
	spawn_glb("electrical_panel_96", Vector3(6.68, 1.50, front_z + 2.0), Vector3(0, -90, 0), Vector3.ONE, blk)
	spawn_glb("fluorescent_fixture_96", Vector3(0.0, 3.22, front_z + 3.0), Vector3.ZERO, Vector3.ONE, blk)
	add_mesh_box("NoticeBoard", Vector3(-6.74, 1.5, front_z + 4.4), Vector3(0.10, 0.85, 1.1), floor_mat, Vector3.ZERO, blk)
	add_mesh_box("EntranceMat", Vector3(0.0, 0.055, front_z + 1.15), Vector3(1.35, 0.02, 0.78), RetroMaterialsLib.get_material("iron"), Vector3.ZERO, blk)
	# Prompt 06 Part 12.3 Apartment Entrance Storytelling Dressing: resident shoes, potted hallway plant & delivery slip
	add_mesh_cyl("LobbyPlantPot", Vector3(5.85, 0.24, front_z + 1.45), 0.22, 0.42, RetroMaterialsLib.get_material("brick_cellar"), Vector3.ZERO, blk)
	add_mesh_cyl("LobbyPlantLeaf", Vector3(5.85, 0.62, front_z + 1.45), 0.34, 0.38, RetroMaterialsLib.get_material("foliage_shrub"), Vector3.ZERO, blk)
	add_mesh_box("LobbyShoesL", Vector3(5.45, 0.09, front_z + 3.2), Vector3(0.11, 0.10, 0.26), RetroMaterialsLib.get_material("iron"), Vector3(0, 12, 0), blk)
	add_mesh_box("LobbyShoesR", Vector3(5.65, 0.09, front_z + 3.25), Vector3(0.11, 0.10, 0.26), RetroMaterialsLib.get_material("iron"), Vector3(0, -6, 0), blk)
	if tag in ["BlockA", "BlockD"]:
		spawn_glb("old_bicycle", Vector3(-5.8, 0.05, front_z + 4.8), Vector3(0, 12, 0), Vector3.ONE, blk)
	elif tag == "BlockC":
		spawn_glb("wooden_chair", Vector3(-5.8, 0.05, front_z + 4.9), Vector3(0, 42, 0), Vector3.ONE, blk)

	var lobby_light := OmniLight3D.new()
	lobby_light.position = Vector3(0.0, 2.8, front_z + 2.5)
	lobby_light.light_color = Color(0.95, 0.88, 0.68)
	lobby_light.light_energy = 2.0 if seed_val != 19953 else 0.95
	lobby_light.omni_range = 11.0
	lobby_light.distance_fade_enabled = true
	blk.add_child(lobby_light)
	if seed_val == 19953:
		register_anim("sodium_lamp_sway", lobby_light, {"energy": 1.15, "seed": 5.2})

	# Exterior Apartment Entrance Canopy Light (makes every building entrance clearly identifiable in fog!)
	var ext_entry := SpotLight3D.new()
	ext_entry.name = tag + "_EntranceCanopyLight"
	ext_entry.position = Vector3(0.0, 2.82, front_z - 1.15)
	ext_entry.rotation_degrees = Vector3(-82.0, 0.0, 0.0)
	ext_entry.light_color = Color(1.0, 0.82, 0.50)
	ext_entry.light_energy = 3.2 if seed_val != 19953 else 1.8
	ext_entry.spot_range = 12.0
	ext_entry.spot_angle = 68.0
	ext_entry.spot_attenuation = 1.2
	ext_entry.distance_fade_enabled = true
	ext_entry.distance_fade_begin = 34.0
	blk.add_child(ext_entry)

	if has_2f_interior:
		_blk_solid(blk, "Floor2F_Flat", Vector3(-2.0, 3.38, 0.0), Vector3(10.0, 0.20, depth), floor_mat)
		_blk_stair(blk, "StairTo2F", Vector3(4.8, 0.0, front_z + 3.0), Vector3(4.8, 3.45, half_d - 2.0), 2.3, trim_mat)
		_blk_solid(blk, "Floor2F_NorthLanding", Vector3(4.8, 3.38, half_d - 1.2), Vector3(4.2, 0.20, 2.4), floor_mat)
		_blk_solid(blk, "Flat2F_Ceiling", Vector3(0.0, 6.65, 0.0), Vector3(14.0, 0.25, depth), trim_mat)
		_blk_solid(blk, "Flat2F_WallF", Vector3(0.0, 5.05, front_z), Vector3(14.0, 3.2, 0.35), facade_mat)
		_blk_solid(blk, "Flat2F_WallB", Vector3(0.0, 5.05, half_d), Vector3(14.0, 3.2, 0.35), wallp_mat)
		_blk_solid(blk, "Flat2F_WallL", Vector3(-7.0, 5.05, 0.0), Vector3(0.35, 3.2, depth), wallp_mat)
		_blk_solid(blk, "Flat2F_WallR", Vector3(7.0, 5.05, 0.0), Vector3(0.35, 3.2, depth), facade_mat)
		_blk_solid(blk, "Flat2F_DivN", Vector3(3.0, 5.05, 2.6), Vector3(0.25, 3.2, 5.0), wallp_mat)
		_blk_solid(blk, "Flat2F_DivS", Vector3(3.0, 5.05, -3.4), Vector3(0.25, 3.2, 4.0), wallp_mat)
		# Hinged PhysicalDoor in 2F Flat Entrance (fits doorway gap Z:-1.4..+0.1 cleanly)
		add_physical_door(tag.to_lower() + "_flat2f_door", "interior", Vector3(3.0, 3.48, -1.28), -90.0, -88.0, false, "", 1.32, blk)
		if flank_w > 1.0:
			_blk_solid(blk, "Flat2FFlankL", Vector3(-7.0 - flank_w * 0.5, 5.0, 0.0), Vector3(flank_w, 3.35, depth), facade_mat)
			_blk_solid(blk, "Flat2FFlankR", Vector3(7.0 + flank_w * 0.5, 5.0, 0.0), Vector3(flank_w, 3.35, depth), facade_mat)
	else:
		_blk_solid(blk, "LobbyCeiling", Vector3(0.0, 3.38, 0.0), Vector3(14.0, 0.25, depth), trim_mat)
		if flank_w > 1.0:
			_blk_solid(blk, "Flat2FFlankL", Vector3(-7.0 - flank_w * 0.5, 5.0, 0.0), Vector3(flank_w, 3.35, depth), facade_mat)
			_blk_solid(blk, "Flat2FFlankR", Vector3(7.0 + flank_w * 0.5, 5.0, 0.0), Vector3(flank_w, 3.35, depth), facade_mat)
		_blk_solid(blk, "Upper2FCenter", Vector3(0.0, 5.0, 0.0), Vector3(14.0, 3.35, depth), facade_mat)

	var upper_h: float = maxf(3.0, total_h - 6.7)
	_blk_solid(blk, "UpperTowerCore", Vector3(0.0, 6.7 + upper_h * 0.5, 0.0), Vector3(width, upper_h, depth), facade_mat)
	_blk_solid(blk, "RoofTrim", Vector3(0.0, total_h + 0.15, 0.0), Vector3(width + 0.4, 0.3, depth + 0.4), trim_mat)
	spawn_glb("sta_antenna_mast", Vector3(-4.0, total_h + 0.3, 1.5), Vector3.ZERO, Vector3(0.55, 0.55, 0.55), blk)

	# Zinc Rainwater Drainpipes on Facade Corners
	for dx: float in [-half_w + 0.3, half_w - 0.3]:
		add_mesh_cyl("DrainPipe_%d" % int(dx), Vector3(dx, total_h * 0.5, front_z - 0.12), 0.075, total_h, drain_mat, Vector3.ZERO, blk)

	var win_amber: Material = RetroMaterialsLib.get_material("window_amber")
	var win_tv: Material = RetroMaterialsLib.get_material("window_tv_blue")
	var win_dark: Material = RetroMaterialsLib.get_material("window_dark")
	for fl: int in range(1, floors):
		var wy: float = float(fl) * 3.1 + 1.5
		for wi: int in range(-2, 3):
			var wx: float = float(wi) * 4.8
			if absf(wx) < 3.6 and fl <= 1:
				continue
			var hsh: int = (seed_val + fl * 17 + wi * 31) & 255
			var wmat: Material = win_amber if (hsh % 7 == 0) else (win_tv if (hsh % 11 == 0) else win_dark)
			add_mesh_box("WinF_%d_%d" % [fl, wi + 3], Vector3(wx, wy, front_z - 0.08), Vector3(1.55, 1.35, 0.08), wmat, Vector3.ZERO, blk)
			add_mesh_box("WinB_%d_%d" % [fl, wi + 3], Vector3(wx, wy, half_d + 0.08), Vector3(1.55, 1.35, 0.08), win_amber if (hsh % 9 == 0) else win_dark, Vector3.ZERO, blk)
			if fl >= 1 and absf(wx) >= 8.0 and (hsh % 2 == 0):
				spawn_glb("panelak_balcony", Vector3(wx, float(fl) * 3.1 + 0.05, front_z - 0.02), Vector3.ZERO, Vector3.ONE, blk)


func _blk_solid(parent: Node3D, nm: String, loc: Vector3, sz: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.name = nm
	body.position = loc
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = sz
	mesh.mesh = box
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = sz
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)


func _blk_stair(parent: Node3D, nm: String, s_pt: Vector3, e_pt: Vector3, width: float, mat: Material) -> void:
	var delta := e_pt - s_pt
	var length := maxf(0.1, delta.length())
	var mid := (s_pt + e_pt) * 0.5
	var body := StaticBody3D.new()
	body.name = nm
	body.position = mid
	body.look_at_from_position(mid, e_pt, Vector3.UP)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, 0.22, length)
	col.shape = shape
	col.position = Vector3(0, -0.11, 0)
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.22, length)
	mesh.mesh = box
	mesh.position = Vector3(0, -0.11, 0)
	mesh.material_override = mat
	body.add_child(mesh)
	# Painted steel stairwell handrails on both edges of the ramp
	var rail_mat: Material = RetroMaterialsLib.get_material("iron")
	for side_x: float in [-width * 0.46, width * 0.46]:
		var rail := MeshInstance3D.new()
		var rbox := BoxMesh.new()
		rbox.size = Vector3(0.045, 0.045, length)
		rbox.material = rail_mat
		rail.mesh = rbox
		rail.position = Vector3(side_x, 0.86, 0.0)
		body.add_child(rail)
		for pz_frac: float in [-0.42, 0.0, 0.42]:
			var post := MeshInstance3D.new()
			var pbox := BoxMesh.new()
			pbox.size = Vector3(0.035, 0.88, 0.035)
			pbox.material = rail_mat
			post.mesh = pbox
			post.position = Vector3(side_x, 0.44, length * pz_frac)
			body.add_child(post)
	parent.add_child(body)


func _add_interior_lamp(pos: Vector3, col: Color, e: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = e
	l.omni_range = 10.0
	l.distance_fade_enabled = true
	add_child(l)


func _spawn_battery_pickup(pid: String, pos: Vector3, loc_label: String) -> void:
	var vis := spawn_glb("battery_pack", pos, Vector3(0, 25, 0))
	var area := add_interactable(pid, "battery_pickup", "[E] Pick up 4.5V Battery Pack (%s)" % loc_label, pos + Vector3(0, 0.25, 0), Vector3(1.1, 1.1, 1.1))
	if vis:
		area.set_meta("visual_node", vis)
