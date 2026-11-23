class_name TechnicalAreaBuilder
extends DistrictBuilderBase

var red_door_pivot: Node3D
var red_door_collision: CollisionShape3D


func build_module(is_showcase: bool = false) -> void:
	if is_showcase:
		return
	var brick: StandardMaterial3D = RetroMaterialsLib.get_material("brick_cellar")
	var concrete: StandardMaterial3D = RetroMaterialsLib.get_material("concrete")
	var dark_plaster: StandardMaterial3D = RetroMaterialsLib.get_material("plaster_dark")
	var iron: StandardMaterial3D = RetroMaterialsLib.get_material("iron")

	# =========================================================================
	# 1. ELECTRICAL SUBSTATION / TRAFOSTANICA (X: -79..-65, Z: -19..-9)
	# =========================================================================
	add_solid_box("Trafo_Floor", Vector3(-72.0, 0.04, -14.0), Vector3(14.0, 0.08, 10.0), concrete)
	add_solid_box("Trafo_Roof", Vector3(-72.0, 3.85, -14.0), Vector3(14.6, 0.3, 10.6), concrete)
	add_solid_box("Trafo_Wall_W", Vector3(-79.0, 1.9, -14.0), Vector3(0.4, 3.8, 10.0), brick)
	add_solid_box("Trafo_Wall_N", Vector3(-72.0, 1.9, -9.0), Vector3(14.0, 3.8, 0.4), brick)
	add_solid_box("Trafo_Wall_S", Vector3(-72.0, 1.9, -19.0), Vector3(14.0, 3.8, 0.4), brick)
	add_solid_box("Trafo_Wall_EN", Vector3(-65.0, 1.9, -11.0), Vector3(0.4, 3.8, 4.0), dark_plaster)
	add_solid_box("Trafo_Wall_ES", Vector3(-65.0, 1.9, -16.8), Vector3(0.4, 3.8, 4.4), dark_plaster)
	add_solid_box("Trafo_Wall_EHdr", Vector3(-65.0, 2.95, -14.0), Vector3(0.4, 1.65, 2.2), dark_plaster)
	add_physical_door("substation_door", "steel", Vector3(-65.0, 0.05, -14.40), -90.0, 88.0, false, "", 1.25)
	add_sign_board("Sign_Trafostanica", "sign_trafostanica", Vector3(-64.75, 2.75, -14.0), Vector2(2.4, 0.8), Vector3(0, 90, 0))

	for tx: float in [-76.5, -72.5]:
		add_solid_box("TransformerUnit_%d" % int(absf(tx)), Vector3(tx, 1.2, -11.5), Vector3(2.2, 2.4, 2.0), iron)
	spawn_glb("electrical_panel_96", Vector3(-68.5, 1.4, -9.32), Vector3.ZERO)
	spawn_glb("fluorescent_fixture_96", Vector3(-72.0, 3.64, -14.0), Vector3.ZERO)
	spawn_glb("manhole_drain", Vector3(-71.0, 0.08, -14.2), Vector3.ZERO)
	add_solid_box("BreakerPanelBox", Vector3(-68.5, 1.4, -9.6), Vector3(1.4, 1.8, 0.6), iron)
	add_interactable("arcade_fusebox", "fusebox", "[E] Reset District Substation Main Breakers", Vector3(-68.5, 1.4, -10.4), Vector3(1.5, 1.8, 1.5))
	add_solid_box("TrafoLogTable", Vector3(-69.0, 0.45, -16.5), Vector3(1.6, 0.9, 0.8), concrete)
	add_interactable("page_5", "page", "[E] Take Jozef's Torn Logbook Page #5 (Substation)", Vector3(-69.0, 1.0, -16.5), Vector3(1.1, 1.1, 1.1), "", {"page_id": "page_5"})
	add_interactable("pickup_doc_registry", "story_doc", "[E] Inspect 1984 Municipal Housing Register (Building B)", Vector3(-69.0, 1.0, -15.6), Vector3(1.1, 1.1, 1.1), "", {"doc_id": "doc_registry_1984"})
	add_spatial_sound("loop_sodium_buzz", Vector3(-74.0, 1.5, -12.0), 13.0, -14.0, is_showcase)

	var trafo_l := OmniLight3D.new()
	trafo_l.position = Vector3(-72.0, 3.3, -14.0)
	trafo_l.light_color = Color(0.75, 0.90, 1.0)
	trafo_l.light_energy = 1.6
	trafo_l.omni_range = 10.0
	add_child(trafo_l)
	add_interactive_prop("trafo_light_switch", "switch", Vector3(-65.25, 1.35, -12.6), -90.0, [trafo_l])

	# =========================================================================
	# 2. BOILER HOUSE & GENERATOR HALL (X: -78..-60, Z: -40..-24)
	# =========================================================================
	add_solid_box("Boiler_Floor_W", Vector3(-74.0, 0.04, -32.0), Vector3(8.0, 0.08, 16.0), concrete)
	add_solid_box("Boiler_Floor_E", Vector3(-63.0, 0.04, -32.0), Vector3(6.0, 0.08, 16.0), concrete)
	add_solid_box("Boiler_Floor_S", Vector3(-68.0, 0.04, -37.0), Vector3(4.2, 0.08, 6.0), concrete)
	add_solid_box("Boiler_Floor_N", Vector3(-68.0, 0.04, -25.5), Vector3(4.2, 0.08, 3.0), concrete)
	add_solid_box("Boiler_Roof", Vector3(-69.0, 4.2, -32.0), Vector3(18.6, 0.3, 16.6), concrete)
	add_solid_box("Boiler_Wall_W", Vector3(-78.0, 2.1, -32.0), Vector3(0.4, 4.2, 16.0), brick)
	add_solid_box("Boiler_Wall_N", Vector3(-69.0, 2.1, -24.0), Vector3(18.0, 4.2, 0.4), brick)
	add_solid_box("Boiler_Wall_S", Vector3(-69.0, 2.1, -40.0), Vector3(18.0, 4.2, 0.4), brick)
	add_solid_box("Boiler_Wall_EN", Vector3(-60.0, 2.1, -27.5), Vector3(0.4, 4.2, 7.0), brick)
	add_solid_box("Boiler_Wall_ES", Vector3(-60.0, 2.1, -37.2), Vector3(0.4, 4.2, 5.6), brick)
	add_solid_box("Boiler_Wall_EHdr", Vector3(-60.0, 3.2, -32.6), Vector3(0.4, 2.0, 3.8), brick)
	add_physical_door("boiler_door", "steel", Vector3(-60.0, 0.05, -33.2), -90.0, -88.0, false, "", 1.25)
	add_sign_board("Sign_Kotolna", "sign_kotolna", Vector3(-59.75, 2.95, -32.5), Vector2(2.6, 0.8), Vector3(0, 90, 0))

	add_solid_box("DieselGenerator", Vector3(-74.0, 1.0, -28.0), Vector3(3.4, 2.0, 2.0), iron)
	add_stair_ramp("Stair_To_BunkerTunnel", Vector3(-68.0, 0.0, -27.2), Vector3(-68.0, -4.4, -34.4), 2.8, iron)

	# =========================================================================
	# 3. SUBTERRANEAN UTILITY TUNNEL, BOILER & BUNKER K-4 (Y = -4.4m)
	# =========================================================================
	add_solid_box("Sub_Floor", Vector3(-75.0, -4.65, -32.0), Vector3(34.0, 0.5, 20.0), concrete)
	add_solid_box("Sub_Ceiling_W", Vector3(-81.5, -0.65, -32.0), Vector3(21.0, 0.4, 20.0), concrete)
	add_solid_box("Sub_Ceiling_E", Vector3(-62.5, -0.65, -32.0), Vector3(9.0, 0.4, 20.0), concrete)
	add_solid_box("Sub_Ceiling_S", Vector3(-68.0, -0.65, -38.25), Vector3(4.2, 0.4, 7.5), concrete)
	add_solid_box("Sub_Wall_E", Vector3(-58.0, -2.5, -32.0), Vector3(0.4, 4.2, 20.0), brick)
	add_solid_box("Sub_Wall_W", Vector3(-92.0, -2.5, -32.0), Vector3(0.4, 4.2, 20.0), brick)
	# North Wall split around physical steel Hidden Service Corridor Door (X: -71.2..-69.8, unlocks Night 5!)
	add_solid_box("Sub_Wall_N_W", Vector3(-81.6, -2.5, -22.0), Vector3(20.8, 4.2, 0.4), brick)
	add_solid_box("Sub_Wall_N_E", Vector3(-63.9, -2.5, -22.0), Vector3(11.8, 4.2, 0.4), brick)
	add_solid_box("Sub_Wall_N_Hdr", Vector3(-70.5, -1.1, -22.0), Vector3(1.6, 1.4, 0.4), brick)
	add_physical_door("hidden_corridor_door", "steel", Vector3(-71.1, -4.4, -22.0), 0.0, 88.0, true, "key_service_corridor", 1.20)
	add_solid_box("Sub_Wall_S", Vector3(-75.0, -2.5, -42.0), Vector3(34.0, 4.2, 0.4), brick)

	# =========================================================================
	# 4. PROMPT 06 NIGHT 5–6: HIDDEN SERVICE CORRIDOR & APARTMENT 47 SERVICE ROOM
	#    (X: -88..-68, Y = -4.4m, Z: -22.0..-9.5)
	# =========================================================================
	var wood_m: StandardMaterial3D = RetroMaterialsLib.get_material("wood_dark")
	add_solid_box("HiddenCorr_Floor", Vector3(-78.0, -4.65, -15.75), Vector3(20.0, 0.5, 12.5), concrete)
	add_solid_box("HiddenCorr_Ceiling", Vector3(-78.0, -0.65, -15.75), Vector3(20.0, 0.4, 12.5), concrete)
	add_solid_box("HiddenCorr_Wall_N", Vector3(-78.0, -2.5, -9.5), Vector3(20.0, 4.2, 0.4), brick)
	add_solid_box("HiddenCorr_Wall_W", Vector3(-88.0, -2.5, -15.75), Vector3(0.4, 4.2, 12.5), brick)
	add_solid_box("HiddenCorr_Wall_E", Vector3(-68.0, -2.5, -15.75), Vector3(0.4, 4.2, 12.5), brick)
	# Partition between main corridor & Unmarked Door 47 Maintenance Room (Z = -13.6)
	add_solid_box("HiddenCorr_Div47_E", Vector3(-74.0, -2.5, -13.6), Vector3(12.0, 4.2, 0.35), dark_plaster)
	add_solid_box("HiddenCorr_Div47_W", Vector3(-86.0, -2.5, -13.6), Vector3(4.0, 4.2, 0.35), dark_plaster)
	add_solid_box("HiddenCorr_Div47_Hdr", Vector3(-82.0, -1.1, -13.6), Vector3(4.0, 1.4, 0.35), dark_plaster)
	add_physical_door("hidden_room_47_door", "steel", Vector3(-82.6, -4.4, -13.6), 0.0, 88.0, false, "", 1.15)
	add_mesh_cyl("HiddenCorr_Pipe", Vector3(-78.0, -1.25, -17.0), 0.12, 18.0, iron, Vector3(0, 0, 90))
	spawn_glb("fluorescent_fixture_96", Vector3(-75.0, -0.95, -18.0), Vector3.ZERO)
	spawn_glb("electrical_panel_96", Vector3(-68.35, -2.8, -17.5), Vector3(0, -90, 0))
	var hc_light := OmniLight3D.new()
	hc_light.name = "HiddenCorridorLight"
	hc_light.position = Vector3(-76.0, -1.5, -17.5)
	hc_light.light_color = Color(0.84, 0.88, 0.78)
	hc_light.light_energy = 1.45
	hc_light.omni_range = 12.5
	add_child(hc_light)
	var hc_light_47 := OmniLight3D.new()
	hc_light_47.name = "HiddenRoom47Light"
	hc_light_47.position = Vector3(-83.5, -1.6, -11.5)
	hc_light_47.light_color = Color(0.92, 0.74, 0.44)
	hc_light_47.light_energy = 1.3
	hc_light_47.omni_range = 8.5
	add_child(hc_light_47)

	# 4a. Workbench with 1984 Building Plan, Repair Tools & Maintenance Key referencing 'Apartment 47'
	add_solid_box("HiddenCorr_PlanTable", Vector3(-74.0, -3.95, -19.2), Vector3(2.0, 0.9, 0.9), wood_m)
	add_mesh_box("HiddenCorr_Plan1984", Vector3(-74.0, -3.48, -19.2), Vector3(0.72, 0.02, 0.52), RetroMaterialsLib.get_material("hall_beige"))
	add_mesh_box("HiddenCorr_MaintKey", Vector3(-73.4, -3.47, -19.0), Vector3(0.10, 0.025, 0.05), RetroMaterialsLib.get_material("prop_brass"))
	add_interactable("n5_hidden_plan_47", "campaign_event", "[E] EXAMINE 1984 BUILDING PLAN & MAINTENANCE KEY ('APT 47')", Vector3(-74.0, -3.3, -18.8), Vector3(2.0, 1.5, 1.8), "", {"event_id": "n5_hidden_plan_47"})

	# 4b. Isolated Storage Bay: Respectful Grounded Discovery of Iveta Hrončová (age 34 — char_iveta.glb)
	spawn_glb("char_iveta", Vector3(-81.8, -4.4, -15.6), Vector3(0, 18, 0))
	add_interactable("n5_iveta_discovery", "campaign_event", "[E] INSPECT IVETA HRONČOVÁ SCENE, BELONGINGS & DAMAGED PHONE", Vector3(-81.6, -3.5, -15.6), Vector3(2.4, 1.8, 2.2), "", {"event_id": "n5_iveta_discovery"})

	# 4c. Milan Švec's Abandoned Guard Radio & Fresh Tape suggesting he may still be alive
	add_solid_box("HiddenCorr_MilanCrate", Vector3(-86.2, -4.02, -18.5), Vector3(0.85, 0.76, 0.85), wood_m)
	spawn_glb("transistor_radio", Vector3(-86.2, -3.62, -18.5), Vector3(0, 35, 0))
	add_interactable("n5_milan_radio", "campaign_event", "[E] INSPECT MILAN ŠVEC'S OLD RADIO & FRESH RECORDING", Vector3(-86.0, -3.4, -18.4), Vector3(1.8, 1.5, 1.8), "", {"event_id": "n5_milan_radio"})

	# 4d. Unmarked Door 47 Maintenance Room Dressing (cot, thermos, electrical logbook where Milan survives!)
	add_solid_box("Room47_Cot", Vector3(-86.0, -4.15, -10.8), Vector3(2.1, 0.45, 0.9), iron)
	add_solid_box("Room47_Table", Vector3(-80.2, -3.98, -10.6), Vector3(1.2, 0.84, 0.7), wood_m)
	add_mesh_box("Room47_UnmarkedPlate", Vector3(-81.8, -2.75, -13.82), Vector3(0.24, 0.14, 0.03), RetroMaterialsLib.get_material("window_amber"))

	for pz: float in [-28.0, -36.0]:
		add_mesh_cyl("SubPipe_%d" % int(absf(pz)), Vector3(-75.0, -1.25, pz), 0.14, 28.0, iron, Vector3(0, 0, 90))
	# Prompt 05 Part 5.5 — Slatted basement storage cages, floor drains, water stains, electrical cabinet & abandoned chair
	spawn_glb("basement_storage_cage", Vector3(-72.2, -4.4, -24.2), Vector3.ZERO)
	add_invisible_collider("SubCage1_Col", Vector3(-72.2, -3.3, -24.2), Vector3(2.2, 2.2, 1.7))
	spawn_glb("basement_storage_cage", Vector3(-72.2, -4.4, -39.6), Vector3(0, 180, 0))
	add_invisible_collider("SubCage2_Col", Vector3(-72.2, -3.3, -39.6), Vector3(2.2, 2.2, 1.7))
	spawn_glb("electrical_panel_96", Vector3(-58.35, -2.8, -34.5), Vector3(0, -90, 0))
	spawn_glb("manhole_drain", Vector3(-68.0, -4.4, -32.0), Vector3.ZERO)
	spawn_glb("wooden_chair", Vector3(-61.2, -4.4, -36.8), Vector3(0, -55, 0))
	var sub_stain := StandardMaterial3D.new()
	sub_stain.albedo_color = Color(0.05, 0.07, 0.08, 0.72)
	sub_stain.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sub_stain.roughness = 0.16
	add_mesh_box("SubWaterStain", Vector3(-68.0, -4.39, -32.0), Vector3(3.4, 0.01, 2.6), sub_stain)

	spawn_glb("boiler_furnace", Vector3(-61.5, -4.4, -29.0), Vector3(0, -90, 0))
	add_invisible_collider("BoilerSub_Col", Vector3(-61.5, -3.2, -29.0), Vector3(2.2, 2.4, 2.6))
	var valve_w := add_mesh_cyl("BoilerValveWheel", Vector3(-63.2, -3.1, -29.0), 0.25, 0.08, iron, Vector3(0, 0, 90))
	register_anim("boiler_valve_spin", valve_w, {"seed": 0.0})
	var gauge_p := add_mesh_box("BoilerGaugePtr", Vector3(-63.0, -2.5, -29.2), Vector3(0.05, 0.18, 0.05), RetroMaterialsLib.get_material("window_amber"))
	register_anim("boiler_gauge_tremble", gauge_p, {"seed": 0.4})
	add_interactable("boiler_valve", "valve", "[E] Bleed Subterranean Boiler Pressure Valve", Vector3(-63.2, -3.1, -29.0), Vector3(1.4, 1.6, 1.4))

	spawn_glb("watchmans_clock", Vector3(-63.5, -3.2, -40.2), Vector3.ZERO)
	add_interactable("clock_boiler", "clock", "[E] Stamp Watchman's Clock #5 (Boiler Tunnel)", Vector3(-63.5, -3.1, -39.5), Vector3(1.1, 1.1, 1.1))
	_spawn_battery_pickup("battery_pack_8", Vector3(-66.5, -4.35, -39.5), "Boiler Utility Table")
	add_interactable("pickup_doc_sealed", "story_doc", "[E] Recover 1986 Sealed Corridor Schematic (Unit 47)", Vector3(-66.5, -3.7, -38.5), Vector3(1.2, 1.2, 1.2), "", {"doc_id": "doc_sealed_unit_47"})
	add_interactable("pickup_tape_05", "story_tape", "[E] Take Sub-Basement Archive Cassette #05", Vector3(-67.3, -3.7, -38.5), Vector3(1.2, 1.2, 1.2), "", {"tape_id": "tape_05_unit_47"})

	var boiler_l := OmniLight3D.new()
	boiler_l.position = Vector3(-64.0, -1.9, -31.0)
	boiler_l.light_color = Color(0.96, 0.44, 0.16)
	boiler_l.light_energy = 2.2
	boiler_l.omni_range = 14.0
	add_child(boiler_l)
	add_spatial_sound("loop_boiler_roar", Vector3(-62.0, -3.0, -29.0), 16.0, -10.0, is_showcase)
	add_interactive_prop("boiler_light_switch", "switch", Vector3(-60.25, 1.35, -30.5), -90.0, [boiler_l])

	# Dividing Wall at X = -76.0 separating Boiler Tunnel from BUNKER K-4 (X: -92..-76)
	add_solid_box("BunkerDiv_N", Vector3(-76.0, -2.5, -26.5), Vector3(0.4, 4.2, 9.0), brick)
	add_solid_box("BunkerDiv_S", Vector3(-76.0, -2.5, -37.5), Vector3(0.4, 4.2, 9.0), brick)
	add_solid_box("BunkerDiv_Hdr", Vector3(-76.0, -1.1, -32.0), Vector3(0.4, 1.4, 2.2), brick)

	# Red Bulkhead Door at X = -76.0, Z = -32.85
	red_door_pivot = Node3D.new()
	red_door_pivot.position = Vector3(-76.0, -4.4, -32.85)
	add_child(red_door_pivot)
	spawn_glb("red_bulkhead_door", Vector3.ZERO, Vector3.ZERO, Vector3.ONE, red_door_pivot)
	var door_body := StaticBody3D.new()
	red_door_collision = CollisionShape3D.new()
	var dcol := BoxShape3D.new()
	dcol.size = Vector3(0.22, 2.5, 1.75)
	red_door_collision.shape = dcol
	red_door_collision.position = Vector3(0, 1.25, 0.85)
	door_body.add_child(red_door_collision)
	red_door_pivot.add_child(door_body)
	add_interactable("red_door", "red_door", "[E] Inspect Sealed Cold-War Red Bulkhead Door", Vector3(-75.4, -3.2, -32.0), Vector3(1.6, 2.2, 1.8))

	# BUNKER K-4 Core (X = -84.0 < -71.0 -> matches GuardController check!)
	var k4_node := spawn_glb("device_k4", Vector3(-84.0, -4.4, -32.0))
	if k4_node:
		k4_node.name = "Anom_K4_Core"
		register_dynamic("anom_k4_core", k4_node)
		register_anomaly_visual("ANOM_32", k4_node)
		register_anim("anom_k4_core_breathe", k4_node, {"anomaly_id": "ANOM_32", "seed": 0.0})
	add_interactable("k4_core", "k4_core", "[E] Inspect Device K-4 Core", Vector3(-84.0, -3.1, -32.0), Vector3(2.2, 2.2, 2.2), "ANOM_32")

	var k4_l := OmniLight3D.new()
	k4_l.position = Vector3(-84.0, -2.0, -32.0)
	k4_l.light_color = Color(0.62, 0.35, 0.95)
	k4_l.light_energy = 2.6
	k4_l.omni_range = 13.0
	add_child(k4_l)
	add_spatial_sound("loop_k4_hum", Vector3(-84.0, -3.2, -32.0), 15.0, -9.0, is_showcase)

	var jozef := spawn_glb("char_resident_a", Vector3(-87.5, -4.4, -28.5), Vector3(0, 40, 0))
	if jozef:
		register_dynamic("anom_jozef_echo", jozef)
	add_interactable("jozef_npc", "jozef", "[E] Speak with Former Guard Jozef Bartos", Vector3(-87.5, -3.2, -28.5), Vector3(1.5, 2.2, 1.5))
	add_interactable("evidence_dossier", "evidence", "[E] Take Secret StB K-4 Dossier", Vector3(-88.5, -3.5, -37.5), Vector3(1.4, 1.4, 1.4), "", {"evidence_id": "evidence_dossier"})
	var r5 := spawn_glb("transistor_radio", Vector3(-87.0, -3.6, -35.5))
	if r5:
		register_anim("anom_radio_dial_jitter", r5, {"anomaly_id": "ANOM_18", "seed": 5.0})
	add_interactable("radio_5", "radio", "[E] Tune Bunker Radio #5 to 50.4 Hz", Vector3(-87.0, -3.5, -35.5), Vector3(1.1, 1.1, 1.1), "ANOM_18")


func set_red_door_open(is_open: bool) -> void:
	if red_door_pivot:
		var target_y: float = -95.0 if is_open else 0.0
		if is_inside_tree():
			var tw := create_tween()
			tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw.tween_property(red_door_pivot, "rotation_degrees:y", target_y, 0.95)
		else:
			red_door_pivot.rotation_degrees.y = target_y
	if red_door_collision:
		red_door_collision.disabled = is_open


func _spawn_battery_pickup(pid: String, pos: Vector3, loc_label: String) -> void:
	var vis := spawn_glb("battery_pack", pos, Vector3(0, 25, 0))
	var area := add_interactable(pid, "battery_pickup", "[E] Pick up 4.5V Battery Pack (%s)" % loc_label, pos + Vector3(0, 0.25, 0), Vector3(1.1, 1.1, 1.1))
	if vis:
		area.set_meta("visual_node", vis)
