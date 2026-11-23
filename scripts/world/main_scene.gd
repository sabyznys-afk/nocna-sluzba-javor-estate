extends Node3D

const Blok14BuilderScript = preload("res://scripts/world/blok14_builder.gd")
const GuardControllerScript = preload("res://scripts/player/guard_controller.gd")
const GameHUDScript = preload("res://scripts/ui/hud.gd")
const HorrorEventManagerScript = preload("res://scripts/systems/horror_event_manager.gd")
const AntagonistAIScript = preload("res://scripts/systems/antagonist_ai.gd")
const PatrolRouteManagerScript = preload("res://scripts/systems/patrol_route_manager.gd")
const NavigationHintManagerScript = preload("res://scripts/systems/navigation_hint_manager.gd")
const NPCScheduleManagerScript = preload("res://scripts/systems/npc_schedule_manager.gd")
const EndingManagerScript = preload("res://scripts/systems/ending_manager.gd")
const RetroRenderingScript = preload("res://scripts/systems/retro_rendering_controller.gd")
const StylizedLightingScript = preload("res://scripts/systems/stylized_lighting_controller.gd")
const CompanionGuardScript = preload("res://scripts/systems/companion_guard_controller.gd")
const VoiceAssetManagerScript = preload("res://scripts/systems/voice_asset_manager.gd")
const AmbientSpeechManagerScript = preload("res://scripts/systems/ambient_speech_manager.gd")
const DistrictNavigationScript = preload("res://scripts/systems/district_navigation.gd")
const TutorialManagerScript = preload("res://scripts/systems/tutorial_manager.gd")

var world_builder: Node3D
var player: CharacterBody3D
var hud: Node
var horror_events: Node3D
var antagonist_ai: Node3D
var patrol_route_mgr: Node
var nav_hint_mgr: Node3D
var npc_schedule_mgr: Node3D
var ending_mgr: Node
var retro_render: Node
var stylized_lighting: Node
var companion_guard: Node3D
var voice_mgr: Node3D
var ambient_speech: Node3D
var district_nav: Node3D
var tutorial_mgr: Node
var _is_seated_in_office: bool = false
var _pre_seat_pos: Vector3 = Vector3.ZERO
var _tut_start_pos: Vector3 = Vector3.ZERO
var _tut_start_yaw: float = 0.0
var _n6_blackout_triggered: bool = false

var _pending_choice_context: String = ""
var _clocks_stamped_this_night: Array[String] = []
var _last_zone_id: String = ""
var _dev_browser_layer: CanvasLayer = null


func _ready() -> void:
	world_builder = Blok14BuilderScript.new()
	world_builder.name = "Blok14World"
	add_child(world_builder)
	world_builder.build_world()

	player = GuardControllerScript.new()
	player.name = "GuardPlayer"
	player.position = world_builder.get_player_spawn_position()
	player.surface_lookup_cb = Callable(world_builder, "get_surface_for_position")
	add_child(player)

	if world_builder.animation_hub:
		world_builder.animation_hub.set_player_ref(player)

	hud = GameHUDScript.new()
	hud.name = "GameHUD"
	add_child(hud)

	player.interactable_focused.connect(_on_focus_changed)
	player.interactable_triggered.connect(_on_interactable_triggered)
	player.bunker_zone_changed.connect(hud.set_bunker_monochrome)
	player.taser_fired.connect(_on_taser_fired)
	player.gear_switched.connect(_on_gear_switched)
	if player.has_signal("flashlight_toggled"):
		player.flashlight_toggled.connect(func(is_on: bool):
			if hud and hud.has_method("set_flashlight_power_state"):
				hud.set_flashlight_power_state(is_on)
			if GameState.current_night == 1 and patrol_route_mgr:
				patrol_route_mgr.complete_tutorial_step("flashlight")
			if tutorial_mgr and tutorial_mgr.has_method("notify_flashlight_toggled"):
				tutorial_mgr.notify_flashlight_toggled(is_on)
		)
	if player.has_signal("radio_used"):
		player.radio_used.connect(func():
			if tutorial_mgr and tutorial_mgr.has_method("notify_radio_used"):
				tutorial_mgr.notify_radio_used()
			elif voice_mgr:
				voice_mgr.play_voice_line("radio_dispatch_02", Vector3.ZERO, false)
		)
	if player.has_signal("door_lock_toggled"):
		player.door_lock_toggled.connect(func(_did: String, _lk: bool):
			if tutorial_mgr and tutorial_mgr.has_method("notify_door_lock_toggled"):
				tutorial_mgr.notify_door_lock_toggled()
		)
	if player.stamina_mgr:
		player.stamina_mgr.stamina_changed.connect(func(v: float, ex: bool):
			hud.update_player_vitals(v, ex, player.sanity_mgr.sanity if player.sanity_mgr else GameState.sanity, player.sanity_mgr.current_stage if player.sanity_mgr else "HIGH", player.headphone_mgr.headphones_on if player.headphone_mgr else GameState.headphones_on)
		)
	if player.sanity_mgr:
		player.sanity_mgr.sanity_changed.connect(func(v: float, st: String):
			hud.update_player_vitals(player.stamina_mgr.stamina if player.stamina_mgr else 100.0, player.stamina_mgr.is_exhausted if player.stamina_mgr else false, v, st, player.headphone_mgr.headphones_on if player.headphone_mgr else GameState.headphones_on)
		)
	if player.headphone_mgr:
		player.headphone_mgr.headphones_toggled.connect(func(w: bool):
			if GameState.current_night == 1 and patrol_route_mgr:
				patrol_route_mgr.complete_tutorial_step("headphones")
			if tutorial_mgr and tutorial_mgr.has_method("notify_headphones_toggled"):
				tutorial_mgr.notify_headphones_toggled(w)
			hud.show_toast("WALKMAN ON — World audio muffled (+stress relief, -awareness)" if w else "HEADPHONES OFF — Ambient & environmental audio clear")
			hud.update_player_vitals(player.stamina_mgr.stamina if player.stamina_mgr else 100.0, player.stamina_mgr.is_exhausted if player.stamina_mgr else false, player.sanity_mgr.sanity if player.sanity_mgr else GameState.sanity, player.sanity_mgr.current_stage if player.sanity_mgr else "HIGH", w)
		)
		player.headphone_mgr.stalker_jumpscare_triggered.connect(_on_stalker_jumpscare)
	player.equipment_action_note.connect(func(txt: String): hud.show_toast(txt))
	hud.incident_note_submitted.connect(_on_incident_note_submitted)

	hud.modal_closed.connect(_on_modal_closed)
	hud.cctv_cycle_requested.connect(_on_cctv_cycle)
	hud.cctv_select_requested.connect(_on_cctv_select)
	hud.cctv_log_requested.connect(_on_cctv_log)
	hud.choice_made.connect(_on_choice_made)
	hud.dawn_submitted.connect(_on_dawn_submitted)
	hud.pause_menu_requested.connect(_on_pause_menu_action)
	hud.anomaly_checked_off.connect(_on_notebook_anomaly_checked)
	hud.notebook_opened_changed.connect(_on_notebook_opened_changed)
	hud.save_slot_requested.connect(_on_save_slot_requested)
	hud.load_slot_requested.connect(_on_load_slot_requested)
	if hud.has_signal("hotbar_slot_selected"):
		hud.hotbar_slot_selected.connect(func(slot_id: String):
			if player:
				player.switch_gear(slot_id)
		)
	if hud.has_signal("tutorial_reopen_requested"):
		hud.tutorial_reopen_requested.connect(func():
			if tutorial_mgr and tutorial_mgr.has_method("begin_tutorial"):
				tutorial_mgr.begin_tutorial(true)
		)
	if hud.has_signal("notebook_section_viewed"):
		hud.notebook_section_viewed.connect(func(sidx: int):
			if tutorial_mgr and tutorial_mgr.has_method("notify_notebook_section_viewed"):
				tutorial_mgr.notify_notebook_section_viewed(sidx)
		)

	horror_events = HorrorEventManagerScript.new()
	add_child(horror_events)
	horror_events.setup_horror_events(world_builder, player, hud)

	antagonist_ai = AntagonistAIScript.new()
	add_child(antagonist_ai)
	antagonist_ai.setup_antagonist(world_builder, player)
	antagonist_ai.office_door_banged.connect(func():
		hud.show_dialogue("SECURITY OFFICE DOOR!", "Something heavy just slammed against the bolted steel door from outside!", 5.0)
	)

	# Prompt 06 Core Campaign, 3-Layer Navigation, Living NPC Schedules & 3-Ending Architecture
	patrol_route_mgr = PatrolRouteManagerScript.new()
	patrol_route_mgr.name = "PatrolRouteManager"
	add_child(patrol_route_mgr)
	patrol_route_mgr.load_from_game_state()
	patrol_route_mgr.checkpoint_visited.connect(func(_n: int, cp_id: String):
		var acp: Dictionary = patrol_route_mgr.get_active_checkpoint()
		if str(acp.get("id", "")) == cp_id:
			hud.show_toast("Reached %s — inspect carefully [E] to log checkpoint." % str(acp.get("name", cp_id)))
		hud.refresh_logbook_content()
	)
	patrol_route_mgr.checkpoint_completed.connect(func(_n: int, cp_id: String):
		if nav_hint_mgr and nav_hint_mgr.has_method("notify_progress_made"):
			nav_hint_mgr.notify_progress_made()
		var nxt: Dictionary = patrol_route_mgr.get_active_checkpoint()
		if not nxt.is_empty() and str(nxt.get("id", "")) != cp_id:
			hud.show_toast("Checkpoint logged ✓ — Next: #%d %s (Check Map [TAB/N])" % [int(nxt.get("num", 1)), str(nxt.get("name", ""))])
		hud.refresh_logbook_content()
	)
	patrol_route_mgr.tutorial_step_completed.connect(func(_sid: String, next_hint: String):
		if not next_hint.is_empty():
			hud.show_toast(next_hint)
		hud.refresh_logbook_content()
	)

	# Prompt 07 Core Voice Registry, Spatial Ambient Conversations, Physical Companion Jozef Varga, PS1 Renderer & Lighting!
	voice_mgr = VoiceAssetManagerScript.new()
	add_child(voice_mgr)

	ambient_speech = AmbientSpeechManagerScript.new()
	add_child(ambient_speech)
	ambient_speech.setup_ambient_speech(voice_mgr, player)

	companion_guard = CompanionGuardScript.new()
	add_child(companion_guard)
	companion_guard.setup_companion(world_builder.district if world_builder else self, player, voice_mgr)
	companion_guard.dialogue_spoken.connect(func(sp: String, tx: String, _vid: String):
		hud.show_dialogue(sp, tx, 8.0, "Senior Security Guard — Mentor")
	)
	companion_guard.checkpoint_guided.connect(func(_sid: String):
		if companion_guard.patrol_completed and tutorial_mgr and tutorial_mgr.has_method("notify_companion_patrol_completed"):
			tutorial_mgr.notify_companion_patrol_completed()
	)
	companion_guard.state_changed.connect(func(nst: String):
		if nst == "ENDING_PATROL" and companion_guard.patrol_completed and tutorial_mgr and tutorial_mgr.has_method("notify_companion_patrol_completed"):
			tutorial_mgr.notify_companion_patrol_completed()
	)

	# Prompt 08 Part 2: Real baked estate NavigationMesh + Developer F8 Navigation Debugger!
	district_nav = DistrictNavigationScript.new()
	add_child(district_nav)
	district_nav.setup_navigation(world_builder.district if world_builder else self, companion_guard)

	# Prompt 08 Part 3: Complete 8-Stage Interactive First-Time Tutorial guided by Jozef Varga!
	tutorial_mgr = TutorialManagerScript.new()
	add_child(tutorial_mgr)
	tutorial_mgr.setup_tutorial(player, companion_guard, hud, voice_mgr, patrol_route_mgr)

	nav_hint_mgr = NavigationHintManagerScript.new()
	add_child(nav_hint_mgr)
	nav_hint_mgr.setup_navigation(patrol_route_mgr, player, companion_guard)
	nav_hint_mgr.lost_player_hint_triggered.connect(func(hint_msg: String, _cp_id: String):
		AudioSynth.play_sfx("radio_squelch", -7.0)
		if voice_mgr:
			voice_mgr.play_voice_line("radio_varga_check_01")
		hud.show_dialogue("JOZEF VARGA — RADIO CH-04", hint_msg, 7.5, "Security Supervisor")
	)
	nav_hint_mgr.clear_direction_cue.connect(func(cue_txt: String):
		hud.show_toast(cue_txt)
	)

	npc_schedule_mgr = NPCScheduleManagerScript.new()
	add_child(npc_schedule_mgr)
	npc_schedule_mgr.setup_schedules(world_builder.district if world_builder else self, player)

	ending_mgr = EndingManagerScript.new()
	ending_mgr.name = "EndingManager"
	add_child(ending_mgr)

	# Prompt 07 PS1 Visual & Shadow Pipeline applied to the complete 3D estate + characters!
	retro_render = RetroRenderingScript.new()
	add_child(retro_render)
	retro_render.setup_retro_rendering(self, hud.crt_material if hud else null)

	stylized_lighting = StylizedLightingScript.new()
	add_child(stylized_lighting)
	stylized_lighting.setup_lighting(world_builder.district if world_builder else self, player)

	if hud.has_method("set_navigation_sources"):
		hud.set_navigation_sources(patrol_route_mgr, nav_hint_mgr)

	_tut_start_pos = player.global_position
	_tut_start_yaw = player.rotation.y

	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		sm.is_tracking_playtime = true
	_begin_shift_presentation()


func _process(delta: float) -> void:
	if player and world_builder:
		hud.player_world_pos = player.global_position
		if hud.has_method("set_flashlight_power_state") and hud._flashlight_powered != player.flashlight_on:
			hud.set_flashlight_power_state(player.flashlight_on)
			if GameState.current_night == 1 and patrol_route_mgr:
				patrol_route_mgr.complete_tutorial_step("flashlight")
		world_builder.set_rain_follow_position(player.global_position)
		if world_builder.get("fog_controller") != null:
			world_builder.fog_controller.update_fog(delta, player.global_position, GameState.current_night)
		var zinfo: Dictionary = world_builder.get_zone_for_position(player.global_position)
		var zid: String = str(zinfo.get("id", ""))
		if zid != _last_zone_id:
			_last_zone_id = zid
			hud.set_zone_label(str(zinfo.get("label", "")))
			GameState.mark_zone_visited(zid)
			if world_builder.get("fog_controller") != null:
				world_builder.fog_controller.apply_zone_atmosphere(zid, GameState.current_night)
			hud.refresh_tutorial_banner()
		# Check patrol checkpoint proximity (distinguishes visiting vs inspecting!) & Night 1 interactive onboarding
		if patrol_route_mgr:
			patrol_route_mgr.check_player_proximity(player.global_position, GameState.current_night)
			if GameState.current_night == 1 and not GameState.tutorial_completed:
				if player.global_position.distance_to(_tut_start_pos) > 1.2:
					patrol_route_mgr.complete_tutorial_step("move")
				if absf(wrapf(player.rotation.y - _tut_start_yaw, -PI, PI)) > 0.35:
					patrol_route_mgr.complete_tutorial_step("look")


func _begin_shift_presentation() -> void:
	_clocks_stamped_this_night.clear()
	_last_zone_id = ""
	_n6_blackout_triggered = false
	var st := get_node_or_null("/root/StoryManager")
	if st and st.has_method("set_chapter"):
		st.set_chapter(GameState.current_night)
	world_builder.refresh_night_state()
	if world_builder and world_builder.district and world_builder.district.has_method("set_estate_blackout"):
		world_builder.district.set_estate_blackout(false)
	if stylized_lighting and stylized_lighting.has_method("set_blackout"):
		stylized_lighting.set_blackout(false)
	if world_builder.door_manager and world_builder.door_manager.has_method("apply_saved_states"):
		world_builder.door_manager.apply_saved_states()
	if horror_events and horror_events.has_method("refresh_for_night"):
		horror_events.refresh_for_night()
	if npc_schedule_mgr and npc_schedule_mgr.has_method("refresh_for_night"):
		npc_schedule_mgr.refresh_for_night(GameState.current_night)
	if companion_guard and companion_guard.has_method("refresh_for_night"):
		companion_guard.refresh_for_night(GameState.current_night)
	if patrol_route_mgr and patrol_route_mgr.has_method("load_from_game_state"):
		patrol_route_mgr.load_from_game_state()
	if nav_hint_mgr and nav_hint_mgr.has_method("notify_progress_made"):
		nav_hint_mgr.notify_progress_made()
	if antagonist_ai and antagonist_ai.has_method("set_blackout_hunt"):
		antagonist_ai.set_blackout_hunt(false)
	AudioSynth.start_ambient()
	AudioSynth.set_distortion_audio(GameState.signal_distortion)
	if GameState.current_night == 1:
		AudioSynth.play_sfx("phone_ring", -8.0)
	elif GameState.current_night == 6:
		if st:
			st.set_flag("night6_started", true)
	hud.show_chapter_card(GameState.current_night)
	var rt: Dictionary = patrol_route_mgr.get_route(GameState.current_night) if patrol_route_mgr else {}
	if GameState.current_night == 1 and tutorial_mgr:
		tutorial_mgr.start_if_needed(1)
	if GameState.current_night == 1 and tutorial_mgr and tutorial_mgr.active:
		pass
	elif GameState.current_night == 1 and not GameState.tutorial_completed:
		hud.show_dialogue("MARTIN KOVAC", "November 18, 1996 — 22:00. First night shift at the Javor Estate. Speak with Supervisor Jozef Varga inside the Security Office [E], then open your shift notebook [TAB/N] to see the patrol map.", 8.5, "Night Security Guard")
	else:
		var brief_txt: String = str(rt.get("briefing", st.get_chapter_data(GameState.current_night).get("summary", "") if st else ""))
		hud.show_dialogue("MARTIN KOVAC", brief_txt if not brief_txt.is_empty() else "22:00. Open your notebook [TAB/N] to check tonight's patrol route.", 6.5, "Night Security Guard")
	hud.refresh_tutorial_banner()


func _on_focus_changed(item: Area3D) -> void:
	if item:
		hud.set_prompt(item.get_prompt())
	else:
		hud.set_prompt("")


func _on_modal_closed() -> void:
	player.set_input_locked(false)


func _on_interactable_triggered(item: Area3D) -> void:
	var iid: String = item.interact_id
	var itype: String = item.interact_type

	match itype:
		"phone":
			_handle_booth_phone()
		"clock":
			_handle_clock_stamp(iid)
		"cctv":
			_open_cctv()
		"desk":
			_handle_booth_desk()
		"door":
			_handle_door_interaction(item)
		"fusebox":
			_handle_fusebox()
		"payphone":
			_handle_payphone()
		"npc":
			_handle_milan()
		"npc_door":
			_handle_maria()
		"clue":
			_handle_clue(item)
		"radio":
			_handle_radio(item)
		"page":
			_handle_page(item)
		"antenna":
			_handle_antenna()
		"valve":
			_handle_boiler_valve()
		"red_door":
			_handle_red_door()
		"k4_core":
			_handle_k4_core()
		"jozef":
			_handle_jozef_bunker()
		"evidence":
			_handle_evidence(item)
		"mobsters":
			_handle_mobsters()
		"gate":
			_handle_main_gate()
		"battery_pickup":
			_handle_battery_pickup(item)
		"physical_door":
			_handle_physical_door(item)
		"interactive_prop":
			_handle_interactive_prop(item)
		"story_npc":
			_handle_story_npc(item)
		"companion_varga":
			_handle_companion_varga()
		"story_doc":
			_handle_story_doc(item)
		"story_tape":
			_handle_story_tape(item)
		"story_intercom":
			_handle_story_intercom()
		"story_door_47":
			_handle_story_door_47()
		"elevator":
			_handle_elevator(item)
		"office_bolt":
			_handle_office_bolt()
		"office_chair":
			_handle_office_chair()
		"office_key_cabinet":
			_handle_office_key_cabinet(item)
		"desk_lamp":
			_handle_desk_lamp(item)
		"prop_inspect":
			_handle_prop_inspect(item)
		"crime_clue":
			_handle_crime_clue(item)
		"campaign_event":
			_handle_campaign_event(item)
		"horror_hook":
			_handle_horror_hook(item)
		"anomaly":
			_open_anomaly(item.anomaly_id)
		_:
			if not item.anomaly_id.is_empty():
				_open_anomaly(item.anomaly_id)

	# Prompt 06/08: Register every completed field interaction with PatrolRouteManager & TutorialManager
	if patrol_route_mgr and not iid.is_empty():
		patrol_route_mgr.register_interaction(iid, GameState.current_night)
		if GameState.current_night == 1:
			patrol_route_mgr.complete_tutorial_step("interact")
	if tutorial_mgr and tutorial_mgr.has_method("notify_player_interacted"):
		tutorial_mgr.notify_player_interacted(iid, itype)


func _handle_physical_door(item: Area3D) -> void:
	var dnode: Variant = item.extra_data.get("door_node", null)
	if dnode == null or not is_instance_valid(dnode):
		return
	var will_open: bool = not bool(dnode.get("is_open"))
	if player and player.viewmodel:
		player.viewmodel.play_interact_door(will_open)
	var res: Dictionary = dnode.interact_toggle()
	if GameState.current_night == 1 and patrol_route_mgr:
		patrol_route_mgr.complete_tutorial_step("keys_doors")
	var msg: String = str(res.get("msg", ""))
	if not msg.is_empty():
		hud.show_toast(msg)


func _handle_campaign_event(item: Area3D) -> void:
	var eid: String = str(item.extra_data.get("event_id", item.interact_id))
	var st := get_node_or_null("/root/StoryManager")
	var n: int = GameState.current_night
	match eid:
		"n1_open_car":
			AudioSynth.play_sfx("door_creak", -7.0, 1.08)
			GameState.add_notebook_entry("PARKING LOT — OPEN CAR DOOR", "Checked slightly open Lada door in Bay 04. Only an ordinary paper shopping bag on the seat. Secured door.", "South Parking Lot")
			hud.show_dialogue("PARKING LOT — BAY 04", "The passenger door wasn't latched shut. Inside rests an ordinary paper grocery bag from Jednota — bread, milk, nothing unusual. You push the door shut.", 6.5)
		"n1_blocka_mailboxes":
			AudioSynth.play_sfx("pencil_check", -6.0)
			GameState.add_notebook_entry("BUILDING A INSPECTION", "Checked Building A entrance lock, intercom, lobby mailboxes, and basement door — all secure.", "Building A")
			hud.show_dialogue("BUILDING A LOBBY", "Aluminum mailboxes intact, intercom humming quietly, basement steel door shut. A faded notice on the board mentions a missing resident: Iveta Hrončová (34).", 7.0)
		"n1_dropped_keys":
			AudioSynth.play_sfx("keys_jingle", -5.0, 1.12)
			GameState.collect_key("key_unfamiliar_park")
			GameState.add_evidence("ev_n1_dropped_keys")
			GameState.add_notebook_entry("CENTRAL PARK — DROPPED KEYS", "Heard a metallic clink in the dense park fog near the swings. Found an unfamiliar brass utility keyring lying on the wet gravel.", "Central Park")
			hud.show_dialogue("METALLIC SOUND IN FOG", "Out of the white fog near the playground swings comes a sharp metallic clink. Nobody is visible — only a worn set of unfamiliar maintenance keys dropped on the damp gravel.", 7.5, "Evidence Added & Keys Collected")
		"n2_blockc_mud":
			AudioSynth.play_sfx("upstairs_run", -6.0)
			GameState.add_evidence("ev_n2_blockc_mud")
			GameState.add_notebook_entry("BUILDING C — MUDDY BOOT MARKS", "Investigated upper-floor footsteps in Building C. Found a 2F door slightly ajar with fresh muddy work-boot prints on the linoleum. No intruder inside.", "Building C")
			hud.show_dialogue("BUILDING C — 2ND FLOOR LANDING", "Heavy footsteps fade above you, then silence. The flat door stands two inches ajar; fresh wet mud tracks lead across the hallway linoleum, yet the flat inside is empty.", 7.5, "Evidence Logged")
		"n2_north_bootprint":
			AudioSynth.play_sfx("pencil_check", -5.5)
			GameState.add_evidence("ev_n2_north_bootprint")
			GameState.add_notebook_entry("NORTHERN PATH — CIGARETTES & BOOT PRINT", "Found freshly crushed cigarette butts and a deep heavy work-boot impression facing Building B along the northern treeline.", "Northern Path")
			hud.show_dialogue("NORTHERN PEDESTRIAN PATH", "Two damp cigarette butts and a fresh heavy work-boot print pressed into the wet mud facing Building B. Someone stood here watching the windows in the fog.", 7.0, "Evidence Logged")
		"n3_garage07_clues":
			AudioSynth.play_sfx("keys_jingle", -5.0, 0.94)
			GameState.collect_key("key_service_corridor")
			GameState.add_evidence("ev_n3_garage07_stash")
			if st:
				st.set_flag("found_n3_garage07_clues", true)
				st.complete_story_objective("j3_garages")
			GameState.add_notebook_entry("GARAGE 07 — MAINTENANCE STASH", "Discovered an old cigarette packet, a steel maintenance key (fits sub-basement service doors), a handwritten '47' scrawled in chalk, and freshly disturbed dust.", "Garage Complex")
			hud.show_dialogue("GARAGE 07 ENTRANCE", "In the disturbed dust beside the shutter: a crumpled cigarette pack, a worn maintenance key, and a hastily penciled number — '47'.", 7.5, "Maintenance Key & Evidence Collected")
		"n3_milan_cassette":
			AudioSynth.play_sfx("cassette_click", -4.0)
			if voice_mgr:
				voice_mgr.play_voice_line("milan_cassette_01")
			GameState.add_evidence("ev_n3_milan_cassette")
			if st:
				st.discover_tape("tape_03_stairwell")
				st.discover_tape("tape_04_before_shift")
				st.complete_story_objective("j3_milan_tape")
				st.trigger_night_climax(3)
			GameState.add_notebook_entry("DELIVERY ALLEY — CASSETTE 'M. ŠVEC / 12.11.96'", "Unlocked rear service storage nook behind the newsstand. Recovered cassette labeled 'M. ŠVEC / 12.11.96'. Milan speaks of Apartment 47, a hidden maintenance corridor, and someone following his patrol — cutting out sharply at 03:17.", "Delivery Alley")
			hud.show_dialogue("CASSETTE: M. ŠVEC / 12.11.96", "MILAN ŠVEC: 'Someone who worked maintenance knows every lock in Sídlisko Javor... Apartment 47 isn't a flat, it's connected to the lower service corridor. Wait—footsteps behind me—' [TAPE CUTS AT 03:17]", 9.0, "Filed in Notebook -> Discovered Evidence")
		"n4_blockb_sighting":
			AudioSynth.play_sfx("door_handle", -4.0)
			if antagonist_ai and antagonist_ai.has_method("trigger_night4_stairwell_walkaway"):
				antagonist_ai.trigger_night4_stairwell_walkaway()
			if st:
				st.record_character_interaction("roman", 4)
				st.set_flag("n4_roman_sighted", true)
				st.complete_story_objective("j4_blockb")
			GameState.add_notebook_entry("BUILDING B — STAIRWELL SIGHTING", "Saw a solid middle-aged man in a dark brown maintenance jacket near Building B stairs. He avoided eye contact and walked calmly away through the side corridor door.", "Building B")
			hud.show_dialogue("BUILDING B STAIRWELL", "A man in a dark brown maintenance jacket pauses near the lower stairs, notices your flashlight beam, avoids eye contact, and walks steadily away around the service corridor door.", 8.0, "Human Suspect Observed")
		"n4_basement_evidence":
			AudioSynth.play_sfx("pencil_check", -5.0)
			GameState.add_evidence("ev_n4_basement_scene")
			if st:
				st.set_flag("found_n4_basement_evidence", true)
			GameState.add_notebook_entry("BASEMENT CRIME EVIDENCE", "Documented disturbed storage boxes, a snapped steel padlock, a torn strip of dark brown work-jacket fabric, and a small dried blood trace along the basement wall.", "Block F Basement")
			hud.show_dialogue("BASEMENT EVIDENCE DOCUMENTED", "Overturned crates, a forced padlock lying on concrete, torn dark-brown maintenance jacket cloth snagged on wire mesh, and a small dried blood smear along the damp brick wall.", 8.0, "Physical Evidence Logged")
		"n5_hidden_plan_47":
			AudioSynth.play_sfx("page_turn", -4.5)
			GameState.collect_key("key_service_corridor")
			GameState.collect_key("key_apt_47")
			GameState.add_evidence("ev_n5_plan_47")
			if st:
				st.discover_document("doc_sealed_unit_47")
				st.set_flag("found_n5_hidden_plan_47", true)
				st.set_flag("n5_hidden_corridor_unlocked", true)
				st.complete_story_objective("j5_plans")
			GameState.add_notebook_entry("HIDDEN SERVICE CORRIDOR — 1984 PLAN", "Recovered the 1984 architectural service schematic and maintenance key. 'Apartment 47' is actually an undocumented subterranean utility room linking the boiler tunnel beneath Building B!", "Hidden Service Corridor")
			hud.show_dialogue("1984 BUILDING PLAN — APARTMENT 47", "The mystery clicks into cold focus: 'Apartment 47' was never a residential flat. It is an undocumented subterranean maintenance room hidden along this service corridor — and someone has been living and working down here.", 9.0, "Evidence & Apt 47 Key Acquired")
		"n5_iveta_discovery":
			AudioSynth.play_sfx("breathing_door", -7.0)
			GameState.add_evidence("ev_n5_iveta_discovery")
			if st:
				st.record_character_interaction("iveta", 5)
				st.set_flag("discovered_iveta_body", true)
				st.set_flag("discovered_crime_victim_body", true)
			GameState.add_notebook_entry("INCIDENT REPORT — IVETA HRONČOVÁ (34)", "Discovered missing resident Iveta Hrončová deceased in the isolated storage bay off the hidden corridor. Documented handbag, signs of struggle, damaged telephone handset, and housing document without disturbing the scene.", "Hidden Service Storage")
			hud.show_dialogue("DISCOVERY — IVETA HRONČOVÁ (AGE 34)", "Beside overturned storage boxes lies missing resident Iveta Hrončová in her faded autumn coat. Her handbag, a torn housing document, and a smashed telephone with a detached handset rest nearby. You record every detail steadily into your notebook.", 9.5, "Major Crime Evidence Logged")
		"n5_milan_radio":
			AudioSynth.play_sfx("radio_squelch", -4.0)
			if voice_mgr:
				voice_mgr.play_voice_line("milan_cassette_02")
			GameState.add_evidence("ev_n5_milan_radio")
			if st:
				st.discover_tape("tape_05_unit_47")
				st.set_flag("n5_milan_radio_found", true)
			if antagonist_ai and antagonist_ai.has_method("trigger_night5_corridor_escape"):
				antagonist_ai.trigger_night5_corridor_escape()
			GameState.add_notebook_entry("MILAN ŠVEC'S RADIO & ESCAPE", "Found Milan's old guard radio and a fresh cassette dated yesterday — Milan may still be alive! Footsteps echoed down the corridor as a human silhouette fled through the physical steel service door.", "Hidden Service Corridor")
			hud.show_dialogue("MILAN'S RADIO & FOOTSTEPS IN CORRIDOR", "Milan Švec's scuffed VHF radio lies on a crate beside a fresh recording: 'Still locked inside Room 47... if the new guard finds this, bring the maintenance key.' Suddenly a figure bolts down the corridor and slams out through the far service door!", 9.5, "Milan Alive Lead Recorded")
		"n6_radio_warning":
			AudioSynth.play_sfx("radio_squelch", -3.0)
			if voice_mgr:
				voice_mgr.play_voice_line("roman_unknown_voice_01")
			if st:
				st.set_flag("n6_warning_received", true)
			GameState.add_notebook_entry("01:30 — UNKNOWN RADIO TRANSMISSION", "Estate is completely silent; residents absent. Unidentified voice broke through Channel 04: 'You are not walking alone.'", "Central Park")
			hud.show_dialogue("UNKNOWN TRANSMISSION — CH-04 (01:30)", "\"You are not walking alone.\" Static swallows the line. Around the dark park, not a single apartment window glows.", 8.0, "Check Office CCTV / Prepare for 03:17")
			if n == 6 and not _n6_blackout_triggered:
				_trigger_night6_blackout()
		"n6_milan_rescue":
			AudioSynth.play_sfx("door_handle", -4.0)
			if voice_mgr:
				voice_mgr.play_voice_line("milan_rescue_03", item.global_position)
			if st:
				st.set_flag("n6_milan_found", true)
				st.set_flag("milan_rescued", true)
				st.record_character_interaction("milan", 6)
			if npc_schedule_mgr:
				npc_schedule_mgr.trigger_talk("milan_rescue", 8.0)
			GameState.add_notebook_entry("APARTMENT 47 ROOM — MILAN ŠVEC FOUND ALIVE", "Unlocked unmarked Room 47 during the 03:17 blackout and found Milan Švec alive but severely exhausted. Guiding him out toward the Outer Service Gate (or lock Vrátnica & call Police 158).", "Apartment 47 Room")
			hud.show_dialogue("MILAN ŠVEC (EXHAUSTED)", "'Martin...? Thank God... Roman Král worked maintenance here until '92 — he never returned the sub-basement keys. Get me to the North Outer Service Gate before he corners us, or bolt Vrátnica and call 158!'", 9.5, "Ending B Ready at North Service Gate | Ending A Ready at Vrátnica")
		"n6_escape_gate":
			if n == 6 and st and bool(st.get_flag("milan_rescued", false)):
				if ending_mgr:
					player.set_input_locked(true)
					ending_mgr.execute_ending("ENDING_B", world_builder, hud, player)
			else:
				hud.show_dialogue("OUTER SERVICE GATE", "Heavy iron perimeter gate leading out to the northern service road. Padlocked on normal shifts.", 4.5)
	hud.refresh_logbook_content()


func _trigger_night6_blackout() -> void:
	if _n6_blackout_triggered:
		return
	_n6_blackout_triggered = true
	AudioSynth.play_sfx("power_out", -3.0)
	var st := get_node_or_null("/root/StoryManager")
	if st:
		st.trigger_night_climax(6)
		st.set_flag("n6_blackout_active", true)
	if world_builder and world_builder.district and world_builder.district.has_method("set_estate_blackout"):
		world_builder.district.set_estate_blackout(true)
	if stylized_lighting and stylized_lighting.has_method("set_blackout"):
		stylized_lighting.set_blackout(true)
	if antagonist_ai and antagonist_ai.has_method("set_blackout_hunt"):
		antagonist_ai.set_blackout_hunt(true)
	GameState.add_notebook_entry("03:17 — COMPLETE ESTATE BLACKOUT", "All streetlamps and building power died simultaneously. Dense fog outside. Roman Král is actively hunting across the estate — use flashlight, locked doors & the Hidden Service Corridor.", "Sídlisko Javor")
	hud.show_dialogue("03:17 — COMPLETE ESTATE BLACKOUT", "Every sodium lamp across Sídlisko Javor snaps dark at once. Only your flashlight beam cuts the dense fog. Heavy boots move somewhere across the wet yard — Roman Král is hunting.", 8.5, "Reach Hidden Room 47 or Secure Vrátnica")


func _handle_interactive_prop(item: Area3D) -> void:
	var pnode: Variant = item.extra_data.get("prop_node", null)
	if pnode == null or not is_instance_valid(pnode):
		return
	if player and player.viewmodel:
		player.viewmodel.play_interact_switch()
	var msg: String = str(pnode.trigger())
	if item.interact_id == "sec_desk_drawer":
		var st := get_node_or_null("/root/StoryManager")
		if st:
			st.complete_story_objective("j1_keys_radio")
	if not msg.is_empty():
		hud.show_toast(msg)


func _handle_companion_varga() -> void:
	var st := get_node_or_null("/root/StoryManager")
	GameState.complete_quest("answer_briefing")
	GameState.collect_key("key_estate_master")
	if st:
		st.record_character_interaction("varga", GameState.current_night)
		st.complete_story_objective("j1_keys_radio")
	if patrol_route_mgr and GameState.current_night == 1:
		patrol_route_mgr.complete_tutorial_step("interact")
	if tutorial_mgr and tutorial_mgr.active and tutorial_mgr.get_current_stage_id() != "first_patrol":
		var sid: String = tutorial_mgr.get_current_stage_id()
		if sid != "intro" and companion_guard and companion_guard.has_method("speak_tutorial_line"):
			var st_def: Dictionary = tutorial_mgr.STAGES[tutorial_mgr.current_stage_idx]
			companion_guard.speak_tutorial_line(str(st_def.get("dialogue", "")), str(st_def.get("voice_id", "")))
	elif companion_guard and companion_guard.has_method("interact_with_player"):
		companion_guard.interact_with_player()
	hud.refresh_logbook_content()


func _handle_story_npc(item: Area3D) -> void:
	var cid: String = str(item.extra_data.get("char_id", ""))
	var st := get_node_or_null("/root/StoryManager")
	if not st or cid.is_empty():
		return
	if npc_schedule_mgr and npc_schedule_mgr.has_method("trigger_talk"):
		npc_schedule_mgr.trigger_talk(cid, 7.0)
	var dlg: Dictionary = st.record_character_interaction(cid, GameState.current_night)
	if not dlg.is_empty():
		hud.show_dialogue(str(dlg.get("speaker", "")), str(dlg.get("text", "")), 8.0, str(dlg.get("role", "")))
		AudioSynth.play_ui_sfx("page_turn", -9.0)
	# Play native Slovak neural character voice spatially from the NPC!
	if voice_mgr and voice_mgr.has_method("play_voice_line"):
		var n: int = GameState.current_night
		if cid == "anna":
			voice_mgr.play_voice_line("anna_building_a_01" if n <= 1 else ("anna_building_a_02" if n <= 3 else "anna_building_a_03"), item.global_position)
		elif cid == "dana":
			voice_mgr.play_voice_line("dana_night_shop_01" if n <= 1 else ("dana_night_shop_02" if n <= 3 else "dana_night_shop_03"), item.global_position)
		elif cid == "varga":
			voice_mgr.play_voice_line("jozef_office_intro_01", item.global_position)
	if cid == "varga":
		GameState.complete_quest("answer_briefing")
		st.complete_story_objective("j1_keys_radio")
		GameState.collect_key("key_estate_master")
		if patrol_route_mgr:
			patrol_route_mgr.complete_tutorial_step("interact")
	elif cid == "anna":
		st.complete_story_objective("j1_patrol_park")
		st.complete_story_objective("j2_noise")
	elif cid == "dana":
		st.complete_story_objective("j1_visit_dana")
		st.complete_story_objective("j2_dana")
	elif cid == "peter":
		st.complete_story_objective("j2_playground")
	elif cid == "zuzana":
		GameState.add_notebook_entry("TRAFIKA CHECK-IN", "Spoke with Zuzana Horváthová at the Trafika window.", "Commercial Square")
	hud.refresh_logbook_content()


func _handle_story_doc(item: Area3D) -> void:
	var did: String = str(item.extra_data.get("doc_id", ""))
	var st := get_node_or_null("/root/StoryManager")
	if not st or did.is_empty():
		return
	st.discover_document(did)
	AudioSynth.play_ui_sfx("page_turn", -5.0)
	var doc: Dictionary = st.DOCUMENTS.get(did, {})
	hud.show_dialogue("DOCUMENT FOUND — " + str(doc.get("title", did)), str(doc.get("body", "")), 8.5, "Filed in Notebook -> Documents")
	if did == "doc_milan_sheet":
		st.complete_story_objective("j3_garages")
	elif did == "doc_sealed_unit_47" or did == "doc_registry_1984":
		st.complete_story_objective("j5_plans")
	hud.refresh_logbook_content()


func _handle_story_tape(item: Area3D) -> void:
	var tid: String = str(item.extra_data.get("tape_id", ""))
	var st := get_node_or_null("/root/StoryManager")
	if not st or tid.is_empty():
		return
	st.discover_tape(tid)
	AudioSynth.play_sfx("cassette_click", -4.5)
	var tp: Dictionary = st.TAPES.get(tid, {})
	hud.show_toast("CASSETTE COLLECTED: %s (Play in Notebook -> Recordings)" % str(tp.get("label", tid)))
	if tid == "tape_04_before_shift":
		st.complete_story_objective("j3_milan_tape")
		st.trigger_night_climax(3)
		hud.show_dialogue("UNLABELED MAXELL C-60", str(tp.get("transcript", "")), 9.0, "Dated 09.11.1996 — Before Your First Shift")
	hud.refresh_logbook_content()


func _handle_story_intercom() -> void:
	var st := get_node_or_null("/root/StoryManager")
	AudioSynth.play_sfx("intercom_buzz", -4.0)
	hud.show_audio_cue_caption("INTERCOM BUZZER — BUILDING B")
	if st and GameState.current_night == 2:
		st.complete_story_objective("j2_intercom")
		st.trigger_night_climax(2)
		hud.show_dialogue("BUILDING B INTERCOM — DISPLAY: [47]", "A dry burst of static answers on the line. The directory beside the glass only lists Flats 1 to 46.", 7.5, "Unlisted Apartment")
	elif st and GameState.current_night == 6:
		_open_javor_final_choice()
	else:
		hud.show_dialogue("BUILDING B INTERCOM", "Buzzers 1–46. Someone scraped a faint '47' into the aluminum edge.", 5.0)


func _handle_story_door_47() -> void:
	var st := get_node_or_null("/root/StoryManager")
	if not st:
		return
	if GameState.current_night == 4:
		st.complete_story_objective("j4_door47")
		st.trigger_night_climax(4)
		AudioSynth.play_sfx("whisper_static", -5.0)
		hud.show_dialogue("LANDING — DOOR 47", "A painted timber door marked '47' stands flush with the corridor wall. When you blink and step closer, only cracked plaster remains.", 7.5)
		if world_builder and world_builder.dynamic_nodes.has("story_door_47"):
			(world_builder.dynamic_nodes["story_door_47"] as Node3D).visible = false
	elif GameState.current_night == 6:
		_open_javor_final_choice()


func _open_javor_final_choice() -> void:
	_pending_choice_context = "javor_final_n6"
	player.set_input_locked(true)
	var req: Dictionary = ending_mgr.get_ending_requirements_status() if ending_mgr else {}
	var ev_cnt: int = int(req.get("evidence_count", 0))
	var opts: Array[Dictionary] = []
	if bool(req.get("can_ending_a", false)):
		opts.append({"id": "ENDING_A", "label": "Lock Vrátnica, Call Police (158) & Submit Evidence Dossier (%d items) — ENDING A: MORNING REPORT" % ev_cnt})
	if bool(req.get("milan_rescued", false)):
		opts.append({"id": "ENDING_B", "label": "Escort Exhausted Milan Švec Out Through Outer Service Gate — ENDING B: THE LAST PATROL"})
	opts.append({"id": "ENDING_C", "label": "Submit Normal Routine Patrol Report & Walk Away — ENDING C: THE NEXT GUARD"})
	hud.open_choice_modal("05:00 — SÍDLISKO JAVOR FINAL RESOLUTION", "The 03:17 blackout grips Sídlisko Javor. Decide how Martin Kováč concludes Shift 06 based on your gathered evidence and rescues.", opts)


func _on_save_slot_requested(slot_idx: int) -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm and sm.save_slot(slot_idx, hud.zone_label.text if hud.zone_label else "Sídlisko Javor", player.global_position):
		hud.show_toast("Shift saved to Slot #%d." % slot_idx)


func _on_load_slot_requested(slot_idx: int) -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm and sm.load_slot(slot_idx):
		_begin_shift_presentation()
		hud.show_toast("Loaded Shift Record #%d." % slot_idx)


func _on_stalker_jumpscare(threat_pos: Vector3) -> void:
	hud.trigger_jumpscare_flash()
	if player and player.sanity_mgr:
		player.sanity_mgr.adjust_sanity(-12.0)
	hud.show_dialogue(
		"STALKER IN THE DARK!",
		"Cold breath brushes your neck right behind you — wearing Walkman headphones outdoors hid the approaching footsteps!",
		5.5
	)
	if DisplayServer.get_name() != "headless" and ResourceLoader.exists("res://assets/models/entity_shadow.glb"):
		var packed: PackedScene = load("res://assets/models/entity_shadow.glb")
		if packed:
			var ghost: Node3D = packed.instantiate() as Node3D
			if ghost:
				ghost.position = threat_pos
				if player:
					ghost.look_at(player.global_position, Vector3.UP)
				add_child(ghost)
				get_tree().create_timer(1.25).timeout.connect(func():
					if is_instance_valid(ghost):
						ghost.queue_free()
				)


func _on_incident_note_submitted(note_text: String) -> void:
	var ztxt: String = hud.zone_label.text if hud and hud.zone_label else ""
	GameState.add_notebook_entry("SHIFT INCIDENT", note_text, ztxt)
	AudioSynth.play_sfx("pencil_check", -4.0)
	if player and player.viewmodel:
		player.viewmodel.play_notebook_write()
	if tutorial_mgr and tutorial_mgr.has_method("notify_notebook_note_written"):
		tutorial_mgr.notify_notebook_note_written()
	hud.refresh_logbook_content()
	hud.show_toast("Entry written in Shift Notebook.")


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("dev_asset_browser"):
		_toggle_dev_asset_browser()
	elif OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F8:
		toggle_nav_debug()


func toggle_nav_debug() -> bool:
	if district_nav and district_nav.has_method("toggle_debug"):
		var on: bool = district_nav.toggle_debug()
		if hud:
			hud.show_toast("Developer Navigation Debug: %s [F8]" % ("ON" if on else "OFF"))
		return on
	return false


func _toggle_dev_asset_browser() -> void:
	if not OS.is_debug_build():
		return
	if _dev_browser_layer and is_instance_valid(_dev_browser_layer):
		_dev_browser_layer.queue_free()
		_dev_browser_layer = null
		player.set_input_locked(hud.is_modal_open())
		return
	var packed_path := "res://tools/asset_browser/AssetManager.tscn"
	if not ResourceLoader.exists(packed_path):
		return
	var packed: PackedScene = load(packed_path)
	if not packed:
		return
	_dev_browser_layer = CanvasLayer.new()
	_dev_browser_layer.name = "DevAssetBrowserLayer"
	_dev_browser_layer.layer = 60
	add_child(_dev_browser_layer)
	var browser := packed.instantiate()
	_dev_browser_layer.add_child(browser)
	player.set_input_locked(true)
	if browser.has_signal("close_requested"):
		browser.connect("close_requested", func():
			if _dev_browser_layer and is_instance_valid(_dev_browser_layer):
				_dev_browser_layer.queue_free()
				_dev_browser_layer = null
				player.set_input_locked(hud.is_modal_open())
		)


func _handle_elevator(item: Area3D) -> void:
	var tpos: Variant = item.extra_data.get("target_pos", null)
	if not (tpos is Vector3):
		return
	var dest_label: String = str(item.extra_data.get("dest_label", "Floor"))
	AudioSynth.play_sfx("door_heavy", -4.0, 0.85)
	player.global_position = tpos as Vector3
	player.velocity = Vector3.ZERO
	hud.show_toast("ELEVATOR: Arrived at %s" % dest_label)


func _handle_office_bolt() -> void:
	if not world_builder or not world_builder.door_manager:
		return
	var sdoor: Variant = world_builder.door_manager.doors.get("sec_office_door", null)
	if sdoor and sdoor.has_method("set_manual_bolt_locked"):
		var next_lock: bool = not sdoor.is_locked
		sdoor.set_manual_bolt_locked(next_lock)
		hud.show_toast("Security Office Door BOLTED from inside." if next_lock else "Security Office Door UNBOLTED.")


func _handle_office_chair() -> void:
	if not player:
		return
	_is_seated_in_office = not _is_seated_in_office
	AudioSynth.play_sfx("door_creak", -9.0, 1.15)
	if _is_seated_in_office:
		_pre_seat_pos = player.global_position
		player.global_position = Vector3(-19.0, 0.05, -56.7)
		player.rotation_degrees.y = 0.0
		if player.head_pivot:
			player.head_pivot.position.y = 1.18
		hud.show_toast("Seated at Guard Desk — Inspect CCTV, phone, or logbook. Interact again to stand.")
	else:
		player.global_position = Vector3(-18.2, 0.15, -56.2)
		if player.head_pivot:
			player.head_pivot.position.y = 1.56
		hud.show_toast("Stood up from Guard Chair.")


func _handle_office_key_cabinet(item: Area3D) -> void:
	var st := get_node_or_null("/root/StoryManager")
	if GameState.current_night == 4 and st and not bool(st.get_flag("n4_0317_key_missing", false)):
		st.set_flag("n4_0317_key_missing", true)
		AudioSynth.play_sfx("metal_impact", -4.0)
		AudioSynth.play_sfx("handle_jiggle", -4.5)
		GameState.add_notebook_entry("03:17 — OFFICE REAR IMPACT & MISSING KEY", "Heavy metallic bang behind Vrátnica. Office handle moved; door stood closed yet unlocked. Key Cabinet was forced open and 1 maintenance key is missing.", "Security Office")
		hud.show_dialogue("03:17 — KEY CABINET OPENED!", "A heavy metallic bang shakes the rear wall as the office handle clicks. The door is closed — yet unlocked. Inside the cabinet, hook #4 stands empty: one basement maintenance key is missing.", 8.5, "Night 4 Climax Logged")
		hud.refresh_logbook_content()
		return
	var has_ring: bool = GameState.has_key("key_estate_master")
	if not has_ring:
		GameState.collect_key("key_estate_master")
		AudioSynth.play_sfx("keys_jingle", -4.5, 1.0)
		if player and player.viewmodel:
			player.viewmodel.play_keys_inspect()
		if GameState.current_night == 1 and patrol_route_mgr:
			patrol_route_mgr.complete_tutorial_step("keys_doors")
		item.prompt_text = "[E] RETURN MASTER KEYS TO CABINET"
		hud.show_dialogue("KEY CABINET", "Took the heavy estate master key ring off hook #1. Equip Keys [3] or press [L] on doors to lock and unlock them.", 5.0)
	else:
		GameState.collected_keys.erase("key_estate_master")
		AudioSynth.play_sfx("keys_jingle", -5.5, 0.90)
		item.prompt_text = "[E] PICK UP MASTER KEYS FROM CABINET"
		hud.show_toast("Hung the master key ring back inside the Security Office cabinet.")
	GameState.emit_signal("state_changed")


func _handle_desk_lamp(item: Area3D) -> void:
	var lnode: Variant = item.extra_data.get("light", null)
	if lnode is Light3D:
		(lnode as Light3D).visible = not (lnode as Light3D).visible
		AudioSynth.play_sfx("switch_click", -5.0, 1.05 if (lnode as Light3D).visible else 0.90)
		hud.show_toast("Desk Gooseneck Lamp %s." % ("ON" if (lnode as Light3D).visible else "OFF"))


func _handle_prop_inspect(item: Area3D) -> void:
	var sp: String = str(item.extra_data.get("speaker", "MARTIN KOVÁČ"))
	var nt: String = str(item.extra_data.get("note", ""))
	if not nt.is_empty():
		hud.show_dialogue(sp, nt, 5.5)


func _handle_crime_clue(item: Area3D) -> void:
	var ev_code: String = str(item.extra_data.get("event_code", ""))
	if horror_events and horror_events.has_method("inspect_crime_clue"):
		var msg: String = horror_events.inspect_crime_clue(ev_code)
		AudioSynth.play_sfx("pencil_check", -5.0)
		if player and player.viewmodel:
			player.viewmodel.play_notebook_write()
		hud.show_dialogue("CRIME SCENE EVIDENCE — " + ev_code.replace("EVENT_", ""), msg, 7.5, "Recorded in Field Notebook")
		hud.refresh_logbook_content()


func _handle_horror_hook(item: Area3D) -> void:
	var aid: String = item.anomaly_id
	if not aid.is_empty():
		AnomalyDirector.discover_anomaly(aid)
	AudioSynth.play_sfx("whisper_static", -5.0)
	if world_builder and world_builder.animation_hub:
		if item.interact_id == "park_swing":
			world_builder.animation_hub.trigger_anim("park_swing_creak", 5.0)
			AudioSynth.play_sfx("chains_sway", -5.0)
		elif item.interact_id == "garage_07":
			world_builder.animation_hub.trigger_anim("garage_underlight_flicker", 4.0)
		else:
			world_builder.animation_hub.trigger_anim("anom_stairwell_fog_pulse", 4.0)
	hud.show_dialogue("FIELD OBSERVATION — %s" % item.interact_id.to_upper(), "Something moves beyond sight... Recorded lead in Field Notebook [TAB/N].", 6.0)
	hud.refresh_logbook_content()


func _open_anomaly(anomaly_id: String) -> void:
	if anomaly_id.is_empty():
		return
	AudioSynth.play_sfx("whisper_static", -6.0)
	AnomalyDirector.discover_anomaly(anomaly_id)
	var entry: Dictionary = AnomalyDirector.get_anomaly_by_id(anomaly_id)
	var title_en: String = str(entry.get("title_en", anomaly_id))
	var desc: String = str(entry.get("description", ""))
	if world_builder and world_builder.animation_hub:
		var anim_map: Dictionary = {
			"ANOM_01": "anom_13th_window_watcher",
			"ANOM_02": "anom_hanging_sheet_flutter",
			"ANOM_04": "anom_hanging_sheet_flutter",
			"ANOM_05": "anom_black_ooze_pulse",
			"ANOM_06": "anom_floating_chairs",
			"ANOM_07": "anom_well_hands_reach",
			"ANOM_11": "anom_skoda_headlights_flash",
			"ANOM_12": "anom_butcher_hooks_swing",
			"ANOM_15": "anom_clock_hands_reverse",
			"ANOM_27": "anom_shadow_stalker_glide",
			"ANOM_32": "anom_k4_core_breathe"
		}
		if anim_map.has(anomaly_id):
			world_builder.animation_hub.trigger_anim(str(anim_map[anomaly_id]), 4.0)
	hud.show_dialogue("ANOMALY SPOTTED — %s" % title_en, "%s\n► Open Field Notebook [TAB/N] to check it off, or equip Stun Taser [2+LMB] to disrupt it." % desc, 7.0)
	hud.refresh_logbook_content()


func _handle_battery_pickup(item: Area3D) -> void:
	GameState.add_spare_battery(1)
	if player and player.viewmodel and player.viewmodel.has_method("play_pickup_object"):
		player.viewmodel.play_pickup_object()
	AudioSynth.play_sfx("battery_swap", -5.0)
	hud.show_toast("+1 4.5V Battery Pack (%d spares) — Press [R] to reload gear!" % GameState.spare_batteries)
	if item.has_meta("visual_node"):
		var vis: Variant = item.get_meta("visual_node")
		if vis is Node and is_instance_valid(vis):
			(vis as Node).queue_free()
	item.queue_free()


func _on_gear_switched(slot: String) -> void:
	if GameState.current_night == 1 and patrol_route_mgr:
		patrol_route_mgr.complete_tutorial_step("inventory")
		if slot == "radio":
			patrol_route_mgr.complete_tutorial_step("radio")
	if tutorial_mgr and tutorial_mgr.has_method("notify_gear_switched"):
		tutorial_mgr.notify_gear_switched(slot)
	if slot == "taser":
		hud.show_toast("STUN TASER EQUIPPED — Aim & click [LMB] to fire electric arc")
	elif slot == "notebook" and hud and not hud.is_modal_open():
		hud.open_logbook(0)


func _on_taser_fired(_hit_pos: Vector3, hit_collider: Object) -> void:
	var target_aid: String = ""
	var visual_node: Node3D = null
	if hit_collider is Area3D or hit_collider is Node:
		var n := hit_collider as Node
		if "anomaly_id" in n and not str(n.get("anomaly_id")).is_empty():
			target_aid = str(n.get("anomaly_id"))
		elif n.has_meta("anomaly_id"):
			target_aid = str(n.get_meta("anomaly_id", ""))
		if n.has_meta("visual_target") and n.get_meta("visual_target") is Node3D:
			visual_node = n.get_meta("visual_target") as Node3D

	if target_aid.is_empty() and world_builder and player and player.camera:
		var res: Dictionary = world_builder.find_anomaly_in_beam(player.camera.global_position, -player.camera.global_transform.basis.z, 6.8)
		if not res.is_empty():
			target_aid = str(res.get("anomaly_id", ""))
			visual_node = res.get("node") as Node3D

	if not target_aid.is_empty() and world_builder and world_builder.animation_hub:
		var stunned: bool = false
		if visual_node != null:
			stunned = world_builder.animation_hub.stun_anomaly_node(visual_node)
		else:
			stunned = world_builder.animation_hub.stun_anomaly_node(target_aid)
		if stunned:
			GameState.anomalies_stunned += 1
			AudioSynth.play_sfx("chair_crash", -5.0)
			AudioSynth.play_sfx("whisper_static", -6.0)
			AnomalyDirector.discover_anomaly(target_aid)
			GameState.adjust_distortion(-5.0)
			var entry: Dictionary = AnomalyDirector.get_anomaly_by_id(target_aid)
			hud.show_dialogue("TASER DISRUPTION HIT!", "High-voltage arc stunned & dispersed [%s]! Open Field Notebook [TAB/N] to check it off." % str(entry.get("title_en", target_aid)), 6.0)
			return

	if GameState.current_night == 1:
		hud.show_toast("Taser arc discharged — high-voltage prongs tested!")


func _on_notebook_anomaly_checked(anomaly_id: String) -> void:
	var ok: bool = GameState.check_off_notebook_anomaly(anomaly_id)
	if ok:
		AudioSynth.play_sfx("pencil_check", -4.0)
		if player and player.viewmodel:
			player.viewmodel.play_notebook_check()
		hud.refresh_logbook_content()
		hud.set_notebook_feedback("✓ VERIFIED IN FIELD NOTEBOOK — Anomaly logged & distortion stabilized (-4%).", true)
	else:
		AudioSynth.play_sfx("ui_blip", -7.0)
		hud.set_notebook_feedback("No physical evidence of that anomaly active tonight — spot it first before logging.", false)


func _on_notebook_opened_changed(opened: bool) -> void:
	if player and player.viewmodel:
		player.viewmodel.play_notebook_open(opened)
	if player:
		player.set_input_locked(opened)
	if tutorial_mgr and tutorial_mgr.has_method("notify_notebook_opened"):
		tutorial_mgr.notify_notebook_opened(opened)
	if opened:
		AudioSynth.play_sfx("notebook_open", -6.0)
		if GameState.current_night == 1 and patrol_route_mgr:
			patrol_route_mgr.complete_tutorial_step("notebook_map")
		hud.refresh_logbook_content()
		if horror_events and horror_events.has_method("on_player_notebook_opened_in_office"):
			horror_events.on_player_notebook_opened_in_office()


func _handle_booth_phone() -> void:
	var n: int = GameState.current_night
	var st := get_node_or_null("/root/StoryManager")
	AudioSynth.play_sfx("switch_click", -5.5, 0.94)
	if world_builder and world_builder.district:
		var rec_node: Node3D = world_builder.district.find_child("OfficePhoneReceiver", true, false) as Node3D
		if rec_node and is_inside_tree():
			var tw := create_tween()
			var base_y: float = rec_node.position.y
			tw.tween_property(rec_node, "position:y", base_y + 0.18, 0.25)
			tw.tween_interval(3.0)
			tw.tween_property(rec_node, "position:y", base_y, 0.30)
	if not GameState.is_quest_done("answer_briefing"):
		GameState.complete_quest("answer_briefing")
		if n == 1 and patrol_route_mgr:
			patrol_route_mgr.complete_tutorial_step("interact")
		if n <= 5:
			AudioSynth.play_voice("voice_kovac_n%d" % n, -1.5)
		if st:
			var dlg: Dictionary = st.record_character_interaction("varga", n)
			st.complete_story_objective("j1_keys_radio")
			hud.show_dialogue(str(dlg.get("speaker", "JOZEF VARGA")), str(dlg.get("text", "")), 11.0, str(dlg.get("role", "Security Supervisor")))
		else:
			var ndata: Dictionary = GameState.get_night_data(n)
			hud.show_dialogue(str(ndata.get("briefing_speaker", "JOZEF VARGA")), str(ndata.get("briefing", "")), 11.0)
	elif n == 1 and st and not bool(st.get_flag("climax_night1_silent_phone", false)):
		st.trigger_night_climax(1)
		st.complete_story_objective("j1_return_office")
		AudioSynth.play_sfx("whisper_static", -6.0)
		hud.show_dialogue("SILENT ROTARY LINE", "Nobody answers. Only cold breathing and faint 50 Hz hum. When you set the receiver down, a new handwritten line sits in your notebook.", 8.0, "Check Notebook -> Personal Notes")
		hud.refresh_logbook_content()
	elif n == 5 and st and not bool(st.get_flag("climax_night5_disconnected_radio", false)):
		st.trigger_night_climax(5)
		st.complete_story_objective("j5_varga")
		AudioSynth.play_sfx("radio_squelch", -4.0)
		hud.show_dialogue("DISCONNECTED DESK RADIO", "\"Martin Kováč...\" — The voice speaks your full name clearly, even though the desk radio's battery compartment is empty.", 8.0)
	elif n == 6:
		_open_javor_final_choice()
	elif n >= 4 and AnomalyDirector.is_active("ANOM_20"):
		_open_anomaly("ANOM_20")
	else:
		hud.show_dialogue("ROTARY PHONE", "Only a dry 50Hz dial tone hums on the line.", 4.5)


func _handle_clock_stamp(clock_id: String) -> void:
	AudioSynth.play_sfx("clock_stamp", -5.0)
	if not clock_id in _clocks_stamped_this_night:
		_clocks_stamped_this_night.append(clock_id)
	GameState.story_flags["night_clocks_stamped"] = _clocks_stamped_this_night.size()

	if GameState.current_night == 1 and _clocks_stamped_this_night.size() >= 3:
		GameState.complete_quest("stamp_clocks")
	elif _clocks_stamped_this_night.size() >= 4:
		if GameState.current_night == 2:
			GameState.complete_quest("stamp_all_n2")
		elif GameState.current_night == 3:
			GameState.complete_quest("stamp_all_n3")

	if clock_id == "clock_boiler" and AnomalyDirector.is_active("ANOM_19"):
		hud.show_dialogue("WATCHMAN'S CLOCK", "Stamped %d/4 checkpoints... Three seconds later, another brass click echoes from the dark well." % _clocks_stamped_this_night.size(), 5.5)
		AnomalyDirector.discover_anomaly("ANOM_19")
	else:
		hud.show_dialogue("WATCHMAN'S CLOCK", "Stamped checkpoint [%s] (%d clocks stamped tonight)." % [clock_id.to_upper(), _clocks_stamped_this_night.size()], 4.0)


func _open_cctv() -> void:
	player.set_input_locked(true)
	GameState.register_cctv_viewed(world_builder.active_cam_idx)
	if GameState.current_night == 3 and world_builder.active_cam_idx == 1:
		GameState.complete_quest("inspect_cam2_1953")
	hud.open_cctv_modal(world_builder.get_cctv_texture(), world_builder.get_active_cctv_label(), _get_cctv_anomaly_hint())


func _on_cctv_cycle() -> void:
	AudioSynth.play_sfx("ui_blip", -7.0)
	var label: String = world_builder.cycle_cctv_camera()
	GameState.register_cctv_viewed(world_builder.active_cam_idx)
	if GameState.current_night == 3 and world_builder.active_cam_idx == 1:
		GameState.complete_quest("inspect_cam2_1953")
	hud.update_cctv_modal(world_builder.get_cctv_texture(), label, _get_cctv_anomaly_hint())


func _on_cctv_select(cam_idx: int) -> void:
	AudioSynth.play_sfx("ui_blip", -7.0)
	var label: String = world_builder.set_cctv_camera(cam_idx)
	GameState.register_cctv_viewed(world_builder.active_cam_idx)
	if GameState.current_night == 3 and world_builder.active_cam_idx == 1:
		GameState.complete_quest("inspect_cam2_1953")
	hud.update_cctv_modal(world_builder.get_cctv_texture(), label, _get_cctv_anomaly_hint())


func _get_cctv_anomaly_hint() -> String:
	var idx: int = world_builder.active_cam_idx
	if antagonist_ai and antagonist_ai.has_method("is_visible_on_cctv") and antagonist_ai.is_visible_on_cctv(idx):
		return "ALERT — LIVE MOVEMENT: A dark human figure is moving through this camera sector right now!"
	if idx == 0:
		if AnomalyDirector.is_active("ANOM_08") or GameState.current_night >= 2:
			return "CAM-01 MAIN GATE: A silhouette in a guard coat was seen near the dark Bus Stop!"
	elif idx == 1:
		if AnomalyDirector.is_active("ANOM_11"):
			return "CAM-02 PARKING LOT: Abandoned Škoda Favorit headlights flashing toward the road!"
	elif idx == 2:
		if AnomalyDirector.is_active("ANOM_04") or AnomalyDirector.is_active("ANOM_07"):
			return "CAM-03 CENTRAL PARK: Playground swing rocking in dead air & movement near Well!"
	elif idx == 3:
		if AnomalyDirector.is_active("ANOM_12") or AnomalyDirector.is_active("ANOM_25"):
			return "CAM-04 SHOPS: Fluorescent buzzing in Jednota & scraping behind delivery dumpsters!"
	elif idx == 4:
		if AnomalyDirector.is_active("ANOM_03") or GameState.current_night >= 2:
			return "CAM-05 GARAGE COMPLEX: Cold cyan glow seeping under locked Garage 07!"
	elif idx == 5:
		if AnomalyDirector.is_active("ANOM_27") or GameState.current_night == 3:
			return "CAM-06 NORTHERN PATH: Shadow figure standing between pines beneath 8F Block B!"
	return "Feed nominal — 50Hz noise within tolerance (%d/6 feeds inspected)." % GameState.inspected_cctv_cams.size()


func _on_cctv_log() -> void:
	var idx: int = world_builder.active_cam_idx
	var logged_id: String = "ANOM_01"
	match idx:
		0: logged_id = "ANOM_08"
		1: logged_id = "ANOM_11"
		2: logged_id = "ANOM_07" if AnomalyDirector.is_active("ANOM_07") else "ANOM_04"
		3: logged_id = "ANOM_12"
		4: logged_id = "ANOM_03"
		5: logged_id = "ANOM_27"

	GameState.check_off_notebook_anomaly(logged_id)
	AudioSynth.play_sfx("pencil_check", -5.0)
	hud.update_cctv_modal(world_builder.get_cctv_texture(), world_builder.get_active_cctv_label(), "RECORDED IN NOTEBOOK: " + logged_id)


func _handle_booth_desk() -> void:
	var n: int = GameState.current_night
	var st := get_node_or_null("/root/StoryManager")
	if n == 6:
		_open_javor_final_choice()
		return
	var route_ready: bool = patrol_route_mgr != null and patrol_route_mgr.are_field_checkpoints_done(n)
	if not GameState.can_finish_shift() and not route_ready:
		player.set_input_locked(true)
		hud.open_logbook(0)
		var acp: Dictionary = patrol_route_mgr.get_active_checkpoint(n) if patrol_route_mgr else {}
		var nxt_txt: String = (" Next checkpoint: #%d %s." % [int(acp.get("num", 1)), str(acp.get("name", ""))]) if not acp.is_empty() else ""
		hud.show_dialogue("GUARD LOGBOOK", "Complete tonight's patrol checkpoints before signing the 06:00 dawn report.%s" % nxt_txt, 5.5)
		return
	# Night 1 03:17 silent phone call with faint footsteps before shift ends
	if n == 1 and st and not bool(st.get_flag("climax_night1_silent_phone", false)):
		st.trigger_night_climax(1)
		AudioSynth.play_sfx("phone_ring", -6.0)
		hud.show_dialogue("03:17 — SILENT ROTARY CALL", "The telephone rings sharply at 03:17. Nobody speaks — only faint wet footsteps echo down the copper line before it clicks dead.", 7.5)
	elif n == 2 and st and not bool(st.get_flag("n2_varga_warned", false)):
		st.set_flag("n2_varga_warned", true)
		GameState.add_notebook_entry("VARGA WARNING", "Supervisor Varga warned me not to inspect old maintenance doors and stick strictly to routine checks.", "Security Office")
	player.set_input_locked(true)
	hud.open_dawn_modal()


func _on_dawn_submitted(mode: String) -> void:
	var n: int = GameState.current_night
	if n < 6:
		# Campaign progresses consecutively across Nights 1 -> 2 -> 3 -> 4 -> 5 -> 6!
		if n == 5:
			GameState.shift_minutes = 480
			GameState.previous_shifts_archive.append({
				"night": 5, "date": "22.11.1996", "report_mode": mode,
				"completed_count": GameState.completed_quests.size(),
				"notes_count": GameState.notebook_entries.size(),
				"anomalies_logged": GameState.notebook_checked.size(),
			})
			GameState.start_new_shift(6, GameState.hardcore_mode, false)
			player.position = world_builder.get_player_spawn_position()
			player.set_input_locked(false)
			_begin_shift_presentation()
			return
		var result: String = GameState.submit_dawn_report(mode)
		if result == "NEXT_NIGHT":
			var next_n: int = n + 1
			GameState.start_new_shift(next_n, GameState.hardcore_mode, false)
			player.position = world_builder.get_player_spawn_position()
			player.set_input_locked(false)
			_begin_shift_presentation()
			return
	# Night 6 resolves into one of the 3 full Prompt 06 Campaign Endings!
	_open_javor_final_choice()


func _handle_door_interaction(item: Area3D) -> void:
	var door_id: String = str(item.extra_data.get("door_id", item.interact_id))
	AudioSynth.play_sfx("door_creak", -5.0)
	if door_id == "watchmaker" or door_id == "watchmaker_door":
		GameState.unlock_door_record("watchmaker")
		if GameState.current_night >= 3 and not ("evidence_film" in GameState.evidence_items):
			GameState.add_evidence("evidence_film")
			GameState.complete_quest("elena_film_n3")
			hud.show_dialogue("GRANDFATHER CLOCK", "Behind the pendulum you recover Elena Kralova's 35mm film roll! (Evidence Added)", 6.5)
		else:
			_open_anomaly("ANOM_15")
	elif door_id == "notary" or door_id == "notary_door":
		GameState.unlock_door_record("notary")
		if GameState.current_night == 2:
			GameState.complete_quest("check_notary")
		_open_anomaly("ANOM_17")
	elif door_id == "attic":
		GameState.unlock_door_record("attic")
		GameState.story_flags["has_jozef_brass_key"] = true
		GameState.add_tape("tape_2")
		hud.show_dialogue("JOZEF'S ATTIC STASH", "Wrapped in oilcloth beside the hatch: Jozef's Brass Master Key (opens Red Bulkhead Door) and Cassette Tape #2!", 6.5)
	elif door_id == "flat7" or door_id == "flat4":
		GameState.unlock_door_record("flat7")
		hud.show_dialogue("2F TENEMENT GALLERY", "You inspect the rusted latch along the quiet wooden corridor.", 4.0)
	elif door_id == "flat9" or door_id == "flat9_door":
		_open_anomaly("ANOM_03")


func _handle_fusebox() -> void:
	AudioSynth.play_sfx("flashlight", -5.0, 0.8)
	if GameState.current_night == 2:
		GameState.complete_quest("reset_fusebox")
	GameState.adjust_distortion(-5.0)
	if GameState.current_night >= 5:
		var st := get_node_or_null("/root/StoryManager")
		GameState.collect_key("key_service_corridor")
		if st:
			st.set_flag("n5_hidden_corridor_unlocked", true)
			st.complete_story_objective("j5_substation")
		if world_builder and world_builder.door_manager and world_builder.door_manager.doors.has("hidden_corridor_door"):
			var hdoor: Node = world_builder.door_manager.doors["hidden_corridor_door"]
			hdoor.is_locked = false
			hdoor.door_state = "CLOSED_UNLOCKED"
		GameState.add_notebook_entry("SUBSTATION CIRCUIT RESTORED", "Restored tripped basement maintenance circuit at Trafostanica. Electromagnetic lock disengaged on the Hidden Service Corridor door inside Boiler Tunnel.", "Technical Area")
		hud.show_dialogue("SUBSTATION POWER RESTORED", "Main transformer breakers latch back in with a heavy hum. Down inside the Boiler Tunnel, the north Hidden Service Corridor magnetic lock clicks open!", 7.5)
	else:
		hud.show_dialogue("MAIN FUSEBOX", "Main corridor breakers snapped back into position. Passage lights buzz cold white.", 4.5)


func _handle_payphone() -> void:
	if GameState.current_night >= 3:
		GameState.complete_quest("answer_payphone_n3")
		GameState.add_tape("tape_3")
		AudioSynth.play_voice("voice_elena_payphone", -1.5)
		_open_anomaly("ANOM_14")
	else:
		hud.show_dialogue("ARCADE PAYPHONE", "Copper line snipped inside the steel casing. Dead weight.", 4.0)


func _handle_milan() -> void:
	AudioSynth.play_voice("voice_milan_n2", -1.5)
	if GameState.current_night == 2 and not GameState.is_quest_done("confront_milan"):
		player.set_input_locked(true)
		_pending_choice_context = "milan_n2"
		var opts: Array[Dictionary] = [
			{"id": "trade", "label": "Trade quiet alley passage for spare batteries & intel (Recommended)"},
			{"id": "chase", "label": "Threaten Milan and chase him out of Block 14"}
		]
		hud.open_choice_modal("MILAN 'THE MOLE' — TRESPASSER", "Milan crouches behind the wet crates holding a fresh battery pack: 'Easy, boss! I didn't touch the flats. Let me keep my corner and I'll tell you what Hruska's boys dragged downstairs last month.'", opts)
	else:
		hud.show_dialogue("MILAN 'THE MOLE'", "Keep your head down after 02:00, boss. Even rats stay off the courtyard stones then.", 5.0)


func _handle_maria() -> void:
	var n: int = GameState.current_night
	if n == 2:
		GameState.complete_quest("check_maria_n2")
		hud.show_dialogue("MRS. MARIA (FLAT 4)", "Through the brass chain: 'Thank you for checking, Marek. Leave my door bolted when those men in the white van come.'", 5.5)
	elif n == 3 and not GameState.is_quest_done("help_maria_n3"):
		GameState.story_flags["helped_maria"] = true
		GameState.complete_quest("help_maria_n3")
		GameState.add_tape("tape_1")
		AudioSynth.play_voice("voice_maria_n3", -1.5)
		hud.show_dialogue("MRS. MARIA (FLAT 4)", "You pass her heart drops through the chain. She hands you an old reel-to-reel cassette (Tape #1): 'In 1953 they didn't dig a well down there. They buried voices inside stone.'", 7.0)
	elif n == 5 and not GameState.is_quest_done("decide_maria_n5"):
		player.set_input_locked(true)
		_pending_choice_context = "maria_n5"
		AudioSynth.play_voice("voice_maria_n5", -1.5)
		var opts: Array[Dictionary] = [
			{"id": "evacuate", "label": "Unlock back alley & evacuate Mrs. Maria with Milan (Safe)"},
			{"id": "leave", "label": "Tell her to bolt the door and stay inside"}
		]
		hud.open_choice_modal("NIGHT 5 — MRS. MARIA (FLAT 4)", "Snow rises upward past the gallery railing. Mrs. Maria clutches her suitcase behind the chain: 'Is it safe to leave before Hruska arrives?'", opts)
	else:
		hud.show_dialogue("MRS. MARIA (FLAT 4)", "Watch the thirteenth window on the east wall, Marek.", 4.5)


func _handle_clue(item: Area3D) -> void:
	var iid: String = item.interact_id
	if iid == "flat7_sink":
		GameState.unlock_door_record("flat7")
		if GameState.current_night == 1:
			GameState.complete_quest("check_flat7_sink")
		_open_anomaly("ANOM_06")
	elif iid == "skoda_car":
		_open_anomaly("ANOM_11")
	elif iid == "clue_1":
		GameState.add_evidence("evidence_plate")
		hud.show_dialogue("SMUGGLED CRATES", "Recorded truck license plate BA-419-HV next to Lada service van (%d/3 evidence)." % GameState.evidence_items.size(), 5.5)
	elif iid == "attic_stash":
		GameState.unlock_door_record("attic")
		GameState.story_flags["has_jozef_brass_key"] = true
		GameState.add_tape("tape_2")
		hud.show_dialogue("JOZEF'S ATTIC STASH", "Wrapped in oilcloth beneath the rafters: Jozef's Brass Master Key (opens Red Iron Door) and Cassette Tape #2!", 6.5)


func _handle_radio(item: Area3D) -> void:
	if not bool(item.extra_data.get("tuned", false)):
		item.extra_data["tuned"] = true
		GameState.register_radio_tuned()
		AnomalyDirector.discover_anomaly("ANOM_18")
		AudioSynth.play_sfx("static_burst", -8.0)
		hud.show_dialogue("TRANSISTOR RADIO", "Tuned to 50.4 Hz (%d/5 radios synchronized). A 1953 voice whispers tenant names beneath static." % GameState.tuned_radios, 5.5)
	else:
		hud.show_dialogue("TRANSISTOR RADIO", "Already humming cleanly at 50.4 Hz.", 3.5)


func _handle_page(item: Area3D) -> void:
	var pid: String = str(item.extra_data.get("page_id", ""))
	if pid.is_empty():
		return
	GameState.add_page(pid)
	if pid == "page_1":
		GameState.complete_quest("find_page_1")
		hud.show_dialogue("JOZEF'S TORN PAGE #1", "'Count the windows on the east wall every night. Tonight there are thirteen. On Tuesday there were twelve.' (%d/8 Pages)" % GameState.collected_pages.size(), 6.5)
	else:
		hud.show_dialogue("JOZEF'S LOGBOOK PAGE", "Recovered torn page [%s]. (%d/8 Pages collected)" % [pid.to_upper(), GameState.collected_pages.size()], 5.0)


func _handle_antenna() -> void:
	AchievementManager.unlock("ACH_03_ON_THE_ROOF")
	if GameState.current_night == 3:
		GameState.complete_quest("climb_sta_roof")
		_open_anomaly("ANOM_24")
	elif GameState.current_night == 5:
		player.set_input_locked(true)
		_pending_choice_context = "sta_n5"
		var opts: Array[Dictionary] = [
			{"id": "sabotage", "label": "Sever coaxial amplifier feed (Required for Ending B)"},
			{"id": "timeslip", "label": "Play Tape 00 / Reverse Broadcast (NG+ 1953 Time-Slip)" if GameState.can_unlock_night_6() else "Inspect humming mast (Requires NG+ & 4 Tapes + 8 Pages for Tape 00)"}
		]
		hud.open_choice_modal("STA ROOFTOP ANTENNA MAST", "Blue corona discharge leaps along the roof mast toward the courtyard well.", opts)
	else:
		hud.show_dialogue("STA ROOFTOP MAST", "Thick steel conduit runs straight down the facade toward the courtyard well.", 4.5)


func _handle_boiler_valve() -> void:
	if world_builder and world_builder.animation_hub:
		world_builder.animation_hub.trigger_anim("boiler_valve_spin", 3.5)
	if GameState.current_night == 4:
		GameState.complete_quest("bleed_boiler_valve")
		AudioSynth.play_sfx("door_heavy", -6.0)
		hud.show_dialogue("BOILER ROOM", "You wrench the red valve open. Scalding frost-rimmed steam shrieks out, dropping pressure to safe margins.", 5.5)
	elif GameState.current_night == 5:
		player.set_input_locked(true)
		_pending_choice_context = "boiler_n5"
		var opts: Array[Dictionary] = [
			{"id": "overload", "label": "Jam main steam valve & short Boiler into Bunker K-4 (Ending C)"},
			{"id": "leave", "label": "Leave pressure steady"}
		]
		hud.open_choice_modal("BOILER PRESSURE MANIFOLD", "Pressure needle trembles against the red stop. Cross-wiring this line with Device K-4 will collapse the entire vault.", opts)


func _handle_red_door() -> void:
	if GameState.current_night < 4 and not bool(GameState.story_flags.get("has_jozef_brass_key", false)):
		hud.show_dialogue("RED IRON DOOR", "Padlocked from outside with heavy cold-war bolts. Kovac ordered: stay away.", 5.0)
		return
	if not bool(GameState.story_flags.get("has_jozef_brass_key", false)) and GameState.current_night >= 4:
		hud.show_dialogue("RED IRON DOOR", "Locked tight. Check Jozef's Attic Stash on the rooftop for the Brass Master Key.", 5.5)
		return

	if not bool(GameState.story_flags.get("red_door_opened", false)):
		GameState.story_flags["red_door_opened"] = true
		GameState.unlock_door_record("red_door")
		world_builder.set_red_door_open(true)
		AudioSynth.play_sfx("door_heavy", -3.0)
		GameState.complete_quest("breach_red_door")
		AchievementManager.unlock("ACH_04_RED_DOOR")
		hud.show_dialogue("BUNKER K-4", "The brass key turns with a crack of rusted grease. Phosphor green cold spills from the sub-cellar vault.", 6.0)


func _handle_k4_core() -> void:
	if GameState.current_night == 4:
		GameState.complete_quest("inspect_device_k4")
		_open_anomaly("ANOM_32")
	elif GameState.current_night == 6:
		GameState.complete_quest("ground_k4_origin")
		AudioSynth.play_sfx("static_burst", -4.0)
		hud.show_dialogue("DEVICE K-4 (1953)", "You rip the heavy copper grounding bus free! The 50Hz roar shatters across the vault. Ascend and exit through the Main Carriage Gate!", 7.5)
	elif GameState.current_night == 5:
		_open_anomaly("ANOM_32")


func _handle_jozef_bunker() -> void:
	GameState.add_tape("tape_4")
	AudioSynth.play_voice("voice_jozef_bunker", -1.5)
	if not bool(GameState.story_flags.get("accepted_jozef_key", false)):
		player.set_input_locked(true)
		_pending_choice_context = "jozef_key"
		var opts: Array[Dictionary] = [
			{"id": "accept", "label": "Take Jozef's Archive Key (Feeds Permanent Shift — Ending D)"},
			{"id": "refuse", "label": "Leave the key and promise to shut down K-4"}
		]
		hud.open_choice_modal("JOZEF BARTOS — BUNKER K-4", "Your predecessor sits catatonic beneath the humming tubes, holding out an old iron watchman key: 'Someone has to hold the frequency at 06:00...'", opts)
	else:
		hud.show_dialogue("JOZEF BARTOS", "03:14... all locks fast... don't look at the thirteenth window...", 4.5)


func _handle_evidence(item: Area3D) -> void:
	var ev_id: String = str(item.extra_data.get("evidence_id", ""))
	if ev_id.is_empty():
		return
	GameState.add_evidence(ev_id)
	if ev_id == "evidence_dossier":
		GameState.complete_quest("recover_dossier_n4")
	hud.show_dialogue("EVIDENCE RECOVERED", "Secured Elena Kralova's concrete-sealed dossier (%d/3 evidence items)." % GameState.evidence_items.size(), 6.0)


func _handle_mobsters() -> void:
	if GameState.current_night == 4 and not GameState.is_quest_done("handle_mobsters_n4"):
		player.set_input_locked(true)
		_pending_choice_context = "mobsters_n4"
		var opts: Array[Dictionary] = [
			{"id": "stealth", "label": "Slip past silently in the shadows (Preserves Ghost achievement)"},
			{"id": "cooperate", "label": "Show guard badge and let them load crates (Aligns Ending A)"},
			{"id": "lure", "label": "Lock cellar grate & lure Boiler Room static onto them (Aligns Ending E)"}
		]
		hud.open_choice_modal("BRANO & IGOR — BOILER ROOM", "Hruska's men are hauling oak crates beside the boiler stairs.", opts)


func _handle_main_gate() -> void:
	var n: int = GameState.current_night
	var st := get_node_or_null("/root/StoryManager")
	if n == 1:
		AudioSynth.play_sfx("door_handle", -6.0)
		GameState.add_notebook_entry("MAIN GATE CHECKED", "Inspected the iron main carriage gate and street barrier. Padlock secure, road quiet under wet fog.", "Main Gate")
		hud.show_dialogue("MAIN ENTRANCE GATE", "Cold iron bars slick with rain, brass padlock locked tight. Across the foggy street, the empty bus shelter glows faintly.", 6.0)
		return
	if n == 2 and not GameState.is_quest_done("delivery_0100"):
		player.set_input_locked(true)
		_pending_choice_context = "delivery_n2"
		var opts: Array[Dictionary] = [
			{"id": "obey", "label": "Look away & stay inside booth (Obey Kovac, +Bribe flag)"},
			{"id": "plate", "label": "Record white Mercedes license plate (Evidence 1/3)"},
			{"id": "eavesdrop", "label": "Eavesdrop closely from the shadow alcove"}
		]
		hud.open_choice_modal("01:00 — WHITE MERCEDES DELIVERY", "Headlights cut across the wet gate bars. Brano and Igor unload heavy tarped bundles.", opts)
	elif n == 5:
		player.set_input_locked(true)
		_pending_choice_context = "final_n5"
		var opts: Array[Dictionary] = [
			{"id": "bribe", "label": "Accept Hruska's 50,000 DM envelope & close curtain (Ending A)"},
			{"id": "whistleblow", "label": "Break gate latch & escape to press at dawn (Ending B path)"},
			{"id": "vengeance", "label": "Sever Kovac's line & let the courtyard static take Hruska (Ending E path)"},
			{"id": "assimilate", "label": "Lock gate from INSIDE at 06:00 (Ending D path if 5 Radios + Jozef Key)"},
			{"id": "back", "label": "Step back and continue exploring Block 14"}
		]
		hud.open_choice_modal("05:55 — MAIN CARRIAGE GATE", "Hruska waits outside the iron bars with armed enforcers while sirens echo faintly in the Old Town.", opts)
	elif n == 6 and st and bool(st.get_flag("milan_rescued", false)):
		if ending_mgr:
			player.set_input_locked(true)
			ending_mgr.execute_ending("ENDING_B", world_builder, hud, player)
	elif n == 6 and GameState.is_quest_done("ground_k4_origin"):
		GameState.complete_quest("exit_dawn_gate")
		_on_dawn_submitted("truth")
	else:
		_open_anomaly("ANOM_05")


func _on_choice_made(cid: String) -> void:
	match _pending_choice_context:
		"milan_n2":
			GameState.complete_quest("confront_milan")
			if cid == "trade":
				GameState.story_flags["helped_milan"] = true
				GameState.spare_batteries += 1
				AchievementManager.unlock("ACH_19_MOLE_DEAL")
				hud.show_dialogue("MILAN 'THE MOLE'", "Fair deal, boss. Take this fresh battery pack—and watch the Red Door downstairs.", 6.0)
			else:
				hud.show_dialogue("MILAN 'THE MOLE'", "Alright, alright, I'm gone! Don't say I didn't warn you about Hruska.", 5.0)
		"delivery_n2":
			GameState.complete_quest("delivery_0100")
			AchievementManager.unlock("ACH_02_BLACK_MARKET")
			if cid == "obey":
				GameState.story_flags["obeyed_kovac"] = true
				GameState.story_flags["took_bribe"] = true
				hud.show_dialogue("MR. KOVAC — RADIO", "Good lad, Dvorak. Quiet eyes keep fat wallets.", 5.0)
			elif cid == "plate":
				GameState.add_evidence("evidence_plate")
				hud.show_dialogue("MAREK DVORAK", "Noted plate BA-419-HV in your coat pocket. White Mercedes registered to Eastern Invest Ltd.", 6.0)
			else:
				GameState.add_evidence("evidence_plate")
				hud.show_dialogue("EAVESDROPPING", "Igor mutters: 'If the journalist's bag leaks inside K-4, Hruska kills us both.'", 6.0)
		"mobsters_n4":
			GameState.complete_quest("handle_mobsters_n4")
			if cid == "stealth":
				hud.show_dialogue("BOILER ROOM SHADOWS", "You freeze behind the coal chute until their heavy boots fade upstairs. Unseen.", 5.0)
			elif cid == "cooperate":
				GameState.player_spotted = true
				GameState.story_flags["obeyed_kovac"] = true
				hud.show_dialogue("BRANO", "Smart guard. Stay upstairs for twenty minutes and nobody gets hurt.", 5.0)
			elif cid == "lure":
				GameState.story_flags["lured_anomalies_on_mobsters"] = true
				world_builder.refresh_night_state()
				AudioSynth.play_sfx("static_burst", -5.0)
				hud.show_dialogue("BOILER ROOM", "You slam the iron grate shut. Behind it, 50Hz static surges violently toward their shouting voices.", 6.0)
		"maria_n5":
			GameState.complete_quest("decide_maria_n5")
			if cid == "evacuate":
				GameState.story_flags["evacuated_maria"] = true
				AchievementManager.check_collectible_achievements()
				hud.show_dialogue("MRS. MARIA", "Milan guides Mrs. Maria out through the unguarded back passage toward the morning tram.", 6.0)
			else:
				hud.show_dialogue("MRS. MARIA", "God keep you, Marek. Lock the gate when it's done.", 5.0)
		"sta_n5":
			if cid == "sabotage":
				GameState.story_flags["antenna_sabotaged"] = true
				AudioSynth.play_sfx("static_burst", -6.0)
				hud.show_dialogue("STA ROOFTOP MAST", "You wrench the coaxial feeder cable out of the rooftop splitter. Static dies across the upper flats.", 6.0)
			elif cid == "timeslip" and GameState.can_unlock_night_6():
				GameState.start_new_shift(6, false, false)
				player.position = Vector3(0.0, 0.2, 6.0)
				_begin_shift_presentation()
		"boiler_n5":
			if cid == "overload":
				GameState.story_flags["boiler_overloaded"] = true
				GameState.complete_quest("final_confrontation")
				hud.show_dialogue("BOILER ROOM", "Steam pipes groan violently toward Bunker K-4! Return to Booth Desk (or finish at Gate) to resolve the collapse.", 6.5)
		"jozef_key":
			if cid == "accept":
				GameState.story_flags["accepted_jozef_key"] = true
				hud.show_dialogue("JOZEF BARTOS", "His cold hand presses the iron key into yours. 'Don't leave Block 14 dark...'", 5.5)
			else:
				hud.show_dialogue("MAREK DVORAK", "No one stays trapped down here anymore, Jozef.", 4.5)
		"javor_final_n6":
			var st := get_node_or_null("/root/StoryManager")
			if cid == "ENDING_A" or cid == "report":
				if st:
					st.set_flag("authorities_contacted", true)
				if world_builder and world_builder.door_manager and world_builder.door_manager.doors.has("sec_office_door"):
					world_builder.door_manager.doors["sec_office_door"].set_manual_bolt_locked(true)
			if ending_mgr:
				player.set_input_locked(true)
				ending_mgr.execute_ending(cid, world_builder, hud, player)
			elif st:
				var end_data: Dictionary = st.resolve_javor_ending(cid)
				player.set_input_locked(true)
				hud.open_javor_ending_modal(end_data)
		"final_n5":
			if cid == "back":
				return
			GameState.complete_quest("final_confrontation")
			if cid == "bribe":
				GameState.story_flags["took_bribe"] = true
				GameState.trigger_ending("A")
			elif cid == "whistleblow":
				GameState.trigger_ending("B" if (GameState.evidence_items.size() >= 2 or bool(GameState.story_flags.get("evacuated_maria", false))) else GameState.evaluate_ending())
			elif cid == "vengeance":
				GameState.story_flags["lured_anomalies_on_mobsters"] = true
				GameState.story_flags["betrayed_kovac"] = true
				GameState.trigger_ending("E")
			elif cid == "assimilate":
				GameState.trigger_ending("D")
			if not GameState.current_ending.is_empty():
				player.set_input_locked(true)
				hud.open_ending_modal(GameState.current_ending)

	_pending_choice_context = ""


func _on_pause_menu_action(action: String) -> void:
	if action == "menu":
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			sm.is_tracking_playtime = false
		get_tree().paused = false
		AudioSynth.stop_ambient()
		player.capture_mouse(false)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
