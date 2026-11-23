class_name AntagonistAI
extends Node3D

signal state_changed(new_state: String)
signal player_spotted(intruder_pos: Vector3)
signal office_door_banged

const VALID_STATES := [
	"PATROLLING",
	"HIDING",
	"INVESTIGATING_SOUND",
	"WATCHING_PLAYER",
	"PURSUING",
	"SEARCHING",
	"ESCAPING",
]

# Roman Král's real maintenance routes across Sídlisko Javor (Part 9.6 & Part 10)
const PATROL_WAYPOINTS := [
	Vector3(58.0, 0.05, 8.0),    # Delivery Alley behind shops
	Vector3(26.0, 0.05, 32.0),   # Dark gap between Block B & Block C
	Vector3(-21.0, 0.05, 22.0),  # Central Park north trees
	Vector3(-64.0, 0.05, -22.0), # Technical Substation shadow
	Vector3(-76.0, 0.05, -48.0), # Garage Complex dark end
	Vector3(24.0, 0.05, -52.0),  # South Parking Lot far corner
]

const HIDEOUT_POS := Vector3(6.8, 0.05, 41.2) # Building B service alcove / Unlisted Door 47

var character_name: String = "Roman Král"
var current_state: String = "PATROLLING"
var visual_root: Node3D
var player_ref: Node3D
var district_ref: Node3D
var footstep_player: AudioStreamPlayer3D

# Articulated human limbs from char_roman.glb (natural ordinary walk & head-checking, zero monster anims!)
var _torso_p: Node3D
var _head_p: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _walk_phase: float = 0.0
var _idle_t: float = 0.0

var waypoint_index: int = 0
var target_position: Vector3 = PATROL_WAYPOINTS[0]
var last_known_player_pos: Vector3 = Vector3.ZERO
var state_timer: float = 0.0
var _step_accum: float = 0.0
var _office_bang_cooldown: float = 0.0
var blackout_hunt_active: bool = false

const PATROL_SPEED: float = 1.65
const INVESTIGATE_SPEED: float = 2.15
const PURSUE_SPEED: float = 3.20
const ESCAPE_SPEED: float = 3.75


func _gs() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("GameState") if ml is SceneTree else null


func _au() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("AudioSynth") if ml is SceneTree else null


func setup_antagonist(district: Node3D, player: Node3D) -> void:
	name = "AntagonistAI"
	district_ref = district
	player_ref = player
	position = PATROL_WAYPOINTS[0]
	target_position = PATROL_WAYPOINTS[1]

	visual_root = Node3D.new()
	visual_root.name = "RomanKralVisual"
	add_child(visual_root)

	# Prompt 06 Part 9.6: Unique articulated Roman Král maintenance worker model (NOT generic placeholder!)
	var glb_path := "res://assets/models/char_roman.glb"
	if not ResourceLoader.exists(glb_path):
		glb_path = "res://assets/models/humanoid_guard.glb"
	if ResourceLoader.exists(glb_path):
		var sc: PackedScene = load(glb_path)
		if sc:
			var inst := sc.instantiate()
			if inst is Node3D:
				(inst as Node3D).rotation_degrees.y = 180.0
				visual_root.add_child(inst)
				_torso_p = inst.find_child("TorsoPivot", true, false) as Node3D
				_head_p = inst.find_child("HeadPivot", true, false) as Node3D
				_arm_l = inst.find_child("ArmL_Pivot", true, false) as Node3D
				_arm_r = inst.find_child("ArmR_Pivot", true, false) as Node3D
				_leg_l = inst.find_child("LegL_Pivot", true, false) as Node3D
				_leg_r = inst.find_child("LegR_Pivot", true, false) as Node3D

	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.name = "IntruderFootstep3D"
	footstep_player.max_distance = 24.0
	footstep_player.unit_size = 3.2
	footstep_player.volume_db = -5.0
	footstep_player.bus = "EnvLayer"
	add_child(footstep_player)


func get_state() -> String:
	return current_state


func set_blackout_hunt(enabled: bool) -> void:
	blackout_hunt_active = enabled
	if enabled:
		# Move physically toward player's general sector without teleporting directly onto player
		if player_ref and global_position.distance_to(player_ref.global_position) > 55.0:
			global_position = Vector3(-52.0, 0.05, -24.0)
		transition_to("INVESTIGATING_SOUND", 14.0)
		if player_ref:
			target_position = Vector3(player_ref.global_position.x, 0.05, player_ref.global_position.z)


func trigger_night4_stairwell_walkaway() -> void:
	# Part 6: Grounded non-teleport sighting near Building B — Roman physically walks away around the corridor!
	global_position = Vector3(5.2, 0.05, 38.6)
	target_position = Vector3(14.5, 0.05, 32.0)
	transition_to("ESCAPING", 10.0)


func trigger_night5_corridor_escape() -> void:
	# Part 7: Silhouette runs physically away through the Hidden Service Corridor exit (zero teleport!)
	global_position = Vector3(-76.0, -4.4, -18.0)
	target_position = Vector3(-61.0, -4.4, -30.0)
	transition_to("ESCAPING", 12.0)


func transition_to(new_state: String, duration: float = 6.0) -> void:
	if not (new_state in VALID_STATES):
		return
	var prev: String = current_state
	current_state = new_state
	state_timer = duration
	match current_state:
		"HIDING":
			target_position = HIDEOUT_POS
		"ESCAPING":
			if target_position.distance_to(global_position) < 2.0:
				target_position = PATROL_WAYPOINTS[(waypoint_index + 2) % PATROL_WAYPOINTS.size()]
	if current_state != prev:
		emit_signal("state_changed", current_state)


func notify_sound_event(world_pos: Vector3, loudness_radius: float = 28.0) -> void:
	if global_position.distance_to(world_pos) <= loudness_radius:
		last_known_player_pos = world_pos
		target_position = world_pos
		if current_state in ["PATROLLING", "HIDING", "WATCHING_PLAYER"]:
			transition_to("INVESTIGATING_SOUND", 10.0)


func is_visible_on_cctv(cam_idx: int) -> bool:
	if not district_ref or not ("cctv_cameras" in district_ref):
		return false
	var cams: Array = district_ref.get("cctv_cameras")
	if cam_idx < 0 or cam_idx >= cams.size():
		return false
	var cam: Camera3D = cams[cam_idx] as Camera3D
	if not cam:
		return false
	var to_me: Vector3 = global_position - cam.global_position
	if to_me.length() > 55.0:
		return false
	var cam_fwd: Vector3 = -cam.global_transform.basis.z
	return cam_fwd.dot(to_me.normalized()) > 0.52


func _process(delta: float) -> void:
	_idle_t += delta
	if _office_bang_cooldown > 0.0:
		_office_bang_cooldown = maxf(0.0, _office_bang_cooldown - delta)
	if state_timer > 0.0:
		state_timer = maxf(0.0, state_timer - delta)

	_evaluate_perception(delta)
	var moved_spd: float = _execute_movement(delta)
	_animate_human_body(delta, moved_spd)


func _evaluate_perception(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	var ppos: Vector3 = player_ref.global_position
	var dist: float = global_position.distance_to(ppos)
	var f_on: bool = bool(player_ref.get("flashlight_on")) and (_gs() != null and _gs().equipped_slot == "flashlight")
	var pvel: Vector3 = player_ref.velocity if ("velocity" in player_ref) else Vector3.ZERO
	var p_speed: float = Vector2(pvel.x, pvel.z).length()

	# Player sprinting nearby attracts investigation
	var sound_range: float = 42.0 if blackout_hunt_active else 32.0
	if p_speed > 3.1 and dist < sound_range and current_state in ["PATROLLING", "WATCHING_PLAYER"]:
		notify_sound_event(ppos, sound_range + 4.0)
		return

	# Roman Král avoids direct eye contact & flashlight beams on early nights (hides/retreats naturally!)
	if f_on and dist < 24.0 and ("camera" in player_ref) and player_ref.camera != null:
		var cam: Camera3D = player_ref.camera
		var cam_fwd: Vector3 = -cam.global_transform.basis.z
		var to_intruder: Vector3 = (global_position - cam.global_position).normalized()
		if cam_fwd.dot(to_intruder) > 0.88 and current_state == "WATCHING_PLAYER" and dist > 11.0 and not blackout_hunt_active:
			transition_to("ESCAPING", 8.0)
			return

	var detect_range: float = (28.0 if blackout_hunt_active else 22.0) if f_on else (15.5 if blackout_hunt_active else 11.5)
	if dist <= detect_range:
		last_known_player_pos = ppos
		if (dist <= 10.5 or blackout_hunt_active) and current_state != "ESCAPING":
			if current_state != "PURSUING":
				emit_signal("player_spotted", global_position)
			transition_to("PURSUING", 9.0 if blackout_hunt_active else 7.5)
		elif current_state in ["PATROLLING", "INVESTIGATING_SOUND"]:
			transition_to("WATCHING_PLAYER", 6.5)
	else:
		if current_state == "PURSUING" and state_timer <= 0.0:
			target_position = last_known_player_pos
			transition_to("SEARCHING", 8.0)
		elif current_state in ["SEARCHING", "INVESTIGATING_SOUND", "WATCHING_PLAYER", "ESCAPING"] and state_timer <= 0.0:
			transition_to("PATROLLING", 12.0)


func _execute_movement(delta: float) -> float:
	var speed: float = PATROL_SPEED
	match current_state:
		"PATROLLING":
			speed = PATROL_SPEED
			target_position = PATROL_WAYPOINTS[waypoint_index]
			if global_position.distance_to(target_position) < 1.2:
				waypoint_index = (waypoint_index + 1) % PATROL_WAYPOINTS.size()
				target_position = PATROL_WAYPOINTS[waypoint_index]
		"HIDING":
			speed = PATROL_SPEED
			if global_position.distance_to(target_position) < 1.0:
				speed = 0.0
		"WATCHING_PLAYER":
			speed = 0.0
			if player_ref:
				_face_towards(player_ref.global_position)
		"INVESTIGATING_SOUND":
			speed = INVESTIGATE_SPEED
			if global_position.distance_to(target_position) < 1.4:
				transition_to("SEARCHING", 6.0)
		"PURSUING":
			speed = PURSUE_SPEED
			if player_ref:
				var ppos: Vector3 = player_ref.global_position
				var player_in_office: bool = (ppos.x >= -23.0 and ppos.x <= -13.0 and ppos.z >= -60.5 and ppos.z <= -51.5)
				if player_in_office:
					target_position = Vector3(-13.1, 0.05, -54.6)
					if global_position.distance_to(target_position) < 1.5:
						_handle_security_office_door_encounter()
						return 0.0
				else:
					target_position = Vector3(ppos.x, global_position.y, ppos.z)
		"SEARCHING":
			speed = PATROL_SPEED * 0.85
			if global_position.distance_to(target_position) < 1.2 and state_timer <= 0.0:
				transition_to("PATROLLING", 10.0)
		"ESCAPING":
			speed = ESCAPE_SPEED
			if global_position.distance_to(target_position) < 1.5:
				transition_to("HIDING", 9.0)

	if speed > 0.01:
		var dir: Vector3 = target_position - global_position
		dir.y = 0.0
		var dist: float = dir.length()
		if dist > 0.05:
			var step_vec: Vector3 = dir.normalized() * minf(dist, speed * delta)
			global_position += step_vec
			_face_towards(global_position + dir.normalized())
			_step_accum += step_vec.length()
			if _step_accum >= 1.35:
				_step_accum = 0.0
				_play_3d_footstep()
			return speed
	return 0.0


func _animate_human_body(delta: float, move_speed: float) -> void:
	# Natural human stride, corner-checking head turns & door-handle arm posture (NO monster posture!)
	if move_speed > 0.05:
		_walk_phase += delta * (move_speed * 3.8)
		var l_sw: float = sin(_walk_phase) * 0.40
		var a_sw: float = -sin(_walk_phase) * 0.30
		if _leg_l:
			_leg_l.rotation.x = l_sw
		if _leg_r:
			_leg_r.rotation.x = -l_sw
		if _arm_l:
			_arm_l.rotation.x = a_sw
		if _arm_r:
			_arm_r.rotation.x = -a_sw
	else:
		if _leg_l:
			_leg_l.rotation.x = lerpf(_leg_l.rotation.x, 0.0, delta * 6.0)
		if _leg_r:
			_leg_r.rotation.x = lerpf(_leg_r.rotation.x, 0.0, delta * 6.0)
		if _arm_r:
			# Subtle door-handle / keyring check motion when waiting quietly
			var check_arm: float = -0.35 if current_state == "SEARCHING" else -0.10
			_arm_r.rotation.x = lerpf(_arm_r.rotation.x, check_arm + sin(_idle_t * 1.5) * 0.05, delta * 4.0)
	if _head_p:
		var scan_y: float = sin(_idle_t * 1.1) * 0.45 if current_state in ["SEARCHING", "INVESTIGATING_SOUND", "HIDING"] else 0.0
		_head_p.rotation.y = lerpf(_head_p.rotation.y, scan_y, delta * 3.5)
	if _torso_p:
		_torso_p.rotation.x = sin(_idle_t * 1.8) * 0.02


func _handle_security_office_door_encounter() -> void:
	var au := _au()
	if district_ref and district_ref.get("door_manager") != null:
		var dm: Node = district_ref.get("door_manager")
		var sdoor: Variant = dm.doors.get("sec_office_door", null)
		if sdoor and sdoor.is_locked:
			if _office_bang_cooldown <= 0.0:
				_office_bang_cooldown = 8.0
				if au:
					au.play_sfx("door_bang", -3.5, 0.96)
				if sdoor.has_method("jiggle_locked_handle"):
					sdoor.jiggle_locked_handle()
				emit_signal("office_door_banged")
			transition_to("ESCAPING", 10.0)
			return
		elif sdoor and not sdoor.is_open:
			sdoor.set_open(true, true)
	transition_to("ESCAPING", 9.0)


func _face_towards(look_pt: Vector3) -> void:
	var flat_pt := Vector3(look_pt.x, global_position.y, look_pt.z)
	if global_position.distance_to(flat_pt) > 0.05:
		look_at(flat_pt, Vector3.UP)


func _play_3d_footstep() -> void:
	var au := _au()
	if not au or not footstep_player:
		return
	if au.has_method("has_stream") and au.has_stream("step_cobble_1"):
		footstep_player.stream = au._streams["step_cobble_1"]
		footstep_player.pitch_scale = randf_range(0.84, 0.94)
		if au._audio_enabled:
			footstep_player.play()
