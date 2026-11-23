class_name AudioEnvironmentManager
extends Node

const BUS_ENV := "EnvLayer"
const BUS_LIFE := "LifeLayer"
const BUS_SUPERNATURAL := "SupernaturalLayer"
const BUS_HEADPHONES := "HeadphoneMusic"

var _env_lpf: AudioEffectLowPassFilter
var _life_lpf: AudioEffectLowPassFilter
var _sup_lpf: AudioEffectLowPassFilter
var _buses_ready: bool = false
var _blend_wear: float = 0.0


func _ready() -> void:
	ensure_audio_buses()


func ensure_audio_buses() -> void:
	if _buses_ready:
		return
	_env_lpf = _ensure_bus_with_lpf(BUS_ENV)
	_life_lpf = _ensure_bus_with_lpf(BUS_LIFE)
	_sup_lpf = _ensure_bus_with_lpf(BUS_SUPERNATURAL)
	if AudioServer.get_bus_index(BUS_HEADPHONES) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_HEADPHONES)
		AudioServer.set_bus_send(idx, "Master")
		var hp_lpf := AudioEffectLowPassFilter.new()
		hp_lpf.cutoff_hz = 5200.0
		AudioServer.add_bus_effect(idx, hp_lpf, 0)
	_buses_ready = true
	apply_mix_factor(0.0)


func _ensure_bus_with_lpf(bus_name: String) -> AudioEffectLowPassFilter:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	for e_idx: int in range(AudioServer.get_bus_effect_count(idx)):
		var fx: AudioEffect = AudioServer.get_bus_effect(idx, e_idx)
		if fx is AudioEffectLowPassFilter:
			return fx as AudioEffectLowPassFilter
	var lpf := AudioEffectLowPassFilter.new()
	lpf.cutoff_hz = 20000.0
	lpf.resonance = 0.55
	AudioServer.add_bus_effect(idx, lpf, 0)
	return lpf


func update_headphone_mix(wearing: bool, delta: float) -> void:
	ensure_audio_buses()
	var target: float = 1.0 if wearing else 0.0
	_blend_wear = move_toward(_blend_wear, target, delta * 3.8)
	apply_mix_factor(_blend_wear)


func apply_mix_factor(wear_factor: float) -> void:
	ensure_audio_buses()
	var w: float = clampf(wear_factor, 0.0, 1.0)
	var i_env := AudioServer.get_bus_index(BUS_ENV)
	var i_life := AudioServer.get_bus_index(BUS_LIFE)
	var i_sup := AudioServer.get_bus_index(BUS_SUPERNATURAL)
	var i_hp := AudioServer.get_bus_index(BUS_HEADPHONES)

	# When wearing headphones: attenuate world layers strongly & lowpass muffle; fade Walkman music in
	if i_env != -1:
		AudioServer.set_bus_volume_db(i_env, lerpf(0.0, -11.5, w))
	if i_life != -1:
		AudioServer.set_bus_volume_db(i_life, lerpf(0.0, -15.5, w))
	if i_sup != -1:
		AudioServer.set_bus_volume_db(i_sup, lerpf(0.0, -24.0, w))
	if i_hp != -1:
		AudioServer.set_bus_volume_db(i_hp, lerpf(-60.0, -6.5, w))
		AudioServer.set_bus_mute(i_hp, w < 0.02)

	if _env_lpf:
		_env_lpf.cutoff_hz = lerpf(20000.0, 920.0, w)
	if _life_lpf:
		_life_lpf.cutoff_hz = lerpf(20000.0, 680.0, w)
	if _sup_lpf:
		_sup_lpf.cutoff_hz = lerpf(20000.0, 480.0, w)


func get_bus_snapshot() -> Dictionary:
	ensure_audio_buses()
	return {
		"env_db": AudioServer.get_bus_volume_db(AudioServer.get_bus_index(BUS_ENV)),
		"life_db": AudioServer.get_bus_volume_db(AudioServer.get_bus_index(BUS_LIFE)),
		"sup_db": AudioServer.get_bus_volume_db(AudioServer.get_bus_index(BUS_SUPERNATURAL)),
		"hp_db": AudioServer.get_bus_volume_db(AudioServer.get_bus_index(BUS_HEADPHONES)),
		"env_cutoff": _env_lpf.cutoff_hz if _env_lpf else 20000.0,
		"sup_cutoff": _sup_lpf.cutoff_hz if _sup_lpf else 20000.0,
	}
