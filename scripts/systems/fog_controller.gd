class_name FogController
extends Node3D

# Prompt 08 Part 1.2 — Balanced Atmospheric Fog Decoupled from Pitch-Black Darkness:
# - Retains ~8-10m useful outdoor visual recognition so buildings, paths, doors, cars & people stay readable!
# - Respects user Fog Intensity & Atmospheric Fog toggle from SettingsManager

var world_env: WorldEnvironment
var ground_fog_layers: Array[MeshInstance3D] = []
var mid_fog_layers: Array[MeshInstance3D] = []
var current_zone_id: String = "security_office"
var is_player_indoors: bool = true

var current_fog_end: float = 16.0
var target_fog_end: float = 16.0
var current_fog_begin: float = 4.2
var target_fog_begin: float = 4.2
var current_density: float = 0.28
var target_density: float = 0.28
var weather_phase: float = 0.0
var weather_state: String = "NOVEMBER_NIGHT_MIST"

# Outdoor visual recognition ~8.8-10.0m, lighter opacity so routes & silhouettes remain distinct!
const ZONE_FOG_PROFILES := {
	"security_office": {"begin": 4.8, "end": 18.0, "density": 0.24, "indoor": true},
	"parking_lot": {"begin": 2.8, "end": 10.0, "density": 0.72, "indoor": false},
	"central_park": {"begin": 2.4, "end": 8.8, "density": 0.76, "indoor": false},
	"commercial_area": {"begin": 2.9, "end": 10.0, "density": 0.70, "indoor": false},
	"garages": {"begin": 2.5, "end": 9.4, "density": 0.75, "indoor": false},
	"technical_area": {"begin": 2.6, "end": 9.6, "density": 0.72, "indoor": false},
	"apartments": {"begin": 2.8, "end": 10.0, "density": 0.72, "indoor": false},
	"northern_forest": {"begin": 2.2, "end": 8.6, "density": 0.79, "indoor": false},
}


func _sett() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("SettingsManager") if ml is SceneTree else null


func setup_fog(env_node: WorldEnvironment) -> void:
	name = "FogController"
	world_env = env_node
	_configure_depth_fog()
	_build_layered_fog_volumes()
	apply_zone_atmosphere("security_office", 1)


func _configure_depth_fog() -> void:
	if not world_env or not world_env.environment:
		return
	var env := world_env.environment
	var sett := _sett()
	env.fog_enabled = bool(sett.get_val("fog_enabled", true)) if sett else true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 2.8
	env.fog_depth_end = 10.0
	env.fog_depth_curve = 1.05
	env.fog_density = 0.72
	env.fog_light_color = Color(0.088, 0.114, 0.138) # Cold moonlit blue-grey mist (NOT pitch black!)
	env.fog_light_energy = 1.08
	env.fog_aerial_perspective = 0.0


func get_ground_fog_count() -> int:
	return ground_fog_layers.size()


func get_mid_fog_count() -> int:
	return mid_fog_layers.size()


func get_outdoor_visibility_meters(zone_id: String = "central_park") -> float:
	var prof: Dictionary = ZONE_FOG_PROFILES.get(zone_id, {"end": 9.8})
	return float(prof.get("end", 9.8))


func _build_layered_fog_volumes() -> void:
	ground_fog_layers.clear()
	mid_fog_layers.clear()

	# LAYER 1: Subtle low-lying Ground Mist above grass, wet asphalt & park (soft opacity so ground stays readable)
	var ground_specs := [
		["GroundFog_CentralPark_Low", Vector3(0.0, 0.28, 2.0), Vector2(58.0, 48.0), 0.068],
		["GroundFog_CentralPark_Mid", Vector3(2.0, 0.72, 4.0), Vector2(52.0, 42.0), 0.052],
		["GroundFog_SouthParking", Vector3(24.0, 0.24, -53.0), Vector2(46.0, 28.0), 0.055],
		["GroundFog_NorthForest", Vector3(-6.0, 0.36, 56.0), Vector2(150.0, 28.0), 0.082],
		["GroundFog_GaragesAlley", Vector3(-72.0, 0.25, -48.0), Vector2(42.0, 26.0), 0.062],
		["GroundFog_DeliveryAlley", Vector3(58.0, 0.26, -6.0), Vector2(24.0, 46.0), 0.055],
		["GroundFog_BlockBCourtyard", Vector3(2.0, 0.30, 32.0), Vector2(68.0, 22.0), 0.055],
		["GroundFog_BlockFBasement", Vector3(-64.0, 0.24, 16.0), Vector2(22.0, 26.0), 0.062],
	]
	for spec: Array in ground_specs:
		var m := _create_fog_slab(str(spec[0]), spec[1], spec[2], 0.36, Color(0.18, 0.24, 0.28, float(spec[3])))
		ground_fog_layers.append(m)

	# LAYER 2: Gentle Mid-Height Night Mist (adds depth without blinding pathways)
	var mid_specs := [
		["MidFog_CentralPark_N", Vector3(-6.0, 1.55, 11.0), Vector2(36.0, 24.0), 0.044],
		["MidFog_CentralPark_S", Vector3(8.0, 1.65, -8.0), Vector2(34.0, 22.0), 0.040],
		["MidFog_ParkingCars", Vector3(25.0, 1.35, -53.0), Vector2(40.0, 22.0), 0.038],
		["MidFog_GaragesApron", Vector3(-74.0, 1.45, -50.0), Vector2(36.0, 18.0), 0.045],
		["MidFog_NorthForestEdge", Vector3(0.0, 1.75, 55.0), Vector2(120.0, 20.0), 0.056],
		["MidFog_CourtyardWalk", Vector3(-24.0, 1.50, 18.0), Vector2(34.0, 26.0), 0.038],
	]
	for mspec: Array in mid_specs:
		var mm := _create_fog_slab(str(mspec[0]), mspec[1], mspec[2], 0.80, Color(0.15, 0.20, 0.24, float(mspec[3])))
		mid_fog_layers.append(mm)


func _create_fog_slab(node_name: String, pos: Vector3, sz: Vector2, thickness: float, col: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = node_name
	m.position = pos
	var q := BoxMesh.new()
	q.size = Vector3(sz.x, thickness, sz.y)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = col
	q.material = mat
	m.mesh = q
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	return m


func _is_position_in_small_interior(pos: Vector3) -> bool:
	if pos.y < -1.5:
		return false
	if pos.x >= -22.6 and pos.x <= -13.4 and pos.z >= -60.1 and pos.z <= -51.9:
		return true
	if pos.x >= 36.2 and pos.x <= 40.4 and pos.z >= -13.1 and pos.z <= -6.9:
		return true
	if pos.x >= 42.0 and pos.x <= 56.0 and pos.z >= -25.0 and pos.z <= 22.0:
		return true
	if pos.x >= -79.0 and pos.x <= -60.0 and pos.z >= -40.0 and pos.z <= -9.0:
		return true
	return false


func _is_position_in_apartment_stairwell(pos: Vector3) -> bool:
	if pos.y >= 2.8 and pos.y < 22.0:
		return true
	if pos.z >= 32.0 and pos.z <= 48.0 and pos.x >= -46.0 and pos.x <= 52.0:
		return true
	if pos.z >= -36.0 and pos.z <= -24.0 and pos.x >= -10.0 and pos.x <= 18.0:
		return true
	return false


func apply_zone_atmosphere(zone_id: String, night_num: int = 1) -> void:
	current_zone_id = zone_id
	var prof: Dictionary = ZONE_FOG_PROFILES.get(zone_id, {"begin": 2.8, "end": 10.0, "density": 0.72, "indoor": false})
	var night_tighten: float = clampf(float(night_num - 1) * 0.18, 0.0, 0.75)
	target_fog_begin = float(prof["begin"])
	target_fog_end = clampf(float(prof["end"]) - (0.0 if bool(prof["indoor"]) else night_tighten), 8.2, 18.0)
	target_density = float(prof["density"])


func update_fog(delta: float, player_pos: Vector3, night_num: int = 1) -> void:
	weather_phase += delta
	var cyc: float = fmod(weather_phase, 180.0)
	if cyc < 65.0:
		weather_state = "NOVEMBER_NIGHT_MIST"
	elif cyc < 125.0:
		weather_state = "COLD_RAIN_MIST"
	else:
		weather_state = "HEAVY_STILL_FOG"

	var sett := _sett()
	var fog_on: bool = bool(sett.get_val("fog_enabled", true)) if sett else true
	var fog_int: float = clampf(float(sett.get_val("fog_intensity", 1.0)) if sett else 1.0, 0.35, 1.45)

	var in_small_room: bool = _is_position_in_small_interior(player_pos)
	var in_stairwell: bool = _is_position_in_apartment_stairwell(player_pos)
	var in_basement: bool = (player_pos.y < -1.5)
	is_player_indoors = in_small_room or in_stairwell

	var desired_begin: float = target_fog_begin
	var desired_end: float = target_fog_end
	var desired_density: float = target_density
	var desired_col: Color = Color(0.088, 0.114, 0.138) # Readable moonlit night mist outdoors

	if in_small_room:
		desired_begin = 5.0
		desired_end = 18.0
		desired_density = 0.22 * fog_int
		desired_col = Color(0.11, 0.10, 0.085)
	elif in_basement:
		desired_begin = 2.6
		desired_end = 11.5
		desired_density = 0.62 * fog_int
		desired_col = Color(0.068, 0.084, 0.095)
	elif in_stairwell:
		desired_begin = 3.6
		desired_end = 13.5
		desired_density = 0.48 * fog_int
		desired_col = Color(0.098, 0.094, 0.084)
	else:
		# Readable 8-10m outdoor fog (scaled smoothly by Fog Intensity slider)
		var weather_shrink: float = 0.45 if weather_state == "HEAVY_STILL_FOG" else 0.0
		var inv_scale: float = clampf(1.0 / maxf(0.55, fog_int), 0.72, 1.55)
		desired_end = clampf((target_fog_end - weather_shrink) * inv_scale, 7.6, 15.5)
		desired_begin = clampf(target_fog_begin * inv_scale, 1.8, 5.5)
		desired_density = clampf(target_density * fog_int, 0.30, 0.86)
		if night_num == 6:
			desired_col = Color(0.070, 0.088, 0.102)

	var blend_speed: float = clampf(delta * 3.0, 0.0, 1.0)
	current_fog_begin = lerpf(current_fog_begin, desired_begin, blend_speed)
	current_fog_end = lerpf(current_fog_end, desired_end, blend_speed)
	current_density = lerpf(current_density, desired_density, blend_speed)

	if world_env and world_env.environment:
		var env := world_env.environment
		env.fog_enabled = fog_on
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_depth_begin = current_fog_begin
		env.fog_depth_end = current_fog_end
		env.fog_density = current_density
		env.fog_light_color = env.fog_light_color.lerp(desired_col, blend_speed)

	var show_outdoor_slabs: bool = fog_on and (not in_small_room)
	for i: int in range(ground_fog_layers.size()):
		var layer := ground_fog_layers[i]
		if layer and is_instance_valid(layer):
			layer.visible = show_outdoor_slabs
			if show_outdoor_slabs:
				layer.rotation.y = sin(weather_phase * 0.09 + float(i)) * 0.05
				layer.position.y = (0.26 if i % 2 == 0 else 0.70) + sin(weather_phase * 0.42 + float(i)) * 0.04

	for j: int in range(mid_fog_layers.size()):
		var ml := mid_fog_layers[j]
		if ml and is_instance_valid(ml):
			ml.visible = show_outdoor_slabs
			if show_outdoor_slabs:
				ml.rotation.y = cos(weather_phase * 0.07 + float(j) * 1.4) * 0.06
				ml.position.y = 1.50 + sin(weather_phase * 0.30 + float(j)) * 0.09
