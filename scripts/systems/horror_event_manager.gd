class_name HorrorEventManager
extends Node3D

const InteractableNode = preload("res://scripts/world/interactable.gd")

signal horror_event_triggered(event_code: String, description: String)

var district_ref: Node3D
var player_ref: Node3D
var hud_ref: Node

var triggered_events: Dictionary = {}
var inspected_clues: Dictionary = {}

# Physical crime-scene nodes spawned into the district
var blood_trail_root: Node3D
var blood_drops: Array[MeshInstance3D] = []
var park_belongings_node: Node3D
var victim_body_node: Node3D
var victim_interact_area: Area3D
var blood_interact_area: Area3D
var belongings_interact_area: Area3D

var _upstairs_step_timer: float = 0.0
var _ambient_sound_timer: float = 18.0
var _blood_illuminated_sec: float = 0.0
var _garage07_seen_once: bool = false


func _gs() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("GameState") if ml is SceneTree else null


func _au() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("AudioSynth") if ml is SceneTree else null


func _st() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("StoryManager") if ml is SceneTree else null


func setup_horror_events(district: Node3D, player: Node3D, hud: Node) -> void:
	name = "HorrorEventManager"
	district_ref = district
	player_ref = player
	hud_ref = hud
	_build_physical_crime_evidence()
	refresh_for_night()


func get_registered_event_codes() -> PackedStringArray:
	return PackedStringArray([
		"EVENT_A_UPSTAIRS_FOOTSTEPS",
		"EVENT_B_AJAR_DAMAGED_DOOR",
		"EVENT_C_BLOOD_TRAIL",
		"EVENT_D_ABANDONED_BELONGINGS",
		"EVENT_E_CURTAIN_WATCHER",
		"EVENT_F_OFFICE_LATCH_NOTEBOOK",
		"EVENT_G_GARAGE07_EXTINGUISH",
		"EVENT_H_BODY_DISCOVERY",
	])


func _build_physical_crime_evidence() -> void:
	# Event C: Dark blood trail near Block F / Boiler Basement threshold (-65.5, 0.02, 16.0 -> -69.5, -2.0, 16.0)
	blood_trail_root = Node3D.new()
	blood_trail_root.name = "EventC_BloodTrail"
	blood_trail_root.position = Vector3(-65.8, 0.02, 16.0)
	add_child(blood_trail_root)

	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.24, 0.025, 0.025)
	bmat.roughness = 0.25
	bmat.metallic = 0.15
	var offsets := [
		Vector3(0.0, 0.01, -0.15),
		Vector3(-0.35, 0.01, 0.08),
		Vector3(-0.72, 0.01, -0.05),
		Vector3(-1.15, -0.18, 0.12),
		Vector3(-1.60, -0.45, -0.04),
	]
	for i: int in range(offsets.size()):
		var drop := MeshInstance3D.new()
		drop.name = "BloodDrop_%d" % i
		var cyl := CylinderMesh.new()
		var r: float = 0.09 + float(i % 2) * 0.04
		cyl.top_radius = r
		cyl.bottom_radius = r
		cyl.height = 0.006
		cyl.material = bmat
		drop.mesh = cyl
		drop.position = offsets[i]
		blood_trail_root.add_child(drop)
		blood_drops.append(drop)

	blood_interact_area = _create_clue_area(
		"crime_event_c_blood",
		"[E] Inspect Fresh Blood Drops on Basement Threshold",
		Vector3(-65.8, 0.55, 16.0),
		Vector3(1.8, 1.4, 1.8),
		"EVENT_C_BLOOD_TRAIL"
	)

	# Event D: Abandoned personal belongings beside quiet Central Park bench (-6.5, 0.02, -3.6)
	park_belongings_node = Node3D.new()
	park_belongings_node.name = "EventD_AbandonedBelongings"
	park_belongings_node.position = Vector3(-6.2, 0.02, -3.55)
	add_child(park_belongings_node)
	_attach_glb(park_belongings_node, "res://assets/models/crime_evidence_bag.glb")

	belongings_interact_area = _create_clue_area(
		"crime_event_d_belongings",
		"[E] Inspect Abandoned Shopping Bag, Scarf & Dropped Keys",
		Vector3(-6.2, 0.55, -3.55),
		Vector3(1.6, 1.3, 1.6),
		"EVENT_D_ABANDONED_BELONGINGS"
	)

	# Event H: Deceased Resident / Guard Discovery on Night 4+ in isolated Block F lower service alcove (-88.5, -4.0, 16.0)
	victim_body_node = Node3D.new()
	victim_body_node.name = "EventH_CrimeVictimBody"
	victim_body_node.position = Vector3(-88.5, -3.98, 17.1)
	victim_body_node.rotation_degrees = Vector3(0.0, 14.0, 0.0)
	add_child(victim_body_node)
	_attach_glb(victim_body_node, "res://assets/models/crime_victim_body.glb")

	victim_interact_area = _create_clue_area(
		"crime_event_h_body",
		"[E] Examine Motionless Body & Signs of Struggle (Record Evidence)",
		Vector3(-88.5, -3.2, 16.8),
		Vector3(2.2, 1.8, 2.0),
		"EVENT_H_BODY_DISCOVERY"
	)


func _create_clue_area(iid: String, prompt: String, pos: Vector3, sz: Vector3, ev_code: String) -> Area3D:
	var area: Area3D = InteractableNode.new()
	area.name = "Int_" + iid
	area.interact_id = iid
	area.interact_type = "crime_clue"
	area.prompt_text = prompt
	area.extra_data = {"event_code": ev_code, "manager": self}
	area.position = pos
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = sz
	col.shape = box
	area.add_child(col)
	add_child(area)
	if district_ref and district_ref.has_method("on_child_interactable"):
		district_ref.on_child_interactable(area)
	return area


func _attach_glb(parent: Node3D, path: String) -> void:
	if ResourceLoader.exists(path):
		var sc: PackedScene = load(path)
		if sc:
			var inst := sc.instantiate()
			if inst is Node3D:
				parent.add_child(inst)


func refresh_for_night() -> void:
	var gs := _gs()
	var n: int = gs.current_night if gs else 1
	# Event H body discovery appears from Night 4 onwards (or when explicitly triggered)
	var show_body: bool = (n >= 4) or triggered_events.has("EVENT_H_BODY_DISCOVERY")
	if victim_body_node:
		victim_body_node.visible = show_body
	if victim_interact_area:
		victim_interact_area.monitoring = show_body
		victim_interact_area.monitorable = show_body


func trigger_event(event_code: String) -> bool:
	var au := _au()
	var gs := _gs()
	var st := _st()
	triggered_events[event_code] = true

	match event_code:
		"EVENT_A_UPSTAIRS_FOOTSTEPS":
			if au:
				au.play_sfx("upstairs_run", -5.0, 0.96)
			if hud_ref and hud_ref.has_method("show_audio_cue_caption"):
				hud_ref.show_audio_cue_caption("Heavy footsteps above ceiling — stopping when you stop")
		"EVENT_B_AJAR_DAMAGED_DOOR":
			if district_ref and district_ref.get("door_manager") != null:
				var dm: Node = district_ref.get("door_manager")
				var door: Variant = dm.doors.get("blocka_flat2f_door", dm.doors.get("delivery_service_door", null))
				if door and door.has_method("set_slightly_ajar"):
					door.set_slightly_ajar(-18.0, true)
			if au:
				au.play_sfx("breathing_door", -6.5, 1.0)
		"EVENT_C_BLOOD_TRAIL":
			if gs and gs.has_method("add_notebook_entry"):
				gs.add_notebook_entry("CRIME EVIDENCE", "Spotted dark blood drops leading down the service stairs toward Block F basement.", "Block F Service Threshold")
		"EVENT_D_ABANDONED_BELONGINGS":
			if gs and gs.has_method("add_notebook_entry"):
				gs.add_notebook_entry("CRIME EVIDENCE", "Found an abandoned shopping bag, burgundy scarf, and dropped keys beside the park bench. Signs of a sudden struggle.", "Central Park")
		"EVENT_E_CURTAIN_WATCHER":
			if district_ref and district_ref.get("dynamic_nodes") != null:
				var dnodes: Dictionary = district_ref.get("dynamic_nodes")
				if dnodes.has("event_E_watcher") and dnodes["event_E_watcher"] is Node3D:
					(dnodes["event_E_watcher"] as Node3D).visible = false
		"EVENT_F_OFFICE_LATCH_NOTEBOOK":
			if district_ref and district_ref.get("door_manager") != null:
				var dm2: Node = district_ref.get("door_manager")
				var sdoor: Variant = dm2.doors.get("sec_office_door", null)
				if sdoor and not sdoor.is_locked and sdoor.has_method("set_slightly_ajar"):
					sdoor.set_slightly_ajar(-15.0, true)
				elif sdoor and sdoor.is_locked and sdoor.has_method("jiggle_locked_handle"):
					sdoor.jiggle_locked_handle()
		"EVENT_G_GARAGE07_EXTINGUISH":
			if district_ref:
				var gmod: Node = district_ref.get_node_or_null("GarageComplex")
				if gmod:
					var slit: Node3D = gmod.get_node_or_null("Garage07_LightSlit") as Node3D
					if slit:
						slit.visible = false
			if au:
				au.play_sfx("switch_click", -5.5, 0.85)
		"EVENT_H_BODY_DISCOVERY":
			if victim_body_node:
				victim_body_node.visible = true
			if victim_interact_area:
				victim_interact_area.monitoring = true
				victim_interact_area.monitorable = true
			if gs and gs.has_method("add_notebook_entry"):
				gs.add_notebook_entry("BODY DISCOVERY", "CRITICAL EVIDENCE: Found Milan Švec's motionless body in the lower service corridor. Overturned stool, bruised collar, and a key scratch pointing to Apartment 47.", "Block F Service Basement")
			if st and st.has_method("set_flag"):
				st.set_flag("discovered_crime_victim_body", true)

	emit_signal("horror_event_triggered", event_code, "Triggered " + event_code)
	return true


func inspect_crime_clue(event_code: String) -> String:
	inspected_clues[event_code] = true
	trigger_event(event_code)
	match event_code:
		"EVENT_C_BLOOD_TRAIL":
			return "Fresh dark blood drops on the concrete steps. Someone was dragged or fled into the basement."
		"EVENT_D_ABANDONED_BELONGINGS":
			return "A resident's shopping bag, scarf, and keys dropped mid-stride. No one is around."
		"EVENT_H_BODY_DISCOVERY":
			return "He's cold. A security clipboard and overturned stool lie beside him — someone silenced him after he found the sealed corridor."
	return "Recorded physical evidence in shift notebook."


func on_player_notebook_opened_in_office() -> void:
	if not player_ref:
		return
	var p: Vector3 = player_ref.global_position
	var in_office: bool = (p.x >= -23.0 and p.x <= -13.0 and p.z >= -60.5 and p.z <= -51.5)
	if in_office and not triggered_events.has("EVENT_F_OFFICE_LATCH_NOTEBOOK"):
		trigger_event("EVENT_F_OFFICE_LATCH_NOTEBOOK")


func _process(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	var ppos: Vector3 = player_ref.global_position
	var pvel: Vector3 = player_ref.velocity if ("velocity" in player_ref) else Vector3.ZERO
	var horiz_spd: float = Vector2(pvel.x, pvel.z).length()

	# Event A: Upstairs footsteps in Block A or Block C lobby that match player movement and stop when player stops
	var in_lobby_ac: bool = (
		(ppos.distance_to(Vector3(-32.0, 0.2, 36.0)) < 7.5 or ppos.distance_to(Vector3(38.0, 0.2, 34.0)) < 7.5)
		and ppos.y < 2.6
	)
	if in_lobby_ac and horiz_spd > 0.4:
		_upstairs_step_timer -= delta
		if _upstairs_step_timer <= 0.0:
			_upstairs_step_timer = 2.8
			trigger_event("EVENT_A_UPSTAIRS_FOOTSTEPS")

	# Event B: First time climbing near Block A 2F landing, door unlatches slightlyajar
	if not triggered_events.has("EVENT_B_AJAR_DAMAGED_DOOR") and ppos.distance_to(Vector3(-29.0, 3.5, 36.8)) < 5.5:
		trigger_event("EVENT_B_AJAR_DAMAGED_DOOR")

	# Event C: Flashlight beam revealing blood trail near Block F basement stairs
	if blood_trail_root and not triggered_events.has("EVENT_C_BLOOD_TRAIL"):
		var f_on: bool = bool(player_ref.get("flashlight_on")) and ( _gs() != null and _gs().equipped_slot == "flashlight")
		if f_on and ppos.distance_to(blood_trail_root.global_position) < 6.5:
			_blood_illuminated_sec += delta
			if _blood_illuminated_sec >= 0.45:
				trigger_event("EVENT_C_BLOOD_TRAIL")

	# Event E: Curtain watcher in Block B 5F vanishes as soon as player approaches within 16m
	if not triggered_events.has("EVENT_E_CURTAIN_WATCHER") and ppos.distance_to(Vector3(4.5, 0.2, 35.5)) < 15.0:
		trigger_event("EVENT_E_CURTAIN_WATCHER")

	# Event G: Light under Garage 07 door extinguishes when player approaches a second time
	var dist_g07: float = ppos.distance_to(Vector3(-68.8, 0.5, -54.3))
	if dist_g07 < 6.0:
		_garage07_seen_once = true
	elif _garage07_seen_once and dist_g07 > 16.0 and not triggered_events.has("EVENT_G_GARAGE07_EXTINGUISH"):
		trigger_event("EVENT_G_GARAGE07_EXTINGUISH")

	# Sound-First Horror: Occasional grounded 3D environmental sounds (car door in empty lot, metal pipe clang)
	_ambient_sound_timer -= delta
	if _ambient_sound_timer <= 0.0:
		_ambient_sound_timer = randf_range(26.0, 44.0)
		var au := _au()
		if au:
			if ppos.z < -25.0:
				au.play_sfx("car_door_distant", -11.0, randf_range(0.95, 1.03))
			else:
				au.play_sfx("metal_impact", -12.0, randf_range(0.92, 1.05))
