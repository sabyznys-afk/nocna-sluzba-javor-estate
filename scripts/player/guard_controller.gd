class_name GuardController
extends CharacterBody3D

const InteractableNode = preload("res://scripts/world/interactable.gd")
const GuardViewmodelScript = preload("res://scripts/player/guard_viewmodel.gd")
const StaminaManagerScript = preload("res://scripts/player/player_stamina_manager.gd")
const SanityManagerScript = preload("res://scripts/systems/player_sanity_manager.gd")
const HeadphoneManagerScript = preload("res://scripts/systems/headphone_manager.gd")
const EquipmentManagerScript = preload("res://scripts/player/player_equipment_manager.gd")
const FirstPersonBodyScript = preload("res://scripts/player/first_person_body.gd")

signal interactable_focused(interactable: Area3D)
signal interactable_triggered(interactable: Area3D)
signal bunker_zone_changed(inside_bunker: bool)
signal taser_fired(hit_pos: Vector3, hit_collider: Object)
signal gear_switched(slot: String)
signal headphones_changed(wearing: bool)
signal sanity_updated(val: float, stage: String)
signal stamina_updated(val: float, exhausted: bool)
signal equipment_action_note(text: String)
signal flashlight_toggled(is_on: bool)
signal radio_used
signal door_lock_toggled(door_id: String, is_locked: bool)

const WALK_SPEED: float = 1.75
const FAST_WALK_SPEED: float = 2.40
const SPRINT_SPEED: float = 4.20
const CROUCH_SPEED: float = 1.20
const GRAVITY: float = 18.0
const MOUSE_SENS: float = 0.0024

var camera: Camera3D
var head_pivot: Node3D
var flashlight_spot: SpotLight3D
var flashlight_spill: OmniLight3D
var interact_ray: RayCast3D
var taser_ray: RayCast3D
var viewmodel: Node3D
var fp_body: Node3D
var surface_lookup_cb: Callable = Callable()

var stamina_mgr: PlayerStaminaManager
var sanity_mgr: PlayerSanityManager
var headphone_mgr: HeadphoneManager
var equipment_mgr: PlayerEquipmentManager

var flashlight_on: bool = true
var input_locked: bool = false
var is_in_bunker: bool = false

var _pitch: float = 0.0
var _step_timer: float = 0.0
var _bob_phase: float = 0.0
var _taser_cooldown: float = 0.0
var _current_focus: Area3D = null
var _sprint_toggled: bool = false


func _ready() -> void:
	floor_max_angle = deg_to_rad(52.0)
	_build_player_rig()
	_init_managers()
	var sett := get_node_or_null("/root/SettingsManager")
	if sett and sett.has_signal("settings_changed"):
		sett.settings_changed.connect(_apply_player_settings)
	_apply_player_settings()
	capture_mouse(true)


func _apply_player_settings() -> void:
	var sett := get_node_or_null("/root/SettingsManager")
	if not sett:
		return
	if camera:
		camera.fov = clampf(float(sett.get_val("fov", 72.0)), 65.0, 95.0)
		camera.far = clampf(float(sett.get_val("view_distance", 220.0)), 120.0, 280.0)
	if flashlight_spot:
		var fl_mult: float = clampf(float(sett.get_val("flashlight_intensity", 1.0)), 0.5, 1.8)
		var sh_ok: bool = bool(sett.get_val("shadows", true)) and str(sett.get_val("ps1_shadow_quality", "blocky")) != "off"
		flashlight_spot.shadow_enabled = sh_ok
		flashlight_spot.shadow_blur = 0.24 if str(sett.get_val("ps1_shadow_quality", "blocky")) == "blocky" else 0.70
		flashlight_spot.light_energy = 4.6 * fl_mult
		if flashlight_spill:
			flashlight_spill.light_energy = 0.34 * fl_mult


func _init_managers() -> void:
	stamina_mgr = StaminaManagerScript.new()
	stamina_mgr.name = "PlayerStaminaManager"
	add_child(stamina_mgr)
	stamina_mgr.stamina_changed.connect(func(v: float, ex: bool): emit_signal("stamina_updated", v, ex))

	sanity_mgr = SanityManagerScript.new()
	sanity_mgr.name = "PlayerSanityManager"
	add_child(sanity_mgr)
	sanity_mgr.set_sanity(GameState.sanity)
	sanity_mgr.sanity_changed.connect(func(v: float, st: String): emit_signal("sanity_updated", v, st))

	headphone_mgr = HeadphoneManagerScript.new()
	headphone_mgr.name = "HeadphoneManager"
	add_child(headphone_mgr)
	headphone_mgr.headphones_toggled.connect(func(w: bool): emit_signal("headphones_changed", w))
	if GameState.headphones_on:
		headphone_mgr.set_headphones(true, false)

	equipment_mgr = EquipmentManagerScript.new()
	equipment_mgr.name = "PlayerEquipmentManager"
	add_child(equipment_mgr)


func _build_player_rig() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.72
	col.shape = cap
	col.position = Vector3(0.0, 0.86, 0.0)
	add_child(col)

	head_pivot = Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 1.56, 0.0)
	add_child(head_pivot)

	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.fov = 72.0
	camera.near = 0.06
	camera.far = 260.0
	head_pivot.add_child(camera)

	viewmodel = GuardViewmodelScript.new()
	camera.add_child(viewmodel)

	flashlight_spot = SpotLight3D.new()
	flashlight_spot.name = "HalogenFlashlight"
	flashlight_spot.position = Vector3(0.14, -0.10, -0.52)
	flashlight_spot.light_color = Color(1.0, 0.93, 0.78)
	flashlight_spot.light_energy = 4.6
	flashlight_spot.spot_range = 24.0
	flashlight_spot.spot_attenuation = 1.05
	flashlight_spot.spot_angle = 36.0
	flashlight_spot.spot_angle_attenuation = 1.45
	flashlight_spot.shadow_enabled = true
	flashlight_spot.shadow_blur = 0.24
	flashlight_spot.shadow_bias = 0.04
	head_pivot.add_child(flashlight_spot)

	flashlight_spill = OmniLight3D.new()
	flashlight_spill.name = "FlashlightSpill"
	flashlight_spill.position = Vector3(0.08, -0.08, -0.78)
	flashlight_spill.light_color = Color(1.0, 0.90, 0.72)
	flashlight_spill.light_energy = 0.34
	flashlight_spill.omni_range = 4.6
	flashlight_spill.omni_attenuation = 1.5
	flashlight_spill.shadow_enabled = false
	head_pivot.add_child(flashlight_spill)

	interact_ray = RayCast3D.new()
	interact_ray.name = "InteractRay"
	interact_ray.target_position = Vector3(0.0, 0.0, -3.1)
	interact_ray.collision_mask = 2
	interact_ray.collide_with_areas = true
	interact_ray.collide_with_bodies = false
	camera.add_child(interact_ray)

	taser_ray = RayCast3D.new()
	taser_ray.name = "TaserRay"
	taser_ray.target_position = Vector3(0.0, 0.0, -6.5)
	taser_ray.collide_with_areas = true
	taser_ray.collide_with_bodies = true
	camera.add_child(taser_ray)

	fp_body = FirstPersonBodyScript.new()
	add_child(fp_body)


func capture_mouse(captured: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


func set_input_locked(locked: bool) -> void:
	input_locked = locked
	capture_mouse(not locked)
	if locked:
		velocity = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm: InputEventMouseMotion = event
		var sett := get_node_or_null("/root/SettingsManager")
		var sens_mult: float = float(sett.get_val("mouse_sensitivity", 1.0)) if sett else 1.0
		var inv_y: float = -1.0 if (sett and bool(sett.get_val("invert_y", false))) else 1.0
		var dyaw: float = -mm.relative.x * MOUSE_SENS * sens_mult
		var dpitch: float = -mm.relative.y * MOUSE_SENS * sens_mult * inv_y
		rotate_y(dyaw)
		_pitch = clampf(_pitch + dpitch, deg_to_rad(-78.0), deg_to_rad(78.0))
		head_pivot.rotation.x = _pitch
		if viewmodel and viewmodel.has_method("update_look_sway"):
			viewmodel.update_look_sway(dyaw, dpitch)

	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cycle_hotbar_slot(1)
			return
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			cycle_hotbar_slot(-1)
			return

	if event is InputEventKey and event.pressed and not event.echo:
		var ke: InputEventKey = event
		if ke.keycode == KEY_0 or ke.keycode == KEY_QUOTELEFT:
			switch_gear("hands")
			return
		elif ke.keycode == KEY_6:
			switch_gear("notebook")
			return

	if event.is_action_pressed("sprint"):
		var sett_s := get_node_or_null("/root/SettingsManager")
		if sett_s and bool(sett_s.get_val("toggle_sprint", false)):
			_sprint_toggled = not _sprint_toggled

	if event.is_action_pressed("flashlight"):
		toggle_flashlight()
	elif event.is_action_pressed("reload_battery"):
		swap_battery()
	elif event.is_action_pressed("toggle_headphones"):
		toggle_headphones()
	elif event.is_action_pressed("equip_flashlight"):
		switch_gear("flashlight")
	elif event.is_action_pressed("equip_taser"):
		switch_gear("taser")
	elif event.is_action_pressed("equip_keys"):
		switch_gear("keys")
	elif event.is_action_pressed("equip_radio"):
		switch_gear("radio")
	elif event.is_action_pressed("equip_watch"):
		switch_gear("watch")
	elif event.is_action_pressed("quick_switch"):
		cycle_hotbar_slot(1, true)
	elif event.is_action_pressed("fire_taser"):
		match GameState.equipped_slot:
			"taser":
				fire_taser()
			"keys":
				use_keys()
			"radio":
				use_radio()
			"watch":
				check_watch()
	elif event.is_action_pressed("lock_door") and _current_focus != null:
		_try_lock_focused_door()
	elif event.is_action_pressed("interact") and _current_focus != null:
		if viewmodel and viewmodel.has_method("play_interact_door"):
			viewmodel.play_interact_door()
		_current_focus.trigger_interact()
		emit_signal("interactable_triggered", _current_focus)
		emit_signal("interactable_focused", _current_focus)


func _try_lock_focused_door() -> void:
	if _current_focus == null or _current_focus.interact_type != "physical_door":
		return
	var dnode: Variant = _current_focus.extra_data.get("door_node", null)
	if dnode != null and is_instance_valid(dnode) and dnode.has_method("toggle_lock"):
		if viewmodel and viewmodel.has_method("play_keys_unlock"):
			viewmodel.play_keys_unlock()
		elif viewmodel:
			viewmodel.play_keys_inspect()
		var res: Dictionary = dnode.toggle_lock()
		if bool(res.get("ok", false)):
			emit_signal("door_lock_toggled", str(dnode.get("door_id")), bool(dnode.get("is_locked")))
		var msg: String = str(res.get("msg", ""))
		if not msg.is_empty():
			emit_signal("equipment_action_note", msg)
		emit_signal("interactable_focused", _current_focus)


func cycle_hotbar_slot(direction: int, ignore_cooldown: bool = false) -> String:
	if not equipment_mgr:
		return GameState.equipped_slot
	var prev_slot: String = GameState.equipped_slot
	var next_slot: String = equipment_mgr.cycle_slot(direction, ignore_cooldown)
	if next_slot != prev_slot:
		AudioSynth.play_ui_sfx("hotbar_scroll", -6.5)
		_apply_switched_gear(next_slot, false)
	return next_slot


func switch_gear(slot: String) -> void:
	var valid := ["hands", "flashlight", "taser", "keys", "radio", "watch", "notebook"]
	var target_slot: String = slot if (slot in valid) else "flashlight"
	if GameState.equipped_slot == target_slot:
		return
	if equipment_mgr:
		equipment_mgr.equip_slot(target_slot)
	else:
		GameState.equipped_slot = target_slot
	_apply_switched_gear(target_slot, true)


func _apply_switched_gear(target_slot: String, play_equip_sfx: bool = true) -> void:
	if viewmodel:
		viewmodel.set_equipped_slot(target_slot)
	_sync_flashlight_beam()
	if play_equip_sfx:
		match target_slot:
			"hands":
				AudioSynth.play_ui_sfx("hotbar_scroll", -6.0)
			"taser":
				AudioSynth.play_sfx("taser_equip", -6.0, 1.0)
			"keys":
				AudioSynth.play_sfx("keys_jingle", -6.0, 1.0)
			"radio":
				AudioSynth.play_sfx("radio_squelch", -7.0, 1.0)
			"watch":
				AudioSynth.play_sfx("watch_tick", -6.0, 1.0)
			"notebook":
				AudioSynth.play_sfx("notebook_open", -6.0, 1.0)
			_:
				AudioSynth.play_sfx("flashlight", -6.0, 1.0)
	GameState.emit_signal("state_changed")
	emit_signal("gear_switched", target_slot)


func _sync_flashlight_beam() -> void:
	var beam_active: bool = flashlight_on and (GameState.equipped_slot == "flashlight") and GameState.flashlight_battery > 0.0
	if flashlight_spot:
		flashlight_spot.visible = beam_active
	if flashlight_spill:
		flashlight_spill.visible = beam_active
	if equipment_mgr:
		equipment_mgr.sync_flashlight_state(flashlight_on)


func get_flashlight_illuminated_object() -> String:
	if not flashlight_on or GameState.equipped_slot != "flashlight" or not camera:
		return ""
	var space := get_world_3d().direct_space_state
	if not space:
		return ""
	var origin: Vector3 = camera.global_position
	var target: Vector3 = origin + (-camera.global_transform.basis.z * 11.0)
	var qp := PhysicsRayQueryParameters3D.create(origin, target, 1)
	qp.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(qp)
	if not hit.is_empty():
		var col_obj: Object = hit.get("collider", null)
		if col_obj is Node:
			return str((col_obj as Node).name)
	return ""


func toggle_headphones() -> bool:
	if not headphone_mgr:
		return false
	var now_wearing: bool = headphone_mgr.toggle_headphones()
	if viewmodel:
		viewmodel.play_headphones_toggle(now_wearing)
	if equipment_mgr:
		equipment_mgr.begin_action("headphones_toggle", 0.45)
	return now_wearing


func use_keys() -> void:
	if viewmodel:
		viewmodel.play_keys_inspect()
	if _current_focus != null and _current_focus.interact_type == "physical_door":
		_try_lock_focused_door()
		return
	AudioSynth.play_sfx("keys_jingle", -5.0)
	var kcount := GameState.collected_keys.size()
	var msg := "Keyring checked (%d key%s collected)." % [kcount, "" if kcount == 1 else "s"] if kcount > 0 else "Standard master ring held — look at a door and press [L] or [LMB] to lock/unlock."
	emit_signal("equipment_action_note", msg)


func use_radio() -> void:
	if viewmodel:
		viewmodel.play_radio_use()
	AudioSynth.play_sfx("radio_squelch", -4.5)
	emit_signal("radio_used")
	emit_signal("equipment_action_note", "VHF Channel 04 (50.4 Hz) — dispatch status checked.")


func check_watch() -> void:
	if viewmodel:
		viewmodel.play_watch_check()
	AudioSynth.play_sfx("watch_tick", -4.5)
	emit_signal("equipment_action_note", "SHIFT WATCH: %s" % GameState.get_formatted_vhs_time())


func fire_taser() -> bool:
	if _taser_cooldown > 0.0:
		return false
	if not GameState.consume_taser_charge(25.0):
		AudioSynth.play_sfx("flashlight", -8.0, 0.55)
		return false
	_taser_cooldown = 0.65
	if viewmodel:
		viewmodel.play_taser_fire()
	AudioSynth.play_sfx("taser_zap", -3.0, randf_range(0.95, 1.05))
	taser_ray.force_raycast_update()
	var hit_col: Object = taser_ray.get_collider() if taser_ray.is_colliding() else null
	var hit_pos: Vector3 = taser_ray.get_collision_point() if taser_ray.is_colliding() else (camera.global_position + (-camera.global_transform.basis.z * 5.0))
	emit_signal("taser_fired", hit_pos, hit_col)
	return true


func toggle_flashlight() -> void:
	if GameState.flashlight_battery <= 0.1 and not flashlight_on:
		AudioSynth.play_sfx("flashlight", -8.0, 0.7)
		return
	if GameState.equipped_slot != "flashlight":
		switch_gear("flashlight")
	flashlight_on = not flashlight_on
	_sync_flashlight_beam()
	if viewmodel:
		viewmodel.play_flashlight_toggle()
	AudioSynth.play_sfx("flashlight", -6.0, 1.0 if flashlight_on else 0.85)
	emit_signal("flashlight_toggled", flashlight_on)
	GameState.emit_signal("state_changed")


func swap_battery() -> bool:
	if not GameState.reload_gear_battery():
		return false
	flashlight_on = true
	_sync_flashlight_beam()
	if viewmodel:
		viewmodel.play_battery_reload()
	AudioSynth.play_sfx("battery_swap", -4.5, 1.0)
	return true


func _physics_process(delta: float) -> void:
	_taser_cooldown = maxf(0.0, _taser_cooldown - delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var in_safe: bool = (position.x >= -23.0 and position.x <= -13.0 and position.z >= -60.5 and position.z <= -51.5 and position.y >= -1.0)
	var near_threat: bool = (GameState.signal_distortion > 35.0 or position.y < -1.5 or position.z > 46.0)
	var hp_on: bool = headphone_mgr.headphones_on if headphone_mgr else false

	if AudioSynth.env_manager:
		AudioSynth.env_manager.update_headphone_mix(hp_on, delta)

	if input_locked:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if stamina_mgr:
			stamina_mgr.update_stamina(delta, false, false, hp_on, sanity_mgr.sanity if sanity_mgr else 100.0)
		if viewmodel:
			viewmodel.update_locomotion(delta, 0.0, false, false, false, stamina_mgr.is_exhausted if stamina_mgr else false, flashlight_on)
		return

	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_dir: Vector3 = (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
	var moving: bool = move_dir.length_squared() > 0.001

	var sett := get_node_or_null("/root/SettingsManager")
	var ctrl_sens: float = float(sett.get_val("controller_sensitivity", 1.0)) if sett else 1.0
	var inv_y: float = -1.0 if (sett and bool(sett.get_val("invert_y", false))) else 1.0
	var joy_rx: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var joy_ry: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(joy_rx) > 0.18:
		rotate_y(-joy_rx * 2.2 * ctrl_sens * delta)
	if absf(joy_ry) > 0.18:
		_pitch = clampf(_pitch - joy_ry * 1.8 * ctrl_sens * inv_y * delta, deg_to_rad(-78.0), deg_to_rad(78.0))
		head_pivot.rotation.x = _pitch

	var crouching: bool = Input.is_action_pressed("crouch")
	if not moving or crouching:
		_sprint_toggled = false
	var use_toggle_sprint: bool = bool(sett.get_val("toggle_sprint", false)) if sett else false
	var want_sprint: bool = (_sprint_toggled if use_toggle_sprint else Input.is_action_pressed("sprint")) and not crouching and moving
	var can_sprint: bool = stamina_mgr.can_sprint() if stamina_mgr else true
	var sprinting: bool = want_sprint and can_sprint
	var fast_walking: bool = Input.is_action_pressed("fast_walk") and not crouching and not sprinting and moving

	var bob_mult: float = float(sett.get_val("head_bob", 1.0)) if sett else 1.0
	if sett and bool(sett.get_val("reduce_shake", false)):
		bob_mult *= 0.25

	if stamina_mgr:
		stamina_mgr.update_stamina(delta, sprinting, moving, hp_on, sanity_mgr.sanity if sanity_mgr else 100.0)
	if sanity_mgr:
		sanity_mgr.update_sanity(delta, in_safe, flashlight_on, hp_on, near_threat)
	if headphone_mgr:
		headphone_mgr.update_threat(delta, in_safe, near_threat, self)

	var speed: float = CROUCH_SPEED if crouching else (SPRINT_SPEED if sprinting else (FAST_WALK_SPEED if fast_walking else WALK_SPEED))
	if stamina_mgr and stamina_mgr.is_exhausted and not crouching:
		speed = minf(speed, WALK_SPEED * 0.78)

	var target_eye_y: float = 1.05 if crouching else 1.56
	head_pivot.position.y = lerpf(head_pivot.position.y, target_eye_y, delta * 9.0)

	var horiz_speed: float = 0.0
	if moving:
		velocity.x = move_toward(velocity.x, move_dir.x * speed, delta * 18.0)
		velocity.z = move_toward(velocity.z, move_dir.z * speed, delta * 18.0)
		horiz_speed = Vector2(velocity.x, velocity.z).length() / WALK_SPEED
		var bob_rate: float = 10.5 if sprinting else (8.4 if fast_walking else 6.2)
		_bob_phase += delta * bob_rate
		camera.position.y = sin(_bob_phase) * (0.034 if sprinting else 0.024) * bob_mult
		camera.rotation.z = lerpf(camera.rotation.z, -input_vec.x * (0.018 if sprinting else 0.009) * bob_mult, delta * 7.5)
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.34 if sprinting else (0.42 if fast_walking else (0.64 if crouching else 0.50))
			var surf: String = "cobble"
			if surface_lookup_cb.is_valid():
				surf = str(surface_lookup_cb.call(position))
			else:
				surf = "wood" if position.y > 2.8 else ("metal" if position.y < -1.5 else "cobble")
			AudioSynth.play_footstep(surf, crouching, sprinting)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 9.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 9.0)
		camera.position.y = lerpf(camera.position.y, 0.0, delta * 6.0)
		camera.rotation.z = lerpf(camera.rotation.z, 0.0, delta * 7.5)

	move_and_slide()
	if viewmodel:
		viewmodel.update_locomotion(delta, horiz_speed, sprinting, fast_walking, crouching, stamina_mgr.is_exhausted if stamina_mgr else false, flashlight_on)
	if fp_body and fp_body.has_method("update_body"):
		fp_body.update_body(delta, horiz_speed, sprinting, fast_walking, crouching, rotation.y, _pitch)

	var active_beam: bool = flashlight_on and (GameState.equipped_slot == "flashlight")
	var fl_mult: float = clampf(float(sett.get_val("flashlight_intensity", 1.0)), 0.5, 1.8) if sett else 1.0
	if flashlight_spot:
		flashlight_spot.visible = active_beam and GameState.flashlight_battery > 0.0
		if flashlight_spill:
			flashlight_spill.visible = flashlight_spot.visible
		if viewmodel and viewmodel.get("flashlight_pivot") != null:
			var fpiv: Node3D = viewmodel.get("flashlight_pivot")
			flashlight_spot.rotation = fpiv.rotation * 0.45

	if active_beam:
		var drain_rate: float = 1.05 if GameState.hardcore_mode else 0.52
		GameState.flashlight_battery = maxf(0.0, GameState.flashlight_battery - drain_rate * delta)
		if GameState.flashlight_battery <= 0.0:
			flashlight_on = false
			_sync_flashlight_beam()
		else:
			var dist_norm: float = clampf(GameState.signal_distortion / 100.0, 0.0, 1.0)
			var flicker: float = 1.0 - (dist_norm * 0.25 * maxf(0.0, sin(Time.get_ticks_msec() * 0.025)))
			flashlight_spot.light_energy = 4.6 * fl_mult * flicker
			if flashlight_spill:
				flashlight_spill.light_energy = 0.34 * fl_mult * flicker

	# Detect Bunker K-4 monochrome zone (west of Red Bulkhead Door at X=-76.0, Y < -2.2)
	var now_bunker: bool = (position.y < -2.2 and position.x < -71.0)
	if now_bunker != is_in_bunker:
		is_in_bunker = now_bunker
		emit_signal("bunker_zone_changed", is_in_bunker)

	interact_ray.force_raycast_update()
	var new_focus: Area3D = null
	if interact_ray.is_colliding():
		var col: Object = interact_ray.get_collider()
		if col is InteractableNode:
			var hit_pt: Vector3 = interact_ray.get_collision_point()
			if not _is_focus_occluded_by_wall(col as Area3D, hit_pt):
				new_focus = col as Area3D

	if new_focus != _current_focus:
		_current_focus = new_focus
		emit_signal("interactable_focused", _current_focus)


func _is_focus_occluded_by_wall(target_area: Area3D, hit_pt: Vector3) -> bool:
	if not camera or not is_inside_tree():
		return false
	var space := get_world_3d().direct_space_state
	if not space:
		return false
	var origin: Vector3 = camera.global_position
	var to_target: Vector3 = hit_pt - origin
	var target_dist: float = to_target.length()
	if target_dist <= 0.15:
		return false
	var exclude: Array[RID] = [get_rid()]
	if target_area.interact_type == "physical_door":
		var dnode: Variant = target_area.extra_data.get("door_node", null)
		if dnode != null and is_instance_valid(dnode) and dnode.get("door_body") is CollisionObject3D:
			exclude.append((dnode.get("door_body") as CollisionObject3D).get_rid())
	var q := PhysicsRayQueryParameters3D.create(origin, hit_pt, 1, exclude)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		return false
	var wall_dist: float = origin.distance_to(hit["position"])
	var margin: float = 0.18 if target_area.interact_type == "physical_door" else 0.42
	return wall_dist < (target_dist - margin)
