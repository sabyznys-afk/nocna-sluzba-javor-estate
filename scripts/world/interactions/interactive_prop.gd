class_name InteractiveProp
extends Node3D

const InteractableNode = preload("res://scripts/world/interactable.gd")

signal state_toggled(prop_id: String, active: bool)

var prop_id: String = ""
var prop_kind: String = "switch" # "switch", "drawer", "locker"
var is_active: bool = false
var target_lights: Array[Light3D] = []
var grant_key_id: String = ""
var grant_battery: bool = false

var _moving_part: Node3D
var _area: Area3D
var _loot_taken: bool = false
var _base_pos: Vector3 = Vector3.ZERO


func setup_prop(
	p_id: String,
	p_kind: String,
	p_pos: Vector3,
	p_rot_y: float = 0.0,
	p_lights: Array[Light3D] = [],
	p_grant_key: String = "",
	p_grant_battery: bool = false
) -> void:
	prop_id = p_id
	prop_kind = p_kind
	target_lights = p_lights
	grant_key_id = p_grant_key
	grant_battery = p_grant_battery
	position = p_pos
	rotation_degrees.y = p_rot_y
	name = "Prop_" + p_id

	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.18, 0.20, 0.22)
	iron.metallic = 0.72
	iron.roughness = 0.48
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.28, 0.19, 0.12)
	wood.roughness = 0.76
	var plastic := StandardMaterial3D.new()
	plastic.albedo_color = Color(0.76, 0.74, 0.66)
	plastic.roughness = 0.45

	if prop_kind == "switch":
		var plate := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(0.12, 0.18, 0.04)
		pb.material = plastic
		plate.mesh = pb
		add_child(plate)

		_moving_part = Node3D.new()
		_moving_part.position = Vector3(0, 0, 0.025)
		add_child(_moving_part)
		var lever := MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(0.03, 0.07, 0.04)
		lb.material = iron
		lever.mesh = lb
		_moving_part.add_child(lever)
		is_active = true
		_moving_part.rotation_degrees.x = -25.0
	elif prop_kind == "drawer":
		var box_m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.54, 0.18, 0.48)
		bm.material = wood
		box_m.mesh = bm
		add_child(box_m)

		_moving_part = Node3D.new()
		_moving_part.position = Vector3(0, 0, 0.02)
		_base_pos = _moving_part.position
		add_child(_moving_part)
		var front := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.50, 0.16, 0.04)
		fm.material = wood
		front.mesh = fm
		front.position = Vector3(0, 0, 0.23)
		_moving_part.add_child(front)
	else: # locker
		var cab := StaticBody3D.new()
		var cm := MeshInstance3D.new()
		var cbox := BoxMesh.new()
		cbox.size = Vector3(0.64, 1.85, 0.56)
		cbox.material = iron
		cm.mesh = cbox
		cm.position = Vector3(0, 0.925, 0)
		cab.add_child(cm)
		var ccol := CollisionShape3D.new()
		var cs := BoxShape3D.new()
		cs.size = Vector3(0.64, 1.85, 0.56)
		ccol.shape = cs
		ccol.position = Vector3(0, 0.925, 0)
		cab.add_child(ccol)
		add_child(cab)

		_moving_part = Node3D.new()
		_moving_part.position = Vector3(-0.31, 0.05, 0.29)
		add_child(_moving_part)
		var leaf := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.60, 1.75, 0.03)
		lm.material = iron
		leaf.mesh = lm
		leaf.position = Vector3(0.30, 0.875, 0.0)
		_moving_part.add_child(leaf)

	_area = InteractableNode.new()
	_area.name = "PropInt_" + p_id
	_area.interact_id = p_id
	_area.interact_type = "interactive_prop"
	_area.extra_data = {"prop_node": self}
	_area.position = Vector3(0, 0.85 if prop_kind == "locker" else 0.0, 0.2)
	var col := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(0.75, 1.4 if prop_kind == "locker" else 0.5, 0.65)
	col.shape = b
	_area.add_child(col)
	add_child(_area)
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _area == null:
		return
	match prop_kind:
		"switch":
			_area.prompt_text = "[E] Flip Light Switch (%s)" % ("OFF" if is_active else "ON")
		"drawer":
			_area.prompt_text = "[E] %s Desk Drawer" % ("Close" if is_active else "Search")
		"locker":
			_area.prompt_text = "[E] %s Steel Locker" % ("Close" if is_active else "Open")


func _gs() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("GameState") if ml is SceneTree else null


func _au() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("AudioSynth") if ml is SceneTree else null


func trigger() -> String:
	var gs := _gs()
	var au := _au()
	is_active = not is_active
	if prop_kind == "switch":
		if au:
			au.play_sfx("switch_click", -5.0, 1.05 if is_active else 0.92)
		if _moving_part:
			var tw := create_tween()
			tw.tween_property(_moving_part, "rotation_degrees:x", -25.0 if is_active else 25.0, 0.10)
		for l: Light3D in target_lights:
			if is_instance_valid(l):
				l.visible = is_active
		_refresh_prompt()
		emit_signal("state_toggled", prop_id, is_active)
		return "Switched lights %s." % ("ON" if is_active else "OFF")

	if au:
		au.play_sfx("drawer_open", -5.0)
	if prop_kind == "drawer" and _moving_part:
		var tw := create_tween()
		tw.tween_property(_moving_part, "position", _base_pos + (Vector3(0, 0, 0.34) if is_active else Vector3.ZERO), 0.32)
	elif prop_kind == "locker" and _moving_part:
		var tw := create_tween()
		tw.tween_property(_moving_part, "rotation_degrees:y", -102.0 if is_active else 0.0, 0.42)

	var found_msg := ""
	if is_active and not _loot_taken:
		_loot_taken = true
		if not grant_key_id.is_empty():
			if gs:
				gs.collect_key(grant_key_id)
			if au:
				au.play_sfx("keys_jingle", -4.0)
			found_msg += "Found Key [%s]! " % grant_key_id.replace("key_", "").to_upper()
		if grant_battery:
			if gs:
				gs.add_spare_battery(1)
			if au:
				au.play_sfx("battery_swap", -5.0)
			found_msg += "Found Spare 4.5V Battery! "
	_refresh_prompt()
	emit_signal("state_toggled", prop_id, is_active)
	return found_msg
