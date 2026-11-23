class_name JavorSaveLoadPanel
extends PanelContainer

signal slot_chosen(slot_idx: int, mode: String)
signal closed

const ThemeLib = preload("res://scripts/ui/javor_theme.gd")

var mode: String = "load" # "load", "save", "new_game"
var _title_lbl: Label
var _slots_box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = ThemeLib.get_theme()
	custom_minimum_size = Vector2(720, 490)
	_build_ui()


func _tr(k: String, fb: String = "") -> String:
	var loc := get_node_or_null("/root/LocalizationManager")
	return loc.tr_key(k, fb) if loc and loc.has_method("tr_key") else (fb if not fb.is_empty() else k)


func open_for_mode(p_mode: String) -> void:
	mode = p_mode
	refresh_slots()


func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)

	_title_lbl = Label.new()
	_title_lbl.add_theme_color_override("font_color", ThemeLib.COL_AMBER)
	_title_lbl.add_theme_font_size_override("font_size", 20)
	if ThemeLib.get_mono_bold_font():
		_title_lbl.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
	vb.add_child(_title_lbl)

	_slots_box = VBoxContainer.new()
	_slots_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_slots_box.add_theme_constant_override("separation", 8)
	vb.add_child(_slots_box)

	var back_btn := Button.new()
	back_btn.text = _tr("menu_back", "BACK")
	back_btn.pressed.connect(func():
		AudioSynth.play_ui_sfx("ui_press")
		emit_signal("closed")
	)
	vb.add_child(back_btn)
	refresh_slots()


func refresh_slots() -> void:
	if not _slots_box:
		return
	if _title_lbl:
		_title_lbl.text = _tr("pause_save", "SAVE GAME") if mode == "save" else _tr("menu_load_game", "LOAD GAME")

	for c: Node in _slots_box.get_children():
		c.queue_free()

	var sm := get_node_or_null("/root/SaveManager")
	if not sm:
		return
	var summaries: Array = sm.get_all_slot_summaries()
	for s: Dictionary in summaries:
		var idx: int = int(s.get("slot_index", 0))
		var exists: bool = bool(s.get("exists", false))
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", ThemeLib.make_box(ThemeLib.COL_OLIVE_DARK, ThemeLib.COL_AMBER if exists else ThemeLib.COL_WARM_BORDER, 1, 10))
		_slots_box.add_child(card)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		card.add_child(hb)

		var info_vb := VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(info_vb)

		var slot_tag := "%s #%d" % [_tr("slot_auto", "AUTOSAVE") if idx == 0 else _tr("slot_manual", "SHIFT RECORD"), idx]
		var hdr := Label.new()
		if ThemeLib.get_mono_bold_font():
			hdr.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
		hdr.add_theme_color_override("font_color", ThemeLib.COL_AMBER if exists else ThemeLib.COL_TEXT_DIM)
		if exists:
			hdr.text = "%s  —  %s" % [slot_tag, str(s.get("chapter_title", "NIGHT 1"))]
		else:
			hdr.text = "%s  —  %s" % [slot_tag, _tr("slot_empty", "EMPTY RECORD SLOT")]
		info_vb.add_child(hdr)

		var sub := Label.new()
		sub.add_theme_color_override("font_color", ThemeLib.COL_TEXT_MAIN if exists else ThemeLib.COL_TEXT_DIM)
		sub.add_theme_font_size_override("font_size", 13)
		if exists:
			var pt: String = str(sm.format_playtime(float(s.get("playtime_sec", 0.0))))
			sub.text = "%s  |  %s  |  %s  |  %s  |  Saved: %s" % [
				str(s.get("date_time", "")),
				str(s.get("location", "Security Office")),
				str(s.get("difficulty", "standard")).to_upper(),
				pt,
				str(s.get("saved_at", "")),
			]
		else:
			sub.text = "No shift record written yet."
		info_vb.add_child(sub)

		var act_btn := Button.new()
		act_btn.custom_minimum_size = Vector2(126, 36)
		if mode == "save" or mode == "new_game":
			act_btn.text = _tr("slot_save", "SAVE HERE")
			act_btn.pressed.connect(func():
				AudioSynth.play_ui_sfx("ui_press")
				emit_signal("slot_chosen", idx, mode)
			)
		else:
			act_btn.text = _tr("slot_load", "LOAD")
			act_btn.disabled = not exists
			act_btn.pressed.connect(func():
				AudioSynth.play_ui_sfx("ui_press")
				emit_signal("slot_chosen", idx, mode)
			)
		hb.add_child(act_btn)

		if exists and mode != "new_game":
			var del_btn := Button.new()
			del_btn.text = _tr("slot_delete", "CLEAR")
			del_btn.custom_minimum_size = Vector2(76, 36)
			del_btn.pressed.connect(func():
				AudioSynth.play_ui_sfx("ui_press")
				sm.delete_slot(idx)
				refresh_slots()
			)
			hb.add_child(del_btn)
