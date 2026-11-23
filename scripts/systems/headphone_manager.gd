class_name HeadphoneManager
extends Node

signal headphones_toggled(wearing: bool)
signal stalker_jumpscare_triggered(threat_pos: Vector3)

var headphones_on: bool = false
var stalker_threat: float = 0.0
var jumpscare_count: int = 0
var _scare_cooldown: float = 0.0


func set_headphones(wearing: bool, play_sfx: bool = true) -> void:
	if headphones_on == wearing:
		return
	headphones_on = wearing
	GameState.headphones_on = headphones_on
	if play_sfx:
		AudioSynth.play_sfx("headphones_on" if headphones_on else "headphones_off", -4.5)
	AudioSynth.set_walkman_playing(headphones_on)
	emit_signal("headphones_toggled", headphones_on)


func toggle_headphones() -> bool:
	set_headphones(not headphones_on, true)
	return headphones_on


func update_threat(delta: float, in_safe_office: bool, near_threat_zone: bool, player_node: Node3D) -> void:
	if _scare_cooldown > 0.0:
		_scare_cooldown = maxf(0.0, _scare_cooldown - delta)

	if headphones_on and not in_safe_office and _scare_cooldown <= 0.0:
		var build_rate: float = 6.2 if near_threat_zone else 1.8
		stalker_threat = minf(100.0, stalker_threat + build_rate * delta)
		if stalker_threat >= 100.0:
			_trigger_stalker_encounter(player_node)
	else:
		# Removing headphones or standing inside Security Office clears approaching blind threat
		stalker_threat = maxf(0.0, stalker_threat - 14.0 * delta)


func force_trigger_test_jumpscare(player_node: Node3D) -> void:
	stalker_threat = 100.0
	_scare_cooldown = 0.0
	_trigger_stalker_encounter(player_node)


func _trigger_stalker_encounter(player_node: Node3D) -> void:
	stalker_threat = 0.0
	_scare_cooldown = 85.0
	jumpscare_count += 1
	AudioSynth.play_sfx("jumpscare_sting", -2.5)
	set_headphones(false, false)
	var sc_pos: Vector3 = player_node.global_position if player_node else Vector3.ZERO
	if player_node:
		var fwd: Vector3 = -player_node.global_transform.basis.z
		sc_pos = player_node.global_position - fwd * 2.1
	emit_signal("stalker_jumpscare_triggered", sc_pos)
