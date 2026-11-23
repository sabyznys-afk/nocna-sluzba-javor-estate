class_name GarageComplexBuilder
extends DistrictBuilderBase


func build_module(is_showcase: bool = false) -> void:
	if is_showcase:
		return
	var concrete: StandardMaterial3D = RetroMaterialsLib.get_material("concrete")
	var asphalt: StandardMaterial3D = RetroMaterialsLib.get_material("asphalt_wet")
	var gravel_wet: StandardMaterial3D = RetroMaterialsLib.get_material("gravel_wet")
	var shutter: StandardMaterial3D = RetroMaterialsLib.get_material("shutter")
	var wood: StandardMaterial3D = RetroMaterialsLib.get_material("wood_dark")

	# Secluded Garages Apron Yard (X: -94..-54, Z: -63..-43)
	add_solid_box("GarageYard_Asphalt", Vector3(-74.0, -0.22, -52.5), Vector3(40.0, 0.4, 19.0), asphalt)
	add_solid_box("GarageYard_GravelTrim", Vector3(-92.0, -0.21, -52.5), Vector3(4.5, 0.4, 18.0), gravel_wet)
	add_solid_box("GarageScreenWall_S", Vector3(-55.5, 1.4, -58.5), Vector3(0.4, 2.8, 9.0), concrete)
	add_solid_box("GarageScreenWall_N", Vector3(-55.5, 1.4, -44.5), Vector3(0.4, 2.8, 3.0), concrete)

	# Row of 10 Concrete Garages along Z = -62.5..-55.0 (each 3.6m wide -> X: -92 .. -56)
	add_solid_box("Garages_BackWall", Vector3(-74.0, 1.4, -62.5), Vector3(37.0, 2.8, 0.35), concrete)
	add_solid_box("Garages_Roof", Vector3(-74.0, 2.9, -58.7), Vector3(37.6, 0.25, 8.2), concrete)
	var rust_iron: StandardMaterial3D = RetroMaterialsLib.get_material("iron")
	add_mesh_cyl("Garages_RainGutter", Vector3(-74.0, 2.82, -54.58), 0.07, 37.6, rust_iron, Vector3(0, 0, 90))
	spawn_glb("manhole_drain", Vector3(-74.0, 0.01, -51.5), Vector3.ZERO)
	var garage_puddle := StandardMaterial3D.new()
	garage_puddle.albedo_color = Color(0.05, 0.07, 0.08, 0.76)
	garage_puddle.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	garage_puddle.roughness = 0.09
	add_mesh_box("GarageApronPuddle", Vector3(-72.0, 0.004, -50.8), Vector3(5.2, 0.008, 2.6), garage_puddle)
	for wpos: Vector3 in [Vector3(-92.8, 0.0, -54.5), Vector3(-56.2, 0.0, -54.2), Vector3(-84.5, 0.0, -44.2)]:
		spawn_glb("shrub_bush_90s", wpos, Vector3(0, wpos.x * 7.0, 0), Vector3(0.65, 0.55, 0.65))

	for i: int in range(11):
		var px: float = -92.2 + i * 3.6
		add_solid_box("GarageDiv_%d" % i, Vector3(px, 1.4, -58.7), Vector3(0.24, 2.8, 7.6), concrete)

	for g: int in range(10):
		var cx: float = -90.4 + g * 3.6
		# Painted 1990s Garage Number Plaque above every bay (01-10)
		var num_plate := add_mesh_box("GaragePlaque_%02d" % (g + 1), Vector3(cx, 2.74, -54.78), Vector3(0.46, 0.22, 0.04), RetroMaterialsLib.get_material("plaster_dark"))
		if num_plate:
			var nl := Label3D.new()
			nl.text = "%02d" % (g + 1)
			nl.pixel_size = 0.0045
			nl.modulate = Color(0.86, 0.80, 0.64)
			nl.position = Vector3(0, 0, 0.03)
			num_plate.add_child(nl)
		if g == 2:
			# Garage 03: OPEN walk-in workshop bay with Steel Locker, Electrical Panel & Fluorescent Lamp!
			spawn_glb("fluorescent_fixture_96", Vector3(cx, 2.70, -58.8), Vector3.ZERO)
			spawn_glb("electrical_panel_96", Vector3(cx + 1.45, 1.45, -58.0), Vector3(0, -90, 0))
			add_solid_box("Garage03_Bench", Vector3(cx, 0.48, -61.6), Vector3(2.8, 0.94, 0.8), wood)
			_spawn_battery_pickup("battery_pack_4", Vector3(cx - 0.6, 0.98, -61.6), "Open Garage 03")
			add_interactable("page_4", "page", "[E] Take Jozef's Torn Logbook Page #4 (Garage 03)", Vector3(cx + 0.7, 1.0, -61.6), Vector3(1.1, 1.1, 1.1), "", {"page_id": "page_4"})
			add_interactable("pickup_doc_milan", "story_doc", "[E] Read Milan Švec's Torn Log Sheet #29", Vector3(cx, 1.0, -61.0), Vector3(1.1, 1.1, 1.1), "", {"doc_id": "doc_milan_sheet"})
			add_interactive_prop("garage03_locker", "locker", Vector3(cx - 1.35, 0.02, -59.5), 90.0, [], "key_garage_06", true)
		elif g == 5:
			# Garage 06: Partial Concrete Frame + Lockable Hinged Physical Steel Door (requires key_garage_06)
			add_solid_box("Garage06_WallL", Vector3(cx - 1.05, 1.3, -55.0), Vector3(1.2, 2.6, 0.22), concrete)
			add_solid_box("Garage06_WallR", Vector3(cx + 1.05, 1.3, -55.0), Vector3(1.2, 2.6, 0.22), concrete)
			add_solid_box("Garage06_Hdr", Vector3(cx, 2.38, -55.0), Vector3(1.2, 0.56, 0.22), concrete)
			add_physical_door("garage_06_door", "steel", Vector3(cx - 0.52, 0.0, -55.0), 0.0, -88.0, true, "key_garage_06", 1.05)
			_spawn_battery_pickup("battery_garage06_stash", Vector3(cx, 0.05, -60.5), "Garage 06 Locked Stash")
			add_interactable("pickup_tape_04", "story_tape", "[E] Take Unlabeled Maxell C-60 Cassette #04", Vector3(cx, 0.85, -59.6), Vector3(1.2, 1.2, 1.2), "", {"tape_id": "tape_04_before_shift"})
			add_interactable("garage_06", "clue", "[E] Inspect Stash Crates inside Garage 06", Vector3(cx, 1.0, -61.0), Vector3(1.4, 1.4, 1.2))
		elif g == 6:
			# Garage 07: Horror Event Location C — light leaking out beneath closed door!
			add_solid_box("GarageDoor_07", Vector3(cx, 1.38, -55.0), Vector3(3.3, 2.48, 0.16), shutter)
			var slit_mat := StandardMaterial3D.new()
			slit_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			slit_mat.albedo_color = Color(0.52, 0.88, 0.95)
			var slit := add_mesh_box("Garage07_LightSlit", Vector3(cx, 0.04, -54.9), Vector3(3.2, 0.08, 0.18), slit_mat)
			var ulight := OmniLight3D.new()
			ulight.position = Vector3(cx, 0.18, -54.3)
			ulight.light_color = Color(0.48, 0.86, 0.96)
			ulight.light_energy = 2.1
			ulight.omni_range = 7.0
			ulight.distance_fade_enabled = true
			add_child(ulight)
			register_anim("garage_underlight_flicker", ulight, {"energy": 2.1, "seed": 1.4})
			register_anim("garage_underlight_flicker", slit, {"seed": 1.4})
			register_event_hook("event_C_garage_07", Vector3(cx, 0.8, -54.3), "Unnatural glow beneath locked Garage 07 door")
			add_interactable("garage_07", "horror_hook", "[E] Peer Under Lit Garage 07 Door", Vector3(cx, 1.1, -54.3), Vector3(2.0, 1.8, 1.4), "ANOM_03")
			# Prompt 06 Night 3 CP2: Garage 07 physical evidence (cigarette packet, maintenance key, handwritten number, disturbed dust)
			var cig_mat := StandardMaterial3D.new()
			cig_mat.albedo_color = Color(0.74, 0.22, 0.18)
			cig_mat.roughness = 0.78
			add_mesh_box("Garage07_CigPacket", Vector3(cx - 0.55, 0.04, -53.85), Vector3(0.08, 0.03, 0.11), cig_mat, Vector3(0, 22, 0))
			add_mesh_box("Garage07_MaintKey", Vector3(cx - 0.32, 0.03, -53.75), Vector3(0.09, 0.02, 0.04), RetroMaterialsLib.get_material("prop_brass"), Vector3(0, -18, 0))
			add_interactable("n3_garage07_clues", "campaign_event", "[E] INSPECT GARAGE 07 EVIDENCE (CIGARETTES, KEY & NUMBER '47')", Vector3(cx - 0.4, 0.55, -53.7), Vector3(1.8, 1.2, 1.5), "", {"event_id": "n3_garage07_clues"})
			add_spatial_sound("loop_k4_hum", Vector3(cx, 0.8, -55.5), 9.0, -15.0, is_showcase)
		else:
			add_solid_box("GarageDoor_%02d" % (g + 1), Vector3(cx, 1.3, -55.0), Vector3(3.3, 2.6, 0.16), shutter)

	add_streetlamp(Vector3(-88.0, 0.0, -45.0), 180.0, "normal", 1.2)
	add_streetlamp(Vector3(-74.0, 0.0, -45.0), 180.0, "dim", 0.5)
	add_streetlamp(Vector3(-58.0, 0.0, -45.0), 180.0, "flicker", 2.0)

	# Milan 'The Mole' behind garage corner (upgraded unique model) + Night 4-5 Mobsters group
	spawn_glb("char_milan", Vector3(-86.0, 0.0, -50.0), Vector3(0, 45, 0), Vector3(0.96, 0.96, 0.96))
	add_interactable("milan_npc", "npc", "[E] Talk to Milan 'The Mole' (Behind Garages)", Vector3(-86.0, 1.1, -49.5), Vector3(1.6, 2.0, 1.6))

	var mobsters := Node3D.new()
	mobsters.name = "MobstersGroup"
	mobsters.position = Vector3(-62.0, 0.0, -47.0)
	add_child(mobsters)
	spawn_glb("char_resident_c", Vector3(-0.7, 0, 0), Vector3(0, 15, 0), Vector3.ONE, mobsters)
	spawn_glb("char_resident_a", Vector3(0.7, 0, 0.2), Vector3(0, -25, 0), Vector3.ONE, mobsters)
	register_dynamic("mobsters_group", mobsters)
	add_interactable("mobsters_int", "mobsters", "[E] Confront Cigarette Smugglers by Garages", Vector3(-62.0, 1.2, -47.0), Vector3(2.8, 2.0, 2.4))


func _spawn_battery_pickup(pid: String, pos: Vector3, loc_label: String) -> void:
	var vis := spawn_glb("battery_pack", pos, Vector3(0, 25, 0))
	var area := add_interactable(pid, "battery_pickup", "[E] Pick up 4.5V Battery Pack (%s)" % loc_label, pos + Vector3(0, 0.25, 0), Vector3(1.1, 1.1, 1.1))
	if vis:
		area.set_meta("visual_node", vis)
