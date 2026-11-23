class_name FirstPersonBodyController
extends Node3D

var body_root: Node3D
var thigh_l: Node3D
var thigh_r: Node3D
var shin_l: Node3D
var shin_r: Node3D
var boot_l: Node3D
var boot_r: Node3D
var torso_node: Node3D

var _walk_phase: float = 0.0
var _turn_lag_yaw: float = 0.0
var _last_parent_yaw: float = 0.0
var shadow_mesh_count: int = 0

const BODY_BASE_OFFSET := Vector3(0.0, 0.0, 0.21)


func _ready() -> void:
	name = "FirstPersonBodyController"
	position = BODY_BASE_OFFSET
	_build_body()
	if get_parent() is Node3D:
		_last_parent_yaw = (get_parent() as Node3D).rotation.y


func _build_body() -> void:
	body_root = Node3D.new()
	body_root.name = "BodyRigRoot"
	add_child(body_root)

	var glb_path := "res://assets/models/fp_guard_body.glb"
	if ResourceLoader.exists(glb_path):
		var packed: Resource = ResourceLoader.load(glb_path)
		if packed is PackedScene:
			var inst: Node = (packed as PackedScene).instantiate()
			if inst is Node3D:
				body_root.add_child(inst)
				_cache_limb_nodes(inst)
				_enable_body_shadows(inst)


func _cache_limb_nodes(root_node: Node) -> void:
	torso_node = root_node.find_child("TorsoJacket", true, false) as Node3D
	thigh_l = root_node.find_child("Thigh_L", true, false) as Node3D
	thigh_r = root_node.find_child("Thigh_R", true, false) as Node3D
	shin_l = root_node.find_child("Shin_L", true, false) as Node3D
	shin_r = root_node.find_child("Shin_R", true, false) as Node3D
	boot_l = root_node.find_child("BootFoot_L", true, false) as Node3D
	boot_r = root_node.find_child("BootFoot_R", true, false) as Node3D


func _enable_body_shadows(node: Node) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		shadow_mesh_count += 1
	for ch in node.get_children():
		_enable_body_shadows(ch)


func is_body_visible_in_down_look(pitch_rad: float) -> bool:
	return visible and body_root != null and shadow_mesh_count > 0 and pitch_rad < deg_to_rad(-28.0)


func update_body(
	delta: float,
	speed_ratio: float,
	sprinting: bool,
	fast_walking: bool,
	crouching: bool,
	parent_yaw: float,
	camera_pitch: float
) -> void:
	# Smooth upper/lower body turn lag so turning feels physical
	var yaw_delta: float = wrapf(parent_yaw - _last_parent_yaw, -PI, PI)
	_last_parent_yaw = parent_yaw
	_turn_lag_yaw = clampf(_turn_lag_yaw - yaw_delta * 0.65, -0.26, 0.26)
	_turn_lag_yaw = move_toward(_turn_lag_yaw, 0.0, delta * 3.2)

	# Keep torso slightly further back when looking straight down to guarantee zero camera clipping
	var down_factor: float = clampf(-camera_pitch / deg_to_rad(78.0), 0.0, 1.0)
	var target_z: float = BODY_BASE_OFFSET.z + down_factor * 0.04
	var target_y: float = -0.32 if crouching else 0.0
	position.z = lerpf(position.z, target_z, delta * 10.0)
	position.y = lerpf(position.y, target_y, delta * 9.0)
	rotation.y = _turn_lag_yaw

	var cadence: float = 10.2 if sprinting else (8.0 if fast_walking else 5.8)
	if speed_ratio > 0.08:
		_walk_phase += delta * cadence
	else:
		_walk_phase = move_toward(_walk_phase, 0.0, delta * 4.0)

	var stride_amp: float = clampf(speed_ratio, 0.0, 1.45) * (0.34 if sprinting else 0.22)
	var swing_l: float = sin(_walk_phase) * stride_amp
	var swing_r: float = -sin(_walk_phase) * stride_amp
	var lift_l: float = maxf(0.0, cos(_walk_phase)) * stride_amp * 0.14
	var lift_r: float = maxf(0.0, -cos(_walk_phase)) * stride_amp * 0.14

	if thigh_l:
		thigh_l.rotation.x = swing_l
	if thigh_r:
		thigh_r.rotation.x = swing_r
	if shin_l:
		shin_l.rotation.x = maxf(0.0, -swing_l * 0.65)
		shin_l.position.z = -swing_l * 0.07
	if shin_r:
		shin_r.rotation.x = maxf(0.0, -swing_r * 0.65)
		shin_r.position.z = -swing_r * 0.07
	if boot_l:
		boot_l.position.z = -0.055 - swing_l * 0.11
		boot_l.position.y = 0.042 + lift_l
	if boot_r:
		boot_r.position.z = -0.055 - swing_r * 0.11
		boot_r.position.y = 0.042 + lift_r
	if torso_node:
		torso_node.rotation.z = sin(_walk_phase * 0.5) * stride_amp * 0.08
