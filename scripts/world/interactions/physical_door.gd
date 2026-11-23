class_name PhysicalDoor
extends Node3D

const InteractableNode = preload("res://scripts/world/interactable.gd")

signal door_state_changed(door_id: String, is_open: bool, is_locked: bool)

const STATE_CLOSED_UNLOCKED := "CLOSED_UNLOCKED"
const STATE_CLOSED_LOCKED := "CLOSED_LOCKED"
const STATE_OPEN := "OPEN"
const STATE_OPENING := "OPENING"
const STATE_CLOSING := "CLOSING"
const STATE_JAMMED := "JAMMED"

var door_id: String = ""
var door_kind: String = "interior"
var required_key_id: String = ""
var can_be_locked: bool = true
var door_state: String = STATE_CLOSED_UNLOCKED
var is_open: bool = false
var is_locked: bool = false
var is_slightly_ajar: bool = false
var swing_angle_deg: float = -88.0
var handle_depression_deg: float = 0.0

var frame_root: Node3D
var hinge_pivot: Node3D
var handle_pivot: Node3D
var latch_bolt: MeshInstance3D
var lock_cylinder: MeshInstance3D
var door_body: StaticBody3D
var door_col: CollisionShape3D
var interact_area: Area3D
var _tween: Tween = null
var _handle_tween: Tween = null


func _gs() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("GameState") if ml is SceneTree else null


func _au() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("AudioSynth") if ml is SceneTree else null


func setup_door(
	p_door_id: String,
	p_kind: String = "interior",
	p_pos: Vector3 = Vector3.ZERO,
	p_rot_deg_y: float = 0.0,
	p_swing_deg: float = -88.0,
	p_locked: bool = false,
	p_key_id: String = "",
	p_width: float = 1.05
) -> void:
	door_id = p_door_id
	door_kind = p_kind
	required_key_id = p_key_id
	is_locked = p_locked
	is_open = false
	door_state = STATE_CLOSED_LOCKED if is_locked else STATE_CLOSED_UNLOCKED
	swing_angle_deg = p_swing_deg
	position = p_pos
	rotation_degrees.y = p_rot_deg_y
	name = "PhysDoor_" + door_id

	# Stationary Door Frame (jambs + lintel) anchored around hinge X=0..p_width so leaf never floats or clips wall
	frame_root = Node3D.new()
	frame_root.name = "DoorFrame"
	add_child(frame_root)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.18, 0.16, 0.14) if p_kind in ["steel", "metal"] else Color(0.24, 0.17, 0.12)
	fmat.metallic = 0.55 if p_kind in ["steel", "metal"] else 0.05
	fmat.roughness = 0.62
	_add_frame_bar("JambHinge", Vector3(-0.035, 1.08, 0.0), Vector3(0.07, 2.16, 0.18), fmat)
	_add_frame_bar("JambLatch", Vector3(p_width + 0.035, 1.08, 0.0), Vector3(0.07, 2.16, 0.18), fmat)
	_add_frame_bar("LintelTop", Vector3(p_width * 0.5, 2.16, 0.0), Vector3(p_width + 0.14, 0.08, 0.18), fmat)

	# True Hinge Pivot at X = 0.0 (never rotates around mesh center!)
	hinge_pivot = Node3D.new()
	hinge_pivot.name = "HingePivot"
	add_child(hinge_pivot)

	var glb_path := "res://assets/models/door_hinged_panel.glb"
	if ResourceLoader.exists(glb_path):
		var sc: PackedScene = load(glb_path)
		if sc:
			var inst := sc.instantiate()
			if inst is Node3D:
				(inst as Node3D).scale = Vector3(p_width / 1.02, 1.0, 1.0)
				hinge_pivot.add_child(inst)
	else:
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(p_width, 2.12, 0.08)
		m.mesh = b
		m.position = Vector3(p_width * 0.5, 1.06, 0.0)
		hinge_pivot.add_child(m)

	# Articulated rotating lever handle + lock cylinder on BOTH sides of the door leaf
	handle_pivot = Node3D.new()
	handle_pivot.name = "HandlePivot"
	handle_pivot.position = Vector3(p_width * 0.88, 1.04, 0.0)
	hinge_pivot.add_child(handle_pivot)

	var h_mat := StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.70, 0.58, 0.28)
	h_mat.metallic = 0.85
	h_mat.roughness = 0.34
	for side_z: float in [-0.062, 0.062]:
		var lever := MeshInstance3D.new()
		var lbox := BoxMesh.new()
		lbox.size = Vector3(0.135, 0.024, 0.024)
		lbox.material = h_mat
		lever.mesh = lbox
		lever.position = Vector3(-0.055, 0.0, side_z)
		handle_pivot.add_child(lever)

	# Articulated Latch Bolt & Key Lock Cylinder (visibly retracts/turns on handle press & lock/unlock!)
	latch_bolt = MeshInstance3D.new()
	latch_bolt.name = "LatchBoltMesh"
	var lbm := BoxMesh.new()
	lbm.size = Vector3(0.045, 0.026, 0.024)
	lbm.material = h_mat
	latch_bolt.mesh = lbm
	latch_bolt.position = Vector3(p_width + 0.010, 1.04, 0.0)
	hinge_pivot.add_child(latch_bolt)

	lock_cylinder = MeshInstance3D.new()
	lock_cylinder.name = "LockCylinderMesh"
	var lcm := CylinderMesh.new()
	lcm.top_radius = 0.018
	lcm.bottom_radius = 0.018
	lcm.height = 0.11
	lcm.material = h_mat
	lock_cylinder.mesh = lcm
	lock_cylinder.position = Vector3(p_width * 0.88, 0.96, 0.0)
	lock_cylinder.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	hinge_pivot.add_child(lock_cylinder)

	# Solid Leaf Collider (Layer 1) swings cleanly with hinge_pivot
	door_body = StaticBody3D.new()
	door_body.name = "DoorLeafBody"
	door_body.collision_layer = 1
	door_body.collision_mask = 1
	door_col = CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(p_width, 2.12, 0.10)
	door_col.shape = sh
	door_col.position = Vector3(p_width * 0.5, 1.06, 0.0)
	door_body.add_child(door_col)
	hinge_pivot.add_child(door_body)

	# Tightly fitted Interaction Area on Layer 2 covering door leaf + handle from both sides without poking through adjacent walls
	interact_area = InteractableNode.new()
	interact_area.name = "DoorInt_" + door_id
	interact_area.interact_id = "physdoor_" + door_id
	interact_area.interact_type = "physical_door"
	interact_area.extra_data = {"door_node": self, "door_id": door_id}
	interact_area.position = Vector3(p_width * 0.5, 1.08, 0.0)
	var acol := CollisionShape3D.new()
	var abox := BoxShape3D.new()
	abox.size = Vector3(p_width + 0.08, 2.12, 0.34)
	acol.shape = abox
	interact_area.add_child(acol)
	hinge_pivot.add_child(interact_area)
	_update_prompt()


func _add_frame_bar(bar_name: String, loc: Vector3, sz: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = bar_name
	mi.position = loc
	var b := BoxMesh.new()
	b.size = sz
	b.material = mat
	mi.mesh = b
	frame_root.add_child(mi)


func get_door_state() -> String:
	return door_state


func set_jammed(jammed: bool) -> void:
	if jammed:
		is_open = false
		is_locked = true
		door_state = STATE_JAMMED
		if hinge_pivot:
			hinge_pivot.rotation_degrees.y = 0.0
	else:
		door_state = STATE_CLOSED_LOCKED if is_locked else (STATE_OPEN if is_open else STATE_CLOSED_UNLOCKED)
	_update_prompt()
	emit_signal("door_state_changed", door_id, is_open, is_locked)


func _update_prompt() -> void:
	if interact_area == null:
		return
	var gs := _gs()
	match door_state:
		STATE_JAMMED:
			interact_area.prompt_text = "[E] JAMMED DOOR"
		STATE_CLOSED_LOCKED:
			if required_key_id.is_empty():
				interact_area.prompt_text = "[E] UNLOCK  |  [L] UNLOCK"
			else:
				var kname: String = required_key_id.replace("key_", "").replace("_", " ").to_upper()
				if gs and gs.has_key(required_key_id):
					interact_area.prompt_text = "[E] UNLOCK (%s KEY)" % kname
				else:
					interact_area.prompt_text = "[E] LOCKED — NEEDS %s KEY" % kname
		STATE_OPEN, STATE_OPENING:
			interact_area.prompt_text = "[E] CLOSE  |  [L] LOCK" if can_be_locked else "[E] CLOSE"
		STATE_CLOSING:
			interact_area.prompt_text = "[E] OPEN"
		_:
			if is_slightly_ajar:
				interact_area.prompt_text = "[E] OPEN"
			else:
				interact_area.prompt_text = "[E] OPEN  |  [L] LOCK" if can_be_locked else "[E] OPEN"


func animate_handle_depress(depress_deg: float = -34.0) -> void:
	handle_depression_deg = depress_deg
	if not handle_pivot:
		return
	if is_inside_tree():
		if _handle_tween and _handle_tween.is_running():
			_handle_tween.kill()
		_handle_tween = create_tween()
		_handle_tween.tween_property(handle_pivot, "rotation_degrees:z", depress_deg, 0.10)
		_handle_tween.tween_property(handle_pivot, "rotation_degrees:z", 0.0, 0.16)
		if latch_bolt and absf(depress_deg) > 16.0:
			var bx: float = latch_bolt.position.x
			var ltw := create_tween()
			ltw.tween_property(latch_bolt, "position:x", bx - 0.026, 0.09)
			ltw.tween_property(latch_bolt, "position:x", bx, 0.16)
	else:
		handle_pivot.rotation_degrees.z = depress_deg


func animate_lock_cylinder(locking: bool) -> void:
	if not lock_cylinder:
		return
	var target_z: float = 90.0 if locking else 0.0
	if is_inside_tree():
		var tw := create_tween()
		tw.tween_property(lock_cylinder, "rotation_degrees:z", target_z, 0.18)
	else:
		lock_cylinder.rotation_degrees.z = target_z


func jiggle_locked_handle() -> void:
	var au := _au()
	if au:
		au.play_sfx("handle_jiggle", -5.5, randf_range(0.95, 1.05))
	# Locked handle cannot turn fully — stops at -12 degrees
	animate_handle_depress(-12.0)


func try_unlock_with_key(key_id: String) -> Dictionary:
	var gs := _gs()
	var au := _au()
	if door_state == STATE_JAMMED:
		jiggle_locked_handle()
		return {"ok": false, "msg": "Door frame is swollen and jammed shut."}
	if not is_locked:
		return {"ok": true, "msg": "Door is already unlocked."}
	if not required_key_id.is_empty() and key_id != required_key_id:
		jiggle_locked_handle()
		return {"ok": false, "msg": "Wrong key — does not turn in this lock."}
	is_locked = false
	door_state = STATE_CLOSED_UNLOCKED
	animate_lock_cylinder(false)
	if au:
		au.play_sfx("keys_jingle", -4.5, 1.0)
	if gs:
		gs.unlock_door_record(door_id)
	_update_prompt()
	emit_signal("door_state_changed", door_id, is_open, is_locked)
	return {"ok": true, "msg": "Door unlocked."}


func toggle_lock() -> Dictionary:
	if not can_be_locked or door_state == STATE_JAMMED:
		jiggle_locked_handle()
		return {"ok": false, "msg": "This door lock cannot be engaged."}
	var gs := _gs()
	var au := _au()
	if is_locked:
		if not required_key_id.is_empty():
			if gs and gs.has_key(required_key_id):
				return try_unlock_with_key(required_key_id)
			jiggle_locked_handle()
			return {"ok": false, "msg": "Locked — requires %s key." % required_key_id.replace("key_", "").to_upper()}
		is_locked = false
		door_state = STATE_CLOSED_UNLOCKED
		if au:
			au.play_sfx("keys_jingle", -5.0, 1.04)
		_update_prompt()
		emit_signal("door_state_changed", door_id, is_open, is_locked)
		return {"ok": true, "msg": "Door unlocked."}
	else:
		# Lock door (if currently open, smoothly close & lock it!)
		if is_open or door_state == STATE_OPENING:
			set_open(false, true)
		is_locked = true
		is_slightly_ajar = false
		door_state = STATE_CLOSED_LOCKED
		if au:
			au.play_sfx("keys_jingle", -5.0, 0.92)
			au.play_sfx("door_seal", -6.0, 0.95)
		_update_prompt()
		emit_signal("door_state_changed", door_id, is_open, is_locked)
		return {"ok": true, "msg": "Door locked."}


func set_slightly_ajar(ajar_angle_deg: float = -14.0, play_sound: bool = true) -> void:
	if door_state == STATE_JAMMED:
		return
	is_open = false
	is_slightly_ajar = true
	is_locked = false
	door_state = STATE_CLOSED_UNLOCKED
	animate_handle_depress(-28.0)
	var au := _au()
	if play_sound and au:
		au.play_sfx("door_handle", -6.0, 0.92)
	if hinge_pivot:
		if is_inside_tree():
			if _tween and _tween.is_running():
				_tween.kill()
			_tween = create_tween()
			_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_tween.tween_property(hinge_pivot, "rotation_degrees:y", ajar_angle_deg, 0.65)
		else:
			hinge_pivot.rotation_degrees.y = ajar_angle_deg
	_update_prompt()
	emit_signal("door_state_changed", door_id, is_open, is_locked)


func set_manual_bolt_locked(locked: bool) -> void:
	is_locked = locked
	if is_locked:
		if is_open or is_slightly_ajar:
			set_open(false, true)
		door_state = STATE_CLOSED_LOCKED
	else:
		door_state = STATE_OPEN if is_open else STATE_CLOSED_UNLOCKED
	var au := _au()
	if au:
		au.play_sfx("door_seal" if locked else "door_handle", -5.5, 0.95)
	_update_prompt()
	emit_signal("door_state_changed", door_id, is_open, is_locked)


func interact_toggle() -> Dictionary:
	var gs := _gs()
	var au := _au()
	if door_state == STATE_JAMMED:
		jiggle_locked_handle()
		return {"ok": false, "msg": "Door is jammed shut."}
	if door_state == STATE_OPENING or door_state == STATE_CLOSING:
		# Smooth reversal without teleporting
		set_open(door_state == STATE_CLOSING, true)
		return {"ok": true, "msg": ""}
	if is_locked:
		if required_key_id.is_empty():
			is_locked = false
			door_state = STATE_CLOSED_UNLOCKED
			animate_handle_depress(-34.0)
			if au:
				au.play_sfx("door_handle", -5.0, 1.0)
			set_open(true, true)
			return {"ok": true, "msg": "Unlocked and opened door."}
		if gs and gs.has_key(required_key_id):
			var ures: Dictionary = try_unlock_with_key(required_key_id)
			if bool(ures.get("ok", false)):
				animate_handle_depress(-34.0)
				set_open(true, true)
				return {"ok": true, "msg": "Unlocked door with %s key." % required_key_id.replace("key_", "").to_upper()}
		jiggle_locked_handle()
		return {"ok": false, "msg": "Door is locked — needs %s key." % required_key_id.replace("key_", "").to_upper()}

	animate_handle_depress(-34.0)
	if au:
		au.play_sfx("door_handle", -5.5, 1.0 if not is_open else 0.92)
	set_open(not is_open, true)
	return {"ok": true, "msg": ""}


func set_open(open_state: bool, animate: bool = true) -> void:
	if door_state == STATE_JAMMED:
		return
	if open_state and is_locked:
		jiggle_locked_handle()
		return
	is_open = open_state
	is_slightly_ajar = false
	var au := _au()
	var target_y: float = swing_angle_deg if is_open else 0.0
	var swing_dur: float = 0.65 if is_open else 0.74
	if door_kind in ["steel", "metal"]:
		swing_dur += 0.12
	if animate and is_inside_tree():
		door_state = STATE_OPENING if is_open else STATE_CLOSING
		if _tween and _tween.is_running():
			_tween.kill()
		_tween = create_tween()
		_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT if is_open else Tween.EASE_IN_OUT)
		_tween.tween_property(hinge_pivot, "rotation_degrees:y", target_y, swing_dur)
		_tween.tween_callback(func():
			if not is_locked:
				door_state = STATE_OPEN if is_open else STATE_CLOSED_UNLOCKED
			else:
				door_state = STATE_CLOSED_LOCKED
			if not is_open:
				var au_end := _au()
				if au_end:
					au_end.play_sfx("door_seal", -6.5, 0.96)
			_update_prompt()
		)
		if au:
			au.play_sfx("door_creak" if door_kind != "metal" else "door_heavy", -6.0, 1.0 if is_open else 0.88)
	elif hinge_pivot:
		hinge_pivot.rotation_degrees.y = target_y
		door_state = STATE_OPEN if is_open else (STATE_CLOSED_LOCKED if is_locked else STATE_CLOSED_UNLOCKED)
	_update_prompt()
	emit_signal("door_state_changed", door_id, is_open, is_locked)
