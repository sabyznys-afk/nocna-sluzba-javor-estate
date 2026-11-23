class_name JavorTheme
extends RefCounted

# Unified 1997 PS1 / Central European Security Terminal Colour System
const COL_CHARCOAL := Color(0.048, 0.056, 0.058, 0.96)     # #0c0e0f Deep PS1 CRT shadow
const COL_OLIVE_DARK := Color(0.082, 0.098, 0.092, 0.96)   # #151917 Aged iron panel
const COL_GREY_GREEN := Color(0.135, 0.165, 0.148, 0.98)   # #222a26 Highlighted terminal row
const COL_WARM_BORDER := Color(0.390, 0.415, 0.392, 0.92)  # #636a64 Hard 2px retro frame
const COL_PAPER := Color(0.815, 0.772, 0.678, 1.0)         # #d0c5ad Aged physical logbook paper
const COL_PAPER_DARK := Color(0.715, 0.668, 0.574, 1.0)    # #b6aa92
const COL_INK := Color(0.118, 0.110, 0.098, 1.0)           # #1e1c19
const COL_TEXT_MAIN := Color(0.845, 0.818, 0.742, 1.0)     # #d7d1bd Desaturated bone-white
const COL_TEXT_DIM := Color(0.545, 0.576, 0.548, 1.0)      # #8b938c
const COL_AMBER := Color(0.820, 0.580, 0.255, 1.0)         # #d19441 Dirty 1996 sodium amber
const COL_ORANGE := Color(0.745, 0.420, 0.190, 1.0)        # #be6b30
const COL_WARNING_RED := Color(0.690, 0.235, 0.200, 1.0)   # #b03c33

static var _cached_theme: Theme = null
static var _font_sans: Font = null
static var _font_mono: Font = null
static var _font_mono_bold: Font = null


static func get_sans_font() -> Font:
	if _font_sans == null and ResourceLoader.exists("res://assets/fonts/bahnschrift.ttf"):
		_font_sans = load("res://assets/fonts/bahnschrift.ttf")
	return _font_sans


static func get_mono_font() -> Font:
	if _font_mono == null and ResourceLoader.exists("res://assets/fonts/consola.ttf"):
		_font_mono = load("res://assets/fonts/consola.ttf")
	return _font_mono


static func get_mono_bold_font() -> Font:
	if _font_mono_bold == null and ResourceLoader.exists("res://assets/fonts/consolab.ttf"):
		_font_mono_bold = load("res://assets/fonts/consolab.ttf")
	return _font_mono_bold


static func get_theme(high_contrast: bool = false) -> Theme:
	if _cached_theme != null and not high_contrast:
		return _cached_theme

	var t := Theme.new()
	var f_sans := get_sans_font()
	var f_mono := get_mono_font()
	var f_mono_b := get_mono_bold_font()
	if f_mono:
		t.default_font = f_mono
	elif f_sans:
		t.default_font = f_sans
	t.default_font_size = 14

	var bg_panel := Color(0.02, 0.025, 0.03, 0.98) if high_contrast else COL_CHARCOAL
	var border_col := COL_AMBER if high_contrast else COL_WARM_BORDER
	var txt_col := Color(0.98, 0.97, 0.94) if high_contrast else COL_TEXT_MAIN

	# PanelContainer — sharp 1997 0px corner double-width border
	var panel_sb := make_box(bg_panel, border_col, 2, 14)
	t.set_stylebox("panel", "PanelContainer", panel_sb)

	# Button states — crisp 1997 retro console / TESLA security system buttons
	var btn_norm := make_box(COL_OLIVE_DARK, COL_WARM_BORDER, 2, 10)
	var btn_hover := make_box(COL_GREY_GREEN, COL_AMBER, 2, 10)
	var btn_press := make_box(Color(0.22, 0.17, 0.10, 0.98), COL_ORANGE, 2, 10)
	var btn_focus := make_box(COL_GREY_GREEN, COL_AMBER, 2, 10)
	var btn_dis := make_box(Color(0.06, 0.07, 0.07, 0.65), Color(0.22, 0.24, 0.22, 0.6), 1, 10)
	if f_mono_b:
		t.set_font("font", "Button", f_mono_b)

	t.set_stylebox("normal", "Button", btn_norm)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_press)
	t.set_stylebox("focus", "Button", btn_focus)
	t.set_stylebox("disabled", "Button", btn_dis)
	t.set_color("font_color", "Button", txt_col)
	t.set_color("font_hover_color", "Button", COL_AMBER)
	t.set_color("font_pressed_color", "Button", Color(0.98, 0.88, 0.65))
	t.set_color("font_focus_color", "Button", COL_AMBER)
	t.set_color("font_disabled_color", "Button", Color(0.40, 0.42, 0.40, 0.7))

	# Labels & RichTextLabel
	t.set_color("font_color", "Label", txt_col)
	t.set_color("default_color", "RichTextLabel", txt_col)

	# LineEdit
	var le_norm := make_box(Color(0.06, 0.075, 0.07, 0.96), COL_WARM_BORDER, 1, 8)
	var le_foc := make_box(Color(0.08, 0.095, 0.09, 0.98), COL_AMBER, 1, 8)
	t.set_stylebox("normal", "LineEdit", le_norm)
	t.set_stylebox("focus", "LineEdit", le_foc)
	t.set_color("font_color", "LineEdit", txt_col)
	if f_mono:
		t.set_font("font", "LineEdit", f_mono)

	# TabContainer / TabBar
	t.set_stylebox("panel", "TabContainer", make_box(COL_OLIVE_DARK, COL_WARM_BORDER, 1, 12))
	t.set_stylebox("tab_selected", "TabContainer", make_box(COL_GREY_GREEN, COL_AMBER, 1, 8))
	t.set_stylebox("tab_unselected", "TabContainer", make_box(COL_CHARCOAL, COL_WARM_BORDER, 1, 8))
	t.set_stylebox("tab_hovered", "TabContainer", make_box(COL_OLIVE_DARK, COL_AMBER, 1, 8))
	t.set_color("font_selected_color", "TabContainer", COL_AMBER)
	t.set_color("font_unselected_color", "TabContainer", COL_TEXT_DIM)

	# OptionButton & CheckButton
	t.set_stylebox("normal", "OptionButton", btn_norm)
	t.set_stylebox("hover", "OptionButton", btn_hover)
	t.set_stylebox("pressed", "OptionButton", btn_press)
	t.set_color("font_color", "OptionButton", txt_col)
	t.set_color("font_color", "CheckButton", txt_col)
	t.set_color("font_color", "CheckBox", txt_col)

	# ProgressBar
	t.set_stylebox("background", "ProgressBar", make_box(Color(0.05, 0.06, 0.06, 0.9), COL_WARM_BORDER, 1, 2))
	t.set_stylebox("fill", "ProgressBar", make_box(COL_AMBER, COL_AMBER, 0, 2))

	if not high_contrast:
		_cached_theme = t
	return t


static func make_box(bg: Color, border: Color, border_w: int = 2, pad: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_content_margin_all(pad)
	# Sharp 0px PS1 pixel-crisp corners (no modern rounded SaaS corners!)
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	return sb


static func make_paper_box(pad: int = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PAPER
	sb.border_color = Color(0.48, 0.43, 0.34, 0.95)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(pad)
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	return sb


static func load_icon(icon_name: String) -> Texture2D:
	var p := "res://assets/graphics/icons/%s.png" % icon_name
	if ResourceLoader.exists(p):
		var res: Resource = load(p)
		if res is Texture2D:
			return res as Texture2D
	return null
