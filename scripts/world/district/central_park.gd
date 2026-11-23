class_name CentralParkBuilder
extends DistrictBuilderBase


func build_module(is_showcase: bool = false) -> void:
	var cobble: StandardMaterial3D = RetroMaterialsLib.get_material("cobble")
	var concrete: StandardMaterial3D = RetroMaterialsLib.get_material("concrete")
	var curb_mat: StandardMaterial3D = RetroMaterialsLib.get_material("concrete_curb")
	var soil_mat: StandardMaterial3D = RetroMaterialsLib.get_material("flowerbed_soil")
	var mud_mat: StandardMaterial3D = RetroMaterialsLib.get_material("mud_leaves")
	var shrub_mat: StandardMaterial3D = RetroMaterialsLib.get_material("foliage_shrub")
	var dark_plaster: StandardMaterial3D = RetroMaterialsLib.get_material("plaster_dark")
	var wood: StandardMaterial3D = RetroMaterialsLib.get_material("wood_dark")

	# Central Residential Park Square & Plaza around Well (0, 0, 0) & Gazebo (+14, 0, +8)
	add_solid_box("Park_CentralPlaza", Vector3(3.0, -0.19, 3.0), Vector3(22.0, 0.4, 22.0), cobble)
	add_solid_box("Park_PlaygroundPad", Vector3(-12.0, -0.20, 12.0), Vector3(17.0, 0.4, 17.0), cobble)

	# Concrete Retaining Planter Beds, Walkway Curbs & Dead Oak Leaf Beds (eliminate flat lawn)
	for fb_pos: Vector3 in [Vector3(-14.0, 0.14, -10.0), Vector3(16.0, 0.14, -8.0), Vector3(-2.0, 0.14, 22.0)]:
		add_solid_box("ParkPlanterWall", fb_pos, Vector3(4.6, 0.28, 2.2), curb_mat)
		add_mesh_box("ParkPlanterSoil", fb_pos + Vector3(0, 0.08, 0), Vector3(4.1, 0.16, 1.7), soil_mat)
	for curb_x: float in [-2.8, 2.8]:
		add_solid_box("ParkWalkCurbS_%d" % int(curb_x), Vector3(curb_x, 0.07, -14.5), Vector3(0.24, 0.14, 10.5), curb_mat)
		add_solid_box("ParkWalkCurbN_%d" % int(curb_x), Vector3(curb_x, 0.07, 17.5), Vector3(0.24, 0.14, 9.5), curb_mat)
	# 1990s Steel Playground Climbing Frame beside Sandbox & Park Trash Bins
	var climb_mat: StandardMaterial3D = RetroMaterialsLib.get_material("iron")
	for cx: float in [-14.2, -12.6]:
		for cz: float in [16.0, 18.2]:
			add_mesh_cyl("ClimbPost_%d_%d" % [int(absf(cx * 10)), int(cz * 10)], Vector3(cx, 1.05, cz), 0.04, 2.1, climb_mat)
	for rung_y: float in [0.55, 1.05, 1.55, 2.02]:
		add_mesh_cyl("ClimbBar_%d" % int(rung_y * 100), Vector3(-13.4, rung_y, 16.0), 0.03, 1.65, climb_mat, Vector3(0, 0, 90))
		add_mesh_cyl("ClimbBarN_%d" % int(rung_y * 100), Vector3(-13.4, rung_y, 18.2), 0.03, 1.65, climb_mat, Vector3(0, 0, 90))
	add_invisible_collider("ClimbFrame_Col", Vector3(-13.4, 1.05, 17.1), Vector3(1.8, 2.1, 2.4))
	for bin_p: Vector3 in [Vector3(6.8, 0.36, 4.2), Vector3(-7.8, 0.36, -4.8), Vector3(16.2, 0.36, 15.8)]:
		add_mesh_cyl("ParkBin_%d" % int(absf(bin_p.x)), bin_p, 0.22, 0.72, climb_mat)
	add_mesh_box("OakLeafPad1", Vector3(-21.0, -0.045, 18.0), Vector3(6.5, 0.02, 6.5), mud_mat)
	add_mesh_box("OakLeafPad2", Vector3(23.0, -0.045, 15.0), Vector3(6.5, 0.02, 6.5), mud_mat)

	# 1. Central Landmark: Medieval Well (0,0,0) + Watchclock #2 + Well Hands anomaly
	spawn_glb("medieval_well", Vector3(0.0, 0.0, 0.0))
	add_invisible_collider("Well_Col", Vector3(0.0, 0.65, 0.0), Vector3(2.05, 1.3, 2.05))
	spawn_glb("watchmans_clock", Vector3(0.0, 1.15, 0.98))
	var clk2_l := OmniLight3D.new()
	clk2_l.position = Vector3(0.0, 1.45, 1.15)
	clk2_l.light_color = Color(0.3, 0.95, 0.45)
	clk2_l.light_energy = 0.55
	clk2_l.omni_range = 3.5
	add_child(clk2_l)
	register_anim("watchclock_pendulum", clk2_l, {"energy": 0.55})
	add_interactable("clock_well", "clock", "[E] Stamp Watchman's Clock #2 (Central Park Well)", Vector3(0.0, 1.35, 1.15), Vector3(0.9, 0.9, 0.7))

	var well_hands := spawn_glb("anom_well_hands", Vector3(0.0, 0.25, 0.0))
	if well_hands:
		well_hands.name = "Anom_Well_Hands"
		register_dynamic("anom_well_hands", well_hands)
		register_anomaly_visual("ANOM_07", well_hands)
		register_anim("anom_well_hands_reach", well_hands, {"anomaly_id": "ANOM_07", "seed": 1.1})
		var w_area := add_interactable("well_inspect", "anomaly", "[E] Inspect Reaching Hands in Well", Vector3(0.0, 1.25, -1.05), Vector3(1.5, 1.1, 1.1), "ANOM_07")
		w_area.set_meta("visual_target", well_hands)

	# 2. Park Gazebo + Battery Pack #2
	spawn_glb("park_gazebo", Vector3(14.0, 0.0, 8.0), Vector3(0, 15, 0))
	add_invisible_collider("Gazebo_Col", Vector3(14.0, 1.2, 8.0), Vector3(3.8, 2.4, 3.8))
	var gazebo_lamp := OmniLight3D.new()
	gazebo_lamp.position = Vector3(14.0, 2.6, 8.0)
	gazebo_lamp.light_color = Color(0.92, 0.70, 0.35)
	gazebo_lamp.light_energy = 1.2
	gazebo_lamp.omni_range = 10.0
	gazebo_lamp.distance_fade_enabled = true
	add_child(gazebo_lamp)
	_spawn_battery_pickup("battery_pack_2", Vector3(14.0, 0.62, 9.15), "Park Gazebo Bench")

	# 3. Playground Area & Horror Event Location A (Moving Swing without wind!)
	var swing := spawn_glb("playground_swing", Vector3(-11.0, 0.0, 8.0), Vector3(0, 20, 0))
	add_invisible_collider("Swing_Col", Vector3(-11.0, 1.3, 8.0), Vector3(3.4, 2.6, 1.2), Vector3(0, 20, 0))
	if swing:
		var seat_pivot := swing.find_child("SwingSeatMoving", true, false)
		if seat_pivot is Node3D:
			register_anim("park_swing_creak", seat_pivot as Node3D, {"anomaly_id": "ANOM_04", "seed": 0.3})
			register_anomaly_visual("ANOM_04", swing)
	add_interactable("park_swing", "horror_hook", "[E] Inspect Self-Rocking Playground Swing", Vector3(-11.0, 1.1, 9.2), Vector3(2.4, 1.8, 2.0), "ANOM_04")
	register_event_hook("event_A_playground", Vector3(-11.0, 1.0, 8.0), "Playground swing rocking without wind")
	# Peter visual driven by NPCScheduleManager (unique articulated char_peter.glb)
	add_interactable("npc_peter", "story_npc", "[E] Talk to Peter (Playground)", Vector3(-13.8, 1.0, 10.6), Vector3(1.5, 1.8, 1.5), "", {"char_id": "peter"})
	# Prompt 06 Night 1 CP4: Metallic sound in fog -> dropped unfamiliar keys beside playground
	var brass_m: StandardMaterial3D = RetroMaterialsLib.get_material("prop_brass")
	add_mesh_box("N1_DroppedKeyRing", Vector3(-9.4, 0.03, 10.5), Vector3(0.11, 0.025, 0.07), brass_m, Vector3(0, 34, 0))
	add_interactable("n1_dropped_keys", "campaign_event", "[E] EXAMINE DROPPED UNFAMILIAR KEYS IN FOG", Vector3(-9.4, 0.45, 10.5), Vector3(1.5, 1.1, 1.5), "", {"event_id": "n1_dropped_keys"})
	# Prompt 06 Night 6 CP2: Unknown radio warning point in silent Central Park
	add_interactable("n6_radio_warning", "campaign_event", "[E] CHECK RADIO INTERFERENCE NEAR CENTRAL PARK WELL", Vector3(2.2, 1.1, 1.8), Vector3(2.2, 1.8, 2.2), "", {"event_id": "n6_radio_warning"})

	spawn_glb("playground_slide", Vector3(-17.0, 0.0, 13.5), Vector3(0, -35, 0))
	add_invisible_collider("Slide_Col", Vector3(-17.0, 0.9, 13.5), Vector3(1.2, 1.8, 3.4), Vector3(0, -35, 0))

	# Concrete Sandbox (-6, 0, +17)
	for sb_wall: Array in [
		[Vector3(-6.0, 0.18, 14.8), Vector3(4.6, 0.36, 0.28)],
		[Vector3(-6.0, 0.18, 19.2), Vector3(4.6, 0.36, 0.28)],
		[Vector3(-8.2, 0.18, 17.0), Vector3(0.28, 0.36, 4.4)],
		[Vector3(-3.8, 0.18, 17.0), Vector3(0.28, 0.36, 4.4)],
	]:
		add_solid_box("SandboxCurb", sb_wall[0], sb_wall[1], concrete)
	var sand_mat := StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.24, 0.21, 0.16)
	sand_mat.roughness = 0.95
	add_mesh_box("SandboxFill", Vector3(-6.0, 0.12, 17.0), Vector3(4.2, 0.10, 4.2), sand_mat)

	# 4. Carpet-Drying Structure (Klepáč) + Fluttering Sheet Anomaly (ANOM_02)
	spawn_glb("carpet_rack", Vector3(20.0, 0.0, -3.0), Vector3(0, -25, 0))
	add_invisible_collider("CarpetRack_Col", Vector3(20.0, 1.2, -3.0), Vector3(3.0, 2.4, 0.4), Vector3(0, -25, 0))
	var sheet1 := spawn_glb("anom_hanging_sheet", Vector3(20.0, 0.0, -3.0), Vector3(0, -25, 0))
	if sheet1:
		sheet1.name = "Anom_Hanging_Sheets"
		register_dynamic("anom_hanging_sheet_1", sheet1)
		register_anomaly_visual("ANOM_02", sheet1)
		register_anim("anom_hanging_sheet_flutter", sheet1, {"anomaly_id": "ANOM_02", "seed": 0.5})
		var sh_area := add_interactable("hanging_sheet_1", "anomaly", "[E] Inspect Fluttering Sheet on Carpet Rack", Vector3(20.0, 1.3, -1.8), Vector3(2.2, 2.0, 1.6), "ANOM_02")
		sh_area.set_meta("visual_target", sheet1)

	# 5. Benches + Payphone + Physical Park Anomalies + Park Life Sound
	var benches := [
		[Vector3(5.5, 0, 4.5), -18.0],
		[Vector3(-6.5, 0, -4.5), 145.0],
		[Vector3(17.5, 0, 16.0), -110.0],
		[Vector3(-22.0, 0, -4.0), 75.0],
	]
	for bi: int in range(benches.size()):
		var bpos: Vector3 = benches[bi][0]
		var brot: float = benches[bi][1]
		spawn_glb("courtyard_bench", bpos, Vector3(0, brot, 0))
		add_invisible_collider("ParkBenchCol_%d" % bi, bpos + Vector3(0, 0.45, 0), Vector3(1.85, 0.9, 0.7), Vector3(0, brot, 0))

	var bench_fig := spawn_glb("entity_shadow", Vector3(-22.0, 0.0, -4.0), Vector3(0, 75, 0), Vector3(0.88, 0.88, 0.88))
	if bench_fig:
		register_dynamic("park_bench_phantom", bench_fig)

	add_interactable("page_2", "page", "[E] Take Jozef's Torn Logbook Page #2", Vector3(-6.5, 0.55, -4.5), Vector3(1.0, 1.0, 1.0), "", {"page_id": "page_2"})

	spawn_glb("payphone_box", Vector3(24.0, 0.0, -10.0), Vector3(0, -90, 0))
	add_invisible_collider("Payphone_Col", Vector3(24.0, 1.2, -10.0), Vector3(1.15, 2.4, 1.15))
	add_interactable("elena_payphone", "payphone", "[E] Answer Ringing Courtyard Payphone", Vector3(22.8, 1.2, -10.0), Vector3(1.2, 1.8, 1.2))

	var ooze := spawn_glb("anom_black_ooze", Vector3(-16.0, 0.02, -9.0), Vector3(0, 22, 0))
	if ooze:
		ooze.name = "Anom_Black_Ooze"
		register_dynamic("anom_black_ooze", ooze)
		register_anomaly_visual("ANOM_05", ooze)
		register_anim("anom_black_ooze_pulse", ooze, {"anomaly_id": "ANOM_05", "seed": 2.0})
		var o_area := add_interactable("ooze_spot", "anomaly", "[E] Inspect Black Tar Seepage near Park", Vector3(-16.0, 0.5, -9.0), Vector3(2.0, 1.2, 2.0), "ANOM_05")
		o_area.set_meta("visual_target", ooze)

	var chair_cluster := Node3D.new()
	chair_cluster.name = "Anom_Floating_Chairs"
	chair_cluster.position = Vector3(-2.0, 0.0, -12.0)
	add_child(chair_cluster)
	var chair_poses := [
		[Vector3(-0.75, 0.22, -0.25), Vector3(78.0, 28.0, -14.0)],
		[Vector3(0.45, 0.24, 0.35), Vector3(-82.0, -45.0, 18.0)],
		[Vector3(0.95, 0.02, -0.45), Vector3(6.0, 118.0, -8.0)],
	]
	for ci: int in range(3):
		var cpos: Vector3 = chair_poses[ci][0]
		var crot: Vector3 = chair_poses[ci][1]
		var cnode := spawn_glb("wooden_chair", cpos, crot, Vector3.ONE, chair_cluster)
		if cnode:
			register_anim("anom_floating_chairs", cnode, {"anomaly_id": "ANOM_06", "hover_y": 0.01, "seed": float(ci) * 1.9})
	spawn_glb("crime_evidence_bag", Vector3(-0.15, 0.02, 0.15), Vector3(0, 32, 0), Vector3.ONE, chair_cluster)
	register_dynamic("anom_floating_chairs", chair_cluster)
	register_anomaly_visual("ANOM_06", chair_cluster)
	var ch_area := add_interactable("chairs_spot", "anomaly", "[E] Inspect Overturned Struggle Chairs & Dropped Belongings", Vector3(-2.0, 0.85, -12.0), Vector3(2.8, 2.0, 2.2), "ANOM_06")
	ch_area.set_meta("visual_target", chair_cluster)

	# Maintenance cabinet, wooden pallets & waste bin
	add_solid_box("ParkMaintCabinet", Vector3(-24.0, 0.9, 19.0), Vector3(1.6, 1.8, 0.9), dark_plaster)
	add_solid_box("ParkPallet", Vector3(-25.2, 0.14, 17.5), Vector3(1.2, 0.28, 1.0), wood)
	spawn_glb("dumpster_90s", Vector3(22.0, 0.0, 20.0), Vector3(0, -120, 0))
	add_invisible_collider("ParkBin_Col", Vector3(22.0, 0.68, 20.0), Vector3(1.5, 1.36, 1.15), Vector3(0, -120, 0))

	# 6. Park Trees, Bushes & Lamps
	var oak1 := spawn_glb("dead_oak_tree", Vector3(-21.0, 0.0, 18.0), Vector3(0, 35, 0))
	if oak1:
		register_anim("dead_oak_wind_sway", oak1, {"seed": 1.2})
	add_invisible_collider("Oak1_Col", Vector3(-21.0, 1.5, 18.0), Vector3(1.1, 3.0, 1.1))

	var oak2 := spawn_glb("dead_oak_tree", Vector3(23.0, 0.0, 15.0), Vector3(0, -45, 0))
	if oak2:
		register_anim("dead_oak_wind_sway", oak2, {"seed": 2.8})
	add_invisible_collider("Oak2_Col", Vector3(23.0, 1.5, 15.0), Vector3(1.1, 3.0, 1.1))

	var park_pines: Array[Transform3D] = []
	var pine_spots := [
		Vector3(-26, 0, -15), Vector3(-29, 0, 5), Vector3(-26, 0, 22),
		Vector3(27, 0, 21), Vector3(29, 0, 3), Vector3(18, 0, -15),
		Vector3(-12, 0, 22), Vector3(13, 0, 22), Vector3(-27, 0, 18)
	]
	for p_idx: int in range(pine_spots.size()):
		var sc: float = 0.85 + float(p_idx % 3) * 0.16
		park_pines.append(Transform3D(Basis(Vector3.UP, float(p_idx) * 0.9).scaled(Vector3.ONE * sc), pine_spots[p_idx]))
	add_multimesh_glb("ParkThicketTrees", "pine_tree_90s", park_pines, true)

	var shrub_xforms: Array[Transform3D] = []
	for bp: Vector3 in [
		Vector3(-22, 0, 2), Vector3(-21, 0, -12), Vector3(24, 0, 8), Vector3(21, 0, 21),
		Vector3(8, 0, 21), Vector3(-14, 0, -12), Vector3(14, 0, -10), Vector3(-3, 0, 22)
	]:
		shrub_xforms.append(Transform3D(Basis(Vector3.UP, bp.x * 0.4), bp))
	add_multimesh_glb("ParkShrubs", "shrub_bush_90s", shrub_xforms, false)

	var park_grass: Array[Transform3D] = []
	for gi: int in range(45):
		var angle := float(gi) * 0.72
		var rad := 13.0 + fmod(float(gi) * 1.9, 14.0)
		park_grass.append(Transform3D(Basis(Vector3.UP, angle).scaled(Vector3(1.1, 0.9, 1.1)), Vector3(cos(angle) * rad, 0.14, sin(angle) * rad)))
	var grass_mm := add_multimesh_box("ParkTallGrass", Vector3(0.36, 0.30, 0.36), shrub_mat, park_grass)
	if grass_mm:
		register_anim("grass_wind_sway", grass_mm, {"seed": 0.9})

	if not is_showcase:
		add_streetlamp(Vector3(-3.5, 0.0, 12.0), 90.0, "normal", 0.3)
		add_streetlamp(Vector3(-12.5, 0.0, 3.0), 0.0, "normal", 0.7)
		add_streetlamp(Vector3(6.5, 0.0, -8.5), 180.0, "normal", 1.5)
		add_streetlamp(Vector3(21.0, 0.0, 10.0), -90.0, "flicker", 2.5)
		add_streetlamp(Vector3(-19.0, 0.0, -15.0), 0.0, "normal", 1.1)
		add_streetlamp(Vector3(9.0, 0.0, 22.0), 180.0, "normal", 0.8)


func _spawn_battery_pickup(pid: String, pos: Vector3, loc_label: String) -> void:
	var vis := spawn_glb("battery_pack", pos, Vector3(0, 25, 0))
	var area := add_interactable(pid, "battery_pickup", "[E] Pick up 4.5V Battery Pack (%s)" % loc_label, pos + Vector3(0, 0.25, 0), Vector3(1.1, 1.1, 1.1))
	if vis:
		area.set_meta("visual_node", vis)
