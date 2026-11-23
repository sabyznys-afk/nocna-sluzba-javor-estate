class_name AmbientSpeechManager
extends Node3D

# Prompt 07 Part 6.3–6.4 & Part 7 — Spatial Human Conversations & Atmospheric World Reactions
# Schedules dynamic, distance-aware Slovak neighbor talks, muffled through-wall apartment voices,
# shop interactions, distant dog barking, car engine starts, window latches, shutters & wall coughs!
# Automatically falls eerily silent on Night 6 (The Last Patrol)!

const SPEECH_ZONES: Array[Dictionary] = [
	{"id": "amb_apt_a", "pos": Vector3(-32.0, 3.8, 32.0), "pool": ["apt_muffled_conv_01", "resident_conv_02"]},
	{"id": "amb_apt_b", "pos": Vector3(2.0, 6.2, 35.8), "pool": ["apt_balcony_04", "resident_conv_03"]},
	{"id": "amb_apt_c", "pos": Vector3(38.0, 3.4, 34.0), "pool": ["apt_muffled_conv_02", "resident_greeting_04"]},
	{"id": "amb_apt_d", "pos": Vector3(6.0, 4.2, -24.0), "pool": ["apt_tv_news_03", "resident_conv_01"]},
	{"id": "amb_shop_vec", "pos": Vector3(45.2, 1.4, -2.0), "pool": ["shop_customer_01", "shop_phone_03"]},
	{"id": "amb_shop_traf", "pos": Vector3(36.8, 1.4, -10.0), "pool": ["shop_closing_02"]},
]

const WORLD_REACTION_SPOTS: Array[Dictionary] = [
	{"id": "rx_dog", "file": "res://assets/audio/voices/Environment/env_dog_bark_distant.ogg", "pos": Vector3(-28.0, 1.2, 54.0)},
	{"id": "rx_car", "file": "res://assets/audio/voices/Environment/env_car_start_distant.ogg", "pos": Vector3(14.0, 1.0, -74.0)},
	{"id": "rx_window", "file": "res://assets/audio/voices/Environment/env_window_close.ogg", "pos": Vector3(-30.0, 4.5, 32.2)},
	{"id": "rx_shutter", "file": "res://assets/audio/voices/Environment/env_shutter_close.ogg", "pos": Vector3(36.3, 1.5, -10.0)},
	{"id": "rx_cough", "file": "res://assets/audio/voices/Environment/env_cough_wall.ogg", "pos": Vector3(4.0, 3.6, -24.2)},
]

var voice_mgr: Node
var player_ref: Node3D
var _reaction_streams: Dictionary = {}
var _reaction_player: AudioStreamPlayer3D
var _speech_timer: float = 9.0
var _reaction_timer: float = 14.0
var _rng := RandomNumberGenerator.new()
var _audio_enabled: bool = true
var triggered_events_count: int = 0


func _gs() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("GameState") if ml is SceneTree else null


func setup_ambient_speech(p_voice_mgr: Node, p_player: Node3D) -> void:
	name = "AmbientSpeechManager"
	voice_mgr = p_voice_mgr
	player_ref = p_player
	_rng.seed = 19960707
	if DisplayServer.get_name() == "headless":
		_audio_enabled = false

	_reaction_player = AudioStreamPlayer3D.new()
	_reaction_player.name = "WorldReaction3D"
	_reaction_player.bus = "LifeLayer"
	_reaction_player.max_distance = 42.0
	_reaction_player.unit_size = 6.5
	_reaction_player.volume_db = -7.5
	add_child(_reaction_player)

	for rx: Dictionary in WORLD_REACTION_SPOTS:
		var fp: String = str(rx["file"])
		if ResourceLoader.exists(fp):
			var st: Resource = load(fp)
			if st is AudioStream:
				_reaction_streams[str(rx["id"])] = st as AudioStream


func get_reaction_sound_count() -> int:
	return _reaction_streams.size()


func _process(delta: float) -> void:
	var gs := _gs()
	var n: int = gs.current_night if gs else 1
	# Night 6 (The Last Patrol): Estate falls dead silent — residents vanished!
	if n >= 6 or not player_ref or not is_instance_valid(player_ref):
		return

	_speech_timer -= delta
	if _speech_timer <= 0.0:
		_speech_timer = _rng.randf_range(16.0, 28.0)
		trigger_nearest_ambient_speech(player_ref.global_position)

	_reaction_timer -= delta
	if _reaction_timer <= 0.0:
		_reaction_timer = _rng.randf_range(18.0, 34.0)
		trigger_world_reaction(player_ref.global_position)


func trigger_nearest_ambient_speech(from_pos: Vector3) -> String:
	if not voice_mgr or not voice_mgr.has_method("play_voice_line"):
		return ""
	var best_zone: Dictionary = {}
	var best_d: float = 34.0
	for z: Dictionary in SPEECH_ZONES:
		var d: float = from_pos.distance_to(z["pos"])
		if d < best_d:
			best_d = d
			best_zone = z
	if best_zone.is_empty():
		return ""
	var pool: Array = best_zone.get("pool", [])
	if pool.is_empty():
		return ""
	var chosen_id: String = str(pool[_rng.randi() % pool.size()])
	if voice_mgr.play_voice_line(chosen_id, best_zone["pos"], false):
		triggered_events_count += 1
		return chosen_id
	return ""


func trigger_world_reaction(from_pos: Vector3, forced_id: String = "") -> String:
	if _reaction_streams.is_empty():
		return ""
	var chosen: Dictionary = {}
	if not forced_id.is_empty():
		for rx: Dictionary in WORLD_REACTION_SPOTS:
			if str(rx["id"]) == forced_id:
				chosen = rx
				break
	else:
		var candidates: Array[Dictionary] = []
		for rx: Dictionary in WORLD_REACTION_SPOTS:
			if from_pos.distance_to(rx["pos"]) <= 48.0:
				candidates.append(rx)
		if candidates.is_empty():
			candidates.append(WORLD_REACTION_SPOTS[0])
		chosen = candidates[_rng.randi() % candidates.size()]
	if chosen.is_empty():
		return ""
	var rx_id: String = str(chosen["id"])
	if not _reaction_streams.has(rx_id):
		return ""
	_reaction_player.global_position = chosen["pos"]
	_reaction_player.stream = _reaction_streams[rx_id]
	if _audio_enabled:
		_reaction_player.play()
	triggered_events_count += 1
	return rx_id
