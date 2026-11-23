class_name JavorDialogueBox
extends PanelContainer

signal dialogue_finished
signal choice_selected(choice_id: String)

const ThemeLib = preload("res://scripts/ui/javor_theme.gd")

var _speaker_lbl: Label
var _role_lbl: Label
var _body_lbl: RichTextLabel
var _choices_box: VBoxContainer
var _continue_lbl: Label

var _full_text: String = ""
var _shown_chars: float = 0.0
var _auto_timer: float = 0.0
var _has_choices: bool = false


func _ready() -> void:
	theme = ThemeLib.get_theme()
	_build_ui()
	visible = false
	var sett := get_node_or_null("/root/SettingsManager")
	if sett and sett.has_signal("settings_changed"):
		sett.settings_changed.connect(_apply_accessibility)
	_apply_accessibility()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 200
	offset_right = -200
	offset_top = -172
	offset_bottom = -36
	add_theme_stylebox_override("panel", ThemeLib.make_box(Color(0.055, 0.068, 0.072, 0.90), ThemeLib.COL_AMBER, 1, 14))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	add_child(vb)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vb.add_child(hdr)

	_speaker_lbl = Label.new()
	_speaker_lbl.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	_speaker_lbl.add_theme_font_size_override("font_size", 16)
	if ThemeLib.get_mono_bold_font():
		_speaker_lbl.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
	hdr.add_child(_speaker_lbl)

	_role_lbl = Label.new()
	_role_lbl.add_theme_color_override("font_color", ThemeLib.COL_TEXT_DIM)
	_role_lbl.add_theme_font_size_override("font_size", 13)
	hdr.add_child(_role_lbl)

	_body_lbl = RichTextLabel.new()
	_body_lbl.bbcode_enabled = true
	_body_lbl.fit_content = true
	_body_lbl.scroll_active = false
	vb.add_child(_body_lbl)

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 4)
	vb.add_child(_choices_box)

	_continue_lbl = Label.new()
	_continue_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_lbl.add_theme_color_override("font_color", ThemeLib.COL_TEXT_DIM)
	_continue_lbl.add_theme_font_size_override("font_size", 11)
	if ThemeLib.get_mono_font():
		_continue_lbl.add_theme_font_override("font", ThemeLib.get_mono_font())
	vb.add_child(_continue_lbl)


func _apply_accessibility() -> void:
	var sett := get_node_or_null("/root/SettingsManager")
	if not sett:
		return
	var sz_idx: int = int(sett.get_val("subtitle_size", 1))
	var fsz: int = 14 if sz_idx == 0 else (16 if sz_idx == 1 else 20)
	if _body_lbl:
		_body_lbl.add_theme_font_size_override("normal_font_size", fsz)
	var show_bg: bool = bool(sett.get_val("subtitle_bg", true))
	var bg_col := Color(0.055, 0.068, 0.072, 0.90) if show_bg else Color(0.0, 0.0, 0.0, 0.0)
	add_theme_stylebox_override("panel", ThemeLib.make_box(bg_col, ThemeLib.COL_AMBER if show_bg else Color(0, 0, 0, 0), 1 if show_bg else 0, 14))
	if _speaker_lbl:
		_speaker_lbl.visible = bool(sett.get_val("subtitle_speaker", true))


func show_line(speaker: String, text: String, duration: float = 6.5, role: String = "", choices: Array[Dictionary] = []) -> void:
	_speaker_lbl.text = speaker.to_upper()
	_role_lbl.text = ("— " + role) if not role.is_empty() else ""
	_full_text = text
	_shown_chars = 0.0
	_body_lbl.text = text
	_body_lbl.visible_characters = 0 if DisplayServer.get_name() != "headless" else -1
	_auto_timer = duration if choices.is_empty() else 0.0
	_has_choices = not choices.is_empty()

	for c: Node in _choices_box.get_children():
		c.queue_free()
	for ch: Dictionary in choices:
		var b := Button.new()
		b.text = str(ch.get("label", "Continue"))
		var cid := str(ch.get("id", ""))
		b.pressed.connect(func():
			AudioSynth.play_ui_sfx("ui_press")
			visible = false
			emit_signal("choice_selected", cid)
		)
		_choices_box.add_child(b)

	var loc := get_node_or_null("/root/LocalizationManager")
	var c_txt: String = loc.tr_key("dlg_continue", "CONTINUE") if loc else "CONTINUE"
	_continue_lbl.text = "[SPACE] %s" % c_txt if not _has_choices else ""
	visible = true


func _process(delta: float) -> void:
	if not visible:
		return
	if _body_lbl.visible_characters >= 0 and _body_lbl.visible_characters < _full_text.length():
		_shown_chars += delta * 58.0
		_body_lbl.visible_characters = mini(_full_text.length(), int(_shown_chars))
	elif _auto_timer > 0.0:
		_auto_timer -= delta
		if _auto_timer <= 0.0:
			visible = false
			emit_signal("dialogue_finished")


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _has_choices:
		return
	if event is InputEventKey and event.pressed and (event.physical_keycode == KEY_SPACE):
		if _body_lbl.visible_characters >= 0 and _body_lbl.visible_characters < _full_text.length():
			_body_lbl.visible_characters = -1
		else:
			visible = false
			emit_signal("dialogue_finished")
