r"""
Builds Prompt 06 unique articulated 3D character models & patrol wayfinding props
into D:\nocna-zmena-blok-14\assets\models\:

Characters (every important NPC & resident gets a unique 1996 Central European model
with articulated TorsoPivot, HeadPivot, ArmL_Pivot, ArmR_Pivot, LegL_Pivot, LegR_Pivot):
  - char_varga.glb      (Jozef Varga, 51 — Security Supervisor, receding grey hair, brown-grey jacket, clipboard)
  - char_anna.glb       (Anna Krížanová, 68 — Resident, light-grey hair, slightly stooped wool cardigan, skirt, shopping bag)
  - char_dana.glb       (Dana Bieliková, 39 — Večierka/Newsstand worker, medium brown hair, knit sweater, shop apron)
  - char_zuzana.glb     (Zuzana Horváthová, 46 — Trafika vendor, glasses, pinned dark hair, burgundy cardigan)
  - char_peter.glb      (Peter, 12 — Local child, 1.38m build, 1996 striped windbreaker, jeans, sneakers)
  - char_milan.glb      (Milan Švec, 44 — Disheveled former guard, unkempt brown hair, stubble, worn security jacket)
  - char_roman.glb      (Roman Král, 46 — Human antagonist / former maintenance worker, scar, dark brown jacket, gloves, keyring)
  - char_iveta.glb      (Iveta Hrončová, 34 — Respectful grounded Night 5 discovery, faded coat, handbag, damaged phone)
  - char_resident_a.glb (Older male resident carrying grocery bag)
  - char_resident_b.glb (Young woman resident in burgundy parka carrying tote)
  - char_resident_c.glb (Delivery / estate maintenance worker in blue overalls carrying crate)

Props & Upgraded Hero Assets:
  - patrol_marker_post.glb (1996 galvanized security patrol checkpoint post with weathered reflective strip)
  - fp_guard_body.glb      (Upgraded Martin Kováč first-person body: dark navy jacket, badge, grey sweater, wristwatch, boots)
"""
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


def make_empty(name, parent=None, loc=(0, 0, 0), rot=(0, 0, 0)):
    obj = bpy.data.objects.new(name, None)
    obj.location = Vector(loc)
    obj.rotation_euler = Euler(rot, "XYZ")
    bpy.context.scene.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    return obj


def _link_obj(obj, parent):
    bpy.context.scene.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    return obj


def make_mat(name, color, metallic=0.0, roughness=0.72, emission=None, emit_str=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is None:
        bsdf = mat.node_tree.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
    bsdf.inputs["Metallic"].default_value = float(metallic)
    bsdf.inputs["Roughness"].default_value = float(roughness)
    if emission is not None and "Emission Color" in bsdf.inputs:
        bsdf.inputs["Emission Color"].default_value = (emission[0], emission[1], emission[2], 1.0)
        bsdf.inputs["Emission Strength"].default_value = float(emit_str)
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


def bm_cyl(parent, name, r1, r2, h, mat, segs=14, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=smooth)


def bm_sphere(parent, name, rad, mat, scale=(1, 1, 1), loc=(0, 0, 0), rot=(0, 0, 0), sub=2):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=rad)
    bmesh.ops.transform(bm, matrix=Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0)), verts=bm.verts)
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
        export_apply=False,  # Preserve articulated child pivots cleanly for Godot procedural animation!
    )
    print(f"EXPORTED_P6_GLB: {filename} ({os.path.getsize(out_path)} bytes)")


# ---------------------------------------------------------------------------
# Articulated 1996 Central European Character Builder
# Blender axes: +X right, -Y forward (maps to +Z in Godot with export_yup=True), +Z up
# Note: in Godot, standard characters face +Z or -Z; we face -Y in Blender so Godot +Z is front!
# ---------------------------------------------------------------------------
def build_human_character(cfg):
    clear_scene()
    root = make_empty(cfg["root_name"])

    h_scale = float(cfg.get("height_scale", 1.0))
    w_scale = float(cfg.get("width_scale", 1.0))
    stoop = float(cfg.get("stoop_rad", 0.0))

    m_skin = make_mat("Skin", cfg["skin"], roughness=0.62)
    m_hair = make_mat("Hair", cfg["hair"], roughness=0.82)
    m_jacket = make_mat("Jacket", cfg["jacket"], roughness=0.84)
    m_shirt = make_mat("Shirt", cfg["shirt"], roughness=0.80)
    m_pants = make_mat("Pants", cfg["pants"], roughness=0.86)
    m_shoes = make_mat("Shoes", cfg.get("shoes", (0.07, 0.06, 0.06)), roughness=0.48)
    m_eye_w = make_mat("EyeWhite", (0.86, 0.85, 0.82), roughness=0.22)
    m_pupil = make_mat("Pupil", cfg.get("eye_col", (0.14, 0.17, 0.22)), roughness=0.14)
    m_lip = make_mat("Lip", cfg.get("lip_col", (0.52, 0.31, 0.28)), roughness=0.58)
    m_brow = make_mat("Brow", cfg.get("brow_col", cfg["hair"]), roughness=0.85)
    m_belt = make_mat("Belt", (0.10, 0.08, 0.06), roughness=0.45)
    m_brass = make_mat("Brass", (0.64, 0.52, 0.24), metallic=0.82, roughness=0.32)

    hip_z = 0.88 * h_scale
    shoulder_z = 1.44 * h_scale
    neck_z = 1.50 * h_scale

    # Pelvis / Hips
    bm_box(root, "Pelvis", (0.31 * w_scale, 0.20 * w_scale, 0.16 * h_scale), m_pants, loc=(0, 0, hip_z), bevel=0.03)
    bm_box(root, "WaistBelt", (0.32 * w_scale, 0.21 * w_scale, 0.045), m_belt, loc=(0, 0, hip_z + 0.05 * h_scale), bevel=0.008)
    bm_box(root, "BeltBuckle", (0.048, 0.02, 0.048), m_brass, loc=(0, -0.108 * w_scale, hip_z + 0.05 * h_scale), bevel=0.005)

    # Legs (Articulated pivots at hips)
    is_skirt = bool(cfg.get("skirt", False))
    if is_skirt:
        bm_cyl(root, "SkirtBody", 0.24 * w_scale, 0.165 * w_scale, 0.58 * h_scale, m_pants, segs=16, loc=(0, 0, hip_z - 0.26 * h_scale))

    for side_name, sx in [("LegL_Pivot", -0.092 * w_scale), ("LegR_Pivot", 0.092 * w_scale)]:
        leg_p = make_empty(side_name, root, loc=(sx, 0, hip_z - 0.02))
        if not is_skirt:
            bm_cyl(leg_p, side_name + "_Thigh", 0.066 * w_scale, 0.078 * w_scale, 0.42 * h_scale, m_pants, segs=12, loc=(0, 0, -0.21 * h_scale))
            bm_cyl(leg_p, side_name + "_Shin", 0.052 * w_scale, 0.064 * w_scale, 0.40 * h_scale, m_pants, segs=12, loc=(0, 0, -0.60 * h_scale))
        else:
            bm_cyl(leg_p, side_name + "_Calf", 0.042 * w_scale, 0.048 * w_scale, 0.36 * h_scale, m_skin, segs=12, loc=(0, 0, -0.62 * h_scale))
        bm_box(leg_p, side_name + "_Shoe", (0.095 * w_scale, 0.24 * h_scale, 0.08 * h_scale), m_shoes, loc=(0, -0.038 * h_scale, -0.82 * h_scale), bevel=0.018)

    # Torso Pivot (supports breathing, stooping, leaning)
    torso_p = make_empty("TorsoPivot", root, loc=(0, 0, hip_z + 0.06 * h_scale), rot=(stoop, 0, 0))
    torso_h = (shoulder_z - hip_z) * 0.96
    bm_box(torso_p, "JacketChest", (0.37 * w_scale, 0.22 * w_scale, torso_h), m_jacket, loc=(0, 0, torso_h * 0.48), bevel=0.042)
    # Shirt / Sweater V-insert & Collar
    bm_box(torso_p, "InnerShirt", (0.14 * w_scale, 0.04, torso_h * 0.64), m_shirt, loc=(0, -0.102 * w_scale, torso_h * 0.56), bevel=0.01)
    bm_cyl(torso_p, "CollarRing", 0.088 * w_scale, 0.096 * w_scale, 0.065, m_jacket, segs=14, loc=(0, 0, torso_h + 0.01))

    # Jacket lapels & buttons
    for lx in [-0.075 * w_scale, 0.075 * w_scale]:
        bm_box(torso_p, f"Lapel_{int(lx*100)}", (0.06 * w_scale, 0.025, torso_h * 0.52), m_jacket, loc=(lx, -0.112 * w_scale, torso_h * 0.62), rot=(0, 0, 0.22 if lx < 0 else -0.22), bevel=0.008)
    for bi in range(3):
        bm_cyl(torso_p, f"Btn_{bi}", 0.012, 0.012, 0.014, m_belt, segs=8, loc=(0, -0.118 * w_scale, torso_h * (0.22 + bi * 0.16)), rot=(math.pi / 2, 0, 0))

    # Optional coat tails / apron / tie / badge / keyring / scarf
    if cfg.get("long_coat", False):
        bm_box(torso_p, "CoatSkirt", (0.39 * w_scale, 0.24 * w_scale, 0.34 * h_scale), m_jacket, loc=(0, 0.01, -0.14 * h_scale), bevel=0.03)
    if cfg.get("apron", None):
        m_apron = make_mat("ShopApron", cfg["apron"], roughness=0.84)
        bm_box(torso_p, "ApronFront", (0.33 * w_scale, 0.025, 0.62 * h_scale), m_apron, loc=(0, -0.118 * w_scale, 0.04 * h_scale), bevel=0.008)
        bm_box(torso_p, "ApronPocket", (0.16 * w_scale, 0.028, 0.13 * h_scale), m_apron, loc=(0, -0.128 * w_scale, -0.04 * h_scale), bevel=0.006)
    if cfg.get("tie", None):
        m_tie = make_mat("Tie", cfg["tie"], roughness=0.65)
        bm_box(torso_p, "NeckTie", (0.042, 0.018, 0.30 * h_scale), m_tie, loc=(0, -0.116 * w_scale, torso_h * 0.52), bevel=0.004)
    if cfg.get("badge", False):
        bm_box(torso_p, "SecurityBadge", (0.046, 0.012, 0.056), m_brass, loc=(0.095 * w_scale, -0.116 * w_scale, torso_h * 0.68), bevel=0.004)
    if cfg.get("scarf", None):
        m_scarf = make_mat("Scarf", cfg["scarf"], roughness=0.88)
        bm_cyl(torso_p, "ScarfLoop", 0.105 * w_scale, 0.105 * w_scale, 0.09, m_scarf, segs=14, loc=(0, 0, torso_h + 0.02))
        bm_box(torso_p, "ScarfTail", (0.09, 0.03, 0.26), m_scarf, loc=(0.05, -0.115 * w_scale, torso_h * 0.64), bevel=0.008)
    if cfg.get("stripe", None):
        m_str = make_mat("JacketStripe", cfg["stripe"], roughness=0.72)
        bm_box(torso_p, "WindbreakerStripe", (0.376 * w_scale, 0.228 * w_scale, 0.08 * h_scale), m_str, loc=(0, 0, torso_h * 0.64), bevel=0.01)
    if cfg.get("utility_keyring", False):
        bm_cyl(torso_p, "UtilityKeyRing", 0.028, 0.028, 0.008, m_brass, segs=12, loc=(0.175 * w_scale, -0.04, -0.02), rot=(0, math.pi / 2, 0))
        for ki in range(4):
            bm_box(torso_p, f"UtilKey_{ki}", (0.010, 0.018, 0.062), m_brass, loc=(0.182 * w_scale, -0.04 + (ki - 1.5) * 0.014, -0.062), rot=(0, 0.18 * ki, 0))

    # Head Pivot (attached to TorsoPivot so head turns & nods independently!)
    head_p = make_empty("HeadPivot", torso_p, loc=(0, 0, torso_h + 0.04))
    bm_cyl(head_p, "Neck", 0.056 * w_scale, 0.052 * w_scale, 0.09 * h_scale, m_skin, segs=12, loc=(0, 0, 0.035 * h_scale))
    # Distinct head proportions
    head_sx = float(cfg.get("head_sx", 0.96))
    head_sy = float(cfg.get("head_sy", 1.04))
    head_sz = float(cfg.get("head_sz", 1.15))
    hz = 0.155 * h_scale
    bm_sphere(head_p, "HeadCranium", 0.108 * h_scale, m_skin, scale=(head_sx, head_sy, head_sz), loc=(0, 0, hz), sub=3)
    # Jaw / Chin definition
    bm_box(head_p, "JawChin", (0.095 * h_scale * head_sx, 0.085 * h_scale, 0.065 * h_scale), m_skin, loc=(0, -0.038 * h_scale, hz - 0.068 * h_scale), bevel=0.022)
    # Nose bridge & tip
    bm_box(head_p, "Nose", (0.024 * h_scale, 0.042 * h_scale, 0.044 * h_scale), m_skin, loc=(0, -0.108 * h_scale * head_sy, hz - 0.008 * h_scale), rot=(0.24, 0, 0), bevel=0.008)
    # Ears
    for ex in [-0.104 * h_scale * head_sx, 0.104 * h_scale * head_sx]:
        bm_sphere(head_p, f"Ear_{int(ex*100)}", 0.024 * h_scale, m_skin, scale=(0.45, 0.78, 1.2), loc=(ex, 0.005, hz - 0.006), sub=2)
    # Eyes (sclera + dark iris/pupil) & Eyebrows
    for ex_sign in [-1.0, 1.0]:
        ex = ex_sign * 0.038 * h_scale
        ey = -0.096 * h_scale * head_sy
        ez = hz + 0.018 * h_scale
        bm_sphere(head_p, f"EyeW_{int(ex_sign)}", 0.015 * h_scale, m_eye_w, scale=(1.15, 0.65, 0.85), loc=(ex, ey, ez), sub=2)
        bm_sphere(head_p, f"Pupil_{int(ex_sign)}", 0.0085 * h_scale, m_pupil, scale=(1.0, 0.6, 1.0), loc=(ex, ey - 0.007 * h_scale, ez), sub=2)
        bm_box(head_p, f"Brow_{int(ex_sign)}", (0.036 * h_scale, 0.014 * h_scale, 0.009 * h_scale), m_brow, loc=(ex, ey - 0.006 * h_scale, ez + 0.022 * h_scale), rot=(0, 0, -0.08 * ex_sign), bevel=0.003)
    # Mouth / Lips
    bm_box(head_p, "Mouth", (0.044 * h_scale, 0.014 * h_scale, 0.011 * h_scale), m_lip, loc=(0, -0.096 * h_scale * head_sy, hz - 0.056 * h_scale), bevel=0.004)

    # Facial Stubble / Scar / Glasses
    if cfg.get("stubble", False):
        m_stub = make_mat("Stubble", (cfg["skin"][0] * 0.66, cfg["skin"][1] * 0.64, cfg["skin"][2] * 0.62), roughness=0.92)
        bm_box(head_p, "FacialStubble", (0.104 * h_scale * head_sx, 0.092 * h_scale, 0.068 * h_scale), m_stub, loc=(0, -0.042 * h_scale, hz - 0.070 * h_scale), bevel=0.025)
    if cfg.get("scar", False):
        m_scar = make_mat("FacialScar", (0.48, 0.25, 0.22), roughness=0.52)
        bm_box(head_p, "CheekScar", (0.008 * h_scale, 0.012 * h_scale, 0.044 * h_scale), m_scar, loc=(-0.058 * h_scale, -0.092 * h_scale, hz - 0.015 * h_scale), rot=(0, 0.35, 0.28), bevel=0.002)
    if cfg.get("glasses", False):
        m_frame = make_mat("GlassesFrame", (0.14, 0.12, 0.10), metallic=0.6, roughness=0.35)
        for ex_sign in [-1.0, 1.0]:
            bm_box(head_p, f"GlassLens_{int(ex_sign)}", (0.042 * h_scale, 0.008, 0.028 * h_scale), m_frame, loc=(ex_sign * 0.039 * h_scale, -0.112 * h_scale * head_sy, hz + 0.018 * h_scale), bevel=0.002)
        bm_box(head_p, "GlassBridge", (0.022 * h_scale, 0.008, 0.007 * h_scale), m_frame, loc=(0, -0.114 * h_scale * head_sy, hz + 0.022 * h_scale))

    # Distinct Hairstyles
    hstyle = cfg.get("hair_style", "short")
    if hstyle == "receding":
        bm_sphere(head_p, "HairBack", 0.112 * h_scale, m_hair, scale=(head_sx * 1.02, head_sy * 0.95, 0.85), loc=(0, 0.026 * h_scale, hz + 0.035 * h_scale), sub=2)
        for sx in [-0.092 * h_scale, 0.092 * h_scale]:
            bm_box(head_p, f"HairTemple_{int(sx*100)}", (0.028 * h_scale, 0.09 * h_scale, 0.075 * h_scale), m_hair, loc=(sx, 0.01, hz + 0.02 * h_scale), bevel=0.01)
    elif hstyle == "elder_curls":
        bm_sphere(head_p, "HairCurledCrown", 0.124 * h_scale, m_hair, scale=(1.08, 1.08, 0.96), loc=(0, 0.018 * h_scale, hz + 0.032 * h_scale), sub=3)
        bm_sphere(head_p, "HairNape", 0.088 * h_scale, m_hair, scale=(1.12, 0.82, 0.88), loc=(0, 0.068 * h_scale, hz - 0.025 * h_scale), sub=2)
    elif hstyle == "shoulder_bob":
        bm_sphere(head_p, "HairTop", 0.118 * h_scale, m_hair, scale=(1.06, 1.06, 1.02), loc=(0, 0.012 * h_scale, hz + 0.034 * h_scale), sub=3)
        bm_box(head_p, "HairBackFlow", (0.20 * h_scale, 0.085 * h_scale, 0.24 * h_scale), m_hair, loc=(0, 0.078 * h_scale, hz - 0.065 * h_scale), bevel=0.028)
        for sx in [-0.105 * h_scale, 0.105 * h_scale]:
            bm_box(head_p, f"HairSide_{int(sx*100)}", (0.042 * h_scale, 0.09 * h_scale, 0.20 * h_scale), m_hair, loc=(sx, 0.01, hz - 0.045 * h_scale), bevel=0.014)
    elif hstyle == "bun":
        bm_sphere(head_p, "HairCrown", 0.116 * h_scale, m_hair, scale=(1.04, 1.05, 0.96), loc=(0, 0.014 * h_scale, hz + 0.034 * h_scale), sub=2)
        bm_sphere(head_p, "HairBun", 0.055 * h_scale, m_hair, loc=(0, 0.118 * h_scale, hz + 0.015 * h_scale), sub=2)
    elif hstyle == "cap":
        m_cap = make_mat("WorkCap", cfg.get("cap_col", (0.14, 0.16, 0.18)), roughness=0.86)
        bm_sphere(head_p, "CapCrown", 0.116 * h_scale, m_cap, scale=(1.04, 1.08, 0.72), loc=(0, 0.005, hz + 0.065 * h_scale), sub=2)
        bm_box(head_p, "CapBrim", (0.15 * h_scale, 0.10 * h_scale, 0.014), m_cap, loc=(0, -0.105 * h_scale, hz + 0.048 * h_scale), rot=(0.14, 0, 0), bevel=0.005)
    else:  # short / unkempt
        bm_sphere(head_p, "HairShort", 0.115 * h_scale, m_hair, scale=(head_sx * 1.04, head_sy * 1.05, 0.92), loc=(0, 0.014 * h_scale, hz + 0.038 * h_scale), sub=2)
        if hstyle == "unkempt":
            for ti, tx in enumerate([-0.045, 0.0, 0.048]):
                bm_box(head_p, f"HairTuft_{ti}", (0.042, 0.048, 0.025), m_hair, loc=(tx * h_scale, -0.06 * h_scale, hz + 0.11 * h_scale), rot=(0.25, 0.15 * (ti - 1), 0), bevel=0.008)

    # Articulated Arms (attached to TorsoPivot shoulders)
    hand_mat = make_mat("WorkGloves", (0.11, 0.10, 0.09), roughness=0.88) if cfg.get("gloves", False) else m_skin
    arm_l = make_empty("ArmL_Pivot", torso_p, loc=(-0.22 * w_scale, 0, torso_h - 0.04))
    arm_r = make_empty("ArmR_Pivot", torso_p, loc=(0.22 * w_scale, 0, torso_h - 0.04))

    for ap, nm in [(arm_l, "L"), (arm_r, "R")]:
        bm_cyl(ap, f"UpperArm_{nm}", 0.046 * w_scale, 0.056 * w_scale, 0.28 * h_scale, m_jacket, segs=10, loc=(0, 0, -0.14 * h_scale))
        bm_cyl(ap, f"ForeArm_{nm}", 0.040 * w_scale, 0.046 * w_scale, 0.26 * h_scale, m_jacket, segs=10, loc=(0, -0.02 * h_scale, -0.39 * h_scale), rot=(0.14, 0, 0))
        bm_sphere(ap, f"Hand_{nm}", 0.042 * h_scale, hand_mat, scale=(0.82, 0.96, 1.15), loc=(0, -0.045 * h_scale, -0.54 * h_scale), sub=2)

    if cfg.get("watch", False):
        bm_cyl(arm_l, "WristWatch", 0.045 * w_scale, 0.045 * w_scale, 0.022, m_brass, segs=12, loc=(0, -0.038 * h_scale, -0.49 * h_scale))

    # Character-Specific Hand Props
    prop = cfg.get("hand_prop", "")
    if prop == "clipboard":
        m_board = make_mat("ClipboardWood", (0.34, 0.24, 0.14), roughness=0.72)
        m_paper = make_mat("ClipboardPaper", (0.85, 0.82, 0.74), roughness=0.90)
        bm_box(arm_l, "Clipboard", (0.22, 0.018, 0.30), m_board, loc=(0.04, -0.14, -0.48), rot=(0.65, 0.15, 0), bevel=0.005)
        bm_box(arm_l, "ClipboardSheet", (0.19, 0.008, 0.26), m_paper, loc=(0.04, -0.15, -0.48), rot=(0.65, 0.15, 0))
    elif prop == "shopping_bag":
        m_bag = make_mat("ClothShoppingBag", (0.44, 0.36, 0.26), roughness=0.90)
        bm_box(arm_r, "ShoppingBagBody", (0.12, 0.26, 0.28), m_bag, loc=(0.04, -0.04, -0.74), bevel=0.02)
        bm_cyl(arm_r, "BagHandle", 0.010, 0.010, 0.14, m_belt, segs=8, loc=(0.04, -0.04, -0.57))
    elif prop == "grocery_bag":
        m_pbag = make_mat("PaperGroceryBag", (0.58, 0.44, 0.28), roughness=0.92)
        bm_box(arm_r, "GroceryBag", (0.18, 0.24, 0.34), m_pbag, loc=(0.05, -0.10, -0.58), bevel=0.015)
    elif prop == "tote_bag":
        m_tote = make_mat("ToteBag", (0.28, 0.20, 0.18), roughness=0.82)
        bm_box(arm_l, "ToteBody", (0.11, 0.28, 0.26), m_tote, loc=(-0.04, -0.04, -0.72), bevel=0.02)
    elif prop == "crate":
        m_crate = make_mat("DeliveryCrate", (0.46, 0.34, 0.20), roughness=0.88)
        bm_box(arm_r, "DeliveryBox", (0.34, 0.26, 0.22), m_crate, loc=(-0.22, -0.22, -0.44), bevel=0.012)

    export_glb(root, cfg["filename"])


# ---------------------------------------------------------------------------
# Iveta Hrončová (34) — Grounded, Respectful Night 5 Body Discovery & Evidence
# ---------------------------------------------------------------------------
def build_char_iveta():
    clear_scene()
    root = make_empty("Char_Iveta_Discovery")
    m_skin = make_mat("IvetaSkin", (0.64, 0.56, 0.50), roughness=0.66)
    m_hair = make_mat("IvetaBrownHair", (0.20, 0.13, 0.09), roughness=0.82)
    m_coat = make_mat("IvetaFadedCoat", (0.34, 0.30, 0.24), roughness=0.88)
    m_blouse = make_mat("IvetaBlouse", (0.72, 0.68, 0.62), roughness=0.80)
    m_pants = make_mat("IvetaTrousers", (0.14, 0.15, 0.18), roughness=0.86)
    m_shoes = make_mat("IvetaShoes", (0.12, 0.09, 0.08), roughness=0.52)
    m_bag = make_mat("IvetaHandbag", (0.28, 0.14, 0.12), roughness=0.62)
    m_phone = make_mat("DamagedPhone", (0.18, 0.20, 0.22), roughness=0.45)
    m_paper = make_mat("IvetaDocument", (0.84, 0.80, 0.72), roughness=0.90)

    # Resting respectfully on her side along +X axis against storage wall (zero gratuitous gore)
    body = make_empty("IvetaBodyPose", root, loc=(0, 0, 0.14), rot=(0.0, math.radians(88), math.radians(12)))
    bm_box(body, "CoatTorso", (0.32, 0.20, 0.52), m_coat, loc=(0, 0, 0.26), bevel=0.04)
    bm_box(body, "BlouseCollar", (0.14, 0.05, 0.14), m_blouse, loc=(0, -0.09, 0.45), bevel=0.01)
    bm_box(body, "CoatLower", (0.34, 0.21, 0.28), m_coat, loc=(0, 0, -0.10), bevel=0.03)
    bm_sphere(body, "Head", 0.102, m_skin, scale=(0.94, 1.02, 1.12), loc=(0, 0.01, 0.64), sub=3)
    bm_sphere(body, "ShoulderHairTop", 0.114, m_hair, scale=(1.04, 1.06, 1.04), loc=(0, 0.025, 0.66), sub=3)
    bm_box(body, "ShoulderHairBack", (0.19, 0.08, 0.24), m_hair, loc=(0, 0.075, 0.55), bevel=0.025)
    # Legs gently bent
    bm_cyl(body, "LegL_Upper", 0.058, 0.068, 0.40, m_pants, segs=12, loc=(-0.08, -0.02, -0.34), rot=(0.24, 0, 0))
    bm_cyl(body, "LegL_Lower", 0.046, 0.056, 0.38, m_pants, segs=12, loc=(-0.08, 0.05, -0.68), rot=(-0.38, 0, 0))
    bm_box(body, "ShoeL", (0.085, 0.21, 0.07), m_shoes, loc=(-0.08, 0.08, -0.88), bevel=0.015)
    bm_cyl(body, "LegR_Upper", 0.058, 0.068, 0.40, m_pants, segs=12, loc=(0.08, -0.05, -0.34), rot=(0.32, 0, 0))
    bm_cyl(body, "LegR_Lower", 0.046, 0.056, 0.38, m_pants, segs=12, loc=(0.08, 0.02, -0.68), rot=(-0.42, 0, 0))
    bm_box(body, "ShoeR", (0.085, 0.21, 0.07), m_shoes, loc=(0.08, 0.04, -0.88), bevel=0.015)
    # Arms resting naturally
    bm_cyl(body, "ArmL", 0.040, 0.048, 0.48, m_coat, segs=10, loc=(-0.18, -0.08, 0.26), rot=(0.45, 0.15, 0))
    bm_sphere(body, "HandL", 0.036, m_skin, loc=(-0.16, -0.22, 0.06), sub=2)
    bm_cyl(body, "ArmR", 0.040, 0.048, 0.48, m_coat, segs=10, loc=(0.18, -0.04, 0.24), rot=(0.25, -0.20, 0))
    bm_sphere(body, "HandR", 0.036, m_skin, loc=(0.22, -0.14, 0.04), sub=2)

    # Identifiable Evidence around scene: handbag, damaged telephone + detached handset, dropped notebook/document
    bm_box(root, "IvetaHandbag", (0.28, 0.12, 0.20), m_bag, loc=(0.45, -0.42, 0.10), rot=(0.15, 0.10, 0.65), bevel=0.022)
    bm_box(root, "DamagedPhoneBase", (0.18, 0.20, 0.09), m_phone, loc=(0.76, -0.28, 0.045), rot=(0, 0, -0.45), bevel=0.012)
    bm_box(root, "DetachedHandset", (0.22, 0.055, 0.048), m_phone, loc=(0.94, -0.44, 0.03), rot=(0.1, 0.0, 0.85), bevel=0.012)
    bm_box(root, "IvetaDocumentSheet", (0.21, 0.28, 0.012), m_paper, loc=(0.22, -0.52, 0.008), rot=(0, 0, 0.32), bevel=0.002)

    export_glb(root, "char_iveta.glb")


# ---------------------------------------------------------------------------
# Layer B Fog-Aware Physical Patrol Marker Post (patrol_marker_post.glb)
# ---------------------------------------------------------------------------
def build_patrol_marker_post():
    clear_scene()
    root = make_empty("PatrolMarkerPost")
    m_post = make_mat("GalvanizedPost", (0.32, 0.34, 0.35), metallic=0.68, roughness=0.56)
    m_base = make_mat("ConcreteFoot", (0.28, 0.28, 0.27), roughness=0.92)
    m_plate = make_mat("PatrolPlateEnamel", (0.16, 0.20, 0.24), metallic=0.25, roughness=0.52)
    m_reflect = make_mat(
        "ReflectiveStripMat", (0.86, 0.44, 0.14),
        metallic=0.15, roughness=0.26, emission=(0.85, 0.42, 0.12), emit_str=0.22
    )
    m_arrow = make_mat("PaintedArrowWhite", (0.80, 0.78, 0.72), roughness=0.72)

    bm_box(root, "ConcreteBase", (0.22, 0.22, 0.12), m_base, loc=(0, 0, 0.06), bevel=0.012)
    bm_cyl(root, "SteelPole", 0.032, 0.032, 1.24, m_post, segs=12, loc=(0, 0, 0.68))
    bm_box(root, "EnamelPlaque", (0.24, 0.028, 0.20), m_plate, loc=(0, -0.025, 1.16), bevel=0.006)
    # Named ReflectiveStrip so NavigationHintManager can modulate subtlety per nav_assist setting!
    bm_box(root, "ReflectiveStrip", (0.20, 0.012, 0.048), m_reflect, loc=(0, -0.042, 1.21), bevel=0.003)
    bm_box(root, "ReflectiveBandLow", (0.072, 0.072, 0.055), m_reflect, loc=(0, 0, 0.86), bevel=0.004)
    # Painted white directional chevron bar
    bm_box(root, "ArrowStem", (0.11, 0.010, 0.022), m_arrow, loc=(-0.01, -0.041, 1.12))
    bm_box(root, "ArrowHeadTop", (0.055, 0.010, 0.018), m_arrow, loc=(0.045, -0.041, 1.136), rot=(0, -0.68, 0))
    bm_box(root, "ArrowHeadBot", (0.055, 0.010, 0.018), m_arrow, loc=(0.045, -0.041, 1.104), rot=(0, 0.68, 0))

    export_glb(root, "patrol_marker_post.glb")


# ---------------------------------------------------------------------------
# Upgraded Martin Kováč First-Person Body (fp_guard_body.glb)
# Preserves exact node names used by FirstPersonBodyController (TorsoJacket, Thigh_L/R, Shin_L/R, BootFoot_L/R)
# Adds navy jacket badge, grey sweater, wristwatch & realistic folds!
# ---------------------------------------------------------------------------
def build_upgraded_fp_guard_body():
    clear_scene()
    root = make_empty("FP_GuardBody_Martin")
    m_jacket = make_mat("MartinNavyJacket", (0.09, 0.13, 0.20), roughness=0.84)
    m_sweater = make_mat("MartinGreySweater", (0.30, 0.31, 0.33), roughness=0.88)
    m_trouser = make_mat("MartinDarkTrousers", (0.08, 0.09, 0.11), roughness=0.86)
    m_belt = make_mat("MartinBelt", (0.08, 0.07, 0.06), roughness=0.45)
    m_brass = make_mat("MartinBadgeBrass", (0.68, 0.56, 0.26), metallic=0.84, roughness=0.28)
    m_boot = make_mat("MartinBlackShoes", (0.05, 0.05, 0.05), roughness=0.42)

    bm_box(root, "TorsoJacket", (0.38, 0.23, 0.54), m_jacket, loc=(0, 0.02, 1.12), bevel=0.045)
    bm_box(root, "SweaterInsert", (0.14, 0.04, 0.26), m_sweater, loc=(0, -0.095, 1.24), bevel=0.01)
    bm_box(root, "MartinSecurityBadge", (0.048, 0.012, 0.058), m_brass, loc=(0.10, -0.105, 1.26), bevel=0.004)
    bm_box(root, "JacketPocketL", (0.10, 0.022, 0.11), m_jacket, loc=(-0.10, -0.102, 0.98), bevel=0.008)
    bm_box(root, "JacketPocketR", (0.10, 0.022, 0.11), m_jacket, loc=(0.10, -0.102, 0.98), bevel=0.008)
    bm_box(root, "UtilityBelt", (0.39, 0.24, 0.055), m_belt, loc=(0, 0.02, 0.87), bevel=0.01)
    bm_box(root, "BeltBuckle", (0.058, 0.022, 0.058), m_brass, loc=(0, -0.108, 0.87), bevel=0.005)
    bm_box(root, "RadioHolster", (0.068, 0.088, 0.12), m_belt, loc=(-0.20, 0.0, 0.84), bevel=0.01)
    bm_box(root, "KeyPouch", (0.065, 0.075, 0.095), m_belt, loc=(0.20, -0.02, 0.85), bevel=0.01)
    bm_box(root, "PelvisTrousers", (0.34, 0.21, 0.16), m_trouser, loc=(0, 0.02, 0.78), bevel=0.03)

    # Articulated legs matching exact FirstPersonBodyController names
    bm_cyl(root, "Thigh_L", 0.072, 0.084, 0.42, m_trouser, segs=12, loc=(-0.10, 0.01, 0.56))
    bm_cyl(root, "Thigh_R", 0.072, 0.084, 0.42, m_trouser, segs=12, loc=(0.10, 0.01, 0.56))
    bm_cyl(root, "Shin_L", 0.056, 0.068, 0.40, m_trouser, segs=12, loc=(-0.10, 0.01, 0.22))
    bm_cyl(root, "Shin_R", 0.056, 0.068, 0.40, m_trouser, segs=12, loc=(0.10, 0.01, 0.22))
    bm_box(root, "BootFoot_L", (0.105, 0.25, 0.085), m_boot, loc=(-0.10, -0.045, 0.042), bevel=0.02)
    bm_box(root, "BootFoot_R", (0.105, 0.25, 0.085), m_boot, loc=(0.10, -0.045, 0.042), bevel=0.02)

    export_glb(root, "fp_guard_body.glb")


CHARACTER_SPECS = [
    {
        "filename": "char_varga.glb",
        "root_name": "Char_JozefVarga",
        "height_scale": 1.01,
        "width_scale": 1.05,
        "skin": (0.74, 0.58, 0.47),
        "hair": (0.30, 0.30, 0.31),
        "hair_style": "receding",
        "jacket": (0.22, 0.19, 0.16),  # Brown-grey supervisor jacket
        "shirt": (0.72, 0.72, 0.68),
        "pants": (0.16, 0.16, 0.17),
        "tie": (0.28, 0.14, 0.13),
        "watch": True,
        "hand_prop": "clipboard",
    },
    {
        "filename": "char_anna.glb",
        "root_name": "Char_AnnaKrizanova",
        "height_scale": 0.90,
        "width_scale": 0.92,
        "stoop_rad": 0.11,
        "skin": (0.78, 0.65, 0.56),
        "hair": (0.72, 0.72, 0.70),
        "hair_style": "elder_curls",
        "jacket": (0.38, 0.30, 0.26),  # Warm wool cardigan
        "shirt": (0.78, 0.74, 0.66),
        "pants": (0.14, 0.13, 0.15),   # Dark skirt
        "skirt": True,
        "scarf": (0.48, 0.36, 0.24),
        "hand_prop": "shopping_bag",
    },
    {
        "filename": "char_dana.glb",
        "root_name": "Char_DanaBielikova",
        "height_scale": 0.94,
        "width_scale": 0.90,
        "skin": (0.79, 0.63, 0.53),
        "hair": (0.34, 0.24, 0.15),
        "hair_style": "shoulder_bob",
        "jacket": (0.46, 0.36, 0.28),  # Warm knit sweater
        "shirt": (0.76, 0.74, 0.70),
        "pants": (0.13, 0.14, 0.16),
        "apron": (0.16, 0.34, 0.36),   # Authentic 1996 shop apron
        "lip_col": (0.58, 0.28, 0.28),
    },
    {
        "filename": "char_zuzana.glb",
        "root_name": "Char_ZuzanaHorvathova",
        "height_scale": 0.93,
        "width_scale": 0.94,
        "skin": (0.77, 0.62, 0.52),
        "hair": (0.18, 0.13, 0.10),
        "hair_style": "bun",
        "glasses": True,
        "jacket": (0.36, 0.14, 0.16),  # Burgundy cardigan
        "shirt": (0.74, 0.70, 0.62),
        "pants": (0.15, 0.15, 0.16),
    },
    {
        "filename": "char_peter.glb",
        "root_name": "Char_PeterChild",
        "height_scale": 0.78,
        "width_scale": 0.76,
        "skin": (0.81, 0.66, 0.56),
        "hair": (0.24, 0.17, 0.11),
        "hair_style": "unkempt",
        "jacket": (0.14, 0.32, 0.34),  # 1996 teal windbreaker
        "stripe": (0.82, 0.56, 0.18),
        "shirt": (0.74, 0.74, 0.72),
        "pants": (0.16, 0.22, 0.34),   # Denim jeans
        "shoes": (0.68, 0.68, 0.66),
    },
    {
        "filename": "char_milan.glb",
        "root_name": "Char_MilanSvec",
        "height_scale": 0.98,
        "width_scale": 0.93,
        "skin": (0.71, 0.60, 0.53),    # Pale & tired
        "hair": (0.21, 0.15, 0.11),
        "hair_style": "unkempt",
        "stubble": True,
        "jacket": (0.12, 0.15, 0.21),  # Worn security jacket
        "shirt": (0.34, 0.33, 0.30),
        "pants": (0.11, 0.11, 0.13),
        "badge": True,
    },
    {
        "filename": "char_roman.glb",
        "root_name": "Char_RomanKral",
        "height_scale": 1.02,
        "width_scale": 1.07,           # Solid ordinary human maintenance build
        "skin": (0.70, 0.55, 0.45),    # Weathered skin
        "hair": (0.18, 0.17, 0.17),    # Dark with grey
        "hair_style": "short",
        "stubble": True,
        "scar": True,
        "jacket": (0.18, 0.12, 0.08),  # Dark brown maintenance jacket
        "shirt": (0.36, 0.36, 0.36),   # Faded grey sweater
        "pants": (0.14, 0.14, 0.13),   # Old work trousers
        "shoes": (0.09, 0.07, 0.05),   # Heavy worn work boots
        "gloves": True,
        "utility_keyring": True,
        "long_coat": True,
    },
    {
        "filename": "char_resident_a.glb",
        "root_name": "Char_ResidentOlderMan",
        "height_scale": 0.97,
        "width_scale": 1.00,
        "stoop_rad": 0.06,
        "skin": (0.76, 0.61, 0.51),
        "hair": (0.56, 0.56, 0.54),
        "hair_style": "cap",
        "cap_col": (0.24, 0.22, 0.18),
        "jacket": (0.24, 0.26, 0.20),  # Olive wool autumn overcoat
        "shirt": (0.64, 0.60, 0.52),
        "pants": (0.18, 0.17, 0.16),
        "long_coat": True,
        "hand_prop": "grocery_bag",
    },
    {
        "filename": "char_resident_b.glb",
        "root_name": "Char_ResidentWoman",
        "height_scale": 0.92,
        "width_scale": 0.88,
        "skin": (0.80, 0.65, 0.55),
        "hair": (0.34, 0.18, 0.12),
        "hair_style": "shoulder_bob",
        "jacket": (0.40, 0.15, 0.17),  # Burgundy autumn parka
        "shirt": (0.74, 0.72, 0.68),
        "pants": (0.14, 0.16, 0.22),
        "scarf": (0.64, 0.58, 0.44),
        "hand_prop": "tote_bag",
    },
    {
        "filename": "char_resident_c.glb",
        "root_name": "Char_ResidentWorker",
        "height_scale": 1.00,
        "width_scale": 1.02,
        "skin": (0.74, 0.58, 0.48),
        "hair": (0.22, 0.16, 0.12),
        "hair_style": "cap",
        "cap_col": (0.12, 0.18, 0.28),
        "jacket": (0.13, 0.20, 0.30),  # Blue maintenance/delivery overalls jacket
        "shirt": (0.48, 0.46, 0.42),
        "pants": (0.12, 0.18, 0.28),
        "gloves": True,
        "hand_prop": "crate",
    },
]


if __name__ == "__main__":
    for spec in CHARACTER_SPECS:
        build_human_character(spec)
    build_char_iveta()
    build_patrol_marker_post()
    build_upgraded_fp_guard_body()
    print("PROMPT06_CHARACTERS_ALL_DONE")
