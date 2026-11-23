class_name SecurityOfficeBuilder
extends DistrictBuilderBase

var cctv_screen_mat: StandardMaterial3D
var booth_phone_beacon: MeshInstance3D
var desk_lamp_light: SpotLight3D


func build_module(is_showcase: bool = false) -> void:
	if is_showcase:
		return
	var brick: StandardMaterial3D = RetroMaterialsLib.get_material("brick_cellar")
	var dark_plaster: StandardMaterial3D = RetroMaterialsLib.get_material("plaster_dark")
	var hall_beige: StandardMaterial3D = RetroMaterialsLib.get_material("hall_beige")
	var linoleum: StandardMaterial3D = RetroMaterialsLib.get_material("tile_linoleum")
	var concrete: StandardMaterial3D = RetroMaterialsLib.get_material("concrete")
	var wood: StandardMaterial3D = RetroMaterialsLib.get_material("wood_dark")
	var iron: StandardMaterial3D = RetroMaterialsLib.get_material("iron")
	var glass: StandardMaterial3D = RetroMaterialsLib.get_material("window_dark")
	var amber_mat: StandardMaterial3D = RetroMaterialsLib.get_material("window_amber")
	var brass_mat: StandardMaterial3D = RetroMaterialsLib.get_material("prop_brass")

	# Standalone 1996 Guard Office (Vrátnica) at (-18, 0, -56), X: -22.5..-13.5, Z: -60..-52
	var center := Vector3(-18.0, 0.0, -56.0)
	add_solid_box("SecOffice_Floor", center + Vector3(0, 0.02, 0), Vector3(9.4, 0.06, 8.4), linoleum)
	add_solid_box("SecOffice_Roof", center + Vector3(0, 3.45, 0), Vector3(9.8, 0.35, 8.8), concrete)

	# Interior architectural walls with warm beige plaster & wood baseboard/dado trim
	add_solid_box("SecOffice_Wall_W", Vector3(-22.5, 1.7, -56.0), Vector3(0.32, 3.4, 8.2), brick)
	add_solid_box("SecOffice_Wall_S", Vector3(-18.0, 1.7, -60.0), Vector3(9.2, 3.4, 0.32), brick)
	add_solid_box("SecOffice_Wall_N", Vector3(-18.0, 1.7, -52.0), Vector3(9.2, 3.4, 0.32), hall_beige)
	add_mesh_box("SecOffice_Baseboard_W", Vector3(-22.32, 0.14, -56.0), Vector3(0.05, 0.22, 7.9), wood)
	add_mesh_box("SecOffice_Baseboard_N", Vector3(-18.0, 0.14, -52.18), Vector3(8.7, 0.22, 0.05), wood)
	add_mesh_box("SecOffice_Baseboard_S", Vector3(-18.0, 0.14, -59.82), Vector3(8.7, 0.22, 0.05), wood)
	add_mesh_box("SecOffice_Dado_N", Vector3(-18.0, 1.05, -52.17), Vector3(8.7, 0.06, 0.04), wood)
	add_mesh_box("SecOffice_Dado_W", Vector3(-22.32, 1.05, -56.0), Vector3(0.04, 0.06, 7.9), wood)

	# Framed Courtyard Observation Window (North Wall) + Parking/Gate Observation Window (East Wall south of door)
	# South Wall behind desk is solid brick for the District Map Board (zero overlap with windows!)
	add_mesh_box("SecWin_N", Vector3(-18.0, 1.85, -52.18), Vector3(3.4, 1.15, 0.06), glass)
	add_mesh_box("SecWinSill_N", Vector3(-18.0, 1.25, -52.32), Vector3(3.6, 0.07, 0.28), wood)
	add_mesh_box("SecWinHead_N", Vector3(-18.0, 2.45, -52.18), Vector3(3.6, 0.08, 0.14), wood)
	for mx: float in [-19.7, -18.0, -16.3]:
		add_mesh_box("SecWinMullion_N_%d" % int(absf(mx)), Vector3(mx, 1.85, -52.18), Vector3(0.07, 1.2, 0.12), wood)

	add_mesh_box("SecWin_E", Vector3(-13.68, 1.85, -57.5), Vector3(0.06, 1.15, 2.5), glass)
	add_mesh_box("SecWinSill_E", Vector3(-13.80, 1.25, -57.5), Vector3(0.26, 0.07, 2.7), wood)
	add_mesh_box("SecWinHead_E", Vector3(-13.68, 2.45, -57.5), Vector3(0.14, 0.08, 2.7), wood)
	for mz: float in [-58.7, -57.5, -56.3]:
		add_mesh_box("SecWinMullion_E_%d" % int(absf(mz)), Vector3(-13.68, 1.85, mz), Vector3(0.12, 1.2, 0.07), wood)

	# East Wall split around framed hinged steel PhysicalDoor (gap Z: -55.20 .. -54.05, width 1.15m)
	# rot_y = +90.0 extends door leaf along -Z from -54.08 to -55.16 (centered cleanly in gap, never inside wall!)
	add_solid_box("SecOffice_Wall_E_S", Vector3(-13.5, 1.7, -57.6), Vector3(0.32, 3.4, 4.8), dark_plaster)
	add_solid_box("SecOffice_Wall_E_N", Vector3(-13.5, 1.7, -53.0), Vector3(0.32, 3.4, 2.1), dark_plaster)
	add_solid_box("SecOffice_Wall_E_Hdr", Vector3(-13.5, 2.80, -54.6), Vector3(0.32, 1.25, 1.5), dark_plaster)
	add_physical_door("sec_office_door", "steel", Vector3(-13.5, 0.05, -54.08), 90.0, -90.0, false, "", 1.08)

	# Interior Manual Deadbolt Latch next to Security Office door
	add_mesh_box("SecOffice_DoorBolt", Vector3(-13.68, 1.22, -53.92), Vector3(0.06, 0.14, 0.10), iron)
	add_interactable("sec_office_bolt", "office_bolt", "[E] BOLT / UNBOLT OFFICE DOOR", Vector3(-13.85, 1.22, -53.92), Vector3(0.75, 0.75, 0.75))

	add_sign_board("Sign_Vratnica", "sign_vratnica", Vector3(-13.3, 2.95, -54.6), Vector2(2.6, 0.78), Vector3(0, 90, 0))

	# Main Ceiling Dual-Tube Fluorescent Fixture + Warm Office Ambience (clearly readable Security Office!)
	spawn_glb("fluorescent_fixture_96", Vector3(-18.0, 3.24, -56.0), Vector3(0, 90, 0))
	var desk_light := OmniLight3D.new()
	desk_light.name = "BoothDeskLight"
	desk_light.position = Vector3(-17.4, 2.95, -55.8)
	desk_light.light_color = Color(0.94, 0.86, 0.64)
	desk_light.light_energy = 1.85
	desk_light.omni_range = 10.5
	add_child(desk_light)
	register_anim("sodium_lamp_sway", desk_light, {"energy": 1.85, "seed": 3.5})
	add_spatial_sound("loop_sodium_buzz", Vector3(-18.0, 3.1, -56.0), 7.0, -24.0, is_showcase)
	add_interactive_prop("sec_office_light_switch", "switch", Vector3(-13.72, 1.35, -53.6), -90.0, [desk_light])

	# Exterior Security Office Entrance Bulkhead Light above East Door (makes exit & walkway unmistakably readable!)
	add_mesh_box("SecOfficeExtFixture", Vector3(-13.26, 2.58, -54.6), Vector3(0.16, 0.22, 0.34), amber_mat)
	var ext_porch := SpotLight3D.new()
	ext_porch.name = "SecOfficeExteriorLamp"
	ext_porch.position = Vector3(-12.95, 2.56, -54.6)
	ext_porch.rotation_degrees = Vector3(-78.0, -90.0, 0.0)
	ext_porch.light_color = Color(1.0, 0.76, 0.38)
	ext_porch.light_energy = 4.2
	ext_porch.spot_range = 14.5
	ext_porch.spot_angle = 68.0
	ext_porch.spot_attenuation = 1.15
	ext_porch.shadow_enabled = true
	ext_porch.shadow_blur = 0.24
	add_child(ext_porch)

	# Subtle animated fabric curtains flanking the North observation window (Prompt 08 Part 5)
	var curt_mat := StandardMaterial3D.new()
	curt_mat.albedo_color = Color(0.42, 0.44, 0.38)
	curt_mat.roughness = 0.94
	var curt_l := add_mesh_box("SecOfficeCurtainL", Vector3(-19.65, 1.82, -52.28), Vector3(0.36, 1.24, 0.04), curt_mat)
	var curt_r := add_mesh_box("SecOfficeCurtainR", Vector3(-16.35, 1.82, -52.28), Vector3(0.36, 1.24, 0.04), curt_mat)
	register_anim("curtain_sway", curt_l, {"seed": 1.1})
	register_anim("curtain_sway", curt_r, {"seed": 2.4})

	# Detailed Guard Workstation: Wooden Desk, Paperwork, Open Logbook, Chair, Gooseneck Lamp, CRT & Rotary Phone
	spawn_glb("guard_booth_desk", Vector3(-19.0, 0.05, -57.8), Vector3.ZERO)
	add_invisible_collider("SecDesk_Col", Vector3(-19.0, 0.5, -57.8), Vector3(2.3, 1.0, 1.0))
	add_interactive_prop("sec_desk_drawer", "drawer", Vector3(-18.1, 0.72, -57.28), 0.0, [], "key_utility", true)
	spawn_glb("wooden_chair", Vector3(-19.0, 0.05, -56.7), Vector3(0, 170, 0))
	add_invisible_collider("SecChair_Col", Vector3(-19.0, 0.45, -56.7), Vector3(0.62, 0.90, 0.62))
	add_interactable("sec_office_chair", "office_chair", "[E] SIT / STAND AT GUARD DESK", Vector3(-19.0, 0.55, -56.7), Vector3(0.95, 1.1, 0.95))

	# Paperwork binder stacks & open logbook on desk
	var paper_mat := StandardMaterial3D.new()
	paper_mat.albedo_color = Color(0.82, 0.78, 0.68)
	paper_mat.roughness = 0.88
	add_mesh_box("DeskPaperStack1", Vector3(-19.35, 0.98, -57.52), Vector3(0.26, 0.04, 0.34), paper_mat, Vector3(0, 8, 0))
	add_mesh_box("DeskPaperStack2", Vector3(-19.02, 0.97, -57.45), Vector3(0.24, 0.025, 0.31), paper_mat, Vector3(0, -12, 0))
	add_mesh_cyl("DeskPenCup", Vector3(-19.52, 1.03, -57.95), 0.036, 0.11, iron)
	add_interactable("booth_desk", "desk", "[E] INSPECT SHIFT LOGBOOK / SIGN DAWN REPORT", Vector3(-19.0, 1.05, -57.3), Vector3(1.2, 0.9, 1.0))

	# Articulable Gooseneck Desk Lamp with warm SpotLight3D
	add_mesh_cyl("DeskLampBase", Vector3(-18.55, 0.98, -58.05), 0.09, 0.04, iron)
	add_mesh_cyl("DeskLampStem", Vector3(-18.55, 1.16, -58.00), 0.015, 0.34, iron, Vector3(-18, 0, 0))
	add_mesh_cyl("DeskLampShade", Vector3(-18.55, 1.32, -57.88), 0.085, 0.14, iron, Vector3(55, 0, 0))
	desk_lamp_light = SpotLight3D.new()
	desk_lamp_light.name = "DeskGooseneckLamp"
	desk_lamp_light.position = Vector3(-18.55, 1.30, -57.86)
	desk_lamp_light.rotation_degrees = Vector3(-68.0, 0.0, 0.0)
	desk_lamp_light.light_color = Color(1.0, 0.84, 0.52)
	desk_lamp_light.light_energy = 4.8
	desk_lamp_light.spot_range = 6.5
	desk_lamp_light.spot_angle = 56.0
	desk_lamp_light.shadow_enabled = true
	desk_lamp_light.shadow_blur = 0.22
	add_child(desk_lamp_light)
	add_interactable("sec_desk_lamp", "desk_lamp", "[E] TOGGLE DESK LAMP", Vector3(-18.55, 1.15, -57.95), Vector3(0.55, 0.55, 0.55), "", {"light": desk_lamp_light})

	# Analog Rotary Phone with animated receiver prop
	spawn_glb("rotary_phone", Vector3(-19.8, 0.96, -57.7), Vector3(0, 180, 0))
	add_mesh_box("OfficePhoneReceiver", Vector3(-19.8, 1.10, -57.7), Vector3(0.22, 0.045, 0.055), iron)
	booth_phone_beacon = add_mesh_box("Phone_Ring_Beacon", Vector3(-19.8, 1.30, -57.7), Vector3(0.08, 0.08, 0.08), amber_mat)
	add_interactable("booth_phone", "phone", "[E] PICK UP ROTARY TELEPHONE", Vector3(-19.8, 1.15, -57.4), Vector3(0.9, 0.9, 0.9))

	# TESLA CRT CCTV Monitor with subtle green phosphor bounce light
	spawn_glb("tesla_crt_monitor", Vector3(-18.0, 0.96, -58.0), Vector3(0, 180, 0))
	cctv_screen_mat = StandardMaterial3D.new()
	cctv_screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cctv_screen_mat.albedo_color = Color(0.75, 0.88, 0.78)
	add_mesh_box("CCTV_Screen", Vector3(-18.0, 1.29, -57.78), Vector3(0.49, 0.37, 0.025), cctv_screen_mat)
	var crt_glow := OmniLight3D.new()
	crt_glow.name = "CRTScreenGlow"
	crt_glow.position = Vector3(-18.0, 1.30, -57.45)
	crt_glow.light_color = Color(0.42, 0.86, 0.56)
	crt_glow.light_energy = 0.95
	crt_glow.omni_range = 3.8
	add_child(crt_glow)
	add_interactable("booth_cctv", "cctv", "[E] INSPECT CCTV MONITOR", Vector3(-18.0, 1.25, -57.4), Vector3(1.1, 1.0, 1.0))

	# District Map mounted cleanly on the solid South brick wall above the guard workstation (with wooden frame)
	add_mesh_box("DistrictMapFrame", Vector3(-18.3, 1.98, -59.82), Vector3(2.52, 1.92, 0.04), wood)
	add_sign_board("DistrictMapBoard", "district_map_1995", Vector3(-18.3, 1.98, -59.78), Vector2(2.4, 1.8), Vector3.ZERO)
	add_solid_box("KeyCabinet", Vector3(-22.2, 1.65, -54.5), Vector3(0.18, 0.78, 0.68), iron)
	for ki: int in range(4):
		add_mesh_cyl("CabinetKeyHook_%d" % ki, Vector3(-22.09, 1.80 - ki * 0.12, -54.68 + ki * 0.11), 0.015, 0.06, brass_mat, Vector3(0, 0, 90))
	add_interactable("office_key_cabinet", "office_key_cabinet", "[E] PICK UP MASTER KEYS FROM CABINET", Vector3(-21.9, 1.65, -54.5), Vector3(0.75, 0.9, 0.8))

	spawn_glb("electrical_panel_96", Vector3(-22.22, 1.55, -56.4), Vector3(0, 90, 0))
	add_solid_box("FilingCabinet", Vector3(-21.6, 0.68, -58.8), Vector3(0.7, 1.35, 0.8), dark_plaster)
	add_solid_box("BoothShelf", Vector3(-21.6, 0.45, -53.6), Vector3(0.9, 0.9, 0.7), wood)

	# Coffee Mug, Steel Thermos, Oil Radiator Heater, Coat Rack, Waste Bin, Calendar & Alarm Control Panel
	add_mesh_cyl("ThermosBody", Vector3(-17.3, 1.12, -58.1), 0.055, 0.28, iron)
	add_mesh_cyl("CoffeeMug", Vector3(-17.52, 1.03, -57.68), 0.042, 0.10, dark_plaster)
	add_interactable("sec_coffee_mug", "prop_inspect", "[E] INSPECT COFFEE & THERMOS", Vector3(-17.42, 1.08, -57.88), Vector3(0.45, 0.45, 0.45), "", {
		"speaker": "MARTIN KOVÁČ",
		"note": "Instant coffee from 21:45. Already lukewarm, tastes like boiled tap water and rust."
	})

	add_solid_box("OfficeHeater", Vector3(-17.8, 0.36, -52.42), Vector3(0.78, 0.62, 0.22), iron)
	add_mesh_box("HeaterPilotLED", Vector3(-17.45, 0.56, -52.30), Vector3(0.03, 0.03, 0.02), amber_mat)

	add_mesh_box("CoatRackBoard", Vector3(-13.70, 1.75, -52.85), Vector3(0.05, 0.14, 0.55), wood)
	add_mesh_box("HangingCoat", Vector3(-13.78, 1.25, -52.85), Vector3(0.14, 0.92, 0.38), dark_plaster)
	add_mesh_cyl("OfficeWasteBin", Vector3(-17.15, 0.22, -57.35), 0.17, 0.42, iron)

	add_mesh_box("WallCalendar1996", Vector3(-15.5, 1.75, -59.83), Vector3(0.42, 0.56, 0.02), paper_mat)
	add_solid_box("SecurityControlPanel", Vector3(-14.6, 1.48, -59.78), Vector3(0.68, 0.54, 0.14), iron)
	add_mesh_box("ControlPanelLED1", Vector3(-14.75, 1.60, -59.70), Vector3(0.04, 0.04, 0.02), amber_mat)
	add_mesh_box("ControlPanelLED2", Vector3(-14.60, 1.60, -59.70), Vector3(0.04, 0.04, 0.02), amber_mat)
	add_interactable("sec_control_panel", "prop_inspect", "[E] INSPECT ALARM CONTROL PANEL", Vector3(-14.6, 1.48, -59.55), Vector3(0.75, 0.65, 0.65), "", {
		"speaker": "MARTIN KOVÁČ",
		"note": "TESLA UK-84 Perimeter Panel: Block B basement loop and Substation sensor show intermittent ground fault."
	})

	add_mesh_cyl("WallClock", Vector3(-15.5, 2.35, -59.82), 0.22, 0.05, amber_mat, Vector3(90, 0, 0))
	var clk_pivot := Node3D.new()
	clk_pivot.name = "WallClockHandPivot"
	clk_pivot.position = Vector3(-15.5, 2.35, -59.78)
	add_child(clk_pivot)
	add_mesh_box("WallClockMinHand", Vector3(0.0, 0.07, 0.0), Vector3(0.018, 0.16, 0.012), iron, Vector3.ZERO, clk_pivot)
	register_anim("clock_hands_tick", clk_pivot, {"speed": 0.45})
	add_spatial_sound("loop_clock_tick", Vector3(-15.5, 2.35, -59.6), 6.5, -18.0, is_showcase)

	var r1 := spawn_glb("transistor_radio", Vector3(-21.6, 1.36, -58.8), Vector3(0, 90, 0))
	if r1:
		register_anim("anom_radio_dial_jitter", r1, {"anomaly_id": "ANOM_18", "seed": 1.0})
	add_interactable("radio_1", "radio", "[E] TUNE GUARD RADIO (50.4 Hz)", Vector3(-21.6, 1.45, -58.5), Vector3(0.9, 0.9, 0.9), "ANOM_18")
	add_interactable("page_1", "page", "[E] PICK UP TORN LOGBOOK PAGE #1", Vector3(-21.6, 1.0, -53.4), Vector3(0.9, 0.9, 0.9), "", {"page_id": "page_1"})
	add_interactable("pickup_tape_02", "story_tape", "[E] PICK UP PATROL CASSETTE #02", Vector3(-21.6, 1.0, -54.7), Vector3(0.9, 0.9, 0.9), "", {"tape_id": "tape_02_milan_shift"})
	add_interactable("pickup_doc_varga", "story_doc", "[E] INSPECT PERSONNEL MEMO", Vector3(-21.6, 1.45, -58.2), Vector3(0.9, 0.9, 0.9), "", {"doc_id": "doc_varga_memo"})
	_spawn_battery_pickup("battery_pack_1", Vector3(-21.6, 0.92, -54.0), "Guard Office Shelf")

	spawn_glb("watchmans_clock", Vector3(-13.28, 1.2, -56.8), Vector3(0, 90, 0))
	add_interactable("clock_gate", "clock", "[E] STAMP WATCHMAN'S CLOCK #1", Vector3(-12.7, 1.35, -56.8), Vector3(0.9, 0.9, 0.9))

	var doppel := spawn_glb("humanoid_guard", Vector3(-14.5, 0.0, -62.2), Vector3.ZERO)
	if doppel:
		doppel.name = "Anom_Booth_Doppel"
		register_dynamic("anom_booth_doppel", doppel)
		register_anomaly_visual("ANOM_08", doppel)


func _spawn_battery_pickup(pid: String, pos: Vector3, loc_label: String) -> void:
	var vis := spawn_glb("battery_pack", pos, Vector3(0, 25, 0))
	var area := add_interactable(pid, "battery_pickup", "[E] PICK UP 4.5V BATTERY (%s)" % loc_label, pos + Vector3(0, 0.25, 0), Vector3(1.1, 1.1, 1.1))
	if vis:
		area.set_meta("visual_node", vis)
