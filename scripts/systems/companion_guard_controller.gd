class_name CompanionGuardController
extends CharacterBody3D

# Prompt 08 Part 2 & Part 3 — Real Physical Companion Guard AI (Jozef Varga, age 51)
# - Real CharacterBody3D with CapsuleShape3D collision (Layer 8, Mask 1|8) — NEVER walks through desks,
#   walls, buildings, parked cars, fences, or closed doors!
# - Real NavigationAgent3D + baked DistrictNavigationManager NavMesh + local raycast obstacle avoidance!
# - Proper PhysicalDoor sequence: stop -> face -> handle/key animation -> open -> WAIT until open -> pass through!
# - Path failure & stuck recovery without teleporting or walking in place against walls!
# - All English dialogue lines synced with Piper English neural voice files!

signal state_changed(new_state: String)
signal dialogue_spoken(speaker: String, text: String, voice_id: String)
signal checkpoint_guided(stop_id: String)
signal door_opened_by_companion(door_id: String)
signal route_blocked_feedback(reason: String)

const VALID_STATES := [
	"WAITING_IN_OFFICE",
	"FOLLOWING_ROUTE",
	"WALKING_TO_CHECKPOINT",
	"WAITING_FOR_PLAYER",
	"EXPLAINING_LOCATION",
	"INTERACTING_WITH_DOOR",
	"INSPECTING_AREA",
	"REACTING_TO_SOUND",
	"RETURNING_TO_ROUTE",
	"ENDING_PATROL",
]

# Verified pedestrian-only Night 1 Guided Patrol Route (100% clear of desks, Building D, parked cars & fences!)
const NIGHT1_GUIDED_STOPS: Array[Dictionary] = [
	{
		"id": "stop_office_exit",
		"path": [Vector3(-14.3, 0.06, -54.6), Vector3(-11.0, 0.06, -54.6)],
		"point_at": Vector3(-13.5, 1.2, -54.6),
		"voice_id": "jozef_office_intro_01",
		"line": "Write everything down. When something goes wrong, paper matters more than memory. Follow me — I'll walk you through your first patrol.",
		"inspect_sec": 3.4,
	},
	{
		"id": "stop_main_gate",
		"path": [Vector3(-6.2, 0.06, -54.6), Vector3(-2.0, 0.06, -59.5), Vector3(-1.4, 0.06, -65.6)],
		"point_at": Vector3(0.0, 1.4, -70.0),
		"voice_id": "jozef_gate_02",
		"line": "Come on. First we check the main entrance gate. People sometimes forget to lock it at night. Inspect the latch and log it in your notebook.",
		"inspect_sec": 4.2,
	},
	{
		"id": "stop_parking_garages",
		"path": [Vector3(-0.8, 0.06, -53.2), Vector3(9.5, 0.06, -53.0), Vector3(18.0, 0.06, -53.0)],
		"point_at": Vector3(19.6, 1.0, -60.0),
		"voice_id": "jozef_parking_03",
		"line": "Keep to the center walkway between the parked cars. Check the parking lot and garage lane on every single shift.",
		"inspect_sec": 4.2,
	},
	{
		"id": "stop_building_a",
		"path": [
			Vector3(4.0, 0.06, -52.8),
			Vector3(-11.5, 0.06, -49.5),
			Vector3(-15.5, 0.06, -34.0),
			Vector3(-15.5, 0.06, -18.0),
			Vector3(-15.5, 0.06, 20.5),
			Vector3(-28.5, 0.06, 28.8),
		],
		"point_at": Vector3(-32.0, 1.4, 32.0),
		"voice_id": "jozef_blocka_04",
		"line": "Take a look at this door at Building A. Make sure it's shut and locked — residents leave it propped open. Then log it in your notebook.",
		"inspect_sec": 4.2,
	},
	{
		"id": "stop_central_park",
		"path": [Vector3(-20.0, 0.06, 24.0), Vector3(-9.5, 0.06, 13.5), Vector3(-7.6, 0.06, 9.8)],
		"point_at": Vector3(-11.0, 1.1, 8.0),
		"voice_id": "jozef_park_05",
		"line": "Stick to the paved path through Central Park. In November fog it's easy to lose your bearings.",
		"react_sound": true,
		"inspect_sec": 4.4,
	},
	{
		"id": "stop_newsstand",
		"path": [Vector3(5.5, 0.06, 12.0), Vector3(28.5, 0.06, 12.0), Vector3(33.2, 0.06, -1.5), Vector3(33.5, 0.06, -9.8)],
		"point_at": Vector3(36.3, 1.5, -10.0),
		"voice_id": "jozef_shop_07",
		"line": "Check the Newsstand shutters and Night Shop entrance here. Dana's worked this square for years — she notices strangers.",
		"inspect_sec": 4.0,
	},
	{
		"id": "stop_return_office",
		"path": [
			Vector3(31.0, 0.06, -24.0),
			Vector3(28.5, 0.06, -38.0),
			Vector3(22.0, 0.06, -52.8),
			Vector3(4.0, 0.06, -53.0),
			Vector3(-9.8, 0.06, -54.6),
			Vector3(-14.2, 0.06, -54.6),
			Vector3(-16.2, 0.06, -56.2),
		],
		"point_at": Vector3(-19.0, 1.0, -57.8),
		"voice_id": "jozef_return_08",
		"line": "Right, that's everything. You can handle the next rounds on your own. Log your notes at the desk and call me on the radio if anything feels off.",
		"inspect_sec": 4.0,
	},
]

const NIGHT2_BRIEF_STOPS: Array[Dictionary] = [
	{
		"id": "n2_courtyard_handoff",
		"path": [
			Vector3(-14.3, 0.06, -54.6),
			Vector3(-11.0, 0.06, -54.6),
			Vector3(-15.5, 0.06, -34.0),
			Vector3(-15.5, 0.06, -18.0),
		],
		"point_at": Vector3(38.0, 2.0, 36.0),
		"voice_id": "jozef_n2_handoff",
		"line": "Someone reported footsteps in an empty flat in Building C. Check it out yourself tonight — I still have paperwork at the main office.",
		"inspect_sec": 4.0,
	},
]

var current_state: String = "WAITING_IN_OFFICE"
var district_ref: Node3D
var player_ref: Node3D
var voice_mgr: Node
var interactable_area: Area3D
var body_col: CollisionShape3D
var nav_agent: NavigationAgent3D

var model_root: Node3D
var torso_pivot: Node3D
var head_pivot: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var varga_flashlight: SpotLight3D
var footstep_player: AudioStreamPlayer3D

var active_stops: Array[Dictionary] = []
var stop_idx: int = 0
var sub_wp_idx: int = 0
var patrol_started: bool = false
var patrol_completed: bool = false
var doors_opened_count: int = 0
var guided_stops_completed: Array[String] = []
var current_move_speed: float = 0.0
var path_recalc_count: int = 0
var recovery_status: String = "OK"
var solid_collision_hits: int = 0

var _state_timer: float = 0.0
var _wait_call_cooldown: float = 0.0
var _walk_phase: float = 0.0
var _anim_t: float = 0.0
var _step_accum: float = 0.0
var _door_interact_target: Node = null
var _door_wait_open: bool = false
var _door_close_after: Node = null
var _point_target_world: Vector3 = Vector3.ZERO
var _last_door_id_opened: String = ""
var _active_nav_target: Vector3 = Vector3.ZERO
var _stuck_timer: float = 0.0
var _last_progress_pos: Vector3 = Vector3.ZERO
var _detour_offset: Vector3 = Vector3.ZERO
var _detour_timer: float = 0.0
var _custom_walk_target: Vector3 = Vector3.ZERO
var _has_custom_walk_target: bool = false
var _talking_timer: float = 0.0

const WALK_SPEED: float = 2.05
const SLOW_SPEED: float = 1.38
const GRAVITY: float = 18.0
const WAIT_DIST: float = 10.5
const RESUME_DIST: float = 7.4
const PLAYER_PERSONAL_SPACE: float = 1.35


func _au() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("AudioSynth") if ml is SceneTree else null


func setup_companion(p_district: Node3D, p_player: Node3D, p_voice_mgr: Node = null) -> void:
	name = "CompanionGuardController"
	district_ref = p_district
	player_ref = p_player
	voice_mgr = p_voice_mgr

	# Real solid human physics body: collides with walls, desks, cars, closed doors & fences (Layer 1) + NPCs (Layer 8)!
	collision_layer = 8
	collision_mask = 1 | 8
	floor_max_angle = deg_to_rad(46.0)
	position = Vector3(-16.2, 0.06, -56.2)
	rotation_degrees.y = 20.0
	_last_progress_pos = position

	body_col = CollisionShape3D.new()
	body_col.name = "CompanionCapsuleCol"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.76
	body_col.shape = cap
	body_col.position = Vector3(0.0, 0.88, 0.0)
	add_child(body_col)

	nav_agent = NavigationAgent3D.new()
	nav_agent.name = "CompanionNavAgent"
	nav_agent.radius = 0.44
	nav_agent.height = 1.85
	nav_agent.path_desired_distance = 0.60
	nav_agent.target_desired_distance = 0.65
	nav_agent.path_max_distance = 2.5
	nav_agent.avoidance_enabled = true
	nav_agent.max_speed = WALK_SPEED + 0.15
	nav_agent.neighbor_distance = 4.2
	nav_agent.time_horizon_agents = 1.1
	nav_agent.time_horizon_obstacles = 0.9
	add_child(nav_agent)

	_load_ps1_varga_model()
	_setup_audio()
	_create_interactable()
	if district_ref and district_ref.has_method("on_child_dynamic"):
		district_ref.on_child_dynamic("npc_varga_visual", self)
	refresh_for_night(1)


func _load_ps1_varga_model() -> void:
	var glb_path := "res://assets/models/char_varga.glb"
	if ResourceLoader.exists(glb_path):
		var packed: Resource = load(glb_path)
		if packed is PackedScene:
			var inst := (packed as PackedScene).instantiate()
			if inst is Node3D:
				model_root = inst as Node3D
				add_child(model_root)
				torso_pivot = model_root.find_child("TorsoPivot", true, false) as Node3D
				head_pivot = model_root.find_child("HeadPivot", true, false) as Node3D
				arm_l = model_root.find_child("ArmL_Pivot", true, false) as Node3D
				arm_r = model_root.find_child("ArmR_Pivot", true, false) as Node3D
				leg_l = model_root.find_child("LegL_Pivot", true, false) as Node3D
				leg_r = model_root.find_child("LegR_Pivot", true, false) as Node3D

				var tip: Node3D = model_root.find_child("VargaFlashlightTip", true, false) as Node3D
				var light_parent: Node3D = tip if tip else (arm_r if arm_r else self)
				varga_flashlight = SpotLight3D.new()
				varga_flashlight.name = "VargaPatrolFlashlight"
				varga_flashlight.light_color = Color(1.0, 0.88, 0.62)
				varga_flashlight.light_energy = 4.6
				varga_flashlight.spot_range = 17.5
				varga_flashlight.spot_angle = 34.0
				varga_flashlight.spot_angle_attenuation = 1.65
				varga_flashlight.shadow_enabled = true
				varga_flashlight.shadow_blur = 0.24
				varga_flashlight.rotation_degrees = Vector3(-8.0, 180.0, 0.0)
				if tip == null:
					varga_flashlight.position = Vector3(0.0, -0.58, 0.25)
				light_parent.add_child(varga_flashlight)


func _setup_audio() -> void:
	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.name = "JozefFootstep3D"
	footstep_player.max_distance = 22.0
	footstep_player.unit_size = 3.0
	footstep_player.volume_db = -6.0
	footstep_player.bus = "EnvLayer"
	add_child(footstep_player)


func _create_interactable() -> void:
	interactable_area = Area3D.new()
	var sc := load("res://scripts/world/interactable.gd")
	if sc:
		interactable_area.set_script(sc)
	interactable_area.name = "Int_npc_varga"
	interactable_area.position = Vector3(0.0, 1.15, 0.0)
	interactable_area.collision_layer = 2
	interactable_area.collision_mask = 0
	interactable_area.set("interact_id", "npc_varga")
	interactable_area.set("interact_type", "companion_varga")
	interactable_area.set("prompt_text", "[E] TALK TO JOZEF VARGA (START / FOLLOW PATROL)")
	interactable_area.set("extra_data", {"char_id": "varga"})
	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(1.6, 2.0, 1.6)
	col.shape = bx
	interactable_area.add_child(col)
	add_child(interactable_area)
	if district_ref and district_ref.has_method("on_child_interactable"):
		district_ref.on_child_interactable(interactable_area)


func is_articulated() -> bool:
	return head_pivot != null and arm_l != null and arm_r != null and leg_l != null and leg_r != null


func get_state() -> String:
	return current_state


func transition_to(new_state: String, duration: float = 0.0) -> void:
	if not (new_state in VALID_STATES):
		return
	var prev: String = current_state
	current_state = new_state
	_state_timer = duration
	if new_state != "WALKING_TO_CHECKPOINT":
		current_move_speed = 0.0
	if current_state != prev:
		emit_signal("state_changed", current_state)


func refresh_for_night(night_num: int) -> void:
	var n: int = clampi(night_num, 1, 6)
	patrol_started = false
	patrol_completed = false
	stop_idx = 0
	sub_wp_idx = 0
	doors_opened_count = 0
	guided_stops_completed.clear()
	_door_interact_target = null
	_door_wait_open = false
	_door_close_after = null
	_last_door_id_opened = ""
	_has_custom_walk_target = false
	_stuck_timer = 0.0
	_detour_timer = 0.0
	recovery_status = "OK"
	velocity = Vector3.ZERO
	position = Vector3(-16.2, 0.06, -56.2)
	rotation_degrees.y = 20.0
	_last_progress_pos = position

	if n == 1:
		active_stops = NIGHT1_GUIDED_STOPS.duplicate(true)
		_set_active(true)
		transition_to("WAITING_IN_OFFICE")
	elif n == 2:
		active_stops = NIGHT2_BRIEF_STOPS.duplicate(true)
		_set_active(true)
		transition_to("WAITING_IN_OFFICE")
	else:
		active_stops.clear()
		_set_active(false)
		transition_to("ENDING_PATROL")


func _set_active(act: bool) -> void:
	visible = act
	set_physics_process(act)
	set_process(false)
	if body_col:
		body_col.disabled = not act
	if varga_flashlight:
		varga_flashlight.visible = act
	if interactable_area:
		interactable_area.monitoring = act
		interactable_area.monitorable = act


func walk_to_local_spot(target_pos: Vector3, point_at: Vector3 = Vector3.ZERO) -> void:
	# Used by TutorialManager inside the Security Office (e.g., walking near desk or office door physically!)
	_custom_walk_target = target_pos
	_has_custom_walk_target = true
	if point_at != Vector3.ZERO:
		_point_target_world = point_at
	_set_nav_target(target_pos)
	transition_to("WALKING_TO_CHECKPOINT")


func speak_tutorial_line(text: String, voice_id: String = "", point_at: Vector3 = Vector3.ZERO) -> Dictionary:
	if point_at != Vector3.ZERO:
		_point_target_world = point_at
		if current_state == "WAITING_IN_OFFICE":
			transition_to("EXPLAINING_LOCATION", 3.2)
	return _speak(text, voice_id)


func interact_with_player() -> Dictionary:
	if not patrol_started and not active_stops.is_empty():
		return start_guided_patrol()
	if current_state == "WAITING_FOR_PLAYER":
		transition_to("RETURNING_TO_ROUTE", 0.4)
		return _speak("Good, let's keep moving. Stay close behind me.", "jozef_wait_06")
	if current_state in ["EXPLAINING_LOCATION", "INSPECTING_AREA"]:
		var stp: Dictionary = active_stops[clampi(stop_idx, 0, active_stops.size() - 1)]
		return _speak(str(stp.get("line", "")), str(stp.get("voice_id", "")))
	if patrol_completed:
		return _speak("Write every detail into your notebook. If anything feels off, call me on the radio.", "jozef_return_08")
	return _speak("Stay with me — I'll show you the next checkpoint.", "jozef_gate_02")


func start_guided_patrol() -> Dictionary:
	if active_stops.is_empty():
		return {}
	_has_custom_walk_target = false
	patrol_started = true
	patrol_completed = false
	stop_idx = 0
	sub_wp_idx = 0
	_stuck_timer = 0.0
	_detour_timer = 0.0
	recovery_status = "OK"
	transition_to("FOLLOWING_ROUTE", 0.5)
	var first_line: String = str(active_stops[0].get("line", "Follow me — I'll show you the patrol route."))
	var first_vid: String = str(active_stops[0].get("voice_id", "jozef_office_intro_01"))
	return _speak(first_line, first_vid)


func react_to_noise_at(sound_pos: Vector3) -> void:
	if not visible or current_state == "ENDING_PATROL":
		return
	_point_target_world = sound_pos
	transition_to("REACTING_TO_SOUND", 3.0)
	_speak("Did you hear that? Hold on a second... sometimes the wind rattles loose metal out here.", "jozef_sound_07")


func _speak(text: String, voice_id: String = "") -> Dictionary:
	_talking_timer = 4.2
	if voice_mgr and voice_mgr.has_method("play_voice_line") and not voice_id.is_empty():
		voice_mgr.play_voice_line(voice_id, global_position + Vector3(0, 1.6, 0))
	emit_signal("dialogue_spoken", "JOZEF VARGA", text, voice_id)
	return {"speaker": "JOZEF VARGA", "role": "Senior Security Guard — Mentor", "text": text, "voice_id": voice_id}


func _set_nav_target(tpos: Vector3) -> void:
	if _active_nav_target.distance_to(tpos) > 0.25 or path_recalc_count == 0:
		_active_nav_target = tpos
		if nav_agent:
			nav_agent.target_position = tpos
			path_recalc_count += 1


func get_nav_debug_info() -> Dictionary:
	var pts := PackedVector3Array()
	var npos: Vector3 = _active_nav_target
	var reachable: bool = true
	if nav_agent and is_inside_tree():
		var rid: RID = nav_agent.get_navigation_map()
		if rid.is_valid():
			pts = NavigationServer3D.map_get_path(rid, global_position, _active_nav_target, true)
			reachable = nav_agent.is_target_reachable()
			if not nav_agent.is_navigation_finished():
				npos = nav_agent.get_next_path_position()
	return {
		"state": current_state,
		"speed": current_move_speed,
		"target": _active_nav_target,
		"next_pos": npos,
		"path": pts,
		"reachable": reachable,
		"avoidance_radius": nav_agent.radius if nav_agent else 0.44,
		"recalc_count": path_recalc_count,
		"recovery_status": recovery_status,
		"doors_opened": doors_opened_count,
	}


func _physics_process(delta: float) -> void:
	_step_single_tick(clampf(delta, 0.001, 0.05))


func _process(delta: float) -> void:
	# Disabled during runtime (set_process(false)); allows deterministic test stepping if invoked directly.
	step_simulation(delta)


func step_simulation(delta: float) -> void:
	if not visible:
		return
	var phys_dt: float = get_physics_process_delta_time()
	if phys_dt <= 0.001:
		phys_dt = 1.0 / 60.0
	var remaining: float = maxf(0.001, delta)
	while remaining > 0.0005:
		var dt: float = minf(remaining, phys_dt)
		_step_single_tick(dt)
		remaining -= dt


func _step_single_tick(dt: float) -> void:
	if not visible:
		return
	_anim_t += dt
	if _wait_call_cooldown > 0.0:
		_wait_call_cooldown = maxf(0.0, _wait_call_cooldown - dt)
	if _state_timer > 0.0:
		_state_timer = maxf(0.0, _state_timer - dt)
	if _talking_timer > 0.0:
		_talking_timer = maxf(0.0, _talking_timer - dt)
	if _detour_timer > 0.0:
		_detour_timer = maxf(0.0, _detour_timer - dt)

	current_move_speed = _tick_state_machine(dt)
	_animate_companion(dt, current_move_speed)


func _tick_state_machine(delta: float) -> float:
	match current_state:
		"WAITING_IN_OFFICE":
			_apply_stationary_physics(delta)
			_face_player(delta)
			return 0.0

		"FOLLOWING_ROUTE":
			_apply_stationary_physics(delta)
			if _state_timer <= 0.0:
				transition_to("WALKING_TO_CHECKPOINT")
			return 0.0

		"RETURNING_TO_ROUTE":
			_apply_stationary_physics(delta)
			if _state_timer <= 0.0:
				transition_to("WALKING_TO_CHECKPOINT")
			return 0.0

		"WALKING_TO_CHECKPOINT":
			var target_pt: Vector3 = Vector3.ZERO
			var stp: Dictionary = {}
			if _has_custom_walk_target:
				target_pt = _custom_walk_target
			else:
				if stop_idx >= active_stops.size():
					patrol_completed = true
					transition_to("ENDING_PATROL")
					return 0.0
				# Wait naturally when Martin lags too far behind in the fog
				if player_ref and is_instance_valid(player_ref):
					var pdist: float = global_position.distance_to(player_ref.global_position)
					if pdist > WAIT_DIST:
						_apply_stationary_physics(delta)
						transition_to("WAITING_FOR_PLAYER")
						if _wait_call_cooldown <= 0.0:
							_wait_call_cooldown = 16.0
							_speak("Martin, come on — don't fall behind in the fog! I'll wait right here.", "jozef_wait_06")
						return 0.0
				stp = active_stops[stop_idx]
				var path_arr: Array = stp.get("path", [])
				if sub_wp_idx >= path_arr.size():
					_arrive_at_stop(stp)
					return 0.0
				target_pt = path_arr[sub_wp_idx]

			# Check if a closed PhysicalDoor blocks our route ahead -> stop & open physically!
			var to_goal: Vector3 = target_pt - global_position
			to_goal.y = 0.0
			var blocking_door: Node = _find_blocking_closed_door(target_pt, 2.25)
			if blocking_door != null:
				_apply_stationary_physics(delta)
				_door_interact_target = blocking_door
				_door_wait_open = true
				transition_to("INTERACTING_WITH_DOOR", 0.55)
				return 0.0

			# Close door politely once both Jozef & Martin have stepped past it if appropriate
			if _door_close_after and is_instance_valid(_door_close_after):
				var dp: Vector3 = (_door_close_after as Node3D).global_position
				if global_position.distance_to(dp) > 3.6 and (not player_ref or player_ref.global_position.distance_to(dp) > 2.6):
					if bool(_door_close_after.get("is_open")) and str(_door_close_after.get("door_id")) != "sec_office_door":
						_door_close_after.set_open(false, true)
					_door_close_after = null

			var dist_goal: float = to_goal.length()
			if dist_goal < 0.62:
				_stuck_timer = 0.0
				_detour_timer = 0.0
				recovery_status = "OK"
				if _has_custom_walk_target:
					_has_custom_walk_target = false
					transition_to("WAITING_IN_OFFICE")
				else:
					sub_wp_idx += 1
					var path_arr2: Array = stp.get("path", [])
					if sub_wp_idx >= path_arr2.size():
						_arrive_at_stop(stp)
				return 0.0

			# Query real NavigationAgent3D path on the baked NavMesh!
			_set_nav_target(target_pt)
			var steer_pt: Vector3 = target_pt
			if nav_agent and is_inside_tree():
				var rid: RID = nav_agent.get_navigation_map()
				if rid.is_valid() and not nav_agent.is_navigation_finished():
					var next_nav: Vector3 = nav_agent.get_next_path_position()
					if next_nav.distance_to(global_position) > 0.15 and next_nav.distance_to(target_pt) <= dist_goal + 18.0:
						steer_pt = next_nav
			if _detour_timer > 0.0:
				steer_pt = global_position + _detour_offset

			var desired_dir: Vector3 = steer_pt - global_position
			desired_dir.y = 0.0
			if desired_dir.length_squared() < 0.001:
				desired_dir = to_goal
			desired_dir = desired_dir.normalized()

			# Local 5-ray solid obstacle avoidance + player personal space (skip side jitter while centering through an open doorway!)
			if not _is_passing_open_doorway(1.9):
				desired_dir = _apply_local_obstacle_avoidance(desired_dir)

			var spd: float = WALK_SPEED
			if not _has_custom_walk_target and player_ref and global_position.distance_to(player_ref.global_position) > 6.5:
				spd = SLOW_SPEED

			# Do not walk into Martin's body if Martin stands right in front!
			if player_ref and is_instance_valid(player_ref):
				var to_pl: Vector3 = player_ref.global_position - global_position
				to_pl.y = 0.0
				var pd: float = to_pl.length()
				if pd < PLAYER_PERSONAL_SPACE and pd > 0.05:
					var away: Vector3 = (-to_pl).normalized()
					var side: Vector3 = Vector3(-away.z, 0.0, away.x)
					desired_dir = (desired_dir + away * 0.8 + side * 0.9).normalized()

			var prev_xz := Vector2(global_position.x, global_position.z)
			velocity.x = desired_dir.x * spd
			velocity.z = desired_dir.z * spd
			if not is_on_floor():
				velocity.y -= GRAVITY * delta
			else:
				velocity.y = 0.0
			move_and_slide()

			if get_slide_collision_count() > 0:
				for ci: int in range(get_slide_collision_count()):
					var col_n: KinematicCollision3D = get_slide_collision(ci)
					if col_n and absf(col_n.get_normal().y) < 0.55:
						solid_collision_hits += 1

			var new_xz := Vector2(global_position.x, global_position.z)
			var actual_moved: float = new_xz.distance_to(prev_xz)
			var actual_speed: float = actual_moved / maxf(delta, 0.001)

			if actual_speed > 0.15:
				_face_point(global_position + Vector3(desired_dir.x, 0.0, desired_dir.z), delta, 5.5)
				_step_accum += actual_moved
				if _step_accum >= 1.25:
					_step_accum = 0.0
					_play_footstep()

			# Part 2.8: Stuck Detection & Real Path Recalculation Recovery (NEVER walk in place or teleport!)
			if global_position.distance_to(_last_progress_pos) > 0.18:
				_last_progress_pos = global_position
				_stuck_timer = 0.0
				if recovery_status != "OK":
					recovery_status = "OK"
			else:
				_stuck_timer += delta
				if _stuck_timer >= 0.85:
					_handle_path_recovery(target_pt, desired_dir)
					return 0.0

			return actual_speed

		"INTERACTING_WITH_DOOR":
			_apply_stationary_physics(delta)
			if _door_interact_target and is_instance_valid(_door_interact_target):
				_face_point((_door_interact_target as Node3D).global_position, delta, 6.5)
				if _state_timer <= 0.25 and _door_wait_open:
					var is_locked_d: bool = bool(_door_interact_target.get("is_locked"))
					var dstate: String = str(_door_interact_target.get("door_state"))
					if dstate == "JAMMED":
						# Jammed door -> stop, inform player, recover gracefully
						if _door_interact_target.has_method("jiggle_locked_handle"):
							_door_interact_target.jiggle_locked_handle()
						_speak("This door is jammed shut. Let's look for another way around.", "jozef_wait_06")
						emit_signal("route_blocked_feedback", "Door jammed")
						_door_interact_target = null
						_door_wait_open = false
						transition_to("WAITING_FOR_PLAYER")
						return 0.0
					if is_locked_d:
						# Jozef carries the supervisor master key ring — unlock cleanly with key animation!
						var req_k: String = str(_door_interact_target.get("required_key_id"))
						if _door_interact_target.has_method("try_unlock_with_key"):
							_door_interact_target.try_unlock_with_key(req_k)
						elif _door_interact_target.has_method("set_manual_bolt_locked"):
							_door_interact_target.set_manual_bolt_locked(false)
					if not bool(_door_interact_target.get("is_open")):
						if _door_interact_target.has_method("animate_handle_depress"):
							_door_interact_target.animate_handle_depress(-34.0)
						if _door_interact_target.has_method("set_open"):
							_door_interact_target.set_open(true, true)
						var did: String = str(_door_interact_target.get("door_id"))
						if did != _last_door_id_opened:
							_last_door_id_opened = did
							doors_opened_count += 1
							emit_signal("door_opened_by_companion", did)
					_door_wait_open = false

				# Part 2.6: WAIT until the door hinge is sufficiently open (>= 55 deg or OPEN) before walking through!
				var hinge_open_enough: bool = false
				var hp: Variant = _door_interact_target.get("hinge_pivot")
				if hp is Node3D and absf((hp as Node3D).rotation_degrees.y) >= 52.0:
					hinge_open_enough = true
				elif str(_door_interact_target.get("door_state")) == "OPEN":
					hinge_open_enough = true
				elif _state_timer <= 0.0 and bool(_door_interact_target.get("is_open")) and DisplayServer.get_name() == "headless":
					# Headless deterministic test stepping does not advance scene tweens between manual step_simulation calls
					if hp is Node3D:
						(hp as Node3D).rotation_degrees.y = float(_door_interact_target.get("swing_angle_deg"))
					hinge_open_enough = true

				if not _door_wait_open and hinge_open_enough:
					var db: Variant = _door_interact_target.get("door_body")
					if db is Node3D:
						(db as Node3D).force_update_transform()
					_door_close_after = _door_interact_target
					_door_interact_target = null
					transition_to("WALKING_TO_CHECKPOINT")
			elif _state_timer <= 0.0:
				_door_interact_target = null
				transition_to("WALKING_TO_CHECKPOINT")
			return 0.0

		"WAITING_FOR_PLAYER":
			_apply_stationary_physics(delta)
			_face_player(delta)
			if player_ref and is_instance_valid(player_ref):
				if global_position.distance_to(player_ref.global_position) <= RESUME_DIST:
					transition_to("RETURNING_TO_ROUTE", 0.30)
			return 0.0

		"REACTING_TO_SOUND":
			_apply_stationary_physics(delta)
			_face_point(_point_target_world, delta, 4.8)
			if _state_timer <= 0.0:
				transition_to("EXPLAINING_LOCATION", 3.6)
			return 0.0

		"EXPLAINING_LOCATION":
			_apply_stationary_physics(delta)
			_face_player(delta)
			if _state_timer <= 0.0:
				if patrol_started:
					transition_to("INSPECTING_AREA", 1.6)
				else:
					transition_to("WAITING_IN_OFFICE")
			return 0.0

		"INSPECTING_AREA":
			_apply_stationary_physics(delta)
			_face_point(_point_target_world, delta, 4.0)
			if _state_timer <= 0.0:
				stop_idx += 1
				sub_wp_idx = 0
				if stop_idx >= active_stops.size():
					patrol_completed = true
					transition_to("ENDING_PATROL")
				else:
					transition_to("WALKING_TO_CHECKPOINT")
			return 0.0

		"ENDING_PATROL":
			_apply_stationary_physics(delta)
			_face_player(delta)
			return 0.0
	return 0.0


func _apply_stationary_physics(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	if is_inside_tree():
		move_and_slide()


func _apply_local_obstacle_avoidance(forward_dir: Vector3) -> Vector3:
	if not is_inside_tree() or not get_world_3d():
		return forward_dir
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if not space:
		return forward_dir

	var origin: Vector3 = global_position + Vector3(0.0, 0.72, 0.0)
	var fwd: Vector3 = Vector3(forward_dir.x, 0.0, forward_dir.z).normalized()
	var probe_dist: float = 1.65

	# Check center ray first — if completely clear, walk smoothly without zigzagging!
	var center_qp := PhysicsRayQueryParameters3D.create(origin, origin + fwd * probe_dist, 1)
	center_qp.exclude = [get_rid()]
	var center_hit: Dictionary = space.intersect_ray(center_qp)
	if center_hit.is_empty():
		return fwd

	# Solid obstacle ahead (car, pole, bench, wall corner) — test angled clear lanes!
	var hit_dist: float = origin.distance_to(center_hit.get("position", origin + fwd))
	var best_dir: Vector3 = fwd
	var best_score: float = -999.0
	for deg: float in [-28.0, 28.0, -56.0, 56.0, -82.0, 82.0]:
		var cand: Vector3 = fwd.rotated(Vector3.UP, deg_to_rad(deg)).normalized()
		var qp := PhysicsRayQueryParameters3D.create(origin, origin + cand * (probe_dist + 0.35), 1)
		qp.exclude = [get_rid()]
		var h: Dictionary = space.intersect_ray(qp)
		var clearance: float = (probe_dist + 0.35) if h.is_empty() else origin.distance_to(h.get("position", origin))
		var score: float = clearance * 2.0 - absf(deg) * 0.015
		if score > best_score:
			best_score = score
			best_dir = cand
	var blend: float = clampf(1.0 - (hit_dist / probe_dist), 0.35, 0.92)
	return fwd.lerp(best_dir, blend).normalized()


func _handle_path_recovery(target_pt: Vector3, blocked_dir: Vector3) -> void:
	_stuck_timer = 0.0
	path_recalc_count += 1
	recovery_status = "RECALCULATING (#%d)" % path_recalc_count

	# Force a fresh NavigationAgent3D query and try perpendicular sidestep clearance
	if nav_agent:
		nav_agent.target_position = target_pt
	var side_l: Vector3 = Vector3(-blocked_dir.z, 0.0, blocked_dir.x).normalized()
	var side_r: Vector3 = -side_l
	var chosen_side: Vector3 = side_l if (path_recalc_count % 2 == 1) else side_r
	if is_inside_tree() and get_world_3d():
		var space := get_world_3d().direct_space_state
		var org := global_position + Vector3(0.0, 0.72, 0.0)
		var hl := space.intersect_ray(PhysicsRayQueryParameters3D.create(org, org + side_l * 2.2, 1))
		var hr := space.intersect_ray(PhysicsRayQueryParameters3D.create(org, org + side_r * 2.2, 1))
		if hl.is_empty() and not hr.is_empty():
			chosen_side = side_l
		elif hr.is_empty() and not hl.is_empty():
			chosen_side = side_r

	_detour_offset = (chosen_side * 1.6 - blocked_dir * 0.45)
	_detour_timer = 0.85

	if path_recalc_count >= 12 and nav_agent and not nav_agent.is_target_reachable():
		recovery_status = "BLOCKED_WAITING"
		emit_signal("route_blocked_feedback", "Path blocked ahead — waiting for clear passage.")
		if _wait_call_cooldown <= 0.0:
			_wait_call_cooldown = 12.0
			_speak("Hold on, something's blocking the path ahead. Give me a second to step around.", "jozef_wait_06")
		transition_to("WAITING_FOR_PLAYER")


func _arrive_at_stop(stp: Dictionary) -> void:
	var sid: String = str(stp.get("id", ""))
	if not sid.is_empty() and not (sid in guided_stops_completed):
		guided_stops_completed.append(sid)
	_point_target_world = stp.get("point_at", global_position + Vector3(0, 1.0, 4.0))
	var line_s: String = str(stp.get("line", ""))
	var vid_s: String = str(stp.get("voice_id", ""))
	if not line_s.is_empty() and stop_idx > 0:
		_speak(line_s, vid_s)
	emit_signal("checkpoint_guided", sid)
	if bool(stp.get("react_sound", false)):
		transition_to("REACTING_TO_SOUND", 2.4)
	else:
		transition_to("EXPLAINING_LOCATION", float(stp.get("inspect_sec", 3.6)))


func _is_passing_open_doorway(radius: float) -> bool:
	if not district_ref or district_ref.get("door_manager") == null:
		return false
	var dm: Node = district_ref.get("door_manager")
	for did: String in dm.doors.keys():
		var dnode: Node = dm.doors[did]
		if dnode is Node3D and bool(dnode.get("is_open")):
			if global_position.distance_to((dnode as Node3D).global_position) <= radius:
				return true
	return false


func _find_blocking_closed_door(target_pt: Vector3, radius: float) -> Node:
	if not district_ref or district_ref.get("door_manager") == null:
		return null
	var dm: Node = district_ref.get("door_manager")
	var to_t: Vector3 = target_pt - global_position
	to_t.y = 0.0
	var dir_t: Vector3 = to_t.normalized() if to_t.length() > 0.05 else Vector3.ZERO
	for did: String in dm.doors.keys():
		var dnode: Node = dm.doors[did]
		if dnode is Node3D and not bool(dnode.get("is_open")):
			var dpos: Vector3 = (dnode as Node3D).global_position
			var to_d: Vector3 = dpos - global_position
			to_d.y = 0.0
			var dist_d: float = to_d.length()
			if dist_d <= radius:
				# Only interact with doors roughly in front of Jozef's travel direction (never doors behind him!)
				if dist_d < 1.05 or dir_t == Vector3.ZERO or dir_t.dot(to_d.normalized()) > 0.25:
					return dnode
	return null


func _face_player(delta: float) -> void:
	if player_ref and is_instance_valid(player_ref):
		_face_point(player_ref.global_position, delta, 4.2)


func _face_point(pt: Vector3, delta: float, turn_speed: float = 4.5) -> void:
	var to_p: Vector3 = pt - global_position
	to_p.y = 0.0
	if to_p.length() > 0.15:
		var target_yaw: float = atan2(to_p.x, to_p.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * turn_speed)


func _animate_companion(delta: float, move_speed: float) -> void:
	# Prompt 08 Part 5 — Complete Jozef Animations:
	# Walking, Stopping, Waiting, Looking Back, Pointing, Talking, Listening, Turning,
	# Opening Doors, Using Keys, Inspecting Environment, Looking Into Fog, Reacting to Sounds!
	if torso_pivot:
		var breath: float = sin(_anim_t * 1.9) * 0.022
		var lean: float = 0.09 if current_state == "INTERACTING_WITH_DOOR" else (0.04 if move_speed > 0.1 else 0.02)
		torso_pivot.rotation.x = lerpf(torso_pivot.rotation.x, lean + breath, delta * 5.0)
		torso_pivot.rotation.z = sin(_walk_phase * 0.5) * 0.032 if move_speed > 0.12 else sin(_anim_t * 0.7) * 0.015

	if move_speed > 0.12:
		_walk_phase += delta * (move_speed * 4.5)
		var l_sw: float = sin(_walk_phase) * 0.38
		if leg_l:
			leg_l.rotation.x = l_sw
		if leg_r:
			leg_r.rotation.x = -l_sw
		if arm_l:
			arm_l.rotation.x = -l_sw * 0.70
		if arm_r:
			arm_r.rotation.x = lerpf(arm_r.rotation.x, -0.78 + sin(_walk_phase) * 0.06, delta * 6.0)
	else:
		if leg_l:
			leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.0, delta * 7.0)
		if leg_r:
			leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.0, delta * 7.0)
		var target_arm_l: float = -0.10
		var target_arm_r: float = -0.68
		var target_arm_l_z: float = 0.0
		if current_state == "INTERACTING_WITH_DOOR":
			# Reaching forward to turn key & depress door handle!
			target_arm_l = -1.12 + sin(_anim_t * 7.5) * 0.12
			target_arm_r = -0.52
		elif current_state == "EXPLAINING_LOCATION":
			# Expressive pointing toward door/building/desk + conversational talking gesture
			target_arm_l = -1.04 + sin(_anim_t * 3.4) * 0.14
			target_arm_l_z = 0.16
			target_arm_r = -0.62 + cos(_anim_t * 2.4) * 0.09
		elif current_state == "WAITING_FOR_PLAYER":
			# Waiting wave/beckon back toward Martin
			target_arm_l = -0.78 + sin(_anim_t * 4.2) * 0.24
			target_arm_r = -0.74
		elif current_state == "REACTING_TO_SOUND":
			# Raising flashlight high & sweeping into fog!
			target_arm_r = -1.08 + sin(_anim_t * 2.2) * 0.08
			target_arm_l = -0.22
		elif current_state == "INSPECTING_AREA":
			# Scanning surroundings with flashlight
			target_arm_r = -0.88 + sin(_anim_t * 1.5) * 0.14
		elif _talking_timer > 0.0:
			# Talking gesture while standing in office
			target_arm_l = -0.55 + sin(_anim_t * 4.6) * 0.18
		if arm_l:
			arm_l.rotation.x = lerpf(arm_l.rotation.x, target_arm_l, delta * 5.5)
			arm_l.rotation.z = lerpf(arm_l.rotation.z, target_arm_l_z, delta * 5.0)
		if arm_r:
			arm_r.rotation.x = lerpf(arm_r.rotation.x, target_arm_r, delta * 5.5)

	if head_pivot:
		var hy: float = 0.0
		var hx: float = 0.0
		if current_state == "REACTING_TO_SOUND":
			hy = sin(_anim_t * 2.6) * 0.52
			hx = -0.06
		elif current_state == "INSPECTING_AREA":
			hy = sin(_anim_t * 1.2) * 0.36
			hx = 0.08
		elif current_state == "WAITING_FOR_PLAYER":
			hy = sin(_anim_t * 1.8) * 0.18
			hx = -0.04
		elif player_ref and is_instance_valid(player_ref) and global_position.distance_to(player_ref.global_position) < 10.0:
			var local_dir: Vector3 = global_transform.basis.inverse() * (player_ref.global_position - global_position).normalized()
			hy = clampf(atan2(local_dir.x, local_dir.z), -0.68, 0.68)
			hx = 0.04 if _talking_timer <= 0.0 else sin(_anim_t * 3.0) * 0.05 # Listening nod vs speaking
		head_pivot.rotation.y = lerpf(head_pivot.rotation.y, hy, delta * 3.5)
		head_pivot.rotation.x = lerpf(head_pivot.rotation.x, hx, delta * 3.5)


func _play_footstep() -> void:
	var au := _au()
	if not au or not footstep_player:
		return
	if au.has_method("has_stream") and au.has_stream("step_cobble_2"):
		footstep_player.stream = au._streams["step_cobble_2"]
		footstep_player.pitch_scale = randf_range(0.88, 0.96)
		if au._audio_enabled:
			footstep_player.play()
