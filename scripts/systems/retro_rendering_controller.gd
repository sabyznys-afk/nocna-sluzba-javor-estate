class_name RetroRenderingController
extends Node

# Central PS1 Rendering Pipeline Controller (Prompt 07 Part 1 & Part 9)
# Controls:
# - True low-resolution 3D rendering (426x240 Authentic PS1 / 512x288 Enhanced / 640x360 Retro High)
# - Bayer 4x4 ordered dithering & 15-bit PS1 RGB555 color quantization
# - Per-mesh PS1 Spatial Shader upgrade (subtle vertex jitter + nearest-neighbor pixel textures)
# - Blocky low-res PS1 shadow atlas configuration

const PS1SpatialShader = preload("res://shaders/ps1_spatial.gdshader")

const RES_PRESETS := {
	"426x240": Vector2(426.0, 240.0),
	"512x288": Vector2(512.0, 288.0),
	"640x360": Vector2(640.0, 360.0),
}

var _ps1_materials: Array[ShaderMaterial] = []
var _post_material: ShaderMaterial = null
var _target_viewport: Viewport = null
var converted_mesh_count: int = 0


func _sett() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("SettingsManager") if ml is SceneTree else null


func setup_retro_rendering(world_root: Node, post_shader_mat: ShaderMaterial = null, sub_vp: Viewport = null) -> void:
	name = "RetroRenderingController"
	_post_material = post_shader_mat
	_target_viewport = sub_vp
	if world_root:
		convert_subtree_to_ps1(world_root)
	var sett := _sett()
	if sett and sett.has_signal("settings_changed"):
		if not sett.settings_changed.is_connected(apply_settings):
			sett.settings_changed.connect(apply_settings)
	apply_settings()


func convert_subtree_to_ps1(root_node: Node) -> int:
	# Upgrades opaque 3D geometry to authentic PS1 vertex-jitter + nearest-neighbor pixel rendering
	# while preserving transparent glass, fog slabs, volumetric cones, and CCTV live screens!
	var count: int = 0
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is MeshInstance3D:
			if _apply_ps1_to_mesh(cur as MeshInstance3D):
				count += 1
		for ch in cur.get_children():
			stack.append(ch)
	converted_mesh_count += count
	return count


func _apply_ps1_to_mesh(mi: MeshInstance3D) -> bool:
	if mi.name in ["CCTV_Screen", "SodiumFogCone", "SodiumFogOrb", "TrafikaWindow", "SecWin_N", "SecWin_E"]:
		return false
	if mi.name.begins_with("GroundFog_") or mi.name.begins_with("MidFog_"):
		return false
	var src_mat: Material = mi.material_override
	if src_mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
		src_mat = mi.mesh.surface_get_material(0)
	if not (src_mat is BaseMaterial3D):
		return false
	var bm := src_mat as BaseMaterial3D
	# Keep alpha-blended puddles, volumetric beams, glass panes on nearest filter without vertex-snapping them out of plane
	if bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or bm.blend_mode != BaseMaterial3D.BLEND_MODE_MIX:
		bm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		return false

	# For StandardMaterial3D surfaces with single surface or material_override, wrap cleanly into PS1SpatialShader!
	if mi.material_override != null or (mi.mesh != null and mi.mesh.get_surface_count() == 1):
		var smat := ShaderMaterial.new()
		smat.shader = PS1SpatialShader
		if bm.albedo_texture != null:
			smat.set_shader_parameter("albedo_tex", bm.albedo_texture)
			smat.set_shader_parameter("use_texture", true)
		else:
			smat.set_shader_parameter("use_texture", false)
		smat.set_shader_parameter("albedo_color", bm.albedo_color)
		smat.set_shader_parameter("uv_scale", bm.uv1_scale)
		smat.set_shader_parameter("use_triplanar", bm.uv1_triplanar)
		if bm.emission_enabled:
			smat.set_shader_parameter("emission_color", bm.emission)
			smat.set_shader_parameter("emission_energy", bm.emission_energy_multiplier)
		mi.material_override = smat
		_ps1_materials.append(smat)
		return true

	# Multi-surface GLB meshes: force nearest-neighbor crisp pixel texture filter + matte PS1 response
	if mi.mesh != null:
		for si: int in range(mi.mesh.get_surface_count()):
			var surf_m: Material = mi.mesh.surface_get_material(si)
			if surf_m is BaseMaterial3D:
				(surf_m as BaseMaterial3D).texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				(surf_m as BaseMaterial3D).specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		return true
	return false


func apply_settings() -> void:
	var sett := _sett()
	var res_key: String = str(sett.get_val("ps1_resolution", "512x288")) if sett else "512x288"
	var res_vec: Vector2 = RES_PRESETS.get(res_key, Vector2(512.0, 288.0))
	var dither: float = float(sett.get_val("ps1_dithering", 0.65)) if sett else 0.65
	var jitter: float = float(sett.get_val("ps1_vertex_jitter", 0.45)) if sett else 0.45
	var cdepth: int = int(sett.get_val("ps1_color_depth", 15)) if sett else 15
	var clevels: float = 32.0 if cdepth <= 15 else (64.0 if cdepth <= 18 else 255.0)
	var shad_mode: String = str(sett.get_val("ps1_shadow_quality", "blocky")) if sett else "blocky"
	var bright: float = float(sett.get_val("brightness", 1.08)) if sett else 1.08
	var gam: float = float(sett.get_val("gamma", 1.0)) if sett else 1.0
	var contr: float = float(sett.get_val("contrast", 1.0)) if sett else 1.0

	# 1. Update PS1 Post-Process Shader (low-res nearest-neighbor pixel grid + Bayer dithering + Brightness/Gamma/Contrast)
	if _post_material:
		_post_material.set_shader_parameter("internal_resolution", res_vec)
		_post_material.set_shader_parameter("dither_strength", dither)
		_post_material.set_shader_parameter("color_levels", clevels)
		_post_material.set_shader_parameter("brightness_val", clampf(bright, 0.55, 1.75))
		_post_material.set_shader_parameter("gamma_val", clampf(gam, 0.55, 1.75))
		_post_material.set_shader_parameter("contrast_val", clampf(contr, 0.65, 1.55))

	# 2. Update SubViewport resolution via SubViewportContainer.stretch_shrink if driving Main Menu 3D vignette
	if _target_viewport and _target_viewport is SubViewport:
		var par: Node = _target_viewport.get_parent()
		if par is SubViewportContainer and (par as SubViewportContainer).stretch:
			(par as SubViewportContainer).stretch_shrink = 3 if res_key == "426x240" else 2
		else:
			(_target_viewport as SubViewport).size = Vector2i(int(res_vec.x), int(res_vec.y))

	# 3. Update vertex jitter snap grid across all converted PS1 spatial materials
	var snap_vec: Vector2 = res_vec * 0.5
	var live_mats: Array[ShaderMaterial] = []
	for sm: ShaderMaterial in _ps1_materials:
		if is_instance_valid(sm):
			sm.set_shader_parameter("jitter_strength", jitter)
			sm.set_shader_parameter("snap_resolution", snap_vec)
			live_mats.append(sm)
	_ps1_materials = live_mats

	# 4. Blocky low-res PS1 shadow atlas configuration
	var vp: Viewport = get_viewport()
	if vp:
		vp.positional_shadow_atlas_size = 512 if shad_mode == "blocky" else (1024 if shad_mode == "sharp" else 0)
		vp.msaa_3d = Viewport.MSAA_DISABLED # Authentic crisp PS1 hard polygon edges!


func get_active_resolution() -> Vector2:
	var sett := _sett()
	var res_key: String = str(sett.get_val("ps1_resolution", "512x288")) if sett else "512x288"
	return RES_PRESETS.get(res_key, Vector2(512.0, 288.0))
