r"""
Generates Prompt 05 Blender 3D (.glb) assets for redesigned 1996 Central European interiors
into D:\nocna-zmena-blok-14\assets\models\:
- trafika_kiosk_96.glb        (1996 Trafika awning, metal shutter box, magazine racks, counter tray & cigarette shelf)
- fluorescent_fixture_96.glb  (industrial dual-tube 1990s fluorescent ceiling lamp fixture)
- grocery_display_island.glb  (stocked 1990s Jednota store display gondola with jars, boxes, crates & yellow price rails)
- basement_storage_cage.glb   (slatted wooden Central European panelák cellar cage 'latková pivnica' with crates)
- electrical_panel_96.glb     (metal industrial breaker/junction cabinet with conduits, warning plaque & fuses)
- mailbox_bank_96.glb         (1990s brushed-aluminum panelák lobby mailbox bank with numbered doors & protruding press)
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


def make_mat(name, color, metallic=0.0, roughness=0.68, emission=(0.0, 0.0, 0.0), emit_str=0.0):
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


def bm_cyl(parent, name, r1, r2, h, mat, segs=12, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=smooth)


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
    print(f"EXPORTED_P5_GLB: {filename} ({os.path.getsize(out_path)} bytes)")


# 1. fluorescent_fixture_96.glb
def build_fluorescent_fixture():
    clear_scene()
    root = make_root("FluorescentFixture96")
    m_housing = make_mat("EnamelMetalHousing", (0.58, 0.60, 0.56), metallic=0.42, roughness=0.48)
    m_cap = make_mat("PlasticEndCap", (0.72, 0.70, 0.62), roughness=0.55)
    m_tube = make_mat("FluorescentTube", (0.90, 0.96, 0.92), roughness=0.22, emission=(0.86, 0.94, 0.88), emit_str=2.6)
    bm_box(root, "CeilingChassis", (1.28, 0.24, 0.06), m_housing, loc=(0, 0, 0.03), bevel=0.004)
    for sx in (-0.61, 0.61):
        bm_box(root, f"EndCap_{sx}", (0.04, 0.22, 0.08), m_cap, loc=(sx, 0, -0.02))
    for sy in (-0.055, 0.055):
        bm_cyl(root, f"Tube_{sy}", 0.018, 0.018, 1.18, m_tube, segs=12, loc=(0, sy, -0.035), rot=(0, math.radians(90), 0))
    export_glb(root, "fluorescent_fixture_96.glb")


# 2. trafika_kiosk_96.glb — Front counter tray, shutter roll hood, magazine rack & cigarette stand
def build_trafika_kiosk_fittings():
    clear_scene()
    root = make_root("TrafikaFittings96")
    m_metal = make_mat("KioskPaintedSteel", (0.16, 0.28, 0.24), metallic=0.45, roughness=0.55)
    m_shutter = make_mat("RollShutterGrey", (0.34, 0.36, 0.37), metallic=0.65, roughness=0.45)
    m_counter = make_mat("LaminateCounter", (0.54, 0.44, 0.30), roughness=0.52)
    m_wire = make_mat("RackWireSteel", (0.48, 0.50, 0.52), metallic=0.80, roughness=0.38)
    m_paper1 = make_mat("NewsprintWhite", (0.76, 0.73, 0.66), roughness=0.88)
    m_mag_red = make_mat("MagRed96", (0.62, 0.16, 0.14), roughness=0.50)
    m_mag_blue = make_mat("MagBlue96", (0.16, 0.32, 0.56), roughness=0.50)
    m_mag_yel = make_mat("MagYellow96", (0.74, 0.60, 0.16), roughness=0.50)

    # Overhead metal rain awning + shutter housing box (faces -X in world when placed at Rot 0, so front is -Y in Blender -> +Z in Godot)
    bm_box(root, "ShutterBox", (2.8, 0.32, 0.34), m_shutter, loc=(0, 0.16, 2.38), bevel=0.008)
    bm_box(root, "CanopyAwning", (3.2, 0.95, 0.09), m_metal, loc=(0, 0.52, 2.58), rot=(math.radians(-10), 0, 0), bevel=0.006)
    # Exterior granite/laminate service ledge under window
    bm_box(root, "ServiceLedge", (2.5, 0.44, 0.07), m_counter, loc=(0, 0.24, 1.04), bevel=0.008)
    bm_box(root, "CoinTray", (0.28, 0.22, 0.025), m_wire, loc=(0.0, 0.22, 1.09))

    # Magazine & newspaper tiered wire display rack on left side of window
    bm_box(root, "RackFrameBack", (0.86, 0.04, 1.25), m_wire, loc=(-1.25, 0.08, 0.72))
    mags = [m_paper1, m_mag_red, m_mag_blue, m_mag_yel]
    for tier in range(4):
        tz = 0.28 + tier * 0.28
        bm_box(root, f"RackShelf_{tier}", (0.84, 0.14, 0.03), m_wire, loc=(-1.25, 0.15, tz))
        for col in range(3):
            mx = -1.52 + col * 0.27
            mat_m = mags[(tier + col) % len(mags)]
            bm_box(root, f"Mag_{tier}_{col}", (0.22, 0.03, 0.24), mat_m, loc=(mx, 0.17, tz + 0.12), rot=(math.radians(-12), 0, 0))

    # Hanging press stack & lottery slip box on right side
    bm_box(root, "LotteryBox", (0.36, 0.22, 0.32), m_mag_yel, loc=(1.12, 0.18, 1.25), bevel=0.006)
    bm_box(root, "NewsStack1", (0.34, 0.26, 0.18), m_paper1, loc=(1.12, 0.22, 0.10))
    bm_box(root, "NewsStack2", (0.34, 0.26, 0.14), m_paper1, loc=(1.14, 0.22, 0.27), rot=(0, 0, math.radians(8)))
    export_glb(root, "trafika_kiosk_96.glb")


# 3. grocery_display_island.glb — Stocked 1990s Jednota store gondola shelf
def build_grocery_display_island():
    clear_scene()
    root = make_root("GroceryDisplayIsland96")
    m_steel = make_mat("GondolaCreamSteel", (0.68, 0.66, 0.58), metallic=0.25, roughness=0.52)
    m_rail = make_mat("PriceRailYellow", (0.78, 0.62, 0.14), roughness=0.45)
    m_crate = make_mat("BreadCrateWood", (0.48, 0.34, 0.20), roughness=0.84)
    prod_mats = [
        make_mat("PackRed", (0.60, 0.16, 0.14), roughness=0.62),
        make_mat("PackBlue", (0.16, 0.30, 0.52), roughness=0.58),
        make_mat("PackGreen", (0.18, 0.42, 0.22), roughness=0.65),
        make_mat("PackOchre", (0.68, 0.52, 0.22), roughness=0.65),
        make_mat("JarGlass", (0.58, 0.66, 0.56), roughness=0.20),
        make_mat("TinCan", (0.58, 0.56, 0.50), metallic=0.72, roughness=0.38),
    ]

    # Central spine + base plinth
    bm_box(root, "Plinth", (2.4, 0.78, 0.14), m_steel, loc=(0, 0, 0.07))
    bm_box(root, "CenterSpine", (2.36, 0.05, 1.56), m_steel, loc=(0, 0, 0.90))
    for end_x in (-1.18, 1.18):
        bm_box(root, f"EndPost_{end_x}", (0.06, 0.74, 1.66), m_steel, loc=(end_x, 0, 0.85))

    # 4 tiered shelves on both sides stocked with varied 90s products
    for lvl, z_h in enumerate([0.22, 0.58, 0.96, 1.34]):
        for side_y in (-0.21, 0.21):
            bm_box(root, f"Shelf_{lvl}_{side_y}", (2.34, 0.34, 0.03), m_steel, loc=(0, side_y, z_h))
            rail_y = side_y + (0.175 if side_y > 0 else -0.175)
            bm_box(root, f"PriceRail_{lvl}_{side_y}", (2.34, 0.015, 0.045), m_rail, loc=(0, rail_y, z_h))
            for item_i in range(8):
                ix = -1.0 + item_i * 0.28
                mat_p = prod_mats[(lvl * 3 + item_i + (1 if side_y > 0 else 0)) % len(prod_mats)]
                if (item_i + lvl) % 3 == 0:
                    bm_cyl(root, f"Jar_{lvl}_{side_y}_{item_i}", 0.052, 0.048, 0.16, mat_p, segs=10, loc=(ix, side_y, z_h + 0.095))
                else:
                    h = 0.18 + ((item_i + lvl) % 2) * 0.06
                    bm_box(root, f"Box_{lvl}_{side_y}_{item_i}", (0.18, 0.16, h), mat_p, loc=(ix, side_y, z_h + h * 0.5 + 0.015))
    # Endcap bread crate
    bm_box(root, "BreadCrate", (0.44, 0.62, 0.28), m_crate, loc=(1.44, 0, 0.14))
    export_glb(root, "grocery_display_island.glb")


# 4. basement_storage_cage.glb — Slatted wooden panelák cellar cage ('latková pivnica')
def build_basement_storage_cage():
    clear_scene()
    root = make_root("BasementStorageCage")
    m_slat = make_mat("AgedCellarWood", (0.30, 0.23, 0.16), roughness=0.90)
    m_iron = make_mat("RustyHasp", (0.20, 0.16, 0.14), metallic=0.78, roughness=0.62)
    m_crate = make_mat("DustyCardboard", (0.38, 0.31, 0.22), roughness=0.92)

    # Corner posts (2.2m wide x 1.8m deep x 2.3m high)
    for px in (-1.1, 1.1):
        for py in (-0.9, 0.9):
            bm_box(root, f"Post_{px}_{py}", (0.07, 0.07, 2.30), m_slat, loc=(px, py, 1.15))
    # Cross rails front & sides
    for rz in (0.35, 1.15, 2.05):
        bm_box(root, f"FrontRail_{rz}", (2.20, 0.05, 0.07), m_slat, loc=(0, 0.90, rz))
        bm_box(root, f"SideRailL_{rz}", (0.05, 1.80, 0.07), m_slat, loc=(-1.10, 0, rz))
        bm_box(root, f"SideRailR_{rz}", (0.05, 1.80, 0.07), m_slat, loc=(1.10, 0, rz))
    # Vertical wooden slats with gaps so flashlight sees stored boxes inside
    for si in range(13):
        sx = -1.0 + si * 0.165
        bm_box(root, f"FrontSlat_{si}", (0.09, 0.022, 2.24), m_slat, loc=(sx, 0.92, 1.12))
    for si in range(10):
        sy = -0.82 + si * 0.18
        bm_box(root, f"SideSlatL_{si}", (0.022, 0.09, 2.24), m_slat, loc=(-1.12, sy, 1.12))
        bm_box(root, f"SideSlatR_{si}", (0.022, 0.09, 2.24), m_slat, loc=(1.12, sy, 1.12))
    # Padlock hasp on front
    bm_box(root, "HaspPlate", (0.14, 0.03, 0.05), m_iron, loc=(0.25, 0.95, 1.12))
    bm_box(root, "PadlockBody", (0.055, 0.03, 0.07), m_iron, loc=(0.25, 0.97, 1.06))
    # Dusty clutter inside cage
    bm_box(root, "StoredBox1", (0.65, 0.55, 0.48), m_crate, loc=(-0.45, -0.25, 0.24), rot=(0, 0, math.radians(12)))
    bm_box(root, "StoredBox2", (0.50, 0.45, 0.38), m_crate, loc=(-0.42, -0.20, 0.67), rot=(0, 0, math.radians(-18)))
    bm_box(root, "StoredCrate3", (0.60, 0.48, 0.42), m_slat, loc=(0.45, -0.35, 0.21))
    export_glb(root, "basement_storage_cage.glb")


# 5. electrical_panel_96.glb
def build_electrical_panel():
    clear_scene()
    root = make_root("ElectricalPanel96")
    m_box = make_mat("IndustrialGreyEnamel", (0.34, 0.37, 0.36), metallic=0.58, roughness=0.52)
    m_pipe = make_mat("ConduitIron", (0.22, 0.23, 0.24), metallic=0.78, roughness=0.48)
    m_warn = make_mat("HazardYellow", (0.82, 0.66, 0.14), roughness=0.45)
    m_led = make_mat("PilotRed", (0.85, 0.15, 0.10), roughness=0.3, emission=(0.95, 0.18, 0.10), emit_str=2.2)

    bm_box(root, "CabinetBody", (0.68, 0.22, 0.92), m_box, loc=(0, 0, 0), bevel=0.008)
    bm_box(root, "CabinetDoor", (0.62, 0.03, 0.86), m_box, loc=(0, 0.115, 0), bevel=0.005)
    bm_box(root, "WarningPlaque", (0.16, 0.01, 0.16), m_warn, loc=(0.0, 0.135, 0.16), rot=(0, math.radians(45), 0))
    bm_box(root, "LatchHandle", (0.04, 0.05, 0.14), m_pipe, loc=(0.24, 0.14, 0.0))
    bm_cyl(root, "PilotLight", 0.018, 0.018, 0.03, m_led, segs=10, loc=(-0.18, 0.135, 0.30), rot=(math.radians(90), 0, 0))
    for cx in (-0.22, 0.0, 0.22):
        bm_cyl(root, f"ConduitTop_{cx}", 0.022, 0.022, 0.85, m_pipe, segs=10, loc=(cx, -0.02, 0.88))
    export_glb(root, "electrical_panel_96.glb")


# 6. mailbox_bank_96.glb — Classic Central European aluminum panelák lobby mailboxes
def build_mailbox_bank():
    clear_scene()
    root = make_root("MailboxBank96")
    m_alu = make_mat("BrushedAluminum96", (0.54, 0.56, 0.55), metallic=0.72, roughness=0.42)
    m_dark = make_mat("SlotDarkMetal", (0.12, 0.13, 0.14), metallic=0.5, roughness=0.65)
    m_paper = make_mat("LeafletPaper", (0.80, 0.76, 0.68), roughness=0.88)
    m_tag = make_mat("NameplateWhite", (0.78, 0.76, 0.70), roughness=0.70)

    bm_box(root, "MainChassis", (1.64, 0.24, 1.08), m_alu, loc=(0, 0, 0), bevel=0.006)
    for r in range(4):
        for c in range(5):
            bx = -0.62 + c * 0.31
            bz = -0.36 + r * 0.24
            bm_box(root, f"BoxDoor_{r}_{c}", (0.28, 0.02, 0.21), m_alu, loc=(bx, 0.125, bz), bevel=0.003)
            bm_box(root, f"MailSlot_{r}_{c}", (0.22, 0.01, 0.024), m_dark, loc=(bx, 0.138, bz + 0.065))
            bm_box(root, f"NameTag_{r}_{c}", (0.11, 0.008, 0.032), m_tag, loc=(bx - 0.04, 0.138, bz - 0.02))
            if (r == 1 and c == 2) or (r == 2 and c == 4):
                bm_box(root, f"Leaflet_{r}_{c}", (0.16, 0.12, 0.012), m_paper, loc=(bx, 0.19, bz + 0.06), rot=(math.radians(18), 0, math.radians(6)))
    export_glb(root, "mailbox_bank_96.glb")


def main():
    build_fluorescent_fixture()
    build_trafika_kiosk_fittings()
    build_grocery_display_island()
    build_basement_storage_cage()
    build_electrical_panel()
    build_mailbox_bank()
    print("ALL_6_PROMPT05_GLBS_COMPLETE")


if __name__ == "__main__":
    main()
