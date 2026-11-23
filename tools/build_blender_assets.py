r"""
Blender 5.3.0 headless 3D asset generator for NOČNÁ ZMENA: BLOK 14.
Exports 18 detailed multi-part PBR .glb hero assets into assets/models/.
Coordinate convention:
  - Base rests at Blender Z = 0.0 (maps to Godot Y = 0.0 via export_yup=True).
  - Front faces Blender -Y (maps to Godot +Z).
Run via:
  "D:\SteamLibrary\steamapps\common\Blender\blender.exe" --background --factory-startup --python "D:\nocna-zmena-blok-14\tools\build_blender_assets.py"
"""
import math
import pathlib
import bpy
import bmesh
from mathutils import Vector

OUT_DIR = pathlib.Path(r"D:\nocna-zmena-blok-14\assets\models")


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    return scene


def make_mat(name: str, color: tuple, metallic: float = 0.0, roughness: float = 0.6,
             emission: tuple = (0.0, 0.0, 0.0), emit_str: float = 0.0, alpha: float = 1.0):
    mat = bpy.data.materials.new(name)
    if mat.node_tree is None:
        mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
    bsdf.inputs["Emission Strength"].default_value = emit_str
    bsdf.inputs["Alpha"].default_value = alpha
    return mat


def get_mats():
    return {
        "skoda_paint": make_mat("SkodaOlive", (0.29, 0.31, 0.26), metallic=0.18, roughness=0.42),
        "rubber": make_mat("Rubber", (0.04, 0.04, 0.045), metallic=0.0, roughness=0.88),
        "bumper": make_mat("BumperDark", (0.07, 0.075, 0.08), metallic=0.12, roughness=0.68),
        "steel": make_mat("Steel", (0.48, 0.50, 0.54), metallic=0.88, roughness=0.34),
        "iron": make_mat("WroughtIron", (0.11, 0.115, 0.12), metallic=0.76, roughness=0.52),
        "galvanized": make_mat("Galvanized", (0.30, 0.32, 0.34), metallic=0.65, roughness=0.48),
        "brass": make_mat("OldBrass", (0.58, 0.44, 0.17), metallic=0.86, roughness=0.36),
        "copper": make_mat("Copper", (0.64, 0.31, 0.15), metallic=0.88, roughness=0.32),
        "oak": make_mat("DarkOak", (0.18, 0.12, 0.08), metallic=0.0, roughness=0.76),
        "walnut": make_mat("Walnut", (0.12, 0.075, 0.05), metallic=0.0, roughness=0.72),
        "stone": make_mat("OldStone", (0.22, 0.22, 0.21), metallic=0.0, roughness=0.86),
        "slate": make_mat("SlateRoof", (0.13, 0.14, 0.16), metallic=0.05, roughness=0.78),
        "glass": make_mat("DarkGlass", (0.05, 0.07, 0.09), metallic=0.15, roughness=0.14),
        "bakelite": make_mat("Bakelite", (0.04, 0.04, 0.045), metallic=0.05, roughness=0.32),
        "plastic_cream": make_mat("TeslaPlastic", (0.32, 0.30, 0.25), metallic=0.0, roughness=0.55),
        "crt_screen": make_mat("CRTScreen", (0.04, 0.07, 0.06), metallic=0.08, roughness=0.18, emission=(0.06, 0.12, 0.09), emit_str=0.45),
        "red_paint": make_mat("CrimsonRust", (0.36, 0.08, 0.065), metallic=0.32, roughness=0.56),
        "red_valve": make_mat("ValveRed", (0.56, 0.10, 0.08), metallic=0.25, roughness=0.45),
        "dial_cream": make_mat("ClockFace", (0.72, 0.68, 0.56), metallic=0.0, roughness=0.52),
        "amber_glow": make_mat("SodiumGlow", (0.98, 0.72, 0.26), metallic=0.0, roughness=0.25, emission=(0.98, 0.68, 0.22), emit_str=2.6),
        "ember_glow": make_mat("EmberGlow", (0.96, 0.32, 0.08), metallic=0.0, roughness=0.4, emission=(0.98, 0.28, 0.06), emit_str=2.4),
        "taillight": make_mat("TailRed", (0.58, 0.06, 0.06), metallic=0.0, roughness=0.28, emission=(0.35, 0.02, 0.02), emit_str=0.4),
        "headlight": make_mat("HeadGlass", (0.78, 0.78, 0.70), metallic=0.1, roughness=0.18, emission=(0.35, 0.34, 0.26), emit_str=0.3),
        "k4_phosphor": make_mat("K4Phosphor", (0.18, 0.85, 0.38), metallic=0.0, roughness=0.15, emission=(0.24, 0.94, 0.42), emit_str=2.8),
        "enamel_white": make_mat("EnamelMug", (0.68, 0.68, 0.64), metallic=0.05, roughness=0.36),
        "coat_sbs": make_mat("SBSNavy", (0.09, 0.11, 0.15), metallic=0.0, roughness=0.82),
        "skin_pale": make_mat("PaleSkin", (0.44, 0.38, 0.34), metallic=0.0, roughness=0.72),
        "shadow_void": make_mat("ShadowEntity", (0.015, 0.018, 0.025), metallic=0.0, roughness=0.92, emission=(0.04, 0.07, 0.10), emit_str=0.35),
        "garbage_bag": make_mat("TrashBag", (0.03, 0.035, 0.04), metallic=0.08, roughness=0.28),
    }


def link_part(parent, name: str, bm: bmesh.types.BMesh, mat, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    if smooth:
        for p in mesh.polygons:
            p.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    obj.location = loc
    obj.rotation_euler = [math.radians(a) for a in rot]
    obj.data.materials.append(mat)
    obj.parent = parent
    bpy.context.scene.collection.objects.link(obj)
    return obj


def bm_box(parent, name: str, size: tuple, mat, loc=(0, 0, 0), rot=(0, 0, 0), bevel: float = 0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    if bevel > 0.0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=2, affect="EDGES")
    return link_part(parent, name, bm, mat, loc=loc, rot=rot, smooth=(bevel > 0.0))


def bm_cyl(parent, name: str, r1: float, r2: float, h: float, mat, segs=16, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return link_part(parent, name, bm, mat, loc=loc, rot=rot, smooth=smooth)


def bm_sphere(parent, name: str, rad: float, mat, scale=(1, 1, 1), loc=(0, 0, 0), rot=(0, 0, 0), sub=2):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=rad)
    bmesh.ops.scale(bm, vec=scale, verts=bm.verts)
    return link_part(parent, name, bm, mat, loc=loc, rot=rot, smooth=True)


def bm_torus(parent, name: str, maj: float, mn: float, mat, maj_s=24, min_s=10, loc=(0, 0, 0), rot=(0, 0, 0)):
    bm = bmesh.new()
    rings = []
    for i in range(maj_s):
        a = (i / maj_s) * math.tau
        ca, sa = math.cos(a), math.sin(a)
        rings.append([
            bm.verts.new((ca * (maj + math.cos(j * math.tau / min_s) * mn),
                          sa * (maj + math.cos(j * math.tau / min_s) * mn),
                          math.sin(j * math.tau / min_s) * mn))
            for j in range(min_s)
        ])
    for i in range(maj_s):
        ni = (i + 1) % maj_s
        for j in range(min_s):
            nj = (j + 1) % min_s
            bm.faces.new((rings[i][j], rings[ni][j], rings[ni][nj], rings[i][nj]))
    return link_part(parent, name, bm, mat, loc=loc, rot=rot, smooth=True)


def bm_tube(parent, name: str, pts: list, radii: list, mat, segs=10, loc=(0, 0, 0), rot=(0, 0, 0)):
    bm = bmesh.new()
    n = len(pts)
    rings = []
    for idx, (pt, rad) in enumerate(zip(pts, radii)):
        p = Vector(pt)
        if idx == 0:
            tang = (Vector(pts[1]) - p).normalized()
        elif idx == n - 1:
            tang = (p - Vector(pts[-2])).normalized()
        else:
            tang = (Vector(pts[idx + 1]) - Vector(pts[idx - 1])).normalized()
        up = Vector((0, 0, 1)) if abs(tang.z) < 0.92 else Vector((1, 0, 0))
        u = tang.cross(up).normalized()
        v = tang.cross(u).normalized()
        ring = []
        for k in range(segs):
            a = (k / segs) * math.tau
            ring.append(bm.verts.new(p + (u * math.cos(a) + v * math.sin(a)) * rad))
        rings.append(ring)
    for idx in range(n - 1):
        for k in range(segs):
            nk = (k + 1) % segs
            bm.faces.new((rings[idx][k], rings[idx][nk], rings[idx + 1][nk], rings[idx + 1][k]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])
    return link_part(parent, name, bm, mat, loc=loc, rot=rot, smooth=True)


def export_glb(root, filepath: pathlib.Path):
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for child in root.children_recursive:
        child.select_set(True)
    bpy.context.view_layer.objects.active = root
    filepath.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(filepath),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_normals=True,
        export_materials="EXPORT",
    )


def new_root(name: str):
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    return root


# -----------------------------------------------------------------------------
# 1. SKODA FAVORIT (boxy 1990s Czechoslovak hatchback, ~3.8m long along Y)
# -----------------------------------------------------------------------------
def build_skoda_favorit(M):
    root = new_root("skoda_favorit")
    # Lower chassis & sculpted hood/cabin
    bm_box(root, "LowerBody", (1.62, 3.74, 0.56), M["skoda_paint"], loc=(0, 0, 0.50), bevel=0.05)
    bm_box(root, "HoodSlope", (1.54, 1.05, 0.16), M["skoda_paint"], loc=(0, -1.25, 0.76), rot=(-5, 0, 0), bevel=0.03)
    bm_box(root, "Cabin", (1.44, 1.92, 0.54), M["skoda_paint"], loc=(0, 0.30, 1.04), bevel=0.05)
    bm_box(root, "Windshield", (1.36, 0.05, 0.56), M["glass"], loc=(0, -0.66, 1.02), rot=(-36, 0, 0))
    bm_box(root, "RearGlass", (1.32, 0.05, 0.52), M["glass"], loc=(0, 1.28, 1.00), rot=(30, 0, 0))
    for sx in (-0.725, 0.725):
        bm_box(root, f"SideGlass_{sx}", (0.03, 1.48, 0.38), M["glass"], loc=(sx, 0.32, 1.04))
        bm_box(root, f"Mirror_{sx}", (0.14, 0.09, 0.08), M["bumper"], loc=(sx * 1.15, -0.58, 0.85))
    # Bumpers, grille, lights
    bm_box(root, "FrontBumper", (1.66, 0.20, 0.20), M["bumper"], loc=(0, -1.86, 0.34), bevel=0.025)
    bm_box(root, "RearBumper", (1.66, 0.20, 0.20), M["bumper"], loc=(0, 1.86, 0.34), bevel=0.025)
    bm_box(root, "Grille", (0.90, 0.06, 0.16), M["bumper"], loc=(0, -1.86, 0.62))
    for sx in (-0.56, 0.56):
        bm_box(root, f"Headlight_{sx}", (0.28, 0.06, 0.16), M["headlight"], loc=(sx, -1.86, 0.62))
        bm_box(root, f"Taillight_{sx}", (0.26, 0.06, 0.18), M["taillight"], loc=(sx, 1.86, 0.62))
    # 4 Wheels & steel rims
    for wx in (-0.76, 0.76):
        for wy in (-1.18, 1.18):
            bm_cyl(root, f"Tire_{wx}_{wy}", 0.31, 0.31, 0.20, M["rubber"], segs=20, loc=(wx, wy, 0.31), rot=(0, 90, 0))
            bm_cyl(root, f"Rim_{wx}_{wy}", 0.18, 0.18, 0.22, M["steel"], segs=12, loc=(wx, wy, 0.31), rot=(0, 90, 0))
    return root


# -----------------------------------------------------------------------------
# 2. MEDIEVAL WELL
# -----------------------------------------------------------------------------
def build_medieval_well(M):
    root = new_root("medieval_well")
    bm_cyl(root, "WellShaft", 1.02, 1.06, 1.04, M["stone"], segs=10, loc=(0, 0, 0.52), smooth=False)
    bm_cyl(root, "WellCoping", 1.12, 1.12, 0.14, M["stone"], segs=10, loc=(0, 0, 1.08), smooth=False)
    # Iron grate bars + rim
    bm_cyl(root, "WellGrateRim", 0.92, 0.92, 0.05, M["iron"], segs=10, loc=(0, 0, 1.14), smooth=False)
    for k in range(-3, 4):
        bm_box(root, f"GrateA_{k}", (1.60, 0.04, 0.04), M["iron"], loc=(0, k * 0.22, 1.15))
        bm_box(root, f"GrateB_{k}", (0.04, 1.60, 0.04), M["iron"], loc=(k * 0.22, 0, 1.15))
    # Timber posts + braces + winch
    for sx in (-0.86, 0.86):
        bm_box(root, f"Post_{sx}", (0.14, 0.14, 1.65), M["oak"], loc=(sx, 0, 1.88), bevel=0.015)
        bm_box(root, f"Brace_{sx}", (0.08, 0.42, 0.08), M["oak"], loc=(sx, 0, 2.48), rot=(45, 0, 0))
    bm_cyl(root, "WinchDrum", 0.11, 0.11, 1.60, M["oak"], segs=12, loc=(0, 0, 1.88), rot=(0, 90, 0))
    bm_cyl(root, "WinchRope", 0.13, 0.13, 0.45, M["dial_cream"], segs=12, loc=(0, 0, 1.88), rot=(0, 90, 0))
    bm_cyl(root, "WellBucket", 0.18, 0.24, 0.34, M["oak"], segs=12, loc=(0, 0, 1.38))
    bm_box(root, "Padlock", (0.10, 0.06, 0.14), M["brass"], loc=(0, -0.96, 1.05), bevel=0.01)
    # Gable slate roof
    bm_box(root, "RoofSlopeN", (2.35, 1.10, 0.09), M["slate"], loc=(0, 0.44, 2.84), rot=(-32, 0, 0), bevel=0.01)
    bm_box(root, "RoofSlopeS", (2.35, 1.10, 0.09), M["slate"], loc=(0, -0.44, 2.84), rot=(32, 0, 0), bevel=0.01)
    bm_box(root, "RidgeCap", (2.40, 0.14, 0.12), M["slate"], loc=(0, 0, 3.12))
    return root


# -----------------------------------------------------------------------------
# 3. CARRIAGE GATE (Double wrought-iron gate + stone piers, 4.4m wide)
# -----------------------------------------------------------------------------
def build_carriage_gate(M):
    root = new_root("carriage_gate")
    for sx in (-2.25, 2.25):
        bm_box(root, f"Pier_{sx}", (0.48, 0.56, 3.60), M["stone"], loc=(sx, 0, 1.80), bevel=0.03)
        bm_box(root, f"PierCap_{sx}", (0.58, 0.66, 0.16), M["stone"], loc=(sx, 0, 3.65), bevel=0.02)
    # Horizontal gate rails
    for hz in (0.28, 1.45, 2.75):
        bm_box(root, f"GateRail_{hz}", (4.05, 0.07, 0.09), M["iron"], loc=(0, 0, hz))
    # Vertical spear pickets
    for i in range(-9, 10):
        px = i * 0.21
        bm_cyl(root, f"Picket_{i}", 0.022, 0.022, 3.05, M["iron"], segs=8, loc=(px, 0, 1.60))
        bm_cyl(root, f"Spear_{i}", 0.042, 0.002, 0.18, M["iron"], segs=4, loc=(px, 0, 3.20))
    # Decorative wrought rings & center lockbox
    for rx in (-1.2, -0.5, 0.5, 1.2):
        bm_torus(root, f"Scroll_{rx}", 0.16, 0.02, M["iron"], maj_s=16, min_s=6, loc=(rx, 0, 2.10), rot=(90, 0, 0))
    bm_box(root, "Lockbox", (0.26, 0.12, 0.34), M["iron"], loc=(0, 0, 1.45), bevel=0.01)
    bm_box(root, "LockBrass", (0.08, 0.14, 0.14), M["brass"], loc=(0, 0, 1.45))
    return root


# -----------------------------------------------------------------------------
# 4. GUARD BOOTH DESK (desk + drawers + banker's lamp + mug + Strážna kniha)
# -----------------------------------------------------------------------------
def build_guard_booth_desk(M):
    root = new_root("guard_booth_desk")
    bm_box(root, "DeskTop", (2.25, 0.96, 0.07), M["oak"], loc=(0, 0, 0.88), bevel=0.015)
    bm_box(root, "DrawerPedestalL", (0.58, 0.86, 0.84), M["walnut"], loc=(-0.78, 0, 0.42), bevel=0.01)
    bm_box(root, "SideLegR", (0.08, 0.86, 0.84), M["walnut"], loc=(1.04, 0, 0.42))
    bm_box(root, "BackPanel", (1.60, 0.05, 0.56), M["walnut"], loc=(0.20, 0.40, 0.56))
    for dz in (0.22, 0.48, 0.72):
        bm_box(root, f"DrawerFront_{dz}", (0.50, 0.04, 0.18), M["oak"], loc=(-0.78, -0.44, dz), bevel=0.008)
        bm_box(root, f"Handle_{dz}", (0.12, 0.04, 0.03), M["brass"], loc=(-0.78, -0.47, dz))
    # Strážna kniha (Guard Logbook) + pen
    bm_box(root, "LogbookCover", (0.34, 0.26, 0.045), M["red_paint"], loc=(0.15, -0.10, 0.94), rot=(0, 0, 8), bevel=0.006)
    bm_box(root, "LogbookPages", (0.31, 0.24, 0.032), M["dial_cream"], loc=(0.15, -0.10, 0.942), rot=(0, 0, 8))
    # Coffee mug
    bm_cyl(root, "MugBody", 0.048, 0.048, 0.10, M["enamel_white"], segs=14, loc=(-0.38, -0.18, 0.96))
    bm_torus(root, "MugHandle", 0.032, 0.008, M["enamel_white"], maj_s=12, min_s=6, loc=(-0.33, -0.18, 0.96), rot=(90, 0, 0))
    # Banker's desk lamp
    bm_cyl(root, "LampBase", 0.11, 0.09, 0.035, M["brass"], segs=16, loc=(0.76, 0.22, 0.93))
    bm_tube(root, "LampNeck", [(0.76, 0.22, 0.95), (0.76, 0.24, 1.24), (0.68, 0.14, 1.32)], [0.015, 0.014, 0.012], M["brass"], segs=8)
    bm_cyl(root, "LampShade", 0.13, 0.06, 0.11, M["iron"], segs=16, loc=(0.66, 0.11, 1.28), rot=(15, 0, 0))
    bm_sphere(root, "LampBulb", 0.045, M["amber_glow"], loc=(0.66, 0.11, 1.24))
    return root


# -----------------------------------------------------------------------------
# 5. TESLA CRT MONITOR (recessed bezel, dark curved tube, tuning knobs)
# -----------------------------------------------------------------------------
def build_tesla_crt_monitor(M):
    root = new_root("tesla_crt_monitor")
    bm_box(root, "StandBase", (0.44, 0.36, 0.05), M["iron"], loc=(0, 0, 0.025), bevel=0.01)
    bm_box(root, "CRTCabinet", (0.64, 0.46, 0.52), M["plastic_cream"], loc=(0, 0.04, 0.31), bevel=0.025)
    bm_box(root, "CRTRearNeck", (0.42, 0.22, 0.36), M["bumper"], loc=(0, 0.34, 0.31), bevel=0.02)
    bm_box(root, "BezelFrame", (0.58, 0.05, 0.45), M["bumper"], loc=(0, -0.19, 0.32), bevel=0.012)
    bm_box(root, "GlassTube", (0.50, 0.04, 0.38), M["crt_screen"], loc=(0, -0.205, 0.33))
    for kx in (-0.18, -0.10, -0.02):
        bm_cyl(root, f"Knob_{kx}", 0.018, 0.016, 0.03, M["iron"], segs=12, loc=(kx, -0.22, 0.095), rot=(90, 0, 0))
    bm_sphere(root, "PowerLED", 0.01, M["k4_phosphor"], loc=(0.22, -0.22, 0.095))
    return root


# -----------------------------------------------------------------------------
# 6. ROTARY PHONE
# -----------------------------------------------------------------------------
def build_rotary_phone(M):
    root = new_root("rotary_phone")
    bm_box(root, "PhoneBase", (0.20, 0.24, 0.09), M["bakelite"], loc=(0, 0, 0.045), bevel=0.018)
    bm_box(root, "DialSlope", (0.17, 0.16, 0.08), M["bakelite"], loc=(0, -0.03, 0.10), rot=(22, 0, 0), bevel=0.012)
    bm_cyl(root, "DialWheel", 0.062, 0.062, 0.018, M["dial_cream"], segs=20, loc=(0, -0.055, 0.145), rot=(22, 0, 0))
    bm_cyl(root, "FingerPlate", 0.058, 0.058, 0.01, M["steel"], segs=20, loc=(0, -0.060, 0.155), rot=(22, 0, 0))
    for sx in (-0.055, 0.055):
        bm_box(root, f"Cradle_{sx}", (0.025, 0.04, 0.05), M["bakelite"], loc=(sx, 0.06, 0.135))
    # Handset across cradle
    bm_box(root, "HandsetBar", (0.24, 0.042, 0.032), M["bakelite"], loc=(0, 0.06, 0.175), bevel=0.012)
    for sx in (-0.095, 0.095):
        bm_cyl(root, f"EarCup_{sx}", 0.038, 0.032, 0.04, M["bakelite"], segs=16, loc=(sx, 0.06, 0.16))
    return root


# -----------------------------------------------------------------------------
# 7. WATCHMAN'S CLOCK (Kontrolné hodiny)
# -----------------------------------------------------------------------------
def build_watchmans_clock(M):
    root = new_root("watchmans_clock")
    bm_box(root, "MountPlate", (0.28, 0.04, 0.38), M["iron"], loc=(0, 0.02, 0.19), bevel=0.008)
    bm_box(root, "ClockBox", (0.24, 0.14, 0.32), M["red_paint"], loc=(0, -0.06, 0.19), bevel=0.014)
    bm_cyl(root, "KeyPlate", 0.055, 0.055, 0.03, M["brass"], segs=16, loc=(0, -0.13, 0.19), rot=(90, 0, 0))
    bm_box(root, "KeySlot", (0.018, 0.03, 0.05), M["iron"], loc=(0, -0.142, 0.19))
    return root


# -----------------------------------------------------------------------------
# 8. STREETLAMP SODIUM (Gooseneck wall bracket + fluted hood + glowing bulb)
# -----------------------------------------------------------------------------
def build_streetlamp_sodium(M):
    root = new_root("streetlamp_sodium")
    bm_box(root, "WallFlange", (0.16, 0.05, 0.36), M["iron"], loc=(0, 0.025, 0.18), bevel=0.01)
    bm_tube(root, "Gooseneck", [(0, 0, 0.18), (0, -0.45, 0.32), (0, -0.92, 0.38), (0, -1.06, 0.25)], [0.035, 0.032, 0.028, 0.026], M["iron"], segs=10)
    bm_cyl(root, "ShadeHood", 0.26, 0.09, 0.15, M["iron"], segs=16, loc=(0, -1.06, 0.20))
    bm_cyl(root, "GlassCage", 0.12, 0.08, 0.18, M["glass"], segs=14, loc=(0, -1.06, 0.07))
    bm_sphere(root, "SodiumBulb", 0.065, M["amber_glow"], scale=(1.0, 1.0, 1.5), loc=(0, -1.06, 0.08))
    return root


# -----------------------------------------------------------------------------
# 9. BOILER FURNACE (Cast-iron boiler + glowing grate + gauge + steam pipes + red valve)
# -----------------------------------------------------------------------------
def build_boiler_furnace(M):
    root = new_root("boiler_furnace")
    bm_box(root, "Plinth", (2.2, 2.0, 0.22), M["stone"], loc=(0, 0, 0.11), bevel=0.02)
    bm_box(root, "BoilerBody", (1.95, 1.75, 2.05), M["iron"], loc=(0, 0, 1.24), bevel=0.05)
    bm_cyl(root, "FluePipe", 0.28, 0.28, 1.35, M["iron"], segs=16, loc=(0, 0.35, 2.65))
    # Firebox door + glowing embers
    bm_box(root, "FireDoorFrame", (0.86, 0.10, 0.68), M["bumper"], loc=(0, -0.90, 0.85), bevel=0.02)
    bm_box(root, "EmberGrate", (0.64, 0.06, 0.44), M["ember_glow"], loc=(0, -0.92, 0.85))
    for gx in (-0.20, -0.10, 0.0, 0.10, 0.20):
        bm_box(root, f"GrateBar_{gx}", (0.035, 0.08, 0.46), M["iron"], loc=(gx, -0.94, 0.85))
    # Steam manifold pipes + pressure gauge + red handwheel
    bm_cyl(root, "SteamPipe", 0.09, 0.09, 1.60, M["copper"], segs=14, loc=(-0.72, -0.95, 1.50))
    bm_cyl(root, "GaugeDial", 0.13, 0.13, 0.06, M["brass"], segs=18, loc=(-0.72, -1.06, 1.98), rot=(90, 0, 0))
    bm_cyl(root, "GaugeFace", 0.10, 0.10, 0.07, M["dial_cream"], segs=18, loc=(-0.72, -1.065, 1.98), rot=(90, 0, 0))
    bm_torus(root, "RedValveWheel", 0.18, 0.025, M["red_valve"], maj_s=18, min_s=8, loc=(-0.72, -1.12, 1.28), rot=(90, 0, 0))
    bm_box(root, "ValveSpoke1", (0.34, 0.03, 0.03), M["red_valve"], loc=(-0.72, -1.12, 1.28))
    bm_box(root, "ValveSpoke2", (0.03, 0.03, 0.34), M["red_valve"], loc=(-0.72, -1.12, 1.28))
    return root


# -----------------------------------------------------------------------------
# 10. GRANDFATHER CLOCK (Hodinárstvo)
# -----------------------------------------------------------------------------
def build_grandfather_clock(M):
    root = new_root("grandfather_clock")
    bm_box(root, "ClockBase", (0.58, 0.38, 0.48), M["walnut"], loc=(0, 0, 0.24), bevel=0.02)
    bm_box(root, "ClockWaist", (0.46, 0.32, 1.18), M["oak"], loc=(0, 0, 1.07), bevel=0.015)
    bm_box(root, "CabinetGlass", (0.32, 0.04, 0.96), M["glass"], loc=(0, -0.15, 1.07))
    bm_cyl(root, "PendulumRod", 0.012, 0.012, 0.72, M["brass"], segs=8, loc=(0, -0.10, 1.12))
    bm_cyl(root, "PendulumBob", 0.09, 0.09, 0.03, M["brass"], segs=18, loc=(0, -0.10, 0.76), rot=(90, 0, 0))
    bm_box(root, "ClockHood", (0.56, 0.38, 0.56), M["walnut"], loc=(0, 0, 1.94), bevel=0.02)
    bm_cyl(root, "ClockDial", 0.18, 0.18, 0.04, M["dial_cream"], segs=24, loc=(0, -0.19, 1.94), rot=(90, 0, 0))
    bm_box(root, "ClockCrown", (0.62, 0.42, 0.12), M["walnut"], loc=(0, 0, 2.26), bevel=0.02)
    return root


# -----------------------------------------------------------------------------
# 11. PAYPHONE BOX (Pasáž wall payphone + acoustic hood)
# -----------------------------------------------------------------------------
def build_payphone_box(M):
    root = new_root("payphone_box")
    bm_box(root, "HoodTop", (0.48, 0.38, 0.05), M["steel"], loc=(0, -0.14, 0.66), bevel=0.01)
    for sx in (-0.23, 0.23):
        bm_box(root, f"HoodSide_{sx}", (0.04, 0.36, 0.66), M["steel"], loc=(sx, -0.14, 0.33), bevel=0.008)
    bm_box(root, "PhoneBody", (0.30, 0.18, 0.48), M["bumper"], loc=(0, -0.05, 0.34), bevel=0.014)
    bm_box(root, "KeypadPlate", (0.14, 0.03, 0.16), M["steel"], loc=(0.04, -0.145, 0.34))
    bm_box(root, "CoinSlot", (0.05, 0.03, 0.08), M["brass"], loc=(0.07, -0.145, 0.49))
    bm_box(root, "Handset", (0.06, 0.06, 0.28), M["bakelite"], loc=(-0.08, -0.16, 0.36), bevel=0.01)
    return root


# -----------------------------------------------------------------------------
# 12. TRANSISTOR RADIO (50.4 Hz)
# -----------------------------------------------------------------------------
def build_transistor_radio(M):
    root = new_root("transistor_radio")
    bm_box(root, "RadioCase", (0.32, 0.12, 0.20), M["bakelite"], loc=(0, 0, 0.10), bevel=0.014)
    bm_box(root, "SpeakerGrille", (0.17, 0.02, 0.15), M["steel"], loc=(-0.055, -0.062, 0.10))
    bm_box(root, "TunerWindow", (0.09, 0.02, 0.06), M["amber_glow"], loc=(0.09, -0.062, 0.135))
    for dz in (0.06, 0.09):
        bm_cyl(root, f"Knob_{dz}", 0.016, 0.014, 0.02, M["brass"], segs=12, loc=(0.09, -0.068, dz), rot=(90, 0, 0))
    bm_box(root, "HandleBar", (0.24, 0.025, 0.025), M["steel"], loc=(0, 0, 0.24))
    bm_cyl(root, "WhipAntenna", 0.005, 0.002, 0.48, M["steel"], segs=8, loc=(0.12, 0.03, 0.42), rot=(0, 12, 0))
    return root


# -----------------------------------------------------------------------------
# 13. STA ANTENNA MAST (Rooftop lattice TV aerial)
# -----------------------------------------------------------------------------
def build_sta_antenna_mast(M):
    root = new_root("sta_antenna_mast")
    bm_box(root, "MastBase", (0.72, 0.72, 0.16), M["stone"], loc=(0, 0, 0.08), bevel=0.02)
    for sx in (-0.18, 0.18):
        for sy in (-0.18, 0.18):
            bm_cyl(root, f"Leg_{sx}_{sy}", 0.025, 0.020, 4.80, M["galvanized"], segs=8, loc=(sx, sy, 2.48))
    for bz in (0.8, 1.6, 2.4, 3.2, 4.0, 4.8):
        bm_box(root, f"BraceX_{bz}", (0.40, 0.40, 0.035), M["galvanized"], loc=(0, 0, bz))
    bm_box(root, "SplitterBox", (0.28, 0.18, 0.36), M["iron"], loc=(0, -0.24, 1.15), bevel=0.01)
    # Stacked Yagi crossbars
    for az, w in [(3.6, 1.8), (4.2, 2.3), (4.7, 1.5)]:
        bm_box(root, f"YagiBoom_{az}", (0.04, 1.35, 0.04), M["steel"], loc=(0, 0, az))
        for dy in (-0.55, -0.2, 0.2, 0.55):
            bm_cyl(root, f"Dipole_{az}_{dy}", 0.012, 0.012, w, M["steel"], segs=8, loc=(0, dy, az), rot=(0, 90, 0))
    bm_sphere(root, "TopBeacon", 0.065, M["ember_glow"], loc=(0, 0, 5.0))
    return root


# -----------------------------------------------------------------------------
# 14. DEVICE K-4 (1953 StB electromagnetic resonator over well core)
# -----------------------------------------------------------------------------
def build_device_k4(M):
    root = new_root("device_k4")
    bm_cyl(root, "SteelPlinth", 0.85, 0.92, 0.22, M["iron"], segs=12, loc=(0, 0, 0.11), smooth=False)
    bm_cyl(root, "CorePillar", 0.42, 0.42, 1.55, M["bumper"], segs=16, loc=(0, 0, 0.98))
    for cz in (0.65, 1.05, 1.45):
        bm_torus(root, f"CopperCoil_{cz}", 0.48, 0.065, M["copper"], maj_s=24, min_s=10, loc=(0, 0, cz))
    # 4 Glowing phosphor-green vacuum tubes around crown
    for k in range(4):
        ang = k * math.pi * 0.5 + math.pi * 0.25
        vx, vy = math.cos(ang) * 0.52, math.sin(ang) * 0.52
        bm_cyl(root, f"TubeSocket_{k}", 0.08, 0.08, 0.12, M["brass"], segs=12, loc=(vx, vy, 1.75))
        bm_cyl(root, f"VacuumTube_{k}", 0.055, 0.055, 0.34, M["k4_phosphor"], segs=14, loc=(vx, vy, 1.98))
    bm_sphere(root, "ResonatorCore", 0.30, M["k4_phosphor"], loc=(0, 0, 1.95))
    bm_box(root, "ConsoleBox", (0.58, 0.36, 0.85), M["iron"], loc=(0, -0.78, 0.42), bevel=0.02)
    bm_box(root, "Oscilloscope", (0.28, 0.04, 0.22), M["k4_phosphor"], loc=(-0.10, -0.96, 0.68))
    return root


# -----------------------------------------------------------------------------
# 15. DUMPSTER 90S (European metal 1100L wheeled kontajner + trash bags)
# -----------------------------------------------------------------------------
def build_dumpster_90s(M):
    root = new_root("dumpster_90s")
    bm_box(root, "BinBody", (1.36, 0.98, 1.02), M["galvanized"], loc=(0, 0, 0.68), bevel=0.03)
    bm_box(root, "BinRim", (1.44, 1.06, 0.08), M["iron"], loc=(0, 0, 1.18), bevel=0.015)
    bm_box(root, "BinLid", (1.40, 1.02, 0.14), M["bumper"], loc=(0, 0, 1.28), rot=(8, 0, 0), bevel=0.04)
    for wx in (-0.54, 0.54):
        for wy in (-0.36, 0.36):
            bm_cyl(root, f"Wheel_{wx}_{wy}", 0.085, 0.085, 0.05, M["rubber"], segs=12, loc=(wx, wy, 0.085), rot=(0, 90, 0))
    bm_sphere(root, "TrashBag1", 0.28, M["garbage_bag"], scale=(1.1, 1.0, 0.85), loc=(0.95, -0.22, 0.24))
    bm_sphere(root, "TrashBag2", 0.24, M["garbage_bag"], scale=(0.95, 1.1, 0.8), loc=(0.82, 0.24, 0.20))
    return root


# -----------------------------------------------------------------------------
# 16. RED BULKHEAD DOOR (Pivot along left edge at X=0, width=1.6m along +X or +Y)
# -----------------------------------------------------------------------------
def build_red_bulkhead_door(M):
    # Pivot at (0, 0, 0); door extends +Z(Godot) i.e. Blender -Y/+X cleanly; match original (0, 1.1, 0.85) in Godot -> Blender +X/Z:
    # Let door span Blender Y from 0.0 to -1.65 (which maps in Godot to +Z from 0.0 to +1.65!), thickness along X!
    root = new_root("red_bulkhead_door")
    bm_box(root, "DoorLeaf", (0.14, 1.62, 2.18), M["red_paint"], loc=(0, -0.82, 1.09), bevel=0.015)
    for hz in (0.35, 1.10, 1.85):
        bm_box(root, f"StrapHinge_{hz}", (0.18, 0.72, 0.09), M["iron"], loc=(0, -0.36, hz))
    # Locking wheel on both faces
    for sx in (-0.11, 0.11):
        bm_torus(root, f"LockWheel_{sx}", 0.18, 0.025, M["steel"], maj_s=16, min_s=8, loc=(sx, -1.18, 1.10), rot=(0, 90, 0))
    bm_box(root, "WarningPlaque", (0.16, 0.34, 0.18), M["dial_cream"], loc=(0, -0.82, 1.56))
    return root


# -----------------------------------------------------------------------------
# 17. HUMANOID GUARD / NPC (Overcoat, boots, limbs, head, cap)
# -----------------------------------------------------------------------------
def build_humanoid_guard(M):
    root = new_root("humanoid_guard")
    for sx in (-0.11, 0.11):
        bm_cyl(root, f"Boot_{sx}", 0.065, 0.055, 0.24, M["rubber"], segs=10, loc=(sx, 0, 0.12))
        bm_cyl(root, f"Leg_{sx}", 0.075, 0.065, 0.62, M["bumper"], segs=10, loc=(sx, 0, 0.54))
    bm_cyl(root, "OvercoatSkirt", 0.24, 0.19, 0.56, M["coat_sbs"], segs=14, loc=(0, 0, 0.88))
    bm_box(root, "Torso", (0.42, 0.24, 0.54), M["coat_sbs"], loc=(0, 0, 1.24), bevel=0.04)
    for sx in (-0.26, 0.26):
        bm_cyl(root, f"Arm_{sx}", 0.065, 0.05, 0.60, M["coat_sbs"], segs=10, loc=(sx, 0, 1.16), rot=(8, sx * 12, 0))
        bm_sphere(root, f"Hand_{sx}", 0.045, M["skin_pale"], loc=(sx * 1.03, -0.04, 0.84))
    bm_sphere(root, "Head", 0.115, M["skin_pale"], scale=(0.9, 0.98, 1.12), loc=(0, 0, 1.64))
    bm_cyl(root, "CapCrown", 0.125, 0.135, 0.09, M["coat_sbs"], segs=14, loc=(0, 0.01, 1.74))
    bm_box(root, "CapVisor", (0.17, 0.11, 0.02), M["bumper"], loc=(0, -0.10, 1.70))
    return root


# -----------------------------------------------------------------------------
# 18. ENTITY SHADOW (Tall 2.35m gaunt VHS shadow silhouette)
# -----------------------------------------------------------------------------
def build_entity_shadow(M):
    root = new_root("entity_shadow")
    for sx in (-0.12, 0.12):
        bm_cyl(root, f"LongLeg_{sx}", 0.06, 0.045, 1.18, M["shadow_void"], segs=10, loc=(sx, 0, 0.59))
    bm_cyl(root, "GauntTorso", 0.18, 0.13, 0.82, M["shadow_void"], segs=12, loc=(0, -0.04, 1.52), rot=(6, 0, 0))
    for sx in (-0.23, 0.23):
        bm_cyl(root, f"LongArm_{sx}", 0.048, 0.032, 1.05, M["shadow_void"], segs=10, loc=(sx, -0.05, 1.38), rot=(10, sx * 8, 0))
    bm_sphere(root, "VoidHead", 0.115, M["shadow_void"], scale=(0.82, 0.92, 1.32), loc=(0, -0.09, 2.08), rot=(12, 14, 18))
    return root


def main():
    builders = {
        "skoda_favorit": build_skoda_favorit,
        "medieval_well": build_medieval_well,
        "carriage_gate": build_carriage_gate,
        "guard_booth_desk": build_guard_booth_desk,
        "tesla_crt_monitor": build_tesla_crt_monitor,
        "rotary_phone": build_rotary_phone,
        "watchmans_clock": build_watchmans_clock,
        "streetlamp_sodium": build_streetlamp_sodium,
        "boiler_furnace": build_boiler_furnace,
        "grandfather_clock": build_grandfather_clock,
        "payphone_box": build_payphone_box,
        "transistor_radio": build_transistor_radio,
        "sta_antenna_mast": build_sta_antenna_mast,
        "device_k4": build_device_k4,
        "dumpster_90s": build_dumpster_90s,
        "red_bulkhead_door": build_red_bulkhead_door,
        "humanoid_guard": build_humanoid_guard,
        "entity_shadow": build_entity_shadow,
    }
    for name, fn in builders.items():
        reset_scene()
        M = get_mats()
        root = fn(M)
        out_path = OUT_DIR / f"{name}.glb"
        export_glb(root, out_path)
        print(f"EXPORTED_GLB={out_path.name}")


if __name__ == "__main__":
    main()
