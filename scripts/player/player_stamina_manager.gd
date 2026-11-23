class_name PlayerStaminaManager
extends Node

signal stamina_changed(val: float, exhausted: bool)
signal exhaustion_started
signal exhaustion_ended

var max_stamina: float = 100.0
var stamina: float = 100.0
var is_exhausted: bool = false
var regen_delay_timer: float = 0.0
var _breath_timer: float = 0.0


func can_sprint() -> bool:
	return (not is_exhausted) and stamina > 0.05


func get_stamina_ratio() -> float:
	return clampf(stamina / maxf(1.0, max_stamina), 0.0, 1.0)


func update_stamina(delta: float, sprinting: bool, moving: bool, headphones_on: bool, sanity_val: float) -> void:
	var prev_stamina: float = stamina
	if sprinting and moving and can_sprint():
		stamina = maxf(0.0, stamina - 19.0 * delta)
		regen_delay_timer = 1.6
		if stamina <= 0.5 and not is_exhausted:
			stamina = 0.0
			is_exhausted = true
			regen_delay_timer = 3.0
			AudioSynth.play_sfx("breath_exhausted", -5.0)
			emit_signal("exhaustion_started")
	else:
		if regen_delay_timer > 0.0:
			regen_delay_timer = maxf(0.0, regen_delay_timer - delta)
		else:
			# Without headphones under psychological stress, stamina recovers more slowly
			var stress_penalty: float = 0.0
			if not headphones_on and sanity_val < 60.0:
				stress_penalty = lerpf(1.5, 4.5, clampf((60.0 - sanity_val) / 60.0, 0.0, 1.0))
			var regen_rate: float = maxf(5.0, 15.0 - stress_penalty)
			stamina = minf(max_stamina, stamina + regen_rate * delta)
			if is_exhausted and stamina >= 26.0:
				is_exhausted = false
				emit_signal("exhaustion_ended")

	# Breathing cues at low / exhausted stamina
	if is_exhausted or stamina < 32.0:
		_breath_timer -= delta
		if _breath_timer <= 0.0:
			_breath_timer = 2.1 if is_exhausted else 2.8
			AudioSynth.play_sfx("breath_exhausted" if is_exhausted else "breath_tired", -7.0)
	else:
		_breath_timer = 0.4

	if absf(stamina - prev_stamina) > 0.05:
		emit_signal("stamina_changed", stamina, is_exhausted)
