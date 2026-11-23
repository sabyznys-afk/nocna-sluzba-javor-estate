class_name DistrictBuilderBase
extends Node3D

const RetroMaterialsLib = preload("res://scripts/systems/retro_materials.gd")
const InteractableNode = preload("res://scripts/world/interactable.gd")

var local_interactables: Array[Area3D] = []
var local_dynamic_nodes: Dictionary = {}
var local_anomaly_nodes: Dictionary = {}
var local_event_hooks: Dictionary = {}
var district_root: Node = null


func set_district_root(root_node: Node) -> void:
	district_root = root_node


func register_interactable(area: Area3D) -> void:
	local_interactables.append(area)
	if district_root and district_root.has_method("on_child_interactable"):
		district_root.on_child_interactable(area)


func register_dynamic(key: String, node: Node3D) -> void:
	if node == null:
		return
	local_dynamic_nodes[key] = node
	if district_root and district_root.has_method("on_child_dynamic"):
		district_root.on_child_dynamic(key, node)


func register_anomaly_visual(anomaly_id: String, node: Node3D) -> void:
	if node == null or anomaly_id.is_empty():
		return
	local_anomaly_nodes[anomaly_id] = node
	if district_root and district_root.has_method("on_child_anomaly_visual"):
		district_root.on_child_anomaly_visual(anomaly_id, node)


func register_anim(anim_name: String, node: Node3D, meta: Dictionary = {}) -> void:
	if node == null:
		return
	if district_root and district_root.has_method("on_child_anim"):
		district_root.on_child_anim(anim_name, node, meta)


func register_event_hook(hook_id: String, pos: Vector3, label: String, extra: Dictionary = {}) -> void:
	var payload := {"pos": pos, "label": label}
	for k in extra.keys():
		payload[k] = extra[k]
	local_event_hooks[hook_id] = payload
	if district_root and district_root.has_method("on_child_event_hook"):
		district_root.on_child_event_hook(hook_id, payload)


func add_spatial_sound(stream_name: String, pos: Vector3, max_dist: float = 16.0, vol_db: float = -12.0, showcase_skip: bool = false) -> void:
	if showcase_skip:
		return
	var p := AudioSynth.create_spatial_loop(stream_name, pos, max_dist, vol_db)
	add_child(p)


func add_solid_box(node_name: String, pos: Vector3, size: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.rotation_degrees = rot_deg
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body


func add_mesh_box(node_name: String, pos: Vector3, size: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO, parent_node: Node3D = null) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.position = pos
	mesh.rotation_degrees = rot_deg
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	if parent_node:
		parent_node.add_child(mesh)
	else:
		add_child(mesh)
	return mesh


func add_mesh_cyl(node_name: String, pos: Vector3, rad: float, height: float, mat: Material, rot_deg: Vector3 = Vector3.ZERO, parent_node: Node3D = null) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.position = pos
	mesh.rotation_degrees = rot_deg
	var cyl := CylinderMesh.new()
	cyl.top_radius = rad
	cyl.bottom_radius = rad
	cyl.height = height
	mesh.mesh = cyl
	mesh.material_override = mat
	if parent_node:
		parent_node.add_child(mesh)
	else:
		add_child(mesh)
	return mesh


func add_invisible_collider(node_name: String, pos: Vector3, size: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.rotation_degrees = rot_deg
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body


func add_stair_ramp(node_name: String, start_pt: Vector3, end_pt: Vector3, width: float, mat: Material) -> void:
	var delta: Vector3 = end_pt - start_pt
	var length: float = maxf(0.1, delta.length())
	var mid: Vector3 = (start_pt + end_pt) * 0.5
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = mid
	body.look_at_from_position(mid, end_pt, Vector3.UP)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, 0.24, length)
	col.shape = shape
	col.position = Vector3(0.0, -0.12, 0.0)
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.24, length)
	mesh.mesh = box
	mesh.position = Vector3(0.0, -0.12, 0.0)
	mesh.material_override = mat
	body.add_child(mesh)
	add_child(body)


func spawn_glb(glb_name: String, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scale_vec: Vector3 = Vector3.ONE, parent_node: Node3D = null) -> Node3D:
	var path: String = "res://assets/models/%s.glb" % glb_name
	if not ResourceLoader.exists(path):
		return null
	var scene: PackedScene = load(path)
	if scene == null:
		return null
	var inst: Node = scene.instantiate()
	if not (inst is Node3D):
		inst.queue_free()
		return null
	var n3d: Node3D = inst
	n3d.position = pos
	n3d.rotation_degrees = rot_deg
	n3d.scale = scale_vec
	if parent_node:
		parent_node.add_child(n3d)
	else:
		add_child(n3d)
	return n3d


func add_sign_board(node_name: String, tex_key: String, pos: Vector3, size_2d: Vector2, rot_deg: Vector3) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.position = pos
	mesh.rotation_degrees = rot_deg
	var quad := QuadMesh.new()
	quad.size = size_2d
	mesh.mesh = quad
	mesh.material_override = RetroMaterialsLib.get_material(tex_key)
	add_child(mesh)
	return mesh


func add_interactable(iid: String, itype: String, prompt: String, pos: Vector3, size: Vector3, anom_id: String = "", extra: Dictionary = {}) -> Area3D:
	var area: Area3D = InteractableNode.new()
	area.name = "Int_" + iid
	area.interact_id = iid
	area.interact_type = itype
	area.prompt_text = prompt
	area.anomaly_id = anom_id
	area.extra_data = extra
	area.position = pos
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	area.add_child(col)
	add_child(area)
	register_interactable(area)
	return area


func add_physical_door(
	door_id: String,
	kind: String,
	pos: Vector3,
	rot_deg_y: float = 0.0,
	swing_deg: float = -88.0,
	locked: bool = false,
	key_id: String = "",
	width: float = 1.05,
	parent_node: Node3D = null
) -> PhysicalDoor:
	var door := PhysicalDoor.new()
	if parent_node:
		parent_node.add_child(door)
	else:
		add_child(door)
	door.setup_door(door_id, kind, pos, rot_deg_y, swing_deg, locked, key_id, width)
	if door.interact_area:
		register_interactable(door.interact_area)
	if district_root and district_root.has_method("on_child_door"):
		district_root.on_child_door(door)
	return door


func add_interactive_prop(
	prop_id: String,
	kind: String,
	pos: Vector3,
	rot_deg_y: float = 0.0,
	lights: Array[Light3D] = [],
	grant_key: String = "",
	grant_battery: bool = false
) -> InteractiveProp:
	var prop := InteractiveProp.new()
	add_child(prop)
	prop.setup_prop(prop_id, kind, pos, rot_deg_y, lights, grant_key, grant_battery)
	var area_child: Area3D = prop.get_node_or_null("PropInt_" + prop_id) as Area3D
	if area_child:
		register_interactable(area_child)
	else:
		for ch: Node in prop.get_children():
			if ch is Area3D:
				register_interactable(ch as Area3D)
				break
	return prop


func add_streetlamp(pos: Vector3, rot_y_deg: float = 0.0, mode: String = "normal", seed_val: float = 0.0) -> void:
	var iron: StandardMaterial3D = RetroMaterialsLib.get_material("iron")
	add_mesh_cyl("LampPole_%d_%d" % [int(pos.x), int(pos.z)], pos + Vector3(0, 2.75, 0), 0.09, 5.5, iron)
	add_invisible_collider("LampCol_%d_%d" % [int(pos.x), int(pos.z)], pos + Vector3(0, 1.3, 0), Vector3(0.28, 2.6, 0.28))
	var head := spawn_glb("streetlamp_sodium", pos + Vector3(0, 5.35, 0), Vector3(0, rot_y_deg, 0))
	if head and mode != "broken":
		# Prompt 08 Part 1.3: Readable downward sodium SpotLight3D pool + soft warm street bounce fill!
		var lamp_light := SpotLight3D.new()
		lamp_light.name = "SodiumPoolSpot"
		lamp_light.light_color = Color(1.0, 0.64, 0.26)
		var base_e: float = 2.4 if mode == "dim" else 4.8
		lamp_light.light_energy = base_e
		lamp_light.spot_range = 17.5
		lamp_light.spot_attenuation = 1.15
		lamp_light.spot_angle = 66.0
		lamp_light.spot_angle_attenuation = 1.45
		lamp_light.shadow_enabled = false # Dynamically promoted by StylizedLightingController within 28m!
		lamp_light.distance_fade_enabled = true
		lamp_light.distance_fade_begin = 38.0
		lamp_light.distance_fade_length = 18.0
		lamp_light.position = Vector3(0.0, -0.05, 1.02)
		lamp_light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		head.add_child(lamp_light)

		# Subtle warm sodium scatter fill so sidewalks, curbs & passers-by stay distinguishable near lamps
		var fill_l := OmniLight3D.new()
		fill_l.name = "SodiumAmbientFill"
		fill_l.light_color = Color(0.96, 0.66, 0.34)
		fill_l.light_energy = 0.45 if mode == "dim" else 0.88
		fill_l.omni_range = 11.5
		fill_l.omni_attenuation = 1.35
		fill_l.shadow_enabled = false
		fill_l.distance_fade_enabled = true
		fill_l.distance_fade_begin = 34.0
		fill_l.distance_fade_length = 14.0
		fill_l.position = Vector3(0.0, -1.65, 1.02)
		head.add_child(fill_l)

		# Visible volumetric sodium fog cone around working streetlamp
		var halo := MeshInstance3D.new()
		halo.name = "SodiumFogCone"
		var cone := CylinderMesh.new()
		cone.top_radius = 0.22
		cone.bottom_radius = 2.65
		cone.height = 5.15
		cone.radial_segments = 14
		cone.cap_top = false
		cone.cap_bottom = false
		var hmat := StandardMaterial3D.new()
		hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		hmat.disable_fog = true
		hmat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
		hmat.distance_fade_min_distance = 22.0
		hmat.distance_fade_max_distance = 12.0
		hmat.albedo_color = Color(0.95, 0.66, 0.24, 0.016 if mode == "dim" else 0.028)
		cone.material = hmat
		halo.mesh = cone
		halo.position = Vector3(0.0, -2.55, 1.02)
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		head.add_child(halo)

		# Soft luminous sodium bulb halo visible through fog
		var orb := MeshInstance3D.new()
		orb.name = "SodiumFogOrb"
		var sph := SphereMesh.new()
		sph.radius = 0.42
		sph.height = 0.84
		sph.radial_segments = 12
		sph.rings = 8
		var omat := StandardMaterial3D.new()
		omat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		omat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		omat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		omat.disable_fog = true
		omat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
		omat.distance_fade_min_distance = 26.0
		omat.distance_fade_max_distance = 14.0
		omat.albedo_color = Color(0.98, 0.68, 0.28, 0.038 if mode == "dim" else 0.068)
		sph.material = omat
		orb.mesh = sph
		orb.position = Vector3(0.0, -0.08, 1.02)
		orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		head.add_child(orb)

		if mode == "flicker":
			register_anim("sodium_lamp_sway", lamp_light, {"energy": base_e, "seed": seed_val})


func add_multimesh_box(node_name: String, size: Vector3, mat: Material, transforms: Array[Transform3D]) -> MultiMeshInstance3D:
	if transforms.is_empty():
		return null
	var box := BoxMesh.new()
	box.size = size
	box.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = transforms.size()
	for i: int in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	add_child(mmi)
	return mmi


func add_multimesh_glb(node_name: String, glb_name: String, transforms: Array[Transform3D], with_trunk_colliders: bool = false) -> void:
	if transforms.is_empty():
		return
	var path: String = "res://assets/models/%s.glb" % glb_name
	if not ResourceLoader.exists(path):
		return
	var packed: Resource = load(path)
	if not (packed is PackedScene):
		return
	var template: Node = (packed as PackedScene).instantiate()
	var parts: Array[Dictionary] = []
	_collect_meshes(template, Transform3D.IDENTITY, parts)

	for p_idx: int in range(parts.size()):
		var part: Dictionary = parts[p_idx]
		var m: Mesh = part["mesh"] as Mesh
		var rel_xform: Transform3D = part["xform"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = m
		mm.instance_count = transforms.size()
		for i: int in range(transforms.size()):
			mm.set_instance_transform(i, transforms[i] * rel_xform)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "%s_Part%d" % [node_name, p_idx]
		mmi.multimesh = mm
		add_child(mmi)
	template.queue_free()

	if with_trunk_colliders:
		for i: int in range(transforms.size()):
			var pos: Vector3 = transforms[i].origin
			if absf(pos.x) < 142.0 and absf(pos.z) < 122.0:
				add_invisible_collider("%s_Col_%d" % [node_name, i], pos + Vector3(0, 1.3, 0), Vector3(0.6, 2.6, 0.6))


func _collect_meshes(node: Node, cur_xform: Transform3D, out: Array[Dictionary]) -> void:
	var next_xform: Transform3D = cur_xform
	if node is Node3D:
		next_xform = cur_xform * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append({"mesh": (node as MeshInstance3D).mesh, "xform": next_xform})
	for ch: Node in node.get_children():
		_collect_meshes(ch, next_xform, out)
