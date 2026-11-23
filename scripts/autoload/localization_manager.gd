extends Node

signal language_changed(lang: String)

const SUPPORTED_LANGS := ["en", "sk", "cs"]
const LANG_LABELS := {
	"en": "English",
	"sk": "Slovenčina",
	"cs": "Čeština",
}

var current_lang: String = "en"
var _tables: Dictionary = {}


func _enter_tree() -> void:
	_load_all_tables()


func _load_all_tables() -> void:
	_tables.clear()
	for code: String in SUPPORTED_LANGS:
		var path := "res://data/localization/strings_%s.json" % code
		if FileAccess.file_exists(path):
			var fa := FileAccess.open(path, FileAccess.READ)
			if fa:
				var parsed: Variant = JSON.parse_string(fa.get_as_text())
				fa.close()
				if parsed is Dictionary:
					_tables[code] = parsed


func set_language(lang: String) -> void:
	var clean := lang.to_lower()
	if not (clean in SUPPORTED_LANGS):
		clean = "en"
	if current_lang == clean:
		return
	current_lang = clean
	emit_signal("language_changed", current_lang)


func tr_key(key: String, fallback: String = "") -> String:
	if _tables.has(current_lang):
		var tbl: Dictionary = _tables[current_lang]
		if tbl.has(key):
			return str(tbl[key])
	if _tables.has("en"):
		var en_tbl: Dictionary = _tables["en"]
		if en_tbl.has(key):
			return str(en_tbl[key])
	return fallback if not fallback.is_empty() else key


func get_key_label(action_name: String) -> String:
	if not InputMap.has_action(action_name):
		return action_name.to_upper()
	var events := InputMap.action_get_events(action_name)
	for ev: InputEvent in events:
		if ev is InputEventKey:
			var k := ev as InputEventKey
			var code: int = k.physical_keycode if k.physical_keycode != 0 else k.keycode
			return OS.get_keycode_string(code).to_upper()
		elif ev is InputEventJoypadButton:
			return "BTN %d" % (ev as InputEventJoypadButton).button_index
		elif ev is InputEventMouseButton:
			var mb := (ev as InputEventMouseButton).button_index
			return "LMB" if mb == MOUSE_BUTTON_LEFT else ("RMB" if mb == MOUSE_BUTTON_RIGHT else "MB%d" % mb)
	return action_name.to_upper()


func get_supported_languages() -> Array[String]:
	var out: Array[String] = []
	for l: String in SUPPORTED_LANGS:
		out.append(l)
	return out
