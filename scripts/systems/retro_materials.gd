class_name RetroMaterials
extends RefCounted

static var _cache: Dictionary = {}


static func get_material(mat_name: String) -> StandardMaterial3D:
	if _cache.has(mat_name):
		return _cache[mat_name]

	var mat := StandardMaterial3D.new()
	# Prompt 07 PS1 Visual Style: Crisp nearest-neighbor pixelated textures + matte retro response (no glossy PBR!)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED

	match mat_name:
		"cobble":
			_apply_pbr_set(mat, "cobble", Vector3(10.0, 10.0, 1.0), 1.45, 0.08)
		"plaster":
			_apply_pbr_set(mat, "plaster_ochre", Vector3(4.0, 2.5, 1.0), 1.25, 0.0)
		"plaster_dark":
			_apply_pbr_set(mat, "plaster_grey", Vector3(3.5, 2.5, 1.0), 1.25, 0.0)
		"brick_cellar":
			_apply_pbr_set(mat, "brick_cellar", Vector3(3.5, 2.0, 1.0), 1.5, 0.0)
		"wood_dark":
			_apply_pbr_set(mat, "wood_gallery", Vector3(4.0, 4.0, 1.0), 1.3, 0.0)
		"concrete":
			_apply_pbr_set(mat, "concrete_dark", Vector3(3.0, 3.0, 1.0), 1.2, 0.0)
		"shutter":
			_apply_pbr_set(mat, "shutter_metal", Vector3(2.0, 2.0, 1.0), 1.4, 0.52)
		"iron":
			_apply_pbr_set(mat, "iron_rusted", Vector3(2.5, 2.5, 1.0), 1.25, 0.72)
		"asphalt_wet":
			_apply_pbr_set(mat, "asphalt_wet", Vector3(8.0, 8.0, 1.0), 1.35, 0.04)
		"panel_concrete":
			_apply_pbr_set(mat, "panel_concrete", Vector3(3.0, 2.5, 1.0), 1.4, 0.0)
		"panel_renovated":
			_apply_pbr_set(mat, "panel_concrete", Vector3(3.0, 2.5, 1.0), 1.1, 0.0)
			mat.albedo_color = Color(0.88, 0.80, 0.66)
		"panel_neglected":
			_apply_pbr_set(mat, "panel_concrete", Vector3(3.0, 2.5, 1.0), 1.6, 0.0)
			mat.albedo_color = Color(0.62, 0.63, 0.60)
		"grass_autumn":
			_apply_pbr_set(mat, "grass_autumn", Vector3(24.0, 24.0, 1.0), 1.2, 0.0)
		"gravel_wet":
			_apply_pbr_set(mat, "gravel_wet", Vector3(12.0, 12.0, 1.0), 1.45, 0.02)
		"mud_leaves":
			_apply_pbr_set(mat, "mud_leaves", Vector3(10.0, 10.0, 1.0), 1.35, 0.0)
		"drainpipe_metal":
			_apply_pbr_set(mat, "iron_rusted", Vector3(2.0, 4.0, 1.0), 1.1, 0.65)
			mat.albedo_color = Color(0.28, 0.30, 0.32)
		"foliage_shrub":
			_apply_pbr_set(mat, "grass_autumn", Vector3(4.0, 4.0, 1.0), 1.4, 0.0)
			mat.albedo_color = Color(0.55, 0.65, 0.45)
		"concrete_curb":
			_apply_pbr_set(mat, "concrete_dark", Vector3(4.0, 1.5, 1.0), 1.25, 0.0)
			mat.albedo_color = Color(0.56, 0.56, 0.54)
		"flowerbed_soil":
			_apply_pbr_set(mat, "mud_leaves", Vector3(3.0, 3.0, 1.0), 1.4, 0.0)
			mat.albedo_color = Color(0.65, 0.58, 0.50)
		"tile_linoleum":
			_apply_pbr_set(mat, "linoleum_worn", Vector3(4.0, 4.0, 1.0), 0.9, 0.0)
			mat.albedo_color = Color(0.86, 0.85, 0.80)
		"terrazzo_tile":
			_apply_pbr_set(mat, "terrazzo_tile", Vector3(4.5, 4.5, 1.0), 0.95, 0.0)
			mat.albedo_color = Color(0.88, 0.88, 0.85)
		"hall_sage":
			_apply_pbr_set(mat, "plaster_grey", Vector3(3.5, 2.5, 1.0), 1.15, 0.0)
			mat.albedo_color = Color(0.56, 0.65, 0.56)
		"hall_bluegrey":
			_apply_pbr_set(mat, "plaster_grey", Vector3(3.5, 2.5, 1.0), 1.15, 0.0)
			mat.albedo_color = Color(0.52, 0.58, 0.64)
		"hall_ochre":
			_apply_pbr_set(mat, "plaster_ochre", Vector3(3.5, 2.5, 1.0), 1.2, 0.0)
			mat.albedo_color = Color(0.74, 0.64, 0.46)
		"hall_beige":
			_apply_pbr_set(mat, "plaster_ochre", Vector3(3.5, 2.5, 1.0), 1.0, 0.0)
			mat.albedo_color = Color(0.78, 0.74, 0.64)
		"wallpaper_90s":
			_apply_pbr_set(mat, "plaster_ochre", Vector3(4.0, 3.0, 1.0), 0.6, 0.0)
			mat.albedo_color = Color(0.68, 0.62, 0.50)
		"sign_vratnica", "sign_hodinarstvo", "sign_notar", "sign_kotolna", "sign_blok14", "poster_1995", \
		"sign_jednota", "sign_vecierka", "sign_trafika", "sign_opravovna", "sign_trafostanica", \
		"sign_bus_stop", "billboard_1995", "district_map_1995", "trafika_ads_1996", "grocery_posters_1996":
			var tex_path: String = "res://assets/textures/%s.png" % mat_name
			if ResourceLoader.exists(tex_path):
				mat.albedo_texture = load(tex_path)
			mat.roughness = 0.58
			mat.metallic = 0.28 if mat_name.begins_with("sign_") else 0.0
		"volumetric_beam":
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat.albedo_color = Color(0.95, 0.68, 0.24, 0.065)
		"red_door":
			_apply_pbr_set(mat, "iron_rusted", Vector3(2.0, 2.0, 1.0), 1.1, 0.38)
			mat.albedo_color = Color(0.75, 0.22, 0.18)
		"window_dark":
			mat.albedo_color = Color(0.035, 0.045, 0.06, 1.0)
			mat.roughness = 0.12
			mat.metallic = 0.28
		"window_amber":
			mat.albedo_color = Color(0.38, 0.27, 0.12, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.88, 0.60, 0.24, 1.0)
			mat.emission_energy_multiplier = 1.65
		"window_tv_blue":
			mat.albedo_color = Color(0.14, 0.22, 0.30, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.32, 0.52, 0.74, 1.0)
			mat.emission_energy_multiplier = 2.0
		"skoda_body":
			mat.albedo_color = Color(0.34, 0.36, 0.32, 1.0)
			mat.roughness = 0.42
			mat.metallic = 0.22
		"shadow_entity":
			mat.albedo_color = Color(0.015, 0.02, 0.03, 0.94)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.emission_enabled = true
			mat.emission = Color(0.06, 0.10, 0.14, 1.0)
			mat.emission_energy_multiplier = 0.55
		"k4_glow":
			mat.albedo_color = Color(0.14, 0.28, 0.18, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.28, 0.82, 0.42, 1.0)
			mat.emission_energy_multiplier = 2.1
		"prop_brass":
			mat.albedo_color = Color(0.55, 0.42, 0.16, 1.0)
			mat.metallic = 0.85
			mat.roughness = 0.34
		_:
			mat.albedo_color = Color(0.24, 0.25, 0.26, 1.0)

	_cache[mat_name] = mat
	return mat


static func _apply_pbr_set(mat: StandardMaterial3D, set_name: String, uv_scale: Vector3, norm_scale: float, metallic_val: float) -> void:
	var alb_path: String = "res://assets/textures/%s_albedo.png" % set_name
	var nrm_path: String = "res://assets/textures/%s_normal.png" % set_name
	var rgh_path: String = "res://assets/textures/%s_roughness.png" % set_name

	if ResourceLoader.exists(alb_path):
		mat.albedo_texture = load(alb_path)
	else:
		mat.albedo_texture = _gen_fallback_noise(64, 64, Color(0.24, 0.24, 0.25), Color(0.14, 0.14, 0.15), set_name.hash())

	if ResourceLoader.exists(nrm_path):
		mat.normal_enabled = false # PS1 aesthetic relies on crisp pixelated albedo, geometry & stark shadows
	if ResourceLoader.exists(rgh_path):
		mat.roughness = 0.94
	else:
		mat.roughness = 0.94

	mat.metallic = clampf(metallic_val * 0.25, 0.0, 0.25)
	mat.uv1_scale = uv_scale


static func _gen_fallback_noise(w: int, h: int, c1: Color, c2: Color, seed_val: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for y in range(h):
		for x in range(w):
			var c: Color = c1.lerp(c2, rng.randf())
			c.a = 1.0
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
