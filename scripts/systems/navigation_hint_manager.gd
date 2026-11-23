class_name NavigationHintManager
extends Node3D

# Prompt 07 Part 5 Update:
# - Removed ALL glowing patrol markers, reflective neon posts & artificial directional arrows!
# - Physical navigation is now led organically by Companion Guard Jozef Varga + architectural
#   1996 building identifier plates (BLOK A..BLOK F) + the physical Notebook Map + realistic radio check-ins.

signal lost_player_hint_triggered(hint_text: String, cp_id: String)
signal clear_direction_cue(cue_text: String)

# Authentic grounded 1996 enamel building identifier plates only (no glowing gamey beacons!)
const BUILDING_PLATES: Array[Dictionary] = [
	{"text": "BLOK A", "pos": Vector3(-32.0, 2.55, 31.78), "yaw": 180.0},
	{"text": "BLOK B", "pos": Vector3(2.0, 2.55, 35.78), "yaw": 180.0},
	{"text": "BLOK C", "pos": Vector3(38.0, 2.55, 29.78), "yaw": 180.0},
	{"text": "BLOK D", "pos": Vector3(4.0, 2.55, -23.78), "yaw": 0.0},
	{"text": "BLOK E", "pos": Vector3(67.78, 2.55, -14.0), "yaw": -90.0},
	{"text": "BLOK F", "pos": Vector3(-61.78, 2.55, 16.0), "yaw": 90.0},
]

var patrol_mgr: Node
var player_ref: Node3D
var companion_ref: Node3D
var architectural_plate_count: int = 0
var glowing_markers_count: int = 0 # Strictly 0 per Prompt 07 Part 5!

var time_without_progress: float = 0.0
var is_player_lost: bool = false
var _hint_cooldown: float = 0.0
var _last_completed_count: int = 0
var _nav_mode: String = "subtle"


func _sett() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("SettingsManager") if ml is SceneTree else null


func _gs() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("GameState") if ml is SceneTree else null


func setup_navigation(p_patrol_mgr: Node, p_player: Node3D, p_companion: Node3D = null) -> void:
	name = "NavigationHintManager"
	patrol_mgr = p_patrol_mgr
	player_ref = p_player
	companion_ref = p_companion
	_sync_nav_mode()
	var sett := _sett()
	if sett and sett.has_signal("settings_changed"):
		if not sett.settings_changed.is_connected(_sync_nav_mode):
			sett.settings_changed.connect(_sync_nav_mode)
	_spawn_architectural_building_plates()


func _sync_nav_mode() -> void:
	var sett := _sett()
	_nav_mode = str(sett.get_val("nav_assist", "subtle")) if sett else "subtle"


func get_nav_mode() -> String:
	_sync_nav_mode()
	return _nav_mode


func get_marker_count() -> int:
	return architectural_plate_count


func has_artificial_glowing_markers() -> bool:
	return glowing_markers_count > 0


func notify_progress_made() -> void:
	time_without_progress = 0.0
	is_player_lost = false


func _spawn_architectural_building_plates() -> void:
	# Real non-glowing weathered enamel plates mounted directly on paneláky (BLOK A..BLOK F)
	var plate_bg := StandardMaterial3D.new()
	plate_bg.albedo_color = Color(0.11, 0.14, 0.19)
	plate_bg.roughness = 0.92
	plate_bg.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	architectural_plate_count = 0
	glowing_markers_count = 0
	for bp: Dictionary in BUILDING_PLATES:
		var pn := Node3D.new()
		pn.name = "Plate_" + str(bp["text"]).replace(" ", "_")
		pn.position = bp["pos"]
		pn.rotation_degrees.y = float(bp["yaw"])
		add_child(pn)
		var bg := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(1.15, 0.38, 0.04)
		bx.material = plate_bg
		bg.mesh = bx
		pn.add_child(bg)
		var tl := Label3D.new()
		tl.text = str(bp["text"])
		tl.pixel_size = 0.0055
		tl.position = Vector3(0.0, 0.0, 0.03)
		tl.modulate = Color(0.84, 0.80, 0.72)
		pn.add_child(tl)
		architectural_plate_count += 1


func _process(delta: float) -> void:
	if not player_ref or not patrol_mgr:
		return
	var gs := _gs()
	var n: int = gs.current_night if gs else 1
	var prog: Dictionary = patrol_mgr.get_completion_progress(n)
	var cur_done: int = int(prog.get("done", 0))
	if cur_done != _last_completed_count:
		_last_completed_count = cur_done
		notify_progress_made()

	if not bool(prog.get("all_done", false)):
		time_without_progress += delta
	if _hint_cooldown > 0.0:
		_hint_cooldown = maxf(0.0, _hint_cooldown - delta)

	var active_cp: Dictionary = patrol_mgr.get_active_checkpoint(n)
	if time_without_progress >= 80.0 and _hint_cooldown <= 0.0 and not active_cp.is_empty():
		trigger_lost_player_assistance(active_cp)


func trigger_lost_player_assistance(active_cp: Dictionary = {}) -> String:
	if active_cp.is_empty() and patrol_mgr:
		active_cp = patrol_mgr.get_active_checkpoint()
	is_player_lost = true
	_hint_cooldown = 95.0
	var cname: String = str(active_cp.get("name", "the next patrol checkpoint"))
	var where_txt: String = str(active_cp.get("where", "Open your notebook to check the estate map."))
	var hint_msg: String = "Martin, Jozef here on radio. Head over and check %s. %s" % [cname, where_txt]
	emit_signal("lost_player_hint_triggered", hint_msg, str(active_cp.get("id", "")))
	return hint_msg
