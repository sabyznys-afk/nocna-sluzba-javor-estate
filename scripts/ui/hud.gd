class_name GameHUD
extends Node

const ThemeLib = preload("res://scripts/ui/javor_theme.gd")
const NotebookUIScript = preload("res://scripts/ui/notebook_ui.gd")
const OptionsMenuScript = preload("res://scripts/ui/options_menu.gd")
const SaveLoadScript = preload("res://scripts/ui/save_load_panel.gd")
const DialogueBoxScript = preload("res://scripts/ui/dialogue_box.gd")
const ChapterOverlayScript = preload("res://scripts/ui/chapter_loading_overlay.gd")

signal modal_closed
signal cctv_cycle_requested
signal cctv_select_requested(cam_idx: int)
signal cctv_log_requested
signal choice_made(choice_id: String)
signal dawn_submitted(mode: String)
signal pause_menu_requested(action: String)
signal anomaly_checked_off(anomaly_id: String)
signal notebook_opened_changed(opened: bool)
signal incident_note_submitted(note_text: String)
signal save_slot_requested(slot_idx: int)
signal load_slot_requested(slot_idx: int)
signal hotbar_slot_selected(slot_id: String)
signal tutorial_reopen_requested
signal notebook_section_viewed(section_idx: int)

var ui_layer: CanvasLayer
var crt_layer: CanvasLayer
var crt_rect: ColorRect
var crt_material: ShaderMaterial
var chapter_overlay: CanvasLayer

# Restrained HUD Elements
var quest_panel: PanelContainer
var quest_label: RichTextLabel
var vhs_label: Label
var zone_label: Label
var stats_label: Label
var equip_icon_rect: TextureRect
var headphones_icon_rect: TextureRect
var headphones_label: Label
var sanity_label: Label
var stamina_bar_bg: ColorRect
var stamina_bar_fill: ColorRect
var stamina_state_lbl: Label
var audio_cue_lbl: Label
var tutorial_panel: PanelContainer
var tutorial_label: Label
var control_hint_panel: PanelContainer
var control_hint_label: Label
var prompt_label: Label
var crosshair: ColorRect
var dialogue_box: PanelContainer
var toast_panel: PanelContainer
var toast_label: Label
var hotbar_container: PanelContainer
var hotbar_row: HBoxContainer
var _hotbar_cards: Dictionary = {}
var _hotbar_fade_timer: float = 4.0
var _flashlight_powered: bool = true

const HOTBAR_SLOTS := [
	{"id": "hands", "key": "0", "label": "HANDS", "icon": "icon_hands"},
	{"id": "flashlight", "key": "1", "label": "TORCH", "icon": "icon_flashlight"},
	{"id": "keys", "key": "3", "label": "KEYS", "icon": "icon_keys"},
	{"id": "radio", "key": "4", "label": "RADIO", "icon": "icon_radio"},
	{"id": "notebook", "key": "6", "label": "LOGBOOK", "icon": "icon_notebook"},
	{"id": "taser", "key": "2", "label": "TASER", "icon": "icon_taser"},
	{"id": "watch", "key": "5", "label": "WATCH", "icon": "icon_watch"},
]

# Modals
var modal_backdrop: ColorRect
var notebook_ui: PanelContainer
var options_panel: PanelContainer
var saveload_panel: PanelContainer
var anomaly_panel: PanelContainer
var anomaly_title: Label
var anomaly_desc: Label
var cctv_panel: PanelContainer
var cctv_feed_rect: TextureRect
var cctv_cam_label: Label
var cctv_anom_hint: Label
var choice_panel: PanelContainer
var choice_title: Label
var choice_body: Label
var choice_buttons_box: VBoxContainer
var dawn_panel: PanelContainer
var ending_panel: PanelContainer
var ending_title: Label
var ending_text: RichTextLabel
var pause_panel: PanelContainer

var can_pause: bool = true
var player_world_pos: Vector3 = Vector3(-15.8, 0.2, -54.5)

var _active_anomaly_id: String = ""
var _toast_timer: float = 0.0
var _audio_cue_timer: float = 0.0
var _current_distortion: float = 0.05
var _target_monochrome: float = 0.0
var _current_monochrome: float = 0.0
var _crt_intensity: float = 0.28
var _modal_open: bool = false
var _sanity_stage: String = "HIGH"
var _jumpscare_flash: float = 0.0
var _hp_on: bool = false
var _hp_interference: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_crt_overlay()
	_build_hud_and_modals()

	GameState.quest_updated.connect(_refresh_quests)
	GameState.state_changed.connect(_refresh_osd)
	GameState.distortion_changed.connect(_on_distortion_changed)
	GameState.dialogue_requested.connect(func(sp: String, tx: String, dur: float): show_dialogue(sp, tx, dur))
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

	var sett := get_node_or_null("/root/SettingsManager")
	if sett and sett.has_signal("settings_changed"):
		sett.settings_changed.connect(_apply_settings)
	var loc := get_node_or_null("/root/LocalizationManager")
	if loc and loc.has_signal("language_changed"):
		loc.language_changed.connect(func(_l: String): _refresh_localized_hud())

	_apply_settings()
	_refresh_quests()
	_refresh_osd()


func _tr(k: String, fb: String = "") -> String:
	var loc := get_node_or_null("/root/LocalizationManager")
	return loc.tr_key(k, fb) if loc and loc.has_method("tr_key") else (fb if not fb.is_empty() else k)


func _apply_settings() -> void:
	var sett := get_node_or_null("/root/SettingsManager")
	if not sett:
		return
	_crt_intensity = clampf(float(sett.get_val("film_grain", 0.28)), 0.0, 1.0)
	if ui_layer and ui_layer.get_child_count() > 0:
		var root_c := ui_layer.get_child(0) as Control
		if root_c:
			root_c.theme = ThemeLib.get_theme(bool(sett.get_val("high_contrast", false)))
	if prompt_label:
		var psz: int = int(sett.get_val("prompt_size", 1))
		prompt_label.add_theme_font_size_override("font_size", 14 if psz == 0 else (16 if psz == 1 else 20))
	if sanity_label:
		sanity_label.visible = bool(sett.get_val("show_sanity_meter", false))


func _refresh_localized_hud() -> void:
	_refresh_quests()
	_refresh_osd()
	if pause_panel:
		_rebuild_pause_modal_buttons()


func _process(delta: float) -> void:
	_current_monochrome = lerpf(_current_monochrome, _target_monochrome, delta * 3.5)
	if _jumpscare_flash > 0.0:
		_jumpscare_flash = maxf(0.0, _jumpscare_flash - delta)
	var sanity_tremor: float = 0.0
	if _sanity_stage == "LOW":
		sanity_tremor = 0.045
	elif _sanity_stage == "CRITICAL":
		sanity_tremor = 0.11
	if crt_material:
		crt_material.set_shader_parameter("distortion", clampf(_current_distortion + sanity_tremor + _jumpscare_flash * 0.45, 0.02, 0.95))
		crt_material.set_shader_parameter("monochrome_mix", _current_monochrome)
		crt_material.set_shader_parameter("crt_intensity", _crt_intensity)

	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and toast_panel:
			toast_panel.visible = false
	if _audio_cue_timer > 0.0:
		_audio_cue_timer -= delta
		if _audio_cue_timer <= 0.0 and audio_cue_lbl:
			audio_cue_lbl.visible = false

	if _hotbar_fade_timer > 0.0:
		_hotbar_fade_timer = maxf(0.0, _hotbar_fade_timer - delta)
	if hotbar_container:
		var target_alpha: float = 0.94 if _hotbar_fade_timer > 0.0 else 0.34
		hotbar_container.modulate.a = lerpf(hotbar_container.modulate.a, target_alpha, delta * 5.0)
		hotbar_container.visible = not _modal_open
	if control_hint_panel and control_hint_label:
		control_hint_panel.visible = (not _modal_open) and (not control_hint_label.text.is_empty())

	if vhs_label:
		var st := get_node_or_null("/root/StoryManager")
		var dt_str := str(st.get_chapter_data(GameState.current_night).get("date", "11.11.1996")) if st else "11.11.1996"
		var total_min: int = (22 * 60) + GameState.shift_minutes
		vhs_label.text = "%02d:%02d  •  %s" % [(total_min / 60) % 24, total_min % 60, dt_str]


func is_modal_open() -> bool:
	return _modal_open


func set_bunker_monochrome(enabled: bool) -> void:
	_target_monochrome = 0.80 if enabled else 0.0


func set_crt_clean_dawn() -> void:
	_crt_intensity = 0.0
	_target_monochrome = 0.0


func _on_distortion_changed(val: float) -> void:
	_current_distortion = clampf(0.03 + (val / 100.0) * 0.42, 0.02, 0.72)
	AudioSynth.set_distortion_audio(val)
	_refresh_osd()


func _build_crt_overlay() -> void:
	crt_layer = CanvasLayer.new()
	crt_layer.name = "CRTLayer"
	crt_layer.layer = 5 # Render PS1 low-res pixelation & dithering BELOW UILayer (layer 20) so text stays crisp!
	add_child(crt_layer)

	crt_rect = ColorRect.new()
	crt_rect.name = "CRTFilterRect"
	crt_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader: Shader = load("res://shaders/crt_vhs.gdshader")
	if shader:
		crt_material = ShaderMaterial.new()
		crt_material.shader = shader
		crt_material.set_shader_parameter("crt_intensity", _crt_intensity)
		crt_rect.material = crt_material
	else:
		crt_rect.color = Color(0, 0, 0, 0)
	crt_layer.add_child(crt_rect)


func _build_hud_and_modals() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 20
	add_child(ui_layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = ThemeLib.get_theme()
	ui_layer.add_child(root)

	# TOP-LEFT: Disabled per Prompt 05 (Notebook is the sole objective hub; zero permanent quest UI!)
	quest_panel = PanelContainer.new()
	quest_panel.visible = false
	quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(quest_panel)

	quest_label = RichTextLabel.new()
	quest_label.bbcode_enabled = true
	quest_label.fit_content = true
	quest_label.scroll_active = false
	quest_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_panel.add_child(quest_label)

	# TOP-RIGHT: Kept completely clean during normal gameplay (no permanent time/zone/objective clutter!)
	# Nodes remain internally for SaveManager zone lookup & optional Accessibility Sanity Meter only.
	var osd_box := VBoxContainer.new()
	osd_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	osd_box.offset_left = -360
	osd_box.offset_top = 18
	osd_box.offset_right = -22
	osd_box.offset_bottom = 128
	osd_box.add_theme_constant_override("separation", 3)
	osd_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(osd_box)

	vhs_label = Label.new()
	vhs_label.visible = false
	osd_box.add_child(vhs_label)

	zone_label = Label.new()
	zone_label.text = "SECURITY OFFICE"
	zone_label.visible = false
	osd_box.add_child(zone_label)

	var hp_row := HBoxContainer.new()
	hp_row.visible = false
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	osd_box.add_child(hp_row)

	headphones_icon_rect = TextureRect.new()
	headphones_icon_rect.visible = false
	hp_row.add_child(headphones_icon_rect)

	headphones_label = Label.new()
	headphones_label.visible = false
	hp_row.add_child(headphones_label)

	# Hidden by default — only shown if Accessibility option 'show_sanity_meter' is explicitly enabled
	sanity_label = Label.new()
	sanity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sanity_label.add_theme_color_override("font_color", ThemeLib.COL_TEXT_DIM)
	sanity_label.add_theme_font_size_override("font_size", 11)
	sanity_label.visible = false
	osd_box.add_child(sanity_label)

	# BOTTOM-LEFT: Minimal Stamina Bar (appears only when sprinting / recovering / winded!)
	stamina_bar_bg = ColorRect.new()
	stamina_bar_bg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stamina_bar_bg.offset_left = 24
	stamina_bar_bg.offset_right = 196
	stamina_bar_bg.offset_top = -34
	stamina_bar_bg.offset_bottom = -28
	stamina_bar_bg.color = Color(0.06, 0.07, 0.07, 0.72)
	stamina_bar_bg.visible = false
	stamina_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stamina_bar_bg)

	stamina_bar_fill = ColorRect.new()
	stamina_bar_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stamina_bar_fill.color = ThemeLib.COL_AMBER
	stamina_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamina_bar_bg.add_child(stamina_bar_fill)

	stamina_state_lbl = Label.new()
	stamina_state_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stamina_state_lbl.offset_left = 24
	stamina_state_lbl.offset_right = 220
	stamina_state_lbl.offset_top = -54
	stamina_state_lbl.offset_bottom = -36
	stamina_state_lbl.add_theme_color_override("font_color", ThemeLib.COL_WARNING_RED)
	stamina_state_lbl.add_theme_font_size_override("font_size", 11)
	stamina_state_lbl.visible = false
	stamina_state_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stamina_state_lbl)

	# BOTTOM-RIGHT: Hidden during normal gameplay (Bottom Inventory Hotbar displays equipment cleanly)
	var equip_box := HBoxContainer.new()
	equip_box.visible = false
	equip_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(equip_box)

	equip_icon_rect = TextureRect.new()
	equip_box.add_child(equip_icon_rect)

	stats_label = Label.new()
	equip_box.add_child(stats_label)

	# BOTTOM-CENTER: 1990s Analog Inventory Hotbar ([ HANDS ] [ TORCH ] [ KEYS ] [ RADIO ] [ LOGBOOK ] [ TASER ] [ WATCH ])
	_build_bottom_hotbar(root)

	# Optional Accessibility Audio Cue Caption
	audio_cue_lbl = Label.new()
	audio_cue_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	audio_cue_lbl.offset_left = -220
	audio_cue_lbl.offset_right = 220
	audio_cue_lbl.offset_top = -200
	audio_cue_lbl.offset_bottom = -176
	audio_cue_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	audio_cue_lbl.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	audio_cue_lbl.visible = false
	audio_cue_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(audio_cue_lbl)

	# Restrained Night 1 Orientation Hint Strip (top-center)
	tutorial_panel = PanelContainer.new()
	tutorial_panel.add_theme_stylebox_override("panel", ThemeLib.make_box(Color(0.07, 0.085, 0.08, 0.78), ThemeLib.COL_AMBER, 1, 8))
	tutorial_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tutorial_panel.offset_left = -260
	tutorial_panel.offset_right = 260
	tutorial_panel.offset_top = 16
	tutorial_panel.offset_bottom = 52
	tutorial_panel.visible = false
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tutorial_panel)

	tutorial_label = Label.new()
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.add_theme_color_override("font_color", ThemeLib.COL_TEXT_MAIN)
	tutorial_label.add_theme_font_size_override("font_size", 12)
	tutorial_panel.add_child(tutorial_label)

	# Ultra-compact temporary tutorial control hint pill (shown only during active interactive tutorial step!)
	control_hint_panel = PanelContainer.new()
	control_hint_panel.name = "ContextualControlHint"
	control_hint_panel.add_theme_stylebox_override("panel", ThemeLib.make_box(Color(0.05, 0.06, 0.065, 0.84), ThemeLib.COL_AMBER, 1, 6))
	control_hint_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	control_hint_panel.offset_left = -250
	control_hint_panel.offset_right = 250
	control_hint_panel.offset_top = -112
	control_hint_panel.offset_bottom = -82
	control_hint_panel.visible = false
	control_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(control_hint_panel)

	control_hint_label = Label.new()
	control_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	control_hint_label.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	control_hint_label.add_theme_font_size_override("font_size", 12)
	if ThemeLib.get_mono_bold_font():
		control_hint_label.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
	control_hint_panel.add_child(control_hint_label)

	# Minimal Center Dot Crosshair & Contextual Prompt
	crosshair = ColorRect.new()
	crosshair.color = Color(0.88, 0.84, 0.74, 0.55)
	crosshair.custom_minimum_size = Vector2(3, 3)
	crosshair.size = Vector2(3, 3)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -1
	crosshair.offset_top = -1
	crosshair.offset_right = 2
	crosshair.offset_bottom = 2
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)

	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER)
	prompt_label.offset_left = -280
	prompt_label.offset_top = 28
	prompt_label.offset_right = 280
	prompt_label.offset_bottom = 62
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	prompt_label.add_theme_font_size_override("font_size", 15)
	if ThemeLib.get_mono_bold_font():
		prompt_label.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_label.visible = false
	root.add_child(prompt_label)

	# Grounded Reusable Dialogue Box
	dialogue_box = DialogueBoxScript.new()
	root.add_child(dialogue_box)

	# Short Contextual Toast Notification
	toast_panel = PanelContainer.new()
	toast_panel.add_theme_stylebox_override("panel", ThemeLib.make_box(Color(0.075, 0.088, 0.085, 0.88), ThemeLib.COL_AMBER, 1, 10))
	toast_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_panel.offset_left = -260
	toast_panel.offset_right = 260
	toast_panel.offset_top = 60
	toast_panel.offset_bottom = 104
	toast_panel.visible = false
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_panel)

	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	toast_panel.add_child(toast_label)

	# Modal Backdrop & Reusable Screens
	modal_backdrop = ColorRect.new()
	modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_backdrop.color = Color(0.02, 0.025, 0.028, 0.72)
	modal_backdrop.visible = false
	root.add_child(modal_backdrop)

	# Physical 9-Page Aged-Paper Notebook UI
	notebook_ui = NotebookUIScript.new()
	notebook_ui.set_anchors_preset(Control.PRESET_CENTER)
	notebook_ui.offset_left = -470
	notebook_ui.offset_right = 470
	notebook_ui.offset_top = -305
	notebook_ui.offset_bottom = 305
	notebook_ui.visible = false
	notebook_ui.closed.connect(close_all_modals)
	notebook_ui.anomaly_checked_off.connect(func(aid: String): emit_signal("anomaly_checked_off", aid))
	notebook_ui.incident_note_submitted.connect(func(txt: String): emit_signal("incident_note_submitted", txt))
	if notebook_ui.has_signal("tutorial_reopen_requested"):
		notebook_ui.tutorial_reopen_requested.connect(func(): emit_signal("tutorial_reopen_requested"))
	if notebook_ui.has_signal("section_viewed"):
		notebook_ui.section_viewed.connect(func(sidx: int): emit_signal("notebook_section_viewed", sidx))
	modal_backdrop.add_child(notebook_ui)

	# In-Game Options Overlay
	options_panel = OptionsMenuScript.new()
	options_panel.set_anchors_preset(Control.PRESET_CENTER)
	options_panel.offset_left = -390
	options_panel.offset_right = 390
	options_panel.offset_top = -280
	options_panel.offset_bottom = 280
	options_panel.visible = false
	options_panel.closed.connect(open_pause_modal)
	modal_backdrop.add_child(options_panel)

	# In-Game Save / Load Slot Cards Overlay
	saveload_panel = SaveLoadScript.new()
	saveload_panel.set_anchors_preset(Control.PRESET_CENTER)
	saveload_panel.offset_left = -360
	saveload_panel.offset_right = 360
	saveload_panel.offset_top = -245
	saveload_panel.offset_bottom = 245
	saveload_panel.visible = false
	saveload_panel.slot_chosen.connect(func(sidx: int, m: String):
		if m == "save":
			emit_signal("save_slot_requested", sidx)
			close_all_modals()
		elif m == "load":
			emit_signal("load_slot_requested", sidx)
			close_all_modals()
	)
	saveload_panel.closed.connect(open_pause_modal)
	modal_backdrop.add_child(saveload_panel)

	_build_anomaly_modal()
	_build_cctv_modal()
	_build_choice_modal()
	_build_dawn_modal()
	_build_ending_modal()
	_build_pause_modal()

	chapter_overlay = ChapterOverlayScript.new()
	add_child(chapter_overlay)


func _build_anomaly_modal() -> void:
	anomaly_panel = _center_modal(Vector2(640, 390))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	anomaly_panel.add_child(vb)
	anomaly_title = Label.new()
	anomaly_title.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	anomaly_title.add_theme_font_size_override("font_size", 19)
	vb.add_child(anomaly_title)
	anomaly_desc = Label.new()
	anomaly_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	anomaly_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(anomaly_desc)
	for act_pair: Array in [
		["[1] Log Observation in Official Shift Report", "log"],
		["[2] Stabilize / Contain Area", "contain"],
		["[3] Examine Closer (+Distortion / Lore)", "investigate"],
		["[4] Leave It Unrecorded", "ignore"]
	]:
		var btn := Button.new()
		btn.text = str(act_pair[0])
		var act_key: String = str(act_pair[1])
		btn.pressed.connect(func(): _resolve_anomaly_choice(act_key))
		vb.add_child(btn)


func _build_cctv_modal() -> void:
	cctv_panel = _center_modal(Vector2(700, 520))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	cctv_panel.add_child(vb)
	cctv_cam_label = Label.new()
	cctv_cam_label.text = "TESLA MONITOR — CAM-01"
	cctv_cam_label.add_theme_color_override("font_color", Color(0.62, 0.88, 0.66))
	cctv_cam_label.add_theme_font_size_override("font_size", 17)
	vb.add_child(cctv_cam_label)
	cctv_feed_rect = TextureRect.new()
	cctv_feed_rect.custom_minimum_size = Vector2(640, 340)
	cctv_feed_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cctv_feed_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vb.add_child(cctv_feed_rect)
	cctv_anom_hint = Label.new()
	cctv_anom_hint.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	vb.add_child(cctv_anom_hint)
	var cam_strip := HBoxContainer.new()
	cam_strip.add_theme_constant_override("separation", 6)
	vb.add_child(cam_strip)
	for ci: int in range(6):
		var cbtn := Button.new()
		cbtn.text = "CAM-0%d" % (ci + 1)
		cbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cidx := ci
		cbtn.pressed.connect(func(): emit_signal("cctv_select_requested", cidx))
		cam_strip.add_child(cbtn)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	var cyc := Button.new()
	cyc.text = "Next Camera"
	cyc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cyc.pressed.connect(func(): emit_signal("cctv_cycle_requested"))
	hb.add_child(cyc)
	var lg := Button.new()
	lg.text = "Log CCTV Sighting"
	lg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lg.pressed.connect(func(): emit_signal("cctv_log_requested"))
	hb.add_child(lg)
	var cl := Button.new()
	cl.text = "Step Back [ESC]"
	cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cl.pressed.connect(close_all_modals)
	hb.add_child(cl)


func _build_choice_modal() -> void:
	choice_panel = _center_modal(Vector2(660, 400))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	choice_panel.add_child(vb)
	choice_title = Label.new()
	choice_title.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	choice_title.add_theme_font_size_override("font_size", 19)
	vb.add_child(choice_title)
	choice_body = Label.new()
	choice_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(choice_body)
	choice_buttons_box = VBoxContainer.new()
	choice_buttons_box.add_theme_constant_override("separation", 6)
	vb.add_child(choice_buttons_box)


func _build_dawn_modal() -> void:
	dawn_panel = _center_modal(Vector2(640, 380))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	dawn_panel.add_child(vb)
	var t := Label.new()
	t.text = "06:00 — DAWN SHIFT REPORT (SÍDLISKO JAVOR)"
	t.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	t.add_theme_font_size_override("font_size", 19)
	vb.add_child(t)
	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text = "Required patrol checks are complete. How do you sign tonight's report for Supervisor Varga?"
	vb.add_child(desc)
	for pair: Array in [
		["File Truthful Report (Include all anomalies & incidents)", "truth"],
		["File Routine Report ('Shift Quiet — Nothing Unusual')", "falsify"],
		["Withhold Sensitive Pages (Keep private notes)", "redact"],
	]:
		var b := Button.new()
		b.text = str(pair[0])
		var m := str(pair[1])
		b.pressed.connect(func():
			close_all_modals()
			emit_signal("dawn_submitted", m)
		)
		vb.add_child(b)


func _build_ending_modal() -> void:
	ending_panel = _center_modal(Vector2(760, 490))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	ending_panel.add_child(vb)
	ending_title = Label.new()
	ending_title.add_theme_font_size_override("font_size", 24)
	ending_title.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	vb.add_child(ending_title)
	ending_text = RichTextLabel.new()
	ending_text.bbcode_enabled = true
	ending_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(ending_text)
	var menu_btn := Button.new()
	menu_btn.text = _tr("pause_main_menu", "MAIN MENU")
	menu_btn.pressed.connect(func(): emit_signal("pause_menu_requested", "menu"))
	vb.add_child(menu_btn)


func _build_pause_modal() -> void:
	pause_panel = _center_modal(Vector2(420, 440))
	_rebuild_pause_modal_buttons()


func _rebuild_pause_modal_buttons() -> void:
	for c: Node in pause_panel.get_children():
		c.queue_free()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pause_panel.add_child(vb)
	var t := Label.new()
	t.text = _tr("pause_title", "SHIFT PAUSED")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	t.add_theme_font_size_override("font_size", 20)
	if ThemeLib.get_mono_bold_font():
		t.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
	vb.add_child(t)

	var entries: Array[Array] = [
		[_tr("pause_resume", "RESUME"), Callable(self, "close_all_modals")],
		[_tr("pause_notebook", "NOTEBOOK"), Callable(self, "open_logbook")],
		[_tr("pause_map", "ESTATE MAP"), Callable(self, "open_map")],
		[_tr("pause_save", "SAVE GAME"), Callable(self, "_open_pause_save")],
		[_tr("pause_load", "LOAD GAME"), Callable(self, "_open_pause_load")],
		[_tr("pause_options", "OPTIONS"), Callable(self, "_open_pause_options")],
		[_tr("pause_main_menu", "MAIN MENU"), Callable(self, "_request_main_menu")],
	]
	for item: Array in entries:
		var b := Button.new()
		b.text = str(item[0])
		b.custom_minimum_size = Vector2(0, 38)
		var cb: Callable = item[1]
		b.pressed.connect(func():
			AudioSynth.play_ui_sfx("ui_press")
			cb.call()
		)
		vb.add_child(b)


func _open_pause_save() -> void:
	_hide_all_modal_panels()
	saveload_panel.open_for_mode("save")
	saveload_panel.visible = true


func _open_pause_load() -> void:
	_hide_all_modal_panels()
	saveload_panel.open_for_mode("load")
	saveload_panel.visible = true


func _open_pause_options() -> void:
	_hide_all_modal_panels()
	options_panel.visible = true


func _request_main_menu() -> void:
	get_tree().paused = false
	emit_signal("pause_menu_requested", "menu")


func show_chapter_card(night_num: int) -> void:
	if chapter_overlay and DisplayServer.get_name() != "headless":
		chapter_overlay.show_chapter_card(night_num, 2.8)


func show_audio_cue_caption(caption: String) -> void:
	var sett := get_node_or_null("/root/SettingsManager")
	if not sett or not bool(sett.get_val("audio_cues", false)):
		return
	if audio_cue_lbl:
		audio_cue_lbl.text = "[ %s ]" % caption
		audio_cue_lbl.visible = true
		_audio_cue_timer = 3.2


func set_prompt(text: String) -> void:
	if not prompt_label:
		return
	var loc := get_node_or_null("/root/LocalizationManager")
	var dyn_txt := text
	if loc and dyn_txt.contains("[E]"):
		dyn_txt = dyn_txt.replace("[E]", "[%s]" % loc.get_key_label("interact"))
	prompt_label.text = dyn_txt
	prompt_label.visible = not dyn_txt.is_empty() and not _modal_open


func show_dialogue(speaker: String, text: String, duration: float = 6.5, role: String = "") -> void:
	if dialogue_box:
		dialogue_box.show_line(speaker, text, duration, role)


func show_toast(msg: String) -> void:
	if not toast_panel or not toast_label:
		return
	toast_label.text = msg
	toast_panel.visible = true
	_toast_timer = 4.2
	AudioSynth.play_ui_sfx("ui_press", -10.0)


func _on_achievement_unlocked(data: Dictionary) -> void:
	show_toast("★ %s" % str(data.get("title_en", "")))


func _refresh_quests() -> void:
	# Permanent objective HUD removed: player checks their physical Notebook [TAB/N] for all assignments.
	if quest_panel:
		quest_panel.visible = false
	refresh_tutorial_banner()
	refresh_logbook_content()


func refresh_tutorial_banner() -> void:
	# Never show persistent top-center tutorial banners; only compact contextual control hints during active steps.
	if tutorial_panel:
		tutorial_panel.visible = false


func show_tutorial_hint(hint_text: String) -> void:
	if control_hint_label:
		control_hint_label.text = hint_text
	if control_hint_panel:
		control_hint_panel.visible = (not _modal_open) and (not hint_text.is_empty())


func is_hud_clean_no_objectives() -> bool:
	var qp_off: bool = (quest_panel == null or not quest_panel.visible)
	var tp_off: bool = (tutorial_panel == null or not tutorial_panel.visible)
	var tr_off: bool = (vhs_label == null or not vhs_label.visible) and (zone_label == null or not zone_label.visible)
	return qp_off and tp_off and tr_off


func set_zone_label(ztext: String) -> void:
	if zone_label and not ztext.is_empty():
		zone_label.text = ztext


func set_notebook_feedback(msg: String, ok: bool = true) -> void:
	if notebook_ui and notebook_ui.has_method("set_feedback"):
		notebook_ui.set_feedback(msg, ok)


func _refresh_osd() -> void:
	if not stats_label:
		return
	var slot_icons := {
		"hands": "icon_hands",
		"flashlight": "icon_flashlight",
		"taser": "icon_taser",
		"keys": "icon_keys",
		"radio": "icon_radio",
		"watch": "icon_watch",
		"notebook": "icon_notebook",
	}
	if equip_icon_rect:
		equip_icon_rect.texture = ThemeLib.load_icon(str(slot_icons.get(GameState.equipped_slot, "icon_flashlight")))
	var torch_state_str := "ON" if _flashlight_powered else "OFF"
	var slot_names := {
		"hands": "EMPTY HANDS",
		"flashlight": "TORCH %s (%d%%)" % [torch_state_str, int(round(GameState.flashlight_battery))],
		"taser": "TASER %d%%" % int(round(GameState.taser_charge)),
		"keys": "KEYS (%d)" % GameState.collected_keys.size(),
		"radio": "RADIO 50.4Hz",
		"watch": "WATCH",
		"notebook": "LOGBOOK",
	}
	stats_label.text = "%s  |  CELLS: %d" % [str(slot_names.get(GameState.equipped_slot, "TORCH")), GameState.spare_batteries]
	_refresh_hotbar()
	refresh_tutorial_banner()


func set_flashlight_power_state(is_on: bool) -> void:
	_flashlight_powered = is_on
	_hotbar_fade_timer = 3.8
	_refresh_osd()


func get_hotbar_slot_count() -> int:
	return _hotbar_cards.size()


func _build_bottom_hotbar(root: Control) -> void:
	hotbar_container = PanelContainer.new()
	hotbar_container.name = "BottomInventoryHotbar"
	hotbar_container.add_theme_stylebox_override("panel", ThemeLib.make_box(Color(0.045, 0.052, 0.054, 0.84), ThemeLib.COL_WARM_BORDER, 1, 6))
	hotbar_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hotbar_container.offset_left = -318
	hotbar_container.offset_right = 318
	hotbar_container.offset_top = -74
	hotbar_container.offset_bottom = -12
	root.add_child(hotbar_container)

	hotbar_row = HBoxContainer.new()
	hotbar_row.name = "HotbarRow"
	hotbar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hotbar_row.add_theme_constant_override("separation", 6)
	hotbar_container.add_child(hotbar_row)

	_hotbar_cards.clear()
	for spec: Dictionary in HOTBAR_SLOTS:
		var sid: String = str(spec.get("id", "hands"))
		var card := PanelContainer.new()
		card.name = "Slot_" + sid
		card.custom_minimum_size = Vector2(84, 52)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var target_sid := sid
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				_hotbar_fade_timer = 4.0
				emit_signal("hotbar_slot_selected", target_sid)
		)
		hotbar_row.add_child(card)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(vb)

		var top_hb := HBoxContainer.new()
		top_hb.add_theme_constant_override("separation", 4)
		top_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(top_hb)

		var key_lbl := Label.new()
		key_lbl.text = "[%s]" % str(spec.get("key", ""))
		key_lbl.add_theme_font_size_override("font_size", 10)
		key_lbl.add_theme_color_override("font_color", ThemeLib.COL_TEXT_DIM)
		if ThemeLib.get_mono_font():
			key_lbl.add_theme_font_override("font", ThemeLib.get_mono_font())
		top_hb.add_child(key_lbl)

		var ic := TextureRect.new()
		ic.custom_minimum_size = Vector2(18, 18)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture = ThemeLib.load_icon(str(spec.get("icon", "icon_flashlight")))
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_hb.add_child(ic)

		var st_lbl := Label.new()
		st_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		st_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		st_lbl.add_theme_font_size_override("font_size", 10)
		st_lbl.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
		if ThemeLib.get_mono_font():
			st_lbl.add_theme_font_override("font", ThemeLib.get_mono_font())
		top_hb.add_child(st_lbl)

		var name_lbl := Label.new()
		name_lbl.text = str(spec.get("label", sid.to_upper()))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 11)
		if ThemeLib.get_mono_bold_font():
			name_lbl.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
		vb.add_child(name_lbl)

		_hotbar_cards[sid] = {
			"panel": card,
			"name_lbl": name_lbl,
			"status_lbl": st_lbl,
			"icon_rect": ic,
		}


func _refresh_hotbar() -> void:
	if _hotbar_cards.is_empty():
		return
	_hotbar_fade_timer = 3.8
	var active_id: String = GameState.equipped_slot
	for sid: String in _hotbar_cards.keys():
		var info: Dictionary = _hotbar_cards[sid]
		var card := info["panel"] as PanelContainer
		var name_lbl := info["name_lbl"] as Label
		var st_lbl := info["status_lbl"] as Label
		var is_sel: bool = (sid == active_id)
		var bg_col := Color(0.14, 0.12, 0.08, 0.94) if is_sel else Color(0.06, 0.07, 0.072, 0.72)
		var border_col := ThemeLib.COL_AMBER if is_sel else Color(0.24, 0.25, 0.24, 0.65)
		card.add_theme_stylebox_override("panel", ThemeLib.make_box(bg_col, border_col, 2 if is_sel else 1, 5))
		name_lbl.add_theme_color_override("font_color", ThemeLib.COL_AMBER if is_sel else ThemeLib.COL_TEXT_MAIN)
		match sid:
			"hands":
				st_lbl.text = "FREE"
			"flashlight":
				st_lbl.text = "ON" if _flashlight_powered else "OFF"
			"keys":
				st_lbl.text = "x%d" % max(1, GameState.collected_keys.size())
			"radio":
				st_lbl.text = "50.4"
			"notebook":
				st_lbl.text = "%d" % GameState.notebook_checked.size()
			"taser":
				st_lbl.text = "%d%%" % int(round(GameState.taser_charge))
			"watch":
				st_lbl.text = "%02d:%02d" % [((22 * 60 + GameState.shift_minutes) / 60) % 24, (22 * 60 + GameState.shift_minutes) % 60]


func set_headphone_interference(active: bool) -> void:
	_hp_interference = active
	_refresh_headphone_badge()


func _refresh_headphone_badge() -> void:
	if not headphones_label:
		return
	if _hp_interference and _hp_on:
		headphones_label.text = _tr("hud_hp_interf", "TAPE INTERFERENCE")
		headphones_label.add_theme_color_override("font_color", ThemeLib.COL_WARNING_RED)
	elif _hp_on:
		headphones_label.text = _tr("hud_hp_on", "HEADPHONES ON")
		headphones_label.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	else:
		headphones_label.text = _tr("hud_hp_off", "HEADPHONES OFF")
		headphones_label.add_theme_color_override("font_color", ThemeLib.COL_TEXT_DIM)


func update_player_vitals(stamina: float, exhausted: bool, sanity: float, stage: String, headphones_on: bool) -> void:
	_sanity_stage = stage
	_hp_on = headphones_on
	_refresh_headphone_badge()
	if sanity_label:
		var sett := get_node_or_null("/root/SettingsManager")
		sanity_label.visible = bool(sett.get_val("show_sanity_meter", false)) if sett else false
		sanity_label.text = "STRAIN: %s (%d%%)" % [stage, int(round(sanity))]
	if stamina_bar_bg and stamina_bar_fill:
		var ratio := clampf(stamina / 100.0, 0.0, 1.0)
		stamina_bar_bg.visible = (ratio < 0.92 or exhausted) and not _modal_open
		stamina_bar_fill.anchor_right = ratio
		stamina_bar_fill.color = ThemeLib.COL_WARNING_RED if exhausted else ThemeLib.COL_AMBER
	if stamina_state_lbl:
		stamina_state_lbl.visible = exhausted and not _modal_open
		stamina_state_lbl.text = _tr("hud_winded", "CATCHING BREATH")


func trigger_jumpscare_flash() -> void:
	_jumpscare_flash = 0.85


func open_logbook(page_idx: int = 0) -> void:
	_hide_all_modal_panels()
	_modal_open = true
	modal_backdrop.visible = true
	notebook_ui.visible = true
	notebook_ui.open_to_page(page_idx, player_world_pos)
	emit_signal("notebook_opened_changed", true)


func set_navigation_sources(p_patrol_mgr: Node, p_nav_hint_mgr: Node = null) -> void:
	if notebook_ui and notebook_ui.has_method("set_navigation_sources"):
		notebook_ui.set_navigation_sources(p_patrol_mgr, p_nav_hint_mgr)


func open_map() -> void:
	open_logbook(6)


func refresh_logbook_content() -> void:
	if notebook_ui and notebook_ui.visible:
		notebook_ui.refresh_content(player_world_pos)


func open_anomaly_modal(anomaly_id: String) -> void:
	var entry: Dictionary = AnomalyDirector.get_anomaly_by_id(anomaly_id)
	if entry.is_empty():
		return
	_hide_all_modal_panels()
	_active_anomaly_id = anomaly_id
	_modal_open = true
	modal_backdrop.visible = true
	anomaly_panel.visible = true
	anomaly_title.text = "%s — %s" % [anomaly_id, str(entry.get("title_en", ""))]
	anomaly_desc.text = str(entry.get("description", ""))


func _resolve_anomaly_choice(action: String) -> void:
	var aid: String = _active_anomaly_id
	close_all_modals()
	if aid.is_empty():
		return
	var outcome: String = AnomalyDirector.handle_anomaly_response(aid, action)
	AudioSynth.play_sfx("static_burst" if action == "investigate" else "ui_press", -7.0)
	show_dialogue("MARTIN KOVÁČ", outcome, 5.5)


func open_cctv_modal(feed_tex: Texture2D, cam_label: String, hint_text: String) -> void:
	_hide_all_modal_panels()
	_modal_open = true
	modal_backdrop.visible = true
	cctv_panel.visible = true
	update_cctv_modal(feed_tex, cam_label, hint_text)


func update_cctv_modal(feed_tex: Texture2D, cam_label: String, hint_text: String) -> void:
	if cctv_feed_rect and feed_tex:
		cctv_feed_rect.texture = feed_tex
	if cctv_cam_label:
		cctv_cam_label.text = "TESLA MONITOR — " + cam_label
	if cctv_anom_hint:
		cctv_anom_hint.text = hint_text


func open_choice_modal(title_text: String, body_text: String, options: Array[Dictionary]) -> void:
	_hide_all_modal_panels()
	_modal_open = true
	modal_backdrop.visible = true
	choice_panel.visible = true
	choice_title.text = title_text
	choice_body.text = body_text
	for child: Node in choice_buttons_box.get_children():
		child.queue_free()
	for opt: Dictionary in options:
		var btn := Button.new()
		btn.text = str(opt.get("label", "Option"))
		var cid: String = str(opt.get("id", ""))
		btn.pressed.connect(func():
			AudioSynth.play_ui_sfx("ui_press")
			close_all_modals()
			emit_signal("choice_made", cid)
		)
		choice_buttons_box.add_child(btn)


func open_dawn_modal() -> void:
	_hide_all_modal_panels()
	_modal_open = true
	modal_backdrop.visible = true
	dawn_panel.visible = true


func open_javor_ending_modal(ending_data: Dictionary) -> void:
	_hide_all_modal_panels()
	_modal_open = true
	modal_backdrop.visible = true
	ending_panel.visible = true
	ending_title.text = str(ending_data.get("title", "ENDING"))
	ending_text.text = "[i]%s[/i]\n\n%s" % [str(ending_data.get("subtitle", "")), str(ending_data.get("body", ""))]


func open_ending_modal(ending_id: String) -> void:
	_hide_all_modal_panels()
	_modal_open = true
	modal_backdrop.visible = true
	ending_panel.visible = true
	var edata: Dictionary = GameState.ENDINGS_DATA.get(ending_id, GameState.ENDINGS_DATA["A"])
	ending_title.text = str(edata.get("title_en", ""))
	ending_text.text = "[i]%s[/i]\n\n%s\n\n[color=#d69e4e]Unlocked Endings: %d/6 | Codex: %d/32 | Achievements: %d/28[/color]" % [
		str(edata.get("subtitle", "")), str(edata.get("text", "")),
		GameState.unlocked_endings.size(), GameState.discovered_anomalies.size(), GameState.unlocked_achievements.size()
	]
	if ending_id == "F":
		set_crt_clean_dawn()


func open_pause_modal() -> void:
	if not can_pause:
		show_toast("Cannot pause during active scripted event.")
		return
	_hide_all_modal_panels()
	_modal_open = true
	modal_backdrop.visible = true
	pause_panel.visible = true
	get_tree().paused = true


func close_all_modals() -> void:
	var was_nb: bool = (notebook_ui != null and notebook_ui.visible)
	_hide_all_modal_panels()
	_modal_open = false
	_active_anomaly_id = ""
	get_tree().paused = false
	if modal_backdrop:
		modal_backdrop.visible = false
	if was_nb:
		emit_signal("notebook_opened_changed", false)
	emit_signal("modal_closed")


func _hide_all_modal_panels() -> void:
	for p: Control in [notebook_ui, options_panel, saveload_panel, anomaly_panel, cctv_panel, choice_panel, dawn_panel, ending_panel, pause_panel]:
		if p:
			p.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if ending_panel and ending_panel.visible:
		return
	if anomaly_panel and anomaly_panel.visible:
		if event.is_action_pressed("choice_1"): _resolve_anomaly_choice("log")
		elif event.is_action_pressed("choice_2"): _resolve_anomaly_choice("contain")
		elif event.is_action_pressed("choice_3"): _resolve_anomaly_choice("investigate")
		elif event.is_action_pressed("choice_4"): _resolve_anomaly_choice("ignore")
		elif event.is_action_pressed("pause"): close_all_modals()
		return

	if event.is_action_pressed("logbook") or event.is_action_pressed("notebook_key"):
		if notebook_ui and notebook_ui.visible:
			close_all_modals()
		elif not _modal_open:
			open_logbook(0)
	elif event.is_action_pressed("pause"):
		if _modal_open:
			close_all_modals()
		else:
			open_pause_modal()


func _center_modal(min_sz: Vector2) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = min_sz
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.offset_left = -min_sz.x * 0.5
	pc.offset_right = min_sz.x * 0.5
	pc.offset_top = -min_sz.y * 0.5
	pc.offset_bottom = min_sz.y * 0.5
	pc.visible = false
	modal_backdrop.add_child(pc)
	return pc
