import math
import os
import bpy
import bmesh
from mathutils import Euler, Matrix, Vector

OUT_DIR = r"D:\nocna-zmena-blok-14\assets\models"
os.makedirs(OUT_DIR, exist_ok=True)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for col in list(bpy.data.collections):
        bpy.data.collections.remove(col)
    for mesh in list(bpy.data.meshes):
        bpy.data.meshes.remove(mesh)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)


def make_root(name):
    obj = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _link_obj(obj, parent):
    bpy.context.scene.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    return obj


def make_mat(name, color, metallic=0.0, roughness=0.65, emission=(0.0, 0.0, 0.0), emit_str=0.0, alpha=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is None:
        bsdf = mat.node_tree.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
    bsdf.inputs["Metallic"].default_value = float(metallic)
    bsdf.inputs["Roughness"].default_value = float(roughness)
    if "Emission Color" in bsdf.inputs:
        bsdf.inputs["Emission Color"].default_value = (emission[0], emission[1], emission[2], 1.0)
    if "Emission Strength" in bsdf.inputs:
        bsdf.inputs["Emission Strength"].default_value = float(emit_str)
    if alpha < 0.999 and "Alpha" in bsdf.inputs:
        bsdf.inputs["Alpha"].default_value = float(alpha)
        mat.blend_method = "BLEND" if hasattr(mat, "blend_method") else "OPAQUE"
    return mat


def _finish_bm(bm, name, mat, parent, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name + "_mesh")
    bm.to_mesh(mesh)
    bm.free()
    if smooth:
        for p in mesh.polygons:
            p.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    obj.location = Vector(loc)
    obj.rotation_euler = Euler(rot, "XYZ")
    if mat is not None:
        obj.data.materials.append(mat)
    return _link_obj(obj, parent)


def bm_box(parent, name, size, mat, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.transform(bm, matrix=Matrix.Diagonal((size[0], size[1], size[2], 1.0)), verts=bm.verts)
    if bevel > 0.0 and len(bm.edges) > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=2, affect="EDGES")
    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=(bevel > 0.0))


def bm_cyl(parent, name, r1, r2, h, mat, segs=16, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=smooth)


def bm_torus(parent, name, maj, mn, mat, maj_s=18, min_s=8, loc=(0, 0, 0), rot=(0, 0, 0)):
    bm = bmesh.new()
    rings = []
    for i in range(maj_s):
        theta = 2.0 * math.pi * i / maj_s
        ring = []
        for j in range(min_s):
            phi = 2.0 * math.pi * j / min_s
            r = maj + math.cos(phi) * mn
            ring.append(bm.verts.new((math.cos(theta) * r, math.sin(theta) * r, math.sin(phi) * mn)))
        rings.append(ring)
    for i in range(maj_s):
        r0, r1 = rings[i], rings[(i + 1) % maj_s]
        for j in range(min_s):
            j1 = (j + 1) % min_s
            bm.faces.new((r0[j], r1[j], r1[j1], r0[j1]))
    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=True)


def bm_tube(parent, name, pts, radii, mat, segs=8, loc=(0, 0, 0), rot=(0, 0, 0)):
    bm = bmesh.new()
    rings = []
    vec_pts = [Vector(p) for p in pts]
    for idx, p in enumerate(vec_pts):
        if idx == 0:
            tangent = (vec_pts[1] - p).normalized()
        elif idx == len(vec_pts) - 1:
            tangent = (p - vec_pts[-2]).normalized()
        else:
            tangent = (vec_pts[idx + 1] - vec_pts[idx - 1]).normalized()
        if tangent.length < 1e-6:
            tangent = Vector((0, 0, 1))
        up = Vector((0, 0, 1)) if abs(tangent.z) < 0.92 else Vector((1, 0, 0))
        side = tangent.cross(up).normalized()
        binorm = side.cross(tangent).normalized()
        rad = radii[idx]
        ring = []
        for s in range(segs):
            ang = 2.0 * math.pi * s / segs
            ring.append(bm.verts.new(p + (side * math.cos(ang) + binorm * math.sin(ang)) * rad))
        rings.append(ring)
    for i in range(len(rings) - 1):
        r0, r1 = rings[i], rings[i + 1]
        for s in range(segs):
            s1 = (s + 1) % segs
            bm.faces.new((r0[s], r0[s1], r1[s1], r1[s]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=True)


def _select_hierarchy(obj):
    bpy.ops.object.select_all(action="DESELECT")
    stack = [obj]
    while stack:
        cur = stack.pop()
        cur.select_set(True)
        for ch in cur.children:
            stack.append(ch)
    bpy.context.view_layer.objects.active = obj


def export_glb(root, filename):
    _select_hierarchy(root)
    out_path = os.path.join(OUT_DIR, filename)
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
    )
    print(f"EXPORTED_DISTRICT_GLB: {filename} ({os.path.getsize(out_path)} bytes)")


def add_car_wheels(root, tire_mat, rim_mat, wx=0.76, wy=1.22, r=0.29):
    for sx in (-wx, wx):
        for sy in (-wy, wy):
            bm_cyl(root, f"Tire_{sx:.1f}_{sy:.1f}", r, r, 0.19, tire_mat, segs=18, loc=(sx, sy, r), rot=(0, math.radians(90), 0))
            bm_cyl(root, f"Rim_{sx:.1f}_{sy:.1f}", r * 0.56, r * 0.56, 0.21, rim_mat, segs=12, loc=(sx, sy, r), rot=(0, math.radians(90), 0))


# 1. skoda_120.glb
def build_skoda_120():
    clear_scene()
    root = make_root("Skoda120")
    m_paint = make_mat("SkodaOrange", (0.58, 0.25, 0.14), metallic=0.25, roughness=0.52)
    m_glass = make_mat("AutoGlass", (0.07, 0.10, 0.12), metallic=0.6, roughness=0.18)
    m_tire = make_mat("Tire", (0.04, 0.04, 0.04), roughness=0.88)
    m_chrome = make_mat("Chrome", (0.68, 0.70, 0.72), metallic=0.88, roughness=0.25)
    m_tail = make_mat("RedLens", (0.72, 0.10, 0.08), roughness=0.35)
    add_car_wheels(root, m_tire, m_chrome, 0.74, 1.24, 0.29)
    bm_box(root, "BodyLower", (1.58, 4.10, 0.52), m_paint, loc=(0, 0, 0.54), bevel=0.04)
    bm_box(root, "Cabin", (1.38, 2.02, 0.56), m_paint, loc=(0, -0.05, 1.06), bevel=0.05)
    bm_box(root, "Windshield", (1.28, 0.06, 0.44), m_glass, loc=(0, 0.94, 1.05), rot=(math.radians(-18), 0, 0))
    bm_box(root, "RearWindow", (1.28, 0.06, 0.42), m_glass, loc=(0, -1.04, 1.05), rot=(math.radians(20), 0, 0))
    bm_box(root, "FrontBumper", (1.62, 0.12, 0.11), m_chrome, loc=(0, 2.08, 0.38), bevel=0.02)
    bm_box(root, "RearBumper", (1.62, 0.12, 0.11), m_chrome, loc=(0, -2.08, 0.38), bevel=0.02)
    for sx in (-0.54, 0.54):
        bm_cyl(root, f"Headlamp_{sx}", 0.09, 0.09, 0.05, m_chrome, segs=12, loc=(sx, 2.05, 0.62), rot=(math.radians(90), 0, 0))
        bm_box(root, f"Taillamp_{sx}", (0.24, 0.04, 0.12), m_tail, loc=(sx, -2.05, 0.62))
    export_glb(root, "skoda_120.glb")


# 2. lada_sedan.glb
def build_lada_sedan():
    clear_scene()
    root = make_root("LadaSedan")
    m_paint = make_mat("LadaCream", (0.64, 0.60, 0.50), metallic=0.22, roughness=0.56)
    m_glass = make_mat("AutoGlass", (0.07, 0.10, 0.12), metallic=0.6, roughness=0.18)
    m_tire = make_mat("Tire", (0.04, 0.04, 0.04), roughness=0.88)
    m_chrome = make_mat("Chrome", (0.65, 0.67, 0.68), metallic=0.85, roughness=0.30)
    m_grille = make_mat("GrilleBlk", (0.08, 0.08, 0.09), roughness=0.7)
    add_car_wheels(root, m_tire, m_chrome, 0.76, 1.25, 0.30)
    bm_box(root, "Hull", (1.62, 4.14, 0.56), m_paint, loc=(0, 0, 0.58), bevel=0.02)
    bm_box(root, "Cabin", (1.42, 1.96, 0.56), m_paint, loc=(0, -0.02, 1.12), bevel=0.02)
    bm_box(root, "Windshield", (1.32, 0.06, 0.44), m_glass, loc=(0, 0.94, 1.11), rot=(math.radians(-16), 0, 0))
    bm_box(root, "SideGlass", (1.44, 1.60, 0.40), m_glass, loc=(0, -0.02, 1.12))
    bm_box(root, "Grille", (1.38, 0.05, 0.22), m_grille, loc=(0, 2.07, 0.64))
    bm_box(root, "FrontBumper", (1.66, 0.12, 0.12), m_chrome, loc=(0, 2.11, 0.40))
    bm_box(root, "RearBumper", (1.66, 0.12, 0.12), m_chrome, loc=(0, -2.11, 0.40))
    export_glb(root, "lada_sedan.glb")


# 3. trabant_601.glb
def build_trabant_601():
    clear_scene()
    root = make_root("Trabant601")
    m_paint = make_mat("TrabantPastel", (0.52, 0.62, 0.58), metallic=0.05, roughness=0.64)
    m_glass = make_mat("Glass", (0.09, 0.12, 0.14), metallic=0.5, roughness=0.2)
    m_tire = make_mat("Tire", (0.04, 0.04, 0.04), roughness=0.88)
    m_chrome = make_mat("Trim", (0.55, 0.56, 0.58), metallic=0.78, roughness=0.35)
    add_car_wheels(root, m_tire, m_chrome, 0.66, 1.05, 0.26)
    bm_box(root, "Hull", (1.46, 3.45, 0.52), m_paint, loc=(0, 0, 0.50), bevel=0.06)
    bm_box(root, "Cabin", (1.28, 1.80, 0.56), m_paint, loc=(0, -0.08, 1.00), bevel=0.05)
    bm_box(root, "GlassBand", (1.30, 1.56, 0.36), m_glass, loc=(0, -0.08, 1.02))
    bm_box(root, "FrontBumper", (1.48, 0.10, 0.10), m_chrome, loc=(0, 1.75, 0.36), bevel=0.02)
    bm_box(root, "RearBumper", (1.48, 0.10, 0.10), m_chrome, loc=(0, -1.75, 0.36), bevel=0.02)
    export_glb(root, "trabant_601.glb")


# 4. playground_swing.glb (top beam + A-frame + SwingSeatMoving pivot for animation!)
def build_playground_swing():
    clear_scene()
    root = make_root("PlaygroundSwing")
    m_rust = make_mat("RustSteel", (0.28, 0.14, 0.10), metallic=0.65, roughness=0.72)
    m_paint = make_mat("FadedBluePipe", (0.18, 0.28, 0.38), metallic=0.4, roughness=0.68)
    m_wood = make_mat("SeatWood", (0.34, 0.22, 0.12), roughness=0.86)
    # 2 A-frames at X=-1.6 and X=+1.6
    for sx in (-1.6, 1.6):
        bm_cyl(root, f"LegF_{sx}", 0.042, 0.042, 2.75, m_paint, segs=10, loc=(sx, -0.58, 1.30), rot=(math.radians(-22), 0, 0))
        bm_cyl(root, f"LegB_{sx}", 0.042, 0.042, 2.75, m_paint, segs=10, loc=(sx, 0.58, 1.30), rot=(math.radians(22), 0, 0))
    bm_cyl(root, "TopCrossbar", 0.048, 0.048, 3.6, m_rust, segs=12, loc=(0, 0, 2.55), rot=(0, math.radians(90), 0))
    # Static empty seat 1
    for cx in (-0.95, -0.45):
        bm_cyl(root, f"ChainL_{cx}", 0.010, 0.010, 1.92, m_rust, segs=8, loc=(cx, 0, 1.56))
    bm_box(root, "SeatStatic", (0.62, 0.24, 0.04), m_wood, loc=(-0.70, 0, 0.60), bevel=0.005)
    # Separable moving pivot at beam height Z=2.55!
    swing_pivot = make_root("SwingSeatMoving")
    swing_pivot.parent = root
    swing_pivot.location = Vector((0.70, 0, 2.55))
    for cx in (-0.25, 0.25):
        bm_cyl(swing_pivot, f"ChainM_{cx}", 0.010, 0.010, 1.92, m_rust, segs=8, loc=(cx, 0, -0.96))
    bm_box(swing_pivot, "SeatBoard", (0.62, 0.24, 0.04), m_wood, loc=(0, 0, -1.94), bevel=0.005)
    export_glb(root, "playground_swing.glb")


# 5. playground_slide.glb
def build_playground_slide():
    clear_scene()
    root = make_root("PlaygroundSlide")
    m_rust = make_mat("SlideRed", (0.48, 0.16, 0.12), metallic=0.35, roughness=0.68)
    m_steel = make_mat("SlideChute", (0.58, 0.60, 0.62), metallic=0.88, roughness=0.32)
    # Ladder posts behind (Y = -0.8, Z 0..1.85)
    for sx in (-0.36, 0.36):
        bm_cyl(root, f"LadderSide_{sx}", 0.025, 0.025, 2.1, m_rust, segs=10, loc=(sx, -0.95, 1.0), rot=(math.radians(15), 0, 0))
        bm_cyl(root, f"TopRail_{sx}", 0.022, 0.022, 0.72, m_rust, segs=8, loc=(sx, -0.55, 1.95), rot=(math.radians(90), 0, 0))
    for r in range(6):
        rz = 0.28 + r * 0.27
        ry = -1.16 + r * 0.072
        bm_cyl(root, f"Rung_{r}", 0.016, 0.016, 0.72, m_rust, segs=8, loc=(0, ry, rz), rot=(0, math.radians(90), 0))
    bm_box(root, "TopPlatform", (0.78, 0.68, 0.06), m_rust, loc=(0, -0.52, 1.72))
    # Chute angled forward (+Y)
    bm_box(root, "ChuteBed", (0.68, 3.1, 0.06), m_steel, loc=(0, 1.05, 0.96), rot=(math.radians(31), 0, 0))
    for sx in (-0.34, 0.34):
        bm_box(root, f"ChuteRim_{sx}", (0.04, 3.1, 0.16), m_rust, loc=(sx, 1.05, 1.04), rot=(math.radians(31), 0, 0))
    bm_cyl(root, "FrontPropL", 0.025, 0.025, 0.55, m_rust, segs=8, loc=(-0.3, 2.1, 0.28))
    bm_cyl(root, "FrontPropR", 0.025, 0.025, 0.55, m_rust, segs=8, loc=(0.3, 2.1, 0.28))
    export_glb(root, "playground_slide.glb")


# 6. park_gazebo.glb
def build_park_gazebo():
    clear_scene()
    root = make_root("ParkGazebo")
    m_conc = make_mat("GazeboConcrete", (0.38, 0.38, 0.36), roughness=0.90)
    m_roof = make_mat("GazeboRoof", (0.20, 0.21, 0.20), roughness=0.88)
    m_wood = make_mat("GazeboBench", (0.28, 0.20, 0.13), roughness=0.84)
    bm_cyl(root, "FloorSlab", 2.35, 2.45, 0.20, m_conc, segs=6, loc=(0, 0, 0.10), smooth=False)
    for i in range(6):
        ang = i * (math.pi / 3.0)
        px, py = math.cos(ang) * 1.95, math.sin(ang) * 1.95
        bm_cyl(root, f"Column_{i}", 0.11, 0.10, 2.7, m_conc, segs=8, loc=(px, py, 1.45), smooth=False)
    bm_cyl(root, "ConicalRoof", 2.75, 0.12, 1.05, m_roof, segs=6, loc=(0, 0, 3.25), smooth=False)
    bm_box(root, "InnerBench", (2.1, 0.46, 0.08), m_wood, loc=(0, 1.15, 0.50))
    bm_box(root, "InnerBenchLegL", (0.12, 0.42, 0.35), m_conc, loc=(-0.85, 1.15, 0.30))
    bm_box(root, "InnerBenchLegR", (0.12, 0.42, 0.35), m_conc, loc=(0.85, 1.15, 0.30))
    export_glb(root, "park_gazebo.glb")


# 7. carpet_rack.glb
def build_carpet_rack():
    clear_scene()
    root = make_root("CarpetRack")
    m_pipe = make_mat("GalvanizedPipe", (0.42, 0.44, 0.45), metallic=0.65, roughness=0.58)
    for sx in (-1.4, 1.4):
        bm_cyl(root, f"Post_{sx}", 0.042, 0.042, 2.35, m_pipe, segs=10, loc=(sx, 0, 1.175))
    bm_cyl(root, "TopRail", 0.042, 0.042, 3.0, m_pipe, segs=10, loc=(0, 0, 2.35), rot=(0, math.radians(90), 0))
    bm_cyl(root, "MidRail", 0.025, 0.025, 2.8, m_pipe, segs=8, loc=(0, 0, 1.65), rot=(0, math.radians(90), 0))
    export_glb(root, "carpet_rack.glb")


# 8. panelak_balcony.glb
def build_panelak_balcony():
    clear_scene()
    root = make_root("PanelakBalcony")
    m_conc = make_mat("BalconyConc", (0.36, 0.37, 0.36), roughness=0.90)
    m_iron = make_mat("RustedRail", (0.14, 0.14, 0.15), metallic=0.72, roughness=0.58)
    bm_box(root, "Slab", (3.6, 1.15, 0.18), m_conc, loc=(0, -0.575, 0.09))
    bm_box(root, "TopHandrail", (3.6, 0.05, 0.05), m_iron, loc=(0, -1.10, 1.05))
    bm_box(root, "SideRailL", (0.05, 1.12, 0.05), m_iron, loc=(-1.77, -0.56, 1.05))
    bm_box(root, "SideRailR", (0.05, 1.12, 0.05), m_iron, loc=(1.77, -0.56, 1.05))
    for i in range(13):
        bx = -1.72 + i * 0.286
        bm_box(root, f"Picket_{i}", (0.028, 0.028, 0.96), m_iron, loc=(bx, -1.10, 0.56))
    bm_box(root, "DividerWall", (0.10, 1.10, 2.2), m_conc, loc=(-1.78, -0.55, 1.15))
    export_glb(root, "panelak_balcony.glb")


# 9. panelak_entrance.glb
def build_panelak_entrance():
    clear_scene()
    root = make_root("PanelakEntrance")
    m_conc = make_mat("CanopyConcrete", (0.34, 0.35, 0.34), roughness=0.90)
    m_steel = make_mat("SteelDoor", (0.18, 0.20, 0.22), metallic=0.75, roughness=0.45)
    m_glass = make_mat("WiredGlass", (0.16, 0.20, 0.22), metallic=0.35, roughness=0.22)
    m_glow = make_mat("IntercomLED", (0.95, 0.72, 0.32), emission=(0.95, 0.72, 0.32), emit_str=1.6)
    # Concrete vestibule hood & side cheeks
    bm_box(root, "CanopyTop", (3.4, 1.65, 0.22), m_conc, loc=(0, -0.82, 2.85))
    bm_box(root, "CheekL", (0.24, 1.50, 2.9), m_conc, loc=(-1.58, -0.75, 1.45))
    bm_box(root, "CheekR", (0.24, 1.50, 2.9), m_conc, loc=(1.58, -0.75, 1.45))
    # Steps & frame (clear doorway opening or thin recessed vestibule frame so player enters doorway walls built by scene!)
    bm_box(root, "ThresholdStep", (3.0, 1.35, 0.14), m_conc, loc=(0, -0.68, 0.07))
    bm_box(root, "SideFrameL", (0.32, 0.18, 2.55), m_steel, loc=(-1.28, -0.05, 1.35))
    bm_box(root, "SideFrameR", (0.32, 0.18, 2.55), m_steel, loc=(1.28, -0.05, 1.35))
    bm_box(root, "Transom", (2.4, 0.16, 0.38), m_glass, loc=(0, -0.05, 2.48))
    # Intercom keypad & lamp
    bm_box(root, "IntercomBox", (0.18, 0.06, 0.34), m_steel, loc=(1.25, -0.18, 1.38))
    bm_box(root, "EntryLightBulb", (0.36, 0.14, 0.10), m_glow, loc=(0, -0.65, 2.72))
    export_glb(root, "panelak_entrance.glb")


# 10. bus_stop_90s.glb
def build_bus_stop_90s():
    clear_scene()
    root = make_root("BusStop90s")
    m_rust = make_mat("ShelterFrame", (0.16, 0.24, 0.28), metallic=0.58, roughness=0.65)
    m_tin = make_mat("CorrugatedTin", (0.36, 0.38, 0.37), metallic=0.62, roughness=0.55)
    m_wood = make_mat("BenchSlats", (0.32, 0.22, 0.14), roughness=0.84)
    m_post = make_mat("SignPostYellow", (0.76, 0.58, 0.12), roughness=0.52)
    bm_box(root, "BackWall", (3.8, 0.08, 2.25), m_tin, loc=(0, 0.85, 1.18))
    bm_box(root, "Roof", (4.0, 1.85, 0.12), m_rust, loc=(0, 0.05, 2.38), rot=(math.radians(-6), 0, 0))
    for lx in (-1.85, 1.85):
        bm_cyl(root, f"PostF_{lx}", 0.04, 0.04, 2.35, m_rust, segs=8, loc=(lx, -0.75, 1.18))
        bm_cyl(root, f"PostB_{lx}", 0.04, 0.04, 2.35, m_rust, segs=8, loc=(lx, 0.82, 1.18))
    bm_box(root, "BenchSeat", (2.8, 0.42, 0.06), m_wood, loc=(0, 0.56, 0.48))
    bm_cyl(root, "TimetablePole", 0.045, 0.045, 2.9, m_post, segs=10, loc=(2.45, -0.65, 1.45))
    bm_box(root, "TimetableHead", (0.48, 0.06, 0.56), m_post, loc=(2.45, -0.65, 2.65))
    export_glb(root, "bus_stop_90s.glb")


# 11. shop_shelf.glb
def build_shop_shelf():
    clear_scene()
    root = make_root("ShopShelf")
    m_metal = make_mat("ShelfMetal", (0.62, 0.60, 0.54), metallic=0.35, roughness=0.60)
    m_pkg_a = make_mat("PkgRed", (0.68, 0.18, 0.16), roughness=0.55)
    m_pkg_b = make_mat("PkgBlue", (0.18, 0.34, 0.62), roughness=0.55)
    m_pkg_c = make_mat("PkgOchre", (0.76, 0.62, 0.24), roughness=0.55)
    bm_box(root, "BackBoard", (2.2, 0.06, 2.0), m_metal, loc=(0, 0.25, 1.0))
    for i in range(4):
        sz = 0.22 + i * 0.48
        bm_box(root, f"Tier_{i}", (2.2, 0.52, 0.04), m_metal, loc=(0, 0, sz))
        for j in range(6):
            px = -0.88 + j * 0.34
            m_use = [m_pkg_a, m_pkg_b, m_pkg_c][(i + j) % 3]
            bm_box(root, f"Box_{i}_{j}", (0.18, 0.22, 0.26), m_use, loc=(px, -0.02, sz + 0.15))
    export_glb(root, "shop_shelf.glb")


# 12. shop_fridge.glb
def build_shop_fridge():
    clear_scene()
    root = make_root("ShopFridge")
    m_white = make_mat("EnamelWhite", (0.76, 0.78, 0.76), metallic=0.15, roughness=0.42)
    m_inner = make_mat("CoolerGlow", (0.68, 0.86, 0.92), emission=(0.55, 0.78, 0.86), emit_str=0.85)
    m_trim = make_mat("TrimSteel", (0.28, 0.30, 0.32), metallic=0.78, roughness=0.38)
    bm_box(root, "Cabinet", (1.35, 0.78, 2.05), m_white, loc=(0, 0, 1.025), bevel=0.02)
    bm_box(root, "GlassFront", (1.16, 0.04, 1.45), m_inner, loc=(0, -0.39, 1.18))
    bm_box(root, "HandleBar", (0.04, 0.08, 0.85), m_trim, loc=(0.48, -0.43, 1.15))
    bm_box(root, "BaseGrill", (1.28, 0.06, 0.28), m_trim, loc=(0, -0.38, 0.18))
    export_glb(root, "shop_fridge.glb")


# 13. cash_register_90s.glb
def build_cash_register_90s():
    clear_scene()
    root = make_root("CashRegister90s")
    m_beige = make_mat("PlasticBeige", (0.72, 0.68, 0.58), roughness=0.52)
    m_keys = make_mat("KeyDark", (0.15, 0.16, 0.18), roughness=0.62)
    m_led = make_mat("GreenVFD", (0.20, 0.88, 0.42), emission=(0.20, 0.88, 0.42), emit_str=2.2)
    bm_box(root, "CashDrawer", (0.46, 0.44, 0.11), m_beige, loc=(0, 0, 0.055))
    bm_box(root, "KeyboardDeck", (0.42, 0.34, 0.14), m_beige, loc=(0, 0.03, 0.16), rot=(math.radians(-18), 0, 0))
    bm_box(root, "Keypad", (0.26, 0.20, 0.03), m_keys, loc=(-0.05, -0.02, 0.21), rot=(math.radians(-18), 0, 0))
    bm_cyl(root, "DisplayPost", 0.02, 0.02, 0.20, m_beige, segs=8, loc=(0.14, 0.15, 0.26))
    bm_box(root, "DisplayHead", (0.20, 0.08, 0.10), m_keys, loc=(0.14, 0.15, 0.37))
    bm_box(root, "VFDWindow", (0.16, 0.02, 0.05), m_led, loc=(0.14, 0.11, 0.37))
    export_glb(root, "cash_register_90s.glb")


# 14. old_bicycle.glb
def build_old_bicycle():
    clear_scene()
    root = make_root("OldBicycle")
    m_frame = make_mat("FavoritBlue", (0.16, 0.30, 0.44), metallic=0.45, roughness=0.55)
    m_tire = make_mat("Tire", (0.04, 0.04, 0.04), roughness=0.88)
    m_steel = make_mat("Chrome", (0.65, 0.67, 0.68), metallic=0.85, roughness=0.30)
    m_saddle = make_mat("BrownLeather", (0.24, 0.15, 0.09), roughness=0.72)
    for wy in (-0.54, 0.54):
        bm_torus(root, f"Wheel_{wy}", 0.32, 0.026, m_tire, maj_s=18, min_s=8, loc=(0, wy, 0.34), rot=(0, math.radians(90), 0))
    bm_tube(root, "FrameMain", [(0, -0.54, 0.34), (0, -0.05, 0.36), (0, 0.40, 0.72), (0, -0.14, 0.74), (0, -0.54, 0.34)], [0.018] * 5, m_frame)
    bm_cyl(root, "SeatTube", 0.018, 0.018, 0.50, m_frame, segs=8, loc=(0, -0.11, 0.58), rot=(math.radians(12), 0, 0))
    bm_cyl(root, "Fork", 0.018, 0.018, 0.56, m_frame, segs=8, loc=(0, 0.46, 0.58), rot=(math.radians(-18), 0, 0))
    bm_cyl(root, "Handlebar", 0.014, 0.014, 0.54, m_steel, segs=8, loc=(0, 0.38, 0.88), rot=(0, math.radians(90), 0))
    bm_box(root, "Saddle", (0.13, 0.24, 0.06), m_saddle, loc=(0, -0.15, 0.86), bevel=0.015)
    export_glb(root, "old_bicycle.glb")


# 15. pine_tree_90s.glb
def build_pine_tree():
    clear_scene()
    root = make_root("PineTree90s")
    m_trunk = make_mat("PineBark", (0.16, 0.12, 0.09), roughness=0.94)
    m_foliage = make_mat("DarkPine", (0.07, 0.12, 0.07), roughness=0.90)
    bm_cyl(root, "Trunk", 0.24, 0.10, 4.6, m_trunk, segs=8, loc=(0, 0, 2.3))
    for i, (cz, rad, h) in enumerate([(2.9, 1.85, 2.2), (4.2, 1.45, 2.0), (5.4, 1.02, 1.7), (6.4, 0.58, 1.3)]):
        bm_cyl(root, f"Tier_{i}", rad, 0.12, h, m_foliage, segs=9, loc=(0, 0, cz), smooth=False)
    export_glb(root, "pine_tree_90s.glb")


# 16. crt_tv_set.glb
def build_crt_tv_set():
    clear_scene()
    root = make_root("CRTTVSet")
    m_wood = make_mat("WalnutVeneer", (0.26, 0.16, 0.09), roughness=0.58)
    m_screen = make_mat("TVGlowBlue", (0.16, 0.28, 0.36), roughness=0.14, emission=(0.35, 0.56, 0.78), emit_str=1.8)
    m_plastic = make_mat("DarkTrim", (0.09, 0.09, 0.10), roughness=0.65)
    bm_box(root, "CabinetStand", (0.92, 0.48, 0.58), m_wood, loc=(0, 0, 0.29), bevel=0.01)
    bm_box(root, "TVHousing", (0.72, 0.44, 0.52), m_wood, loc=(0, 0, 0.84), bevel=0.02)
    bm_box(root, "CRTGlass", (0.50, 0.04, 0.38), m_screen, loc=(-0.06, -0.22, 0.85))
    bm_box(root, "ControlPanel", (0.12, 0.04, 0.38), m_plastic, loc=(0.27, -0.22, 0.85))
    for rx in (-0.12, 0.12):
        bm_cyl(root, f"RabbitEar_{rx}", 0.006, 0.004, 0.42, m_plastic, segs=6, loc=(rx, 0.05, 1.28), rot=(0, math.radians(-28 if rx < 0 else 28), 0))
    export_glb(root, "crt_tv_set.glb")


def main():
    build_skoda_120()
    build_lada_sedan()
    build_trabant_601()
    build_playground_swing()
    build_playground_slide()
    build_park_gazebo()
    build_carpet_rack()
    build_panelak_balcony()
    build_panelak_entrance()
    build_bus_stop_90s()
    build_shop_shelf()
    build_shop_fridge()
    build_cash_register_90s()
    build_old_bicycle()
    build_pine_tree()
    build_crt_tv_set()
    print("ALL_16_DISTRICT_GLBS_COMPLETE")


if __name__ == "__main__":
    main()
