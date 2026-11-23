class_name Blok14Builder
extends Node3D

const DistrictScene := preload("res://scenes/district/ResidentialDistrict.tscn")

var district: Node3D
var interactables: Array[Area3D] = []
var dynamic_nodes: Dictionary = {}
var anomaly_visual_nodes: Dictionary = {}
var event_locations: Dictionary = {}
var animation_hub: Node
var door_manager: Node

var cctv_cameras: Array[Camera3D] = []
var cctv_labels: Array[String] = []
var active_cam_idx: int = 0


func build_world(is_showcase: bool = false) -> void:
	district = DistrictScene.instantiate()
	district.name = "ResidentialDistrict"
	add_child(district)
	district.build_district(is_showcase)

	interactables = district.interactables
	dynamic_nodes = district.dynamic_nodes
	anomaly_visual_nodes = district.anomaly_visual_nodes
	event_locations = district.event_locations
	animation_hub = district.animation_hub
	door_manager = district.door_manager
	cctv_cameras = district.cctv_cameras
	cctv_labels = district.cctv_labels
	active_cam_idx = district.active_cam_idx


func get_player_spawn_position() -> Vector3:
	if district:
		return district.get_player_spawn_position()
	return Vector3(-15.8, 0.20, -54.5)


func set_rain_follow_position(pos: Vector3) -> void:
	if district and district.has_method("set_rain_follow_position"):
		district.set_rain_follow_position(pos)


func get_zone_for_position(pos: Vector3) -> Dictionary:
	if district:
		return district.get_zone_for_position(pos)
	return {"id": "central_park", "label": "CENTRAL DISTRICT"}


func get_surface_for_position(pos: Vector3) -> String:
	if district:
		return district.get_surface_for_position(pos)
	return "cobble"


func refresh_night_state() -> void:
	if district:
		district.refresh_night_state()


func set_red_door_open(is_open: bool) -> void:
	if district:
		district.set_red_door_open(is_open)


func cycle_cctv_camera() -> String:
	if district:
		var lbl: String = district.cycle_cctv_camera()
		active_cam_idx = district.active_cam_idx
		return lbl
	return "NO SIGNAL"


func set_cctv_camera(idx: int) -> String:
	if district:
		var lbl: String = district.set_cctv_camera(idx)
		active_cam_idx = district.active_cam_idx
		return lbl
	return "NO SIGNAL"


func get_cctv_texture() -> Texture2D:
	if district:
		return district.get_cctv_texture()
	return null


func get_active_cctv_label() -> String:
	if district:
		return district.get_active_cctv_label()
	return "CAM-01"


func find_anomaly_in_beam(origin: Vector3, dir: Vector3, max_dist: float = 7.0) -> Dictionary:
	if district:
		return district.find_anomaly_in_beam(origin, dir, max_dist)
	return {}
