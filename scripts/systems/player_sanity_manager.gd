class_name PlayerSanityManager
extends Node

signal sanity_changed(val: float, stage: String)
signal stage_changed(new_stage: String)
signal hallucination_triggered(kind: String)

var sanity: float = 100.0
var current_stage: String = "HIGH"
var _whisper_cd: float = 14.0


func get_stage() -> String:
	if sanity >= 75.0:
		return "HIGH"
	if sanity >= 45.0:
		return "MODERATE"
	if sanity >= 20.0:
		return "LOW"
	return "CRITICAL"


func set_sanity(val: float) -> void:
	sanity = clampf(val, 0.0, 100.0)
	GameState.sanity = sanity
	var ns: String = get_stage()
	if ns != current_stage:
		current_stage = ns
		emit_signal("stage_changed", current_stage)
	emit_signal("sanity_changed", sanity, current_stage)


func adjust_sanity(delta: float) -> void:
	set_sanity(sanity + delta)


func update_sanity(delta: float, in_safe_office: bool, flashlight_on: bool, headphones_on: bool, near_anomaly_or_dark: bool) -> void:
	var rate: float = 0.0
	if in_safe_office:
		rate += 4.5
	elif headphones_on:
		# Music soothes passive dread while worn
		rate += 1.5
		if near_anomaly_or_dark:
			rate -= 0.4
	else:
		if not flashlight_on:
			rate -= 1.35
		if near_anomaly_or_dark:
			rate -= 2.1

	if absf(rate) > 0.01:
		adjust_sanity(rate * delta)

	if current_stage == "LOW" or current_stage == "CRITICAL":
		_whisper_cd -= delta
		if _whisper_cd <= 0.0:
			_whisper_cd = randf_range(9.0, 18.0) if current_stage == "LOW" else randf_range(5.0, 11.0)
			if not headphones_on:
				AudioSynth.play_sfx("whisper_static", -8.0, randf_range(0.88, 1.12))
			emit_signal("hallucination_triggered", "whisper" if randf() > 0.35 else "peripheral")
