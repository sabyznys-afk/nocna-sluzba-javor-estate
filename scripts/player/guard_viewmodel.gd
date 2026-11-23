class_name GuardViewmodel
extends Node3D

const ANIM_NAMES := [
	"vm_idle_breathe",
	"vm_walk_bob",
	"vm_fast_walk_bob",
	"vm_sprint_pump",
	"vm_crouch_lower",
	"vm_exhausted_sway",
	"vm_flashlight_toggle",
	"vm_battery_reload",
	"vm_taser_equip",
	"vm_taser_fire",
	"vm_taser_recharge",
	"vm_notebook_raise",
	"vm_notebook_page_flip",
	"vm_notebook_write",
	"vm_notebook_lower",
	"vm_keys_equip",
	"vm_keys_inspect",
	"vm_radio_equip",
	"vm_radio_use",
	"vm_watch_check",
	"vm_headphones_on",
	"vm_headphones_off",
	"vm_interact_door",
	"vm_interact_switch",
	"vm_empty_hands_idle",
	"vm_holster_item",
	"vm_stop_settle",
	"vm_keys_unlock",
	"vm_door_open",
	"vm_door_close",
	"vm_door_lock",
	"vm_notebook_cover_open",
	"vm_notebook_cover_close",
	"vm_pickup_object",
	"vm_inspect_evidence",
]

var equipped_slot: String = "flashlight"
var active_animation: String = "vm_idle_breathe"

var hands_pivot: Node3D
var flashlight_pivot: Node3D
var flashlight_fog_cone: MeshInstance3D
var taser_pivot: Node3D
var keys_pivot: Node3D
var radio_pivot: Node3D
var watch_pivot: Node3D
var headphones_pivot: Node3D
var notebook_pivot: Node3D
var pencil_pivot: Node3D
var taser_arc_mesh: MeshInstance3D
var taser_arc_light: OmniLight3D

var _phase: float = 0.0
var _toggle_kick: float = 0.0
var _reload_timer: float = 0.0
var _reload_duration: float = 0.95
var _taser_fire_timer: float = 0.0
var _taser_recharge_timer: float = 0.0
var _equip_timer: float = 0.0
var _action_timer: float = 0.0
var _action_kind: String = ""
var _notebook_open: bool = false
var _notebook_blend: float = 0.0
var _notebook_flip_timer: float = 0.0
var _notebook_write_timer: float = 0.0
var _hp_anim_timer: float = 0.0
var _hp_putting_on: bool = true
var _interact_timer: float = 0.0
var _interact_kind: String = ""
var _flashlight_on: bool = true
var _look_sway: Vector2 = Vector2.ZERO
var _was_moving: bool = false
var _stop_settle_timer: float = 0.0

const HANDS_BASE_POS := Vector3(0.0, -0.25, -0.32)
const FLASH_BASE_POS := Vector3(0.24, -0.22, -0.36)
const TASER_BASE_POS := Vector3(0.25, -0.21, -0.37)
const KEYS_BASE_POS := Vector3(0.22, -0.22, -0.35)
const RADIO_BASE_POS := Vector3(0.23, -0.23, -0.36)
const WATCH_BASE_POS := Vector3(-0.18, -0.21, -0.32)
const HP_DOWN_POS := Vector3(0.0, -0.52, -0.28)
const HP_UP_POS := Vector3(0.0, -0.02, -0.14)
const NOTEBOOK_DOWN_POS := Vector3(-0.24, -0.58, -0.24)
const NOTEBOOK_UP_POS := Vector3(-0.08, -0.22, -0.33)


func _ready() -> void:
	name = "GuardViewmodel"
	_build_pivots()
	set_equipped_slot("flashlight")


func get_registered_animation_names() -> PackedStringArray:
	return ANIM_NAMES


func get_animation_count() -> int:
	return ANIM_NAMES.size()


func _build_pivots() -> void:
	hands_pivot = Node3D.new()
	hands_pivot.name = "HandsPivot"
	hands_pivot.position = HANDS_BASE_POS
	hands_pivot.visible = false
	add_child(hands_pivot)
	_attach_glb(hands_pivot, "res://assets/models/vm_empty_hands.glb", Vector3.ONE)

	flashlight_pivot = Node3D.new()
	flashlight_pivot.name = "FlashlightPivot"
	flashlight_pivot.position = FLASH_BASE_POS
	add_child(flashlight_pivot)
	_attach_glb(flashlight_pivot, "res://assets/models/vm_flashlight.glb", Vector3.ONE)

	flashlight_fog_cone = MeshInstance3D.new()
	flashlight_fog_cone.name = "FlashlightFogCone"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.025
	cone.bottom_radius = 1.15
	cone.height = 5.4
	cone.radial_segments = 18
	cone.cap_top = false
	cone.cap_bottom = false
	var cone_mat := StandardMaterial3D.new()
	cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cone_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	cone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone_mat.disable_fog = true
	cone_mat.albedo_color = Color(0.95, 0.84, 0.58, 0.014)
	cone.material = cone_mat
	flashlight_fog_cone.mesh = cone
	flashlight_fog_cone.position = Vector3(0.0, 0.02, -2.92)
	flashlight_fog_cone.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	flashlight_fog_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flashlight_pivot.add_child(flashlight_fog_cone)

	# Subtle inner beam whisper (zero distracting hard ring!)
	var core_cone := MeshInstance3D.new()
	core_cone.name = "FlashlightFogCore"
	var inner_c := CylinderMesh.new()
	inner_c.top_radius = 0.018
	inner_c.bottom_radius = 0.36
	inner_c.height = 2.6
	inner_c.radial_segments = 14
	inner_c.cap_top = false
	inner_c.cap_bottom = false
	var inner_mat := StandardMaterial3D.new()
	inner_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	inner_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	inner_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	inner_mat.disable_fog = true
	inner_mat.albedo_color = Color(1.0, 0.90, 0.68, 0.012)
	inner_c.material = inner_mat
	core_cone.mesh = inner_c
	core_cone.position = Vector3(0.0, 1.05, 0.0)
	core_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flashlight_fog_cone.add_child(core_cone)

	taser_pivot = Node3D.new()
	taser_pivot.name = "TaserPivot"
	taser_pivot.position = TASER_BASE_POS
	add_child(taser_pivot)
	_attach_glb(taser_pivot, "res://assets/models/vm_taser.glb", Vector3.ONE)

	taser_arc_mesh = MeshInstance3D.new()
	taser_arc_mesh.name = "TaserArcMesh"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.004
	cyl.bottom_radius = 0.004
	cyl.height = 0.044
	var arc_mat := StandardMaterial3D.new()
	arc_mat.albedo_color = Color(0.55, 0.90, 1.0, 0.95)
	arc_mat.emission_enabled = true
	arc_mat.emission = Color(0.35, 0.86, 1.0)
	arc_mat.emission_energy_multiplier = 6.0
	cyl.material = arc_mat
	taser_arc_mesh.mesh = cyl
	taser_arc_mesh.position = Vector3(0.0, 0.015, -0.262)
	taser_arc_mesh.rotation_degrees = Vector3(0, 0, 90)
	taser_arc_mesh.visible = false
	taser_pivot.add_child(taser_arc_mesh)

	taser_arc_light = OmniLight3D.new()
	taser_arc_light.name = "TaserArcLight"
	taser_arc_light.position = Vector3(0.0, 0.02, -0.28)
	taser_arc_light.light_color = Color(0.45, 0.85, 1.0)
	taser_arc_light.light_energy = 0.0
	taser_arc_light.omni_range = 4.2
	taser_pivot.add_child(taser_arc_light)

	keys_pivot = Node3D.new()
	keys_pivot.name = "KeysPivot"
	keys_pivot.position = KEYS_BASE_POS
	keys_pivot.visible = false
	add_child(keys_pivot)
	_attach_glb(keys_pivot, "res://assets/models/vm_keys.glb", Vector3.ONE)

	radio_pivot = Node3D.new()
	radio_pivot.name = "RadioPivot"
	radio_pivot.position = RADIO_BASE_POS
	radio_pivot.visible = false
	add_child(radio_pivot)
	_attach_glb(radio_pivot, "res://assets/models/vm_radio.glb", Vector3.ONE)

	watch_pivot = Node3D.new()
	watch_pivot.name = "WatchPivot"
	watch_pivot.position = WATCH_BASE_POS
	watch_pivot.visible = false
	add_child(watch_pivot)
	_attach_glb(watch_pivot, "res://assets/models/vm_watch.glb", Vector3.ONE)

	headphones_pivot = Node3D.new()
	headphones_pivot.name = "HeadphonesPivot"
	headphones_pivot.position = HP_DOWN_POS
	headphones_pivot.visible = false
	add_child(headphones_pivot)
	_attach_glb(headphones_pivot, "res://assets/models/vm_headphones.glb", Vector3.ONE)

	notebook_pivot = Node3D.new()
	notebook_pivot.name = "NotebookPivot"
	notebook_pivot.position = NOTEBOOK_DOWN_POS
	notebook_pivot.visible = false
	add_child(notebook_pivot)
	var nb_inst := _attach_glb(notebook_pivot, "res://assets/models/vm_notebook.glb", Vector3.ONE)
	if nb_inst != null:
		nb_inst.rotation_degrees = Vector3(14, 6, 0)

	pencil_pivot = Node3D.new()
	pencil_pivot.name = "PencilHandPivot"
	pencil_pivot.position = Vector3(0.08, 0.04, 0.02)
	pencil_pivot.visible = false
	notebook_pivot.add_child(pencil_pivot)
	_attach_glb(pencil_pivot, "res://assets/models/vm_pencil_hand.glb", Vector3.ONE)


func _attach_glb(parent: Node3D, res_path: String, scale_vec: Vector3) -> Node3D:
	if not ResourceLoader.exists(res_path):
		return null
	var packed: Resource = ResourceLoader.load(res_path)
	if packed is PackedScene:
		var inst: Node = (packed as PackedScene).instantiate()
		if inst is Node3D:
			(inst as Node3D).scale = scale_vec
			parent.add_child(inst)
			return inst as Node3D
	return null


func set_equipped_slot(slot: String) -> void:
	var valid := ["hands", "flashlight", "taser", "keys", "radio", "watch", "notebook"]
	equipped_slot = slot if (slot in valid) else "flashlight"
	_equip_timer = 0.35
	match equipped_slot:
		"hands":
			active_animation = "vm_holster_item"
			_notebook_open = false
		"taser":
			active_animation = "vm_taser_equip"
			_notebook_open = false
		"keys":
			active_animation = "vm_keys_equip"
			_notebook_open = false
		"radio":
			active_animation = "vm_radio_equip"
			_notebook_open = false
		"watch":
			active_animation = "vm_watch_check"
			_action_kind = "watch"
			_action_timer = 0.65
			_notebook_open = false
		"notebook":
			active_animation = "vm_notebook_raise"
			_notebook_open = true
		_:
			active_animation = "vm_flashlight_toggle"
			_notebook_open = false

	if hands_pivot:
		hands_pivot.visible = (equipped_slot == "hands")
	if flashlight_pivot:
		flashlight_pivot.visible = (equipped_slot == "flashlight")
	if flashlight_fog_cone:
		flashlight_fog_cone.visible = (equipped_slot == "flashlight" and _flashlight_on)
	if taser_pivot:
		taser_pivot.visible = (equipped_slot == "taser")
	if keys_pivot:
		keys_pivot.visible = (equipped_slot == "keys")
	if radio_pivot:
		radio_pivot.visible = (equipped_slot == "radio")
	if watch_pivot:
		watch_pivot.visible = (equipped_slot == "watch")
	if notebook_pivot and equipped_slot == "notebook":
		notebook_pivot.visible = true


func play_flashlight_toggle() -> void:
	_toggle_kick = 1.0
	active_animation = "vm_flashlight_toggle"


func play_battery_reload() -> void:
	_reload_timer = _reload_duration
	active_animation = "vm_battery_reload"


func play_taser_fire() -> void:
	_taser_fire_timer = 0.42
	_taser_recharge_timer = 0.85
	active_animation = "vm_taser_fire"


func play_notebook_open(opened: bool) -> void:
	_notebook_open = opened
	active_animation = "vm_notebook_raise" if opened else "vm_notebook_lower"
	if notebook_pivot != null and opened:
		notebook_pivot.visible = true


func play_notebook_check() -> void:
	_notebook_flip_timer = 0.36
	active_animation = "vm_notebook_page_flip"


func play_notebook_write() -> void:
	_notebook_write_timer = 0.65
	active_animation = "vm_notebook_write"


func play_keys_inspect() -> void:
	_action_kind = "keys"
	_action_timer = 0.55
	active_animation = "vm_keys_inspect"


func play_radio_use() -> void:
	_action_kind = "radio"
	_action_timer = 0.65
	active_animation = "vm_radio_use"


func play_watch_check() -> void:
	_action_kind = "watch"
	_action_timer = 0.65
	active_animation = "vm_watch_check"


func play_headphones_toggle(putting_on: bool) -> void:
	_hp_putting_on = putting_on
	_hp_anim_timer = 0.65
	active_animation = "vm_headphones_on" if putting_on else "vm_headphones_off"


func play_interact_door(opening: bool = true) -> void:
	_interact_kind = "door_open" if opening else "door_close"
	_interact_timer = 0.42
	active_animation = "vm_door_open" if opening else "vm_door_close"


func play_door_lock() -> void:
	_interact_kind = "door_lock"
	_interact_timer = 0.48
	active_animation = "vm_door_lock"


func play_keys_unlock() -> void:
	_action_kind = "keys_unlock"
	_action_timer = 0.60
	active_animation = "vm_keys_unlock"


func play_pickup_object() -> void:
	_interact_kind = "pickup"
	_interact_timer = 0.44
	active_animation = "vm_pickup_object"


func play_inspect_evidence() -> void:
	_interact_kind = "inspect"
	_interact_timer = 0.65
	active_animation = "vm_inspect_evidence"


func update_look_sway(delta_yaw: float, delta_pitch: float) -> void:
	_look_sway.x = clampf(_look_sway.x + delta_yaw * 0.45, -0.045, 0.045)
	_look_sway.y = clampf(_look_sway.y + delta_pitch * 0.45, -0.035, 0.035)


func play_interact_switch() -> void:
	_interact_kind = "switch"
	_interact_timer = 0.28
	active_animation = "vm_interact_switch"


func update_locomotion(
	delta: float,
	speed_ratio: float,
	sprinting: bool,
	fast_walking: bool = false,
	crouching: bool = false,
	exhausted: bool = false,
	flashlight_on: bool = true
) -> void:
	_flashlight_on = flashlight_on
	var rate: float = 1.6
	if sprinting and speed_ratio > 0.2:
		rate = 10.5
		active_animation = "vm_sprint_pump"
	elif fast_walking and speed_ratio > 0.18:
		rate = 8.4
		active_animation = "vm_fast_walk_bob"
	elif speed_ratio > 0.12:
		rate = 6.2
		active_animation = "vm_walk_bob"
	elif exhausted:
		rate = 3.2
		active_animation = "vm_exhausted_sway"
	elif crouching:
		rate = 1.3
		active_animation = "vm_crouch_lower"
	else:
		active_animation = "vm_idle_breathe"
	_phase += delta * rate

	_toggle_kick = maxf(0.0, _toggle_kick - delta * 5.2)
	_equip_timer = maxf(0.0, _equip_timer - delta)
	_reload_timer = maxf(0.0, _reload_timer - delta)
	_taser_fire_timer = maxf(0.0, _taser_fire_timer - delta)
	_taser_recharge_timer = maxf(0.0, _taser_recharge_timer - delta)
	_notebook_flip_timer = maxf(0.0, _notebook_flip_timer - delta)
	_notebook_write_timer = maxf(0.0, _notebook_write_timer - delta)
	_action_timer = maxf(0.0, _action_timer - delta)
	_hp_anim_timer = maxf(0.0, _hp_anim_timer - delta)
	_interact_timer = maxf(0.0, _interact_timer - delta)

	var moving_now: bool = speed_ratio > 0.12
	if _was_moving and not moving_now:
		_stop_settle_timer = 0.32
	_was_moving = moving_now
	_stop_settle_timer = maxf(0.0, _stop_settle_timer - delta)
	_look_sway = _look_sway.lerp(Vector2.ZERO, clampf(delta * 8.5, 0.0, 1.0))

	if _hp_anim_timer > 0.0:
		active_animation = "vm_headphones_on" if _hp_putting_on else "vm_headphones_off"
	elif _interact_timer > 0.0:
		match _interact_kind:
			"door_open": active_animation = "vm_door_open"
			"door_close": active_animation = "vm_door_close"
			"door_lock": active_animation = "vm_door_lock"
			"pickup": active_animation = "vm_pickup_object"
			"inspect": active_animation = "vm_inspect_evidence"
			"switch": active_animation = "vm_interact_switch"
			_: active_animation = "vm_interact_door"
	elif _taser_fire_timer > 0.0:
		active_animation = "vm_taser_fire"
	elif _reload_timer > 0.0:
		active_animation = "vm_battery_reload"
	elif _notebook_write_timer > 0.0:
		active_animation = "vm_notebook_write"
	elif _notebook_flip_timer > 0.0:
		active_animation = "vm_notebook_page_flip"
	elif _notebook_open:
		active_animation = "vm_notebook_cover_open" if _notebook_blend < 0.85 else "vm_notebook_raise"
	elif _notebook_blend > 0.05 and not _notebook_open:
		active_animation = "vm_notebook_cover_close"
	elif _action_timer > 0.0:
		if _action_kind == "keys_unlock":
			active_animation = "vm_keys_unlock"
		elif _action_kind == "keys":
			active_animation = "vm_keys_inspect"
		elif _action_kind == "radio":
			active_animation = "vm_radio_use"
		elif _action_kind == "watch":
			active_animation = "vm_watch_check"
	elif _stop_settle_timer > 0.0:
		active_animation = "vm_stop_settle"
	elif _taser_recharge_timer > 0.0 and equipped_slot == "taser":
		active_animation = "vm_taser_recharge"
	elif _equip_timer > 0.0:
		if equipped_slot == "hands":
			active_animation = "vm_holster_item"
		elif equipped_slot == "taser":
			active_animation = "vm_taser_equip"
		elif equipped_slot == "keys":
			active_animation = "vm_keys_equip"
		elif equipped_slot == "radio":
			active_animation = "vm_radio_equip"
	elif equipped_slot == "hands" and speed_ratio <= 0.12 and not crouching and not exhausted:
		active_animation = "vm_empty_hands_idle"

	var sway_ex: float = 0.012 if exhausted else 0.0
	var bob_amp: float = 0.004 + (0.012 if speed_ratio > 0.12 else 0.0) + (0.008 if fast_walking else 0.0) + (0.016 if sprinting else 0.0) + sway_ex
	var bob_x: float = cos(_phase * 0.5) * bob_amp + _look_sway.x
	var stop_dip: float = -sin((_stop_settle_timer / 0.32) * PI) * 0.016 if _stop_settle_timer > 0.0 else 0.0
	var bob_y: float = absf(sin(_phase)) * (-bob_amp * 0.85) + (sin(_phase * 1.1) * 0.009 if exhausted else 0.0) + _look_sway.y + stop_dip
	var crouch_y: float = -0.045 if crouching else 0.0
	var idle_breathe: float = sin(_phase * 0.8) * 0.004

	var interact_z: float = -sin((_interact_timer / 0.38) * PI) * 0.09 if _interact_timer > 0.0 else 0.0
	var interact_pitch: float = sin((_interact_timer / 0.38) * PI) * 0.25 if _interact_timer > 0.0 else 0.0

	var reload_t: float = 0.0
	var reload_roll: float = 0.0
	if _reload_timer > 0.0:
		var p: float = 1.0 - (_reload_timer / _reload_duration)
		reload_t = sin(p * PI)
		reload_roll = sin(p * PI * 2.0) * 0.48

	var equip_drop: float = (_equip_timer / 0.35) * 0.14

	if hands_pivot and hands_pivot.visible:
		hands_pivot.position = HANDS_BASE_POS + Vector3(
			bob_x * 0.8,
			bob_y * 0.8 + crouch_y + idle_breathe - equip_drop * 0.7,
			interact_z * 1.15
		)
		hands_pivot.rotation = Vector3(-interact_pitch * 0.8, 0.0, 0.0)

	if flashlight_fog_cone:
		flashlight_fog_cone.visible = (equipped_slot == "flashlight" and _flashlight_on)

	if flashlight_pivot:
		var pitch_offset: float = (-0.18 if sprinting and speed_ratio > 0.3 else 0.0) - (_toggle_kick * 0.12) - (reload_t * 0.45) - interact_pitch
		flashlight_pivot.position = FLASH_BASE_POS + Vector3(
			bob_x - reload_t * 0.06,
			bob_y + crouch_y + idle_breathe - reload_t * 0.12 - equip_drop,
			(_toggle_kick * 0.025) + reload_t * 0.05 + interact_z
		)
		flashlight_pivot.rotation = Vector3(pitch_offset, reload_t * 0.25, reload_roll)

	if taser_pivot:
		var recoil_z: float = sin(minf(1.0, _taser_fire_timer / 0.42) * PI) * 0.06
		var recoil_pitch: float = sin(minf(1.0, _taser_fire_timer / 0.42) * PI) * 0.18
		var jitter_x: float = sin(_phase * 19.0) * 0.008 if _taser_fire_timer > 0.0 else 0.0
		var jitter_y: float = cos(_phase * 23.0) * 0.008 if _taser_fire_timer > 0.0 else 0.0
		taser_pivot.position = TASER_BASE_POS + Vector3(
			bob_x + jitter_x,
			bob_y + crouch_y + idle_breathe + jitter_y - equip_drop - reload_t * 0.11,
			recoil_z + reload_t * 0.04 + interact_z
		)
		taser_pivot.rotation = Vector3(recoil_pitch - reload_t * 0.38 - interact_pitch, 0.0, reload_roll)

	if taser_arc_mesh and taser_arc_light:
		var arcing: bool = (_taser_fire_timer > 0.0 and equipped_slot == "taser")
		taser_arc_mesh.visible = arcing
		if arcing:
			taser_arc_light.light_energy = 1.8 + absf(sin(Time.get_ticks_msec() * 0.09)) * 4.5
			taser_arc_mesh.rotation_degrees.x = float(Time.get_ticks_msec() % 180)
		else:
			taser_arc_light.light_energy = 0.0

	if keys_pivot and keys_pivot.visible:
		var unlock_twist: float = sin((_action_timer / 0.60) * PI * 2.0) * 0.72 if (_action_timer > 0.0 and _action_kind == "keys_unlock") else 0.0
		var jingle_rot: float = sin(Time.get_ticks_msec() * 0.04) * 0.35 if (_action_timer > 0.0 and _action_kind == "keys") else 0.0
		var raise_z: float = -0.09 if (_action_timer > 0.0 and _action_kind in ["keys", "keys_unlock"]) else 0.0
		keys_pivot.position = KEYS_BASE_POS + Vector3(bob_x, bob_y + crouch_y + idle_breathe - equip_drop, raise_z + interact_z)
		keys_pivot.rotation = Vector3(jingle_rot - interact_pitch, 0.0, jingle_rot * 0.8 + unlock_twist)

	if radio_pivot and radio_pivot.visible:
		var use_t: float = sin((_action_timer / 0.65) * PI) if (_action_timer > 0.0 and _action_kind == "radio") else 0.0
		radio_pivot.position = RADIO_BASE_POS + Vector3(bob_x - use_t * 0.06, bob_y + crouch_y + idle_breathe + use_t * 0.07 - equip_drop, use_t * 0.05 + interact_z)
		radio_pivot.rotation = Vector3(-use_t * 0.22 - interact_pitch, use_t * 0.15, 0.0)

	if watch_pivot and watch_pivot.visible:
		var check_t: float = sin((_action_timer / 0.65) * PI) if (_action_timer > 0.0 and _action_kind == "watch") else 0.0
		watch_pivot.position = WATCH_BASE_POS + Vector3(bob_x * 0.6 + check_t * 0.10, bob_y * 0.6 + crouch_y + check_t * 0.09 - equip_drop, check_t * 0.05)
		watch_pivot.rotation = Vector3(-0.35 * check_t, 0.30 * check_t, 0.15 * check_t)

	if headphones_pivot:
		headphones_pivot.visible = (_hp_anim_timer > 0.0)
		if headphones_pivot.visible:
			var p: float = 1.0 - (_hp_anim_timer / 0.65)
			var t_hp: float = sin(p * PI)
			var base_pos := HP_DOWN_POS.lerp(HP_UP_POS, t_hp)
			headphones_pivot.position = base_pos
			headphones_pivot.rotation = Vector3((1.0 - t_hp) * 0.35, 0.0, 0.0)

	if notebook_pivot:
		var target_blend: float = 1.0 if _notebook_open else 0.0
		_notebook_blend = move_toward(_notebook_blend, target_blend, delta * 6.5)
		notebook_pivot.visible = (_notebook_blend > 0.03)
		var flip_kick: float = sin((_notebook_flip_timer / 0.36) * PI) * 0.18 if _notebook_flip_timer > 0.0 else 0.0
		notebook_pivot.position = NOTEBOOK_DOWN_POS.lerp(NOTEBOOK_UP_POS, _notebook_blend) + Vector3(0.0, bob_y * 0.4 + flip_kick * 0.04, 0.0)
		notebook_pivot.rotation = Vector3(-flip_kick, flip_kick * 0.4, 0.0)
		if pencil_pivot:
			pencil_pivot.visible = (_notebook_write_timer > 0.0 or _notebook_flip_timer > 0.0) and notebook_pivot.visible
			if pencil_pivot.visible:
				var scribble: float = sin(Time.get_ticks_msec() * 0.035) * 0.035
				pencil_pivot.position = Vector3(0.06 + scribble, 0.035 + absf(scribble) * 0.3, 0.02 + scribble * 0.4)
				pencil_pivot.rotation = Vector3(0.25, 0.15, scribble * 2.0)
