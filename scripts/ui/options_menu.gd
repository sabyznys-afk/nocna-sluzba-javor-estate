class_name JavorOptionsMenu
extends PanelContainer

signal closed

const ThemeLib = preload("res://scripts/ui/javor_theme.gd")

var _tabs: TabContainer
var _title_lbl: Label
var _apply_btn: Button
var _reset_btn: Button
var _back_btn: Button
var _rebinding_action: String = ""
var _rebind_buttons: Dictionary = {}
var _calib_preview: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = ThemeLib.get_theme()
	custom_minimum_size = Vector2(780, 560)
	_build_ui()
	var loc := get_node_or_null("/root/LocalizationManager")
	if loc and loc.has_signal("language_changed"):
		loc.language_changed.connect(func(_l: String): _rebuild_ui())


func _tr(k: String, fb: String = "") -> String:
	var loc := get_node_or_null("/root/LocalizationManager")
	return loc.tr_key(k, fb) if loc and loc.has_method("tr_key") else (fb if not fb.is_empty() else k)


func _sett() -> Node:
	return get_node_or_null("/root/SettingsManager")


func _rebuild_ui() -> void:
	var cur_tab: int = _tabs.current_tab if _tabs else 0
	for ch: Node in get_children():
		ch.queue_free()
	_rebind_buttons.clear()
	_build_ui()
	if _tabs and cur_tab >= 0 and cur_tab < _tabs.get_tab_count():
		_tabs.current_tab = cur_tab


func _build_ui() -> void:
	var sett := _sett()
	theme = ThemeLib.get_theme(bool(sett.get_val("high_contrast", false)) if sett else false)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)

	_title_lbl = Label.new()
	_title_lbl.text = _tr("opt_title", "SYSTEM & FIELD SETTINGS")
	_title_lbl.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	_title_lbl.add_theme_font_size_override("font_size", 20)
	if ThemeLib.get_mono_bold_font():
		_title_lbl.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
	vb.add_child(_title_lbl)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_tabs)

	_build_display_tab()
	_build_graphics_tab()
	_build_audio_tab()
	_build_gameplay_tab()
	_build_accessibility_tab()
	_build_language_tab()

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	vb.add_child(foot)

	_apply_btn = Button.new()
	_apply_btn.text = _tr("opt_apply", "APPLY & SAVE")
	_apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_btn.pressed.connect(func():
		AudioSynth.play_ui_sfx("ui_press")
		if _sett():
			_sett().save_settings()
			_sett().apply_all()
	)
	foot.add_child(_apply_btn)

	_reset_btn = Button.new()
	_reset_btn.text = _tr("opt_reset", "RESET DEFAULTS")
	_reset_btn.pressed.connect(func():
		AudioSynth.play_ui_sfx("ui_press")
		if _sett():
			_sett().reset_defaults()
			_rebuild_ui()
	)
	foot.add_child(_reset_btn)

	_back_btn = Button.new()
	_back_btn.text = _tr("menu_back", "BACK")
	_back_btn.pressed.connect(func():
		AudioSynth.play_ui_sfx("ui_press")
		if _sett():
			_sett().save_settings()
		emit_signal("closed")
	)
	foot.add_child(_back_btn)


func _make_tab(tab_title: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = tab_title
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(sc)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	sc.add_child(box)
	return box


func _add_option_row(parent: VBoxContainer, label_text: String, items: Array[String], selected_idx: int, cb: Callable) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	parent.add_child(hb)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl)
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(230, 32)
	for it: String in items:
		opt.add_item(it)
	opt.selected = clampi(selected_idx, 0, maxi(0, items.size() - 1))
	opt.item_selected.connect(func(idx: int):
		AudioSynth.play_ui_sfx("ui_press")
		cb.call(idx)
	)
	hb.add_child(opt)


func _add_check_row(parent: VBoxContainer, label_text: String, checked: bool, cb: Callable) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	parent.add_child(hb)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl)
	var chk := CheckButton.new()
	chk.button_pressed = checked
	chk.toggled.connect(func(val: bool):
		AudioSynth.play_ui_sfx("ui_press")
		cb.call(val)
	)
	hb.add_child(chk)


func _add_slider_row(parent: VBoxContainer, label_text: String, min_v: float, max_v: float, step_v: float, cur_v: float, fmt: String, cb: Callable) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	parent.add_child(hb)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl)
	var val_lbl := Label.new()
	val_lbl.custom_minimum_size = Vector2(58, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.text = fmt % cur_v
	var sl := HSlider.new()
	sl.min_value = min_v
	sl.max_value = max_v
	sl.step = step_v
	sl.value = cur_v
	sl.custom_minimum_size = Vector2(210, 24)
	sl.value_changed.connect(func(v: float):
		val_lbl.text = fmt % v
		cb.call(v)
	)
	hb.add_child(sl)
	hb.add_child(val_lbl)


func _build_display_tab() -> void:
	var box := _make_tab(_tr("opt_display", "DISPLAY"))
	var sett := _sett()
	var res_opts: Array[String] = ["1280x720", "1600x900", "1920x1080", "2560x1440"]
	var cur_res := str(sett.get_val("resolution", "1280x720")) if sett else "1280x720"
	_add_option_row(box, _tr("opt_resolution", "Resolution"), res_opts, maxi(0, res_opts.find(cur_res)), func(i: int):
		if _sett():
			_sett().set_val("resolution", res_opts[i])
	)
	_add_option_row(box, _tr("opt_display_mode", "Display Mode"), ["Windowed", "Fullscreen", "Borderless"], int(sett.get_val("display_mode", 0)) if sett else 0, func(i: int):
		if _sett():
			_sett().set_val("display_mode", i)
	)
	_add_check_row(box, _tr("opt_vsync", "VSync"), bool(sett.get_val("vsync", true)) if sett else true, func(v: bool):
		if _sett():
			_sett().set_val("vsync", v)
	)
	var fps_vals := [0, 30, 60, 120]
	var cur_fps := int(sett.get_val("fps_limit", 0)) if sett else 0
	_add_option_row(box, _tr("opt_fps_limit", "FPS Limit"), ["Unlimited", "30 FPS", "60 FPS", "120 FPS"], maxi(0, fps_vals.find(cur_fps)), func(i: int):
		if _sett():
			_sett().set_val("fps_limit", fps_vals[i])
	)
	_add_slider_row(box, _tr("opt_brightness", "Brightness"), 0.7, 1.55, 0.05, float(sett.get_val("brightness", 1.08)) if sett else 1.08, "%.2f", func(v: float):
		if _sett():
			_sett().set_val("brightness", v)
		if _calib_preview:
			_calib_preview.queue_redraw()
	)
	_add_slider_row(box, _tr("opt_gamma", "Gamma"), 0.7, 1.5, 0.05, float(sett.get_val("gamma", 1.0)) if sett else 1.0, "%.2f", func(v: float):
		if _sett():
			_sett().set_val("gamma", v)
		if _calib_preview:
			_calib_preview.queue_redraw()
	)
	_add_slider_row(box, _tr("opt_contrast", "Contrast"), 0.7, 1.45, 0.05, float(sett.get_val("contrast", 1.0)) if sett else 1.0, "%.2f", func(v: float):
		if _sett():
			_sett().set_val("contrast", v)
		if _calib_preview:
			_calib_preview.queue_redraw()
	)
	_add_slider_row(box, _tr("opt_fov", "Field of View"), 65.0, 95.0, 1.0, float(sett.get_val("fov", 72.0)) if sett else 72.0, "%.0f°", func(v: float):
		if _sett():
			_sett().set_val("fov", v)
	)
	_build_brightness_calibration_widget(box)


func _build_brightness_calibration_widget(parent: VBoxContainer) -> void:
	var frame := PanelContainer.new()
	frame.name = "BrightnessCalibrationPanel"
	frame.add_theme_stylebox_override("panel", ThemeLib.make_box(Color(0.04, 0.045, 0.05, 0.96), ThemeLib.COL_WARM_BORDER, 1, 8))
	parent.add_child(frame)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	frame.add_child(vb)

	var hdr := Label.new()
	hdr.text = "LIGHTING & BRIGHTNESS CALIBRATION — Adjust until the dark guard silhouette & patches remain faintly visible:"
	hdr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hdr.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	hdr.add_theme_font_size_override("font_size", 11)
	vb.add_child(hdr)

	_calib_preview = Control.new()
	_calib_preview.name = "CalibrationTestImage"
	_calib_preview.custom_minimum_size = Vector2(540, 86)
	_calib_preview.draw.connect(_draw_calibration_preview)
	vb.add_child(_calib_preview)


func _draw_calibration_preview() -> void:
	if not _calib_preview:
		return
	var sett := _sett()
	var br: float = float(sett.get_val("brightness", 1.08)) if sett else 1.08
	var gm: float = float(sett.get_val("gamma", 1.0)) if sett else 1.0
	var ct: float = float(sett.get_val("contrast", 1.0)) if sett else 1.0
	var sz: Vector2 = _calib_preview.size
	if sz.x < 20.0:
		return

	var eval_shade := func(base_v: float) -> Color:
		var g: float = pow(clampf(base_v, 0.0, 1.0), 1.0 / clampf(gm, 0.55, 1.75)) * clampf(br, 0.6, 1.75)
		g = clampf((g - 0.5) * clampf(ct, 0.65, 1.55) + 0.5, 0.0, 1.0)
		return Color(g * 0.92, g * 0.98, g * 1.04)

	# Dark background field
	_calib_preview.draw_rect(Rect2(Vector2.ZERO, sz), eval_shade.call(0.045), true)
	# 5 stepped dark-to-mid swatches
	var steps := [0.07, 0.11, 0.17, 0.28, 0.45]
	var sw: float = (sz.x * 0.58) / float(steps.size())
	for i: int in range(steps.size()):
		var r := Rect2(Vector2(10.0 + float(i) * (sw + 4.0), 14.0), Vector2(sw - 4.0, sz.y - 28.0))
		_calib_preview.draw_rect(r, eval_shade.call(steps[i]), true)
		_calib_preview.draw_rect(r, Color(0.24, 0.28, 0.30, 0.5), false, 1.0)

	# Right side: Dark figure silhouette against slightly lighter night fog background (must be clearly distinguishable!)
	var fig_bg := Rect2(Vector2(sz.x * 0.66, 8.0), Vector2(sz.x * 0.31, sz.y - 16.0))
	_calib_preview.draw_rect(fig_bg, eval_shade.call(0.145), true)
	var fig_col: Color = eval_shade.call(0.072)
	var cx: float = fig_bg.position.x + fig_bg.size.x * 0.5
	var cy: float = fig_bg.position.y + fig_bg.size.y * 0.5
	_calib_preview.draw_circle(Vector2(cx, cy - 16.0), 9.0, fig_col) # Head
	_calib_preview.draw_rect(Rect2(Vector2(cx - 12.0, cy - 5.0), Vector2(24.0, 26.0)), fig_col, true) # Torso
	_calib_preview.draw_rect(Rect2(Vector2(cx - 9.0, cy + 21.0), Vector2(7.0, 14.0)), fig_col, true) # Left leg
	_calib_preview.draw_rect(Rect2(Vector2(cx + 2.0, cy + 21.0), Vector2(7.0, 14.0)), fig_col, true) # Right leg
	_calib_preview.draw_rect(fig_bg, Color(0.32, 0.36, 0.38, 0.65), false, 1.0)


func _build_graphics_tab() -> void:
	var box := _make_tab(_tr("opt_graphics", "GRAPHICS"))
	var sett := _sett()
	var ps1_res_vals: Array[String] = ["426x240", "512x288", "640x360"]
	var ps1_res_labels: Array[String] = ["426x240 (Authentic PS1)", "512x288 (Enhanced Pixelated)", "640x360 (Higher-Res Retro)"]
	var cur_ps1_res: String = str(sett.get_val("ps1_resolution", "512x288")) if sett else "512x288"
	_add_option_row(box, "Internal 3D Resolution", ps1_res_labels, maxi(0, ps1_res_vals.find(cur_ps1_res)), func(i: int):
		if _sett():
			_sett().set_val("ps1_resolution", ps1_res_vals[i])
	)
	var sh_vals: Array[String] = ["blocky", "sharp", "off"]
	var sh_labels: Array[String] = ["PS1 Blocky Shadows", "Sharp Retro Shadows", "Off"]
	var cur_sh: String = str(sett.get_val("ps1_shadow_quality", "blocky")) if sett else "blocky"
	_add_option_row(box, "Shadow Style", sh_labels, maxi(0, sh_vals.find(cur_sh)), func(i: int):
		if _sett():
			_sett().set_val("ps1_shadow_quality", sh_vals[i])
	)
	_add_slider_row(box, "PS1 Ordered Dithering", 0.0, 1.0, 0.05, float(sett.get_val("ps1_dithering", 0.72)) if sett else 0.72, "%.0f%%", func(v: float):
		if _sett():
			_sett().set_val("ps1_dithering", v)
	)
	_add_slider_row(box, "PS1 Vertex Jitter", 0.0, 1.0, 0.05, float(sett.get_val("ps1_vertex_jitter", 0.55)) if sett else 0.55, "%.0f%%", func(v: float):
		if _sett():
			_sett().set_val("ps1_vertex_jitter", v)
	)
	var cd_vals := [15, 18, 24]
	var cur_cd: int = int(sett.get_val("ps1_color_depth", 15)) if sett else 15
	_add_option_row(box, "Retro Color Depth", ["15-bit PS1 (RGB555)", "18-bit Retro", "24-bit Full"], maxi(0, cd_vals.find(cur_cd)), func(i: int):
		if _sett():
			_sett().set_val("ps1_color_depth", cd_vals[i])
	)
	_add_option_row(box, _tr("opt_quality", "Overall Quality"), ["Low", "Medium", "High"], int(sett.get_val("quality_preset", 2)) if sett else 2, func(i: int):
		if _sett():
			_sett().set_val("quality_preset", i)
	)
	_add_check_row(box, _tr("opt_shadows", "Dynamic Shadows"), bool(sett.get_val("shadows", true)) if sett else true, func(v: bool):
		if _sett():
			_sett().set_val("shadows", v)
	)
	_add_check_row(box, _tr("opt_fog", "Atmospheric Fog"), bool(sett.get_val("fog_enabled", true)) if sett else true, func(v: bool):
		if _sett():
			_sett().set_val("fog_enabled", v)
	)
	_add_slider_row(box, "Fog Intensity", 0.4, 1.4, 0.05, float(sett.get_val("fog_intensity", 1.0)) if sett else 1.0, "%.0f%%", func(v: float):
		if _sett():
			_sett().set_val("fog_intensity", v)
	)
	_add_slider_row(box, "Flashlight Intensity", 0.6, 1.6, 0.05, float(sett.get_val("flashlight_intensity", 1.0)) if sett else 1.0, "%.0f%%", func(v: float):
		if _sett():
			_sett().set_val("flashlight_intensity", v)
	)
	_add_option_row(box, _tr("opt_aa", "Anti-Aliasing (MSAA)"), ["Off", "2x MSAA", "4x MSAA"], int(sett.get_val("msaa", 1)) if sett else 1, func(i: int):
		if _sett():
			_sett().set_val("msaa", i)
	)
	_add_slider_row(box, _tr("opt_view_dist", "View Distance"), 120.0, 260.0, 10.0, float(sett.get_val("view_distance", 220.0)) if sett else 220.0, "%.0fm", func(v: float):
		if _sett():
			_sett().set_val("view_distance", v)
	)


func _build_audio_tab() -> void:
	var box := _make_tab(_tr("opt_audio", "AUDIO"))
	var sett := _sett()
	for pair: Array in [
		["vol_master", _tr("opt_vol_master", "Master Volume")],
		["vol_music", _tr("opt_vol_music", "Music Volume")],
		["vol_env", _tr("opt_vol_env", "Environmental Audio")],
		["vol_dialogue", _tr("opt_vol_dialogue", "Dialogue Volume")],
		["vol_sfx", _tr("opt_vol_sfx", "Sound Effects")],
		["vol_headphones", _tr("opt_vol_headphones", "Walkman / Headphone Music")],
	]:
		var k: String = str(pair[0])
		_add_slider_row(box, str(pair[1]), 0.0, 1.0, 0.05, float(sett.get_val(k, 0.85)) if sett else 0.85, "%.0f%%", func(v: float):
			if _sett():
				_sett().set_val(k, v)
		)
	_add_check_row(box, _tr("opt_ui_sfx_reduce", "Reduce Menu UI Sound Effects"), bool(sett.get_val("reduce_ui_sfx", false)) if sett else false, func(v: bool):
		if _sett():
			_sett().set_val("reduce_ui_sfx", v)
	)


func _build_gameplay_tab() -> void:
	var box := _make_tab(_tr("opt_gameplay", "GAMEPLAY"))
	var sett := _sett()
	_add_slider_row(box, _tr("opt_mouse_sens", "Mouse Sensitivity"), 0.3, 2.5, 0.1, float(sett.get_val("mouse_sensitivity", 1.0)) if sett else 1.0, "%.1fx", func(v: float):
		if _sett():
			_sett().set_val("mouse_sensitivity", v)
	)
	_add_slider_row(box, _tr("opt_ctrl_sens", "Controller Sensitivity"), 0.3, 2.5, 0.1, float(sett.get_val("controller_sensitivity", 1.0)) if sett else 1.0, "%.1fx", func(v: float):
		if _sett():
			_sett().set_val("controller_sensitivity", v)
	)
	_add_check_row(box, _tr("opt_invert_y", "Invert Y-Axis"), bool(sett.get_val("invert_y", false)) if sett else false, func(v: bool):
		if _sett():
			_sett().set_val("invert_y", v)
	)
	_add_slider_row(box, _tr("opt_head_bob", "Head Bob Intensity"), 0.0, 1.5, 0.1, float(sett.get_val("head_bob", 1.0)) if sett else 1.0, "%.1fx", func(v: float):
		if _sett():
			_sett().set_val("head_bob", v)
	)
	_add_slider_row(box, _tr("opt_cam_shake", "Camera Shake"), 0.0, 1.0, 0.1, float(sett.get_val("camera_shake", 1.0)) if sett else 1.0, "%.1fx", func(v: float):
		if _sett():
			_sett().set_val("camera_shake", v)
	)
	_add_check_row(box, _tr("opt_toggle_sprint", "Toggle Sprint"), bool(sett.get_val("toggle_sprint", false)) if sett else false, func(v: bool):
		if _sett():
			_sett().set_val("toggle_sprint", v)
	)
	_add_check_row(box, _tr("opt_hold_interact", "Hold-to-Interact Mode"), bool(sett.get_val("hold_interact", false)) if sett else false, func(v: bool):
		if _sett():
			_sett().set_val("hold_interact", v)
	)
	_add_check_row(box, "Skip Night 1 First-Time Tutorial", bool(sett.get_val("skip_tutorial", false)) if sett else false, func(v: bool):
		if _sett():
			_sett().set_val("skip_tutorial", v)
	)

	var loc := get_node_or_null("/root/LocalizationManager")
	for pair: Array in [
		["notebook_key", _tr("opt_remap_notebook", "Notebook Key")],
		["toggle_headphones", _tr("opt_remap_headphones", "Headphones Key")],
		["flashlight", _tr("opt_remap_flashlight", "Flashlight Key")],
	]:
		var act := str(pair[0])
		var hb := HBoxContainer.new()
		box.add_child(hb)
		var lbl := Label.new()
		lbl.text = str(pair[1])
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(lbl)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 32)
		btn.text = "[%s]" % (loc.get_key_label(act) if loc else act.to_upper())
		btn.pressed.connect(func():
			_rebinding_action = act
			btn.text = "PRESS KEY..."
		)
		_rebind_buttons[act] = btn
		hb.add_child(btn)


func _build_accessibility_tab() -> void:
	var box := _make_tab(_tr("opt_accessibility", "ACCESSIBILITY"))
	var sett := _sett()
	var nav_vals: Array[String] = ["off", "subtle", "clear"]
	var nav_labels: Array[String] = ["OFF (Notebook & Signs Only)", "SUBTLE (Reflective Markers)", "CLEAR (Brief Lost-Player Cue)"]
	var cur_nav: String = str(sett.get_val("nav_assist", "subtle")) if sett else "subtle"
	_add_option_row(box, _tr("opt_nav_assist", "Navigation Assistance"), nav_labels, maxi(0, nav_vals.find(cur_nav)), func(i: int):
		if _sett():
			_sett().set_val("nav_assist", nav_vals[i])
	)
	_add_option_row(box, _tr("opt_sub_size", "Subtitle Size"), ["Small", "Medium", "Large"], int(sett.get_val("subtitle_size", 1)) if sett else 1, func(i: int):
		if _sett():
			_sett().set_val("subtitle_size", i)
	)
	_add_check_row(box, _tr("opt_sub_bg", "Subtitle Background Box"), bool(sett.get_val("subtitle_bg", true)) if sett else true, func(v: bool):
		if _sett():
			_sett().set_val("subtitle_bg", v)
	)
	_add_check_row(box, _tr("opt_sub_speaker", "Show Speaker Name"), bool(sett.get_val("subtitle_speaker", true)) if sett else true, func(v: bool):
		if _sett():
			_sett().set_val("subtitle_speaker", v)
	)
	_add_check_row(box, _tr("opt_high_contrast", "High Contrast UI"), bool(sett.get_val("high_contrast", false)) if sett else false, func(v: bool):
		if _sett():
			_sett().set_val("high_contrast", v)
			_rebuild_ui()
	)
	_add_option_row(box, _tr("opt_prompt_size", "Interaction Prompt Size"), ["Normal", "Medium", "Large"], int(sett.get_val("prompt_size", 1)) if sett else 1, func(i: int):
		if _sett():
			_sett().set_val("prompt_size", i)
	)
	_add_check_row(box, _tr("opt_reduce_shake", "Reduce Motion / Camera Shake"), bool(sett.get_val("reduce_shake", false)) if sett else false, func(v: bool):
		if _sett():
			_sett().set_val("reduce_shake", v)
	)
	_add_slider_row(box, _tr("opt_film_grain", "Analog Film Grain / CRT"), 0.0, 1.0, 0.05, float(sett.get_val("film_grain", 0.28)) if sett else 0.28, "%.0f%%", func(v: float):
		if _sett():
			_sett().set_val("film_grain", v)
	)
	_add_check_row(box, _tr("opt_audio_cues", "Audio Cue Visual Captions"), bool(sett.get_val("audio_cues", false)) if sett else false, func(v: bool):
		if _sett():
			_sett().set_val("audio_cues", v)
	)
	_add_check_row(box, _tr("opt_show_sanity", "Show Psychological Strain Meter"), bool(sett.get_val("show_sanity_meter", false)) if sett else false, func(v: bool):
		if _sett():
			_sett().set_val("show_sanity_meter", v)
	)


func _build_language_tab() -> void:
	var box := _make_tab(_tr("opt_language", "LANGUAGE"))
	var sett := _sett()
	var codes := ["en", "sk", "cs"]
	var names: Array[String] = ["English", "Slovenčina", "Čeština"]
	var cur := str(sett.get_val("language", "en")) if sett else "en"
	_add_option_row(box, _tr("opt_lang_select", "Interface & Subtitles Language"), names, maxi(0, codes.find(cur)), func(i: int):
		if _sett():
			_sett().set_val("language", codes[i])
			_sett().save_settings()
	)


func _input(event: InputEvent) -> void:
	if _rebinding_action.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		var code: int = k.physical_keycode if k.physical_keycode != 0 else k.keycode
		if code != KEY_ESCAPE and _sett():
			_sett().remap_key(_rebinding_action, code)
		var btn: Button = _rebind_buttons.get(_rebinding_action, null) as Button
		var loc := get_node_or_null("/root/LocalizationManager")
		if btn and loc:
			btn.text = "[%s]" % loc.get_key_label(_rebinding_action)
		_rebinding_action = ""
		get_viewport().set_input_as_handled()
