class_name JavorChapterLoadingOverlay
extends CanvasLayer

signal dismissed

const ThemeLib = preload("res://scripts/ui/javor_theme.gd")

const LOADING_ARTS := [
	"res://assets/graphics/loading/loading_plan.png",
	"res://assets/graphics/loading/loading_dossier.png",
	"res://assets/graphics/loading/loading_cassette.png",
	"res://assets/graphics/loading/loading_notebook.png",
]

var _root: Control
var _art_rect: TextureRect
var _title_lbl: Label
var _sub_lbl: Label
var _hint_lbl: Label
var _prog_bar: ProgressBar
var _continue_btn: Button
var _auto_timer: float = 0.0
var _active: bool = false


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false


func _tr(k: String, fb: String = "") -> String:
	var loc := get_node_or_null("/root/LocalizationManager")
	return loc.tr_key(k, fb) if loc and loc.has_method("tr_key") else (fb if not fb.is_empty() else k)


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = ThemeLib.get_theme()
	add_child(_root)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.055, 1.0)
	_root.add_child(bg)

	_art_rect = TextureRect.new()
	_art_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_root.add_child(_art_rect)

	var bottom_band := PanelContainer.new()
	bottom_band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_band.offset_top = -188
	bottom_band.offset_bottom = 0
	bottom_band.add_theme_stylebox_override("panel", ThemeLib.make_box(Color(0.05, 0.065, 0.07, 0.92), ThemeLib.COL_AMBER, 1, 22))
	_root.add_child(bottom_band)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	bottom_band.add_child(vb)

	_title_lbl = Label.new()
	_title_lbl.add_theme_font_size_override("font_size", 28)
	_title_lbl.add_theme_color_override("font_color", ThemeLib.COL_TEXT_MAIN)
	vb.add_child(_title_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.add_theme_font_size_override("font_size", 15)
	_sub_lbl.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	if ThemeLib.get_mono_font():
		_sub_lbl.add_theme_font_override("font", ThemeLib.get_mono_font())
	vb.add_child(_sub_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_lbl.add_theme_color_override("font_color", ThemeLib.COL_TEXT_DIM)
	vb.add_child(_hint_lbl)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 14)
	vb.add_child(foot)

	_prog_bar = ProgressBar.new()
	_prog_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prog_bar.custom_minimum_size = Vector2(0, 14)
	_prog_bar.max_value = 100.0
	_prog_bar.value = 100.0
	_prog_bar.show_percentage = false
	foot.add_child(_prog_bar)

	_continue_btn = Button.new()
	_continue_btn.custom_minimum_size = Vector2(180, 34)
	_continue_btn.text = _tr("dlg_continue", "CONTINUE")
	_continue_btn.pressed.connect(hide_overlay)
	foot.add_child(_continue_btn)


func show_chapter_card(night_num: int, auto_dismiss_sec: float = 3.2) -> void:
	var n := clampi(night_num, 1, 6)
	var art_path := "res://assets/graphics/chapters/chapter_night_%d.png" % n
	if ResourceLoader.exists(art_path):
		var tex: Resource = load(art_path)
		if tex is Texture2D:
			_art_rect.texture = tex as Texture2D

	_title_lbl.text = _tr("ch_%d_title" % n, "NIGHT %d" % n)
	_sub_lbl.text = _tr("ch_%d_sub" % n, "SÍDLISKO JAVOR • 1996")
	var hint_idx := ((n - 1) % 5) + 1
	_hint_lbl.text = _tr("load_hint_%d" % hint_idx, "")
	_continue_btn.text = _tr("dlg_continue", "CONTINUE")
	_prog_bar.value = 0.0
	_auto_timer = auto_dismiss_sec
	_active = true
	visible = true


func show_loading_screen(art_index: int = 0) -> void:
	var p: String = str(LOADING_ARTS[posmod(art_index, LOADING_ARTS.size())])
	if ResourceLoader.exists(p):
		var tex: Resource = load(p)
		if tex is Texture2D:
			_art_rect.texture = tex as Texture2D
	_title_lbl.text = _tr("game_full_title", "NIGHT SHIFT: THE JAVOR ESTATE")
	_sub_lbl.text = _tr("setting_tag", "SÍDLISKO JAVOR • NOVÝ BROD • NOVEMBER 1996")
	_hint_lbl.text = _tr("load_hint_%d" % ((art_index % 5) + 1), "")
	_prog_bar.value = 85.0
	_auto_timer = 1.6
	_active = true
	visible = true


func _process(delta: float) -> void:
	if not _active:
		return
	if _prog_bar.value < 100.0:
		_prog_bar.value = minf(100.0, _prog_bar.value + delta * 62.0)
	if _auto_timer > 0.0:
		_auto_timer -= delta
		if _auto_timer <= 0.0:
			hide_overlay()


func hide_overlay() -> void:
	if not _active:
		return
	_active = false
	visible = false
	emit_signal("dismissed")
