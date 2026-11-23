class_name VoiceAssetManager
extends Node3D

# Prompt 07 Part 6.6 — Voice Asset Registry & Priority Non-Overlapping Dialogue Manager
# Loads voice_registry.json + all native Slovak .ogg voice files (Characters, AmbientSpeech, Radio, Telephone, Cassettes)
# Ensures high-priority dialogue NEVER overlaps unintentionally while supporting spatial 3D voices!

signal voice_started(voice_id: String, speaker: String, text: String)
signal voice_finished(voice_id: String)

const REGISTRY_PATH := "res://assets/audio/voices/voice_registry.json"

var registry: Dictionary = {} # voice_id -> metadata Dictionary
var _streams: Dictionary = {} # voice_id -> AudioStream
var _main_2d_player: AudioStreamPlayer
var _main_3d_player: AudioStreamPlayer3D
var _ambient_3d_player: AudioStreamPlayer3D

var active_voice_id: String = ""
var active_priority: int = -1
var _audio_enabled: bool = true
var played_history: Array[String] = []


func _ready() -> void:
	name = "VoiceAssetManager"
	if DisplayServer.get_name() == "headless":
		_audio_enabled = false

	_main_2d_player = AudioStreamPlayer.new()
	_main_2d_player.name = "MainVoice2D"
	_main_2d_player.bus = "Master"
	_main_2d_player.volume_db = -1.5
	_main_2d_player.finished.connect(_on_main_finished)
	add_child(_main_2d_player)

	_main_3d_player = AudioStreamPlayer3D.new()
	_main_3d_player.name = "MainVoice3D"
	_main_3d_player.bus = "EnvLayer"
	_main_3d_player.max_distance = 26.0
	_main_3d_player.unit_size = 5.5
	_main_3d_player.volume_db = -1.0
	_main_3d_player.finished.connect(_on_main_finished)
	add_child(_main_3d_player)

	_ambient_3d_player = AudioStreamPlayer3D.new()
	_ambient_3d_player.name = "AmbientSpeech3D"
	_ambient_3d_player.bus = "LifeLayer"
	_ambient_3d_player.max_distance = 24.0
	_ambient_3d_player.unit_size = 4.2
	_ambient_3d_player.volume_db = -6.5
	add_child(_ambient_3d_player)

	load_registry()


func load_registry() -> int:
	registry.clear()
	_streams.clear()
	if not FileAccess.file_exists(REGISTRY_PATH):
		return 0
	var fa := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	if not fa:
		return 0
	var parsed: Variant = JSON.parse_string(fa.get_as_text())
	fa.close()
	if not (parsed is Dictionary):
		return 0
	var entries: Array = (parsed as Dictionary).get("voices", [])
	for e_var in entries:
		if not (e_var is Dictionary):
			continue
		var entry: Dictionary = e_var
		var vid: String = str(entry.get("id", ""))
		var fpath: String = str(entry.get("file", ""))
		if vid.is_empty() or fpath.is_empty():
			continue
		registry[vid] = entry
		if ResourceLoader.exists(fpath):
			var st: Resource = load(fpath)
			if st is AudioStream:
				_streams[vid] = st as AudioStream
	return _streams.size()


func get_loaded_voice_count() -> int:
	return _streams.size()


func has_voice(voice_id: String) -> bool:
	return _streams.has(voice_id)


func is_important_dialogue_playing() -> bool:
	if not _audio_enabled:
		return active_priority >= 7
	return (_main_2d_player.playing or _main_3d_player.playing) and active_priority >= 7


func play_voice_line(voice_id: String, world_pos: Vector3 = Vector3.ZERO, force_override: bool = false) -> bool:
	if not registry.has(voice_id) or not _streams.has(voice_id):
		return false
	var meta: Dictionary = registry[voice_id]
	var prio: int = int(meta.get("priority", 5))
	var is_pos: bool = bool(meta.get("positional", false)) and world_pos != Vector3.ZERO
	var stream: AudioStream = _streams[voice_id] as AudioStream

	# Priority gate: never allow lower-priority chatter to talk over important dialogue!
	var busy: bool = _main_2d_player.playing or _main_3d_player.playing
	if busy and not force_override and prio < active_priority:
		return false

	# If playing low-priority ambient speech (priority <= 4), route cleanly to AmbientSpeech3D if main isn't talking
	if prio <= 4:
		if busy or active_priority >= 7:
			return false
		_ambient_3d_player.global_position = world_pos
		_ambient_3d_player.stream = stream
		if _audio_enabled:
			_ambient_3d_player.play()
		played_history.append(voice_id)
		emit_signal("voice_started", voice_id, str(meta.get("speaker", "")), str(meta.get("text", "")))
		return true

	# High-priority character / radio / phone / cassette dialogue: stop any ambient speech cleanly so zero overlap!
	if _ambient_3d_player.playing:
		_ambient_3d_player.stop()
	if _main_2d_player.playing:
		_main_2d_player.stop()
	if _main_3d_player.playing:
		_main_3d_player.stop()

	active_voice_id = voice_id
	active_priority = prio
	played_history.append(voice_id)
	if is_pos:
		_main_3d_player.global_position = world_pos
		_main_3d_player.stream = stream
		if _audio_enabled:
			_main_3d_player.play()
	else:
		_main_2d_player.stream = stream
		if _audio_enabled:
			_main_2d_player.play()

	emit_signal("voice_started", voice_id, str(meta.get("speaker", "")), str(meta.get("text", "")))
	return true


func stop_all_voices() -> void:
	_main_2d_player.stop()
	_main_3d_player.stop()
	_ambient_3d_player.stop()
	active_voice_id = ""
	active_priority = -1


func _on_main_finished() -> void:
	var finished_id: String = active_voice_id
	active_voice_id = ""
	active_priority = -1
	if not finished_id.is_empty():
		emit_signal("voice_finished", finished_id)
