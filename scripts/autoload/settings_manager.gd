extends Node

signal settings_changed

const SETTINGS_PATH := "user://javor_settings.json"

var config: Dictionary = {}


func _enter_tree() -> void:
	config = _default_config()
	load_settings()


func _ready() -> void:
	apply_all()


func _default_config() -> Dictionary:
	return {
		# Display
		"resolution": "1280x720",
		"display_mode": 0, # 0=Windowed, 1=Fullscreen, 2=Borderless
		"vsync": true,
		"fps_limit": 0, # 0=Unlimited, 30, 60, 120
		"brightness": 1.08,
		"gamma": 1.0,
		"contrast": 1.0,
		"fog_intensity": 1.0,
		"flashlight_intensity": 1.0,
		"fov": 72.0,
		# Graphics & PS1 Retro Rendering
		"quality_preset": 2, # 0=Low, 1=Medium, 2=High
		"shadows": true,
		"fog_enabled": true,
		"msaa": 0, # Authentic crisp PS1 edges by default
		"view_distance": 220.0,
		"ps1_resolution": "512x288", # 426x240 (Authentic PS1), 512x288 (Enhanced), 640x360 (Higher-Res Retro)
		"ps1_texture_filter": "nearest", # nearest, linear
		"ps1_shadow_quality": "blocky", # blocky, sharp, off
		"ps1_dithering": 0.72,
		"ps1_vertex_jitter": 0.55,
		"ps1_color_depth": 15, # 15 (RGB555), 18, 24
		# Audio
		"vol_master": 0.90,
		"vol_music": 0.78,
		"vol_env": 0.88,
		"vol_dialogue": 0.95,
		"vol_sfx": 0.88,
		"vol_headphones": 0.85,
		"reduce_ui_sfx": false,
		# Gameplay
		"mouse_sensitivity": 1.0,
		"controller_sensitivity": 1.0,
		"invert_y": false,
		"head_bob": 1.0,
		"camera_shake": 1.0,
		"toggle_sprint": false,
		"hold_interact": false,
		"skip_tutorial": false,
		"difficulty": "standard", # story, standard, intense
		"key_notebook": KEY_N,
		"key_headphones": KEY_H,
		"key_flashlight": KEY_F,
		# Accessibility
		"subtitle_size": 1, # 0=Small, 1=Medium, 2=Large
		"subtitle_bg": true,
		"subtitle_speaker": true,
		"high_contrast": false,
		"prompt_size": 1, # 0=Normal, 1=Medium, 2=Large
		"reduce_shake": false,
		"film_grain": 0.28, # Restrained subtle analog feel by default
		"audio_cues": false,
		"show_sanity_meter": false,
		"nav_assist": "subtle", # off, subtle (default), clear
		# Language
		"language": "en",
	}


func get_val(key: String, default_val: Variant = null) -> Variant:
	return config.get(key, default_val)


func set_val(key: String, value: Variant, auto_apply: bool = true) -> void:
	config[key] = value
	if auto_apply:
		apply_all()


func reset_defaults() -> void:
	config = _default_config()
	save_settings()
	apply_all()


func save_settings() -> void:
	var fa := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if fa:
		fa.store_string(JSON.stringify(config, "\t"))
		fa.close()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var fa := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not fa:
		return
	var parsed: Variant = JSON.parse_string(fa.get_as_text())
	fa.close()
	if parsed is Dictionary:
		for k in (parsed as Dictionary).keys():
			config[str(k)] = parsed[k]


func remap_key(action_name: String, keycode: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	InputMap.action_erase_events(action_name)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action_name, ev)
	if action_name == "notebook_key":
		config["key_notebook"] = keycode
	elif action_name == "toggle_headphones":
		config["key_headphones"] = keycode
	elif action_name == "flashlight":
		config["key_flashlight"] = keycode
	emit_signal("settings_changed")


func apply_all() -> void:
	# 1. Localization
	var loc := get_node_or_null("/root/LocalizationManager")
	if loc and loc.has_method("set_language"):
		loc.set_language(str(config.get("language", "en")))

	# 2. Keybindings
	if InputMap.has_action("notebook_key"):
		_apply_single_key("notebook_key", int(config.get("key_notebook", KEY_N)))
	if InputMap.has_action("toggle_headphones"):
		_apply_single_key("toggle_headphones", int(config.get("key_headphones", KEY_H)))
	if InputMap.has_action("flashlight"):
		_apply_single_key("flashlight", int(config.get("key_flashlight", KEY_F)))

	# 3. Audio Buses
	_set_bus_linear("Master", float(config.get("vol_master", 0.90)))
	_set_bus_linear("EnvLayer", float(config.get("vol_env", 0.88)))
	_set_bus_linear("LifeLayer", float(config.get("vol_env", 0.88)))
	_set_bus_linear("SupernaturalLayer", float(config.get("vol_sfx", 0.88)))
	_set_bus_linear("HeadphoneMusic", float(config.get("vol_headphones", 0.85)))

	# 4. Engine FPS & Display (only modify window when not headless)
	Engine.max_fps = int(config.get("fps_limit", 0))
	if DisplayServer.get_name() != "headless":
		var mode := int(config.get("display_mode", 0))
		if mode == 1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif mode == 2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var res_parts := str(config.get("resolution", "1280x720")).split("x")
			if res_parts.size() == 2:
				var rw := clampi(int(res_parts[0]), 960, 3840)
				var rh := clampi(int(res_parts[1]), 540, 2160)
				DisplayServer.window_set_size(Vector2i(rw, rh))
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if bool(config.get("vsync", true)) else DisplayServer.VSYNC_DISABLED
		)
		var vp := get_viewport()
		if vp:
			var aa := int(config.get("msaa", 1))
			vp.msaa_3d = Viewport.MSAA_4X if aa == 2 else (Viewport.MSAA_2X if aa == 1 else Viewport.MSAA_DISABLED)

	emit_signal("settings_changed")


func _apply_single_key(action_name: String, keycode: int) -> void:
	if keycode <= 0:
		return
	InputMap.action_erase_events(action_name)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action_name, ev)


func _set_bus_linear(bus_name: String, linear_val: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var clamped := clampf(linear_val, 0.0, 1.0)
	if clamped <= 0.005:
		AudioServer.set_bus_volume_db(idx, -60.0)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clamped))
