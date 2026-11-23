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
    mat_scale = Matrix.Diagonal((size[0], size[1], size[2], 1.0))
    bmesh.ops.transform(bm, matrix=mat_scale, verts=bm.verts)
    if bevel > 0.0 and len(bm.edges) > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=2, affect="EDGES")
    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=(bevel > 0.0))


def bm_cyl(parent, name, r1, r2, h, mat, segs=16, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True):
    bm = bmesh.new()
    bmesh.ops.create_cone(
        bm,
        cap_ends=True,
        cap_tris=False,
        segments=segs,
        radius1=r1,
        radius2=r2,
        depth=h,
    )
    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=smooth)


def bm_sphere(parent, name, rad, mat, scale=(1, 1, 1), loc=(0, 0, 0), rot=(0, 0, 0), sub=2):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=rad)
    mat_scale = Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0))
    bmesh.ops.transform(bm, matrix=mat_scale, verts=bm.verts)
    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=True)


def bm_torus(parent, name, maj, mn, mat, maj_s=24, min_s=10, loc=(0, 0, 0), rot=(0, 0, 0)):
    bm = bmesh.new()
    rings = []
    for i in range(maj_s):
        theta = 2.0 * math.pi * i / maj_s
        cx = math.cos(theta) * maj
        cy = math.sin(theta) * maj
        ring = []
        for j in range(min_s):
            phi = 2.0 * math.pi * j / min_s
            r = maj + math.cos(phi) * mn
            vx = math.cos(theta) * r
            vy = math.sin(theta) * r
            vz = math.sin(phi) * mn
            ring.append(bm.verts.new((vx, vy, vz)))
        rings.append(ring)
    for i in range(maj_s):
        r0 = rings[i]
        r1 = rings[(i + 1) % maj_s]
        for j in range(min_s):
            j1 = (j + 1) % min_s
            bm.faces.new((r0[j], r1[j], r1[j1], r0[j1]))
    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=True)


def bm_tube(parent, name, pts, radii, mat, segs=10, loc=(0, 0, 0), rot=(0, 0, 0)):
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
            offset = (side * math.cos(ang) + binorm * math.sin(ang)) * rad
            ring.append(bm.verts.new(p + offset))
        rings.append(ring)
    for i in range(len(rings) - 1):
        r0 = rings[i]
        r1 = rings[i + 1]
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
    print(f"EXPORTED_GLB: {out_path} ({os.path.getsize(out_path)} bytes)")


def add_gloved_hand(parent, glove_mat, sleeve_mat, grip_offset=(0, 0, 0), open_palm=False):
    gx, gy, gz = grip_offset
    # Coat sleeve cuff coming from behind (+Z in Godot -> -Y in Blender)
    bm_cyl(parent, "CoatSleeve", 0.046, 0.052, 0.24, sleeve_mat, segs=14,
           loc=(gx + 0.01, gy - 0.17, gz - 0.025), rot=(math.radians(82), 0, math.radians(-8)))
    # Knitted glove wrist
    bm_cyl(parent, "GloveWrist", 0.036, 0.041, 0.07, glove_mat, segs=12,
           loc=(gx + 0.004, gy - 0.055, gz - 0.012), rot=(math.radians(84), 0, 0))
    # Palm
    bm_box(parent, "Palm", (0.068, 0.078, 0.030), glove_mat,
           loc=(gx, gy, gz), rot=(0, 0, 0), bevel=0.008)
    # 4 Fingers curled or supporting
    for i in range(4):
        fx = gx - 0.022 + i * 0.015
        if open_palm:
            bm_box(parent, f"Finger_{i}", (0.012, 0.046, 0.014), glove_mat,
                   loc=(fx, gy + 0.045, gz + 0.004), rot=(math.radians(15), 0, 0), bevel=0.003)
        else:
            bm_box(parent, f"FingerProx_{i}", (0.013, 0.036, 0.016), glove_mat,
                   loc=(fx, gy + 0.036, gz + 0.012), rot=(math.radians(-42), 0, 0), bevel=0.004)
            bm_box(parent, f"FingerDist_{i}", (0.012, 0.030, 0.014), glove_mat,
                   loc=(fx, gy + 0.032, gz + 0.034), rot=(math.radians(-102), 0, 0), bevel=0.003)
    # Thumb
    bm_box(parent, "Thumb", (0.016, 0.044, 0.016), glove_mat,
           loc=(gx - 0.034, gy + 0.022, gz + 0.018), rot=(math.radians(-22), 0, math.radians(-24)), bevel=0.004)


# 1. vm_flashlight.glb
def build_vm_flashlight():
    clear_scene()
    root = make_root("VM_Flashlight")
    m_metal = make_mat("TorchSteel", (0.14, 0.15, 0.17), metallic=0.82, roughness=0.38)
    m_rubber = make_mat("TorchGrip", (0.05, 0.05, 0.06), metallic=0.05, roughness=0.82)
    m_brass = make_mat("TorchBrass", (0.64, 0.48, 0.22), metallic=0.88, roughness=0.32)
    m_switch = make_mat("RedSwitch", (0.72, 0.10, 0.08), metallic=0.1, roughness=0.45)
    m_lens = make_mat("BulbLens", (0.96, 0.90, 0.68), metallic=0.05, roughness=0.12,
                      emission=(1.0, 0.88, 0.62), emit_str=2.6)
    m_glove = make_mat("WoolGlove", (0.11, 0.12, 0.13), metallic=0.0, roughness=0.92)
    m_sleeve = make_mat("GuardCoat", (0.14, 0.17, 0.20), metallic=0.0, roughness=0.88)

    add_gloved_hand(root, m_glove, m_sleeve, grip_offset=(0.0, -0.01, -0.025))
    # Barrel pointing forward (+Y)
    bm_cyl(root, "MainBarrel", 0.024, 0.024, 0.22, m_metal, segs=18,
           loc=(0, 0.02, 0.01), rot=(math.radians(90), 0, 0))
    # Knurled rubber grip collar
    for k in range(5):
        bm_cyl(root, f"GripRing_{k}", 0.0265, 0.0265, 0.012, m_rubber, segs=18,
               loc=(0, -0.03 + k * 0.022, 0.01), rot=(math.radians(90), 0, 0))
    # Flared reflector head
    bm_cyl(root, "HeadCone", 0.025, 0.044, 0.055, m_metal, segs=24,
           loc=(0, 0.155, 0.01), rot=(math.radians(90), 0, 0))
    bm_cyl(root, "BezelRing", 0.046, 0.045, 0.022, m_brass, segs=24,
           loc=(0, 0.19, 0.01), rot=(math.radians(90), 0, 0))
    # Tail cap & brass lanyard ring
    bm_cyl(root, "TailCap", 0.027, 0.025, 0.024, m_brass, segs=18,
           loc=(0, -0.098, 0.01), rot=(math.radians(90), 0, 0))
    bm_torus(root, "LanyardLoop", 0.011, 0.0025, m_metal, maj_s=14, min_s=6,
             loc=(0, -0.114, 0.01), rot=(0, math.radians(90), 0))
    # Slide switch
    bm_box(root, "SlideSwitch", (0.014, 0.034, 0.012), m_switch,
           loc=(0, 0.085, 0.035), rot=(0, 0, 0), bevel=0.002)
    # Glowing reflector & bulb lens
    bm_cyl(root, "LensGlass", 0.039, 0.036, 0.008, m_lens, segs=24,
           loc=(0, 0.198, 0.01), rot=(math.radians(90), 0, 0))
    export_glb(root, "vm_flashlight.glb")


# 2. vm_taser.glb
def build_vm_taser():
    clear_scene()
    root = make_root("VM_Taser")
    m_body = make_mat("TaserPolymer", (0.09, 0.10, 0.11), metallic=0.12, roughness=0.58)
    m_hazard = make_mat("HazardYellow", (0.88, 0.68, 0.08), metallic=0.05, roughness=0.48)
    m_steel = make_mat("ProngSteel", (0.76, 0.78, 0.82), metallic=0.92, roughness=0.22)
    m_led = make_mat("ChargeLED", (0.20, 0.85, 1.0), metallic=0.0, roughness=0.2,
                     emission=(0.25, 0.85, 1.0), emit_str=3.5)
    m_arc_tip = make_mat("ArcTip", (0.55, 0.88, 1.0), metallic=0.0, roughness=0.1,
                         emission=(0.45, 0.88, 1.0), emit_str=4.0)
    m_glove = make_mat("WoolGlove", (0.11, 0.12, 0.13), metallic=0.0, roughness=0.92)
    m_sleeve = make_mat("GuardCoat", (0.14, 0.17, 0.20), metallic=0.0, roughness=0.88)

    add_gloved_hand(root, m_glove, m_sleeve, grip_offset=(0.0, -0.015, -0.025))
    # Main stun baton handle & capacitor body
    bm_box(root, "GripHandle", (0.042, 0.135, 0.036), m_body,
           loc=(0, 0.02, 0.008), rot=(0, 0, 0), bevel=0.005)
    bm_box(root, "CapacitorHousing", (0.054, 0.125, 0.044), m_body,
           loc=(0, 0.145, 0.012), rot=(0, 0, 0), bevel=0.006)
    # Yellow 90s Czechoslovakia industrial hazard panels
    bm_box(root, "HazardBandL", (0.057, 0.052, 0.022), m_hazard,
           loc=(0, 0.135, 0.015), rot=(0, 0, 0), bevel=0.002)
    bm_box(root, "HazardBandRear", (0.044, 0.018, 0.038), m_hazard,
           loc=(0, -0.035, 0.008), rot=(0, 0, 0), bevel=0.002)
    # Charge indicator LED
    bm_cyl(root, "StatusLED", 0.005, 0.005, 0.008, m_led, segs=12,
           loc=(0, 0.095, 0.036), rot=(0, 0, 0))
    # Trigger button
    bm_box(root, "TriggerBtn", (0.016, 0.024, 0.014), m_hazard,
           loc=(0, 0.068, 0.030), rot=(0, 0, 0), bevel=0.002)
    # Twin high-voltage electrodes + guard prongs extending forward (+Y)
    for sx, tag in [(-0.018, "L"), (0.018, "R")]:
        bm_cyl(root, f"ProngBase_{tag}", 0.0065, 0.0055, 0.055, m_steel, segs=12,
               loc=(sx, 0.232, 0.014), rot=(math.radians(90), 0, 0))
        bm_box(root, f"ProngHook_{tag}", (0.005, 0.022, 0.012), m_steel,
               loc=(sx, 0.264, 0.014), rot=(0, 0, math.radians(-12 if sx < 0 else 12)), bevel=0.001)
    # Central arc spark node
    bm_sphere(root, "ArcBridge", 0.006, m_arc_tip, scale=(2.2, 0.6, 0.6), loc=(0, 0.262, 0.014), sub=1)
    export_glb(root, "vm_taser.glb")


# 3. vm_notebook.glb
def build_vm_notebook():
    clear_scene()
    root = make_root("VM_Notebook")
    m_cover = make_mat("LeatherCover", (0.20, 0.13, 0.09), metallic=0.0, roughness=0.78)
    m_paper = make_mat("AgedPaper", (0.86, 0.82, 0.70), metallic=0.0, roughness=0.88)
    m_line = make_mat("InkLine", (0.24, 0.29, 0.38), metallic=0.0, roughness=0.7)
    m_wire = make_mat("SpiralWire", (0.62, 0.64, 0.66), metallic=0.85, roughness=0.35)
    m_pencil = make_mat("YellowPencil", (0.84, 0.62, 0.14), metallic=0.0, roughness=0.55)
    m_wood = make_mat("PencilWood", (0.72, 0.56, 0.38), metallic=0.0, roughness=0.75)
    m_lead = make_mat("GraphiteLead", (0.12, 0.12, 0.14), metallic=0.3, roughness=0.45)
    m_glove = make_mat("WoolGlove", (0.11, 0.12, 0.13), metallic=0.0, roughness=0.92)
    m_sleeve = make_mat("GuardCoat", (0.14, 0.17, 0.20), metallic=0.0, roughness=0.88)

    add_gloved_hand(root, m_glove, m_sleeve, grip_offset=(-0.03, -0.02, -0.028), open_palm=True)
    # Tilted open notebook facing camera (-Y / up toward viewer)
    nb_pivot = make_root("NotebookBook")
    nb_pivot.parent = root
    nb_pivot.location = Vector((0.02, 0.06, 0.015))
    nb_pivot.rotation_euler = Euler((math.radians(-48), 0, math.radians(-10)), "XYZ")

    # Left & right leather covers slightly open in a V
    bm_box(nb_pivot, "CoverL", (0.135, 0.185, 0.006), m_cover,
           loc=(-0.070, 0, -0.006), rot=(0, math.radians(-10), 0), bevel=0.001)
    bm_box(nb_pivot, "CoverR", (0.135, 0.185, 0.006), m_cover,
           loc=(0.070, 0, -0.006), rot=(0, math.radians(10), 0), bevel=0.001)
    bm_box(nb_pivot, "Spine", (0.018, 0.186, 0.010), m_cover, loc=(0, 0, -0.012))
    # Page blocks
    bm_box(nb_pivot, "PagesL", (0.125, 0.174, 0.008), m_paper,
           loc=(-0.066, 0, 0.001), rot=(0, math.radians(-10), 0))
    bm_box(nb_pivot, "PagesR", (0.125, 0.174, 0.008), m_paper,
           loc=(0.066, 0, 0.001), rot=(0, math.radians(10), 0))
    # Ink rule lines across right page
    for ln in range(6):
        bm_box(nb_pivot, f"RuleLine_{ln}", (0.095, 0.0025, 0.001), m_line,
               loc=(0.066, 0.058 - ln * 0.022, 0.006), rot=(0, math.radians(10), 0))
    # Spiral rings down center spine
    for s in range(7):
        bm_torus(nb_pivot, f"Spiral_{s}", 0.008, 0.0016, m_wire, maj_s=12, min_s=6,
                 loc=(0, -0.066 + s * 0.022, 0.004), rot=(0, math.radians(90), 0))
    # Clipped guard pencil along right margin
    bm_cyl(nb_pivot, "PencilShaft", 0.0045, 0.0045, 0.135, m_pencil, segs=6,
           loc=(0.118, -0.005, 0.016), rot=(math.radians(90), 0, math.radians(5)), smooth=False)
    bm_cyl(nb_pivot, "PencilCone", 0.0045, 0.0012, 0.018, m_wood, segs=6,
           loc=(0.111, 0.071, 0.016), rot=(math.radians(-90), 0, math.radians(5)))
    bm_cyl(nb_pivot, "PencilTip", 0.0014, 0.0002, 0.006, m_lead, segs=6,
           loc=(0.110, 0.083, 0.016), rot=(math.radians(-90), 0, math.radians(5)))
    export_glb(root, "vm_notebook.glb")


# 4. battery_pack.glb
def build_battery_pack():
    clear_scene()
    root = make_root("BatteryPack_3R12")
    m_yellow = make_mat("RetroBatteryYellow", (0.86, 0.64, 0.10), metallic=0.05, roughness=0.45,
                        emission=(0.35, 0.25, 0.02), emit_str=0.22)
    m_red = make_mat("RetroBatteryRed", (0.68, 0.12, 0.09), metallic=0.05, roughness=0.48)
    m_black = make_mat("TarPitchTop", (0.06, 0.06, 0.07), metallic=0.05, roughness=0.68)
    m_brass = make_mat("BrassTerminal", (0.82, 0.68, 0.26), metallic=0.90, roughness=0.25)

    # Classic Czechoslovak 4.5V flat lantern battery brick
    bm_box(root, "CaseMain", (0.15, 0.085, 0.20), m_yellow, loc=(0, 0, 0.10), bevel=0.005)
    bm_box(root, "LabelBand", (0.153, 0.088, 0.072), m_red, loc=(0, 0, 0.11), bevel=0.002)
    bm_box(root, "PitchSeal", (0.142, 0.078, 0.016), m_black, loc=(0, 0, 0.204))
    # Two springy brass terminal strips (+ short, - long)
    bm_box(root, "TermShort", (0.016, 0.005, 0.042), m_brass,
           loc=(-0.036, 0, 0.226), rot=(math.radians(12), 0, 0))
    bm_box(root, "TermLong", (0.016, 0.005, 0.064), m_brass,
           loc=(0.036, 0, 0.236), rot=(math.radians(-18), 0, 0))
    export_glb(root, "battery_pack.glb")


# 5. lada_van.glb
def build_lada_van():
    clear_scene()
    root = make_root("Lada_Utility_Van")
    m_paint = make_mat("FadedBlueVan", (0.34, 0.42, 0.48), metallic=0.28, roughness=0.52)
    m_roof = make_mat("CreamRoof", (0.68, 0.66, 0.58), metallic=0.12, roughness=0.62)
    m_rust = make_mat("WheelArchRust", (0.28, 0.16, 0.10), metallic=0.2, roughness=0.86)
    m_glass = make_mat("DirtyGlass", (0.08, 0.12, 0.14), metallic=0.65, roughness=0.18)
    m_tire = make_mat("TireRubber", (0.04, 0.04, 0.05), metallic=0.0, roughness=0.88)
    m_steel = make_mat("ChromeSteel", (0.62, 0.64, 0.66), metallic=0.86, roughness=0.30)
    m_amber = make_mat("TailLamp", (0.76, 0.22, 0.08), metallic=0.1, roughness=0.30)
    m_lamp = make_mat("HeadlampGlass", (0.85, 0.83, 0.72), metallic=0.2, roughness=0.18,
                      emission=(0.9, 0.85, 0.7), emit_str=0.25)

    # Cargo box + lower chassis (Z ground = 0)
    bm_box(root, "Chassis", (1.68, 3.85, 0.26), m_rust, loc=(0, 0, 0.36))
    bm_box(root, "LowerBody", (1.82, 4.10, 0.68), m_paint, loc=(0, 0, 0.76), bevel=0.03)
    bm_box(root, "UpperVanShell", (1.76, 3.05, 0.92), m_paint, loc=(0, -0.48, 1.48), bevel=0.04)
    bm_box(root, "CabUpper", (1.74, 1.02, 0.78), m_paint, loc=(0, 1.42, 1.42), bevel=0.04)
    bm_box(root, "RoofPanel", (1.72, 4.02, 0.09), m_roof, loc=(0, -0.02, 1.94), bevel=0.02)
    # Windshield & cab windows
    bm_box(root, "Windshield", (1.58, 0.06, 0.56), m_glass, loc=(0, 1.92, 1.44), rot=(math.radians(-10), 0, 0))
    for sx, tag in [(-0.88, "L"), (0.88, "R")]:
        bm_box(root, f"DoorGlass_{tag}", (0.04, 0.66, 0.48), m_glass, loc=(sx, 1.38, 1.44))
        bm_box(root, f"CargoSlotGlass_{tag}", (0.04, 0.84, 0.42), m_glass, loc=(sx, 0.15, 1.48))
        bm_box(root, f"MirrorArm_{tag}", (0.16, 0.04, 0.04), m_steel, loc=(sx * 1.07, 1.72, 1.34))
        bm_box(root, f"MirrorHead_{tag}", (0.05, 0.09, 0.16), m_steel, loc=(sx * 1.15, 1.72, 1.38))
    # Front grille, chrome bumpers, twin headlights & rear doors
    bm_box(root, "Grille", (1.02, 0.06, 0.30), m_steel, loc=(0, 2.05, 0.86))
    bm_box(root, "FrontBumper", (1.88, 0.14, 0.14), m_steel, loc=(0, 2.09, 0.46), bevel=0.02)
    bm_box(root, "RearBumper", (1.88, 0.14, 0.14), m_steel, loc=(0, -2.08, 0.46), bevel=0.02)
    for sx in (-0.66, 0.66):
        bm_cyl(root, f"Headlamp_{sx:.1f}", 0.11, 0.11, 0.06, m_lamp, segs=16,
               loc=(sx, 2.06, 0.86), rot=(math.radians(90), 0, 0))
        bm_box(root, f"TailLamp_{sx:.1f}", (0.14, 0.05, 0.24), m_amber, loc=(sx, -2.05, 0.84))
    # Roof rack bars
    for ry in (-1.2, -0.4, 0.4):
        bm_box(root, f"RoofBar_{ry:.1f}", (1.58, 0.05, 0.06), m_steel, loc=(0, ry, 2.02))
    bm_box(root, "RackRailL", (0.04, 1.9, 0.06), m_steel, loc=(-0.78, -0.4, 2.02))
    bm_box(root, "RackRailR", (0.04, 1.9, 0.06), m_steel, loc=(0.78, -0.4, 2.02))
    # 4 Wheels
    for wx in (-0.84, 0.84):
        for wy in (-1.28, 1.32):
            bm_cyl(root, f"Tire_{wx:.1f}_{wy:.1f}", 0.34, 0.34, 0.22, m_tire, segs=20,
                   loc=(wx, wy, 0.34), rot=(0, math.radians(90), 0))
            bm_cyl(root, f"Rim_{wx:.1f}_{wy:.1f}", 0.19, 0.19, 0.24, m_steel, segs=14,
                   loc=(wx, wy, 0.34), rot=(0, math.radians(90), 0))
    export_glb(root, "lada_van.glb")


# 6. courtyard_bench.glb
def build_courtyard_bench():
    clear_scene()
    root = make_root("CourtyardBench")
    m_wood = make_mat("WeatheredOak", (0.30, 0.21, 0.14), metallic=0.0, roughness=0.84)
    m_iron = make_mat("CastIron", (0.10, 0.11, 0.12), metallic=0.68, roughness=0.58)

    # 2 Cast iron leg frames
    for lx in (-0.72, 0.72):
        bm_box(root, f"FrontLeg_{lx:.1f}", (0.06, 0.06, 0.44), m_iron, loc=(lx, -0.22, 0.22))
        bm_box(root, f"BackPost_{lx:.1f}", (0.06, 0.06, 0.86), m_iron,
               loc=(lx, 0.24, 0.43), rot=(math.radians(-10), 0, 0))
        bm_box(root, f"SeatStrut_{lx:.1f}", (0.05, 0.54, 0.05), m_iron, loc=(lx, 0.0, 0.42))
        bm_box(root, f"Armrest_{lx:.1f}", (0.05, 0.48, 0.04), m_iron, loc=(lx, 0.02, 0.62), bevel=0.006)
        bm_box(root, f"ArmSupport_{lx:.1f}", (0.04, 0.04, 0.20), m_iron, loc=(lx, -0.18, 0.52))
    # Seat slats (3) & backrest slats (2)
    for i, sy in enumerate((-0.18, 0.0, 0.18)):
        bm_box(root, f"SeatSlat_{i}", (1.78, 0.14, 0.035), m_wood, loc=(0, sy, 0.455), bevel=0.004)
    for j, bz in enumerate((0.64, 0.81)):
        bm_box(root, f"BackSlat_{j}", (1.78, 0.035, 0.13), m_wood,
               loc=(0, 0.24 + j * 0.03, bz), rot=(math.radians(-10), 0, 0), bevel=0.004)
    export_glb(root, "courtyard_bench.glb")


# 7. wooden_chair.glb
def build_wooden_chair():
    clear_scene()
    root = make_root("WoodenChair")
    m_wood = make_mat("BentwoodOak", (0.36, 0.23, 0.13), metallic=0.0, roughness=0.72)

    for lx in (-0.19, 0.19):
        bm_cyl(root, f"FrontLeg_{lx:.1f}", 0.018, 0.014, 0.46, m_wood, segs=10,
               loc=(lx, -0.18, 0.23), rot=(math.radians(4), 0, 0))
        bm_cyl(root, f"BackStile_{lx:.1f}", 0.018, 0.015, 0.92, m_wood, segs=10,
               loc=(lx, 0.19, 0.46), rot=(math.radians(-7), 0, 0))
    # Cross stretchers
    bm_cyl(root, "StretcherL", 0.011, 0.011, 0.36, m_wood, segs=8,
           loc=(-0.18, 0.0, 0.15), rot=(math.radians(90), 0, 0))
    bm_cyl(root, "StretcherR", 0.011, 0.011, 0.36, m_wood, segs=8,
           loc=(0.18, 0.0, 0.15), rot=(math.radians(90), 0, 0))
    bm_cyl(root, "StretcherF", 0.011, 0.011, 0.36, m_wood, segs=8,
           loc=(0.0, -0.17, 0.18), rot=(0, math.radians(90), 0))
    # Seat & back rails
    bm_box(root, "Seat", (0.44, 0.42, 0.035), m_wood, loc=(0, 0.0, 0.46), bevel=0.008)
    bm_box(root, "TopRail", (0.44, 0.03, 0.11), m_wood, loc=(0, 0.23, 0.85), rot=(math.radians(-7), 0, 0), bevel=0.005)
    bm_box(root, "MidRail", (0.40, 0.025, 0.06), m_wood, loc=(0, 0.21, 0.68), rot=(math.radians(-7), 0, 0), bevel=0.004)
    export_glb(root, "wooden_chair.glb")


# 8. chapel_shrine.glb
def build_chapel_shrine():
    clear_scene()
    root = make_root("ChapelShrine")
    m_stone = make_mat("Sandstone", (0.44, 0.42, 0.37), metallic=0.0, roughness=0.90)
    m_dark_stone = make_mat("PlinthGranite", (0.26, 0.26, 0.25), metallic=0.0, roughness=0.88)
    m_iron = make_mat("WroughtIron", (0.09, 0.09, 0.10), metallic=0.72, roughness=0.55)
    m_brass = make_mat("TarnishedBrass", (0.66, 0.50, 0.20), metallic=0.84, roughness=0.38)
    m_wax = make_mat("CandleWax", (0.82, 0.78, 0.66), metallic=0.0, roughness=0.65)
    m_flame = make_mat("CandleFlame", (1.0, 0.66, 0.20), metallic=0.0, roughness=0.1,
                       emission=(1.0, 0.62, 0.18), emit_str=3.2)

    bm_box(root, "BaseStep", (1.65, 1.35, 0.22), m_dark_stone, loc=(0, 0, 0.11))
    bm_box(root, "Pedestal", (1.28, 1.02, 0.88), m_stone, loc=(0, 0, 0.66))
    # Niche pillars + back wall + arched gable
    bm_box(root, "BackWall", (1.16, 0.26, 1.35), m_stone, loc=(0, 0.34, 1.78))
    bm_box(root, "PillarL", (0.24, 0.72, 1.35), m_stone, loc=(-0.48, 0.06, 1.78))
    bm_box(root, "PillarR", (0.24, 0.72, 1.35), m_stone, loc=(0.48, 0.06, 1.78))
    bm_box(root, "RoofSlab", (1.42, 1.12, 0.24), m_dark_stone, loc=(0, 0.04, 2.55), bevel=0.03)
    # Stone cross finial
    bm_box(root, "CrossVert", (0.12, 0.10, 0.56), m_stone, loc=(0, 0.04, 2.94))
    bm_box(root, "CrossHoriz", (0.38, 0.10, 0.11), m_stone, loc=(0, 0.04, 3.04))
    # Brass icon & twin candles inside niche
    bm_box(root, "IconPlate", (0.46, 0.04, 0.64), m_brass, loc=(0, 0.19, 1.65), bevel=0.008)
    for cx in (-0.28, 0.28):
        bm_cyl(root, f"CandleStick_{cx:.1f}", 0.045, 0.025, 0.12, m_brass, segs=12, loc=(cx, -0.05, 1.16))
        bm_cyl(root, f"CandleWax_{cx:.1f}", 0.024, 0.022, 0.14, m_wax, segs=10, loc=(cx, -0.05, 1.29))
        bm_sphere(root, f"Flame_{cx:.1f}", 0.018, m_flame, scale=(0.7, 0.7, 1.6), loc=(cx, -0.05, 1.39), sub=1)
    # Iron bars in front of niche
    for bx in (-0.30, -0.15, 0.0, 0.15, 0.30):
        bm_cyl(root, f"GrateBar_{bx:.1f}", 0.012, 0.012, 1.24, m_iron, segs=8, loc=(bx, -0.32, 1.72))
    export_glb(root, "chapel_shrine.glb")


# 9. dead_oak_tree.glb
def build_dead_oak_tree():
    clear_scene()
    root = make_root("DeadOakTree")
    m_bark = make_mat("DeadOakBark", (0.16, 0.14, 0.12), metallic=0.0, roughness=0.95)

    # Gnarled main trunk
    bm_tube(
        root,
        "MainTrunk",
        [(0, 0, 0.0), (0.08, -0.05, 1.1), (0.18, 0.10, 2.4), (0.05, 0.16, 3.6), (-0.12, 0.05, 4.7)],
        [0.44, 0.32, 0.26, 0.20, 0.12],
        m_bark,
        segs=10,
    )
    # 4 Flared root buttresses
    for i in range(4):
        ang = i * (math.pi / 2.0) + 0.35
        dx, dy = math.cos(ang), math.sin(ang)
        bm_tube(
            root,
            f"Root_{i}",
            [(dx * 0.22, dy * 0.22, 0.65), (dx * 0.55, dy * 0.55, 0.18), (dx * 0.95, dy * 0.95, 0.0)],
            [0.20, 0.12, 0.04],
            m_bark,
            segs=7,
        )
    # Major & minor crooked bare limbs
    branches = [
        ([(0.16, 0.10, 2.5), (0.85, 0.35, 3.3), (1.55, 0.62, 4.1), (2.05, 0.42, 4.8)], [0.16, 0.11, 0.06, 0.02]),
        ([(0.05, 0.14, 3.1), (-0.75, -0.38, 3.8), (-1.45, -0.58, 4.6), (-1.92, -0.30, 5.1)], [0.15, 0.10, 0.05, 0.02]),
        ([(0.10, 0.12, 3.4), (-0.42, 0.85, 4.3), (-0.68, 1.48, 5.0)], [0.12, 0.07, 0.02]),
        ([(-0.08, 0.05, 4.2), (0.45, -0.78, 5.0), (0.88, -1.25, 5.5)], [0.10, 0.06, 0.02]),
        ([(0.85, 0.35, 3.3), (1.10, -0.25, 3.9), (1.42, -0.55, 4.4)], [0.08, 0.05, 0.02]),
        ([(-0.75, -0.38, 3.8), (-0.52, -0.95, 4.4), (-0.30, -1.35, 4.9)], [0.08, 0.05, 0.02]),
    ]
    for idx, (pts, rads) in enumerate(branches):
        bm_tube(root, f"Limb_{idx}", pts, rads, m_bark, segs=7)
    export_glb(root, "dead_oak_tree.glb")


# 10. butcher_hook_rack.glb
def build_butcher_hook_rack():
    clear_scene()
    root = make_root("ButcherHookRack")
    m_rail = make_mat("DarkIronRail", (0.14, 0.15, 0.16), metallic=0.80, roughness=0.45)
    m_hook = make_mat("StainlessHook", (0.58, 0.60, 0.62), metallic=0.90, roughness=0.28)
    m_rust = make_mat("BloodRustHook", (0.34, 0.13, 0.10), metallic=0.62, roughness=0.52)

    # Overhead rail bar at Z=2.35 (hangs down toward Z=1.35)
    bm_box(root, "BeamBar", (2.60, 0.08, 0.10), m_rail, loc=(0, 0, 2.35))
    for bx in (-1.15, 1.15):
        bm_box(root, f"MountBracket_{bx:.1f}", (0.10, 0.14, 0.35), m_rail, loc=(bx, 0, 2.50))
    for idx, hx in enumerate((-0.90, -0.45, 0.0, 0.45, 0.90)):
        # Chain links + S-hook hanging beneath
        for c in range(4):
            cz = 2.22 - c * 0.11
            bm_torus(root, f"Chain_{idx}_{c}", 0.032, 0.008, m_hook, maj_s=12, min_s=6,
                     loc=(hx, 0, cz), rot=(0, math.radians(90 if c % 2 == 0 else 0), 0))
        # Curved meat hook
        mat_h = m_rust if idx in (1, 3) else m_hook
        bm_tube(
            root,
            f"MeatHook_{idx}",
            [(hx, 0, 1.78), (hx, 0, 1.56), (hx + 0.05, 0, 1.46), (hx + 0.09, 0, 1.52), (hx + 0.07, 0, 1.60)],
            [0.011, 0.010, 0.010, 0.008, 0.003],
            mat_h,
            segs=8,
        )
    export_glb(root, "butcher_hook_rack.glb")


# 11. anom_well_hands.glb
def build_anom_well_hands():
    clear_scene()
    root = make_root("Anom_Well_Hands")
    m_pale = make_mat("SpectralAshSkin", (0.58, 0.62, 0.64), metallic=0.05, roughness=0.72,
                      emission=(0.28, 0.36, 0.40), emit_str=0.45)

    arm_specs = [
        ((0.0, 0.0, 0.0), (0.04, 0.02, 0.48), (0.12, -0.04, 0.92), 0.2),
        ((-0.24, 0.16, 0.0), (-0.18, 0.10, 0.44), (-0.28, 0.02, 0.85), 1.4),
        ((0.26, -0.14, 0.0), (0.20, -0.18, 0.42), (0.28, -0.10, 0.78), 2.8),
        ((-0.12, -0.22, 0.0), (-0.06, -0.24, 0.38), (-0.14, -0.14, 0.72), -0.9),
    ]
    for i, (p0, p1, p2, yaw) in enumerate(arm_specs):
        bm_tube(root, f"Arm_{i}", [p0, p1, p2], [0.055, 0.042, 0.032], m_pale, segs=9)
        # Palm
        bm_box(root, f"Palm_{i}", (0.095, 0.036, 0.11), m_pale,
               loc=(p2[0], p2[1], p2[2] + 0.06), rot=(0, 0, yaw), bevel=0.012)
        # 5 splayed reaching fingers
        for f in range(5):
            ang = -0.55 + f * 0.27
            fx = p2[0] + math.cos(yaw) * math.sin(ang) * 0.065
            fy = p2[1] + math.sin(yaw) * math.sin(ang) * 0.065
            fz = p2[2] + 0.14
            flen = 0.09 if f in (1, 2, 3) else 0.072
            bm_tube(
                root,
                f"Finger_{i}_{f}",
                [(fx * 0.95 + p2[0] * 0.05, fy * 0.95 + p2[1] * 0.05, p2[2] + 0.09),
                 (fx, fy, fz),
                 (fx + math.cos(yaw) * 0.015, fy + math.sin(yaw) * 0.015, fz + flen)],
                [0.012, 0.009, 0.004],
                m_pale,
                segs=6,
            )
    export_glb(root, "anom_well_hands.glb")


# 12. anom_black_ooze.glb
def build_anom_black_ooze():
    clear_scene()
    root = make_root("Anom_Black_Ooze")
    m_ooze = make_mat("PitchTarOoze", (0.02, 0.025, 0.03), metallic=0.18, roughness=0.14,
                      emission=(0.04, 0.07, 0.09), emit_str=0.25)

    # Organic main tar pool + satellite blobs + rising tendrils
    bm_sphere(root, "MainPool", 1.15, m_ooze, scale=(1.15, 0.95, 0.06), loc=(0, 0, 0.02), sub=3)
    bm_sphere(root, "SubPoolA", 0.58, m_ooze, scale=(1.3, 0.7, 0.07), loc=(0.82, 0.35, 0.02), sub=2)
    bm_sphere(root, "SubPoolB", 0.52, m_ooze, scale=(0.8, 1.2, 0.07), loc=(-0.74, -0.42, 0.02), sub=2)
    tendrils = [
        ([(0.15, 0.08, 0.02), (0.22, 0.12, 0.28), (0.34, 0.06, 0.54), (0.28, -0.05, 0.72)], [0.09, 0.06, 0.03, 0.01]),
        ([(-0.32, 0.24, 0.02), (-0.42, 0.35, 0.24), (-0.36, 0.44, 0.45)], [0.08, 0.045, 0.012]),
        ([(0.48, -0.28, 0.02), (0.58, -0.34, 0.22), (0.52, -0.22, 0.40)], [0.07, 0.04, 0.01]),
    ]
    for i, (pts, rads) in enumerate(tendrils):
        bm_tube(root, f"OozeTendril_{i}", pts, rads, m_ooze, segs=8)
    export_glb(root, "anom_black_ooze.glb")


# 13. anom_hanging_sheet.glb
def build_anom_hanging_sheet():
    clear_scene()
    root = make_root("Anom_Hanging_Sheet")
    m_sheet = make_mat("DampLinenSheet", (0.76, 0.75, 0.70), metallic=0.0, roughness=0.92,
                       emission=(0.14, 0.16, 0.18), emit_str=0.18)
    m_rope = make_mat("HempLine", (0.38, 0.32, 0.22), metallic=0.0, roughness=0.95)
    m_wood = make_mat("ClothesPeg", (0.52, 0.40, 0.24), metallic=0.0, roughness=0.75)

    # Clothesline rope across top at Z=2.35
    bm_cyl(root, "Clothesline", 0.012, 0.012, 2.2, m_rope, segs=8,
           loc=(0, 0, 2.35), rot=(0, math.radians(90), 0))
    for px in (-0.52, 0.0, 0.52):
        bm_box(root, f"Peg_{px:.1f}", (0.025, 0.035, 0.075), m_wood, loc=(px, 0, 2.37))

    # Undulating draped sheet surface using grid in bmesh
    bm = bmesh.new()
    cols, rows = 14, 14
    w, h = 1.15, 1.55
    verts_grid = []
    for r in range(rows):
        v_frac = r / (rows - 1)
        z = 2.35 - v_frac * h
        row_v = []
        for c in range(cols):
            u_frac = c / (cols - 1) - 0.5
            x = u_frac * w
            # Ripples + eerie chest/shoulder silhouette bulge in center
            fold = math.sin(u_frac * math.pi * 5.0) * (0.03 + 0.05 * v_frac)
            bulge = math.exp(-((u_frac * 3.2) ** 2 + ((v_frac - 0.38) * 3.4) ** 2)) * 0.22
            y = fold - bulge
            row_v.append(bm.verts.new((x, y, z)))
        verts_grid.append(row_v)
    for r in range(rows - 1):
        for c in range(cols - 1):
            bm.faces.new((verts_grid[r][c], verts_grid[r][c + 1], verts_grid[r + 1][c + 1], verts_grid[r + 1][c]))
    bmesh.ops.solidify(bm, geom=list(bm.faces), thickness=0.014)
    _finish_bm(bm, "DrapedSheetMesh", m_sheet, root, smooth=True)
    export_glb(root, "anom_hanging_sheet.glb")


# 14. anom_cracked_window.glb
def build_anom_cracked_window():
    clear_scene()
    root = make_root("Anom_Cracked_Window")
    m_frame = make_mat("RottedFrame", (0.14, 0.11, 0.09), metallic=0.0, roughness=0.88)
    m_void = make_mat("WindowAbyss", (0.02, 0.02, 0.03), metallic=0.0, roughness=0.95)
    m_glass = make_mat("JaggedShard", (0.48, 0.58, 0.62), metallic=0.35, roughness=0.14,
                       emission=(0.15, 0.22, 0.26), emit_str=0.35, alpha=0.72)
    m_sil = make_mat("WatcherGlow", (0.72, 0.62, 0.44), metallic=0.0, roughness=0.6,
                     emission=(0.75, 0.58, 0.32), emit_str=1.35)

    # Outer frame (1.2m wide x 1.65m tall centered in Z around 0.85)
    bm_box(root, "FrameBottom", (1.28, 0.14, 0.09), m_frame, loc=(0, 0, 0.045))
    bm_box(root, "FrameTop", (1.28, 0.14, 0.09), m_frame, loc=(0, 0, 1.62))
    bm_box(root, "FrameLeft", (0.09, 0.14, 1.56), m_frame, loc=(-0.59, 0, 0.83))
    bm_box(root, "FrameRight", (0.09, 0.14, 1.56), m_frame, loc=(0.59, 0, 0.83))
    bm_box(root, "MullionH", (1.10, 0.08, 0.06), m_frame, loc=(0, 0, 0.85))
    bm_box(root, "MullionV", (0.06, 0.08, 1.50), m_frame, loc=(0, 0, 0.83))
    # Dark interior backing + shadowy figure standing behind glass
    bm_box(root, "AbyssBack", (1.12, 0.04, 1.52), m_void, loc=(0, 0.06, 0.83))
    bm_sphere(root, "WatcherHead", 0.11, m_sil, scale=(0.85, 0.4, 1.1), loc=(0.14, 0.02, 1.18), sub=2)
    bm_box(root, "WatcherTorso", (0.36, 0.06, 0.54), m_sil, loc=(0.14, 0.02, 0.72), bevel=0.04)
    # Jagged shattered glass triangles around perimeter
    shard_specs = [
        ((-0.44, -0.02, 1.38), (0.28, 0.01, 0.34), (0, 0.25, 0)),
        ((0.42, -0.02, 1.40), (0.30, 0.01, 0.30), (0, -0.35, 0)),
        ((-0.42, -0.02, 0.32), (0.32, 0.01, 0.40), (0, -0.22, 0)),
        ((0.40, -0.02, 0.36), (0.28, 0.01, 0.36), (0, 0.40, 0)),
        ((-0.14, -0.02, 1.48), (0.24, 0.01, 0.20), (0, -0.15, 0)),
        ((0.18, -0.02, 0.20), (0.22, 0.01, 0.22), (0, 0.18, 0)),
    ]
    for idx, (loc, sz, rot) in enumerate(shard_specs):
        bm_box(root, f"GlassShard_{idx}", sz, m_glass, loc=loc, rot=rot)
    export_glb(root, "anom_cracked_window.glb")


def main():
    build_vm_flashlight()
    build_vm_taser()
    build_vm_notebook()
    build_battery_pack()
    build_lada_van()
    build_courtyard_bench()
    build_wooden_chair()
    build_chapel_shrine()
    build_dead_oak_tree()
    build_butcher_hook_rack()
    build_anom_well_hands()
    build_anom_black_ooze()
    build_anom_hanging_sheet()
    build_anom_cracked_window()
    print("ALL_14_V2_GLBS_COMPLETE")


if __name__ == "__main__":
    main()
