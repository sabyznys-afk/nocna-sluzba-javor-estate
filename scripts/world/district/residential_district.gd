class_name ResidentialDistrictController
extends Node3D

const AnimationHubScript = preload("res://scripts/systems/animation_hub.gd")
const RetroMaterialsLib = preload("res://scripts/systems/retro_materials.gd")
const DoorManagerScript = preload("res://scripts/systems/door_manager.gd")
const FogControllerScript = preload("res://scripts/systems/fog_controller.gd")

const MODULE_SCENES := [
	["OuterEnvironment", "res://scenes/district/OuterEnvironment.tscn"],
	["CentralPark", "res://scenes/district/CentralPark.tscn"],
	["ParkingArea", "res://scenes/district/ParkingArea.tscn"],
	["CommercialArea", "res://scenes/district/CommercialArea.tscn"],
	["GarageComplex", "res://scenes/district/GarageComplex.tscn"],
	["SecurityOffice", "res://scenes/district/SecurityOffice.tscn"],
	["TechnicalArea", "res://scenes/district/TechnicalArea.tscn"],
	["ApartmentBuildings", "res://scenes/district/ApartmentBuildings.tscn"],
]

var interactables: Array[Area3D] = []
var dynamic_nodes: Dictionary = {}
var anomaly_visual_nodes: Dictionary = {}
var event_locations: Dictionary = {}
var animation_hub: Node
var door_manager: Node
var fog_controller: Node

var cctv_viewport: SubViewport
var cctv_cameras: Array[Camera3D] = []
var cctv_labels: Array[String] = [
	"CAM-01 MAIN ENTRANCE & BUS STOP",
	"CAM-02 PARKING LOT",
	"CAM-03 CENTRAL PARK & PLAYGROUND",
	"CAM-04 COMMERCIAL PROMENADE",
	"CAM-05 GARAGE COMPLEX ENTRANCE",
	"CAM-06 NORTHERN PATH & BUILDING B",
]
var active_cam_idx: int = 0

var rain_particles: CPUParticles3D
var upward_snow_nodes: Array[MeshInstance3D] = []
var _security_office_mod: Node
var _technical_area_mod: Node
var _anim_time: float = 0.0
var _is_showcase: bool = false


func build_district(is_showcase: bool = false) -> void:
	_is_showcase = is_showcase
	animation_hub = AnimationHubScript.new()
	animation_hub.name = "AnimationHub"
	add_child(animation_hub)

	door_manager = DoorManagerScript.new()
	door_manager.name = "DoorManager"
	add_child(door_manager)

	_setup_environment()

	for pair: Array in MODULE_SCENES:
		var m_name: String = str(pair[0])
		var m_path: String = str(pair[1])
		if not ResourceLoader.exists(m_path):
			continue
		var packed: Resource = load(m_path)
		if not (packed is PackedScene):
			continue
		var inst: Node = (packed as PackedScene).instantiate()
		inst.name = m_name
		add_child(inst)
		if inst.has_method("set_district_root"):
			inst.set_district_root(self)
		if inst.has_method("build_module"):
			inst.build_module(is_showcase)
		if m_name == "SecurityOffice":
			_security_office_mod = inst
		elif m_name == "TechnicalArea":
			_technical_area_mod = inst

	if not _is_showcase:
		_build_cctv_system()
	_build_rain_and_atmosphere()
	var env_node: WorldEnvironment = get_node_or_null("WorldEnvironment")
	fog_controller = FogControllerScript.new()
	add_child(fog_controller)
	fog_controller.setup_fog(env_node)
	refresh_night_state()


func on_child_interactable(area: Area3D) -> void:
	interactables.append(area)


func on_child_door(door: Node) -> void:
	if door_manager and door_manager.has_method("register_door"):
		door_manager.register_door(door)


func on_child_dynamic(key: String, node: Node3D) -> void:
	dynamic_nodes[key] = node


func on_child_anomaly_visual(aid: String, node: Node3D) -> void:
	anomaly_visual_nodes[aid] = node


func on_child_anim(anim_name: String, node: Node3D, meta: Dictionary) -> void:
	if animation_hub:
		animation_hub.register_target(anim_name, node, meta)


func on_child_event_hook(hook_id: String, payload: Dictionary) -> void:
	event_locations[hook_id] = payload


func get_player_spawn_position() -> Vector3:
	return Vector3(-15.8, 0.20, -54.5)


func set_rain_follow_position(pos: Vector3) -> void:
	if rain_particles:
		rain_particles.position = Vector3(pos.x, pos.y + 11.5, pos.z)


func get_zone_for_position(pos: Vector3) -> Dictionary:
	if pos.y < -1.8 and pos.x < -58.0:
		return {"id": "technical_area", "label": "ZONE 7: SUBTERRANEAN BOILER & BUNKER K-4"}
	if pos.x >= -23.0 and pos.x <= -13.0 and pos.z >= -60.5 and pos.z <= -51.5:
		return {"id": "security_office", "label": "ZONE 1: SECURITY OFFICE (VRÁTNICA)"}
	if pos.x >= 4.0 and pos.x <= 46.0 and pos.z >= -65.0 and pos.z <= -41.0:
		return {"id": "parking_lot", "label": "ZONE 2: SOUTH PARKING LOT"}
	if pos.x <= -54.0 and pos.z <= -43.0:
		return {"id": "garages", "label": "ZONE 5: CONCRETE GARAGE COMPLEX"}
	if pos.x <= -54.0 and pos.z > -43.0 and pos.z < -6.0:
		return {"id": "technical_area", "label": "ZONE 7: SUBSTATION & BOILER PLANT"}
	if pos.x >= 34.0 and pos.x <= 66.0 and pos.z >= -28.0 and pos.z <= 24.0:
		return {"id": "commercial_area", "label": "ZONE 4: COMMERCIAL SQUARE & DELIVERY ALLEY"}
	if absf(pos.x) <= 28.0 and pos.z >= -20.0 and pos.z <= 24.0:
		return {"id": "central_park", "label": "ZONE 3: CENTRAL PARK & PLAYGROUND"}
	if pos.z >= 50.0:
		return {"id": "northern_forest", "label": "ZONE 8: NORTHERN PATH & PERIMETER FOREST"}
	return {"id": "apartments", "label": "ZONE 6: RESIDENTIAL PANELÁK BLOCKS (A–F)"}


func get_surface_for_position(pos: Vector3) -> String:
	if pos.y < -1.8:
		return "metal" if pos.x > -76.0 else "cobble"
	if pos.y >= 3.0 and pos.y < 20.0:
		return "wood"
	if pos.y >= 24.0:
		return "concrete"
	# Security Office & Commercial interiors -> indoor wood/linoleum
	if pos.x >= -22.5 and pos.x <= -13.5 and pos.z >= -60.0 and pos.z <= -52.0:
		return "wood"
	if pos.x >= 42.0 and pos.x <= 56.0 and pos.z >= -25.0 and pos.z <= 22.0:
		return "wood"
	# Asphalt parking & roads
	if pos.x >= 4.0 and pos.x <= 46.0 and pos.z >= -65.0 and pos.z <= -41.0:
		return "asphalt"
	if absf(pos.x + 54.0) < 3.0 or absf(pos.x - 62.0) < 3.0 or pos.z <= -67.0:
		return "asphalt"
	if pos.x <= -54.0 and pos.z <= -43.0:
		return "asphalt"
	# Wet gravel trails (Park rim, alley shortcuts, Block E rear)
	if (pos.x >= -33.5 and pos.x <= -26.5 and absf(pos.z) <= 26.0) or (pos.x >= 80.0 and absf(pos.z + 14.0) <= 22.0):
		return "gravel"
	if (pos.x >= 13.0 and pos.x <= 27.0 and pos.z >= 29.0 and pos.z <= 47.0) or (pos.x >= -22.0 and pos.x <= -10.0 and pos.z >= 32.0 and pos.z <= 48.0):
		return "gravel"
	# Cobble plaza & main sidewalks
	if absf(pos.x) <= 24.0 and absf(pos.z) <= 22.0:
		return "cobble"
	if absf(pos.x) <= 3.0 or (pos.x >= 33.0 and pos.x <= 42.0) or (pos.z >= 23.0 and pos.z <= 33.0) or (pos.z >= 51.0 and pos.z <= 57.0):
		return "concrete"
	# Forest mud outskirts vs courtyard grass
	if pos.z >= 62.0 or pos.x <= -98.0 or pos.x >= 88.0:
		return "mud"
	return "grass"


func _process(delta: float) -> void:
	_anim_time += delta
	if _security_office_mod and _security_office_mod.get("booth_phone_beacon") != null:
		var beacon: MeshInstance3D = _security_office_mod.get("booth_phone_beacon") as MeshInstance3D
		if beacon:
			var ring_needed: bool = not GameState.is_quest_done("answer_briefing")
			beacon.visible = ring_needed and (fmod(_anim_time, 0.9) < 0.45)

	if not upward_snow_nodes.is_empty():
		var show_snow: bool = AnomalyDirector.is_active("ANOM_21") or GameState.current_night >= 5
		for flake: MeshInstance3D in upward_snow_nodes:
			flake.visible = show_snow
			if show_snow:
				flake.position.y += delta * 1.15
				if flake.position.y > 12.0:
					flake.position.y = 0.2


func refresh_night_state() -> void:
	var n: int = GameState.current_night
	_set_vis("anom_13th_window", AnomalyDirector.is_active("ANOM_01") or n == 1)
	_set_vis("anom_well_hands", AnomalyDirector.is_active("ANOM_07") or AnomalyDirector.is_active("ANOM_10") or n == 1)
	_set_vis("anom_black_ooze", AnomalyDirector.is_active("ANOM_05") or AnomalyDirector.is_active("ANOM_25") or n == 1)
	_set_vis("anom_floating_chairs", AnomalyDirector.is_active("ANOM_06") or AnomalyDirector.is_active("ANOM_23") or n == 1)
	_set_vis("anom_hanging_sheet_1", AnomalyDirector.is_active("ANOM_02") or AnomalyDirector.is_active("ANOM_04") or n >= 2)
	_set_vis("anom_booth_doppel", AnomalyDirector.is_active("ANOM_08"))
	_set_vis("anom_shadow_stalker", AnomalyDirector.is_active("ANOM_27") or AnomalyDirector.is_active("ANOM_12") or n >= 2)
	_set_vis("park_bench_phantom", AnomalyDirector.is_active("ANOM_26") or n >= 2)
	_set_vis("anom_jozef_echo", AnomalyDirector.is_active("ANOM_29") or n >= 2)
	_set_vis("flat7_tv_glow", n >= 3 or AnomalyDirector.is_active("ANOM_16"))
	_set_vis("mobsters_group", (n == 4 or n == 5) and not bool(GameState.story_flags.get("lured_anomalies_on_mobsters", false)))
	# Residents present Nights 1–5; vanish on Night 6 (The Last Patrol)
	_set_vis("npc_anna_visual", n <= 5)
	_set_vis("npc_dana_visual", n <= 5)
	_set_vis("npc_peter_visual", n <= 5)
	_set_vis("npc_zuzana_visual", n <= 5)
	# Unlisted Door 47 manifests on Night 4 (The Wrong Floor) & Night 6 (The Last Patrol)
	_set_vis("story_door_47", n == 4 or n == 6)

	if rain_particles:
		rain_particles.emitting = (n <= 4)

	set_red_door_open(bool(GameState.story_flags.get("red_door_opened", false)))

	var env_node: WorldEnvironment = get_node_or_null("WorldEnvironment")
	if env_node and env_node.environment:
		var sett := get_node_or_null("/root/SettingsManager")
		env_node.environment.fog_enabled = bool(sett.get_val("fog_enabled", true)) if sett else true
		env_node.environment.fog_mode = Environment.FOG_MODE_DEPTH
		env_node.environment.fog_depth_begin = 2.8
		env_node.environment.fog_depth_end = 10.0
		env_node.environment.fog_depth_curve = 1.05
		env_node.environment.fog_density = 0.72
		env_node.environment.fog_light_color = Color(0.070, 0.088, 0.102) if n == 6 else Color(0.088, 0.114, 0.138)
		if sett:
			env_node.environment.adjustment_enabled = true
			env_node.environment.adjustment_brightness = float(sett.get_val("brightness", 1.08))
			env_node.environment.adjustment_contrast = float(sett.get_val("contrast", 1.0))
	if fog_controller and fog_controller.has_method("apply_zone_atmosphere"):
		fog_controller.apply_zone_atmosphere(fog_controller.current_zone_id, n)


func set_estate_blackout(active: bool) -> void:
	# Prompt 06/07 Night 6 (03:17): Complete estate power loss — exterior sodium spots & interior lamps drop!
	var queue: Array[Node] = [self]
	while not queue.is_empty():
		var cur: Node = queue.pop_back()
		if (cur is OmniLight3D or cur is SpotLight3D) and not cur.name.begins_with("EmergencyDawnLight"):
			var l := cur as Light3D
			if active:
				if not l.has_meta("orig_energy"):
					l.set_meta("orig_energy", l.light_energy)
				l.light_energy = 0.06 if l.name == "CRTScreenGlow" else 0.0
			elif l.has_meta("orig_energy"):
				l.light_energy = float(l.get_meta("orig_energy"))
		for ch in cur.get_children():
			queue.append(ch)
	var env_node: WorldEnvironment = get_node_or_null("WorldEnvironment")
	if env_node and env_node.environment:
		if active:
			env_node.environment.ambient_light_energy = 0.12
			env_node.environment.fog_depth_end = 8.0
		else:
			env_node.environment.ambient_light_energy = 0.46
			env_node.environment.fog_depth_end = 10.0


func _set_vis(key: String, vis: bool) -> void:
	if dynamic_nodes.has(key) and dynamic_nodes[key] is Node3D:
		(dynamic_nodes[key] as Node3D).visible = vis


func set_red_door_open(is_open: bool) -> void:
	if _technical_area_mod and _technical_area_mod.has_method("set_red_door_open"):
		_technical_area_mod.set_red_door_open(is_open)


func cycle_cctv_camera() -> String:
	if cctv_cameras.is_empty():
		return "NO SIGNAL"
	active_cam_idx = (active_cam_idx + 1) % cctv_cameras.size()
	return set_cctv_camera(active_cam_idx)


func set_cctv_camera(idx: int) -> String:
	if cctv_cameras.is_empty():
		return "NO SIGNAL"
	active_cam_idx = clampi(idx, 0, cctv_cameras.size() - 1)
	for i: int in range(cctv_cameras.size()):
		cctv_cameras[i].current = (i == active_cam_idx)
	return cctv_labels[active_cam_idx]


func get_cctv_texture() -> Texture2D:
	if cctv_viewport:
		return cctv_viewport.get_texture()
	return null


func get_active_cctv_label() -> String:
	if active_cam_idx >= 0 and active_cam_idx < cctv_labels.size():
		return cctv_labels[active_cam_idx]
	return "CAM-01"


func find_anomaly_in_beam(origin: Vector3, dir: Vector3, max_dist: float = 7.0) -> Dictionary:
	var best_dist: float = max_dist
	var best_res: Dictionary = {}
	var norm_dir := dir.normalized()
	for aid: String in anomaly_visual_nodes.keys():
		var nd: Node3D = anomaly_visual_nodes[aid] as Node3D
		if nd == null or not is_instance_valid(nd) or not nd.visible:
			continue
		var to_nd: Vector3 = nd.global_position - origin
		var d: float = to_nd.length()
		if d > max_dist or d < 0.35:
			continue
		if norm_dir.dot(to_nd.normalized()) >= 0.70 and d < best_dist:
			best_dist = d
			best_res = {"anomaly_id": aid, "node": nd, "distance": d}
	return best_res


func _setup_environment() -> void:
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.032, 0.044, 0.058)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.28, 0.35)
	env.ambient_light_energy = 0.46
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 2.8
	env.fog_depth_end = 10.0
	env.fog_depth_curve = 1.05
	env.fog_density = 0.72
	env.fog_light_color = Color(0.088, 0.114, 0.138)
	env.fog_light_energy = 1.08
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.name = "ColdMoonRim"
	moon.light_color = Color(0.48, 0.60, 0.76)
	moon.light_energy = 0.36
	moon.rotation_degrees = Vector3(-48.0, 26.0, 0.0)
	moon.shadow_enabled = false
	add_child(moon)


func _build_cctv_system() -> void:
	cctv_viewport = SubViewport.new()
	cctv_viewport.name = "CCTVViewport"
	cctv_viewport.size = Vector2i(320, 240)
	cctv_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED if DisplayServer.get_name() == "headless" else SubViewport.UPDATE_ALWAYS
	add_child(cctv_viewport)

	var cam_configs: Array[Dictionary] = [
		{"pos": Vector3(-10.0, 4.6, -53.0), "look": Vector3(-6.0, 1.2, -74.0)},
		{"pos": Vector3(3.0, 6.8, -42.0), "look": Vector3(25.0, 1.0, -56.0)},
		{"pos": Vector3(-4.0, 7.2, -18.0), "look": Vector3(0.0, 1.0, 8.0)},
		{"pos": Vector3(36.0, 6.2, -24.0), "look": Vector3(49.0, 1.8, 10.0)},
		{"pos": Vector3(-53.0, 5.6, -42.0), "look": Vector3(-74.0, 1.4, -55.0)},
		{"pos": Vector3(-24.0, 6.8, 52.0), "look": Vector3(2.0, 3.5, 42.0)},
	]
	var iron := RetroMaterialsLib.get_material("iron")
	for idx: int in range(cam_configs.size()):
		var cfg: Dictionary = cam_configs[idx]
		var cam := Camera3D.new()
		cam.name = "CCTV_Cam_%d" % (idx + 1)
		cam.position = cfg["pos"]
		cam.fov = 68.0
		cam.far = 160.0
		cctv_viewport.add_child(cam)
		cam.look_at(cfg["look"], Vector3.UP)
		cctv_cameras.append(cam)

		var housing := MeshInstance3D.new()
		housing.name = "CCTVCamHousing_%d" % (idx + 1)
		housing.position = cfg["pos"]
		var box := BoxMesh.new()
		box.size = Vector3(0.24, 0.18, 0.36)
		box.material = iron
		housing.mesh = box
		add_child(housing)
		animation_hub.register_target("cctv_camera_pan", housing, {"seed": float(idx) * 1.3})

	set_cctv_camera(0)
	if _security_office_mod and _security_office_mod.get("cctv_screen_mat") != null and DisplayServer.get_name() != "headless":
		var smat: StandardMaterial3D = _security_office_mod.get("cctv_screen_mat") as StandardMaterial3D
		if smat:
			smat.albedo_texture = cctv_viewport.get_texture()


func _build_rain_and_atmosphere() -> void:
	rain_particles = CPUParticles3D.new()
	rain_particles.name = "CourtyardRain"
	rain_particles.position = Vector3(-15.8, 12.0, -54.5) if not _is_showcase else Vector3(0.0, 12.0, 0.0)
	rain_particles.amount = 520
	rain_particles.lifetime = 1.05
	rain_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain_particles.emission_box_extents = Vector3(24.0, 0.5, 24.0)
	rain_particles.direction = Vector3(0.06, -1.0, 0.04)
	rain_particles.spread = 4.0
	rain_particles.initial_velocity_min = 10.5
	rain_particles.initial_velocity_max = 13.5
	rain_particles.gravity = Vector3(0.0, -6.0, 0.0)
	var drop_mesh := BoxMesh.new()
	drop_mesh.size = Vector3(0.015, 0.46, 0.015)
	var drop_mat := StandardMaterial3D.new()
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.albedo_color = Color(0.58, 0.68, 0.78, 0.32)
	drop_mesh.material = drop_mat
	rain_particles.mesh = drop_mesh
	add_child(rain_particles)
	animation_hub.register_target("rain_curtain_drift", rain_particles, {"seed": 0.0})
