extends Node

signal saves_updated

const SLOT_COUNT := 4
const SLOT_PREFIX := "user://javor_slot_"

var active_slot: int = 0
var session_playtime_sec: float = 0.0
var is_tracking_playtime: bool = false


func _process(delta: float) -> void:
	if is_tracking_playtime and not get_tree().paused:
		session_playtime_sec += delta


func _slot_path(slot_idx: int) -> String:
	return "%s%d.json" % [SLOT_PREFIX, clampi(slot_idx, 0, SLOT_COUNT - 1)]


func has_any_save() -> bool:
	for i: int in range(SLOT_COUNT):
		if FileAccess.file_exists(_slot_path(i)):
			return true
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.has_method("has_saved_run") and gs.has_saved_run():
		return true
	return false


func get_latest_slot() -> int:
	var best_slot := -1
	var best_unix := -1
	for i: int in range(SLOT_COUNT):
		var summ := get_slot_summary(i)
		if bool(summ.get("exists", false)):
			var ux := int(summ.get("saved_unix", 0))
			if ux > best_unix:
				best_unix = ux
				best_slot = i
	return best_slot


func get_slot_summary(slot_idx: int) -> Dictionary:
	var p := _slot_path(slot_idx)
	if not FileAccess.file_exists(p):
		return {
			"exists": false,
			"slot_index": slot_idx,
			"is_auto": (slot_idx == 0),
		}
	var fa := FileAccess.open(p, FileAccess.READ)
	if not fa:
		return {"exists": false, "slot_index": slot_idx, "is_auto": (slot_idx == 0)}
	var parsed: Variant = JSON.parse_string(fa.get_as_text())
	fa.close()
	if not (parsed is Dictionary):
		return {"exists": false, "slot_index": slot_idx, "is_auto": (slot_idx == 0)}
	var d: Dictionary = parsed
	var meta: Dictionary = d.get("meta", {})
	return {
		"exists": true,
		"slot_index": slot_idx,
		"is_auto": (slot_idx == 0),
		"shift_number": int(meta.get("shift_number", 1)),
		"chapter_title": str(meta.get("chapter_title", "NIGHT 1: THE ROUTINE")),
		"date_time": str(meta.get("date_time", "11.11.1996 22:00")),
		"location": str(meta.get("location", "Security Office")),
		"difficulty": str(meta.get("difficulty", "standard")),
		"playtime_sec": float(meta.get("playtime_sec", 0.0)),
		"saved_at": str(meta.get("saved_at", "")),
		"saved_unix": int(meta.get("saved_unix", 0)),
	}


func get_all_slot_summaries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i: int in range(SLOT_COUNT):
		out.append(get_slot_summary(i))
	return out


func save_slot(slot_idx: int, location_label: String = "Security Office", player_pos: Vector3 = Vector3.ZERO) -> bool:
	var gs := get_node_or_null("/root/GameState")
	var sm := get_node_or_null("/root/StoryManager")
	var sett := get_node_or_null("/root/SettingsManager")
	if not gs:
		return false

	active_slot = clampi(slot_idx, 0, SLOT_COUNT - 1)
	var ch_title := "NIGHT %d" % gs.current_night
	var loc := get_node_or_null("/root/LocalizationManager")
	if loc and loc.has_method("tr_key"):
		ch_title = loc.tr_key("ch_%d_title" % gs.current_night, ch_title)

	var dt_dict := Time.get_datetime_dict_from_system()
	var stamp := "%04d-%02d-%02d %02d:%02d" % [
		int(dt_dict.get("year", 1996)),
		int(dt_dict.get("month", 11)),
		int(dt_dict.get("day", 11)),
		int(dt_dict.get("hour", 22)),
		int(dt_dict.get("minute", 0)),
	]
	var payload := {
		"meta": {
			"shift_number": gs.current_night,
			"chapter_title": ch_title,
			"date_time": gs.get_formatted_vhs_time(),
			"location": location_label,
			"difficulty": str(sett.get_val("difficulty", "standard")) if sett else "standard",
			"playtime_sec": session_playtime_sec,
			"saved_at": stamp,
			"saved_unix": int(Time.get_unix_time_from_system()),
			"player_pos": [player_pos.x, player_pos.y, player_pos.z],
		},
		"game_state": {
			"current_night": gs.current_night,
			"shift_minutes": gs.shift_minutes,
			"hardcore_mode": gs.hardcore_mode,
			"flashlight_battery": gs.flashlight_battery,
			"spare_batteries": gs.spare_batteries,
			"signal_distortion": gs.signal_distortion,
			"sanity": gs.sanity,
			"headphones_on": gs.headphones_on,
			"player_spotted": gs.player_spotted,
			"completed_quests": gs.completed_quests,
			"quest_completion_times": gs.quest_completion_times,
			"previous_shifts_archive": gs.previous_shifts_archive,
			"tutorial_completed": gs.tutorial_completed,
			"collected_pages": gs.collected_pages,
			"collected_tapes": gs.collected_tapes,
			"evidence_items": gs.evidence_items,
			"unlocked_doors": gs.unlocked_doors,
			"collected_keys": gs.collected_keys,
			"door_states": gs.door_states,
			"notebook_entries": gs.notebook_entries,
			"tuned_radios": gs.tuned_radios,
			"cctv_anomalies_logged": gs.cctv_anomalies_logged,
			"story_flags": gs.story_flags,
		},
		"story_state": sm.export_state() if sm and sm.has_method("export_state") else {},
	}

	var fa := FileAccess.open(_slot_path(active_slot), FileAccess.WRITE)
	if not fa:
		return false
	fa.store_string(JSON.stringify(payload, "\t"))
	fa.close()
	gs.save_run()
	emit_signal("saves_updated")
	return true


func load_slot(slot_idx: int) -> bool:
	var p := _slot_path(slot_idx)
	if not FileAccess.file_exists(p):
		return false
	var fa := FileAccess.open(p, FileAccess.READ)
	if not fa:
		return false
	var parsed: Variant = JSON.parse_string(fa.get_as_text())
	fa.close()
	if not (parsed is Dictionary):
		return false

	var gs := get_node_or_null("/root/GameState")
	var sm := get_node_or_null("/root/StoryManager")
	var sett := get_node_or_null("/root/SettingsManager")
	if not gs:
		return false

	active_slot = clampi(slot_idx, 0, SLOT_COUNT - 1)
	var d: Dictionary = parsed
	var meta: Dictionary = d.get("meta", {})
	var gdata: Dictionary = d.get("game_state", {})
	var sdata: Dictionary = d.get("story_state", {})

	session_playtime_sec = float(meta.get("playtime_sec", 0.0))
	if sett:
		sett.set_val("difficulty", str(meta.get("difficulty", "standard")), false)

	var night_n := int(gdata.get("current_night", 1))
	gs.start_new_shift(night_n, bool(gdata.get("hardcore_mode", false)), false)
	gs.shift_minutes = int(gdata.get("shift_minutes", 0))
	gs.flashlight_battery = float(gdata.get("flashlight_battery", 100.0))
	gs.spare_batteries = int(gdata.get("spare_batteries", 2))
	gs.signal_distortion = float(gdata.get("signal_distortion", 8.0))
	gs.sanity = float(gdata.get("sanity", 100.0))
	gs.headphones_on = bool(gdata.get("headphones_on", false))
	gs.player_spotted = bool(gdata.get("player_spotted", false))
	gs.tuned_radios = int(gdata.get("tuned_radios", 0))
	gs.cctv_anomalies_logged = int(gdata.get("cctv_anomalies_logged", 0))

	gs.completed_quests.clear()
	for q in gdata.get("completed_quests", []):
		gs.completed_quests.append(str(q))
	for qd: Dictionary in gs.active_quests:
		if str(qd.get("id", "")) in gs.completed_quests:
			qd["done"] = true
	gs.quest_completion_times.clear()
	var qct: Variant = gdata.get("quest_completion_times", {})
	if qct is Dictionary:
		for qk in (qct as Dictionary).keys():
			gs.quest_completion_times[str(qk)] = str(qct[qk])
	gs.previous_shifts_archive.clear()
	for psa in gdata.get("previous_shifts_archive", []):
		if psa is Dictionary:
			gs.previous_shifts_archive.append(psa)
	if gdata.has("tutorial_completed"):
		gs.tutorial_completed = bool(gdata.get("tutorial_completed", false))

	gs.collected_pages.clear()
	for pg in gdata.get("collected_pages", []):
		gs.collected_pages.append(str(pg))
	gs.collected_tapes.clear()
	for tp in gdata.get("collected_tapes", []):
		gs.collected_tapes.append(str(tp))
	gs.evidence_items.clear()
	for ev in gdata.get("evidence_items", []):
		gs.evidence_items.append(str(ev))
	gs.unlocked_doors.clear()
	for dr in gdata.get("unlocked_doors", []):
		gs.unlocked_doors.append(str(dr))
	gs.collected_keys.clear()
	for ky in gdata.get("collected_keys", []):
		gs.collected_keys.append(str(ky))
	gs.door_states.clear()
	var ds: Variant = gdata.get("door_states", {})
	if ds is Dictionary:
		for dk in (ds as Dictionary).keys():
			gs.door_states[str(dk)] = ds[dk]
	gs.notebook_entries.clear()
	for ne in gdata.get("notebook_entries", []):
		if ne is Dictionary:
			gs.notebook_entries.append(ne)
	var sf: Variant = gdata.get("story_flags", {})
	if sf is Dictionary:
		for fk in (sf as Dictionary).keys():
			gs.story_flags[str(fk)] = sf[fk]

	if sm and sm.has_method("import_state"):
		sm.import_state(sdata)
		sm.set_chapter(night_n)

	gs.emit_signal("quest_updated")
	gs.emit_signal("state_changed")
	return true


func delete_slot(slot_idx: int) -> void:
	var p := _slot_path(slot_idx)
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
		emit_signal("saves_updated")


func format_playtime(sec: float) -> String:
	var total := int(sec)
	var hh := total / 3600
	var mm := (total % 3600) / 60
	var ss := total % 60
	return "%02d:%02d:%02d" % [hh, mm, ss]
