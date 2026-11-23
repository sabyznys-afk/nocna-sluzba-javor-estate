class_name EndingManager
extends Node

signal ending_sequence_started(ending_id: String, payload: Dictionary)

const CAMPAIGN_ENDINGS: Dictionary = {
	"ENDING_A": {
		"id": "ENDING_A",
		"code": "A",
		"title": "ENDING A — MORNING REPORT",
		"subtitle": "Evidence-Based Investigation",
		"dialogue_speaker": "EMERGENCY DISPATCH / DAWN REPORT",
		"dialogue_line": "You bolt the steel office door, call 158, and finish signing every page of the incident dossier. Through the lifting November fog, pulsing blue and red lights sweep across the wet asphalt of the Javor Estate.",
		"notebook_entry": "ENDING A (MORNING REPORT): Evidence dossier submitted and authorities arrived at dawn. Final glance at desk: pages 4 through 7 of the shift binder are missing.",
		"body": "You gathered the physical evidence from the garages, basement, and hidden service corridor beneath Building B, locked the Security Office from inside, contacted Novy Brod Police (158), and signed the complete incident report.\n\nAt 06:10, distant blue and red emergency vehicle lights cut through the thinning morning fog. Slowly, the six concrete apartment blocks emerge in pale cold daylight. Officers seal the subterranean Boiler corridor behind crime-scene tape.\n\nAs you walk out into the cold morning air, one final look through the Security Office window shows your open notebook resting under the glowing desk lamp — several pages cleanly torn away. The official investigation has begun.",
		"dawn_fog_end": 44.0,
		"dawn_sky": Color(0.24, 0.30, 0.38),
		"dawn_ambient": Color(0.42, 0.48, 0.56),
		"dawn_energy": 0.85,
		"emergency_flashers": true,
	},
	"ENDING_B": {
		"id": "ENDING_B",
		"code": "B",
		"title": "ENDING B — THE LAST PATROL",
		"subtitle": "Survival & Rescue — Milan Švec",
		"dialogue_speaker": "JOZEF VARGA — RADIO CH-04",
		"dialogue_line": "\"Shift complete. Return to duty.\" — Even past the outer service gate at dawn, the radio in your hand crackles with Varga's calm voice.",
		"notebook_entry": "ENDING B (THE LAST PATROL): Rescued exhausted Milan Svec from the hidden Apartment 47 maintenance room and reached the outer service gate at dawn. Varga radioed: 'Shift complete. Return to duty.'",
		"body": "Using the maintenance key, you unlocked the unmarked Apartment 47 service room beneath the Javor Estate and found former guard Milan Svec alive — pale, shivering, and exhausted, clutching his torn patrol log.\n\nSupporting him through the fog-choked service corridor and evading Roman Kral along the dark perimeter, you both push through the Outer Service Gate just as pale November dawn breaks over the pines.\n\nCatching his breath beside the road, Milan warns you quietly that the municipal records will never hold the whole truth. Before you can answer, your VHF guard radio crackles sharply to life with Jozef Varga's voice:\n\n\"Shift complete. Return to duty.\"",
		"dawn_fog_end": 34.0,
		"dawn_sky": Color(0.28, 0.25, 0.24),
		"dawn_ambient": Color(0.46, 0.40, 0.36),
		"dawn_energy": 0.72,
		"emergency_flashers": false,
	},
	"ENDING_C": {
		"id": "ENDING_C",
		"code": "C",
		"title": "ENDING C — THE NEXT GUARD",
		"subtitle": "SHIFT 01 / NOVEMBER 1996 (NIGHT 7)",
		"dialogue_speaker": "SECURITY OFFICE — ROTARY TELEPHONE",
		"dialogue_line": "Quiet morning. Martin hangs up his keys and leaves Vrátnica. Minutes later, a new guard steps inside, opens a fresh notebook reading 'SHIFT 01 — NOVEMBER 1996', and the rotary phone begins to ring.",
		"notebook_entry": "ENDING C (THE NEXT GUARD): Routine patrol report filed without exposing the hidden corridor. Next watchman receives a fresh binder marked SHIFT 01 / NOVEMBER 1996.",
		"body": "You accepted Supervisor Varga's assurances, logged a quiet routine shift without pressing deeper into the hidden corridor, and left the master key ring hanging inside Vrátnica.\n\nThe following morning in Nový Brod is damp and completely ordinary. Martin Kováč steps past the wet iron gate and disappears toward the bus stop.\n\nShortly before 22:00, a new temporary night watchman unlocks Vrátnica, sets down his thermos, and opens a fresh paper notebook waiting under the desk lamp:\n\nSHIFT 01 — NOVEMBER 1996\n\nHe picks up the estate keys. On the corner of the wooden desk, the black rotary telephone starts ringing.",
		"dawn_fog_end": 26.0,
		"dawn_sky": Color(0.14, 0.16, 0.18),
		"dawn_ambient": Color(0.26, 0.28, 0.32),
		"dawn_energy": 0.52,
		"emergency_flashers": false,
	},
}

var _flasher_timer: float = 0.0
var _flasher_nodes: Array[OmniLight3D] = []
var _active_ending_id: String = ""


func _gs() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("GameState") if ml is SceneTree else null


func _st() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("StoryManager") if ml is SceneTree else null


func _au() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("AudioSynth") if ml is SceneTree else null


func get_ending_requirements_status() -> Dictionary:
	var gs := _gs()
	var st := _st()
	var ev_count: int = gs.evidence_items.size() if gs else 0
	var hidden_found: bool = st != null and (bool(st.get_flag("n5_hidden_corridor_unlocked", false)) or bool(st.get_flag("found_n5_hidden_plan_47", false)))
	var auth_called: bool = st != null and bool(st.get_flag("authorities_contacted", false))
	var milan_found: bool = st != null and (bool(st.get_flag("n5_milan_radio_found", false)) or bool(st.get_flag("n6_milan_found", false)))
	var has_keys: bool = gs != null and (gs.has_key("key_service_corridor") or gs.has_key("key_estate_master"))
	var milan_rescued: bool = st != null and bool(st.get_flag("milan_rescued", false))

	return {
		"evidence_count": ev_count,
		"hidden_corridor_discovered": hidden_found,
		"authorities_contacted": auth_called,
		"milan_found": milan_found,
		"has_service_keys": has_keys,
		"milan_rescued": milan_rescued,
		"can_ending_a": (ev_count >= 4 and hidden_found),
		"can_ending_b": (milan_found and has_keys and milan_rescued),
		"can_ending_c": true,
	}


func evaluate_campaign_ending(explicit_choice: String = "") -> String:
	var req: Dictionary = get_ending_requirements_status()
	if explicit_choice == "ENDING_B" or explicit_choice == "rescue_milan" or explicit_choice == "apartment_47":
		if bool(req.get("milan_rescued", false)) or explicit_choice == "ENDING_B":
			return "ENDING_B"
	if explicit_choice == "ENDING_A" or explicit_choice == "morning_report" or explicit_choice == "report":
		if bool(req.get("can_ending_a", false)) or explicit_choice == "ENDING_A":
			return "ENDING_A"
	if explicit_choice == "ENDING_C" or explicit_choice == "next_guard" or explicit_choice == "next_shift":
		return "ENDING_C"

	# Gameplay-driven automatic resolution when choice is omitted
	if bool(req.get("can_ending_b", false)):
		return "ENDING_B"
	if bool(req.get("can_ending_a", false)) and bool(req.get("authorities_contacted", false)):
		return "ENDING_A"
	return "ENDING_C"


func execute_ending(ending_id: String, world_builder: Node3D, hud: Node, player: Node3D = null) -> Dictionary:
	var eid: String = ending_id if CAMPAIGN_ENDINGS.has(ending_id) else evaluate_campaign_ending(ending_id)
	var data: Dictionary = CAMPAIGN_ENDINGS[eid]
	_active_ending_id = eid

	var gs := _gs()
	var st := _st()
	var au := _au()

	# 1. Record unique notebook entry & save-state persistence
	if gs:
		gs.add_notebook_entry(str(data["title"]), str(data["notebook_entry"]), "FINAL SHIFT RECORD")
		gs.story_flags["campaign_ending_id"] = eid
		if not (eid in gs.unlocked_endings):
			gs.unlocked_endings.append(eid)
		gs.current_ending = str(data["code"])
		gs.save_run()
		gs.save_meta()
	if st:
		st.active_ending_id = eid
		st.set_flag("ending_" + eid.to_lower(), true)
		st.add_personal_note(str(data["notebook_entry"]))

	# 2. Apply unique 3D environmental dawn lighting, fog lift & emergency vehicle lights
	_apply_ending_environment(data, world_builder, player)

	# 3. Play ending-specific audio cues
	if au:
		match eid:
			"ENDING_A":
				au.play_sfx("door_seal", -4.0)
				au.play_sfx("distant_tram", -8.0, 1.05)
			"ENDING_B":
				au.play_sfx("radio_squelch", -3.0)
				au.play_sfx("door_creak", -6.0)
				var vm: Node = get_parent().get_node_or_null("VoiceAssetManager") if get_parent() else null
				if vm and vm.has_method("play_voice_line"):
					vm.play_voice_line("radio_varga_end_b", Vector3.ZERO, true)
			"ENDING_C":
				au.play_sfx("keys_jingle", -5.0)
				au.play_sfx("phone_ring", -3.0)

	# 4. Present unique ending modal + dawn visuals on HUD
	if hud:
		if hud.has_method("set_crt_clean_dawn"):
			hud.set_crt_clean_dawn()
		if hud.has_method("show_dialogue"):
			hud.show_dialogue(str(data["dialogue_speaker"]), str(data["dialogue_line"]), 9.5, str(data["subtitle"]))
		if hud.has_method("open_javor_ending_modal"):
			hud.open_javor_ending_modal(data)

	emit_signal("ending_sequence_started", eid, data)
	return data


func _apply_ending_environment(data: Dictionary, world_builder: Node3D, player: Node3D) -> void:
	for fl: OmniLight3D in _flasher_nodes:
		if is_instance_valid(fl):
			fl.queue_free()
	_flasher_nodes.clear()

	if not world_builder or not ("district" in world_builder) or world_builder.district == null:
		return
	var dist: Node3D = world_builder.district as Node3D
	var we: WorldEnvironment = dist.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment.fog_depth_end = float(data.get("dawn_fog_end", 36.0))
		we.environment.background_color = data.get("dawn_sky", Color(0.22, 0.28, 0.35))
		we.environment.fog_light_color = data.get("dawn_sky", Color(0.22, 0.28, 0.35))
		we.environment.ambient_light_color = data.get("dawn_ambient", Color(0.38, 0.44, 0.50))
		we.environment.ambient_light_energy = float(data.get("dawn_energy", 0.72))

	# Ending A: Pulsing blue & red emergency vehicle lights cutting through lifting dawn fog outside Vrátnica!
	if bool(data.get("emergency_flashers", false)):
		for spec: Array in [
			[Vector3(-6.0, 2.2, -64.0), Color(0.12, 0.42, 1.0)],
			[Vector3(-3.0, 2.2, -65.0), Color(1.0, 0.14, 0.14)],
		]:
			var el := OmniLight3D.new()
			el.name = "EmergencyDawnLight"
			el.position = spec[0]
			el.light_color = spec[1]
			el.light_energy = 5.0
			el.omni_range = 28.0
			dist.add_child(el)
			_flasher_nodes.append(el)

	# Ending B: Position dawn vantage near Outer Service Gate
	if str(data.get("id", "")) == "ENDING_B" and player:
		player.global_position = Vector3(-32.0, 0.2, 59.0)
	# Ending C: Quiet Security Office desk vantage
	elif str(data.get("id", "")) == "ENDING_C" and player:
		player.global_position = Vector3(-18.2, 0.2, -56.4)


func _process(delta: float) -> void:
	if _flasher_nodes.size() >= 2:
		_flasher_timer += delta * 6.5
		var phase: bool = int(floor(_flasher_timer)) % 2 == 0
		if is_instance_valid(_flasher_nodes[0]):
			_flasher_nodes[0].light_energy = 6.5 if phase else 0.4
		if is_instance_valid(_flasher_nodes[1]):
			_flasher_nodes[1].light_energy = 0.4 if phase else 6.5
