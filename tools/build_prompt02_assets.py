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


def make_mat(name, color, metallic=0.0, roughness=0.65, emission=(0.0, 0.0, 0.0), emit_str=0.0):
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


def bm_sphere(parent, name, rad, mat, scale=(1, 1, 1), loc=(0, 0, 0), rot=(0, 0, 0), sub=2):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=rad)
    bmesh.ops.transform(bm, matrix=Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0)), verts=bm.verts)
    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=True)


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


def add_gloved_hand(parent, glove_mat, sleeve_mat, grip_offset=(0, 0, 0), open_palm=False):
    gx, gy, gz = grip_offset
    bm_cyl(parent, "CoatSleeve", 0.044, 0.050, 0.24, sleeve_mat, segs=14,
           loc=(gx + 0.01, gy - 0.16, gz - 0.025), rot=(math.radians(82), 0, math.radians(-6)))
    bm_cyl(parent, "GloveWrist", 0.035, 0.040, 0.07, glove_mat, segs=12,
           loc=(gx + 0.004, gy - 0.055, gz - 0.012), rot=(math.radians(84), 0, 0))
    bm_box(parent, "Palm", (0.066, 0.076, 0.028), glove_mat, loc=(gx, gy, gz), bevel=0.008)
    for i in range(4):
        fx = gx - 0.022 + i * 0.015
        if open_palm:
            bm_box(parent, f"Finger_{i}", (0.012, 0.042, 0.014), glove_mat,
                   loc=(fx, gy + 0.042, gz + 0.004), rot=(math.radians(14), 0, 0), bevel=0.003)
        else:
            bm_box(parent, f"FingerProx_{i}", (0.013, 0.034, 0.016), glove_mat,
                   loc=(fx, gy + 0.034, gz + 0.012), rot=(math.radians(-42), 0, 0), bevel=0.004)
            bm_box(parent, f"FingerDist_{i}", (0.012, 0.028, 0.014), glove_mat,
                   loc=(fx, gy + 0.030, gz + 0.032), rot=(math.radians(-102), 0, 0), bevel=0.003)
    bm_box(parent, "Thumb", (0.016, 0.042, 0.016), glove_mat,
           loc=(gx - 0.032, gy + 0.022, gz + 0.018), rot=(math.radians(-22), 0, math.radians(-24)), bevel=0.004)


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
    print(f"EXPORTED_P2_GLB: {filename} ({os.path.getsize(out_path)} bytes)")


# 1. vm_headphones.glb — 1990s Steel & Leather Studio Headphones
def build_vm_headphones():
    clear_scene()
    root = make_root("VM_Headphones")
    m_leather = make_mat("PadLeather", (0.08, 0.08, 0.09), roughness=0.72)
    m_steel = make_mat("BandSteel", (0.64, 0.66, 0.68), metallic=0.88, roughness=0.28)
    m_cup = make_mat("CupPlastic", (0.14, 0.14, 0.16), metallic=0.15, roughness=0.48)
    m_foam = make_mat("OrangeFoamAccent", (0.76, 0.34, 0.10), roughness=0.90)
    # Arch headband across X
    for seg in range(11):
        frac = (seg / 10.0) - 0.5
        ang = frac * math.pi * 0.92
        bx = math.sin(ang) * 0.115
        bz = math.cos(ang) * 0.115
        bm_box(root, f"BandSeg_{seg}", (0.026, 0.026, 0.014), m_steel, loc=(bx, 0, bz), rot=(0, ang, 0))
    bm_box(root, "CrownPad", (0.10, 0.032, 0.022), m_leather, loc=(0, 0, 0.120), bevel=0.006)
    # Left & Right earcups facing inward
    for sx, tag in [(-0.118, "L"), (0.118, "R")]:
        bm_cyl(root, f"CupShell_{tag}", 0.048, 0.044, 0.038, m_cup, segs=18, loc=(sx, 0, -0.01), rot=(0, math.radians(90), 0))
        bm_torus(root, f"CupPad_{tag}", 0.036, 0.014, m_leather, maj_s=18, min_s=8, loc=(sx * 0.85, 0, -0.01), rot=(0, math.radians(90), 0))
        bm_cyl(root, f"Badge_{tag}", 0.018, 0.018, 0.006, m_foam, segs=14, loc=(sx * 1.15, 0, -0.01), rot=(0, math.radians(90), 0))
    export_glb(root, "vm_headphones.glb")


# 2. vm_keys.glb — Heavy Brass 1990s Guard Keyring
def build_vm_keys():
    clear_scene()
    root = make_root("VM_Keys")
    m_brass = make_mat("GuardBrass", (0.76, 0.60, 0.24), metallic=0.88, roughness=0.30)
    m_steel = make_mat("KeySteel", (0.64, 0.66, 0.68), metallic=0.90, roughness=0.32)
    m_glove = make_mat("WoolGlove", (0.11, 0.12, 0.13), roughness=0.92)
    m_sleeve = make_mat("GuardCoat", (0.14, 0.17, 0.20), roughness=0.88)
    add_gloved_hand(root, m_glove, m_sleeve, grip_offset=(0, -0.01, -0.02))
    bm_torus(root, "KeyRing", 0.022, 0.003, m_steel, maj_s=16, min_s=6, loc=(0.0, 0.055, 0.018), rot=(math.radians(75), 0, 0))
    for k in range(4):
        ang = -0.35 + k * 0.24
        mat_k = m_brass if k in (0, 2) else m_steel
        kx = math.sin(ang) * 0.025
        ky = 0.095
        kz = 0.010 - abs(ang) * 0.018
        bm_cyl(root, f"KeyBow_{k}", 0.014, 0.014, 0.004, mat_k, segs=12, loc=(kx, 0.068, kz), rot=(0, ang, 0))
        bm_box(root, f"KeyBlade_{k}", (0.006, 0.055, 0.003), mat_k, loc=(kx, ky, kz), rot=(0, 0, ang))
        bm_box(root, f"KeyTeeth_{k}", (0.007, 0.018, 0.004), mat_k, loc=(kx + 0.005, ky + 0.018, kz), rot=(0, 0, ang))
    export_glb(root, "vm_keys.glb")


# 3. vm_radio.glb — 1990s VHF Analog Walkie-Talkie in Gloved Hand
def build_vm_radio():
    clear_scene()
    root = make_root("VM_Radio")
    m_body = make_mat("RadioPolymer", (0.08, 0.09, 0.10), metallic=0.1, roughness=0.62)
    m_grille = make_mat("SpeakerGrill", (0.04, 0.04, 0.05), roughness=0.8)
    m_led = make_mat("TxLED", (0.95, 0.22, 0.14), emission=(0.95, 0.22, 0.14), emit_str=3.0)
    m_steel = make_mat("KnobChrome", (0.65, 0.67, 0.70), metallic=0.85, roughness=0.3)
    m_glove = make_mat("WoolGlove", (0.11, 0.12, 0.13), roughness=0.92)
    m_sleeve = make_mat("GuardCoat", (0.14, 0.17, 0.20), roughness=0.88)
    add_gloved_hand(root, m_glove, m_sleeve, grip_offset=(0, -0.01, -0.02))
    bm_box(root, "Chassis", (0.062, 0.042, 0.165), m_body, loc=(0, 0.02, 0.035), bevel=0.005)
    bm_box(root, "SpeakerPlate", (0.048, 0.006, 0.065), m_grille, loc=(0, -0.002, 0.062))
    bm_cyl(root, "AntennaBase", 0.007, 0.005, 0.03, m_body, segs=10, loc=(0.02, 0.02, 0.132))
    bm_cyl(root, "AntennaWhip", 0.0035, 0.002, 0.155, m_body, segs=8, loc=(0.02, 0.02, 0.215))
    bm_cyl(root, "ChKnob", 0.009, 0.009, 0.02, m_steel, segs=12, loc=(-0.016, 0.02, 0.125))
    bm_sphere(root, "StatusLED", 0.004, m_led, loc=(-0.018, -0.002, 0.105), sub=1)
    export_glb(root, "vm_radio.glb")


# 4. vm_watch.glb — Left Gloved Wrist & Vintage Steel Wristwatch
def build_vm_watch():
    clear_scene()
    root = make_root("VM_Watch")
    m_coat = make_mat("GuardCoat", (0.14, 0.17, 0.20), roughness=0.88)
    m_glove = make_mat("WoolGlove", (0.11, 0.12, 0.13), roughness=0.92)
    m_steel = make_mat("PrimCase", (0.72, 0.74, 0.76), metallic=0.88, roughness=0.28)
    m_strap = make_mat("LeatherStrap", (0.16, 0.10, 0.07), roughness=0.75)
    m_dial = make_mat("GlowDial", (0.78, 0.88, 0.72), emission=(0.45, 0.75, 0.42), emit_str=1.2)
    m_hand = make_mat("DarkHand", (0.06, 0.06, 0.08), roughness=0.5)
    bm_cyl(root, "ForearmSleeve", 0.044, 0.048, 0.22, m_coat, segs=14, loc=(-0.08, 0.0, 0.0), rot=(0, math.radians(90), 0))
    bm_cyl(root, "WristGlove", 0.036, 0.038, 0.10, m_glove, segs=14, loc=(0.06, 0.0, 0.0), rot=(0, math.radians(90), 0))
    bm_torus(root, "WatchStrap", 0.041, 0.006, m_strap, maj_s=18, min_s=6, loc=(0.03, 0.0, 0.0), rot=(0, math.radians(90), 0))
    bm_cyl(root, "WatchBezel", 0.022, 0.022, 0.010, m_steel, segs=20, loc=(0.03, 0.0, 0.042))
    bm_cyl(root, "WatchFace", 0.018, 0.018, 0.011, m_dial, segs=20, loc=(0.03, 0.0, 0.043))
    bm_box(root, "HourHand", (0.012, 0.0025, 0.002), m_hand, loc=(0.035, 0.002, 0.049), rot=(0, 0, 0.5))
    bm_box(root, "MinHand", (0.015, 0.002, 0.002), m_hand, loc=(0.026, -0.004, 0.050), rot=(0, 0, -1.1))
    export_glb(root, "vm_watch.glb")


# 5. vm_pencil_hand.glb — Right Gloved Hand Holding Yellow Pencil for Notebook Writing
def build_vm_pencil_hand():
    clear_scene()
    root = make_root("VM_PencilHand")
    m_glove = make_mat("WoolGlove", (0.11, 0.12, 0.13), roughness=0.92)
    m_sleeve = make_mat("GuardCoat", (0.14, 0.17, 0.20), roughness=0.88)
    m_pencil = make_mat("YellowPencil", (0.86, 0.64, 0.14), roughness=0.52)
    m_wood = make_mat("PencilCone", (0.72, 0.56, 0.36), roughness=0.72)
    m_lead = make_mat("Graphite", (0.10, 0.10, 0.12), roughness=0.45)
    add_gloved_hand(root, m_glove, m_sleeve, grip_offset=(0.02, -0.02, 0.0))
    bm_cyl(root, "PencilBody", 0.0045, 0.0045, 0.15, m_pencil, segs=6, loc=(0, 0.04, 0.015), rot=(math.radians(65), 0, math.radians(15)), smooth=False)
    bm_cyl(root, "PencilTipWood", 0.0045, 0.001, 0.022, m_wood, segs=6, loc=(-0.02, 0.11, -0.018), rot=(math.radians(-115), 0, math.radians(15)))
    bm_cyl(root, "PencilLead", 0.0012, 0.0002, 0.008, m_lead, segs=6, loc=(-0.024, 0.123, -0.024), rot=(math.radians(-115), 0, math.radians(15)))
    export_glb(root, "vm_pencil_hand.glb")


# 6. door_hinged_panel.glb — Hinge at X=0.0, Door extends to X=+1.05, Height Z=2.15
def build_door_hinged_panel():
    clear_scene()
    root = make_root("DoorHingedPanel")
    m_wood = make_mat("WeatheredDoorWood", (0.30, 0.21, 0.14), roughness=0.78)
    m_inset = make_mat("DoorRecess", (0.24, 0.16, 0.11), roughness=0.82)
    m_brass = make_mat("DoorBrass", (0.68, 0.54, 0.22), metallic=0.86, roughness=0.32)
    bm_box(root, "DoorLeaf", (1.02, 0.07, 2.12), m_wood, loc=(0.51, 0, 1.06), bevel=0.006)
    bm_box(root, "UpperPanel", (0.72, 0.085, 0.85), m_inset, loc=(0.51, 0, 1.48))
    bm_box(root, "LowerPanel", (0.72, 0.085, 0.62), m_inset, loc=(0.51, 0, 0.52))
    for side_y in (-0.055, 0.055):
        bm_box(root, f"Escutcheon_{side_y}", (0.045, 0.015, 0.16), m_brass, loc=(0.90, side_y, 1.02))
        bm_box(root, f"LeverHandle_{side_y}", (0.12, 0.022, 0.024), m_brass, loc=(0.86, side_y * 1.4, 1.05), bevel=0.004)
    export_glb(root, "door_hinged_panel.glb")


# 7. utility_pole_90s.glb
def build_utility_pole():
    clear_scene()
    root = make_root("UtilityPole90s")
    m_conc = make_mat("PoleConcrete", (0.35, 0.35, 0.34), roughness=0.92)
    m_iron = make_mat("ArmIron", (0.18, 0.16, 0.15), metallic=0.72, roughness=0.58)
    m_glass = make_mat("Porcelain", (0.76, 0.78, 0.74), roughness=0.25)
    bm_cyl(root, "MainPole", 0.16, 0.11, 7.6, m_conc, segs=10, loc=(0, 0, 3.8))
    bm_box(root, "CrossArm", (1.75, 0.10, 0.10), m_iron, loc=(0, 0, 7.15))
    for sx in (-0.72, -0.24, 0.24, 0.72):
        bm_cyl(root, f"Insulator_{sx}", 0.04, 0.03, 0.14, m_glass, segs=10, loc=(sx, 0, 7.26))
    bm_box(root, "JunctionBox", (0.28, 0.20, 0.42), m_iron, loc=(0, -0.18, 1.85))
    export_glb(root, "utility_pole_90s.glb")


# 8. manhole_drain.glb
def build_manhole_drain():
    clear_scene()
    root = make_root("ManholeDrain")
    m_iron = make_mat("CastIronCover", (0.14, 0.14, 0.15), metallic=0.78, roughness=0.55)
    m_rim = make_mat("AsphaltRim", (0.22, 0.22, 0.22), roughness=0.88)
    bm_cyl(root, "OuterRim", 0.44, 0.44, 0.04, m_rim, segs=20, loc=(0, 0, 0.02))
    bm_cyl(root, "CoverLid", 0.38, 0.38, 0.05, m_iron, segs=20, loc=(0, 0, 0.03))
    bm_torus(root, "TreadRing", 0.24, 0.015, m_iron, maj_s=18, min_s=6, loc=(0, 0, 0.055))
    export_glb(root, "manhole_drain.glb")


# 9. shrub_bush_90s.glb
def build_shrub_bush():
    clear_scene()
    root = make_root("ShrubBush90s")
    m_foliage = make_mat("AutumnShrub", (0.11, 0.15, 0.08), roughness=0.92)
    m_twig = make_mat("TwigBark", (0.18, 0.14, 0.10), roughness=0.95)
    bm_cyl(root, "Stem", 0.10, 0.06, 0.45, m_twig, segs=6, loc=(0, 0, 0.22))
    for loc, sc in [
        ((0.0, 0.0, 0.65), (1.1, 1.0, 0.85)),
        ((-0.42, 0.22, 0.52), (0.85, 0.85, 0.72)),
        ((0.40, -0.25, 0.50), (0.80, 0.88, 0.70)),
        ((0.18, 0.38, 0.48), (0.72, 0.78, 0.68)),
    ]:
        bm_sphere(root, "Cluster", 0.52, m_foliage, scale=sc, loc=loc, sub=1)
    export_glb(root, "shrub_bush_90s.glb")


def main():
    build_vm_headphones()
    build_vm_keys()
    build_vm_radio()
    build_vm_watch()
    build_vm_pencil_hand()
    build_door_hinged_panel()
    build_utility_pole()
    build_manhole_drain()
    build_shrub_bush()
    print("ALL_9_PROMPT02_GLBS_COMPLETE")


if __name__ == "__main__":
    main()
