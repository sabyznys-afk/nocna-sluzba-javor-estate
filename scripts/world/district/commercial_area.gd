class_name CommercialAreaBuilder
extends DistrictBuilderBase


func build_module(is_showcase: bool = false) -> void:
	if is_showcase:
		return
	var linoleum: StandardMaterial3D = RetroMaterialsLib.get_material("tile_linoleum")
	var dark_plaster: StandardMaterial3D = RetroMaterialsLib.get_material("plaster_dark")
	var hall_beige: StandardMaterial3D = RetroMaterialsLib.get_material("hall_beige")
	var ochre: StandardMaterial3D = RetroMaterialsLib.get_material("plaster")
	var wood: StandardMaterial3D = RetroMaterialsLib.get_material("wood_dark")
	var brick: StandardMaterial3D = RetroMaterialsLib.get_material("brick_cellar")
	var concrete: StandardMaterial3D = RetroMaterialsLib.get_material("concrete")
	var glass_win: StandardMaterial3D = RetroMaterialsLib.get_material("window_dark")
	var shutter: StandardMaterial3D = RetroMaterialsLib.get_material("shutter")
	var iron: StandardMaterial3D = RetroMaterialsLib.get_material("iron")
	var amber_mat: StandardMaterial3D = RetroMaterialsLib.get_material("window_amber")

	# =========================================================================
	# 1. POTRAVINY JEDNOTA — REDESIGNED 1996 GROCERY STORE & REAR STORAGE ROOM
	#    (X: +42..+56, Z: +6..+22, center +49, 0, +14)
	# =========================================================================
	_build_shop_shell("Jednota", Vector3(49.0, 0.0, 14.0), Vector2(14.0, 16.0), linoleum, hall_beige, true, true)
	add_sign_board("Sign_Jednota", "sign_jednota", Vector3(41.7, 3.35, 14.0), Vector2(4.4, 1.25), Vector3(0, -90, 0))
	add_sign_board("JednotaPoster_Ext", "grocery_posters_1996", Vector3(41.72, 1.65, 10.2), Vector2(1.45, 1.45), Vector3(0, -90, 0))
	add_sign_board("JednotaPoster_Int", "grocery_posters_1996", Vector3(49.0, 2.05, 21.75), Vector2(1.65, 1.65), Vector3(0, 180, 0))

	# Dual Ceiling Fluorescent Fixtures + Wall Switch
	spawn_glb("fluorescent_fixture_96", Vector3(46.2, 3.64, 11.2), Vector3(0, 90, 0))
	spawn_glb("fluorescent_fixture_96", Vector3(46.2, 3.64, 17.2), Vector3(0, 90, 0))
	spawn_glb("fluorescent_fixture_96", Vector3(53.8, 3.64, 14.0), Vector3(0, 90, 0))
	var jed_light := _add_fluorescent(Vector3(47.2, 3.45, 14.2), Color(0.86, 0.94, 0.88), false)
	var jed_back_light := _add_fluorescent(Vector3(53.8, 3.45, 14.0), Color(0.92, 0.86, 0.68), true)
	add_interactive_prop("jednota_switch", "switch", Vector3(42.25, 1.35, 12.5), 90.0, [jed_light, jed_back_light])
	add_physical_door("jednota_front_door", "interior", Vector3(42.0, 0.02, 13.38), -90.0, 88.0, false, "", 1.24)
	add_physical_door("jednota_rear_door", "steel", Vector3(56.0, 0.02, 13.42), -90.0, -88.0, false, "", 1.15)

	# Interior Partition separating Sales Floor (X:42..51.8) from Rear Storage Room (X:52.0..56.0)
	add_solid_box("JednotaStorageWall_S", Vector3(52.0, 1.9, 9.2), Vector3(0.24, 3.8, 6.2), dark_plaster)
	add_solid_box("JednotaStorageWall_N", Vector3(52.0, 1.9, 18.8), Vector3(0.24, 3.8, 6.2), dark_plaster)
	add_solid_box("JednotaStorageWall_Hdr", Vector3(52.0, 3.05, 14.0), Vector3(0.24, 1.5, 3.4), dark_plaster)
	add_physical_door("jednota_storage_door", "interior", Vector3(52.0, 0.02, 13.40), -90.0, -88.0, false, "", 1.15)

	# Stocked 1996 Grocery Display Gondolas + Perimeter Shelves + Refrigerators
	for gz: float in [9.6, 13.4, 17.2]:
		spawn_glb("grocery_display_island", Vector3(47.6, 0.02, gz), Vector3.ZERO)
		add_invisible_collider("JednotaIslandCol_%d" % int(gz), Vector3(47.6, 0.88, gz), Vector3(2.45, 1.76, 0.85))
	spawn_glb("shop_shelf", Vector3(46.0, 0.02, 6.6), Vector3.ZERO)
	spawn_glb("shop_shelf", Vector3(49.2, 0.02, 6.6), Vector3.ZERO)
	spawn_glb("shop_fridge", Vector3(51.3, 0.02, 9.6), Vector3(0, 90, 0))
	spawn_glb("shop_fridge", Vector3(51.3, 0.02, 11.5), Vector3(0, 90, 0))
	add_invisible_collider("JednotaFridgeCol", Vector3(51.3, 1.0, 10.55), Vector3(0.85, 2.0, 3.5))
	add_spatial_sound("loop_sodium_buzz", Vector3(51.3, 1.5, 10.5), 9.0, -18.0, is_showcase)

	# Checkout Counter, Cash Register, Divider Bar & Shopping Baskets
	add_solid_box("JednotaCounter", Vector3(44.2, 0.50, 18.8), Vector3(1.1, 0.96, 3.4), wood)
	add_mesh_box("JednotaCounterTop", Vector3(44.2, 1.00, 18.8), Vector3(1.18, 0.05, 3.48), concrete)
	spawn_glb("cash_register_90s", Vector3(44.2, 1.03, 18.8), Vector3(0, -90, 0))
	add_solid_box("JednotaBasketStack", Vector3(43.2, 0.32, 16.4), Vector3(0.45, 0.60, 0.35), iron)
	_spawn_battery_pickup("battery_pack_3", Vector3(44.2, 1.04, 17.4), "Jednota Checkout")
	add_interactable("page_3", "page", "[E] PICK UP TORN LOGBOOK PAGE #3", Vector3(47.6, 0.9, 15.2), Vector3(1.1, 1.1, 1.1), "", {"page_id": "page_3"})

	# Rear Storage Room Details: Pallets, Crates, Electrical Panel & Delivery Manifest Clue
	add_solid_box("JedStoragePallet1", Vector3(54.2, 0.42, 8.2), Vector3(1.4, 0.84, 1.8), wood)
	add_solid_box("JedStoragePallet2", Vector3(54.2, 0.56, 19.6), Vector3(1.4, 1.12, 1.6), wood)
	spawn_glb("electrical_panel_96", Vector3(52.25, 1.55, 16.4), Vector3(0, 90, 0))
	add_interactable("jednota_manifest", "prop_inspect", "[E] INSPECT JEDNOTA DELIVERY MANIFEST", Vector3(54.2, 1.05, 8.2), Vector3(1.2, 1.0, 1.2), "", {
		"speaker": "MARTIN KOVÁČ",
		"note": "Jednota Delivery Slip (Nov 1996): 'Rear steel door left unlatched twice after midnight deliveries. Check lock every patrol.'"
	})

	# =========================================================================
	# 2. VEČIERKA NIGHT SHOP (X: +42..+56, Z: -8..+4, center +49, 0, -2)
	# =========================================================================
	_build_shop_shell("Vecierka", Vector3(49.0, 0.0, -2.0), Vector2(14.0, 12.0), linoleum, dark_plaster, true, true)
	add_sign_board("Sign_Vecierka", "sign_vecierka", Vector3(41.7, 3.35, -2.0), Vector2(4.0, 1.15), Vector3(0, -90, 0))
	add_sign_board("VecierkaPoster_Int", "grocery_posters_1996", Vector3(49.0, 2.0, 3.75), Vector2(1.4, 1.4), Vector3(0, 180, 0))
	spawn_glb("fluorescent_fixture_96", Vector3(48.5, 3.64, -2.0), Vector3(0, 90, 0))
	var vec_light := _add_fluorescent(Vector3(48.5, 3.45, -2.0), Color(0.78, 0.90, 0.96), true)
	add_interactive_prop("vecierka_switch", "switch", Vector3(42.25, 1.35, -3.5), 90.0, [vec_light])
	add_physical_door("vecierka_front_door", "interior", Vector3(42.0, 0.02, -2.62), -90.0, 88.0, false, "", 1.24)

	spawn_glb("grocery_display_island", Vector3(48.8, 0.02, -4.4), Vector3.ZERO)
	add_invisible_collider("VecierkaIslandCol", Vector3(48.8, 0.88, -4.4), Vector3(2.45, 1.76, 0.85))
	spawn_glb("shop_shelf", Vector3(48.5, 0.02, -7.2), Vector3.ZERO)
	spawn_glb("shop_fridge", Vector3(54.2, 0.02, -4.5), Vector3(0, 90, 0))
	add_solid_box("VecierkaCounter", Vector3(45.2, 0.50, 1.5), Vector3(2.8, 0.96, 0.9), wood)
	spawn_glb("cash_register_90s", Vector3(45.2, 1.0, 1.5), Vector3(0, 180, 0))
	# Dana Bieliková visual & daily counter routine driven by NPCScheduleManager (char_dana.glb)
	add_interactable("npc_dana", "story_npc", "[E] TALK TO DANA BIELIKOVÁ (VEČIERKA)", Vector3(45.2, 1.1, 0.8), Vector3(1.8, 2.0, 1.6), "", {"char_id": "dana"})
	add_interactable("pickup_tape_03", "story_tape", "[E] PICK UP CASSETTE TAPE #03", Vector3(58.0, 0.65, 2.0), Vector3(1.2, 1.2, 1.2), "", {"tape_id": "tape_03_stairwell"})
	add_interactable("door_notary", "door", "[E] INSPECT BACK STORAGE LEDGER", Vector3(53.2, 1.2, -2.0), Vector3(1.5, 2.0, 1.5), "ANOM_17", {"door_id": "notary"})

	# =========================================================================
	# 3. TRAFIKA NEWSSTAND KIOSK — COMPLETE 1996 EXTERIOR + INTERIOR REDESIGN
	#    (X: +36.2..+40.4, Z: -13.0..-7.0, center +38.3, 0, -10.0)
	# =========================================================================
	var kiosk_green := StandardMaterial3D.new()
	kiosk_green.albedo_color = Color(0.16, 0.25, 0.22)
	kiosk_green.metallic = 0.35
	kiosk_green.roughness = 0.58

	add_solid_box("TrafikaFloor", Vector3(38.3, 0.04, -10.0), Vector3(4.3, 0.08, 6.2), linoleum)
	add_solid_box("TrafikaRoof", Vector3(38.3, 2.95, -10.0), Vector3(4.6, 0.24, 6.6), shutter)
	# Solid East & North Walls
	add_solid_box("TrafikaWall_E", Vector3(40.35, 1.48, -10.0), Vector3(0.18, 2.9, 6.0), kiosk_green)
	add_solid_box("TrafikaWall_N", Vector3(38.3, 1.48, -7.05), Vector3(4.2, 2.9, 0.18), kiosk_green)
	# South Wall split around enterable Staff PhysicalDoor (X: 37.8..38.85)
	add_solid_box("TrafikaWall_SW", Vector3(37.0, 1.48, -12.95), Vector3(1.6, 2.9, 0.18), kiosk_green)
	add_solid_box("TrafikaWall_SE", Vector3(39.6, 1.48, -12.95), Vector3(1.5, 2.9, 0.18), kiosk_green)
	add_solid_box("TrafikaWall_SHdr", Vector3(38.32, 2.55, -12.95), Vector3(1.2, 0.72, 0.18), kiosk_green)
	add_physical_door("trafika_staff_door", "steel", Vector3(37.80, 0.06, -12.95), 0.0, -88.0, false, "", 1.05)

	# West Storefront Wall with Recessed Glass Service Window Opening (Z: -11.3..-8.7)
	add_solid_box("TrafikaFront_N", Vector3(36.30, 1.48, -7.85), Vector3(0.18, 2.9, 1.65), kiosk_green)
	add_solid_box("TrafikaFront_S", Vector3(36.30, 1.48, -12.15), Vector3(0.18, 2.9, 1.65), kiosk_green)
	add_solid_box("TrafikaFront_Apron", Vector3(36.30, 0.54, -10.0), Vector3(0.18, 1.08, 2.7), kiosk_green)
	add_solid_box("TrafikaFront_Hdr", Vector3(36.30, 2.54, -10.0), Vector3(0.18, 0.72, 2.7), kiosk_green)
	# Slightly translucent dirty window glass with pass-through slot at bottom
	var traf_glass := StandardMaterial3D.new()
	traf_glass.albedo_color = Color(0.58, 0.68, 0.66, 0.24)
	traf_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	traf_glass.roughness = 0.28
	add_mesh_box("TrafikaWindow", Vector3(36.30, 1.72, -10.0), Vector3(0.05, 0.92, 2.55), traf_glass)

	# Custom 1996 Trafika Fittings GLB (Canopy awning, shutter roll hood, magazine rack, coin tray, lottery box)
	spawn_glb("trafika_kiosk_96", Vector3(36.22, 0.04, -10.0), Vector3(0, -90, 0))
	add_sign_board("Sign_Trafika", "sign_trafika", Vector3(36.12, 3.05, -10.0), Vector2(3.6, 0.95), Vector3(0, -90, 0))
	add_sign_board("TrafikaAds1996", "trafika_ads_1996", Vector3(36.18, 1.55, -7.9), Vector2(1.25, 1.25), Vector3(0, -90, 0))
	add_sign_board("TrafikaPoster", "poster_1995", Vector3(36.18, 1.55, -12.1), Vector2(0.95, 1.25), Vector3(0, -90, 0))

	# Trafika Interior Workspace: Counter, Storage Boxes, Old Phone, Heater, Fluorescent Lamp & Vendor Zuzana!
	spawn_glb("fluorescent_fixture_96", Vector3(38.3, 2.78, -10.0), Vector3(0, 90, 0))
	var traf_light := OmniLight3D.new()
	traf_light.name = "TrafikaInteriorLight"
	traf_light.position = Vector3(38.0, 2.55, -10.0)
	traf_light.light_color = Color(0.98, 0.90, 0.70)
	traf_light.light_energy = 2.15
	traf_light.omni_range = 9.0
	add_child(traf_light)
	register_anim("anom_neon_sign_buzz", traf_light, {"energy": 2.15, "seed": 7.2})

	# Exterior Shop & Newsstand Canopy Lights (Commercial Promenade readability!)
	for shop_l: Array in [
		["TrafikaExtLight", Vector3(35.3, 2.65, -10.0), Color(1.0, 0.86, 0.56), 2.8],
		["VecierkaExtLight", Vector3(41.1, 2.95, -2.0), Color(0.84, 0.94, 1.0), 2.4],
		["JednotaExtLight", Vector3(41.1, 2.95, 14.0), Color(0.90, 0.96, 0.88), 2.4],
	]:
		var sl := OmniLight3D.new()
		sl.name = str(shop_l[0])
		sl.position = shop_l[1]
		sl.light_color = shop_l[2]
		sl.light_energy = float(shop_l[3])
		sl.omni_range = 10.5
		sl.distance_fade_enabled = true
		add_child(sl)

	add_solid_box("TrafikaIntCounter", Vector3(36.72, 0.50, -10.0), Vector3(0.68, 0.96, 2.8), wood)
	add_solid_box("TrafikaBackShelf", Vector3(39.85, 1.15, -9.8), Vector3(0.55, 2.2, 4.4), wood)
	add_solid_box("TrafikaBox1", Vector3(39.4, 0.28, -7.8), Vector3(0.65, 0.50, 0.55), ochre)
	add_solid_box("TrafikaBox2", Vector3(39.35, 0.72, -7.85), Vector3(0.52, 0.38, 0.48), ochre)
	spawn_glb("rotary_phone", Vector3(36.75, 1.00, -10.95), Vector3(0, 90, 0))
	add_solid_box("TrafikaHeater", Vector3(38.9, 0.25, -11.6), Vector3(0.45, 0.42, 0.22), iron)
	add_mesh_box("TrafikaHeaterCoil", Vector3(38.66, 0.25, -11.6), Vector3(0.03, 0.18, 0.16), amber_mat)

	# Loose wind-blown newspaper sheets outside Trafika window
	var paper_m := StandardMaterial3D.new()
	paper_m.albedo_color = Color(0.74, 0.72, 0.65)
	paper_m.roughness = 0.90
	var loose_p := add_mesh_box("TrafikaLoosePaper", Vector3(35.3, 0.02, -9.2), Vector3(0.32, 0.008, 0.44), paper_m, Vector3(0, 24, 0))
	register_anim("anom_hanging_sheet_flutter", loose_p, {"seed": 4.1})

	# Prompt 06 Part 12.3 Newsstand Storytelling Dressing: newspaper stacks, change tray, mug, price tags & stock sheet
	add_mesh_box("TrafikaNewsStack1", Vector3(36.75, 1.04, -9.6), Vector3(0.32, 0.12, 0.24), paper_m, Vector3(0, 6, 0))
	add_mesh_box("TrafikaNewsStack2", Vector3(36.75, 1.03, -10.35), Vector3(0.30, 0.10, 0.24), paper_m, Vector3(0, -11, 0))
	add_mesh_box("TrafikaChangeTray", Vector3(36.45, 1.00, -10.0), Vector3(0.16, 0.02, 0.22), iron)
	add_mesh_cyl("TrafikaPersonalMug", Vector3(36.85, 1.03, -9.15), 0.042, 0.10, ochre)
	add_mesh_box("TrafikaStockClipboard", Vector3(36.82, 1.01, -10.65), Vector3(0.22, 0.015, 0.30), wood, Vector3(0, 14, 0))

	# Interactive Trafika Vendor: Zuzana Horváthová (animated char_zuzana.glb managed by NPCScheduleManager)
	add_interactable("npc_zuzana", "story_npc", "[E] TALK TO ZUZANA (TRAFIKA WINDOW)", Vector3(35.75, 1.25, -10.0), Vector3(1.4, 1.6, 2.2), "", {"char_id": "zuzana"})
	add_interactable("trafika_clue_slip", "prop_inspect", "[E] INSPECT PRESS DELIVERY SLIP", Vector3(36.72, 1.12, -9.15), Vector3(0.7, 0.6, 0.7), "", {
		"speaker": "MARTIN KOVÁČ",
		"note": "Trafika Press Log: '22:20 — Stranger in dark utility coat bought 1996 city map and asked for 1984 Block B directory. Walked north into fog.'"
	})

	# =========================================================================
	# 4. OPRAVOVŇA / REPAIR WORKSHOP (X: +42..+56, Z: -25..-11, center +49, 0, -18)
	# =========================================================================
	_build_shop_shell("Opravovna", Vector3(49.0, 0.0, -18.0), Vector2(14.0, 14.0), concrete, brick, true, true)
	add_sign_board("Sign_Opravovna", "sign_opravovna", Vector3(41.7, 3.35, -18.0), Vector2(4.2, 1.18), Vector3(0, -90, 0))
	spawn_glb("fluorescent_fixture_96", Vector3(48.8, 3.64, -18.0), Vector3(0, 90, 0))
	var opr_light := _add_fluorescent(Vector3(48.8, 3.45, -18.0), Color(0.92, 0.78, 0.45), true)
	add_interactive_prop("opravovna_switch", "switch", Vector3(42.25, 1.35, -19.5), 90.0, [opr_light])
	add_physical_door("opravovna_front_door", "steel", Vector3(42.0, 0.02, -18.62), -90.0, 88.0, false, "", 1.24)
	spawn_glb("electrical_panel_96", Vector3(42.25, 1.55, -14.8), Vector3(0, 90, 0))

	add_solid_box("WorkshopBench", Vector3(53.2, 0.50, -23.0), Vector3(4.2, 0.96, 1.0), wood)
	var r2 := spawn_glb("transistor_radio", Vector3(52.5, 1.0, -23.0), Vector3(0, 180, 0))
	if r2:
		register_anim("anom_radio_dial_jitter", r2, {"anomaly_id": "ANOM_18", "seed": 2.0})
	add_interactable("radio_2", "radio", "[E] TUNE WORKSHOP RADIO (50.4 Hz)", Vector3(52.5, 1.15, -22.5), Vector3(1.0, 1.0, 1.0), "ANOM_18")
	add_spatial_sound("loop_radio_504", Vector3(52.5, 1.1, -23.0), 7.5, -20.0, is_showcase)
	spawn_glb("grandfather_clock", Vector3(44.2, 0.02, -23.2), Vector3(0, 90, 0))
	add_interactable("door_watchmaker", "door", "[E] INSPECT GRANDFATHER CLOCK", Vector3(44.8, 1.3, -22.6), Vector3(1.5, 2.0, 1.5), "ANOM_15", {"door_id": "watchmaker"})

	var hooks := spawn_glb("butcher_hook_rack", Vector3(53.2, 0.9, -14.8), Vector3(0, 90, 0))
	if hooks:
		hooks.name = "Anom_Butcher_Hooks"
		register_dynamic("anom_butcher_hooks", hooks)
		register_anomaly_visual("ANOM_12", hooks)
		register_anim("anom_butcher_hooks_swing", hooks, {"anomaly_id": "ANOM_12", "seed": 0.9})
		var h_area := add_interactable("butcher_hooks", "anomaly", "[E] INSPECT SWINGING HOOKS", Vector3(53.2, 1.4, -14.8), Vector3(1.8, 2.0, 2.6), "ANOM_12")
		h_area.set_meta("visual_target", hooks)
	add_spatial_sound("chains_sway", Vector3(53.2, 1.8, -14.8), 11.0, -14.0, is_showcase)

	# =========================================================================
	# 5. DELIVERY ALLEY & HORROR EVENT LOCATION F (X: +57..+60)
	# =========================================================================
	for dz: float in [14.0, -2.0, -16.0]:
		spawn_glb("dumpster_90s", Vector3(58.0, 0.0, dz), Vector3(0, -90, 0))
		add_invisible_collider("AlleyDumpsterCol_%d" % int(dz), Vector3(58.0, 0.68, dz), Vector3(1.5, 1.36, 1.2), Vector3(0, -90, 0))
	add_solid_box("AlleyPallet1", Vector3(58.0, 0.45, 7.0), Vector3(1.4, 0.9, 1.8), wood)
	add_solid_box("AlleyPallet2", Vector3(58.0, 0.35, -9.0), Vector3(1.3, 0.7, 1.4), wood)

	spawn_glb("watchmans_clock", Vector3(56.25, 1.15, 10.0), Vector3(0, 90, 0))
	add_interactable("clock_alley", "clock", "[E] STAMP WATCHMAN'S CLOCK #3", Vector3(57.0, 1.35, 10.0), Vector3(1.2, 1.1, 1.1))
	add_interactable("alley_rustle", "horror_hook", "[E] INSPECT DELIVERY CONTAINERS", Vector3(58.0, 1.1, 12.0), Vector3(2.0, 1.6, 2.4), "ANOM_25")
	register_event_hook("event_F_delivery_alley", Vector3(58.0, 1.0, 12.0), "Something moving behind commercial dumpsters")
	# Prompt 06 Night 3 CP3: Unlocked Delivery Alley Service Storage Nook & Cassette 'M. ŠVEC / 12.11.96'
	add_solid_box("AlleyServiceBox", Vector3(56.55, 0.44, 4.2), Vector3(0.85, 0.88, 1.1), wood)
	add_mesh_box("AlleyMilanCassette", Vector3(56.55, 0.90, 4.2), Vector3(0.11, 0.025, 0.07), iron, Vector3(0, 18, 0))
	add_interactable("n3_milan_cassette", "campaign_event", "[E] RECOVER CASSETTE 'M. ŠVEC / 12.11.96' (DELIVERY STORAGE)", Vector3(57.2, 0.95, 4.2), Vector3(1.8, 1.5, 1.8), "", {"event_id": "n3_milan_cassette"})


func _build_shop_shell(tag: String, center: Vector3, sz: Vector2, floor_mat: Material, wall_mat: Material, front_open: bool, back_open: bool) -> void:
	var hw: float = sz.x * 0.5
	var hd: float = sz.y * 0.5
	var roof_mat: Material = RetroMaterialsLib.get_material("concrete")
	add_solid_box(tag + "_Floor", center + Vector3(0, 0.01, 0), Vector3(sz.x, 0.04, sz.y), floor_mat)
	add_solid_box(tag + "_Roof", center + Vector3(0, 3.85, 0), Vector3(sz.x + 0.6, 0.3, sz.y + 0.6), roof_mat)
	add_solid_box(tag + "_Wall_N", center + Vector3(0, 1.9, hd), Vector3(sz.x, 3.8, 0.32), wall_mat)
	add_solid_box(tag + "_Wall_S", center + Vector3(0, 1.9, -hd), Vector3(sz.x, 3.8, 0.32), wall_mat)
	if front_open:
		var side_len: float = (sz.y - 1.30) * 0.5
		add_solid_box(tag + "_FrontW_N", center + Vector3(-hw, 1.9, hd - side_len * 0.5), Vector3(0.32, 3.8, side_len), wall_mat)
		add_solid_box(tag + "_FrontW_S", center + Vector3(-hw, 1.9, -hd + side_len * 0.5), Vector3(0.32, 3.8, side_len), wall_mat)
		add_solid_box(tag + "_FrontW_Hdr", center + Vector3(-hw, 3.0, 0.0), Vector3(0.32, 1.65, 1.5), wall_mat)
	if back_open:
		var back_side: float = (sz.y - 1.25) * 0.5
		add_solid_box(tag + "_BackE_N", center + Vector3(hw, 1.9, hd - back_side * 0.5), Vector3(0.32, 3.8, back_side), wall_mat)
		add_solid_box(tag + "_BackE_S", center + Vector3(hw, 1.9, -hd + back_side * 0.5), Vector3(0.32, 3.8, back_side), wall_mat)
		add_solid_box(tag + "_BackE_Hdr", center + Vector3(hw, 3.0, 0.0), Vector3(0.32, 1.65, 1.4), wall_mat)


func _add_fluorescent(pos: Vector3, col: Color, flicker: bool) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = 1.75
	l.omni_range = 11.5
	l.distance_fade_enabled = true
	l.shadow_enabled = false
	add_child(l)
	if flicker:
		register_anim("anom_neon_sign_buzz", l, {"energy": 1.75, "seed": float(pos.z)})
	return l


func _spawn_battery_pickup(pid: String, pos: Vector3, loc_label: String) -> void:
	var vis := spawn_glb("battery_pack", pos, Vector3(0, 25, 0))
	var area := add_interactable(pid, "battery_pickup", "[E] PICK UP 4.5V BATTERY (%s)" % loc_label, pos + Vector3(0, 0.25, 0), Vector3(1.1, 1.1, 1.1))
	if vis:
		area.set_meta("visual_node", vis)
