extends Node

const SAMPLE_RATE: int = 22050

var _streams: Dictionary = {}
var _ambient_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _drone_player: AudioStreamPlayer
var _voice_player: AudioStreamPlayer
var _walkman_player: AudioStreamPlayer
var env_manager: AudioEnvironmentManager
var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
var _audio_enabled: bool = true
var _last_step_idx: Dictionary = {}


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		_audio_enabled = false

	env_manager = AudioEnvironmentManager.new()
	env_manager.name = "AudioEnvironmentManager"
	add_child(env_manager)
	env_manager.ensure_audio_buses()

	_load_studio_audio()
	_build_fallback_streams()

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientRainPlayer"
	_ambient_player.bus = "EnvLayer"
	_ambient_player.volume_db = -14.0
	add_child(_ambient_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	_music_player.volume_db = -12.0
	add_child(_music_player)

	_drone_player = AudioStreamPlayer.new()
	_drone_player.name = "TensionDronePlayer"
	_drone_player.bus = "SupernaturalLayer"
	_drone_player.volume_db = -40.0
	add_child(_drone_player)

	_voice_player = AudioStreamPlayer.new()
	_voice_player.name = "VoicePlayer"
	_voice_player.bus = "EnvLayer"
	_voice_player.volume_db = -2.0
	add_child(_voice_player)

	_walkman_player = AudioStreamPlayer.new()
	_walkman_player.name = "WalkmanPlayer"
	_walkman_player.bus = "HeadphoneMusic"
	_walkman_player.volume_db = -10.5
	add_child(_walkman_player)

	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPool_%d" % i
		p.bus = "EnvLayer"
		add_child(p)
		_sfx_pool.append(p)


func _load_studio_audio() -> void:
	var loop_files: Dictionary = {
		"amb_rain_city": "res://assets/audio/amb_rain_city.ogg",
		"music_menu_theme": "res://assets/audio/music_menu_theme.ogg",
		"music_tension_drone": "res://assets/audio/music_tension_drone.ogg",
		"music_walkman_tape": "res://assets/audio/music_walkman_tape.ogg",
		"loop_sodium_buzz": "res://assets/audio/loop_sodium_buzz.ogg",
		"loop_boiler_roar": "res://assets/audio/loop_boiler_roar.ogg",
		"loop_clock_tick": "res://assets/audio/loop_clock_tick.ogg",
		"loop_k4_hum": "res://assets/audio/loop_k4_hum.ogg",
		"loop_radio_504": "res://assets/audio/loop_radio_504.ogg",
		"loop_apartment_life": "res://assets/audio/loop_apartment_life.ogg",
		"loop_forest_wind": "res://assets/audio/loop_forest_wind.ogg",
		"chains_sway": "res://assets/audio/sfx_chains_sway.ogg",
		"distant_tram": "res://assets/audio/sfx_distant_tram.ogg",
	}
	for key: String in loop_files.keys():
		var path: String = str(loop_files[key])
		if ResourceLoader.exists(path):
			var st: AudioStream = load(path)
			if st is AudioStreamOggVorbis:
				(st as AudioStreamOggVorbis).loop = true
			if st:
				_streams[key] = st

	var sfx_files: Dictionary = {
		"step_cobble_1": "res://assets/audio/sfx_step_cobble_1.ogg",
		"step_cobble_2": "res://assets/audio/sfx_step_cobble_2.ogg",
		"step_cobble_3": "res://assets/audio/sfx_step_cobble_3.ogg",
		"step_cobble_4": "res://assets/audio/sfx_step_cobble_4.ogg",
		"step_grass_1": "res://assets/audio/sfx_step_grass_1.ogg",
		"step_grass_2": "res://assets/audio/sfx_step_grass_2.ogg",
		"step_grass_3": "res://assets/audio/sfx_step_grass_3.ogg",
		"step_grass_4": "res://assets/audio/sfx_step_grass_4.ogg",
		"step_gravel_1": "res://assets/audio/sfx_step_gravel_1.ogg",
		"step_gravel_2": "res://assets/audio/sfx_step_gravel_2.ogg",
		"step_gravel_3": "res://assets/audio/sfx_step_gravel_3.ogg",
		"step_gravel_4": "res://assets/audio/sfx_step_gravel_4.ogg",
		"step_wood_1": "res://assets/audio/sfx_step_wood_1.ogg",
		"step_wood_2": "res://assets/audio/sfx_step_wood_2.ogg",
		"step_wood_3": "res://assets/audio/sfx_step_wood_3.ogg",
		"step_wood_4": "res://assets/audio/sfx_step_wood_4.ogg",
		"step_metal_1": "res://assets/audio/sfx_step_metal_1.ogg",
		"step_metal_2": "res://assets/audio/sfx_step_metal_2.ogg",
		"step_metal_3": "res://assets/audio/sfx_step_metal_3.ogg",
		"step_metal_4": "res://assets/audio/sfx_step_metal_4.ogg",
		"step_wood": "res://assets/audio/sfx_step_wood_1.ogg",
		"step_metal": "res://assets/audio/sfx_step_metal_1.ogg",
		"flashlight": "res://assets/audio/sfx_flashlight.ogg",
		"clock_stamp": "res://assets/audio/sfx_clock_stamp.ogg",
		"phone_ring": "res://assets/audio/sfx_phone_ring.ogg",
		"door_heavy": "res://assets/audio/sfx_door_iron.ogg",
		"door_creak": "res://assets/audio/sfx_door_creak.ogg",
		"static_burst": "res://assets/audio/sfx_static_burst.ogg",
		"anomaly_sting": "res://assets/audio/sfx_anomaly_sting.ogg",
		"ui_blip": "res://assets/audio/sfx_ui_blip.ogg",
		"taser_zap": "res://assets/audio/sfx_taser_zap.ogg",
		"taser_equip": "res://assets/audio/sfx_taser_equip.ogg",
		"battery_swap": "res://assets/audio/sfx_battery_swap.ogg",
		"notebook_open": "res://assets/audio/sfx_notebook_open.ogg",
		"pencil_check": "res://assets/audio/sfx_pencil_check.ogg",
		"chair_crash": "res://assets/audio/sfx_chair_crash.ogg",
		"whisper_static": "res://assets/audio/sfx_whisper_static.ogg",
		"headphones_on": "res://assets/audio/sfx_headphones_on.ogg",
		"headphones_off": "res://assets/audio/sfx_headphones_off.ogg",
		"keys_jingle": "res://assets/audio/sfx_keys_jingle.ogg",
		"radio_squelch": "res://assets/audio/sfx_radio_squelch.ogg",
		"watch_tick": "res://assets/audio/sfx_watch_tick.ogg",
		"switch_click": "res://assets/audio/sfx_switch_click.ogg",
		"drawer_open": "res://assets/audio/sfx_drawer_open.ogg",
		"breath_tired": "res://assets/audio/sfx_breath_tired.ogg",
		"breath_exhausted": "res://assets/audio/sfx_breath_exhausted.ogg",
		"jumpscare_sting": "res://assets/audio/sfx_jumpscare_sting.ogg",
		"ui_hover": "res://assets/audio/sfx_ui_hover.ogg",
		"ui_press": "res://assets/audio/sfx_ui_press.ogg",
		"page_turn": "res://assets/audio/sfx_page_turn.ogg",
		"cassette_click": "res://assets/audio/sfx_cassette_click.ogg",
		"intercom_buzz": "res://assets/audio/sfx_intercom_buzz.ogg",
		"power_out": "res://assets/audio/sfx_power_out.ogg",
		"voice_kovac_n1": "res://assets/audio/voice_kovac_n1.ogg",
		"voice_kovac_n2": "res://assets/audio/voice_kovac_n2.ogg",
		"voice_kovac_n3": "res://assets/audio/voice_kovac_n3.ogg",
		"voice_kovac_n4": "res://assets/audio/voice_kovac_n4.ogg",
		"voice_kovac_n5": "res://assets/audio/voice_kovac_n5.ogg",
		"voice_elena_payphone": "res://assets/audio/voice_elena_payphone.ogg",
		"voice_maria_n3": "res://assets/audio/voice_maria_n3.ogg",
		"voice_maria_n5": "res://assets/audio/voice_maria_n5.ogg",
		"voice_jozef_bunker": "res://assets/audio/voice_jozef_bunker.ogg",
		"voice_milan_n2": "res://assets/audio/voice_milan_n2.ogg",
		"hotbar_scroll": "res://assets/audio/sfx_hotbar_scroll.ogg",
		"door_handle": "res://assets/audio/sfx_door_handle.ogg",
		"door_seal": "res://assets/audio/sfx_door_seal.ogg",
		"door_bang": "res://assets/audio/sfx_door_bang.ogg",
		"car_door_distant": "res://assets/audio/sfx_car_door_distant.ogg",
		"upstairs_run": "res://assets/audio/sfx_upstairs_run.ogg",
		"breathing_door": "res://assets/audio/sfx_breathing_door.ogg",
		"handle_jiggle": "res://assets/audio/sfx_handle_jiggle.ogg",
		"metal_impact": "res://assets/audio/sfx_metal_impact.ogg",
	}
	for key: String in sfx_files.keys():
		var path: String = str(sfx_files[key])
		if ResourceLoader.exists(path):
			var st: AudioStream = load(path)
			if st:
				_streams[key] = st


func _build_fallback_streams() -> void:
	if not _streams.has("amb_rain_city"):
		_streams["amb_rain_city"] = _make_ambient_hum(2.0)
	if not _streams.has("step_cobble_1"):
		_streams["step_cobble_1"] = _make_step_burst(0.09, 140.0)
	if not _streams.has("step_wood"):
		_streams["step_wood"] = _make_step_burst(0.11, 210.0)
	if not _streams.has("step_metal"):
		_streams["step_metal"] = _make_step_burst(0.12, 420.0)
	if not _streams.has("flashlight"):
		_streams["flashlight"] = _make_click(0.045, 950.0)
	if not _streams.has("clock_stamp"):
		_streams["clock_stamp"] = _make_beep(0.18, 620.0)
	if not _streams.has("phone_ring"):
		_streams["phone_ring"] = _make_beep(0.45, 1320.0)
	if not _streams.has("static_burst"):
		_streams["static_burst"] = _make_step_burst(0.35, 320.0)
	if not _streams.has("door_heavy"):
		_streams["door_heavy"] = _make_step_burst(0.28, 95.0)
	if not _streams.has("ui_blip"):
		_streams["ui_blip"] = _make_beep(0.07, 680.0)
	if not _streams.has("hotbar_scroll"):
		_streams["hotbar_scroll"] = _make_click(0.04, 640.0)
	if not _streams.has("door_handle"):
		_streams["door_handle"] = _make_click(0.12, 420.0)
	if not _streams.has("door_seal"):
		_streams["door_seal"] = _make_step_burst(0.22, 110.0)
	if not _streams.has("door_bang"):
		_streams["door_bang"] = _make_step_burst(0.35, 85.0)
	if not _streams.has("car_door_distant"):
		_streams["car_door_distant"] = _make_step_burst(0.30, 120.0)
	if not _streams.has("upstairs_run"):
		_streams["upstairs_run"] = _make_step_burst(0.45, 95.0)
	if not _streams.has("breathing_door"):
		_streams["breathing_door"] = _make_step_burst(0.60, 260.0)
	if not _streams.has("handle_jiggle"):
		_streams["handle_jiggle"] = _make_click(0.18, 520.0)
	if not _streams.has("metal_impact"):
		_streams["metal_impact"] = _make_step_burst(0.38, 340.0)


func has_stream(stream_name: String) -> bool:
	return _streams.has(stream_name)


func start_menu_music() -> void:
	if not _audio_enabled:
		return
	if _streams.has("amb_rain_city") and not _ambient_player.playing:
		_ambient_player.stream = _streams["amb_rain_city"]
		_ambient_player.volume_db = -17.0
		_ambient_player.play()
	if _streams.has("music_menu_theme"):
		if _music_player.stream != _streams["music_menu_theme"] or not _music_player.playing:
			_music_player.stream = _streams["music_menu_theme"]
			_music_player.volume_db = -11.0
			_music_player.play()


func stop_music() -> void:
	if _music_player and _music_player.playing:
		_music_player.stop()
	if _drone_player and _drone_player.playing:
		_drone_player.stop()


func start_ambient() -> void:
	if not _audio_enabled:
		return
	stop_music()
	if _streams.has("amb_rain_city"):
		_ambient_player.stream = _streams["amb_rain_city"]
		_ambient_player.volume_db = -13.0
		if not _ambient_player.playing:
			_ambient_player.play()
	if _streams.has("music_tension_drone"):
		_drone_player.stream = _streams["music_tension_drone"]
		_drone_player.volume_db = -38.0
		if not _drone_player.playing:
			_drone_player.play()


func stop_ambient() -> void:
	if _ambient_player and _ambient_player.playing:
		_ambient_player.stop()
	set_walkman_playing(false)
	stop_music()
	stop_voice()


func set_walkman_playing(playing: bool) -> void:
	if not _walkman_player:
		return
	if not _audio_enabled or not playing:
		if _walkman_player.playing:
			_walkman_player.stop()
		return
	if _streams.has("music_walkman_tape"):
		_walkman_player.stream = _streams["music_walkman_tape"]
		_walkman_player.volume_db = -10.5
		if not _walkman_player.playing:
			_walkman_player.play()


func play_ui_sfx(sfx_name: String, base_vol_db: float = -7.0) -> void:
	var sett := get_node_or_null("/root/SettingsManager")
	var reduced: bool = bool(sett.get_val("reduce_ui_sfx", false)) if sett and sett.has_method("get_val") else false
	var vol := base_vol_db - (10.0 if reduced else 0.0)
	play_sfx(sfx_name, vol, randf_range(0.97, 1.03), "Master")


func play_tape(stream_name: String) -> void:
	if not _audio_enabled or not _streams.has(stream_name):
		return
	play_sfx("cassette_click", -5.0, 1.0, "Master")
	if _voice_player.playing:
		_voice_player.stop()
	_voice_player.stream = _streams[stream_name]
	_voice_player.bus = "Master"
	_voice_player.volume_db = -3.0
	_voice_player.play()


func stop_tape() -> void:
	play_sfx("cassette_click", -6.0, 0.90, "Master")
	stop_voice()


func set_distortion_audio(level_0_to_100: float) -> void:
	if not _drone_player or not _streams.has("music_tension_drone"):
		return
	var norm: float = clampf(level_0_to_100 / 100.0, 0.0, 1.0)
	_drone_player.volume_db = lerpf(-38.0, -13.0, norm)
	_drone_player.pitch_scale = lerpf(0.98, 1.04, norm)


func _infer_sfx_bus(sfx_name: String) -> String:
	if sfx_name in ["anomaly_sting", "whisper_static", "jumpscare_sting", "chair_crash", "loop_k4_hum", "chains_sway"]:
		return "SupernaturalLayer"
	if sfx_name in ["ui_blip", "headphones_on", "headphones_off", "breath_tired", "breath_exhausted"]:
		return "Master"
	if sfx_name in ["loop_apartment_life", "loop_radio_504", "loop_clock_tick"]:
		return "LifeLayer"
	return "EnvLayer"


func play_sfx(sfx_name: String, volume_db: float = -6.0, pitch_scale: float = 1.0, bus_name: String = "") -> void:
	if not _audio_enabled:
		return
	var target_name: String = sfx_name
	if sfx_name == "step_cobble":
		target_name = "step_cobble_%d" % randi_range(1, 4)
	if not _streams.has(target_name):
		return
	var player: AudioStreamPlayer = _sfx_pool[_pool_index]
	_pool_index = (_pool_index + 1) % _sfx_pool.size()
	player.stream = _streams[target_name]
	player.bus = bus_name if not bus_name.is_empty() else _infer_sfx_bus(target_name)
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func play_footstep(surface: String = "cobble", crouching: bool = false, sprinting: bool = false) -> void:
	var surf: String = surface
	var extra_pitch: float = 1.0
	var extra_vol: float = 0.0
	match surface:
		"asphalt":
			surf = "cobble"
			extra_pitch = 0.98
		"concrete":
			surf = "cobble"
			extra_pitch = 1.06
		"mud":
			surf = "grass"
			extra_pitch = 0.80
			extra_vol = -1.5
		"cobble", "wood", "metal", "grass", "gravel":
			surf = surface
		_:
			surf = "cobble"
	var prev: int = int(_last_step_idx.get(surf, 0))
	var idx: int = randi_range(1, 4)
	if idx == prev:
		idx = (idx % 4) + 1
	_last_step_idx[surf] = idx
	var key := "step_%s_%d" % [surf, idx]
	if not _streams.has(key):
		key = "step_" + surf if _streams.has("step_" + surf) else "step_cobble_1"
	var vol: float = -2.5 + extra_vol
	if crouching:
		vol -= 6.0
	elif sprinting:
		vol += 3.5
	var pitch: float = randf_range(0.93, 1.07) * extra_pitch
	play_sfx(key, vol, pitch, "EnvLayer")


func play_voice(voice_name: String, volume_db: float = -2.0) -> void:
	if not _audio_enabled or not _streams.has(voice_name):
		return
	if _voice_player.playing:
		_voice_player.stop()
	_voice_player.stream = _streams[voice_name]
	_voice_player.volume_db = volume_db
	_voice_player.play()


func stop_voice() -> void:
	if _voice_player and _voice_player.playing:
		_voice_player.stop()


func create_spatial_loop(stream_name: String, pos: Vector3, max_dist: float = 14.0, vol_db: float = -8.0, bus_name: String = "") -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.name = "Spatial_" + stream_name
	p.position = pos
	p.max_distance = max_dist
	p.unit_size = 2.8
	p.volume_db = vol_db
	p.bus = bus_name if not bus_name.is_empty() else _infer_sfx_bus(stream_name)
	if _streams.has(stream_name):
		p.stream = _streams[stream_name]
		p.autoplay = _audio_enabled
	return p


func _pack_wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav


func _make_ambient_hum(seconds: float) -> AudioStreamWAV:
	var count: int = int(seconds * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		buf[i] = sin(TAU * 50.0 * t) * 0.22
	return _pack_wav(buf, true)


func _make_step_burst(seconds: float, resonance_hz: float) -> AudioStreamWAV:
	var count: int = int(seconds * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(resonance_hz)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		buf[i] = (sin(TAU * resonance_hz * t) * 0.5 + rng.randf_range(-0.35, 0.35)) * exp(-t * 28.0) * 0.65
	return _pack_wav(buf)


func _make_click(seconds: float, freq_hz: float) -> AudioStreamWAV:
	var count: int = int(seconds * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		buf[i] = sin(TAU * freq_hz * t) * exp(-t * 85.0) * 0.7
	return _pack_wav(buf)


func _make_beep(seconds: float, freq_hz: float) -> AudioStreamWAV:
	var count: int = int(seconds * SAMPLE_RATE)
	var buf := PackedFloat32Array()
	buf.resize(count)
	for i in range(count):
		var t: float = float(i) / float(SAMPLE_RATE)
		buf[i] = sin(TAU * freq_hz * t) * exp(-t * 18.0) * 0.35
	return _pack_wav(buf)
