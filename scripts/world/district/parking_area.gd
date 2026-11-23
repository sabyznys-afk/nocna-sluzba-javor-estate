class_name ParkingAreaBuilder
extends DistrictBuilderBase


func build_module(is_showcase: bool = false) -> void:
	if is_showcase:
		return
	var asphalt: StandardMaterial3D = RetroMaterialsLib.get_material("asphalt_wet")
	var concrete: StandardMaterial3D = RetroMaterialsLib.get_material("concrete")
	var curb_mat: StandardMaterial3D = RetroMaterialsLib.get_material("concrete_curb")
	var mud_mat: StandardMaterial3D = RetroMaterialsLib.get_material("mud_leaves")
	var white_paint := StandardMaterial3D.new()
	white_paint.albedo_color = Color(0.64, 0.64, 0.58)
	white_paint.roughness = 0.85

	# Tightened Parking Lot Apron (X: +4..+46, Z: -65..-41 -> 20 bays in 2 rows, center +25, -53)
	add_solid_box("ParkingLot_Asphalt", Vector3(25.0, -0.22, -53.0), Vector3(42.0, 0.4, 24.0), asphalt)
	var puddle_mat := StandardMaterial3D.new()
	puddle_mat.albedo_color = Color(0.05, 0.07, 0.09, 0.78)
	puddle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puddle_mat.roughness = 0.08
	puddle_mat.metallic = 0.25
	add_mesh_box("ParkingPuddle_1", Vector3(18.0, 0.004, -53.0), Vector3(4.8, 0.008, 3.0), puddle_mat)
	add_mesh_box("ParkingPuddle_2", Vector3(33.0, 0.004, -52.5), Vector3(4.0, 0.008, 2.4), puddle_mat)
	add_mesh_box("ParkingPuddle_3", Vector3(11.5, 0.004, -53.8), Vector3(3.2, 0.008, 2.2), puddle_mat)
	spawn_glb("manhole_drain", Vector3(25.0, 0.01, -53.0), Vector3.ZERO)
	add_mesh_box("OilStain_Bay1", Vector3(19.6, 0.003, -60.2), Vector3(1.1, 0.006, 1.4), mud_mat)
	add_mesh_box("OilStain_Bay2", Vector3(30.4, 0.003, -45.6), Vector3(1.0, 0.006, 1.2), mud_mat)

	# 20 Painted Parking Bay dividers & concrete wheel curbs
	for i: int in range(11):
		var bx: float = 7.0 + i * 3.6
		add_mesh_box("ParkLine_S_%d" % i, Vector3(bx, 0.005, -60.5), Vector3(0.14, 0.01, 4.8), white_paint)
		add_mesh_box("ParkLine_N_%d" % i, Vector3(bx, 0.005, -45.5), Vector3(0.14, 0.01, 4.8), white_paint)
	for i: int in range(10):
		var cx: float = 8.8 + i * 3.6
		add_solid_box("CurbStop_S_%d" % i, Vector3(cx, 0.08, -62.9), Vector3(2.2, 0.16, 0.24), curb_mat)
		add_solid_box("CurbStop_N_%d" % i, Vector3(cx, 0.08, -43.1), Vector3(2.2, 0.16, 0.24), curb_mat)

	# Perimeter parking concrete barriers
	add_solid_box("ParkingBarrier_E", Vector3(45.6, 0.28, -53.0), Vector3(0.35, 0.56, 22.0), concrete)

	add_streetlamp(Vector3(3.5, 0.0, -56.5), 90.0, "normal", 0.1)
	add_streetlamp(Vector3(14.5, 0.0, -49.4), 180.0, "normal", 0.4)
	add_streetlamp(Vector3(28.0, 0.0, -49.4), 180.0, "flicker", 2.2)
	add_streetlamp(Vector3(43.5, 0.0, -53.0), -90.0, "dim", 0.9)

	# Hero Vehicle: Abandoned Skoda Favorit with flashing headlights anomaly (ANOM_11)
	var skoda := spawn_glb("skoda_favorit", Vector3(12.4, 0.0, -60.2), Vector3(0.0, 174.0, 0.0))
	if skoda:
		for htag: String in ["SkodaHeadlightL", "SkodaHeadlightR"]:
			var spot := SpotLight3D.new()
			spot.name = htag
			spot.light_color = Color(1.0, 0.88, 0.56)
			spot.light_energy = 0.0
			spot.spot_range = 16.0
			spot.spot_angle = 28.0
			spot.position = Vector3(-0.55 if htag.ends_with("L") else 0.55, 0.68, -1.9)
			skoda.add_child(spot)
			register_anim("anom_skoda_headlights_flash", spot, {"anomaly_id": "ANOM_11", "seed": 0.5})
			# Volumetric headlight fog cone cutting through dense parking lot mist
			var hcone := MeshInstance3D.new()
			var hc := CylinderMesh.new()
			hc.top_radius = 0.08
			hc.bottom_radius = 1.05
			hc.height = 6.2
			hc.cap_top = false
			hc.cap_bottom = false
			var hcm := StandardMaterial3D.new()
			hcm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			hcm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			hcm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			hcm.cull_mode = BaseMaterial3D.CULL_DISABLED
			hcm.disable_fog = true
			hcm.albedo_color = Color(1.0, 0.90, 0.62, 0.045)
			hc.material = hcm
			hcone.mesh = hc
			hcone.position = Vector3(-0.55 if htag.ends_with("L") else 0.55, 0.65, -5.0)
			hcone.rotation_degrees = Vector3(90, 0, 0)
			hcone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			skoda.add_child(hcone)
			register_anim("van_hazard_blink", hcone, {"seed": 0.5})
		register_anomaly_visual("ANOM_11", skoda)
	add_invisible_collider("SkodaFavorit_Col", Vector3(12.4, 0.72, -60.2), Vector3(1.8, 1.44, 3.7), Vector3(0, 174, 0))
	add_interactable("skoda_car", "clue", "[E] Inspect Abandoned Škoda Favorit", Vector3(11.0, 0.9, -60.2), Vector3(1.5, 1.4, 3.2), "ANOM_11")

	var cars: Array[Dictionary] = [
		{"m": "skoda_120", "p": Vector3(8.8, 0, -60.5), "r": 182},
		{"m": "lada_sedan", "p": Vector3(19.6, 0, -60.3), "r": 179},
		{"m": "trabant_601", "p": Vector3(26.8, 0, -60.3), "r": 184},
		{"m": "skoda_120", "p": Vector3(34.0, 0, -60.5), "r": 175},
		{"m": "lada_van", "p": Vector3(41.2, 0, -59.8), "r": 180, "hazard": true},
		{"m": "lada_sedan", "p": Vector3(8.8, 0, -45.6), "r": 2},
		{"m": "trabant_601", "p": Vector3(16.0, 0, -45.6), "r": -4},
		{"m": "skoda_120", "p": Vector3(23.2, 0, -45.8), "r": 5},
		{"m": "lada_sedan", "p": Vector3(30.4, 0, -45.6), "r": 0},
		{"m": "skoda_120", "p": Vector3(37.6, 0, -45.8), "r": -8},
		{"m": "lada_sedan", "p": Vector3(41.2, 0, -45.8), "r": 3},
	]
	for idx: int in range(cars.size()):
		var cfg: Dictionary = cars[idx]
		var mp: String = str(cfg["m"])
		var pos: Vector3 = cfg["p"]
		var rot_y: float = float(cfg["r"])
		var car_node := spawn_glb(mp, pos, Vector3(0, rot_y, 0))
		add_invisible_collider("ParkCar_Col_%d" % idx, pos + Vector3(0, 0.78, 0), Vector3(1.85, 1.56, 4.1), Vector3(0, rot_y, 0))
		if car_node and bool(cfg.get("hazard", false)):
			var haz := OmniLight3D.new()
			haz.light_color = Color(1.0, 0.56, 0.08)
			haz.light_energy = 1.6
			haz.omni_range = 7.5
			haz.distance_fade_enabled = true
			haz.position = Vector3(0, 1.35, -2.1)
			car_node.add_child(haz)
			register_anim("van_hazard_blink", haz, {"energy": 1.6, "seed": 0.4})

	add_interactable("evidence_plate", "evidence", "[E] Photograph Smuggled White Van Plate (BA-419-HV)", Vector3(41.2, 1.0, -57.2), Vector3(2.0, 1.4, 1.8), "", {"evidence_id": "evidence_plate"})
	add_interactable("clue_1", "clue", "[E] Examine Smuggled Cargo Boxes behind Van", Vector3(39.8, 1.0, -58.0), Vector3(1.4, 1.2, 1.4), "", {"evidence_id": "evidence_plate"})

	# Prompt 06 Night 1 CP2 Optional Grounded Discovery: Slightly open car door with ordinary shopping bag
	var bag_mat := StandardMaterial3D.new()
	bag_mat.albedo_color = Color(0.56, 0.44, 0.28)
	bag_mat.roughness = 0.88
	add_mesh_box("OpenCarDoorLeaf", Vector3(18.55, 0.68, -59.8), Vector3(0.08, 0.72, 0.88), RetroMaterialsLib.get_material("shutter"), Vector3(0, 28, 0))
	add_mesh_box("OpenCarShoppingBag", Vector3(19.25, 0.56, -59.9), Vector3(0.24, 0.30, 0.22), bag_mat)
	add_interactable("n1_open_car", "campaign_event", "[E] INSPECT SLIGHTLY OPEN CAR DOOR (BAY 04)", Vector3(18.4, 0.95, -59.6), Vector3(1.8, 1.5, 1.8), "", {"event_id": "n1_open_car"})
