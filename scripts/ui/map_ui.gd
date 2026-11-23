class_name JavorMapUI
extends Control

const ThemeLib = preload("res://scripts/ui/javor_theme.gd")

# Matches real world coordinates in ResidentialDistrict (X: -110..+100, Z: -84..+66)
const WORLD_MIN_X := -110.0
const WORLD_SPAN_X := 210.0
const WORLD_MAX_Z := 66.0
const WORLD_SPAN_Z := 150.0

# Exact architectural footprints matching ResidentialDistrict geometry (Part 1.1 Layer A)
const WORLD_BUILDINGS := [
	{"label": "BLDG A", "rect": Rect2(-46.0, 32.0, 28.0, 12.0), "col": Color(0.32, 0.34, 0.36, 0.45)},
	{"label": "BLDG B (8F)", "rect": Rect2(-13.0, 36.0, 30.0, 12.0), "col": Color(0.30, 0.34, 0.40, 0.50)},
	{"label": "BLDG C", "rect": Rect2(24.0, 30.0, 28.0, 12.0), "col": Color(0.36, 0.32, 0.30, 0.45)},
	{"label": "BLDG D", "rect": Rect2(-10.0, -36.0, 28.0, 12.0), "col": Color(0.42, 0.36, 0.28, 0.45)},
	{"label": "BLDG E", "rect": Rect2(68.0, -28.0, 12.0, 28.0), "col": Color(0.32, 0.34, 0.36, 0.45)},
	{"label": "BLDG F", "rect": Rect2(-74.0, 2.0, 12.0, 28.0), "col": Color(0.36, 0.32, 0.30, 0.45)},
	{"label": "OFFICE", "rect": Rect2(-22.5, -60.0, 9.0, 8.0), "col": Color(0.68, 0.44, 0.18, 0.55)},
	{"label": "NEWSSTAND", "rect": Rect2(36.2, -13.0, 4.2, 6.0), "col": Color(0.24, 0.44, 0.34, 0.55)},
	{"label": "NIGHT SHOP", "rect": Rect2(42.0, -8.0, 14.0, 12.0), "col": Color(0.30, 0.42, 0.48, 0.48)},
	{"label": "GROCERY", "rect": Rect2(42.0, 6.0, 14.0, 16.0), "col": Color(0.30, 0.46, 0.36, 0.48)},
	{"label": "GARAGES", "rect": Rect2(-92.0, -62.5, 36.0, 7.5), "col": Color(0.34, 0.34, 0.34, 0.50)},
	{"label": "SUBSTATION", "rect": Rect2(-79.0, -19.0, 14.0, 10.0), "col": Color(0.46, 0.34, 0.24, 0.52)},
	{"label": "BOILER", "rect": Rect2(-78.0, -40.0, 18.0, 16.0), "col": Color(0.48, 0.28, 0.22, 0.52)},
]

const ZONE_PINS := {
	"security_office": {"label": "SECURITY OFFICE", "pos": Vector2(-18.0, -56.0)},
	"parking_lot": {"label": "PARKING", "pos": Vector2(25.0, -53.0)},
	"central_park": {"label": "CENTRAL PARK", "pos": Vector2(0.0, 2.0)},
	"commercial_area": {"label": "SHOPS", "pos": Vector2(49.0, -2.0)},
	"garages": {"label": "GARAGES 01-10", "pos": Vector2(-74.0, -56.0)},
	"technical_area": {"label": "SUBSTATION / BOILER", "pos": Vector2(-70.0, -25.0)},
	"apartments": {"label": "BLOCKS A-F", "pos": Vector2(2.0, 42.0)},
	"northern_forest": {"label": "NORTH PATH", "pos": Vector2(2.0, 56.0)},
}

var _title_lbl: Label
var _legend_lbl: Label
var _route_lbl: Label
var _map_tex: TextureRect
var _overlay: Control
var _player_world_pos: Vector3 = Vector3(-15.8, 0.2, -54.5)
var patrol_mgr: Node = null
var nav_hint_mgr: Node = null


func _ready() -> void:
	_build_ui()


func _tr(k: String, fb: String = "") -> String:
	var loc := get_node_or_null("/root/LocalizationManager")
	return loc.tr_key(k, fb) if loc and loc.has_method("tr_key") else (fb if not fb.is_empty() else k)


func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 5)
	add_child(vb)

	_title_lbl = Label.new()
	_title_lbl.text = _tr("map_title", "JAVOR ESTATE — PATROL ROUTE MAP (1996)")
	_title_lbl.add_theme_color_override("font_color", ThemeLib.COL_INK)
	_title_lbl.add_theme_font_size_override("font_size", 14)
	if ThemeLib.get_mono_bold_font():
		_title_lbl.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
	vb.add_child(_title_lbl)

	var map_host := Control.new()
	map_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_host.custom_minimum_size = Vector2(420, 290)
	vb.add_child(map_host)

	_map_tex = TextureRect.new()
	_map_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_tex.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists("res://assets/graphics/ui/javor_blueprint_map.png"):
		var tx: Resource = load("res://assets/graphics/ui/javor_blueprint_map.png")
		if tx is Texture2D:
			_map_tex.texture = tx as Texture2D
	map_host.add_child(_map_tex)

	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_on_overlay_draw)
	map_host.add_child(_overlay)

	_route_lbl = Label.new()
	_route_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_route_lbl.add_theme_color_override("font_color", Color(0.58, 0.18, 0.10))
	_route_lbl.add_theme_font_size_override("font_size", 11)
	if ThemeLib.get_mono_bold_font():
		_route_lbl.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
	vb.add_child(_route_lbl)

	_legend_lbl = Label.new()
	_legend_lbl.text = "Red Pencil: Active Patrol Route  |  Green ✓: Inspected  |  Amber ○: Optional  |  Blue ●: You"
	_legend_lbl.add_theme_color_override("font_color", Color(0.28, 0.25, 0.21))
	_legend_lbl.add_theme_font_size_override("font_size", 11)
	vb.add_child(_legend_lbl)


func set_navigation_sources(p_patrol_mgr: Node, p_nav_hint_mgr: Node = null) -> void:
	patrol_mgr = p_patrol_mgr
	nav_hint_mgr = p_nav_hint_mgr


func refresh_map(player_pos: Vector3 = Vector3(-15.8, 0.2, -54.5)) -> void:
	_player_world_pos = player_pos
	var gs := get_node_or_null("/root/GameState")
	var n: int = gs.current_night if gs else 1
	if _title_lbl:
		_title_lbl.text = "SHIFT %02d — JAVOR ESTATE MAP (1996)" % n
	if _route_lbl and patrol_mgr and patrol_mgr.has_method("get_active_checkpoint"):
		var acp: Dictionary = patrol_mgr.get_active_checkpoint(n)
		if not acp.is_empty():
			_route_lbl.text = "NEXT [#%d]: %s — %s" % [int(acp.get("num", 1)), str(acp.get("name", "")), str(acp.get("action", ""))]
		else:
			_route_lbl.text = "ALL PATROL CHECKPOINTS VERIFIED — Return to Security Office."
	if _overlay:
		_overlay.queue_redraw()


func _world_to_canvas(wx: float, wz: float, sz: Vector2) -> Vector2:
	var nx: float = clampf((wx - WORLD_MIN_X) / WORLD_SPAN_X, 0.04, 0.96)
	var ny: float = clampf((WORLD_MAX_Z - wz) / WORLD_SPAN_Z, 0.05, 0.95)
	return Vector2(nx * sz.x, ny * sz.y)


func _world_rect_to_canvas(wr: Rect2, sz: Vector2) -> Rect2:
	var p1: Vector2 = _world_to_canvas(wr.position.x, wr.position.y + wr.size.y, sz)
	var p2: Vector2 = _world_to_canvas(wr.position.x + wr.size.x, wr.position.y, sz)
	return Rect2(p1, Vector2(maxf(4.0, p2.x - p1.x), maxf(4.0, p2.y - p1.y)))


func _draw_pencil_segment(p0: Vector2, p1: Vector2, col: Color, width: float = 2.4) -> void:
	# Slightly hand-drawn red/orange pencil stroke with authentic organic wobble
	var steps: int = 6
	var prev: Vector2 = p0
	var perp: Vector2 = (p1 - p0).normalized().orthogonal()
	for i: int in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var wobble: float = sin(t * PI * 3.0 + p0.x * 0.05) * 1.4 if (i < steps) else 0.0
		var cur: Vector2 = p0.lerp(p1, t) + perp * wobble
		_overlay.draw_line(prev, cur, col, width, true)
		prev = cur


func _on_overlay_draw() -> void:
	if not _overlay:
		return
	var sz := _overlay.size
	if sz.x < 10.0 or sz.y < 10.0:
		return
	var gs := get_node_or_null("/root/GameState")
	var st := get_node_or_null("/root/StoryManager")
	var fnt: Font = ThemeLib.get_mono_bold_font() if ThemeLib.get_mono_bold_font() else ThemeDB.fallback_font
	var n: int = gs.current_night if gs else 1

	# 1. Exact world building footprints & pedestrian roads matching actual playable level geometry
	var road_col := Color(0.24, 0.22, 0.20, 0.35)
	_overlay.draw_line(_world_to_canvas(-95.0, -74.0, sz), _world_to_canvas(90.0, -74.0, sz), road_col, 3.0)
	_overlay.draw_line(_world_to_canvas(0.0, -74.0, sz), _world_to_canvas(0.0, 54.0, sz), road_col, 2.5)
	_overlay.draw_line(_world_to_canvas(-54.0, -64.0, sz), _world_to_canvas(-54.0, 54.0, sz), road_col, 2.5)
	_overlay.draw_line(_world_to_canvas(37.5, -44.0, sz), _world_to_canvas(37.5, 34.0, sz), road_col, 2.5)
	_overlay.draw_line(_world_to_canvas(-54.0, 28.0, sz), _world_to_canvas(54.0, 28.0, sz), road_col, 2.2)
	_overlay.draw_line(_world_to_canvas(-54.0, 54.0, sz), _world_to_canvas(54.0, 54.0, sz), road_col, 2.0)

	for b: Dictionary in WORLD_BUILDINGS:
		var r: Rect2 = _world_rect_to_canvas(b["rect"], sz)
		_overlay.draw_rect(r, b["col"], true)
		_overlay.draw_rect(r, Color(0.18, 0.15, 0.12, 0.72), false, 1.2)
		var lbl_s: String = str(b["label"])
		_overlay.draw_string(fnt, r.position + Vector2(3.0, minf(12.0, r.size.y * 0.72)), lbl_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.14, 0.12, 0.10))

	# 2. Layer A: Handwritten Red/Orange Pencil Patrol Route with numbered Checkpoints 1..N
	if patrol_mgr and patrol_mgr.has_method("get_route"):
		var rt: Dictionary = patrol_mgr.get_route(n)
		var start_w: Vector3 = rt.get("start_pos", Vector3(-15.8, 0.2, -54.5))
		var cps: Array = rt.get("checkpoints", [])
		var active_cp: Dictionary = patrol_mgr.get_active_checkpoint(n)
		var active_id: String = str(active_cp.get("id", ""))
		var lost_flag: bool = (nav_hint_mgr != null and bool(nav_hint_mgr.get("is_player_lost")))

		var prev_pt: Vector2 = _world_to_canvas(start_w.x, start_w.z, sz)
		for cp_var in cps:
			var cp: Dictionary = cp_var
			var cid: String = str(cp.get("id", ""))
			var cpos: Vector3 = cp.get("pos", Vector3.ZERO)
			var cpt: Vector2 = _world_to_canvas(cpos.x, cpos.z, sz)
			var done: bool = patrol_mgr.is_checkpoint_completed(cid)
			var visited: bool = patrol_mgr.is_checkpoint_visited(cid)
			var is_next: bool = (cid == active_id)

			var line_col: Color = Color(0.16, 0.48, 0.22, 0.78) if done else (Color(0.84, 0.20, 0.10, 0.94) if is_next else Color(0.76, 0.32, 0.14, 0.72))
			_draw_pencil_segment(prev_pt, cpt, line_col, 3.0 if (is_next and lost_flag) else 2.2)

			# Checkpoint numbered circle
			if done:
				_overlay.draw_circle(cpt, 8.0, Color(0.16, 0.48, 0.22, 0.92))
				_overlay.draw_string(fnt, cpt + Vector2(-4.0, 4.0), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.96, 0.95, 0.90))
			else:
				var fill_c: Color = Color(0.82, 0.22, 0.12, 0.95) if is_next else Color(0.76, 0.38, 0.14, 0.85)
				_overlay.draw_circle(cpt, 8.5 if is_next else 7.5, fill_c)
				if visited and not done:
					_overlay.draw_arc(cpt, 12.0, 0.0, TAU, 18, Color(0.88, 0.54, 0.10, 0.95), 2.0)
				if is_next:
					_overlay.draw_arc(cpt, 13.5 if lost_flag else 11.5, 0.0, TAU, 22, Color(0.85, 0.16, 0.10, 0.92), 2.2)
				_overlay.draw_string(fnt, cpt + Vector2(-3.5, 4.0), str(int(cp.get("num", 1))), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.98, 0.96, 0.92))
			prev_pt = cpt

		# Optional investigation locations (hand-circled amber dots)
		for opt_var in rt.get("optional_spots", []):
			var opt: Dictionary = opt_var
			var opos: Vector3 = opt.get("pos", Vector3.ZERO)
			var opt_pt: Vector2 = _world_to_canvas(opos.x, opos.z, sz)
			_overlay.draw_arc(opt_pt, 6.0, 0.0, TAU, 14, Color(0.72, 0.48, 0.12, 0.85), 1.6)
			_overlay.draw_string(fnt, opt_pt + Vector2(8.0, 4.0), "? " + str(opt.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.46, 0.30, 0.10))

	# 3. Story mystery pencil annotations unlocked dynamically
	if st and bool(st.get_flag("climax_night2_intercom_47", false)):
		var b_pt := _world_to_canvas(2.0, 42.0, sz)
		_overlay.draw_string(fnt, b_pt + Vector2(-28, -12), "APT 47?", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.18, 0.14))
	if st and (bool(st.get_flag("found_doc_sealed_unit_47", false)) or bool(st.get_flag("n5_hidden_corridor_unlocked", false))):
		var t_pt := _world_to_canvas(-80.0, -18.0, sz)
		_overlay.draw_string(fnt, t_pt + Vector2(-34, 14), "SERVICE CORRIDOR 47", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.72, 0.14, 0.12))

	# 4. Approximate player location marker (Blue dot)
	var ppt := _world_to_canvas(_player_world_pos.x, _player_world_pos.z, sz)
	_overlay.draw_circle(ppt, 6.0, Color(0.14, 0.42, 0.76, 0.96))
	_overlay.draw_arc(ppt, 10.5, 0.0, TAU, 20, Color(0.14, 0.42, 0.76, 0.70), 2.0)
