class_name NPCCharacterController
extends CharacterBody3D

# Prompt 08 Part 2.3 — Real CharacterBody3D collision on all estate NPCs so no resident clips walls or props!

var char_id: String = ""
var role_mode: String = "idle_alert"
var model_root: Node3D
var torso_pivot: Node3D
var head_pivot: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var npc_col: CollisionShape3D

var player_ref: Node3D
var linked_interactable: Area3D
var interactable_offset: Vector3 = Vector3(0.0, 1.1, 0.0)

var schedule_waypoints: Array[Vector3] = []
var waypoint_idx: int = 0
var walk_speed: float = 1.18
var wait_timer: float = 0.0
var is_moving: bool = false

var _anim_t: float = 0.0
var _walk_phase: float = 0.0
var _talk_timer: float = 0.0
var _base_torso_rx: float = 0.0
var _seed: float = 0.0


func setup_character(
	p_char_id: String,
	glb_name: String,
	p_role_mode: String,
	start_pos: Vector3,
	start_yaw_deg: float = 0.0,
	p_player: Node3D = null
) -> void:
	char_id = p_char_id
	role_mode = p_role_mode
	player_ref = p_player
	name = "NPC_" + p_char_id.capitalize()
	position = start_pos
	rotation_degrees.y = start_yaw_deg
	_seed = float(abs(p_char_id.hash() % 1000)) * 0.01

	collision_layer = 8
	collision_mask = 1
	npc_col = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.68
	npc_col.shape = cap
	npc_col.position = Vector3(0.0, 0.84, 0.0)
	add_child(npc_col)

	var path := "res://assets/models/%s.glb" % glb_name
	if ResourceLoader.exists(path):
		var packed: Resource = load(path)
		if packed is PackedScene:
			var inst := (packed as PackedScene).instantiate()
			if inst is Node3D:
				model_root = inst as Node3D
				add_child(model_root)
				_bind_articulated_pivots(model_root)


func adopt_existing_model(p_char_id: String, existing_model: Node3D, p_role_mode: String, p_player: Node3D = null) -> void:
	char_id = p_char_id
	role_mode = p_role_mode
	player_ref = p_player
	model_root = existing_model
	_seed = float(abs(p_char_id.hash() % 1000)) * 0.01
	if model_root:
		_bind_articulated_pivots(model_root)


func _bind_articulated_pivots(root_node: Node3D) -> void:
	torso_pivot = root_node.find_child("TorsoPivot", true, false) as Node3D
	head_pivot = root_node.find_child("HeadPivot", true, false) as Node3D
	arm_l = root_node.find_child("ArmL_Pivot", true, false) as Node3D
	arm_r = root_node.find_child("ArmR_Pivot", true, false) as Node3D
	leg_l = root_node.find_child("LegL_Pivot", true, false) as Node3D
	leg_r = root_node.find_child("LegR_Pivot", true, false) as Node3D
	if torso_pivot:
		_base_torso_rx = torso_pivot.rotation.x


func set_schedule_waypoints(pts: Array[Vector3], speed: float = 1.18) -> void:
	schedule_waypoints = pts.duplicate()
	walk_speed = speed
	waypoint_idx = 1 if (pts.size() >= 2 and position.distance_to(pts[0]) < 1.2) else 0
	wait_timer = 0.6


func trigger_talk_gesture(duration: float = 5.5) -> void:
	_talk_timer = maxf(_talk_timer, duration)


func is_articulated() -> bool:
	return head_pivot != null and arm_l != null and arm_r != null and leg_l != null and leg_r != null


func _process(delta: float) -> void:
	if not visible:
		return
	_anim_t += delta
	if _talk_timer > 0.0:
		_talk_timer = maxf(0.0, _talk_timer - delta)

	_update_schedule_movement(delta)
	_update_procedural_animation(delta)

	if linked_interactable and is_instance_valid(linked_interactable):
		linked_interactable.global_position = global_position + interactable_offset


func _update_schedule_movement(delta: float) -> void:
	is_moving = false
	if schedule_waypoints.size() < 2:
		return
	if _talk_timer > 0.0:
		_smooth_face_player(delta)
		return
	if player_ref and is_instance_valid(player_ref) and char_id in ["anna", "dana", "varga"]:
		if global_position.distance_to(player_ref.global_position) < 3.6:
			_smooth_face_player(delta)
			return

	if wait_timer > 0.0:
		wait_timer = maxf(0.0, wait_timer - delta)
		return

	var target: Vector3 = schedule_waypoints[waypoint_idx]
	var to_t: Vector3 = target - global_position
	to_t.y = 0.0
	var dist: float = to_t.length()
	if dist < 0.50:
		waypoint_idx = (waypoint_idx + 1) % schedule_waypoints.size()
		wait_timer = 4.5 + fmod(_seed * 3.1 + float(waypoint_idx) * 1.7, 5.5)
		return

	is_moving = true
	var dir_v: Vector3 = to_t.normalized()
	velocity.x = dir_v.x * walk_speed
	velocity.z = dir_v.z * walk_speed
	velocity.y = 0.0 if is_on_floor() else -12.0 * minf(delta, 0.05)
	if is_inside_tree():
		var phys_dt: float = get_physics_process_delta_time()
		if phys_dt <= 0.001:
			phys_dt = 1.0 / 60.0
		var rem: float = maxf(0.001, delta)
		while rem > 0.0005:
			move_and_slide()
			rem -= phys_dt
	else:
		global_position += dir_v * minf(dist, walk_speed * delta)
	var target_yaw: float = atan2(to_t.x, to_t.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * 4.5)


func _smooth_face_player(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	var to_p: Vector3 = player_ref.global_position - global_position
	to_p.y = 0.0
	if to_p.length() > 0.2:
		var target_yaw: float = atan2(to_p.x, to_p.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 3.8)


func _update_procedural_animation(delta: float) -> void:
	var breath: float = sin(_anim_t * 1.9 + _seed)
	if torso_pivot:
		var lean: float = 0.22 if role_mode == "exhausted" else 0.0
		torso_pivot.rotation.x = _base_torso_rx + lean + breath * 0.022
		torso_pivot.rotation.z = sin(_walk_phase * 0.5) * 0.035 if is_moving else breath * 0.01

	if is_moving:
		_walk_phase += delta * (walk_speed * 4.6)
		var leg_swing: float = sin(_walk_phase) * 0.36
		var arm_swing: float = -sin(_walk_phase) * 0.26
		if leg_l:
			leg_l.rotation.x = leg_swing
		if leg_r:
			leg_r.rotation.x = -leg_swing
		if arm_l:
			arm_l.rotation.x = arm_swing
		if arm_r:
			arm_r.rotation.x = -arm_swing * (0.45 if char_id in ["anna", "resident_a"] else 1.0)
	else:
		if leg_l:
			leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.0, delta * 6.0)
		if leg_r:
			leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.0, delta * 6.0)
		_animate_role_idle_arms(delta)

	if head_pivot:
		var target_hy: float = sin(_anim_t * 0.65 + _seed) * 0.28
		var target_hx: float = 0.0
		if role_mode == "idle_supervisor":
			target_hx = 0.22 if (sin(_anim_t * 0.9 + _seed) > 0.1) else -0.04
		elif role_mode == "idle_shop":
			target_hx = 0.16 if (sin(_anim_t * 0.8 + _seed) > 0.0) else -0.04
			target_hy = sin(_anim_t * 0.55 + _seed) * 0.42
		elif role_mode == "exhausted":
			target_hx = 0.34 + sin(_anim_t * 1.1) * 0.05
			target_hy = sin(_anim_t * 0.4) * 0.10

		if player_ref and is_instance_valid(player_ref):
			var to_p: Vector3 = player_ref.global_position - global_position
			var d: float = to_p.length()
			if d < 6.8:
				var local_dir: Vector3 = global_transform.basis.inverse() * to_p.normalized()
				target_hy = clampf(atan2(local_dir.x, local_dir.z), -0.68, 0.68)
				target_hx = clampf(-local_dir.y * 0.35, -0.22, 0.22)
		var head_lag: float = 2.0 if char_id in ["anna", "peter", "milan_rescue"] else 3.2
		head_pivot.rotation.y = lerpf(head_pivot.rotation.y, target_hy, delta * head_lag)
		head_pivot.rotation.x = lerpf(head_pivot.rotation.x, target_hx, delta * head_lag)


func _animate_role_idle_arms(delta: float) -> void:
	var target_l: float = 0.0
	var target_r: float = 0.0
	if _talk_timer > 0.0:
		target_r = -0.42 + sin(_anim_t * 4.2 + _seed) * 0.22
		target_l = -0.18 + cos(_anim_t * 2.8 + _seed) * 0.10
	elif role_mode == "idle_supervisor":
		target_l = -0.58 + sin(_anim_t * 1.1) * 0.04
		target_r = -0.14 + sin(_anim_t * 2.4 + _seed) * 0.07
	elif role_mode == "idle_shop":
		target_l = -0.45 + sin(_anim_t * 2.1 + _seed) * 0.18
		target_r = -0.40 + cos(_anim_t * 1.9 + _seed) * 0.20
	elif role_mode == "idle_alert":
		target_r = -0.18 + sin(_anim_t * 1.3 + _seed) * 0.05
		target_l = -0.08 + sin(_anim_t * 0.9) * 0.04
	elif role_mode == "exhausted":
		target_l = -0.32
		target_r = -0.35

	if arm_l:
		arm_l.rotation.x = lerpf(arm_l.rotation.x, target_l, delta * 4.5)
	if arm_r:
		arm_r.rotation.x = lerpf(arm_r.rotation.x, target_r, delta * 4.5)
