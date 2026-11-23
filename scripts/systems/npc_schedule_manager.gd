class_name NPCScheduleManager
extends Node3D

const NPCControllerScript = preload("res://scripts/systems/npc_character.gd")

var controllers: Dictionary = {} # char_id -> NPCCharacterController
var district_ref: Node3D
var player_ref: Node3D
var _varga_interactable: Area3D
var _milan_rescue_interactable: Area3D


func setup_schedules(district: Node3D, player: Node3D) -> void:
	name = "NPCScheduleManager"
	district_ref = district
	player_ref = player
	_spawn_all_npcs()
	refresh_for_night(GameState.current_night if get_node_or_null("/root/GameState") else 1)


func get_npc_count() -> int:
	return controllers.size()


func get_npc(char_id: String) -> Node3D:
	return controllers.get(char_id, null) as Node3D


func trigger_talk(char_id: String, duration: float = 6.0) -> void:
	var ctrl: Variant = controllers.get(char_id, null)
	if ctrl and ctrl.has_method("trigger_talk_gesture"):
		ctrl.trigger_talk_gesture(duration)


func _spawn_all_npcs() -> void:
	# Note: Jozef Varga is driven by CompanionGuardController (physical walking mentor on Nights 1-2!)
	# 1. Anna Krížanová (68, Long-term Resident — walks believable route around Block A, bench & courtyard)
	var anna := NPCControllerScript.new()
	anna.setup_character("anna", "char_anna", "idle_alert", Vector3(-28.5, 0.0, 30.8), 175.0, player_ref)
	anna.set_schedule_waypoints([
		Vector3(-28.5, 0.0, 30.8),
		Vector3(-21.0, 0.0, 28.0),
		Vector3(-15.0, 0.0, 27.5),
		Vector3(-28.5, 0.0, 30.8),
	], 0.82)
	add_child(anna)
	controllers["anna"] = anna
	var anna_int := _find_district_interactable("npc_anna")
	if anna_int:
		anna.linked_interactable = anna_int
		anna.interactable_offset = Vector3(0.0, 1.1, 0.0)
	if district_ref and district_ref.has_method("on_child_dynamic"):
		district_ref.on_child_dynamic("npc_anna_visual", anna)

	# 3. Dana Bieliková (39, Večierka & Newsstand Worker — active behind shop counter, tidying & watching street)
	var dana := NPCControllerScript.new()
	dana.setup_character("dana", "char_dana", "idle_shop", Vector3(45.2, 0.02, 2.3), 180.0, player_ref)
	dana.set_schedule_waypoints([
		Vector3(45.2, 0.02, 2.3),
		Vector3(46.3, 0.02, 2.3),
		Vector3(44.3, 0.02, 2.3),
	], 0.65)
	add_child(dana)
	controllers["dana"] = dana
	var dana_int := _find_district_interactable("npc_dana")
	if dana_int:
		dana.linked_interactable = dana_int
		dana.interactable_offset = Vector3(0.0, 1.1, -1.4)
	if district_ref and district_ref.has_method("on_child_dynamic"):
		district_ref.on_child_dynamic("npc_dana_visual", dana)

	# 4. Zuzana Horváthová (46, Trafika Newsstand Vendor — animated inside Trafika kiosk)
	var zuzana := NPCControllerScript.new()
	zuzana.setup_character("zuzana", "char_zuzana", "idle_shop", Vector3(37.65, 0.08, -10.0), -90.0, player_ref)
	add_child(zuzana)
	controllers["zuzana"] = zuzana
	if district_ref and district_ref.has_method("on_child_dynamic"):
		district_ref.on_child_dynamic("npc_zuzana_visual", zuzana)

	# 5. Peter (12, Local Child — near Central Park Playground)
	var peter := NPCControllerScript.new()
	peter.setup_character("peter", "char_peter", "idle_alert", Vector3(-13.8, 0.0, 10.6), 40.0, player_ref)
	add_child(peter)
	controllers["peter"] = peter
	if district_ref and district_ref.has_method("on_child_dynamic"):
		district_ref.on_child_dynamic("npc_peter_visual", peter)

	# 6. Milan Švec (44, Missing Previous Guard — alive & exhausted inside Hidden Apartment 47 Room on Night 6!)
	var milan := NPCControllerScript.new()
	milan.setup_character("milan_rescue", "char_milan", "exhausted", Vector3(-84.2, -4.4, -12.0), 90.0, player_ref)
	add_child(milan)
	controllers["milan_rescue"] = milan
	_milan_rescue_interactable = _make_npc_interactable("n6_milan_rescue", "campaign_event", "[E] HELP EXHAUSTED MILAN ŠVEC (APARTMENT 47 ROOM)", Vector3(-84.2, -3.4, -12.0), Vector3(1.9, 2.0, 1.9), {"event_id": "n6_milan_rescue"})
	if district_ref and district_ref.has_method("on_child_dynamic"):
		district_ref.on_child_dynamic("npc_milan_rescue_visual", milan)

	# 7. Environmental Residents (Part 9.8 & Part 10 — living pedestrian routes across Nights 1-5!)
	var res_a := NPCControllerScript.new()
	res_a.setup_character("resident_a", "char_resident_a", "resident_walk", Vector3(12.0, 0.0, -21.0), 0.0, player_ref)
	res_a.set_schedule_waypoints([
		Vector3(12.0, 0.0, -21.0),
		Vector3(36.0, 0.0, -20.0),
		Vector3(36.5, 0.0, 10.0),
		Vector3(10.0, 0.0, 2.0),
		Vector3(4.0, 0.0, -21.0),
	], 1.05)
	add_child(res_a)
	controllers["resident_a"] = res_a

	var res_b := NPCControllerScript.new()
	res_b.setup_character("resident_b", "char_resident_b", "resident_walk", Vector3(26.0, 0.0, 28.0), -90.0, player_ref)
	res_b.set_schedule_waypoints([
		Vector3(26.0, 0.0, 28.0),
		Vector3(0.0, 0.0, 28.0),
		Vector3(-24.0, 0.0, 28.0),
		Vector3(0.0, 0.0, 12.0),
		Vector3(34.0, 0.0, 26.0),
	], 1.18)
	add_child(res_b)
	controllers["resident_b"] = res_b

	var res_c := NPCControllerScript.new()
	res_c.setup_character("resident_c", "char_resident_c", "resident_walk", Vector3(58.0, 0.0, 16.0), 180.0, player_ref)
	res_c.set_schedule_waypoints([
		Vector3(58.0, 0.0, 16.0),
		Vector3(58.0, 0.0, -14.0),
		Vector3(38.0, 0.0, -34.0),
		Vector3(20.0, 0.0, -45.0),
		Vector3(58.0, 0.0, -14.0),
	], 1.24)
	add_child(res_c)
	controllers["resident_c"] = res_c


func refresh_for_night(night_num: int) -> void:
	var n: int = clampi(night_num, 1, 6)
	# Familiar estate residents active Nights 1–5; eerily absent on Night 6 (Part 8: The Last Patrol!)
	_set_npc_active("anna", n <= 5)
	_set_npc_active("dana", n <= 5)
	_set_npc_active("zuzana", n <= 5)
	_set_npc_active("peter", n <= 5)
	_set_npc_active("resident_a", n <= 4)
	_set_npc_active("resident_b", n <= 5)
	_set_npc_active("resident_c", n <= 3)

	# Exhausted Milan Švec discoverable alive in Hidden Apartment 47 Room on Night 6 (Ending B Rescue!)
	_set_npc_active("milan_rescue", n == 6)
	if _milan_rescue_interactable:
		_milan_rescue_interactable.monitoring = (n == 6)
		_milan_rescue_interactable.monitorable = (n == 6)


func _set_npc_active(cid: String, active: bool) -> void:
	var ctrl: Node3D = controllers.get(cid, null) as Node3D
	if ctrl:
		ctrl.visible = active
		ctrl.set_process(active)


func _find_district_interactable(iid: String) -> Area3D:
	if not district_ref or not ("interactables" in district_ref):
		return null
	for area: Area3D in district_ref.interactables:
		if is_instance_valid(area) and ("interact_id" in area) and str(area.interact_id) == iid:
			return area
	return null


func _make_npc_interactable(iid: String, itype: String, prompt: String, pos: Vector3, sz: Vector3, extra: Dictionary) -> Area3D:
	var area := Area3D.new()
	var sc := load("res://scripts/world/interactable.gd")
	if sc:
		area.set_script(sc)
	area.name = "Int_" + iid
	area.position = pos
	area.collision_layer = 2
	area.collision_mask = 0
	area.set("interact_id", iid)
	area.set("interact_type", itype)
	area.set("prompt_text", prompt)
	area.set("extra_data", extra)
	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = sz
	col.shape = bx
	area.add_child(col)
	add_child(area)
	if district_ref and district_ref.has_method("on_child_interactable"):
		district_ref.on_child_interactable(area)
	return area
