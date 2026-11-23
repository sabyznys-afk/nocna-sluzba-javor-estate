class_name AssetRegistry
extends RefCounted

const CATEGORIES := [
	"Buildings",
	"Interiors",
	"Props",
	"Vehicles",
	"Vegetation",
	"Environment",
	"Street Furniture",
	"Interactables",
	"Characters",
	"Entities",
	"First-Person Equipment",
	"Animations",
	"Materials",
	"Textures",
	"Audio",
	"Scenes",
]

const REQUIRED_GAME_ASSETS := [
	"res://scenes/main.tscn",
	"res://scenes/main_menu.tscn",
	"res://scenes/district/ResidentialDistrict.tscn",
	"res://scenes/district/OuterEnvironment.tscn",
	"res://scenes/district/ApartmentBuildings.tscn",
	"res://scenes/district/CentralPark.tscn",
	"res://scenes/district/CommercialArea.tscn",
	"res://scenes/district/ParkingArea.tscn",
	"res://scenes/district/GarageComplex.tscn",
	"res://scenes/district/SecurityOffice.tscn",
	"res://scenes/district/TechnicalArea.tscn",
	"res://assets/models/vm_flashlight.glb",
	"res://assets/models/vm_taser.glb",
	"res://assets/models/vm_notebook.glb",
	"res://assets/models/vm_headphones.glb",
	"res://assets/models/vm_keys.glb",
	"res://assets/models/vm_radio.glb",
	"res://assets/models/vm_watch.glb",
	"res://assets/models/vm_pencil_hand.glb",
	"res://assets/models/door_hinged_panel.glb",
	"res://assets/models/utility_pole_90s.glb",
	"res://assets/models/manhole_drain.glb",
	"res://assets/models/shrub_bush_90s.glb",
	"res://assets/models/skoda_favorit.glb",
	"res://assets/models/pine_tree_90s.glb",
	"res://assets/textures/gravel_wet_albedo.png",
	"res://assets/textures/mud_leaves_albedo.png",
	"res://assets/textures/cobble_albedo.png",
	"res://assets/textures/asphalt_wet_albedo.png",
	"res://assets/audio/music_walkman_tape.ogg",
	"res://assets/audio/loop_apartment_life.ogg",
	"res://assets/audio/loop_forest_wind.ogg",
	"res://assets/audio/sfx_headphones_on.ogg",
	"res://assets/audio/sfx_headphones_off.ogg",
	"res://tools/asset_browser/AssetManager.tscn",
]


static func scan_project() -> Dictionary:
	var all_files: Array[String] = []
	_walk_dir("res://", all_files)

	var text_sources: Dictionary = {}
	var broken_paths: Dictionary = {}
	var path_rx := RegEx.new()
	path_rx.compile("res://[A-Za-z0-9_./-]+\\.[A-Za-z0-9]+")

	for fp: String in all_files:
		var ext := fp.get_extension().to_lower()
		if ext in ["gd", "tscn", "gdshader", "cfg"]:
			var fa := FileAccess.open(fp, FileAccess.READ)
			if fa:
				var txt := fa.get_as_text()
				fa.close()
				text_sources[fp] = txt
				if not fp.begins_with("res://tests/"):
					for m: RegExMatch in path_rx.search_all(txt):
						var ref_p: String = m.get_string()
						if ref_p.ends_with(".tmp") or ref_p.contains("%s"):
							continue
						if not FileAccess.file_exists(ref_p) and not ResourceLoader.exists(ref_p):
							broken_paths[ref_p] = fp

	var assets: Array[Dictionary] = []
	var used_count := 0
	var unused_count := 0
	var missing_count := 0
	var broken_count := 0
	var cat_counts: Dictionary = {}
	for c: String in CATEGORIES:
		cat_counts[c] = 0

	var disk_set: Dictionary = {}
	for fp: String in all_files:
		disk_set[fp] = true
		var ext := fp.get_extension().to_lower()
		if not (ext in ["glb", "png", "ogg", "wav", "tscn", "gd", "gdshader"]):
			continue
		if ext == "gd" and not _is_tracked_script_asset(fp):
			continue
		var fsize := _get_file_size(fp)
		var cat := _classify_asset(fp)
		var stem := fp.get_file().get_basename()
		var used_in: Array[String] = []
		for src_path: String in text_sources.keys():
			if src_path == fp:
				continue
			var src_txt: String = str(text_sources[src_path])
			if src_txt.contains(fp) or (ext == "glb" and src_txt.contains("\"%s\"" % stem)) or (ext == "png" and src_txt.contains(stem)):
				used_in.append(src_path)

		# Entrypoint scenes & scripts registered as autoloads in project.godot are implicitly active
		var st_status := "USED"
		var res_ok: bool = fsize > 0
		if ext in ["glb", "tscn"] and res_ok:
			res_ok = ResourceLoader.exists(fp)
		if not res_ok:
			st_status = "BROKEN"
			broken_count += 1
		elif used_in.is_empty() and not _is_root_entrypoint(fp):
			st_status = "UNUSED"
			unused_count += 1
		else:
			st_status = "USED"
			used_count += 1

		cat_counts[cat] = int(cat_counts.get(cat, 0)) + 1
		assets.append({
			"name": fp.get_file(),
			"stem": stem,
			"path": fp,
			"ext": ext,
			"category": cat,
			"status": st_status,
			"size_bytes": fsize,
			"used_in": used_in,
			"usage_count": used_in.size(),
		})

	var missing_list: Array[String] = []
	for req_p: String in REQUIRED_GAME_ASSETS:
		if not disk_set.has(req_p) and not ResourceLoader.exists(req_p):
			missing_list.append(req_p)
			missing_count += 1
			var cat_m := _classify_asset(req_p)
			cat_counts[cat_m] = int(cat_counts.get(cat_m, 0)) + 1
			assets.append({
				"name": req_p.get_file(),
				"stem": req_p.get_file().get_basename(),
				"path": req_p,
				"ext": req_p.get_extension().to_lower(),
				"category": cat_m,
				"status": "MISSING",
				"size_bytes": 0,
				"used_in": [],
				"usage_count": 0,
			})

	for bp: String in broken_paths.keys():
		broken_count += 1
		var cat_b := _classify_asset(bp)
		assets.append({
			"name": bp.get_file(),
			"stem": bp.get_file().get_basename(),
			"path": bp,
			"ext": bp.get_extension().to_lower(),
			"category": cat_b,
			"status": "BROKEN",
			"size_bytes": 0,
			"used_in": [str(broken_paths[bp])],
			"usage_count": 1,
		})

	var req_present := REQUIRED_GAME_ASSETS.size() - missing_list.size()
	var comp_pct := float(req_present) / float(maxi(1, REQUIRED_GAME_ASSETS.size())) * 100.0

	return {
		"assets": assets,
		"missing": missing_list,
		"completeness": {
			"required_total": REQUIRED_GAME_ASSETS.size(),
			"required_present": req_present,
			"percent": comp_pct,
		},
		"stats": {
			"total_assets": assets.size(),
			"used": used_count,
			"unused": unused_count,
			"missing": missing_count,
			"broken": broken_count,
			"categories": cat_counts,
		},
	}


static func _walk_dir(dir_path: String, out: Array[String]) -> void:
	var da := DirAccess.open(dir_path)
	if da == null:
		return
	da.list_dir_begin()
	var nm := da.get_next()
	while not nm.is_empty():
		if nm.begins_with(".") or nm == "addons":
			nm = da.get_next()
			continue
		var full := (dir_path.path_join(nm) if dir_path != "res://" else "res://" + nm)
		if da.current_is_dir():
			_walk_dir(full, out)
		else:
			out.append(full)
		nm = da.get_next()
	da.list_dir_end()


static func _get_file_size(res_path: String) -> int:
	var fa := FileAccess.open(res_path, FileAccess.READ)
	if fa == null:
		return 0
	var sz := fa.get_length()
	fa.close()
	return sz


static func _is_tracked_script_asset(fp: String) -> bool:
	return (
		fp.contains("animation_hub.gd")
		or fp.contains("retro_materials.gd")
		or fp.contains("physical_door.gd")
		or fp.contains("interactive_prop.gd")
		or fp.contains("interactable.gd")
		or fp.contains("guard_controller.gd")
		or fp.contains("guard_viewmodel.gd")
		or fp.contains("anomaly_director.gd")
	)


static func _is_root_entrypoint(fp: String) -> bool:
	return fp in [
		"res://scenes/main_menu.tscn",
		"res://scenes/main.tscn",
		"res://tools/asset_browser/AssetManager.tscn",
		"res://scripts/systems/animation_hub.gd",
		"res://scripts/systems/retro_materials.gd",
	]


static func _classify_asset(fp: String) -> String:
	var ext := fp.get_extension().to_lower()
	var nm := fp.get_file().get_basename().to_lower()
	if ext == "ogg" or ext == "wav":
		return "Audio"
	if ext == "tscn":
		if fp.contains("/district/"):
			if nm in ["apartmentbuildings", "garagecomplex", "securityoffice", "technicalarea", "commercialarea"]:
				return "Buildings"
			return "Environment"
		return "Scenes"
	if ext == "gdshader":
		return "Environment"
	if ext == "gd":
		if nm in ["physical_door", "interactive_prop", "interactable"]:
			return "Interactables"
		if nm.contains("guard"):
			return "Characters"
		if nm.contains("animation"):
			return "Animations"
		if nm.contains("material"):
			return "Materials"
		return "Entities"
	if ext == "png":
		if nm.begins_with("sign_") or nm.begins_with("billboard_"):
			return "Street Furniture"
		if nm.begins_with("poster_") or nm.begins_with("district_map"):
			return "Props"
		return "Textures"
	# .glb models
	if nm.begins_with("vm_"):
		return "First-Person Equipment"
	if nm.begins_with("anom_") or nm == "entity_shadow":
		return "Entities"
	if nm == "humanoid_guard":
		return "Characters"
	if nm in ["skoda_favorit", "skoda_120", "lada_sedan", "lada_van", "trabant_601", "old_bicycle"]:
		return "Vehicles"
	if nm in ["pine_tree_90s", "dead_oak_tree", "shrub_bush_90s"]:
		return "Vegetation"
	if nm in ["panelak_balcony", "panelak_entrance", "sta_antenna_mast", "red_bulkhead_door", "door_hinged_panel"]:
		return "Buildings"
	if nm in ["streetlamp_sodium", "bus_stop_90s", "carriage_gate", "courtyard_bench", "payphone_box", "utility_pole_90s", "manhole_drain"]:
		return "Street Furniture"
	if nm in ["guard_booth_desk", "wooden_chair", "crt_tv_set", "grandfather_clock", "shop_shelf", "shop_fridge", "cash_register_90s", "tesla_crt_monitor", "rotary_phone"]:
		return "Interiors"
	if nm in ["medieval_well", "park_gazebo", "playground_swing", "playground_slide", "chapel_shrine"]:
		return "Environment"
	return "Props"
