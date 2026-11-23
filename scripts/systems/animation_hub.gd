class_name AnimationHub
extends Node

const ANIM_NAMES := [
	# World Mechanisms (12)
	"gate_iron_swing",
	"guard_booth_door_swing",
	"cctv_camera_pan",
	"sodium_lamp_sway",
	"rain_curtain_drift",
	"payphone_receiver_swing",
	"boiler_gauge_tremble",
	"boiler_valve_spin",
	"watchclock_pendulum",
	"dead_oak_wind_sway",
	"shrine_candle_flicker",
	"van_hazard_blink",
	"park_swing_creak",
	"garage_underlight_flicker",
	"curtain_sway",
	"clock_hands_tick",
	"grass_wind_sway",
	"crt_flicker",
	# Physical 3D Anomalies (14)
	"anom_floating_chairs",
	"anom_well_hands_reach",
	"anom_black_ooze_pulse",
	"anom_butcher_hooks_swing",
	"anom_hanging_sheet_flutter",
	"anom_13th_window_watcher",
	"anom_shadow_stalker_glide",
	"anom_skoda_headlights_flash",
	"anom_clock_hands_reverse",
	"anom_k4_core_breathe",
	"anom_radio_dial_jitter",
	"anom_door_knocker_slam",
	"anom_neon_sign_buzz",
	"anom_stairwell_fog_pulse",
]

# Array of { "anim": String, "node": Node3D, "base_pos": Vector3, "base_rot": Vector3, "base_scale": Vector3, "meta": Dictionary }
var _entries: Array[Dictionary] = []
var _triggered_timers: Dictionary = {} # anim_name -> remaining_sec
var _stunned_nodes: Dictionary = {}    # instance_id -> { "until": float, "permanent": bool }
var _anomaly_id_to_nodes: Dictionary = {} # anomaly_id -> Array[Node3D]
var _elapsed: float = 0.0
var _player_ref: Node3D = null


func get_registered_animation_names() -> PackedStringArray:
	return ANIM_NAMES


func get_animation_count() -> int:
	return ANIM_NAMES.size()


func set_player_ref(p: Node3D) -> void:
	_player_ref = p


func register_target(anim_name: String, node: Node3D, metadata: Dictionary = {}) -> void:
	if node == null:
		return
	var entry: Dictionary = {
		"anim": anim_name,
		"node": node,
		"base_pos": node.position,
		"base_rot": node.rotation,
		"base_scale": node.scale,
		"meta": metadata.duplicate(),
	}
	_entries.append(entry)
	var aid: String = str(metadata.get("anomaly_id", ""))
	if not aid.is_empty():
		if not _anomaly_id_to_nodes.has(aid):
			_anomaly_id_to_nodes[aid] = []
		(_anomaly_id_to_nodes[aid] as Array).append(node)


func trigger_anim(anim_name: String, duration: float = 2.5) -> void:
	_triggered_timers[anim_name] = maxf(float(_triggered_timers.get(anim_name, 0.0)), duration)


func is_node_stunned(node: Node3D) -> bool:
	if node == null:
		return false
	var key: int = node.get_instance_id()
	if not _stunned_nodes.has(key):
		return false
	var st: Dictionary = _stunned_nodes[key]
	if bool(st.get("permanent", false)):
		return true
	return _elapsed < float(st.get("until", 0.0))


func stun_anomaly_node(node_or_id: Variant) -> bool:
	var targets: Array[Node3D] = []
	if node_or_id is Node3D:
		targets.append(node_or_id as Node3D)
	elif node_or_id is String:
		var aid := str(node_or_id)
		if _anomaly_id_to_nodes.has(aid):
			for nd in _anomaly_id_to_nodes[aid]:
				if nd is Node3D:
					targets.append(nd as Node3D)
	elif node_or_id is Area3D or node_or_id is Node:
		var n := node_or_id as Node
		if n.has_meta("visual_target") and n.get_meta("visual_target") is Node3D:
			targets.append(n.get_meta("visual_target") as Node3D)
		elif n.has_meta("anomaly_id"):
			return stun_anomaly_node(str(n.get_meta("anomaly_id", "")))

	if targets.is_empty():
		return false

	for t in targets:
		if not is_instance_valid(t):
			continue
		var is_stalker: bool = ("Shadow" in t.name or "Stalker" in t.name or str(t.get_meta("anim_name", "")) == "anom_shadow_stalker_glide")
		_stunned_nodes[t.get_instance_id()] = {
			"until": _elapsed + 35.0,
			"permanent": is_stalker,
		}
		_spawn_stun_flash(t)
		_animate_stun_drop(t, is_stalker)
	return true


func _spawn_stun_flash(target: Node3D) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(0.42, 0.86, 1.0)
	light.light_energy = 5.5
	light.omni_range = 6.5
	target.add_child(light)
	var tw := target.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.45)
	tw.tween_callback(light.queue_free)


func _animate_stun_drop(target: Node3D, disperse_permanent: bool) -> void:
	var base_p: Vector3 = target.position
	var tw := target.create_tween()
	tw.tween_property(target, "position", base_p + Vector3(0.08, -0.05, -0.06), 0.06)
	tw.tween_property(target, "position", base_p + Vector3(-0.08, -0.10, 0.06), 0.06)
	if disperse_permanent:
		tw.tween_property(target, "scale", Vector3(0.05, 0.05, 0.05), 0.28)
		tw.tween_callback(func() -> void: target.visible = false)
	else:
		tw.tween_property(target, "position:y", maxf(0.02, base_p.y - 0.65), 0.25)


func _process(delta: float) -> void:
	_elapsed += delta
	for k in _triggered_timers.keys():
		var rem: float = float(_triggered_timers[k]) - delta
		if rem <= 0.0:
			_triggered_timers.erase(k)
		else:
			_triggered_timers[k] = rem

	for entry in _entries:
		var node: Node3D = entry.get("node") as Node3D
		if node == null or not is_instance_valid(node) or not node.visible:
			continue
		if is_node_stunned(node):
			continue
		_update_entry(entry, delta)


func _update_entry(entry: Dictionary, delta: float) -> void:
	var anim: String = str(entry["anim"])
	var node: Node3D = entry["node"] as Node3D
	var bpos: Vector3 = entry["base_pos"]
	var brot: Vector3 = entry["base_rot"]
	var bscl: Vector3 = entry["base_scale"]
	var meta: Dictionary = entry["meta"]
	var seed_f: float = float(meta.get("seed", 0.0))
	var t: float = _elapsed + seed_f
	var trig: float = float(_triggered_timers.get(anim, 0.0))

	match anim:
		"gate_iron_swing":
			var swing: float = sin(trig * PI * 0.6) * 1.15 if trig > 0.0 else sin(t * 1.1) * 0.018
			node.rotation = brot + Vector3(0.0, swing, 0.0)
		"guard_booth_door_swing":
			var dswing: float = sin(trig * PI * 0.65) * 1.25 if trig > 0.0 else sin(t * 0.9) * 0.012
			node.rotation = brot + Vector3(0.0, dswing, 0.0)
		"cctv_camera_pan":
			node.rotation = brot + Vector3(0.0, sin(t * 0.42) * 0.58, 0.0)
		"sodium_lamp_sway":
			node.rotation = brot + Vector3(sin(t * 1.2) * 0.035, 0.0, cos(t * 1.45) * 0.04)
			if node is Light3D:
				var base_e: float = float(meta.get("energy", 2.2))
				var dip: float = 0.25 if fmod(t * 1.7 + seed_f, 9.3) < 0.14 else 1.0
				(node as Light3D).light_energy = base_e * (0.94 + sin(t * 7.0) * 0.06) * dip
		"rain_curtain_drift":
			node.position = bpos + Vector3(sin(t * 0.6) * 0.35, -fmod(t * 6.5, 4.0), cos(t * 0.5) * 0.25)
		"payphone_receiver_swing":
			node.rotation = brot + Vector3(sin(t * 2.1) * 0.14, 0.0, cos(t * 1.7) * 0.10)
		"boiler_gauge_tremble":
			node.rotation = brot + Vector3(0.0, 0.0, sin(t * 28.0) * 0.16)
		"boiler_valve_spin":
			if trig > 0.0:
				node.rotation.z += delta * 5.2
			else:
				node.rotation.z += delta * 0.12
		"watchclock_pendulum":
			if node is Light3D:
				var pulse: float = 0.45 + 0.55 * maxf(0.0, sin(t * 3.14))
				(node as Light3D).light_energy = float(meta.get("energy", 0.6)) * pulse
			else:
				node.rotation = brot + Vector3(0.0, 0.0, sin(t * 3.14) * 0.05)
		"dead_oak_wind_sway":
			node.rotation = brot + Vector3(sin(t * 0.8) * 0.025, 0.0, cos(t * 0.65) * 0.03)
		"shrine_candle_flicker":
			if node is Light3D:
				var ce: float = float(meta.get("energy", 1.15))
				(node as Light3D).light_energy = ce * (0.85 + 0.20 * sin(t * 11.3) + 0.10 * cos(t * 17.7))
			else:
				var sc: float = 0.92 + 0.12 * sin(t * 13.0)
				node.scale = Vector3(bscl.x, bscl.y * sc, bscl.z)
		"van_hazard_blink":
			var on: bool = fmod(t, 1.1) < 0.45
			if node is Light3D:
				(node as Light3D).light_energy = float(meta.get("energy", 1.8)) if on else 0.0
			else:
				node.visible = on
		"park_swing_creak":
			var swing_amp: float = 0.42 if trig > 0.0 else 0.16
			node.rotation = brot + Vector3(sin(t * 1.45) * swing_amp, 0.0, 0.0)
		"garage_underlight_flicker":
			var pulse_on: bool = fmod(t * 2.3 + seed_f, 7.0) > 0.35
			if node is Light3D:
				(node as Light3D).light_energy = (float(meta.get("energy", 1.9)) * (0.88 + 0.12 * sin(t * 19.0))) if pulse_on else 0.25
			else:
				node.visible = pulse_on
		"curtain_sway":
			node.rotation = brot + Vector3(sin(t * 1.15) * 0.045, 0.0, cos(t * 0.85) * 0.03)
		"clock_hands_tick":
			var spd: float = float(meta.get("speed", 0.45))
			node.rotation = brot + Vector3(0.0, 0.0, -fmod(t * spd, TAU))
		"grass_wind_sway":
			node.rotation = brot + Vector3(sin(t * 1.6) * 0.018, 0.0, cos(t * 1.3) * 0.015)
		"crt_flicker":
			if node is Light3D:
				(node as Light3D).light_energy = float(meta.get("energy", 0.95)) * (0.88 + 0.12 * sin(t * 24.0))
		"anom_floating_chairs":
			var tremor: float = sin(t * 9.5) * 0.008 if fmod(t, 4.5) < 0.55 else 0.0
			node.position = Vector3(bpos.x + tremor, bpos.y, bpos.z)
			node.rotation = brot + Vector3(0.0, tremor * 2.5, 0.0)
		"anom_well_hands_reach":
			var reach: float = 0.35 + sin(t * 1.45) * 0.28 + (0.25 if trig > 0.0 else 0.0)
			node.position = bpos + Vector3(0.0, reach, 0.0)
			node.rotation = brot + Vector3(sin(t * 2.2) * 0.10, t * 0.28, cos(t * 1.9) * 0.10)
		"anom_black_ooze_pulse":
			var pulse_xz: float = 1.0 + sin(t * 1.8) * 0.09 + (0.12 if trig > 0.0 else 0.0)
			var pulse_y: float = 1.0 + cos(t * 2.4) * 0.24
			node.scale = Vector3(bscl.x * pulse_xz, bscl.y * pulse_y, bscl.z * pulse_xz)
		"anom_butcher_hooks_swing":
			var amp: float = 0.32 if trig > 0.0 else 0.16
			node.rotation = brot + Vector3(sin(t * 1.65) * amp, 0.0, cos(t * 1.1) * (amp * 0.5))
		"anom_hanging_sheet_flutter":
			var gust: float = 0.18 + (0.22 if trig > 0.0 else 0.0)
			node.rotation = brot + Vector3(sin(t * 2.7) * gust, sin(t * 0.9) * 0.14, cos(t * 3.1) * 0.08)
		"anom_13th_window_watcher":
			if node is Light3D:
				(node as Light3D).light_energy = float(meta.get("energy", 1.8)) * (0.65 + 0.55 * absf(sin(t * 0.85)))
			else:
				node.position = bpos + Vector3(sin(t * 0.9) * 0.06, sin(t * 1.5) * 0.04, 0.0)
		"anom_shadow_stalker_glide":
			var dist: float = float(meta.get("patrol_span", 4.5))
			node.position = bpos + Vector3(sin(t * 0.55) * dist, sin(t * 3.4) * 0.04, cos(t * 0.35) * 1.2)
			if _player_ref != null and is_instance_valid(_player_ref):
				var ppos := Vector3(_player_ref.global_position.x, node.global_position.y, _player_ref.global_position.z)
				if node.global_position.distance_to(ppos) > 0.5:
					node.look_at(ppos, Vector3.UP)
		"anom_skoda_headlights_flash":
			var burst: bool = fmod(t, 4.2) < 0.75 or trig > 0.0
			if node is Light3D:
				(node as Light3D).light_energy = (4.6 * (0.7 + 0.3 * sin(t * 22.0))) if burst else 0.0
		"anom_clock_hands_reverse":
			node.rotation = brot + Vector3(0.0, 0.0, -fmod(t * 2.6, TAU))
		"anom_k4_core_breathe":
			var bscale: float = 1.0 + sin(t * 1.9) * 0.14
			node.scale = bscl * bscale
			node.rotation.y += delta * 0.45
		"anom_radio_dial_jitter":
			node.position = bpos + Vector3(sin(t * 34.0) * 0.008, absf(cos(t * 27.0)) * 0.006, 0.0)
		"anom_door_knocker_slam":
			var slam: float = absf(sin(t * 8.5)) * 0.035 if (trig > 0.0 or fmod(t, 5.5) < 0.8) else 0.0
			node.position = bpos + Vector3(0.0, 0.0, slam)
		"anom_neon_sign_buzz":
			if node is Light3D:
				var buzz_on: bool = fmod(t * 4.3, 1.0) > 0.22
				(node as Light3D).light_energy = float(meta.get("energy", 1.5)) if buzz_on else 0.15
			else:
				node.rotation = brot + Vector3(0.0, 0.0, sin(t * 31.0) * 0.025)
		"anom_stairwell_fog_pulse":
			var fs: float = 1.0 + sin(t * 0.75) * 0.22
			node.scale = Vector3(bscl.x * fs, bscl.y, bscl.z * fs)
			if node is Light3D:
				(node as Light3D).light_energy = float(meta.get("energy", 0.9)) * (0.55 + 0.45 * sin(t * 0.9))
