extends SceneTree

# Prompt 08 Part 1.7 — Real Rendered First-Person Lighting Quality Test Route!
# Launches the ACTUAL running game with GPU rendering at normal default brightness,
# teleports the real first-person player camera through all 6 required locations,
# and captures PNG screenshots for visual inspection!

const OUT_DIR := "D:/GameStudioTools/tmp/p8_lighting_screens"

const ROUTE_SPOTS: Array[Dictionary] = [
	{"file": "01_security_office.png",    "pos": Vector3(-16.2, 0.2, -55.4), "look": Vector3(-13.5, 1.35, -54.6), "torch": true},
	{"file": "02_pedestrian_path.png",    "pos": Vector3(-10.5, 0.2, -54.6), "look": Vector3(-2.0, 1.4, -63.0),   "torch": true},
	{"file": "03_parking_lot.png",        "pos": Vector3(8.0, 0.2, -53.0),   "look": Vector3(22.0, 1.1, -56.0),   "torch": true},
	{"file": "04_central_park.png",       "pos": Vector3(-6.0, 0.2, -4.0),   "look": Vector3(-11.0, 1.3, 8.0),    "torch": true},
	{"file": "05_apartment_entrance.png", "pos": Vector3(-32.0, 0.2, 24.5),  "look": Vector3(-32.0, 1.8, 32.0),   "torch": true},
	{"file": "06_basement_corridor.png",  "pos": Vector3(-74.0, -3.9, 16.0), "look": Vector3(-86.0, -2.5, 16.0),  "torch": true},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	create_timer(45.0).timeout.connect(func():
		print("SCREENSHOT_TIMEOUT")
		quit(1)
	)
	call_deferred("_capture_all")


func _capture_all() -> void:
	var gs: Node = root.get_node_or_null("GameState")
	var sett: Node = root.get_node_or_null("SettingsManager")
	if sett:
		sett.set_val("skip_tutorial", true, true)
		sett.set_val("brightness", 1.08, true)
		sett.set_val("gamma", 1.0, true)
		sett.set_val("contrast", 1.0, true)
		sett.set_val("fog_intensity", 1.0, true)
		sett.set_val("flashlight_intensity", 1.0, true)
	if gs:
		gs.tutorial_completed = true
		gs.start_new_shift(1, false, true)

	var main_packed: PackedScene = load("res://scenes/main.tscn")
	var main_inst: Node = main_packed.instantiate()
	root.add_child(main_inst)

	# Hide chapter card overlay cleanly so screenshots show live gameplay immediately
	var hud: Node = main_inst.get_node_or_null("GameHUD")
	if hud and hud.get("chapter_overlay") != null:
		hud.chapter_overlay.visible = false
	if hud and hud.get("dialogue_box") != null:
		hud.dialogue_box.visible = false

	var player: CharacterBody3D = main_inst.get_node_or_null("GuardPlayer") as CharacterBody3D
	var dist: Node3D = main_inst.world_builder.district if main_inst and main_inst.world_builder else null
	var light_c: Node = main_inst.get_node_or_null("StylizedLightingController")

	if player:
		player.capture_mouse(false)
		player.switch_gear("flashlight")
		if not player.flashlight_on:
			player.toggle_flashlight()

	for i: int in range(6):
		await process_frame

	for spot: Dictionary in ROUTE_SPOTS:
		var pos: Vector3 = spot["pos"]
		var look_t: Vector3 = spot["look"]
		if player:
			player.global_position = pos
			var dir: Vector3 = look_t - (pos + Vector3(0.0, 1.56, 0.0))
			player.rotation.y = atan2(-dir.x, -dir.z)
			var horiz: float = Vector2(dir.x, dir.z).length()
			if player.head_pivot:
				player.head_pivot.rotation.x = clampf(atan2(dir.y, maxf(0.01, horiz)), deg_to_rad(-60.0), deg_to_rad(60.0))
			if dist and dist.fog_controller:
				var zinfo: Dictionary = dist.get_zone_for_position(pos)
				dist.fog_controller.apply_zone_atmosphere(str(zinfo.get("id", "parking_lot")), 1)
				dist.fog_controller.update_fog(5.0, pos, 1)
			if light_c and light_c.has_method("update_proximity_shadows"):
				light_c.update_proximity_shadows()

		for _f: int in range(8):
			await process_frame

		var img: Image = root.get_texture().get_image()
		if img:
			var avg_luma: float = 0.0
			var samples: int = 0
			for sy: int in range(0, img.get_height(), 16):
				for sx: int in range(0, img.get_width(), 16):
					var c: Color = img.get_pixel(sx, sy)
					avg_luma += c.r * 0.299 + c.g * 0.587 + c.b * 0.114
					samples += 1
			avg_luma /= maxf(1.0, float(samples))
			var out_p: String = OUT_DIR + "/" + str(spot["file"])
			img.save_png(out_p)
			print("CAPTURED: %s (avg_luma=%.3f)" % [str(spot["file"]), avg_luma])

	if sett:
		sett.set_val("skip_tutorial", false, false)
		sett.save_settings()
	main_inst.queue_free()
	print("LIGHTING_ROUTE_CAPTURE_DONE")
	quit(0)
