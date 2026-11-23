class_name JavorNotebookUI
extends PanelContainer

# Prompt 08 Part 4 — Redesigned Simple, Readable 1996 Guard Paper Notebook ("Less Is More"):
# - Exactly FOUR clean primary sections: 1. SHIFT | 2. MAP | 3. NOTES | 4. EVIDENCE
# - Plus a small unobtrusive TUTORIAL button in the footer to reopen/review training anytime
# - Aged worn cover, muted 2-3 paper tones, pencil ink, checkboxes, page numbers, crisp typography
# - Progressive handwriting animation + pencil scratch sound + accurate timestamps when logging entries!

signal closed
signal anomaly_checked_off(anomaly_id: String)
signal incident_note_submitted(note_text: String)
signal tutorial_reopen_requested
signal section_viewed(section_idx: int)

const ThemeLib = preload("res://scripts/ui/javor_theme.gd")
const MapUIScript = preload("res://scripts/ui/map_ui.gd")

const SECTION_DEFS := [
	{"key": "nb_shift", "label": "SHIFT"},
	{"key": "nb_map", "label": "MAP"},
	{"key": "nb_notes", "label": "NOTES"},
	{"key": "nb_evidence", "label": "EVIDENCE"},
]

var current_page: int = 0
var _page_buttons: Array[Button] = []
var _left_title: Label
var _left_page_num: Label
var _right_page_num: Label
var _left_scroll: ScrollContainer
var _left_box: VBoxContainer
var _right_scroll: ScrollContainer
var _right_box: VBoxContainer
var _feedback_lbl: Label
var _map_widget: Control
var _player_pos: Vector3 = Vector3(-15.8, 0.2, -54.5)
var _selected_doc_id: String = "doc_patrol_order"
var _selected_tape_transcript: String = ""
var _handwriting_lbl: Label
var _handwriting_progress: float = 1.0
var _animate_latest_incident: bool = false
var _show_tutorial_sheet: bool = false
var patrol_mgr: Node = null
var nav_hint_mgr: Node = null


func set_navigation_sources(p_patrol_mgr: Node, p_nav_hint_mgr: Node = null) -> void:
	patrol_mgr = p_patrol_mgr
	nav_hint_mgr = p_nav_hint_mgr
	if _map_widget and _map_widget.has_method("set_navigation_sources"):
		_map_widget.set_navigation_sources(p_patrol_mgr, p_nav_hint_mgr)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = ThemeLib.get_theme()
	custom_minimum_size = Vector2(900, 580)
	# Worn dark-brown cardboard notebook cover with simple 2px border
	add_theme_stylebox_override("panel", ThemeLib.make_box(Color(0.18, 0.14, 0.10, 0.99), Color(0.38, 0.30, 0.21), 2, 12))
	_build_ui()


func _process(delta: float) -> void:
	if _handwriting_lbl and is_instance_valid(_handwriting_lbl) and _handwriting_progress < 1.0:
		# Realistic handwriting cadence with tiny micro-pauses between words!
		var rate: float = 0.95 + 0.35 * sin(_handwriting_progress * 18.0)
		_handwriting_progress = minf(1.0, _handwriting_progress + delta * rate)
		var total_chars: int = _handwriting_lbl.text.length()
		_handwriting_lbl.visible_characters = maxi(1, int(round(float(total_chars) * _handwriting_progress)))
		if _handwriting_progress >= 1.0:
			_handwriting_lbl.visible_characters = -1


func get_section_count() -> int:
	return SECTION_DEFS.size()


func get_section_names() -> PackedStringArray:
	var out := PackedStringArray()
	for s: Dictionary in SECTION_DEFS:
		out.append(str(s["label"]))
	return out


func is_handwriting_animating() -> bool:
	return _handwriting_lbl != null and is_instance_valid(_handwriting_lbl) and _handwriting_progress < 1.0


func trigger_progressive_handwriting() -> void:
	_animate_latest_incident = true
	AudioSynth.play_sfx("pencil_check", -5.0, randf_range(0.95, 1.05))


func _tr(k: String, fb: String = "") -> String:
	var loc := get_node_or_null("/root/LocalizationManager")
	return loc.tr_key(k, fb) if loc and loc.has_method("tr_key") else (fb if not fb.is_empty() else k)


func _build_ui() -> void:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)

	# Simple single row of 4 clean paper index tabs: SHIFT | MAP | NOTES | EVIDENCE
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	outer.add_child(tab_row)

	_page_buttons.clear()
	for i: int in range(SECTION_DEFS.size()):
		var sec: Dictionary = SECTION_DEFS[i]
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, str(sec["label"])]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 32)
		b.add_theme_font_size_override("font_size", 13)
		var pidx := i
		b.pressed.connect(func():
			_show_tutorial_sheet = false
			select_page(pidx)
		)
		tab_row.add_child(b)
		_page_buttons.append(b)

	# Simple Aged Paper Two-Page Spread (clean muted cream/manila tones, center binding shadow)
	var spread_host := Control.new()
	spread_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(spread_host)

	var paper_bg := TextureRect.new()
	paper_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper_bg.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists("res://assets/graphics/ui/notebook_paper_bg.png"):
		var tx: Resource = load("res://assets/graphics/ui/notebook_paper_bg.png")
		if tx is Texture2D:
			paper_bg.texture = tx as Texture2D
	spread_host.add_child(paper_bg)

	# Subtle warm paper tint overlay so ink contrast is effortless to read
	var paper_tint := ColorRect.new()
	paper_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper_tint.color = Color(0.93, 0.90, 0.82, 0.42)
	paper_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spread_host.add_child(paper_tint)

	var spine := ColorRect.new()
	spine.set_anchors_preset(Control.PRESET_CENTER_TOP)
	spine.anchor_bottom = 1.0
	spine.offset_left = -2
	spine.offset_right = 2
	spine.color = Color(0.28, 0.24, 0.19, 0.35)
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spread_host.add_child(spine)

	var spread := HBoxContainer.new()
	spread.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spread.offset_left = 26
	spread.offset_top = 16
	spread.offset_right = -26
	spread.offset_bottom = -28
	spread.add_theme_constant_override("separation", 38)
	spread_host.add_child(spread)

	# Left Page
	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 6)
	spread.add_child(left_col)

	_left_title = Label.new()
	_left_title.add_theme_color_override("font_color", Color(0.14, 0.12, 0.10))
	_left_title.add_theme_font_size_override("font_size", 16)
	if ThemeLib.get_mono_bold_font():
		_left_title.add_theme_font_override("font", ThemeLib.get_mono_bold_font())
	left_col.add_child(_left_title)

	var underline := ColorRect.new()
	underline.custom_minimum_size = Vector2(0, 1)
	underline.color = Color(0.32, 0.28, 0.22, 0.55)
	left_col.add_child(underline)

	_feedback_lbl = Label.new()
	_feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_lbl.add_theme_color_override("font_color", Color(0.16, 0.38, 0.20))
	_feedback_lbl.add_theme_font_size_override("font_size", 12)
	left_col.add_child(_feedback_lbl)

	_left_scroll = ScrollContainer.new()
	_left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.add_child(_left_scroll)

	_left_box = VBoxContainer.new()
	_left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_box.add_theme_constant_override("separation", 6)
	_left_scroll.add_child(_left_box)

	# Right Page
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 6)
	spread.add_child(right_col)

	_map_widget = MapUIScript.new()
	_map_widget.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_widget.visible = false
	right_col.add_child(_map_widget)

	_right_scroll = ScrollContainer.new()
	_right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(_right_scroll)

	_right_box = VBoxContainer.new()
	_right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_box.add_theme_constant_override("separation", 7)
	_right_scroll.add_child(_right_box)

	# Small printed page numbers at bottom corners of the paper spread
	_left_page_num = Label.new()
	_left_page_num.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_left_page_num.offset_left = 28
	_left_page_num.offset_top = -24
	_left_page_num.offset_right = 120
	_left_page_num.offset_bottom = -4
	_left_page_num.add_theme_color_override("font_color", Color(0.32, 0.28, 0.23))
	_left_page_num.add_theme_font_size_override("font_size", 11)
	spread_host.add_child(_left_page_num)

	_right_page_num = Label.new()
	_right_page_num.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_right_page_num.offset_left = -120
	_right_page_num.offset_top = -24
	_right_page_num.offset_right = -28
	_right_page_num.offset_bottom = -4
	_right_page_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_right_page_num.add_theme_color_override("font_color", Color(0.32, 0.28, 0.23))
	_right_page_num.add_theme_font_size_override("font_size", 11)
	spread_host.add_child(_right_page_num)

	# Simple Footer: Prev / Next / Small Tutorial Button / Close
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	outer.add_child(foot)

	var prev_b := Button.new()
	prev_b.text = "◀ PREV"
	prev_b.pressed.connect(func():
		_show_tutorial_sheet = false
		select_page(posmod(current_page - 1, SECTION_DEFS.size()))
	)
	foot.add_child(prev_b)

	var next_b := Button.new()
	next_b.text = "NEXT ▶"
	next_b.pressed.connect(func():
		_show_tutorial_sheet = false
		select_page(posmod(current_page + 1, SECTION_DEFS.size()))
	)
	foot.add_child(next_b)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp)

	var tut_b := Button.new()
	tut_b.name = "TutorialGuideBtn"
	tut_b.text = "TUTORIAL & CONTROLS"
	tut_b.add_theme_font_size_override("font_size", 11)
	tut_b.pressed.connect(func():
		AudioSynth.play_ui_sfx("page_turn", -6.0)
		_show_tutorial_sheet = not _show_tutorial_sheet
		refresh_content(_player_pos)
	)
	foot.add_child(tut_b)

	var close_b := Button.new()
	close_b.text = "CLOSE [TAB / ESC]"
	close_b.pressed.connect(func():
		AudioSynth.play_ui_sfx("page_turn")
		emit_signal("closed")
	)
	foot.add_child(close_b)


func set_feedback(msg: String, ok: bool = true) -> void:
	if _feedback_lbl:
		_feedback_lbl.text = msg
		_feedback_lbl.add_theme_color_override("font_color", Color(0.14, 0.42, 0.20) if ok else Color(0.64, 0.16, 0.14))


func open_to_page(page_idx: int, player_pos: Vector3 = Vector3(-15.8, 0.2, -54.5)) -> void:
	_player_pos = player_pos
	_show_tutorial_sheet = false
	# Map legacy caller page indices cleanly onto the 4 simple sections!
	var mapped: int = clampi(page_idx, 0, SECTION_DEFS.size() - 1)
	if page_idx == 6:
		mapped = 1 # Map
	elif page_idx == 5:
		mapped = 3 # Evidence
	select_page(mapped, false)


func select_page(page_idx: int, play_sfx: bool = true) -> void:
	current_page = clampi(page_idx, 0, SECTION_DEFS.size() - 1)
	if play_sfx:
		AudioSynth.play_ui_sfx("page_turn", -6.0)
	emit_signal("section_viewed", current_page)
	refresh_content(_player_pos)


func refresh_content(player_pos: Vector3 = Vector3(-15.8, 0.2, -54.5)) -> void:
	_player_pos = player_pos
	for i: int in range(_page_buttons.size()):
		var sec: Dictionary = SECTION_DEFS[i]
		_page_buttons[i].text = "%d. %s" % [i + 1, str(sec["label"])]
		_page_buttons[i].modulate = Color(1.0, 0.90, 0.62) if (not _show_tutorial_sheet and i == current_page) else Color(0.76, 0.78, 0.76)

	for ch: Node in _left_box.get_children():
		ch.queue_free()
	for ch: Node in _right_box.get_children():
		ch.queue_free()
	_map_widget.visible = false
	_right_scroll.visible = true

	if _show_tutorial_sheet:
		_left_title.text = "FIELD GUIDE & TUTORIAL"
		_left_page_num.text = "p. T-1"
		_right_page_num.text = "p. T-2"
		_render_tutorial_reference()
		return

	var cur_sec: Dictionary = SECTION_DEFS[current_page]
	_left_title.text = str(cur_sec["label"])
	_left_page_num.text = "p. %d" % (current_page * 2 + 1)
	_right_page_num.text = "p. %d" % (current_page * 2 + 2)

	match current_page:
		0: _render_shift_section()
		1: _render_map_section()
		2: _render_notes_section()
		3: _render_evidence_section()


func _add_ink(parent: Control, text: String, col: Color = Color(0.14, 0.13, 0.11), size_px: int = 13, mono: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", size_px)
	if mono and ThemeLib.get_mono_font():
		l.add_theme_font_override("font", ThemeLib.get_mono_font())
	parent.add_child(l)
	return l


# ---------------------------------------------------------------------------
# 1. SHIFT — Current Night, Ordered Assignments, Checkboxes & Basic Instructions
# ---------------------------------------------------------------------------
func _render_shift_section() -> void:
	var gs := get_node_or_null("/root/GameState")
	var st := get_node_or_null("/root/StoryManager")
	var n: int = gs.current_night if gs else 1
	var rt: Dictionary = patrol_mgr.get_route(n) if patrol_mgr and patrol_mgr.has_method("get_route") else {}
	var ch: Dictionary = st.get_chapter_data(n) if st else {}
	var date_raw: String = str(rt.get("date", ch.get("date", "18.11.1996")))
	var time_now: String = gs.get_clock_time_only() if gs and gs.has_method("get_clock_time_only") else "22:00"

	_add_ink(_left_box, "NIGHT %02d  |  %s  |  %s\nGUARD: Martin Kovac   |   SUPERVISOR: Jozef Varga" % [n, date_raw, time_now], Color(0.18, 0.16, 0.14), 13, true)

	if patrol_mgr and patrol_mgr.has_method("get_checkpoints"):
		var cps: Array = patrol_mgr.get_checkpoints(n)
		var active_cp: Dictionary = patrol_mgr.get_active_checkpoint(n)
		var active_id: String = str(active_cp.get("id", ""))
		_add_ink(_left_box, "\nASSIGNMENTS:", Color(0.42, 0.18, 0.12), 13, true)
		for cp_var in cps:
			var cp: Dictionary = cp_var
			var cid: String = str(cp.get("id", ""))
			var done: bool = patrol_mgr.is_checkpoint_completed(cid)
			var vis: bool = patrol_mgr.is_checkpoint_visited(cid)
			var ts: String = str(patrol_mgr.completed_checkpoints.get(cid, ""))
			var box_ch: String = "[✓]" if done else ("[•]" if vis else "[ ]")
			var stamp: String = ("  %s" % ts) if done else ("  (inspect)" if (vis and not done) else "")
			var col: Color = Color(0.16, 0.38, 0.18) if done else (Color(0.58, 0.16, 0.10) if cid == active_id else Color(0.16, 0.15, 0.13))
			_add_ink(_left_box, "%s %d. %s%s" % [box_ch, int(cp.get("num", 1)), str(cp.get("name", "")), stamp], col, 13, true)

		if not active_cp.is_empty():
			_add_ink(_right_box, "NEXT STOP — #%d %s" % [int(active_cp.get("num", 1)), str(active_cp.get("name", ""))], Color(0.46, 0.16, 0.10), 14, true)
			_add_ink(_right_box, "%s\n\nROUTE: %s\nACTION: %s" % [
				str(active_cp.get("what", "")),
				str(active_cp.get("where", "")),
				str(active_cp.get("action", "")),
			], Color(0.16, 0.15, 0.13), 13)
	else:
		_add_ink(_left_box, "\nSHIFT TASKS:", Color(0.42, 0.18, 0.12), 13, true)
		if gs:
			for q: Dictionary in gs.active_quests:
				var done: bool = bool(q.get("done", false))
				_add_ink(_left_box, "%s %s" % ["[✓]" if done else "[ ]", str(q.get("label", ""))], Color(0.16, 0.38, 0.18) if done else Color(0.16, 0.15, 0.13), 13, true)

	_add_ink(_right_box, "\nSHIFT INSTRUCTIONS:", Color(0.42, 0.18, 0.12), 13, true)
	_add_ink(_right_box, str(rt.get("briefing", ch.get("summary", "Check all entrances, keep doors locked, and record any unusual incidents."))), Color(0.22, 0.20, 0.17), 12)

	if gs:
		_add_ink(_right_box, "\nSTATUS: Battery %d%%  |  Spares: %d  |  Keys: %d  |  CCTV: %d/6" % [
			int(round(gs.flashlight_battery)), gs.spare_batteries, gs.collected_keys.size(), gs.inspected_cctv_cams.size()
		], Color(0.28, 0.25, 0.21), 12, true)

	if st and bool(st.get_flag("climax_night1_silent_phone", false)):
		_add_ink(_right_box, "\n[PENCIL MARGIN NOTE]:\n\"When you hear your own name, do not answer.\"", Color(0.14, 0.22, 0.48), 13, true)


# ---------------------------------------------------------------------------
# 2. MAP — Residential District Layout, Main Patrol Path & Discovered Locations
# ---------------------------------------------------------------------------
func _render_map_section() -> void:
	var gs := get_node_or_null("/root/GameState")
	var n: int = gs.current_night if gs else 1
	_add_ink(_left_box, "PATROL ROUTE — NIGHT %02d:" % n, Color(0.42, 0.18, 0.12), 13, true)
	if patrol_mgr and patrol_mgr.has_method("get_checkpoints"):
		for cp_var in patrol_mgr.get_checkpoints(n):
			var cp: Dictionary = cp_var
			var cid: String = str(cp.get("id", ""))
			var done: bool = patrol_mgr.is_checkpoint_completed(cid)
			var box_s: String = "[✓]" if done else "[ ]"
			_add_ink(_left_box, "%s %d. %s" % [box_s, int(cp.get("num", 1)), str(cp.get("name", ""))], Color(0.16, 0.38, 0.18) if done else Color(0.16, 0.15, 0.13), 12, true)

	_add_ink(_left_box, "\nDISCOVERED LOCATIONS:", Color(0.42, 0.18, 0.12), 13, true)
	var zones := {
		"security_office": "Security Office (Hub & CCTV)",
		"parking_lot": "South Parking Lot",
		"central_park": "Central Park & Playground",
		"commercial_area": "Newsstand, Night Shop & Grocery",
		"garages": "Garages 01–10",
		"technical_area": "Substation & Boiler Plant",
		"apartments": "Apartment Blocks A–F",
		"northern_forest": "Northern Path & Trees",
	}
	for k: String in zones.keys():
		var vis: bool = bool(gs.visited_zones.get(k, false)) if gs else false
		_add_ink(_left_box, "%s %s" % ["•" if vis else "?", zones[k] if vis else "Unvisited sector"], Color(0.18, 0.16, 0.14) if vis else Color(0.46, 0.43, 0.38), 12)

	_right_scroll.visible = false
	_map_widget.visible = true
	if _map_widget.has_method("set_navigation_sources"):
		_map_widget.set_navigation_sources(patrol_mgr, nav_hint_mgr)
	_map_widget.refresh_map(_player_pos)


# ---------------------------------------------------------------------------
# 3. NOTES — Personal Observations, Incident Reports & Character Statements
# ---------------------------------------------------------------------------
func _render_notes_section() -> void:
	var gs := get_node_or_null("/root/GameState")
	var st := get_node_or_null("/root/StoryManager")
	_handwriting_lbl = null

	_add_ink(_left_box, "INCIDENT REPORTS & OBSERVATIONS:", Color(0.42, 0.18, 0.12), 13, true)
	if gs and not gs.notebook_entries.is_empty():
		var count: int = gs.notebook_entries.size()
		for idx: int in range(count):
			var ne: Dictionary = gs.notebook_entries[idx]
			var lbl := _add_ink(_left_box, "• [%s] %s — %s" % [
				str(ne.get("time", "")), str(ne.get("title", "NOTE")), str(ne.get("note", ""))
			], Color(0.16, 0.15, 0.13), 12, true)
			if _animate_latest_incident and idx == count - 1:
				_handwriting_lbl = lbl
				_handwriting_progress = 0.05
				lbl.visible_characters = 2
				_animate_latest_incident = false
	else:
		_add_ink(_left_box, "(No entries written yet this shift.)", Color(0.44, 0.40, 0.35), 12)

	if st and not st.resident_notes.is_empty():
		_add_ink(_left_box, "\nRESIDENT STATEMENTS:", Color(0.42, 0.18, 0.12), 13, true)
		for cid: String in st.resident_notes.keys():
			var cname: String = str(st.CHARACTERS.get(cid, {}).get("name", cid))
			_add_ink(_left_box, "%s: %s" % [cname, str(st.resident_notes[cid][-1])], Color(0.18, 0.24, 0.42), 12)

	# Right page: Pencil Entry Form + Quick Patrol Log Stamps + Important Emergency Numbers
	_add_ink(_right_box, "WRITE NEW ENTRY (PENCIL):", Color(0.42, 0.18, 0.12), 13, true)
	var le := LineEdit.new()
	le.placeholder_text = "Write observation (e.g., Main gate door checked and locked)..."
	_right_box.add_child(le)

	var wb := Button.new()
	wb.text = "WRITE IN NOTEBOOK"
	wb.pressed.connect(func():
		if not le.text.strip_edges().is_empty():
			var txt := le.text
			le.text = ""
			trigger_progressive_handwriting()
			emit_signal("incident_note_submitted", txt)
			refresh_content(_player_pos)
	)
	_right_box.add_child(wb)

	_add_ink(_right_box, "\nQUICK PATROL LOG STAMPS:", Color(0.32, 0.28, 0.23), 12, true)
	for qtxt: String in [
		"Door checked — shut and locked.",
		"Unusual footsteps heard in stairwell.",
		"Entrance door found unlocked / propped ajar.",
		"Unknown figure observed near garages.",
	]:
		var qb := Button.new()
		qb.text = "+ " + qtxt
		qb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		qb.add_theme_font_size_override("font_size", 11)
		var cap := qtxt
		qb.pressed.connect(func():
			trigger_progressive_handwriting()
			emit_signal("incident_note_submitted", cap)
			refresh_content(_player_pos)
		)
		_right_box.add_child(qb)

	_add_ink(_right_box, "\nEMERGENCY & ESTATE NUMBERS:\nSecurity Office: Ext. 101  |  Jozef Varga: 07-542-198\nPolice: 158  |  Ambulance: 155  |  Fire: 150", Color(0.30, 0.27, 0.22), 11, true)


# ---------------------------------------------------------------------------
# 4. EVIDENCE — Discovered Items, Documents, Cassette Recordings & Case Log
# ---------------------------------------------------------------------------
func _render_evidence_section() -> void:
	var st := get_node_or_null("/root/StoryManager")
	var gs := get_node_or_null("/root/GameState")
	var ad := get_node_or_null("/root/AnomalyDirector")

	if gs:
		_add_ink(_left_box, "COLLECTED EVIDENCE & KEYS:", Color(0.42, 0.18, 0.12), 13, true)
		_add_ink(_left_box, "Case Evidence Items: %d\nKeys Carried: %s" % [
			gs.evidence_items.size(),
			", ".join(gs.collected_keys) if not gs.collected_keys.is_empty() else "Standard Guard Keyring",
		], Color(0.16, 0.15, 0.13), 12, true)

	if st:
		_add_ink(_left_box, "\nDOCUMENTS (%d / %d):" % [st.discovered_documents.size(), st.DOCUMENTS.size()], Color(0.42, 0.18, 0.12), 12, true)
		for did: String in st.discovered_documents:
			var doc: Dictionary = st.DOCUMENTS.get(did, {})
			var b := Button.new()
			b.text = "• %s" % str(doc.get("title", did))
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 11)
			var td := did
			b.pressed.connect(func():
				AudioSynth.play_ui_sfx("page_turn")
				_selected_doc_id = td
				_selected_tape_transcript = ""
				refresh_content(_player_pos)
			)
			_left_box.add_child(b)

		_add_ink(_left_box, "\nCASSETTES (%d / %d):" % [st.discovered_tapes.size(), st.TAPES.size()], Color(0.42, 0.18, 0.12), 12, true)
		for tid: String in st.discovered_tapes:
			var tp: Dictionary = st.TAPES.get(tid, {})
			var hb := HBoxContainer.new()
			_left_box.add_child(hb)
			var pb := Button.new()
			pb.text = "▶ " + str(tp.get("label", tid))
			pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			pb.add_theme_font_size_override("font_size", 11)
			var ak := str(tp.get("audio", "music_walkman_tape"))
			var fk := str(tp.get("flag", ""))
			var ts := str(tp.get("transcript", ""))
			var tl := str(tp.get("label", tid))
			pb.pressed.connect(func():
				AudioSynth.play_tape(ak)
				if not fk.is_empty():
					st.set_flag(fk, true)
				_selected_tape_transcript = "CASSETTE: %s\n\n%s" % [tl, ts]
				set_feedback("Playing: " + tl, true)
				refresh_content(_player_pos)
			)
			hb.add_child(pb)
			var sb := Button.new()
			sb.text = "■"
			sb.pressed.connect(func(): AudioSynth.stop_tape())
			hb.add_child(sb)

	# Spotted anomaly check-off (only spotted/active items so the page stays crisp & uncluttered!)
	if ad and gs:
		var spotted_list: Array[Dictionary] = []
		for entry: Dictionary in ad.get_all_anomalies():
			var aid: String = str(entry.get("id", ""))
			if (aid in gs.logged_anomalies_this_night) or (aid in gs.discovered_anomalies):
				spotted_list.append(entry)
		if not spotted_list.is_empty():
			_add_ink(_left_box, "\nSPOTTED INCIDENTS TO VERIFY:", Color(0.42, 0.18, 0.12), 12, true)
			for entry: Dictionary in spotted_list:
				var aid: String = str(entry.get("id", ""))
				var checked: bool = gs.is_anomaly_checked_in_notebook(aid)
				var row := HBoxContainer.new()
				_left_box.add_child(row)
				var lbl := Label.new()
				lbl.text = "%s — %s" % [aid, str(entry.get("title_en", aid))]
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.add_theme_color_override("font_color", Color(0.16, 0.40, 0.20) if checked else Color(0.56, 0.22, 0.10))
				lbl.add_theme_font_size_override("font_size", 11)
				row.add_child(lbl)
				var cb := Button.new()
				cb.text = "✓" if checked else "LOG"
				cb.disabled = checked
				var taid := aid
				cb.pressed.connect(func(): emit_signal("anomaly_checked_off", taid))
				row.add_child(cb)

	# Right page: selected document or cassette transcript
	if not _selected_tape_transcript.is_empty():
		_add_ink(_right_box, "CASSETTE TRANSCRIPT:", Color(0.46, 0.16, 0.12), 13, true)
		_add_ink(_right_box, _selected_tape_transcript, Color(0.16, 0.15, 0.13), 12, true)
	elif st:
		var sel: Dictionary = st.DOCUMENTS.get(_selected_doc_id, st.DOCUMENTS["doc_patrol_order"])
		_add_ink(_right_box, str(sel.get("title", "")), Color(0.46, 0.16, 0.12), 14, true)
		_add_ink(_right_box, "Date: %s  |  Source: %s" % [str(sel.get("date", "")), str(sel.get("source", ""))], Color(0.34, 0.30, 0.25), 11, true)
		_add_ink(_right_box, "\n" + str(sel.get("body", "")), Color(0.16, 0.15, 0.13), 12, true)


# ---------------------------------------------------------------------------
# TUTORIAL REFERENCE SHEET (accessible anytime via footer 'TUTORIAL & CONTROLS' button)
# ---------------------------------------------------------------------------
func _render_tutorial_reference() -> void:
	var loc := get_node_or_null("/root/LocalizationManager")
	var k_int: String = loc.get_key_label("interact") if loc else "E"
	var k_nb: String = loc.get_key_label("notebook_key") if loc else "N"
	var k_fl: String = loc.get_key_label("flashlight") if loc else "F"
	var k_hp: String = loc.get_key_label("toggle_headphones") if loc else "H"

	_add_ink(_left_box, "ESSENTIAL GUARD CONTROLS:", Color(0.42, 0.18, 0.12), 13, true)
	_add_ink(_left_box, "• MOVE: W A S D   |   SPRINT: SHIFT   |   CROUCH: CTRL\n• LOOK AROUND: MOUSE\n• INTERACT / OPEN DOORS: [%s]\n• LOCK / UNLOCK DOOR: [L] (or equip Keys + LMB)\n• SWITCH EQUIPMENT: MOUSE WHEEL or [0–6]\n• EMPTY HANDS: [0]\n• FLASHLIGHT ON / OFF: [%s]   |   RELOAD CELL: [R]\n• NOTEBOOK: [%s] or [TAB]\n• RADIO CHECK: [4] + LMB\n• WALKMAN HEADPHONES: [%s]" % [k_int, k_fl, k_nb, k_hp], Color(0.16, 0.15, 0.13), 12, true)

	_add_ink(_right_box, "SHIFT TUTORIAL & REPLAY:", Color(0.42, 0.18, 0.12), 13, true)
	_add_ink(_right_box, "Jozef Varga walks you through every tool and your first guided patrol on Night 1.\n\nIf you skipped the tutorial or want to review the step-by-step office training again, restart it below:", Color(0.20, 0.18, 0.16), 12)

	var replay_btn := Button.new()
	replay_btn.text = "REOPEN INTERACTIVE TUTORIAL"
	replay_btn.pressed.connect(func():
		emit_signal("tutorial_reopen_requested")
		emit_signal("closed")
	)
	_right_box.add_child(replay_btn)
