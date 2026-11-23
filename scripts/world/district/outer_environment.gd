class_name OuterEnvironmentBuilder
extends DistrictBuilderBase


func build_module(is_showcase: bool = false) -> void:
	var grass: StandardMaterial3D = RetroMaterialsLib.get_material("grass_autumn")
	var mud_leaves: StandardMaterial3D = RetroMaterialsLib.get_material("mud_leaves")
	var gravel_wet: StandardMaterial3D = RetroMaterialsLib.get_material("gravel_wet")
	var asphalt: StandardMaterial3D = RetroMaterialsLib.get_material("asphalt_wet")
	var cobble: StandardMaterial3D = RetroMaterialsLib.get_material("cobble")
	var concrete: StandardMaterial3D = RetroMaterialsLib.get_material("concrete")
	var curb_mat: StandardMaterial3D = RetroMaterialsLib.get_material("concrete_curb")
	var shrub_mat: StandardMaterial3D = RetroMaterialsLib.get_material("foliage_shrub")
	var brick: StandardMaterial3D = RetroMaterialsLib.get_material("brick_cellar")
	var dark_plaster: StandardMaterial3D = RetroMaterialsLib.get_material("plaster_dark")
	var iron: StandardMaterial3D = RetroMaterialsLib.get_material("iron")

	# 1. Base Ground Skirt (290m x 260m, top Y = -0.06)
	add_solid_box("Ground_Terrain_Skirt", Vector3(-5.0, -0.31, -4.0), Vector3(290.0, 0.5, 260.0), grass)

	# Forest Edge & Ditch Mud/Leaf Surface Pads (eliminates bare flat lawn edges)
	add_mesh_box("MudPad_North", Vector3(-5.0, -0.052, 74.0), Vector3(240.0, 0.02, 34.0), mud_leaves)
	add_mesh_box("MudPad_West", Vector3(-114.0, -0.052, -4.0), Vector3(26.0, 0.02, 190.0), mud_leaves)
	add_mesh_box("MudPad_East", Vector3(106.0, -0.052, -4.0), Vector3(26.0, 0.02, 190.0), mud_leaves)
	add_mesh_box("MudPad_South", Vector3(-5.0, -0.052, -92.0), Vector3(240.0, 0.02, 26.0), mud_leaves)

	# 2. Connected Road & Service Drive Network (top Y = -0.02)
	add_solid_box("Road_Main_South", Vector3(-5.0, -0.22, -76.0), Vector3(230.0, 0.4, 7.6), asphalt)
	add_solid_box("Road_Gate_Spur", Vector3(0.0, -0.22, -62.0), Vector3(8.5, 0.4, 34.0), asphalt)
	add_solid_box("Road_Gate_Cross", Vector3(-8.0, -0.22, -48.0), Vector3(26.0, 0.4, 6.0), asphalt)
	add_solid_box("Road_West_Service", Vector3(-54.0, -0.22, -6.0), Vector3(5.2, 0.4, 134.0), asphalt)
	add_solid_box("Road_East_Delivery", Vector3(62.0, -0.22, -6.0), Vector3(5.4, 0.4, 134.0), asphalt)

	# Wet Gravel Shoulders & Courtyards Transitions (top Y = -0.01)
	add_solid_box("Gravel_ParkRim_W", Vector3(-30.0, -0.21, 2.0), Vector3(7.0, 0.4, 48.0), gravel_wet)
	add_solid_box("Gravel_Alley_NE", Vector3(20.0, -0.21, 38.0), Vector3(14.0, 0.4, 18.0), gravel_wet)
	add_solid_box("Gravel_Alley_NW", Vector3(-16.0, -0.21, 40.0), Vector3(12.0, 0.4, 16.0), gravel_wet)
	add_solid_box("Gravel_RearBlockE", Vector3(86.0, -0.21, -14.0), Vector3(12.0, 0.4, 44.0), gravel_wet)

	# Pedestrian Sidewalks & Enclosed Courtyard Paths (top Y = 0.00)
	add_solid_box("Walk_North_Loop", Vector3(-2.0, -0.20, 54.0), Vector3(132.0, 0.4, 4.2), cobble)
	add_solid_box("Walk_Park_NS", Vector3(0.0, -0.20, -6.0), Vector3(4.4, 0.4, 124.0), cobble)
	add_solid_box("Walk_Park_EW", Vector3(-4.0, -0.20, 2.0), Vector3(98.0, 0.4, 4.0), cobble)
	add_solid_box("Walk_East_Promenade", Vector3(37.5, -0.20, -2.0), Vector3(9.0, 0.4, 84.0), cobble)
	add_solid_box("Walk_West_Connector", Vector3(-48.0, -0.20, 12.0), Vector3(4.5, 0.4, 52.0), concrete)
	add_solid_box("Walk_BuildingD_Apron", Vector3(4.0, -0.20, -21.0), Vector3(38.0, 0.4, 9.0), cobble)
	add_solid_box("Walk_BuildingABC_Front", Vector3(3.0, -0.20, 28.0), Vector3(106.0, 0.4, 9.0), cobble)
	add_solid_box("Walk_BlockC_To_Shops", Vector3(46.0, -0.20, 26.0), Vector3(18.0, 0.4, 10.0), concrete)
	add_solid_box("Walk_BlockE_Apron", Vector3(66.0, -0.20, -14.0), Vector3(4.2, 0.4, 34.0), concrete)
	add_solid_box("Walk_SecOffice_Apron", Vector3(-16.0, -0.20, -49.0), Vector3(16.0, 0.4, 10.0), concrete)
	# Dedicated well-lit pedestrian walkway connecting Security Office West Flank cleanly around Building D to Central Park!
	add_solid_box("Walk_SecOffice_To_Park", Vector3(-15.5, -0.20, -32.0), Vector3(4.6, 0.4, 34.0), cobble)
	add_solid_box("Walk_Parking_To_Promenade", Vector3(28.5, -0.20, -32.0), Vector3(5.0, 0.4, 24.0), concrete)

	if is_showcase:
		return

	# 3. Main Gate & Tightened Concrete Perimeter Fence (X: -106..+96, Z: -70..+62)
	var gate_node := spawn_glb("carriage_gate", Vector3(0.0, 0.0, -70.0), Vector3.ZERO, Vector3(1.5, 1.3, 1.3))
	if gate_node:
		register_anim("gate_iron_swing", gate_node, {"seed": 0.0})
	add_sign_board("Sign_Blok14", "sign_blok14", Vector3(-6.2, 3.0, -69.6), Vector2(3.6, 1.2), Vector3(0, 180, 0))
	add_interactable("main_gate", "gate", "[E] Inspect Main Perimeter Gate / Street Barrier", Vector3(0.0, 1.4, -68.5), Vector3(4.5, 2.5, 2.2))

	var fence_xforms: Array[Transform3D] = []
	for x_seg: int in range(-103, 96, 5):
		if absf(float(x_seg)) >= 5.0:
			fence_xforms.append(Transform3D(Basis.IDENTITY, Vector3(float(x_seg), 1.35, -70.0)))
		if absf(float(x_seg) + 32.0) >= 3.0:
			fence_xforms.append(Transform3D(Basis.IDENTITY, Vector3(float(x_seg), 1.35, 62.0)))
	for z_seg: int in range(-68, 62, 5):
		fence_xforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-106.0, 1.35, float(z_seg))))
		fence_xforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(96.0, 1.35, float(z_seg))))
	add_multimesh_box("PerimeterFenceSlabs", Vector3(4.9, 2.7, 0.28), concrete, fence_xforms)

	add_invisible_collider("Fence_Col_N_L", Vector3(-70.0, 1.4, 62.0), Vector3(72.0, 2.8, 0.5))
	add_invisible_collider("Fence_Col_N_R", Vector3(34.0, 1.4, 62.0), Vector3(124.0, 2.8, 0.5))
	add_invisible_collider("Fence_Col_S_L", Vector3(-56.0, 1.4, -70.0), Vector3(100.0, 2.8, 0.5))
	add_invisible_collider("Fence_Col_S_R", Vector3(51.0, 1.4, -70.0), Vector3(90.0, 2.8, 0.5))
	add_invisible_collider("Fence_Col_W", Vector3(-106.0, 1.4, -4.0), Vector3(0.5, 2.8, 134.0))
	add_invisible_collider("Fence_Col_E", Vector3(96.0, 1.4, -4.0), Vector3(0.5, 2.8, 134.0))

	spawn_glb("carriage_gate", Vector3(-32.0, 0.0, 62.0), Vector3.ZERO, Vector3(1.1, 1.1, 1.1))
	add_invisible_collider("NorthGate_Col", Vector3(-32.0, 1.4, 62.0), Vector3(4.8, 2.8, 0.5))
	# Prompt 06 Night 6 Ending B Outer Service Escape Gate (Escort Milan out at dawn!)
	add_interactable("n6_escape_gate", "campaign_event", "[E] OUTER SERVICE GATE — ESCORT MILAN TO FREEDOM (DAWN ESCAPE)", Vector3(-32.0, 1.35, 60.6), Vector3(3.8, 2.4, 2.0), "", {"event_id": "n6_escape_gate"})

	# Prompt 06 Night 2 CP4: Northern Pedestrian Route cigarette remains & fresh muddy boot impression
	var cig_stub_m := StandardMaterial3D.new()
	cig_stub_m.albedo_color = Color(0.84, 0.62, 0.28)
	cig_stub_m.roughness = 0.85
	add_mesh_box("NorthPath_BootPrint", Vector3(2.0, 0.015, 54.0), Vector3(0.24, 0.02, 0.38), mud_leaves, Vector3(0, 22, 0))
	add_mesh_cyl("NorthPath_CigButt1", Vector3(2.35, 0.02, 54.2), 0.012, 0.06, cig_stub_m, Vector3(0, 0, 90))
	add_mesh_cyl("NorthPath_CigButt2", Vector3(2.22, 0.02, 54.32), 0.012, 0.05, cig_stub_m, Vector3(0, 40, 90))
	add_interactable("n2_north_bootprint", "campaign_event", "[E] INSPECT CIGARETTE REMAINS & FRESH BOOT PRINT (NORTH PATH)", Vector3(2.1, 0.45, 54.1), Vector3(2.0, 1.2, 2.0), "", {"event_id": "n2_north_bootprint"})

	# 4. Bus Stop, Billboard & Technical Shed
	spawn_glb("bus_stop_90s", Vector3(-36.0, 0.0, -81.0), Vector3(0.0, 180.0, 0.0))
	add_sign_board("Sign_BusStop", "sign_bus_stop", Vector3(-38.4, 2.65, -80.3), Vector2(1.0, 0.55), Vector3.ZERO)
	add_invisible_collider("BusStop_Col", Vector3(-36.0, 1.2, -81.8), Vector3(4.0, 2.4, 0.6))

	add_solid_box("BillboardStandL", Vector3(31.7, 2.6, -81.0), Vector3(0.25, 5.2, 0.25), iron)
	add_solid_box("BillboardStandR", Vector3(36.3, 2.6, -81.0), Vector3(0.25, 5.2, 0.25), iron)
	add_solid_box("BillboardBoard", Vector3(34.0, 4.0, -81.0), Vector3(5.2, 3.6, 0.25), dark_plaster)
	add_sign_board("Billboard_1995", "billboard_1995", Vector3(34.0, 4.0, -80.84), Vector2(4.8, 3.3), Vector3.ZERO)

	add_solid_box("RuinedShed_W", Vector3(-94.0, 1.5, 48.0), Vector3(0.35, 3.0, 7.0), brick)
	add_solid_box("RuinedShed_N", Vector3(-90.5, 1.5, 51.5), Vector3(7.0, 3.0, 0.35), brick)
	add_solid_box("RuinedShed_E", Vector3(-87.0, 1.5, 48.0), Vector3(0.35, 3.0, 7.0), brick)
	add_solid_box("RuinedShed_Roof", Vector3(-90.5, 3.1, 48.0), Vector3(7.6, 0.25, 7.6), concrete, Vector3(0, 0, -4))

	# 5. Concrete Road Curbs, Manholes & Overhead Utility Poles (MultiMesh)
	var curb_xforms: Array[Transform3D] = []
	for cx in range(-95, 92, 4):
		curb_xforms.append(Transform3D(Basis.IDENTITY, Vector3(float(cx), 0.06, -72.0)))
	for cz in range(-64, 54, 4):
		curb_xforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-51.3, 0.06, float(cz))))
		curb_xforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-56.7, 0.06, float(cz))))
		curb_xforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(59.2, 0.06, float(cz))))
		curb_xforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(64.8, 0.06, float(cz))))
	add_multimesh_box("ConcreteRoadCurbs", Vector3(3.8, 0.14, 0.22), curb_mat, curb_xforms)

	var manhole_xforms: Array[Transform3D] = []
	for mp: Vector3 in [
		Vector3(-54.0, 0.01, -48.0), Vector3(-54.0, 0.01, -24.0), Vector3(-54.0, 0.01, 2.0), Vector3(-54.0, 0.01, 28.0),
		Vector3(62.0, 0.01, -30.0), Vector3(62.0, 0.01, -6.0), Vector3(62.0, 0.01, 18.0), Vector3(62.0, 0.01, 38.0),
		Vector3(0.0, 0.01, -60.0), Vector3(0.0, 0.01, -20.0), Vector3(20.0, 0.01, 28.0), Vector3(-20.0, 0.01, 28.0),
		Vector3(-68.0, 0.01, -48.0), Vector3(14.0, 0.01, -52.0), Vector3(32.0, 0.01, -52.0), Vector3(-12.0, 0.01, 54.0),
	]:
		manhole_xforms.append(Transform3D(Basis.IDENTITY, mp))
	add_multimesh_glb("DistrictManholes", "manhole_drain", manhole_xforms, false)

	var pole_xforms: Array[Transform3D] = []
	for pp: Vector3 in [
		Vector3(-57.4, 0.0, -56.0), Vector3(-57.4, 0.0, -32.0), Vector3(-57.4, 0.0, -6.0), Vector3(-57.4, 0.0, 22.0), Vector3(-57.4, 0.0, 48.0),
		Vector3(65.2, 0.0, -48.0), Vector3(65.2, 0.0, -24.0), Vector3(65.2, 0.0, 4.0), Vector3(65.2, 0.0, 28.0), Vector3(65.2, 0.0, 52.0),
		Vector3(-42.0, 0.0, -71.5), Vector3(-12.0, 0.0, -71.5), Vector3(18.0, 0.0, -71.5), Vector3(48.0, 0.0, -71.5),
	]:
		pole_xforms.append(Transform3D(Basis.IDENTITY, pp))
	add_multimesh_glb("UtilityPoles", "utility_pole_90s", pole_xforms, true)

	# 6. Dense Forest, Interior Courtyards Shrubs & Wild Grass / Weed Tufts
	var rng := RandomNumberGenerator.new()
	rng.seed = 199502
	var pine_xforms: Array[Transform3D] = []
	for tx in range(-106, 100, 9):
		for tz in [65.0, 74.0, 84.0, 96.0]:
			var sc: float = rng.randf_range(0.85, 1.38)
			pine_xforms.append(Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * sc), Vector3(float(tx) + rng.randf_range(-2.2, 2.2), 0.0, tz + rng.randf_range(-1.8, 1.8))))
	for tz in range(-68, 62, 10):
		for wx in [-118.0, -109.0, -96.0]:
			if tz > -48 and tz < 32 and wx > -103.0:
				continue
			pine_xforms.append(Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.85, 1.3)), Vector3(wx + rng.randf_range(-2, 2), 0.0, float(tz))))
		for ex in [88.0, 100.0, 110.0]:
			if tz > -32 and tz < 8 and ex < 92.0:
				continue
			pine_xforms.append(Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.85, 1.3)), Vector3(ex + rng.randf_range(-2, 2), 0.0, float(tz))))
	add_multimesh_glb("OuterPineForest", "pine_tree_90s", pine_xforms, true)

	var shrub_xforms: Array[Transform3D] = []
	for bx: float in [-42.0, -24.0, -10.0, 12.0, 26.0, 44.0, 50.0, -60.0, 72.0, 82.0]:
		for bz: float in [-42.0, -18.0, 22.0, 49.0, 58.0]:
			var s_sc: float = rng.randf_range(0.75, 1.35)
			shrub_xforms.append(Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * s_sc), Vector3(bx + rng.randf_range(-2.0, 2.0), 0.0, bz + rng.randf_range(-1.5, 1.5))))
	add_multimesh_glb("DistrictShrubs", "shrub_bush_90s", shrub_xforms, false)

	var grass_xforms: Array[Transform3D] = []
	for gi: int in range(180):
		var gx: float = rng.randf_range(-95.0, 88.0)
		var gz: float = rng.randf_range(-64.0, 58.0)
		if absf(gx) < 22.0 and absf(gz) < 22.0:
			continue
		if gx > 4.0 and gx < 46.0 and gz > -64.0 and gz < -40.0:
			continue
		grass_xforms.append(Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3(rng.randf_range(0.7, 1.8), rng.randf_range(0.4, 1.4), rng.randf_range(0.7, 1.8))), Vector3(gx, 0.14, gz)))
	add_multimesh_box("WildGrassWeeds", Vector3(0.42, 0.34, 0.42), shrub_mat, grass_xforms)

	# 7. Distant Skyline Silhouette Apartment Blocks outside Forest Perimeter
	var skyline_specs := [
		Vector3(-75, 10.0, 128), Vector3(-20, 13.0, 134), Vector3(40, 10.5, 126), Vector3(95, 11.5, 130),
		Vector3(138, 10.0, 45), Vector3(142, 12.5, -18), Vector3(135, 9.5, -62),
		Vector3(-136, 9.5, 48), Vector3(-140, 12.0, -16), Vector3(-35, 10.0, -118)
	]
	for idx: int in range(skyline_specs.size()):
		var sp: Vector3 = skyline_specs[idx]
		add_mesh_box("DistantSkyline_%d" % idx, sp, Vector3(32.0, sp.y * 2.0, 12.0), dark_plaster)

	# 8. Streetlamps across Roads & Pedestrian Patrol Routes (regular intervals; selective flicker/broken only!)
	add_streetlamp(Vector3(-24.0, 0.0, -67.0), 180.0, "normal", 0.2)
	add_streetlamp(Vector3(-6.2, 0.0, -65.5), 90.0, "normal", 0.4)
	add_streetlamp(Vector3(-8.5, 0.0, -51.5), 180.0, "normal", 0.6)
	add_streetlamp(Vector3(24.0, 0.0, -67.0), 180.0, "flicker", 1.7)
	add_streetlamp(Vector3(-18.2, 0.0, -38.0), 90.0, "normal", 1.0)
	add_streetlamp(Vector3(-18.2, 0.0, -24.0), 90.0, "normal", 1.3)
	add_streetlamp(Vector3(24.5, 0.0, -34.0), 90.0, "normal", 1.5)
	add_streetlamp(Vector3(-50.5, 0.0, -40.0), -90.0, "dim", 0.0)
	add_streetlamp(Vector3(-50.5, 0.0, 4.0), -90.0, "normal", 0.9)
	add_streetlamp(Vector3(-50.5, 0.0, 38.0), -90.0, "flicker", 3.1)
	add_streetlamp(Vector3(-22.0, 0.0, 52.0), 180.0, "normal", 0.5)
	add_streetlamp(Vector3(26.0, 0.0, 52.0), 180.0, "dim", 2.1)
	add_streetlamp(Vector3(-22.0, 0.0, 26.0), 0.0, "normal", 1.1)
	add_streetlamp(Vector3(14.0, 0.0, 26.0), 0.0, "normal", 1.4)
	add_streetlamp(Vector3(33.2, 0.0, 22.0), 90.0, "normal", 1.2)
	add_streetlamp(Vector3(33.2, 0.0, 4.0), 90.0, "normal", 1.8)
	add_streetlamp(Vector3(33.2, 0.0, -22.0), 90.0, "flicker", 4.0)

	# 9. Horror Event D: Northern Forest Path Stalker + Spatial Wind/Tram Audio
	var stalker := spawn_glb("entity_shadow", Vector3(-12.0, 0.0, 54.0), Vector3(0.0, 180.0, 0.0))
	if stalker:
		stalker.name = "Anom_Shadow_Stalker"
		register_dynamic("anom_shadow_stalker", stalker)
		register_anomaly_visual("ANOM_27", stalker)
		register_anim("anom_shadow_stalker_glide", stalker, {"anomaly_id": "ANOM_27", "patrol_span": 6.5, "seed": 1.3})
		var st_area := add_interactable("shadow_stalker", "anomaly", "[2+LMB] Stun Shadow Stalker on Northern Path", Vector3(-12.0, 1.2, 54.0), Vector3(2.8, 2.4, 3.2), "ANOM_27")
		st_area.set_meta("visual_target", stalker)
	register_event_hook("event_D_north_path", Vector3(-12.0, 1.0, 54.0), "Human silhouette between northern forest trees")
	add_spatial_sound("distant_tram", Vector3(0.0, 2.0, -78.0), 48.0, -14.0, is_showcase)
	add_spatial_sound("loop_forest_wind", Vector3(-12.0, 2.2, 58.0), 34.0, -12.0, is_showcase)
	add_spatial_sound("loop_forest_wind", Vector3(-92.0, 2.2, 14.0), 30.0, -14.0, is_showcase)
