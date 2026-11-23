extends Node3D

# Prompt 07 Phase 2 / User Test #1:
# Complete Standalone PS1 Security Office Test Room showcasing:
# - Pixelated 64-256px textures & PS1 spatial vertex jitter
# - Strong dark shadows (DeskGooseneckLamp + CRT green phosphor bounce + dark corners)
# - Distorted low-poly PS1 Jozef Varga standing beside the desk with his flashlight
# - True low-res PS1 Bayer 4x4 dithering & RGB555 post pass

const SecurityOfficeScript = preload("res://scripts/world/district/security_office.gd")
const RetroRenderScript = preload("res://scripts/systems/retro_rendering_controller.gd")
const StylizedLightScript = preload("res://scripts/systems/stylized_lighting_controller.gd")
const CompanionScript = preload("res://scripts/systems/companion_guard_controller.gd")

var office_mod: Node3D
var retro_render: Node
var light_ctrl: Node
var varga_test: Node3D
var test_cam: Camera3D
var post_mat: ShaderMaterial


func _ready() -> void:
	name = "PS1TestOfficeScene"
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.012, 0.016)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.045, 0.064, 0.080)
	env.ambient_light_energy = 0.09
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 2.0
	env.fog_depth_end = 12.5
	env.fog_density = 0.85
	env.fog_light_color = Color(0.020, 0.030, 0.036)
	we.environment = env
	add_child(we)

	office_mod = SecurityOfficeScript.new()
	office_mod.name = "TestSecurityOffice"
	add_child(office_mod)
	office_mod.build_module(false)

	test_cam = Camera3D.new()
	test_cam.name = "PS1TestCamera"
	test_cam.position = Vector3(-15.5, 1.55, -54.2)
	test_cam.fov = 68.0
	add_child(test_cam)
	test_cam.look_at(Vector3(-18.6, 1.15, -57.5), Vector3.UP)
	test_cam.current = true

	varga_test = CompanionScript.new()
	add_child(varga_test)
	varga_test.setup_companion(self, test_cam, null)

	var post_layer := CanvasLayer.new()
	post_layer.name = "PS1PostLayer"
	post_layer.layer = 5
	add_child(post_layer)
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh: Shader = load("res://shaders/crt_vhs.gdshader")
	if sh:
		post_mat = ShaderMaterial.new()
		post_mat.shader = sh
		rect.material = post_mat
	post_layer.add_child(rect)

	retro_render = RetroRenderScript.new()
	add_child(retro_render)
	retro_render.setup_retro_rendering(office_mod, post_mat)

	light_ctrl = StylizedLightScript.new()
	add_child(light_ctrl)
	light_ctrl.setup_lighting(self, test_cam)
