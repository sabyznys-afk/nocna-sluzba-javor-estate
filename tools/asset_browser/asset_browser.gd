@tool
class_name DistrictAssetBrowser
extends Control

const RegistryScript = preload("res://tools/asset_browser/asset_registry.gd")

signal close_requested

var _scan_data: Dictionary = {}
var _filtered_assets: Array[Dictionary] = []
var _selected_category: String = "ALL"
var _selected_status: String = "ALL"
var _selected_asset: Dictionary = {}

# UI Controls
var _stats_label: Label
var _completeness_label: Label
var _category_list: ItemList
var _search_edit: LineEdit
var _sort_option: OptionButton
var _asset_list: ItemList
var _preview_vp_container: SubViewportContainer
var _preview_vp: SubViewport
var _preview_pivot: Node3D
var _preview_cam: Camera3D
var _tex_preview: TextureRect
var _audio_preview_box: HBoxContainer
var _audio_player: AudioStreamPlayer
var _inspector_text: RichTextLabel
var _auto_rotate: bool = true
var _wireframe: bool = false
var _cam_yaw: float = 0.65
var _cam_pitch: float = -0.35
var _cam_dist: float = 3.6
var _dragging_vp: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh_scan()


func _process(delta: float) -> void:
	if _auto_rotate and _preview_pivot and is_instance_valid(_preview_pivot) and _preview_pivot.get_child_count() > 0:
		_cam_yaw += delta * 0.55
		_update_preview_camera()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.07, 0.085, 0.98)
	add_child(bg)

	var main_vb := VBoxContainer.new()
	main_vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vb.offset_left = 12
	main_vb.offset_top = 12
	main_vb.offset_right = -12
	main_vb.offset_bottom = -12
	main_vb.add_theme_constant_override("separation", 8)
	add_child(main_vb)

	# Top Developer Header Bar
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	main_vb.add_child(top_bar)

	var title_lbl := Label.new()
	title_lbl.text = "RESIDENTIAL DISTRICT ASSET MANAGER [DEV ONLY]"
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.80, 0.38))
	title_lbl.add_theme_font_size_override("font_size", 18)
	top_bar.add_child(title_lbl)

	_stats_label = Label.new()
	_stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_label.add_theme_color_override("font_color", Color(0.75, 0.86, 0.82))
	top_bar.add_child(_stats_label)

	_completeness_label = Label.new()
	_completeness_label.add_theme_color_override("font_color", Color(0.55, 0.92, 0.65))
	top_bar.add_child(_completeness_label)

	var refresh_btn := Button.new()
	refresh_btn.text = "Rescan Project"
	refresh_btn.pressed.connect(refresh_scan)
	top_bar.add_child(refresh_btn)

	var close_btn := Button.new()
	close_btn.text = "Close [F9]"
	close_btn.pressed.connect(func(): emit_signal("close_requested"))
	top_bar.add_child(close_btn)

	# Main 3-Column Body
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vb.add_child(body)

	# 1. Left Category Sidebar
	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(220, 0)
	left_vb.add_theme_constant_override("separation", 6)
	body.add_child(left_vb)

	var st_row := HBoxContainer.new()
	left_vb.add_child(st_row)
	for st_key: String in ["ALL", "USED", "UNUSED", "MISSING", "BROKEN"]:
		var b := Button.new()
		b.text = st_key
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sk := st_key
		b.pressed.connect(func():
			_selected_status = sk
			_apply_filters()
		)
		st_row.add_child(b)

	_category_list = ItemList.new()
	_category_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_category_list.item_selected.connect(_on_category_selected)
	left_vb.add_child(_category_list)

	# 2. Center + Right Split
	var center_right := HSplitContainer.new()
	center_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(center_right)

	# Center Asset List + Filter Toolbar
	var mid_vb := VBoxContainer.new()
	mid_vb.custom_minimum_size = Vector2(440, 0)
	mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_vb.add_theme_constant_override("separation", 6)
	center_right.add_child(mid_vb)

	var search_hb := HBoxContainer.new()
	mid_vb.add_child(search_hb)
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Filter by asset name or res:// path..."
	_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_edit.text_changed.connect(func(_t: String): _apply_filters())
	search_hb.add_child(_search_edit)

	_sort_option = OptionButton.new()
	_sort_option.add_item("Sort: Name")
	_sort_option.add_item("Sort: Status")
	_sort_option.add_item("Sort: Usage Refs")
	_sort_option.item_selected.connect(func(_i: int): _apply_filters())
	search_hb.add_child(_sort_option)

	_asset_list = ItemList.new()
	_asset_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_asset_list.item_selected.connect(_on_asset_selected)
	mid_vb.add_child(_asset_list)

	# 3. Right Preview + Metadata Inspector
	var right_vb := VBoxContainer.new()
	right_vb.custom_minimum_size = Vector2(400, 0)
	right_vb.add_theme_constant_override("separation", 6)
	center_right.add_child(right_vb)

	var vp_ctrl_hb := HBoxContainer.new()
	right_vb.add_child(vp_ctrl_hb)
	var rot_btn := Button.new()
	rot_btn.text = "Toggle Spin"
	rot_btn.pressed.connect(func(): _auto_rotate = not _auto_rotate)
	vp_ctrl_hb.add_child(rot_btn)

	var wire_btn := Button.new()
	wire_btn.text = "Wireframe"
	wire_btn.pressed.connect(_toggle_wireframe)
	vp_ctrl_hb.add_child(wire_btn)

	var copy_btn := Button.new()
	copy_btn.text = "Copy res:// Path"
	copy_btn.pressed.connect(func():
		if _selected_asset.has("path") and DisplayServer.get_name() != "headless":
			DisplayServer.clipboard_set(str(_selected_asset["path"]))
	)
	vp_ctrl_hb.add_child(copy_btn)

	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(360, 260)
	right_vb.add_child(preview_panel)

	_preview_vp_container = SubViewportContainer.new()
	_preview_vp_container.stretch = true
	_preview_vp_container.gui_input.connect(_on_vp_gui_input)
	preview_panel.add_child(_preview_vp_container)

	_preview_vp = SubViewport.new()
	_preview_vp.own_world_3d = true
	_preview_vp.size = Vector2i(360, 260)
	_preview_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED if DisplayServer.get_name() == "headless" else SubViewport.UPDATE_ALWAYS
	_preview_vp_container.add_child(_preview_vp)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.08, 0.10, 0.12)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.62, 0.72)
	e.ambient_light_energy = 0.85
	env.environment = e
	_preview_vp.add_child(env)

	var dl := DirectionalLight3D.new()
	dl.rotation_degrees = Vector3(-42, 35, 0)
	dl.light_energy = 1.4
	_preview_vp.add_child(dl)

	_preview_pivot = Node3D.new()
	_preview_vp.add_child(_preview_pivot)

	_preview_cam = Camera3D.new()
	_preview_cam.fov = 52.0
	_preview_vp.add_child(_preview_cam)
	_preview_cam.current = true
	_update_preview_camera()

	_tex_preview = TextureRect.new()
	_tex_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tex_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_preview.visible = false
	preview_panel.add_child(_tex_preview)

	_audio_preview_box = HBoxContainer.new()
	_audio_preview_box.visible = false
	right_vb.add_child(_audio_preview_box)
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	var play_btn := Button.new()
	play_btn.text = "▶ Play Audio"
	play_btn.pressed.connect(func():
		if _audio_player.stream:
			_audio_player.play()
	)
	_audio_preview_box.add_child(play_btn)
	var stop_btn := Button.new()
	stop_btn.text = "■ Stop"
	stop_btn.pressed.connect(func(): _audio_player.stop())
	_audio_preview_box.add_child(stop_btn)

	_inspector_text = RichTextLabel.new()
	_inspector_text.bbcode_enabled = true
	_inspector_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_child(_inspector_text)


func refresh_scan() -> void:
	_scan_data = RegistryScript.scan_project()
	var stats: Dictionary = _scan_data.get("stats", {})
	var comp: Dictionary = _scan_data.get("completeness", {})
	if _stats_label:
		_stats_label.text = "Total: %d | Used: %d | Unused: %d | Missing: %d | Broken: %d" % [
			int(stats.get("total_assets", 0)),
			int(stats.get("used", 0)),
			int(stats.get("unused", 0)),
			int(stats.get("missing", 0)),
			int(stats.get("broken", 0)),
		]
	if _completeness_label:
		_completeness_label.text = "District Ready: %.0f%% (%d/%d)" % [
			float(comp.get("percent", 100.0)),
			int(comp.get("required_present", 0)),
			int(comp.get("required_total", 0)),
		]

	if _category_list:
		_category_list.clear()
		var cats: Dictionary = stats.get("categories", {})
		_category_list.add_item("ALL (%d)" % int(stats.get("total_assets", 0)))
		_category_list.set_item_metadata(0, "ALL")
		for c: String in RegistryScript.CATEGORIES:
			var idx := _category_list.item_count
			_category_list.add_item("%s (%d)" % [c, int(cats.get(c, 0))])
			_category_list.set_item_metadata(idx, c)

	_apply_filters()


func _on_category_selected(idx: int) -> void:
	if _category_list:
		_selected_category = str(_category_list.get_item_metadata(idx))
		_apply_filters()


func _apply_filters() -> void:
	_filtered_assets.clear()
	var raw_assets: Array = _scan_data.get("assets", [])
	var query := _search_edit.text.strip_edges().to_lower() if _search_edit else ""
	for item in raw_assets:
		if not (item is Dictionary):
			continue
		var d: Dictionary = item
		if _selected_category != "ALL" and str(d.get("category", "")) != _selected_category:
			continue
		if _selected_status != "ALL" and str(d.get("status", "")) != _selected_status:
			continue
		if not query.is_empty() and not str(d.get("path", "")).to_lower().contains(query):
			continue
		_filtered_assets.append(d)

	var sort_mode := _sort_option.selected if _sort_option else 0
	_filtered_assets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if sort_mode == 1:
			return str(a.get("status", "")) < str(b.get("status", ""))
		if sort_mode == 2:
			return int(a.get("usage_count", 0)) > int(b.get("usage_count", 0))
		return str(a.get("name", "")) < str(b.get("name", ""))
	)

	if _asset_list:
		_asset_list.clear()
		for d: Dictionary in _filtered_assets:
			var st := str(d.get("status", "USED"))
			var idx := _asset_list.item_count
			_asset_list.add_item("[%s] %s  |  %s  (%d refs)" % [
				st,
				str(d.get("name", "")),
				str(d.get("category", "")),
				int(d.get("usage_count", 0)),
			])
			var col := Color(0.68, 0.90, 0.72)
			if st == "UNUSED":
				col = Color(0.95, 0.80, 0.42)
			elif st == "MISSING" or st == "BROKEN":
				col = Color(0.96, 0.42, 0.38)
			_asset_list.set_item_custom_fg_color(idx, col)


func _on_asset_selected(idx: int) -> void:
	if idx < 0 or idx >= _filtered_assets.size():
		return
	_selected_asset = _filtered_assets[idx]
	_update_preview(_selected_asset)


func _clear_3d_preview() -> void:
	if _preview_pivot:
		for c: Node in _preview_pivot.get_children():
			c.queue_free()


func _update_preview(d: Dictionary) -> void:
	_clear_3d_preview()
	_tex_preview.visible = false
	_audio_preview_box.visible = false
	_preview_vp_container.visible = false
	if _audio_player:
		_audio_player.stop()

	var p := str(d.get("path", ""))
	var ext := str(d.get("ext", ""))
	var extra_info := ""

	if d.get("status", "") != "MISSING" and ResourceLoader.exists(p):
		if ext == "glb" or ext == "tscn":
			_preview_vp_container.visible = true
			var packed: Resource = load(p)
			if packed is PackedScene:
				var inst := (packed as PackedScene).instantiate()
				if inst is Node3D:
					_preview_pivot.add_child(inst)
					_frame_3d_model(inst as Node3D)
				else:
					inst.queue_free()
		elif ext == "png":
			_tex_preview.visible = true
			var tex: Resource = load(p)
			if tex is Texture2D:
				_tex_preview.texture = tex as Texture2D
				extra_info = "Resolution: %dx%d px\n" % [(tex as Texture2D).get_width(), (tex as Texture2D).get_height()]
		elif ext == "ogg" or ext == "wav":
			_audio_preview_box.visible = true
			var aud: Resource = load(p)
			if aud is AudioStream:
				_audio_player.stream = aud as AudioStream
				extra_info = "Length: %.2fs\n" % (aud as AudioStream).get_length()

	var refs: Array = d.get("used_in", [])
	var lines: Array[String] = [
		"[color=#f4cc66][b]%s[/b][/color]" % str(d.get("name", "")),
		"[b]Status:[/b] %s" % str(d.get("status", "")),
		"[b]Category:[/b] %s | [b]Format:[/b] .%s | [b]Size:[/b] %.1f KB" % [
			str(d.get("category", "")), ext.to_upper(), float(d.get("size_bytes", 0)) / 1024.0
		],
		"[b]Path:[/b] %s" % p,
	]
	if not extra_info.is_empty():
		lines.append(extra_info.strip_edges())
	lines.append("")
	lines.append("[b]Referenced in (%d files):[/b]" % refs.size())
	if refs.is_empty():
		lines.append("  (No direct .tscn/.gd reference matched)")
	else:
		for r: String in refs:
			lines.append("  • " + r)
	_inspector_text.text = "\n".join(lines)


func _frame_3d_model(root3d: Node3D) -> void:
	_cam_dist = 3.2
	if str(_selected_asset.get("name", "")).begins_with("vm_"):
		_cam_dist = 0.85
	elif str(_selected_asset.get("name", "")) in ["skoda_favorit.glb", "lada_van.glb", "pine_tree_90s.glb", "dead_oak_tree.glb"]:
		_cam_dist = 6.5
	elif str(_selected_asset.get("category", "")) == "Buildings":
		_cam_dist = 12.0
	root3d.position = Vector3.ZERO
	_update_preview_camera()


func _update_preview_camera() -> void:
	if not _preview_cam:
		return
	var offset := Vector3(
		cos(_cam_pitch) * sin(_cam_yaw),
		-sin(_cam_pitch),
		cos(_cam_pitch) * cos(_cam_yaw)
	) * _cam_dist
	_preview_cam.position = Vector3(0, 0.7, 0) + offset
	_preview_cam.look_at(Vector3(0, 0.55, 0), Vector3.UP)


func _on_vp_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging_vp = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cam_dist = maxf(0.45, _cam_dist * 0.88)
			_update_preview_camera()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cam_dist = minf(48.0, _cam_dist * 1.12)
			_update_preview_camera()
	elif event is InputEventMouseMotion and _dragging_vp:
		var mm := event as InputEventMouseMotion
		_cam_yaw -= mm.relative.x * 0.012
		_cam_pitch = clampf(_cam_pitch - mm.relative.y * 0.012, -1.25, 0.85)
		_update_preview_camera()


func _toggle_wireframe() -> void:
	_wireframe = not _wireframe
	if _preview_vp:
		_preview_vp.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME if _wireframe else Viewport.DEBUG_DRAW_DISABLED
