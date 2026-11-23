r"""
Builds Prompt 04 Blender 3D (.glb) assets into D:\nocna-zmena-blok-14\assets\models\:
- vm_empty_hands.glb       (pair of 1996 security guard forearms & gloved hands in natural resting posture)
- fp_guard_body.glb        (first-person lower torso, dark security jacket, utility belt, trousers, and boots)
- crime_evidence_bag.glb   (abandoned shopping bag, scarf, keyring, and cracked glasses for Event D / Event H)
- crime_victim_body.glb    (grounded, non-gratuitous deceased resident in 1990s coat with dropped clipboard & overturned stool for Night 4 Event H)
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


def make_root(name):
    obj = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _link_obj(obj, parent):
    bpy.context.scene.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    return obj


def make_mat(name, color, metallic=0.0, roughness=0.68):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is None:
        bsdf = mat.node_tree.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
    bsdf.inputs["Metallic"].default_value = float(metallic)
    bsdf.inputs["Roughness"].default_value = float(roughness)
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
        export_apply=True,
    )
    print(f"EXPORTED_P4_GLB: {filename} ({os.path.getsize(out_path)} bytes)")


# 1. vm_empty_hands.glb — Resting security guard forearms & hands in dark jacket sleeves
def build_vm_empty_hands():
    clear_scene()
    root = make_root("VM_EmptyHands")
    m_sleeve = make_mat("GuardJacketSleeve", (0.11, 0.13, 0.16), roughness=0.84)
    m_cuff = make_mat("JacketRibCuff", (0.08, 0.09, 0.11), roughness=0.88)
    m_skin = make_mat("GuardHandSkin", (0.64, 0.50, 0.42), roughness=0.72)
    m_glove = make_mat("FingerlessKnitGlove", (0.14, 0.14, 0.15), roughness=0.86)

    for side, sx in [("L", -1.0), ("R", 1.0)]:
        bx = sx * 0.16
        # Forearm sleeve extending forward (+Y in Blender -> -Z in Godot)
        bm_cyl(
            root, f"Sleeve_{side}", 0.044, 0.052, 0.26, m_sleeve, segs=14,
            loc=(bx + sx * 0.03, -0.14, -0.04),
            rot=(math.radians(78), 0, math.radians(-sx * 10))
        )
        bm_cyl(
            root, f"Cuff_{side}", 0.036, 0.040, 0.05, m_cuff, segs=12,
            loc=(bx + sx * 0.01, -0.02, -0.015),
            rot=(math.radians(82), 0, math.radians(-sx * 8))
        )
        # Knit fingerless glove over palm
        bm_box(
            root, f"PalmGlove_{side}", (0.072, 0.082, 0.030), m_glove,
            loc=(bx, 0.035, 0.0),
            rot=(math.radians(8), math.radians(sx * 14), math.radians(-sx * 6)),
            bevel=0.008
        )
        # Relaxed slightly curled fingers
        for i in range(4):
            fx = bx + (i - 1.5) * 0.016
            bm_box(
                root, f"FingerProx_{side}_{i}", (0.013, 0.034, 0.014), m_glove,
                loc=(fx, 0.082, -0.003),
                rot=(math.radians(-18), 0, 0),
                bevel=0.003
            )
            bm_box(
                root, f"FingerTip_{side}_{i}", (0.012, 0.026, 0.013), m_skin,
                loc=(fx, 0.106, -0.014),
                rot=(math.radians(-38), 0, 0),
                bevel=0.003
            )
        # Thumb
        tx = bx - sx * 0.038
        bm_box(
            root, f"Thumb_{side}", (0.016, 0.044, 0.016), m_skin,
            loc=(tx, 0.056, 0.008),
            rot=(math.radians(-12), 0, math.radians(sx * 26)),
            bevel=0.004
        )
    export_glb(root, "vm_empty_hands.glb")


# 2. fp_guard_body.glb — Lower torso, security jacket, utility belt, legs, and boots (origin at ground Z=0)
def build_fp_guard_body():
    clear_scene()
    root = make_root("FP_GuardBody")
    m_jacket = make_mat("SecurityJacket96", (0.11, 0.13, 0.16), roughness=0.82)
    m_trouser = make_mat("GuardTrousers", (0.14, 0.15, 0.17), roughness=0.86)
    m_belt = make_mat("UtilityBeltLeather", (0.07, 0.07, 0.08), roughness=0.58)
    m_brass = make_mat("BeltBuckleMetal", (0.58, 0.54, 0.44), metallic=0.82, roughness=0.36)
    m_boot = make_mat("HeavyGuardBoot", (0.06, 0.06, 0.07), roughness=0.52)

    # Torso & jacket lower hem (Z = 0.86..1.34m so looking down shows chest/stomach/belt without camera clipping at 1.66m)
    bm_box(root, "TorsoJacket", (0.40, 0.25, 0.48), m_jacket, loc=(0.0, 0.0, 1.12), bevel=0.03)
    bm_box(root, "JacketZipperFlap", (0.05, 0.265, 0.46), m_belt, loc=(0.0, 0.01, 1.12), bevel=0.006)
    bm_box(root, "UtilityBelt", (0.42, 0.27, 0.07), m_belt, loc=(0.0, 0.0, 0.89), bevel=0.01)
    bm_box(root, "BeltBuckle", (0.06, 0.02, 0.055), m_brass, loc=(0.0, 0.14, 0.89), bevel=0.004)
    bm_box(root, "BeltPouchL", (0.07, 0.06, 0.10), m_belt, loc=(-0.21, 0.04, 0.89), bevel=0.008)
    bm_box(root, "BeltHolsterR", (0.07, 0.08, 0.12), m_belt, loc=(0.21, 0.04, 0.88), bevel=0.008)
    bm_box(root, "Pelvis", (0.36, 0.23, 0.16), m_trouser, loc=(0.0, 0.0, 0.79), bevel=0.02)

    for side, sx in [("L", -0.11), ("R", 0.11)]:
        bm_cyl(root, f"Thigh_{side}", 0.088, 0.074, 0.40, m_trouser, segs=12, loc=(sx, 0.0, 0.56))
        bm_cyl(root, f"Shin_{side}", 0.072, 0.058, 0.38, m_trouser, segs=12, loc=(sx, 0.0, 0.23))
        bm_box(root, f"BootAnkle_{side}", (0.11, 0.13, 0.13), m_boot, loc=(sx, 0.01, 0.10), bevel=0.012)
        bm_box(root, f"BootFoot_{side}", (0.115, 0.25, 0.085), m_boot, loc=(sx, 0.055, 0.042), bevel=0.015)

    export_glb(root, "fp_guard_body.glb")


# 3. crime_evidence_bag.glb — Abandoned personal belongings (shopping bag, scarf, spilled papers, keyring)
def build_crime_evidence_bag():
    clear_scene()
    root = make_root("CrimeEvidenceBag")
    m_bag = make_mat("CrumpledShoppingBag", (0.58, 0.48, 0.34), roughness=0.88)
    m_scarf = make_mat("WoolScarfBurgundy", (0.42, 0.12, 0.14), roughness=0.92)
    m_paper = make_mat("WetDocumentPage", (0.76, 0.73, 0.65), roughness=0.84)
    m_metal = make_mat("DroppedKeyRing", (0.64, 0.62, 0.54), metallic=0.85, roughness=0.35)

    # Fallen shopping bag on its side
    bm_box(
        root, "BagBody", (0.34, 0.26, 0.18), m_bag,
        loc=(0.0, 0.0, 0.09),
        rot=(math.radians(8), math.radians(-14), math.radians(22)),
        bevel=0.02
    )
    # Dropped wool scarf
    bm_box(
        root, "DroppedScarf", (0.42, 0.14, 0.035), m_scarf,
        loc=(0.24, 0.12, 0.02),
        rot=(0, 0, math.radians(-34)),
        bevel=0.012
    )
    # Spilled papers & keyring
    bm_box(root, "SpilledDoc1", (0.21, 0.29, 0.006), m_paper, loc=(-0.22, 0.18, 0.005), rot=(0, 0, math.radians(18)))
    bm_box(root, "SpilledDoc2", (0.21, 0.29, 0.006), m_paper, loc=(-0.14, 0.26, 0.008), rot=(0, 0, math.radians(-12)))
    bm_cyl(root, "KeyRing", 0.032, 0.032, 0.008, m_metal, segs=14, loc=(0.12, -0.20, 0.008))
    bm_box(root, "KeyBlade1", (0.014, 0.055, 0.005), m_metal, loc=(0.15, -0.22, 0.008), rot=(0, 0, math.radians(35)))
    bm_box(root, "KeyBlade2", (0.014, 0.050, 0.005), m_metal, loc=(0.14, -0.18, 0.008), rot=(0, 0, math.radians(-15)))
    export_glb(root, "crime_evidence_bag.glb")


# 4. crime_victim_body.glb — Grounded, non-gratuitous deceased resident in 1990s coat lying on side near service door
def build_crime_victim_body():
    clear_scene()
    root = make_root("CrimeVictimBody")
    m_coat = make_mat("VictimWinterCoat", (0.16, 0.18, 0.15), roughness=0.88)
    m_pants = make_mat("VictimTrousers", (0.14, 0.15, 0.18), roughness=0.86)
    m_shoe = make_mat("VictimShoe", (0.08, 0.07, 0.06), roughness=0.65)
    m_skin = make_mat("PaleSkin", (0.56, 0.52, 0.48), roughness=0.78)
    m_hair = make_mat("DarkHair", (0.10, 0.09, 0.08), roughness=0.90)
    m_wood = make_mat("OverturnedStoolWood", (0.28, 0.20, 0.13), roughness=0.82)
    m_evidence = make_mat("DarkBloodTrace", (0.22, 0.03, 0.03), roughness=0.32)

    # Person lying motionless on side in winter coat (length ~1.68m along X)
    bm_box(root, "TorsoCoat", (0.56, 0.34, 0.26), m_coat, loc=(0.0, 0.0, 0.14), rot=(math.radians(12), 0, math.radians(8)), bevel=0.04)
    bm_sphere(root, "Head", 0.115, m_skin, scale=(1.05, 0.95, 0.95), loc=(-0.40, 0.05, 0.13))
    bm_sphere(root, "HairCap", 0.118, m_hair, scale=(1.06, 0.96, 0.90), loc=(-0.42, 0.06, 0.15))
    # Arms
    bm_cyl(root, "ArmUpperL", 0.062, 0.054, 0.34, m_coat, segs=10, loc=(-0.18, -0.22, 0.11), rot=(math.radians(84), 0, math.radians(38)))
    bm_cyl(root, "ArmLowerL", 0.052, 0.044, 0.30, m_coat, segs=10, loc=(-0.34, -0.38, 0.07), rot=(math.radians(88), 0, math.radians(72)))
    bm_sphere(root, "HandL", 0.045, m_skin, loc=(-0.48, -0.44, 0.045))
    bm_cyl(root, "ArmR", 0.060, 0.048, 0.52, m_coat, segs=10, loc=(-0.05, 0.22, 0.16), rot=(math.radians(76), 0, math.radians(-28)))
    # Legs slightly bent
    bm_cyl(root, "LegL", 0.082, 0.062, 0.72, m_pants, segs=10, loc=(0.54, -0.08, 0.11), rot=(0, math.radians(88), math.radians(-14)))
    bm_cyl(root, "LegR", 0.082, 0.062, 0.70, m_pants, segs=10, loc=(0.52, 0.12, 0.12), rot=(0, math.radians(86), math.radians(10)))
    bm_box(root, "ShoeL", (0.10, 0.22, 0.09), m_shoe, loc=(0.90, -0.16, 0.08), rot=(0, 0, math.radians(-20)), bevel=0.01)
    bm_box(root, "ShoeR", (0.10, 0.22, 0.09), m_shoe, loc=(0.88, 0.18, 0.08), rot=(0, 0, math.radians(12)), bevel=0.01)
    # Restrained dark blood stain on concrete under head/shoulder + overturned wooden stool
    bm_cyl(root, "BloodPool", 0.28, 0.28, 0.005, m_evidence, segs=16, loc=(-0.36, -0.06, 0.003))
    bm_box(root, "OverturnedStoolSeat", (0.34, 0.34, 0.04), m_wood, loc=(0.35, -0.52, 0.18), rot=(math.radians(74), math.radians(18), math.radians(32)), bevel=0.006)
    for lx, ly in [(-0.12, -0.12), (0.12, -0.12), (-0.12, 0.12), (0.12, 0.12)]:
        bm_cyl(root, f"StoolLeg_{lx}_{ly}", 0.018, 0.016, 0.42, m_wood, segs=8, loc=(0.35 + lx, -0.72, 0.14 + ly * 0.5), rot=(math.radians(74), 0, math.radians(32)))

    export_glb(root, "crime_victim_body.glb")


def main():
    build_vm_empty_hands()
    build_fp_guard_body()
    build_crime_evidence_bag()
    build_crime_victim_body()
    print("ALL_4_PROMPT04_GLBS_COMPLETE")


if __name__ == "__main__":
    main()
