extends Control

const Blok14BuilderScript = preload("res://scripts/world/blok14_builder.gd")
const ThemeLib = preload("res://scripts/ui/javor_theme.gd")
const OptionsMenuScript = preload("res://scripts/ui/options_menu.gd")
const SaveLoadScript = preload("res://scripts/ui/save_load_panel.gd")
const ChapterOverlayScript = preload("res://scripts/ui/chapter_loading_overlay.gd")
const RetroRenderScript = preload("res://scripts/systems/retro_rendering_controller.gd")

var crt_layer: CanvasLayer
var crt_rect: ColorRect
var crt_mat: ShaderMaterial
var retro_render: Node

var preview_viewport: SubViewport
var preview_world: Node3D
var preview_cam: Camera3D
var _desk_lamp: SpotLight3D
var _crt_glow_light: OmniLight3D
var _crt_screen_mat: StandardMaterial3D
var _clock_hand: Node3D
var _distant_win_mat: StandardMaterial3D
var _window_silhouette: Node3D

var _ui_root: Control
var _logo_rect: TextureRect
var _setting_lbl: Label
var main_panel: VBoxContainer
var _right_container: Control
var _options_panel: PanelContainer
var _saveload_panel: PanelContainer
var _newgame_panel: PanelContainer
var _credits_panel: PanelContainer
var _chapter_overlay: CanvasLayer

var continue_btn: Button
var new_btn: Button
var load_btn: Button
var options_btn: Button
var credits_btn: Button
var exit_btn: Button
var dev_btn: Button

var _selected_diff: String = "standard"
var _time_acc: float = 0.0
var _dev_browser_layer: CanvasLayer = null


func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	theme = ThemeLib.get_theme()
	_build_3d_office_background()
	_build_crt_overlay()
	_build_menu_ui()
	retro_render = RetroRenderScript.new()
	add_child(retro_render)
	retro_render.setup_retro_rendering(preview_viewport, crt_mat, preview_viewport)
	_refresh_localized_texts()
	_refresh_button_states()

	var loc := get_node_or_null("/root/LocalizationManager")
	if loc and loc.has_signal("language_changed"):
		loc.language_changed.connect(func(_l: String): _refresh_localized_texts())
	var sett := get_node_or_null("/root/SettingsManager")
	if sett and sett.has_signal("settings_changed"):
		sett.settings_changed.connect(_apply_visual_settings)
	_apply_visual_settings()
	AudioSynth.start_menu_music()


func _tr(k: String, fb: String = "") -> String:
	var loc := get_node_or_null("/root/LocalizationManager")
	return loc.tr_key(k, fb) if loc and loc.has_method("tr_key") else (fb if not fb.is_empty() else k)


func _apply_visual_settings() -> void:
	var sett := get_node_or_null("/root/SettingsManager")
	if sett and crt_mat:
		var grain: float = float(sett.get_val("film_grain", 0.28))
		crt_mat.set_shader_parameter("crt_intensity", grain)
	if sett:
		theme = ThemeLib.get_theme(bool(sett.get_val("high_contrast", false)))


func _process(delta: float) -> void:
	_time_acc += delta
	if crt_mat:
		crt_mat.set_shader_parameter("distortion", 0.055 + 0.018 * sin(_time_acc * 1.4))
	if _desk_lamp:
		var dip: float = 0.65 if fmod(_time_acc, 11.5) > 11.2 else 1.0
		_desk_lamp.light_energy = (3.6 + 0.14 * sin(_time_acc * 4.5)) * dip
	if _crt_glow_light:
		_crt_glow_light.light_energy = 0.95 + 0.22 * sin(_time_acc * 19.0)
	if _crt_screen_mat:
		var scan_pulse: float = 0.72 + 0.28 * sin(_time_acc * 17.0)
		_crt_screen_mat.albedo_color = Color(0.32 * scan_pulse, 0.78 * scan_pulse, 0.44 * scan_pulse)
	if _window_silhouette:
		# Part 4.1: Subtle distant human silhouette briefly appearing outside the rain window every ~18s!
		var cyc: float = fmod(_time_acc, 18.0)
		_window_silhouette.visible = (cyc > 11.5 and cyc < 15.8)
		if _window_silhouette.visible:
			_window_silhouette.position.x = -1.6 + (cyc - 11.5) * 0.42
	if _clock_hand:
		_clock_hand.rotation_degrees.z = -fmod(_time_acc * 6.0, 360.0)
	if preview_cam:
		preview_cam.position = Vector3(0.04 * sin(_time_acc * 0.22), 1.48 + 0.012 * sin(_time_acc * 0.45), 1.85)
		preview_cam.look_at(Vector3(0.15, 1.15, -3.5), Vector3.UP)


func _build_3d_office_background() -> void:
	var fallback_bg := ColorRect.new()
	fallback_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fallback_bg.color = Color(0.025, 0.032, 0.036, 1.0)
	fallback_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fallback_bg)

	var svc := SubViewportContainer.new()
	svc.name = "Menu3DBackdrop"
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.stretch = true
	svc.stretch_shrink = 2 # Crisp PS1 low-res 3D rendering inside SubViewportContainer!
	svc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # Crisp PS1 nearest-neighbor 3D upscaling!
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)

	preview_viewport = SubViewport.new()
	preview_viewport.name = "MenuPreviewViewport"
	preview_viewport.msaa_3d = Viewport.MSAA_DISABLED
	preview_viewport.positional_shadow_atlas_size = 512
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED if DisplayServer.get_name() == "headless" else SubViewport.UPDATE_ALWAYS
	svc.add_child(preview_viewport)

	# Keep MenuBlok14Showcase node path intact for residential courtyard + rain + distant Paneláky!
	preview_world = Blok14BuilderScript.new()
	preview_world.name = "MenuBlok14Showcase"
	preview_viewport.add_child(preview_world)
	preview_world.build_world(true)

	# Foreground Security Office Interior Frame positioned directly around camera (Z = +2 .. -1)
	var office := Node3D.new()
	office.name = "MenuSecurityOfficeSet"
	office.position = Vector3(0.0, 0.0, 0.0)
	preview_viewport.add_child(office)

	var dark_wall := StandardMaterial3D.new()
	dark_wall.albedo_color = Color(0.11, 0.13, 0.12)
	dark_wall.roughness = 0.88
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.24, 0.17, 0.12)
	wood_mat.roughness = 0.72
	var glass_mat := StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.35, 0.44, 0.50, 0.18)
	glass_mat.roughness = 0.12

	# Office Window Framing looking north into rain-soaked courtyard & Panelák blocks
	_add_box(office, Vector3(-2.6, 1.4, -0.8), Vector3(1.8, 3.0, 0.25), dark_wall)
	_add_box(office, Vector3(2.8, 1.4, -0.8), Vector3(2.0, 3.0, 0.25), dark_wall)
	_add_box(office, Vector3(0.0, 0.42, -0.8), Vector3(4.0, 0.85, 0.25), dark_wall)
	_add_box(office, Vector3(0.0, 2.55, -0.8), Vector3(4.0, 0.70, 0.25), dark_wall)
	_add_box(office, Vector3(0.0, 1.50, -0.8), Vector3(3.6, 1.35, 0.03), glass_mat)
	_add_box(office, Vector3(0.15, 1.50, -0.78), Vector3(0.06, 1.35, 0.08), wood_mat)

	# Real Guard Desk + Iconic 1996 Equipment Assets (CRT, Notebook, Keys, Flashlight, Headphones, Phone)
	_spawn_set_glb(office, "guard_booth_desk", Vector3(0.25, 0.0, 0.15), Vector3(0, 180, 0))
	_spawn_set_glb(office, "tesla_crt_monitor", Vector3(0.85, 0.92, -0.05), Vector3(0, -24, 0))
	_spawn_set_glb(office, "rotary_phone", Vector3(-0.48, 0.92, 0.10), Vector3(0, 18, 0))
	_spawn_set_glb(office, "vm_notebook", Vector3(0.12, 0.95, 0.28), Vector3(-86, 16, 0), Vector3(1.25, 1.25, 1.25))
	_spawn_set_glb(office, "vm_keys", Vector3(-0.18, 0.96, 0.34), Vector3(88, 35, 0), Vector3(1.4, 1.4, 1.4))
	_spawn_set_glb(office, "vm_flashlight", Vector3(0.45, 0.96, 0.35), Vector3(0, 52, 0), Vector3(1.25, 1.25, 1.25))
	_spawn_set_glb(office, "vm_headphones", Vector3(0.68, 0.98, 0.26), Vector3(82, -28, 0), Vector3(1.2, 1.2, 1.2))

	# Moving Wall Clock on right office pillar
	var clk_face := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.20
	cyl.bottom_radius = 0.20
	cyl.height = 0.04
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.76, 0.72, 0.62)
	cyl.material = cmat
	clk_face.mesh = cyl
	clk_face.position = Vector3(1.92, 2.02, -0.65)
	clk_face.rotation_degrees = Vector3(90, 0, 0)
	office.add_child(clk_face)

	_clock_hand = Node3D.new()
	_clock_hand.position = Vector3(1.92, 2.02, -0.62)
	office.add_child(_clock_hand)
	var hand_m := _add_box(_clock_hand, Vector3(0.0, 0.06, 0.0), Vector3(0.015, 0.14, 0.01), dark_wall)
	hand_m.name = "ClockSecondHand"

	# Distant Illuminated Apartment Window silhouette outside the office window!
	_distant_win_mat = StandardMaterial3D.new()
	_distant_win_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_distant_win_mat.albedo_color = Color(0.95, 0.72, 0.35)
	_add_box(office, Vector3(-1.8, 12.2, -32.0), Vector3(1.5, 1.4, 0.2), _distant_win_mat)

	# Animated CRT Phosphor Screen Face on Desk Monitor
	_crt_screen_mat = StandardMaterial3D.new()
	_crt_screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_crt_screen_mat.albedo_color = Color(0.32, 0.78, 0.44)
	_add_box(office, Vector3(0.81, 1.24, 0.14), Vector3(0.38, 0.28, 0.02), _crt_screen_mat)

	# Subtle Distant Human Silhouette outside the rain window (PS1 Roman Král figure!)
	var sil_p := "res://assets/models/char_roman.glb"
	if ResourceLoader.exists(sil_p):
		var spacked: Resource = load(sil_p)
		if spacked is PackedScene:
			var sinst := (spacked as PackedScene).instantiate()
			if sinst is Node3D:
				_window_silhouette = sinst as Node3D
				_window_silhouette.name = "MenuWindowSilhouette"
				_window_silhouette.position = Vector3(-1.4, 0.0, -7.8)
				_window_silhouette.rotation_degrees.y = 18.0
				_window_silhouette.visible = false
				office.add_child(_window_silhouette)

	# Strong Shadow-Casting Desk SpotLight + CRT Phosphor Glow (stark PS1 office shadows!)
	_desk_lamp = SpotLight3D.new()
	_desk_lamp.position = Vector3(-0.35, 1.92, 0.45)
	_desk_lamp.rotation_degrees = Vector3(-68.0, -14.0, 0.0)
	_desk_lamp.light_color = Color(0.98, 0.74, 0.36)
	_desk_lamp.light_energy = 3.6
	_desk_lamp.spot_range = 6.8
	_desk_lamp.spot_angle = 52.0
	_desk_lamp.shadow_enabled = true
	_desk_lamp.shadow_blur = 0.22
	office.add_child(_desk_lamp)

	_crt_glow_light = OmniLight3D.new()
	_crt_glow_light.position = Vector3(0.75, 1.25, 0.32)
	_crt_glow_light.light_color = Color(0.38, 0.84, 0.50)
	_crt_glow_light.light_energy = 0.95
	_crt_glow_light.omni_range = 3.6
	office.add_child(_crt_glow_light)

	preview_cam = Camera3D.new()
	preview_cam.name = "MenuShowcaseCam"
	preview_cam.fov = 58.0
	preview_cam.far = 160.0
	preview_cam.position = Vector3(0.0, 1.48, 1.85)
	preview_viewport.add_child(preview_cam)
	preview_cam.look_at(Vector3(0.15, 1.15, -3.5), Vector3.UP)
	preview_cam.current = true


func _add_box(parent: Node3D, pos: Vector3, sz: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = sz
	m.mesh = b
	m.material_override = mat
	m.position = pos
	parent.add_child(m)
	return m


func _spawn_set_glb(parent: Node3D, nm: String, pos: Vector3, rot: Vector3, sc: Vector3 = Vector3.ONE) -> void:
	var p := "res://assets/models/%s.glb" % nm
	if not ResourceLoader.exists(p):
		return
	var packed: Resource = load(p)
	if packed is PackedScene:
		var inst := (packed as PackedScene).instantiate()
		if inst is Node3D:
			(inst as Node3D).position = pos
			(inst as Node3D).rotation_degrees = rot
			(inst as Node3D).scale = sc
			parent.add_child(inst)


func _build_crt_overlay() -> void:
	crt_layer = CanvasLayer.new()
	crt_layer.name = "MenuCRTLayer"
	crt_layer.layer = 5 # Apply PS1 dithering & RGB555 quantization BELOW MenuUILayer (layer 10) so text stays crisp!
	add_child(crt_layer)

	crt_rect = ColorRect.new()
	crt_rect.name = "MenuCRTRect"
	crt_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader: Shader = load("res://shaders/crt_vhs.gdshader")
	if shader:
		crt_mat = ShaderMaterial.new()
		crt_mat.shader = shader
		crt_mat.set_shader_parameter("distortion", 0.06)
		crt_mat.set_shader_parameter("crt_intensity", 0.28)
		crt_rect.material = crt_mat
	else:
		crt_rect.color = Color(0, 0, 0, 0)
	crt_layer.add_child(crt_rect)


func _build_menu_ui() -> void:
	var ui_layer := CanvasLayer.new()
	ui_layer.name = "MenuUILayer"
	ui_layer.layer = 10
	add_child(ui_layer)

	_ui_root = Control.new()
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.theme = ThemeLib.get_theme()
	ui_layer.add_child(_ui_root)

	# Left dark analog column scrim (leaves right 60% clear to admire live 3D Security Office!)
	var left_panel := PanelContainer.new()
	left_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left_panel.offset_left = 36
	left_panel.offset_top = 34
	left_panel.offset_right = 468
	left_panel.offset_bottom = -34
	left_panel.add_theme_stylebox_override("panel", ThemeLib.make_box(Color(0.055, 0.068, 0.072, 0.84), ThemeLib.COL_WARM_BORDER, 1, 22))
	_ui_root.add_child(left_panel)

	main_panel = VBoxContainer.new()
	main_panel.add_theme_constant_override("separation", 10)
	left_panel.add_child(main_panel)

	var term_hdr := Label.new()
	term_hdr.text = "TESLA-OS 96 // SECURITY OFFICE TERMINAL [01]   ● REC"
	term_hdr.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	term_hdr.add_theme_font_size_override("font_size", 11)
	if ThemeLib.get_mono_bold_font():
		term_hdr.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
	main_panel.add_child(term_hdr)

	# Official 1997 Pixelated Retro Logo Texture
	_logo_rect = TextureRect.new()
	_logo_rect.custom_minimum_size = Vector2(380, 114)
	_logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	main_panel.add_child(_logo_rect)

	_setting_lbl = Label.new()
	_setting_lbl.add_theme_color_override("font_color", ThemeLib.COL_TEXT_DIM)
	_setting_lbl.add_theme_font_size_override("font_size", 12)
	if ThemeLib.get_mono_font():
		_setting_lbl.add_theme_font_override("font", ThemeLib.get_mono_font())
	main_panel.add_child(_setting_lbl)

	var sep := HSeparator.new()
	main_panel.add_child(sep)

	continue_btn = _make_btn("CONTINUE", "icon_objective")
	continue_btn.pressed.connect(_on_continue_pressed)
	main_panel.add_child(continue_btn)

	new_btn = _make_btn("NEW GAME", "icon_notebook")
	new_btn.pressed.connect(_open_new_game_panel)
	main_panel.add_child(new_btn)

	load_btn = _make_btn("LOAD GAME", "icon_save")
	load_btn.pressed.connect(_open_load_panel)
	main_panel.add_child(load_btn)

	options_btn = _make_btn("OPTIONS", "icon_settings")
	options_btn.pressed.connect(_open_options_panel)
	main_panel.add_child(options_btn)

	credits_btn = _make_btn("CREDITS", "icon_building")
	credits_btn.pressed.connect(_open_credits_panel)
	main_panel.add_child(credits_btn)

	if OS.is_debug_build():
		dev_btn = _make_btn("[DEV] ASSET MANAGER (F9)", "icon_map")
		dev_btn.pressed.connect(_toggle_dev_asset_browser)
		main_panel.add_child(dev_btn)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.add_child(spacer)

	exit_btn = _make_btn("EXIT", "icon_door")
	exit_btn.pressed.connect(func():
		AudioSynth.play_ui_sfx("ui_press")
		get_tree().quit()
	)
	main_panel.add_child(exit_btn)

	# Right Overlay Host Container (for New Game / Load Game / Options / Credits)
	_right_container = Control.new()
	_right_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_right_container.offset_left = 496
	_right_container.offset_top = 48
	_right_container.offset_right = -36
	_right_container.offset_bottom = -48
	_right_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(_right_container)

	_options_panel = OptionsMenuScript.new()
	_options_panel.visible = false
	_options_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_options_panel.closed.connect(_close_subpanels)
	_right_container.add_child(_options_panel)

	_saveload_panel = SaveLoadScript.new()
	_saveload_panel.visible = false
	_saveload_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_saveload_panel.slot_chosen.connect(_on_slot_chosen)
	_saveload_panel.closed.connect(_close_subpanels)
	_right_container.add_child(_saveload_panel)

	_build_new_game_panel()
	_build_credits_panel()

	_chapter_overlay = ChapterOverlayScript.new()
	add_child(_chapter_overlay)


func _build_new_game_panel() -> void:
	_newgame_panel = PanelContainer.new()
	_newgame_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_newgame_panel.visible = false
	_right_container.add_child(_newgame_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_newgame_panel.add_child(vb)

	var hdr := Label.new()
	hdr.name = "NGHeader"
	hdr.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	hdr.add_theme_font_size_override("font_size", 20)
	if ThemeLib.get_mono_bold_font():
		hdr.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
	vb.add_child(hdr)

	var intro := Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = "Nový Brod, November 1996. Martin Kováč begins a temporary six-night watch at Sídlisko Javor. Listen closely, keep your logbook accurate, and decide when it is safe to put on your headphones."
	vb.add_child(intro)

	var diff_desc := Label.new()
	diff_desc.name = "DiffDesc"
	diff_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diff_desc.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	diff_desc.text = _tr("diff_standard_desc", "Intended experience.")

	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 8)
	vb.add_child(diff_row)
	for d_id: String in ["story", "standard", "intense"]:
		var b := Button.new()
		b.text = _tr("diff_" + d_id, d_id.to_upper())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var did := d_id
		b.pressed.connect(func():
			AudioSynth.play_ui_sfx("ui_press")
			_selected_diff = did
			diff_desc.text = _tr("diff_" + did + "_desc", "")
		)
		diff_row.add_child(b)
	vb.add_child(diff_desc)

	var slot_lbl := Label.new()
	slot_lbl.text = "Choose record slot to begin Shift 1:"
	slot_lbl.add_theme_color_override("font_color", ThemeLib.COL_TEXT_DIM)
	vb.add_child(slot_lbl)

	for s_idx: int in range(1, 4):
		var sb_btn := Button.new()
		sb_btn.text = "START SHIFT IN RECORD SLOT #%d" % s_idx
		sb_btn.custom_minimum_size = Vector2(0, 42)
		var slot_i := s_idx
		sb_btn.pressed.connect(func(): _launch_new_game(slot_i))
		vb.add_child(sb_btn)

	var back_b := Button.new()
	back_b.text = _tr("menu_back", "BACK")
	back_b.pressed.connect(_close_subpanels)
	vb.add_child(back_b)


func _build_credits_panel() -> void:
	_credits_panel = PanelContainer.new()
	_credits_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_credits_panel.visible = false
	_right_container.add_child(_credits_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_credits_panel.add_child(vb)

	var t := Label.new()
	t.name = "CreditsTitle"
	t.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	t.add_theme_font_size_override("font_size", 20)
	vb.add_child(t)

	var body := Label.new()
	body.name = "CreditsBody"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(body)

	var back_b := Button.new()
	back_b.text = _tr("menu_back", "BACK")
	back_b.pressed.connect(_close_subpanels)
	vb.add_child(back_b)


func _refresh_localized_texts() -> void:
	var loc := get_node_or_null("/root/LocalizationManager")
	var lang: String = loc.current_lang if loc else "en"
	var logo_path := "res://assets/graphics/logos/logo_night_shift.png" if lang == "en" else "res://assets/graphics/logos/logo_nocna_sluzba.png"
	if _logo_rect and ResourceLoader.exists(logo_path):
		var tx: Resource = load(logo_path)
		if tx is Texture2D:
			_logo_rect.texture = tx as Texture2D

	if _setting_lbl:
		_setting_lbl.text = _tr("setting_tag", "SÍDLISKO JAVOR • NOVÝ BROD • NOVEMBER 1996")
	if continue_btn:
		continue_btn.text = "  " + _tr("menu_continue", "CONTINUE")
	if new_btn:
		new_btn.text = "  " + _tr("menu_new_game", "NEW GAME")
	if load_btn:
		load_btn.text = "  " + _tr("menu_load_game", "LOAD GAME")
	if options_btn:
		options_btn.text = "  " + _tr("menu_options", "OPTIONS")
	if credits_btn:
		credits_btn.text = "  " + _tr("menu_credits", "CREDITS")
	if dev_btn:
		dev_btn.text = "  " + _tr("menu_dev_assets", "[DEV] ASSET MANAGER (F9)")
	if exit_btn:
		exit_btn.text = "  " + _tr("menu_exit", "EXIT")

	var ng_hdr := _newgame_panel.find_child("NGHeader", true, false) as Label if _newgame_panel else null
	if ng_hdr:
		ng_hdr.text = _tr("diff_title", "SELECT SHIFT DIFFICULTY & SAVE SLOT")
	var cr_t := _credits_panel.find_child("CreditsTitle", true, false) as Label if _credits_panel else null
	var cr_b := _credits_panel.find_child("CreditsBody", true, false) as Label if _credits_panel else null
	if cr_t:
		cr_t.text = _tr("credits_title", "CREDITS")
	if cr_b:
		cr_b.text = _tr("credits_body", "")


func _refresh_button_states() -> void:
	var sm := get_node_or_null("/root/SaveManager")
	var has_save: bool = (sm.has_any_save() if sm else false) or GameState.has_saved_run()
	if continue_btn:
		continue_btn.disabled = not has_save
		if has_save and DisplayServer.get_name() != "headless":
			continue_btn.grab_focus()
		elif new_btn and DisplayServer.get_name() != "headless":
			new_btn.grab_focus()


func _close_subpanels() -> void:
	for p: Control in [_options_panel, _saveload_panel, _newgame_panel, _credits_panel]:
		if p:
			p.visible = false
	_refresh_button_states()


func _open_new_game_panel() -> void:
	AudioSynth.play_ui_sfx("ui_press")
	_close_subpanels()
	_newgame_panel.visible = true


func _open_load_panel() -> void:
	AudioSynth.play_ui_sfx("ui_press")
	_close_subpanels()
	_saveload_panel.open_for_mode("load")
	_saveload_panel.visible = true


func _open_options_panel() -> void:
	AudioSynth.play_ui_sfx("ui_press")
	_close_subpanels()
	_options_panel.visible = true


func _open_credits_panel() -> void:
	AudioSynth.play_ui_sfx("ui_press")
	_close_subpanels()
	_credits_panel.visible = true


func _on_continue_pressed() -> void:
	AudioSynth.play_ui_sfx("ui_press")
	AudioSynth.stop_music()
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		var latest: int = sm.get_latest_slot()
		if latest >= 0 and sm.load_slot(latest):
			_transition_to_main(GameState.current_night)
			return
	if GameState.load_run():
		_transition_to_main(GameState.current_night)


func _on_slot_chosen(slot_idx: int, mode: String) -> void:
	if mode == "load":
		var sm := get_node_or_null("/root/SaveManager")
		if sm and sm.load_slot(slot_idx):
			AudioSynth.stop_music()
			_transition_to_main(GameState.current_night)


func _launch_new_game(slot_idx: int) -> void:
	AudioSynth.play_ui_sfx("ui_press")
	AudioSynth.stop_music()
	var sett := get_node_or_null("/root/SettingsManager")
	if sett:
		sett.set_val("difficulty", _selected_diff)
	var is_intense: bool = (_selected_diff == "intense")
	GameState.start_new_shift(1, is_intense, true)
	var st := get_node_or_null("/root/StoryManager")
	if st and st.has_method("reset_story"):
		st.reset_story()
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		sm.session_playtime_sec = 0.0
		sm.save_slot(slot_idx, "Security Office (Vrátnica)")
	_transition_to_main(1)


func _transition_to_main(night_num: int) -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
	if _chapter_overlay:
		_chapter_overlay.show_chapter_card(night_num, 1.8)
		_chapter_overlay.dismissed.connect(func():
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		, CONNECT_ONE_SHOT)
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _make_btn(label_text: String, icon_name: String = "") -> Button:
	var btn := Button.new()
	btn.text = "  " + label_text
	btn.custom_minimum_size = Vector2(360, 42)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if not icon_name.is_empty():
		var ic := ThemeLib.load_icon(icon_name)
		if ic:
			btn.icon = ic
			btn.expand_icon = false
	btn.mouse_entered.connect(func(): AudioSynth.play_ui_sfx("ui_hover", -12.0))
	return btn


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("dev_asset_browser"):
		_toggle_dev_asset_browser()
	elif event.is_action_pressed("pause"):
		_close_subpanels()


func _toggle_dev_asset_browser() -> void:
	if not OS.is_debug_build():
		return
	if _dev_browser_layer and is_instance_valid(_dev_browser_layer):
		_dev_browser_layer.queue_free()
		_dev_browser_layer = null
		return
	var packed_path := "res://tools/asset_browser/AssetManager.tscn"
	if not ResourceLoader.exists(packed_path):
		return
	var packed: PackedScene = load(packed_path)
	if not packed:
		return
	_dev_browser_layer = CanvasLayer.new()
	_dev_browser_layer.name = "DevAssetBrowserLayer"
	_dev_browser_layer.layer = 60
	add_child(_dev_browser_layer)
	var browser := packed.instantiate()
	_dev_browser_layer.add_child(browser)
	if browser.has_signal("close_requested"):
		browser.connect("close_requested", func():
			if _dev_browser_layer and is_instance_valid(_dev_browser_layer):
				_dev_browser_layer.queue_free()
				_dev_browser_layer = null
		)
