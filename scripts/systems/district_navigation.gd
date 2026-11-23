class_name DistrictNavigationManager
extends Node3D

# Prompt 08 Part 2.2 & Part 2.9 — Real Walkable NavigationMesh + Developer Navigation Debug Mode
# - Bakes a true NavigationRegion3D from Layer-1 StaticBody3D colliders (excluding walls, buildings,
#   parked cars, desks, chairs, fences, closed garages & solid props, while keeping openable doorways passable!)
# - Provides toggleable F8 Developer Navigation Debug visualization (navmesh wireframe, active path,
#   waypoints, companion collider capsule, avoidance radius & reachability status!)

var nav_region: NavigationRegion3D
var nav_mesh: NavigationMesh
var district_ref: Node3D
var companion_ref: Node3D
var is_baked: bool = false
var polygon_count: int = 0
var debug_enabled: bool = false

var _debug_root: Node3D
var _navmesh_mesh_inst: MeshInstance3D
var _path_mesh_inst: MeshInstance3D
var _debug_canvas: CanvasLayer
var _debug_label: Label


func setup_navigation(p_district: Node3D, p_companion: Node3D = null) -> void:
	name = "DistrictNavigationManager"
	district_ref = p_district
	companion_ref = p_companion
	_build_nav_region()
	bake_estate_navmesh()
	_build_debug_visuals()


func set_companion_ref(p_companion: Node3D) -> void:
	companion_ref = p_companion


func _build_nav_region() -> void:
	nav_region = NavigationRegion3D.new()
	nav_region.name = "DistrictNavRegion"
	nav_mesh = NavigationMesh.new()
	# Exact integer multiples of cell_size (0.20) & cell_height (0.25) -> ZERO voxel rounding warnings
	# AND clean walkable NavMesh corridors through every 1.15m building doorway while excluding cars/desks/walls!
	nav_mesh.cell_size = 0.20
	nav_mesh.cell_height = 0.25
	nav_mesh.agent_radius = 0.40
	nav_mesh.agent_height = 1.75
	nav_mesh.agent_max_climb = 0.50
	nav_mesh.agent_max_slope = 38.0
	nav_mesh.region_min_size = 4.0
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = 1
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nav_mesh.filter_baking_aabb = AABB(Vector3(-106.0, -5.5, -76.0), Vector3(204.0, 12.0, 140.0))
	add_child(nav_region)
	if is_inside_tree():
		var map_rid: RID = nav_region.get_navigation_map()
		if map_rid.is_valid():
			NavigationServer3D.map_set_cell_size(map_rid, 0.20)
			NavigationServer3D.map_set_cell_height(map_rid, 0.25)
	nav_region.navigation_mesh = nav_mesh


func bake_estate_navmesh() -> int:
	if not district_ref or not nav_region or not nav_mesh:
		return 0

	# Temporarily exempt openable PhysicalDoor leaf colliders from the static bake so
	# doorways stay connected on the NavMesh, then immediately restore Layer 1 solid blocking!
	var disabled_door_bodies: Array[StaticBody3D] = []
	var dm: Node = district_ref.get("door_manager")
	if dm and ("doors" in dm):
		for did: String in dm.doors.keys():
			var dnode: Node = dm.doors[did]
			if dnode and ("door_body" in dnode) and dnode.door_body is StaticBody3D:
				var sb: StaticBody3D = dnode.door_body as StaticBody3D
				if sb.collision_layer != 0:
					sb.set_meta("_orig_nav_layer", sb.collision_layer)
					sb.collision_layer = 0
					disabled_door_bodies.append(sb)

	var source_geo := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nav_mesh, source_geo, district_ref)
	NavigationServer3D.bake_from_source_geometry_data(nav_mesh, source_geo)
	nav_region.navigation_mesh = nav_mesh

	for sb: StaticBody3D in disabled_door_bodies:
		if is_instance_valid(sb):
			sb.collision_layer = int(sb.get_meta("_orig_nav_layer", 1))

	if is_inside_tree():
		var rid: RID = nav_region.get_navigation_map()
		if rid.is_valid():
			NavigationServer3D.map_set_cell_size(rid, 0.20)
			NavigationServer3D.map_set_cell_height(rid, 0.25)
			NavigationServer3D.map_force_update(rid)

	polygon_count = nav_mesh.get_polygon_count()
	is_baked = polygon_count > 0
	return polygon_count


func _build_debug_visuals() -> void:
	_debug_root = Node3D.new()
	_debug_root.name = "NavDebug3DRoot"
	_debug_root.visible = false
	add_child(_debug_root)

	_navmesh_mesh_inst = MeshInstance3D.new()
	_navmesh_mesh_inst.name = "NavMeshWireframe"
	_navmesh_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_debug_root.add_child(_navmesh_mesh_inst)

	_path_mesh_inst = MeshInstance3D.new()
	_path_mesh_inst.name = "CompanionPathDebug"
	_path_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_debug_root.add_child(_path_mesh_inst)

	_debug_canvas = CanvasLayer.new()
	_debug_canvas.name = "NavDebugHUD"
	_debug_canvas.layer = 45
	_debug_canvas.visible = false
	add_child(_debug_canvas)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 14
	panel.offset_top = 14
	panel.offset_right = 420
	panel.offset_bottom = 176
	_debug_canvas.add_child(panel)

	_debug_label = Label.new()
	_debug_label.add_theme_font_size_override("font_size", 11)
	_debug_label.add_theme_color_override("font_color", Color(0.55, 0.96, 0.88))
	panel.add_child(_debug_label)


func toggle_debug() -> bool:
	set_debug_enabled(not debug_enabled)
	return debug_enabled


func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	if _debug_root:
		_debug_root.visible = enabled
	if _debug_canvas:
		_debug_canvas.visible = enabled
	if enabled:
		_rebuild_navmesh_wireframe()


func _rebuild_navmesh_wireframe() -> void:
	if not nav_mesh or not _navmesh_mesh_inst:
		return
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.18, 0.85, 0.72, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var verts: PackedVector3Array = nav_mesh.get_vertices()
	var pcount: int = nav_mesh.get_polygon_count()
	if pcount > 0:
		im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
		for pi: int in range(pcount):
			var poly: PackedInt32Array = nav_mesh.get_polygon(pi)
			var sz: int = poly.size()
			for k: int in range(sz):
				var v0: Vector3 = verts[poly[k]] + Vector3(0, 0.08, 0)
				var v1: Vector3 = verts[poly[(k + 1) % sz]] + Vector3(0, 0.08, 0)
				im.surface_add_vertex(v0)
				im.surface_add_vertex(v1)
		im.surface_end()
	_navmesh_mesh_inst.mesh = im


func _process(_delta: float) -> void:
	if not debug_enabled or not companion_ref or not is_instance_valid(companion_ref):
		return
	_update_companion_debug_overlay()


func _update_companion_debug_overlay() -> void:
	if not _path_mesh_inst:
		return
	var info: Dictionary = companion_ref.get_nav_debug_info() if companion_ref.has_method("get_nav_debug_info") else {}
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true

	var cpos: Vector3 = companion_ref.global_position
	var path_pts: PackedVector3Array = info.get("path", PackedVector3Array())
	var target_pos: Vector3 = info.get("target", cpos)
	var next_wp: Vector3 = info.get("next_pos", cpos)
	var avoid_r: float = float(info.get("avoidance_radius", 0.44))
	var reachable: bool = bool(info.get("reachable", true))

	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	# Calculated navigation path polyline (amber)
	var path_col := Color(1.0, 0.78, 0.22) if reachable else Color(1.0, 0.22, 0.20)
	if path_pts.size() >= 2:
		for i: int in range(path_pts.size() - 1):
			im.surface_set_color(path_col)
			im.surface_add_vertex(path_pts[i] + Vector3(0, 0.22, 0))
			im.surface_add_vertex(path_pts[i + 1] + Vector3(0, 0.22, 0))
	else:
		im.surface_set_color(path_col)
		im.surface_add_vertex(cpos + Vector3(0, 0.22, 0))
		im.surface_add_vertex(next_wp + Vector3(0, 0.22, 0))

	# Current waypoint beacon (green) & destination beacon (magenta)
	im.surface_set_color(Color(0.25, 1.0, 0.45))
	im.surface_add_vertex(next_wp)
	im.surface_add_vertex(next_wp + Vector3(0, 2.2, 0))
	im.surface_set_color(Color(1.0, 0.35, 0.90))
	im.surface_add_vertex(target_pos)
	im.surface_add_vertex(target_pos + Vector3(0, 2.8, 0))

	# Companion collision circle (0.36m) & avoidance radius ring
	for ring_spec: Array in [[0.36, 0.18, Color(0.2, 0.8, 1.0)], [avoid_r, 0.12, Color(1.0, 0.6, 0.15)]]:
		var rad: float = float(ring_spec[0])
		var yy: float = float(ring_spec[1])
		var rc: Color = ring_spec[2]
		var segs: int = 16
		for s: int in range(segs):
			var a0: float = (float(s) / float(segs)) * TAU
			var a1: float = (float(s + 1) / float(segs)) * TAU
			im.surface_set_color(rc)
			im.surface_add_vertex(cpos + Vector3(cos(a0) * rad, yy, sin(a0) * rad))
			im.surface_add_vertex(cpos + Vector3(cos(a1) * rad, yy, sin(a1) * rad))
	im.surface_end()
	_path_mesh_inst.mesh = im

	if _debug_label:
		_debug_label.text = "NAV DEBUG [F8]  |  NAVMESH POLYS: %d\nSTATE: %s  |  SPEED: %.2f m/s\nTARGET: (%.1f, %.1f)  |  REACHABLE: %s\nRECALCS: %d  |  STUCK: %s  |  DOORS: %d" % [
			polygon_count,
			str(info.get("state", "")),
			float(info.get("speed", 0.0)),
			target_pos.x, target_pos.z,
			"YES" if reachable else "NO!",
			int(info.get("recalc_count", 0)),
			str(info.get("recovery_status", "OK")),
			int(info.get("doors_opened", 0)),
		]
