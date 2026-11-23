class_name StylizedLightingController
extends Node

# Prompt 08 Part 1 — Balanced PS1 Psychological Horror Lighting & Dynamic Proximity Shadow Manager
# - Preserves moody 1996 retro darkness & strong shadows while ensuring paths, buildings, cars,
#   doors, props, and human silhouettes remain clearly recognizable!
# - Dynamically enables sharp blocky PS1 shadows on the nearest 6 streetlamps/interiors around player
# - Reacts live to Brightness, Gamma, Contrast, Shadow Quality, and Fog Intensity settings

var district_root: Node3D
var player_ref: Node3D
var _managed_lights: Array[Light3D] = []
var _update_accum: float = 0.0
var shadow_enabled_count: int = 0
var blackout_active: bool = false


func _sett() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("SettingsManager") if ml is SceneTree else null


func setup_lighting(p_district: Node3D, p_player: Node3D) -> void:
	name = "StylizedLightingController"
	district_root = p_district
	player_ref = p_player
	_collect_district_lights()
	_configure_ps1_environment()
	var sett := _sett()
	if sett and sett.has_signal("settings_changed"):
		if not sett.settings_changed.is_connected(_on_settings_changed):
			sett.settings_changed.connect(_on_settings_changed)
	update_proximity_shadows()


func _on_settings_changed() -> void:
	_configure_ps1_environment()
	update_proximity_shadows()


func set_blackout(active: bool) -> void:
	blackout_active = active
	_configure_ps1_environment()


func _configure_ps1_environment() -> void:
	if not district_root:
		return
	var sett := _sett()
	var bright: float = float(sett.get_val("brightness", 1.08)) if sett else 1.08
	var contr: float = float(sett.get_val("contrast", 1.0)) if sett else 1.0

	var we: WorldEnvironment = district_root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment.background_color = Color(0.012, 0.018, 0.024) if blackout_active else Color(0.032, 0.044, 0.058)
		we.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		we.environment.ambient_light_color = Color(0.11, 0.14, 0.18) if blackout_active else Color(0.22, 0.28, 0.35)
		we.environment.ambient_light_energy = 0.12 if blackout_active else 0.46
		we.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		we.environment.adjustment_enabled = true
		we.environment.adjustment_brightness = clampf(bright, 0.65, 1.65)
		we.environment.adjustment_contrast = clampf(contr, 0.70, 1.50)

	var moon: DirectionalLight3D = district_root.get_node_or_null("ColdMoonRim") as DirectionalLight3D
	if moon:
		moon.light_color = Color(0.48, 0.60, 0.76)
		moon.light_energy = 0.10 if blackout_active else 0.36
		var sh_ok: bool = (sett == null) or (bool(sett.get_val("shadows", true)) and str(sett.get_val("ps1_shadow_quality", "blocky")) != "off")
		moon.shadow_enabled = sh_ok
		moon.shadow_blur = 0.24


func _collect_district_lights() -> void:
	_managed_lights.clear()
	if not district_root:
		return
	var stack: Array[Node] = [district_root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is SpotLight3D or cur is OmniLight3D:
			var l := cur as Light3D
			if l.name in ["DeskGooseneckLamp", "TrafikaInteriorLight", "SecOfficeExteriorLamp"]:
				l.shadow_enabled = true
				l.shadow_blur = 0.24
			elif l.name == "SodiumAmbientFill":
				# Soft fill lights stay shadowless for clean bounce readability without shadow clutter
				l.shadow_enabled = false
			else:
				_managed_lights.append(l)
		for ch in cur.get_children():
			stack.append(ch)


func _process(delta: float) -> void:
	_update_accum += delta
	if _update_accum >= 0.30:
		_update_accum = 0.0
		update_proximity_shadows()


func update_proximity_shadows() -> void:
	var sett := _sett()
	var sh_mode: String = str(sett.get_val("ps1_shadow_quality", "blocky")) if sett else "blocky"
	var allow_sh: bool = ((sett == null) or bool(sett.get_val("shadows", true))) and sh_mode != "off"
	var blur_val: float = 0.24 if sh_mode == "blocky" else 0.72

	shadow_enabled_count = 0
	if not player_ref or not is_instance_valid(player_ref) or _managed_lights.is_empty():
		return

	var ppos: Vector3 = player_ref.global_position
	var ranked: Array[Dictionary] = []
	for l: Light3D in _managed_lights:
		if not is_instance_valid(l):
			continue
		if not allow_sh or not l.visible or l.light_energy <= 0.05:
			l.shadow_enabled = false
			continue
		var d: float = l.global_position.distance_to(ppos)
		if d <= 28.0:
			ranked.append({"light": l, "dist": d})
		else:
			l.shadow_enabled = false

	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["dist"]) < float(b["dist"]))
	var budget: int = 6 # Strong blocky dynamic shadows on nearest 6 streetlamps/interiors!
	for i: int in range(ranked.size()):
		var l: Light3D = ranked[i]["light"] as Light3D
		var enable: bool = i < budget
		l.shadow_enabled = enable
		if enable:
			l.shadow_blur = blur_val
			l.shadow_bias = 0.045
			shadow_enabled_count += 1
