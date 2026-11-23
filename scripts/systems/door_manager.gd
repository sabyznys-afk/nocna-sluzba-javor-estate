class_name DoorManager
extends Node

var doors: Dictionary = {} # door_id -> PhysicalDoor


func _gs() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("GameState") if ml is SceneTree else null


func register_door(door_node: Node) -> void:
	if door_node == null or not ("door_id" in door_node):
		return
	var did: String = str(door_node.door_id)
	doors[did] = door_node
	if door_node.has_signal("door_state_changed") and not door_node.door_state_changed.is_connected(_on_door_state_changed):
		door_node.door_state_changed.connect(_on_door_state_changed)
	_restore_single_door(did, door_node)


func apply_saved_states() -> void:
	for did: String in doors.keys():
		var dnode: Node = doors[did]
		if dnode and is_instance_valid(dnode):
			_restore_single_door(did, dnode)


func _restore_single_door(did: String, door_node: Node) -> void:
	var gs := _gs()
	if not gs or not gs.door_states.has(did):
		return
	var st: Dictionary = gs.door_states[did]
	var want_open: bool = bool(st.get("open", false))
	var want_locked: bool = bool(st.get("locked", door_node.is_locked))
	door_node.is_locked = false
	door_node.set_open(want_open, false)
	if want_locked and not want_open:
		door_node.is_locked = true
		door_node.door_state = "CLOSED_LOCKED"
		if door_node.has_method("_update_prompt"):
			door_node._update_prompt()


func _on_door_state_changed(did: String, is_open: bool, is_locked: bool) -> void:
	var gs := _gs()
	if gs:
		gs.set_door_state(did, is_open, is_locked)


func get_door_count() -> int:
	return doors.size()
