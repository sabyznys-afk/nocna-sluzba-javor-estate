r"""
Prompt 09 Part 2 — Organic Low-Poly PS1 Character Model Builder (Blender 5.3.0):
Completely replaces box-shaped heads & block hair with stylized low-poly human anatomy:
  - Sculpted multi-ring organic human heads (rounded cranium, brow ridge, eye-socket recess,
    angled cheekbones, defined jawline, distinct chin, protruding 3D low-poly nose, sculpted 3D ears,
    organic neck joining clavicles) with direct seamless cylindrical-frontal UV mapping!
  - Distinct sculpted 3D low-poly hairstyles (receding short grey, side-parted, elder wavy curls,
    shoulder bob, sleek bun + 3D glasses, tousled youth, slicked cropped, flat cap / wool beanie)
    with embedded pixelated hair strand textures — ZERO cube hair!
  - Coherent anatomical bodies: contoured torsos with collar lapels, rounded deltoid shoulders,
    elbow joints, tapered forearms, sculpted hands with thumbs, knees, tapered calves & winter boots!
  - Builds all 11 existing estate characters + Martin Kovac full model + Distant Anomaly Silhouette
    + Martin FP body, preserving all articulated pivots (TorsoPivot, HeadPivot, ArmL/R_Pivot,
    LegL/R_Pivot, VargaFlashlightTip).
"""
import math
import os
import bpy
import bmesh
from mathutils import Euler, Matrix, Vector

OUT_DIR = r"D:\nocna-zmena-blok-14\assets\models"
FACE_DIR = r"D:\nocna-zmena-blok-14\assets\textures\ps1_faces"
os.makedirs(OUT_DIR, exist_ok=True)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for col in list(bpy.data.collections):
        bpy.data.collections.remove(col)
    for mesh in list(bpy.data.meshes):
        bpy.data.meshes.remove(mesh)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)
    for img in list(bpy.data.images):
        bpy.data.images.remove(img)


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


def make_ps1_mat(name, color, tex_path=None, metallic=0.0, roughness=0.92):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    if bsdf is None:
        bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
    bsdf.inputs["Metallic"].default_value = float(metallic)
    bsdf.inputs["Roughness"].default_value = float(roughness)
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.10

    if tex_path and os.path.exists(tex_path):
        tex = nt.nodes.new("ShaderNodeTexImage")
        img = bpy.data.images.load(tex_path, check_existing=True)
        img.pack()
        tex.image = img
        tex.interpolation = "Closest"
        if color != (1.0, 1.0, 1.0):
            mix = nt.nodes.new("ShaderNodeMix")
            mix.data_type = "RGBA"
            mix.blend_type = "MULTIPLY"
            mix.inputs["Factor"].default_value = 1.0
            mix.inputs[7].default_value = (color[0], color[1], color[2], 1.0)
            nt.links.new(tex.outputs["Color"], mix.inputs[6])
            nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
        else:
            nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def _finish_bm(bm, name, mat, parent, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False, keep_uvs=False):
    if not keep_uvs:
        uv_layer = bm.loops.layers.uv.verify()
        for f in bm.faces:
            n = f.normal
            ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
            for loop in f.loops:
                co = loop.vert.co
                if ay >= ax and ay >= az:
                    loop[uv_layer].uv = (co.x * 2.4 + 0.5, co.z * 2.4 + 0.5)
                elif ax >= az:
                    loop[uv_layer].uv = (co.y * 2.4 + 0.5, co.z * 2.4 + 0.5)
                else:
                    loop[uv_layer].uv = (co.x * 2.4 + 0.5, co.y * 2.4 + 0.5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name + "_mesh")
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons:
        p.use_smooth = smooth
    obj = bpy.data.objects.new(name, mesh)
    obj.location = Vector(loc)
    obj.rotation_euler = Euler(rot, "XYZ")
    if mat is not None:
        obj.data.materials.append(mat)
    return _link_obj(obj, parent)


def lp_loft(parent, name, rings, mat, segs=10, loc=(0, 0, 0), rot=(0, 0, 0), cap_bottom=True, cap_top=True, smooth=False):
    """
    Creates an organic contoured low-poly mesh from vertical elliptical rings.
    Each ring tuple: (z, rx, ry, y_offset)
    """
    bm = bmesh.new()
    ring_verts = []
    for (z, rx, ry, y_off) in rings:
        row = []
        for s in range(segs):
            ang = (2.0 * math.pi * s) / float(segs)
            vx = math.sin(ang) * rx
            vy = -math.cos(ang) * ry + y_off
            row.append(bm.verts.new((vx, vy, z)))
        ring_verts.append(row)

    for r in range(len(ring_verts) - 1):
        r0 = ring_verts[r]
        r1 = ring_verts[r + 1]
        for s in range(segs):
            sn = (s + 1) % segs
            bm.faces.new((r0[s], r0[sn], r1[sn], r1[s]))

    if cap_bottom and len(ring_verts) > 0:
        bm.faces.new(list(reversed(ring_verts[0])))
    if cap_top and len(ring_verts) > 0:
        bm.faces.new(ring_verts[-1])

    return _finish_bm(bm, name, mat, parent, loc, rot, smooth=smooth)


def lp_box(parent, name, size, mat, loc=(0, 0, 0), rot=(0, 0, 0), taper_top=1.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.transform(bm, matrix=Matrix.Diagonal((size[0], size[1], size[2], 1.0)), verts=bm.verts)
    if abs(taper_top - 1.0) > 0.001:
        for v in bm.verts:
            if v.co.z > 0.0:
                v.co.x *= taper_top
                v.co.y *= taper_top
    return _finish_bm(bm, name, mat, parent, loc, rot)


def lp_cyl(parent, name, r1, r2, h, mat, segs=8, loc=(0, 0, 0), rot=(0, 0, 0)):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return _finish_bm(bm, name, mat, parent, loc, rot)


def build_organic_head(head_p, h_sc, head_sc, m_face, m_skin, jaw_w=1.0, nose_len=1.0, cheek_w=1.0):
    """
    Sculpts a genuine organic low-poly PS1 human head (NOT a cube!):
    - 16 radial columns x 11 vertical anatomical loops (~190 verts, ~360 tris)
    - Rounded cranium, contoured temples, subtle brow ridge & orbital recesses,
      angular cheekbones, tapered jawline, distinct chin, sculpted 3D nose bridge/tip,
      plus sculpted 3D ears and organic neck.
    - Direct cylindrical-frontal UV mapping aligned exactly to build_p9_face_textures.py!
    """
    sx = 0.090 * h_sc * head_sc
    sy = 0.106 * h_sc * head_sc
    sz = 0.240 * h_sc * head_sc
    base_z = 0.068 * h_sc

    # Anatomical neck joining clavicles -> skull base
    neck_rings = [
        (0.000 * h_sc, 0.062 * h_sc * head_sc, 0.056 * h_sc * head_sc, 0.006),
        (0.040 * h_sc, 0.052 * h_sc * head_sc, 0.050 * h_sc * head_sc, 0.008),
        (0.088 * h_sc, 0.050 * h_sc * head_sc, 0.052 * h_sc * head_sc, 0.004),
    ]
    lp_loft(head_p, "NeckOrganic", neck_rings, m_skin, segs=8, smooth=True)

    # Vertical profile loops: (v_top_0_to_1, rx_mult, ry_front, ry_back, y_shift)
    # v_top = 0 at crown, 1 at bottom of sub-chin (matches texture vy directly!)
    loops = [
        (0.04, 0.36, 0.38, 0.42, 0.012),  # Crown top ring
        (0.11, 0.74, 0.72, 0.80, 0.012),  # Upper cranium
        (0.22, 0.94, 0.90, 0.98, 0.010),  # Upper forehead / parietal
        (0.34, 0.98, 0.96, 1.00, 0.006),  # Forehead
        (0.42, 0.99, 1.00, 0.98, 0.004),  # Brow ridge
        (0.49, 0.97 * cheek_w, 0.93, 0.94, 0.004),  # Eye sockets / temples
        (0.58, 0.98 * cheek_w, 0.96, 0.88, 0.002),  # Cheekbones / nose bridge
        (0.67, 0.88 * jaw_w,   0.92, 0.78, 0.000),  # Lower cheek / nostrils / jaw angle
        (0.75, 0.78 * jaw_w,   0.88, 0.66, -0.003), # Mouth / mid-jaw
        (0.84, 0.60 * jaw_w,   0.78, 0.54, -0.006), # Chin / anterior jaw
        (0.93, 0.42,           0.50, 0.46, 0.004),  # Sub-chin -> neck junction
    ]

    segs = 16
    bm = bmesh.new()
    # We keep a seam at back of skull (s=0 and s=segs share 3D pos via split UV column) so cylindrical UVs NEVER stretch!
    # Angle a in [-pi, +pi]: 0 = exact front (-Y in Blender -> +Z in Godot)!
    ring_verts = []
    ring_uvs = []

    for (vt, rx_m, ry_f, ry_b, y_sh) in loops:
        z_local = base_z + (1.0 - vt) * sz
        row_v = []
        row_uv = []
        for s in range(segs + 1):
            # u goes 0.0 (back-left) -> 0.5 (front nose) -> 1.0 (back-right)
            u_val = float(s) / float(segs)
            ang = (u_val - 0.5) * 2.0 * math.pi  # -pi .. +pi; 0 is straight front (-Y)

            sin_a = math.sin(ang)
            cos_a = math.cos(ang)  # +1 at front, -1 at back
            ry_use = ry_f if cos_a >= 0.0 else ry_b

            vx = sin_a * sx * rx_m
            vy = -cos_a * sy * ry_use + y_sh * h_sc

            # --- Sculpted Anatomical Landmarks (front face cos_a > 0) ---
            front_w = max(0.0, cos_a)
            abs_a = abs(ang)

            # 1. Subtle brow ridge prominence (vt ~ 0.42)
            brow_k = math.exp(-((vt - 0.42) / 0.045) ** 2) * math.exp(-(abs_a / 0.72) ** 2)
            vy -= 0.009 * h_sc * head_sc * brow_k

            # 2. Eye socket indentation (vt ~ 0.48, |ang| ~ 0.42 rad)
            eye_k = math.exp(-((vt - 0.485) / 0.045) ** 2) * math.exp(-((abs_a - 0.46) / 0.22) ** 2)
            vy += 0.008 * h_sc * head_sc * eye_k

            # 3. Cheekbone angular prominence (vt ~ 0.58, |ang| ~ 0.72 rad)
            cheek_k = math.exp(-((vt - 0.58) / 0.065) ** 2) * math.exp(-((abs_a - 0.78) / 0.30) ** 2)
            vx += (1.0 if sin_a >= 0 else -1.0) * 0.006 * h_sc * head_sc * cheek_k * cheek_w
            vy -= 0.006 * h_sc * head_sc * cheek_k

            # 4. Protruding 3D Low-Poly Nose Bridge & Tip (vt 0.48..0.65, |ang| < 0.26 rad)!
            if cos_a > 0.5 and abs_a < 0.32 and 0.46 <= vt <= 0.68:
                nose_center = math.exp(-(abs_a / 0.13) ** 2)
                if vt <= 0.62:
                    # Sloping bridge down to prominent tip at vt=0.62
                    bridge_h = max(0.0, (vt - 0.46) / 0.16)
                    vy -= (0.024 * nose_len) * h_sc * head_sc * bridge_h * nose_center
                else:
                    # Clean underside slope back to philtrum
                    under_h = max(0.0, 1.0 - (vt - 0.62) / 0.06)
                    vy -= (0.022 * nose_len) * h_sc * head_sc * under_h * nose_center

            # 5. Subtle lip protrusion (vt ~ 0.73) & distinct chin point (vt ~ 0.84)
            lip_k = math.exp(-((vt - 0.73) / 0.032) ** 2) * math.exp(-(abs_a / 0.30) ** 2)
            vy -= 0.007 * h_sc * head_sc * lip_k
            chin_k = math.exp(-((vt - 0.84) / 0.050) ** 2) * math.exp(-(abs_a / 0.36) ** 2)
            vy -= 0.011 * h_sc * head_sc * chin_k
            # Taper sides of chin sharply so jawline looks genuinely human!
            if vt >= 0.74 and front_w > 0.1:
                vx *= (1.0 - 0.14 * ((vt - 0.74) / 0.20) * (abs_a / 1.4))

            # 6. Occipital skull curve at back (cos_a < 0)
            if cos_a < -0.2 and 0.20 <= vt <= 0.60:
                occ_k = math.exp(-((vt - 0.42) / 0.20) ** 2) * (-cos_a)
                vy += 0.010 * h_sc * head_sc * occ_k

            # Reuse seam vert at s == segs? NO — duplicate vertex on back seam with u=1.0 so UV is 100% distortion-free!
            v = bm.verts.new((vx, vy, z_local))
            row_v.append(v)
            row_uv.append((u_val, 1.0 - vt))
        ring_verts.append(row_v)
        ring_uvs.append(row_uv)

    # Crown pole and sub-chin pole
    crown_v = bm.verts.new((0.0, 0.012 * h_sc, base_z + sz * 1.015))
    bottom_v = bm.verts.new((0.0, 0.006 * h_sc, base_z + sz * 0.01))

    uv_layer = bm.loops.layers.uv.verify()

    # Main facial/cranial quads
    for r in range(len(ring_verts) - 1):
        for s in range(segs):
            v00 = ring_verts[r][s]
            v01 = ring_verts[r][s + 1]
            v11 = ring_verts[r + 1][s + 1]
            v10 = ring_verts[r + 1][s]
            f = bm.faces.new((v00, v10, v11, v01))
            f_uvs = [ring_uvs[r][s], ring_uvs[r + 1][s], ring_uvs[r + 1][s + 1], ring_uvs[r][s + 1]]
            for lp, uv in zip(f.loops, f_uvs):
                lp[uv_layer].uv = uv

    # Crown cap triangles
    for s in range(segs):
        v0 = ring_verts[0][s]
        v1 = ring_verts[0][s + 1]
        f = bm.faces.new((crown_v, v0, v1))
        u_mid = 0.5 * (ring_uvs[0][s][0] + ring_uvs[0][s + 1][0])
        for lp, uv in zip(f.loops, [(u_mid, 0.99), ring_uvs[0][s], ring_uvs[0][s + 1]]):
            lp[uv_layer].uv = uv

    # Bottom cap triangles
    last_r = len(ring_verts) - 1
    for s in range(segs):
        v0 = ring_verts[last_r][s]
        v1 = ring_verts[last_r][s + 1]
        f = bm.faces.new((bottom_v, v1, v0))
        u_mid = 0.5 * (ring_uvs[last_r][s][0] + ring_uvs[last_r][s + 1][0])
        for lp, uv in zip(f.loops, [(u_mid, 0.02), ring_uvs[last_r][s + 1], ring_uvs[last_r][s]]):
            lp[uv_layer].uv = uv

    head_obj = _finish_bm(bm, "OrganicHeadMesh", m_face, head_p, smooth=True, keep_uvs=True)

    # --- Sculpted Low-Poly 3D Ears positioned naturally at eye-to-nose height ---
    ear_z = base_z + sz * 0.43
    for side, sgn in [("Ear_L", -1.0), ("Ear_R", 1.0)]:
        ear_rings = [
            (-0.028 * h_sc * head_sc, 0.008 * h_sc * head_sc, 0.013 * h_sc * head_sc, 0.002),
            (-0.008 * h_sc * head_sc, 0.013 * h_sc * head_sc, 0.021 * h_sc * head_sc, 0.000),
            (0.015 * h_sc * head_sc,  0.014 * h_sc * head_sc, 0.022 * h_sc * head_sc, 0.003),
            (0.028 * h_sc * head_sc,  0.009 * h_sc * head_sc, 0.014 * h_sc * head_sc, 0.006),
        ]
        lp_loft(
            head_p, side, ear_rings, m_skin, segs=6,
            loc=(sgn * sx * 0.98, 0.012 * h_sc * head_sc, ear_z),
            rot=(0.08, sgn * 0.22, sgn * -0.18),
            smooth=True,
        )

    return head_obj, sx, sy, sz, base_z


def build_organic_hair(head_p, hstyle, sx, sy, sz, base_z, h_sc, head_sc, m_hair, cfg):
    """
    Constructs sculpted, contoured low-poly 3D hairstyle geometry conforming to the organic cranium.
    ZERO cube hair blocks!
    """
    def _hair_shell(name, v_bands, ang_min_deg, ang_max_deg, mat, segs_u=12, flare=1.0):
        """Creates a curved solid-thickness hair shell conforming to the skull over [ang_min..ang_max] (0=front, +-180=back)."""
        bm = bmesh.new()
        outer_rows = []
        inner_rows = []
        for (vt, rad_x, rad_y, thick, y_sh) in v_bands:
            z = base_z + (1.0 - vt) * sz
            o_row = []
            i_row = []
            for i in range(segs_u + 1):
                t = float(i) / float(segs_u)
                ang = math.radians(ang_min_deg + (ang_max_deg - ang_min_deg) * t)
                sin_a = math.sin(ang)
                cos_a = math.cos(ang)
                ox = sin_a * sx * rad_x * flare
                oy = -cos_a * sy * rad_y * flare + y_sh * h_sc
                ix = sin_a * sx * max(0.3, rad_x - thick)
                iy = -cos_a * sy * max(0.3, rad_y - thick) + y_sh * h_sc
                o_row.append(bm.verts.new((ox, oy, z)))
                i_row.append(bm.verts.new((ix, iy, z)))
            outer_rows.append(o_row)
            inner_rows.append(i_row)

        closed_ring = abs((ang_max_deg - ang_min_deg) - 360.0) < 1.0
        n_seg = segs_u if closed_ring else segs_u
        for r in range(len(outer_rows) - 1):
            for i in range(n_seg):
                # Outer faces
                bm.faces.new((outer_rows[r][i], outer_rows[r + 1][i], outer_rows[r + 1][i + 1], outer_rows[r][i + 1]))
                # Inner faces (reversed)
                bm.faces.new((inner_rows[r][i], inner_rows[r][i + 1], inner_rows[r + 1][i + 1], inner_rows[r + 1][i]))
        # Cap top & bottom thickness rims
        for i in range(n_seg):
            bm.faces.new((outer_rows[0][i], outer_rows[0][i + 1], inner_rows[0][i + 1], inner_rows[0][i]))
            bm.faces.new((outer_rows[-1][i], inner_rows[-1][i], inner_rows[-1][i + 1], outer_rows[-1][i + 1]))
        if not closed_ring:
            for r in range(len(outer_rows) - 1):
                bm.faces.new((outer_rows[r][0], inner_rows[r][0], inner_rows[r + 1][0], outer_rows[r + 1][0]))
                bm.faces.new((outer_rows[r][-1], outer_rows[r + 1][-1], inner_rows[r + 1][-1], inner_rows[r][-1]))
        return _finish_bm(bm, name, mat, head_p, smooth=True)

    if hstyle == "receding":
        # Jozef Varga (51): sculpted receding side/back short grey hair + sideburns, open weathered forehead!
        _hair_shell("HairRecedingBack", [
            (0.06, 0.72, 0.76, 0.10, 0.018),
            (0.16, 1.04, 1.06, 0.11, 0.016),
            (0.32, 1.08, 1.09, 0.10, 0.014),
            (0.54, 1.06, 1.04, 0.09, 0.012),
            (0.74, 0.88, 0.90, 0.08, 0.010),
        ], 52.0, 308.0, m_hair, segs_u=10)
        # Subtle swept side tufts above temples
        for side, sgn in [("TempleTuft_L", -1.0), ("TempleTuft_R", 1.0)]:
            lp_loft(head_p, side, [
                (0.0, 0.016 * h_sc, 0.028 * h_sc, 0.0),
                (0.055 * h_sc, 0.022 * h_sc, 0.042 * h_sc, 0.008),
                (0.090 * h_sc, 0.012 * h_sc, 0.026 * h_sc, 0.012),
            ], m_hair, segs=6, loc=(sgn * sx * 0.96, 0.002, base_z + sz * 0.56), smooth=True)

    elif hstyle == "elder_curls":
        # Anna Krizanova (68): rounded soft sculpted wavy perm volume framing face & neck
        _hair_shell("HairElderCrown", [
            (-0.02, 0.55, 0.58, 0.14, 0.014),
            (0.08,  1.06, 1.06, 0.16, 0.012),
            (0.20,  1.18, 1.15, 0.17, 0.010),
            (0.38,  1.22, 1.16, 0.16, 0.012),
            (0.62,  1.16, 1.12, 0.15, 0.016),
            (0.80,  0.96, 0.98, 0.12, 0.018),
        ], 42.0, 318.0, m_hair, segs_u=14)
        # Soft curled front fringe above forehead
        _hair_shell("HairElderFringe", [
            (0.02, 0.65, 0.65, 0.12, 0.008),
            (0.14, 1.08, 1.06, 0.14, 0.004),
            (0.26, 1.06, 1.04, 0.12, 0.000),
        ], -55.0, 55.0, m_hair, segs_u=8)

    elif hstyle == "shoulder_bob":
        # Dana Bielikova & Resident B: sculpted shoulder-length bob curving cleanly past cheeks & jaw!
        _hair_shell("HairBobCrown", [
            (-0.02, 0.45, 0.48, 0.11, 0.012),
            (0.08,  0.98, 0.98, 0.12, 0.010),
            (0.20,  1.12, 1.10, 0.13, 0.008),
        ], 0.0, 360.0, m_hair, segs_u=14)
        _hair_shell("HairBobCurtain", [
            (0.18, 1.13, 1.12, 0.13, 0.010),
            (0.45, 1.18, 1.16, 0.14, 0.014),
            (0.75, 1.16, 1.12, 0.13, 0.018),
            (1.06, 1.08, 1.06, 0.12, 0.022),
            (1.22, 0.94, 0.92, 0.10, 0.026),
        ], 46.0, 314.0, m_hair, segs_u=14)
        # Side-parted forehead bangs
        _hair_shell("HairBobBangs", [
            (0.14, 1.08, 1.05, 0.10, 0.004),
            (0.28, 1.05, 1.03, 0.09, -0.002),
        ], -52.0, 48.0, m_hair, segs_u=8)

    elif hstyle == "bun":
        # Zuzana Horvathova (46): pulled-back sleek hair shell + rounded sculpted rear chignon bun!
        _hair_shell("HairPulledCrown", [
            (-0.01, 0.46, 0.48, 0.10, 0.012),
            (0.09,  0.96, 0.96, 0.11, 0.010),
            (0.22,  1.08, 1.08, 0.11, 0.010),
        ], 0.0, 360.0, m_hair, segs_u=14)
        _hair_shell("HairPulledBack", [
            (0.20, 1.08, 1.08, 0.11, 0.012),
            (0.48, 1.06, 1.06, 0.10, 0.014),
            (0.76, 0.92, 0.94, 0.09, 0.016),
        ], 48.0, 312.0, m_hair, segs_u=12)
        # Sculpted organic bun at back of skull
        bun_rings = [
            (-0.040 * h_sc, 0.028 * h_sc, 0.024 * h_sc, 0.0),
            (-0.015 * h_sc, 0.052 * h_sc, 0.044 * h_sc, 0.004),
            (0.018 * h_sc,  0.050 * h_sc, 0.042 * h_sc, 0.002),
            (0.042 * h_sc,  0.026 * h_sc, 0.022 * h_sc, -0.002),
        ]
        lp_loft(head_p, "HairChignonBun", bun_rings, m_hair, segs=10, loc=(0.0, sy * 1.24, base_z + sz * 0.56), smooth=True)

    elif hstyle == "cap":
        # Central European 1990s winter flat cap / peaked work cap + visible hair at nape
        m_cap = make_ps1_mat("PS1Cap", cfg.get("cap_col", (0.16, 0.18, 0.22)), tex_path=os.path.join(FACE_DIR, "ps1_cloth_wool.png"))
        _hair_shell("CapDome", [
            (-0.05, 0.45, 0.48, 0.12, 0.008),
            (0.04,  1.06, 1.08, 0.13, 0.006),
            (0.18,  1.15, 1.16, 0.13, 0.006),
            (0.29,  1.10, 1.12, 0.11, 0.008),
        ], 0.0, 360.0, m_cap, segs_u=14)
        # Curved brim/visor extending over forehead
        _hair_shell("CapVisorCurved", [
            (0.26, 1.12, 1.38, 0.14, -0.014),
            (0.32, 1.06, 1.56, 0.12, -0.022),
        ], -52.0, 52.0, m_cap, segs_u=8)
        # Hair peeking out at back/sides under cap
        _hair_shell("HairUnderCap", [
            (0.28, 1.05, 1.06, 0.09, 0.012),
            (0.55, 1.03, 1.03, 0.08, 0.012),
            (0.75, 0.88, 0.90, 0.07, 0.012),
        ], 58.0, 302.0, m_hair, segs_u=10)

    elif hstyle == "messy_youth":
        # Peter (12): fuller tousled young hair with layered bangs
        _hair_shell("HairYouthCrown", [
            (-0.04, 0.52, 0.54, 0.14, 0.010),
            (0.08,  1.06, 1.05, 0.15, 0.008),
            (0.24,  1.14, 1.12, 0.14, 0.006),
            (0.34,  1.08, 1.06, 0.12, 0.002),
        ], -62.0, 62.0, m_hair, segs_u=10)
        _hair_shell("HairYouthBack", [
            (0.10, 1.08, 1.08, 0.14, 0.012),
            (0.42, 1.12, 1.10, 0.13, 0.014),
            (0.74, 0.98, 0.98, 0.11, 0.014),
        ], 48.0, 312.0, m_hair, segs_u=12)

    elif hstyle == "slick_cropped":
        # Roman Kral (46): sharp, close-cropped brushed-back silhouette
        _hair_shell("HairCroppedCrown", [
            (-0.01, 0.44, 0.46, 0.08, 0.012),
            (0.09,  0.96, 0.98, 0.09, 0.012),
            (0.21,  1.06, 1.06, 0.09, 0.010),
        ], 0.0, 360.0, m_hair, segs_u=14)
        _hair_shell("HairCroppedSides", [
            (0.20, 1.06, 1.06, 0.08, 0.012),
            (0.48, 1.04, 1.04, 0.08, 0.012),
            (0.70, 0.90, 0.92, 0.07, 0.012),
        ], 54.0, 306.0, m_hair, segs_u=12)

    else:
        # Default "short_parted" / "tired_tousled" (Martin Kovac, Milan Svec)
        _hair_shell("HairShortCrown", [
            (-0.03, 0.48, 0.50, 0.12, 0.010),
            (0.08,  1.02, 1.02, 0.13, 0.008),
            (0.22,  1.10, 1.09, 0.12, 0.006),
        ], 0.0, 360.0, m_hair, segs_u=14)
        _hair_shell("HairShortBack", [
            (0.20, 1.10, 1.09, 0.12, 0.012),
            (0.48, 1.08, 1.07, 0.11, 0.014),
            (0.74, 0.93, 0.95, 0.09, 0.014),
        ], 50.0, 310.0, m_hair, segs_u=12)
        # Side-parted fringe sweep
        _hair_shell("HairShortFringe", [
            (0.16, 1.08, 1.06, 0.10, 0.002),
            (0.29, 1.06, 1.05, 0.09, -0.004),
        ], -48.0, 56.0, m_hair, segs_u=8)

    # Optional 3D wire-frame glasses (Zuzana)
    if cfg.get("glasses_3d", False):
        m_gl = make_ps1_mat("PS1Glasses", (0.14, 0.12, 0.11), metallic=0.5, roughness=0.4)
        gz = base_z + sz * 0.525
        gy = -sy * 1.04
        for side, gx in [("LensRim_L", -sx * 0.40), ("LensRim_R", sx * 0.40)]:
            lp_box(head_p, side + "_T", (sx * 0.44, 0.007, 0.006), m_gl, loc=(gx, gy, gz + 0.015))
            lp_box(head_p, side + "_B", (sx * 0.44, 0.007, 0.006), m_gl, loc=(gx, gy, gz - 0.015))
            lp_box(head_p, side + "_O", (0.006, 0.007, 0.032), m_gl, loc=(gx + (sx * 0.21 if gx > 0 else -sx * 0.21), gy, gz))
            lp_box(head_p, side + "_I", (0.006, 0.007, 0.032), m_gl, loc=(gx + (-sx * 0.21 if gx > 0 else sx * 0.21), gy, gz))
        lp_box(head_p, "GlassesBridge", (sx * 0.24, 0.007, 0.006), m_gl, loc=(0.0, gy - 0.004, gz + 0.004))


def build_ps1_character(cfg):
    clear_scene()
    root = make_empty(cfg["root_name"])

    # Coherent human proportions with subtle character individuality (no cartoon bobbleheads!)
    h_sc = float(cfg.get("height_scale", 1.0))
    w_sc = float(cfg.get("width_scale", 1.0))
    head_sc = float(cfg.get("head_scale", 1.02))
    arm_len = float(cfg.get("arm_scale", 1.02))
    stoop = float(cfg.get("stoop_rad", 0.03))
    asym_tilt = float(cfg.get("shoulder_asym", 0.015))

    face_tex = os.path.join(FACE_DIR, cfg["face_tex"])
    cloth_tex = os.path.join(FACE_DIR, cfg.get("cloth_tex", "ps1_cloth_navy.png"))
    hair_tex = os.path.join(FACE_DIR, cfg.get("hair_tex", "ps1_hair_dark.png"))

    m_face = make_ps1_mat("PS1Face", (1.0, 1.0, 1.0), tex_path=face_tex, roughness=0.88)
    m_skin = make_ps1_mat("PS1Skin", cfg["skin"], roughness=0.90)
    m_hair = make_ps1_mat("PS1Hair", (1.0, 1.0, 1.0) if os.path.exists(hair_tex) else cfg["hair"], tex_path=hair_tex, roughness=0.94)
    m_jacket = make_ps1_mat("PS1Jacket", cfg["jacket"], tex_path=cloth_tex, roughness=0.92)
    m_shirt = make_ps1_mat("PS1Shirt", cfg["shirt"], roughness=0.92)
    m_pants = make_ps1_mat("PS1Pants", cfg["pants"], tex_path=os.path.join(FACE_DIR, "ps1_cloth_navy.png"), roughness=0.94)
    m_shoes = make_ps1_mat("PS1Shoes", cfg.get("shoes", (0.08, 0.07, 0.07)), roughness=0.85)
    m_brass = make_ps1_mat("PS1Brass", (0.68, 0.54, 0.24), metallic=0.48, roughness=0.52)
    m_dark = make_ps1_mat("PS1Dark", (0.09, 0.09, 0.09), roughness=0.88)

    hip_z = 0.87 * h_sc
    torso_h = 0.56 * h_sc

    # Organic Contoured Pelvis & Belt
    pelvis_rings = [
        (-0.08 * h_sc, 0.145 * w_sc, 0.100 * w_sc, 0.0),
        (0.00 * h_sc,  0.168 * w_sc, 0.112 * w_sc, 0.004),
        (0.08 * h_sc,  0.158 * w_sc, 0.106 * w_sc, 0.002),
    ]
    lp_loft(root, "Pelvis", pelvis_rings, m_pants, segs=10, loc=(0, 0, hip_z), smooth=False)
    lp_loft(root, "Belt", [
        (-0.022, 0.166 * w_sc, 0.114 * w_sc, 0.002),
        (0.022,  0.166 * w_sc, 0.114 * w_sc, 0.002),
    ], m_dark, segs=10, loc=(0, 0, hip_z + 0.065 * h_sc))

    # Contoured Legs with Thigh, Knee Joint, Calf & Sculpted 1990s Boot!
    is_skirt = bool(cfg.get("skirt", False))
    if is_skirt:
        skirt_rings = [
            (-0.54 * h_sc, 0.23 * w_sc, 0.18 * w_sc, 0.005),
            (-0.28 * h_sc, 0.20 * w_sc, 0.15 * w_sc, 0.004),
            (0.02 * h_sc,  0.16 * w_sc, 0.11 * w_sc, 0.002),
        ]
        lp_loft(root, "Skirt", skirt_rings, m_pants, segs=10, loc=(0, 0, hip_z + 0.02))

    for side_name, sx_leg in [("LegL_Pivot", -0.092 * w_sc), ("LegR_Pivot", 0.092 * w_sc)]:
        leg_p = make_empty(side_name, root, loc=(sx_leg, 0, hip_z - 0.01))
        if not is_skirt:
            # Organic trouser leg with thigh taper -> knee joint -> calf -> ankle cuff
            leg_rings = [
                (-0.79 * h_sc, 0.048 * w_sc, 0.052 * w_sc, 0.006),  # Ankle cuff
                (-0.56 * h_sc, 0.058 * w_sc, 0.062 * w_sc, 0.008),  # Calf
                (-0.42 * h_sc, 0.056 * w_sc, 0.060 * w_sc, -0.006), # Knee joint (subtle forward curve)
                (-0.18 * h_sc, 0.076 * w_sc, 0.080 * w_sc, 0.000),  # Mid thigh
                (0.00 * h_sc,  0.082 * w_sc, 0.084 * w_sc, 0.000),  # Hip joint
            ]
            lp_loft(leg_p, side_name + "_Leg", leg_rings, m_pants, segs=8, smooth=False)
        else:
            calf_rings = [
                (-0.79 * h_sc, 0.036 * w_sc, 0.038 * w_sc, 0.004),
                (-0.58 * h_sc, 0.048 * w_sc, 0.050 * w_sc, 0.006),
                (-0.42 * h_sc, 0.044 * w_sc, 0.046 * w_sc, -0.002),
            ]
            lp_loft(leg_p, side_name + "_Calf", calf_rings, m_skin, segs=8, smooth=True)

        # Contoured winter boot / leather shoe (heel + vamp + rounded toe)
        boot_rings = [
            (-0.86 * h_sc, 0.052 * w_sc, 0.125 * h_sc, -0.038 * h_sc),
            (-0.82 * h_sc, 0.050 * w_sc, 0.118 * h_sc, -0.034 * h_sc),
            (-0.77 * h_sc, 0.046 * w_sc, 0.072 * h_sc, 0.002 * h_sc),
        ]
        lp_loft(leg_p, side_name + "_Boot", boot_rings, m_shoes, segs=8, smooth=False)

    # Organic Contoured Torso & 1990s Jacket Silhouette (waist -> ribcage -> broad chest -> collar/traps)
    torso_p = make_empty("TorsoPivot", root, loc=(0, 0, hip_z + 0.06 * h_sc), rot=(stoop, asym_tilt, 0))
    chest_w = float(cfg.get("chest_scale", 1.0))
    torso_rings = [
        (0.00 * torso_h, 0.168 * w_sc, 0.112 * w_sc, 0.004),          # Waist hem
        (0.28 * torso_h, 0.174 * w_sc, 0.118 * w_sc, 0.002),          # Lower ribs
        (0.62 * torso_h, 0.210 * w_sc * chest_w, 0.132 * w_sc, -0.004),  # Chest
        (0.88 * torso_h, 0.228 * w_sc * chest_w, 0.124 * w_sc, 0.002),   # Shoulders
        (1.01 * torso_h, 0.115 * w_sc, 0.095 * w_sc, 0.008),          # Collar / Trapezius base
    ]
    lp_loft(torso_p, "JacketTorso", torso_rings, m_jacket, segs=10, smooth=False)

    # Shirt / Sweater V-insert + Popped 1990s Collar Lapels
    lp_loft(torso_p, "ShirtCollar", [
        (torso_h * 0.45, 0.052 * w_sc, 0.025, 0.0),
        (torso_h * 0.92, 0.080 * w_sc, 0.030, 0.0),
    ], m_shirt, segs=6, loc=(0, -0.106 * w_sc, 0))
    lp_loft(torso_p, "JacketCollarRim", [
        (torso_h * 0.94, 0.106 * w_sc, 0.094 * w_sc, 0.006),
        (torso_h * 1.06, 0.112 * w_sc, 0.102 * w_sc, 0.010),
    ], m_jacket, segs=10, cap_top=False, cap_bottom=False)

    if cfg.get("long_coat", False):
        coat_rings = [
            (-0.34 * h_sc, 0.225 * w_sc, 0.150 * w_sc, 0.010),
            (-0.16 * h_sc, 0.205 * w_sc, 0.136 * w_sc, 0.008),
            (0.02 * h_sc,  0.175 * w_sc, 0.118 * w_sc, 0.004),
        ]
        lp_loft(torso_p, "CoatSkirt", coat_rings, m_jacket, segs=10)
    if cfg.get("apron", False):
        m_apron = make_ps1_mat("PS1Apron", (0.85, 0.92, 0.92), tex_path=os.path.join(FACE_DIR, "ps1_cloth_apron.png"))
        lp_box(torso_p, "ShopApron", (0.33 * w_sc, 0.028, 0.58 * h_sc), m_apron, loc=(0, -0.132 * w_sc, 0.08 * h_sc))
    if cfg.get("badge", False):
        lp_box(torso_p, "GuardBadge", (0.052, 0.015, 0.062), m_brass, loc=(0.105 * w_sc, -0.128 * w_sc, torso_h * 0.72))
    if cfg.get("keyring", False):
        lp_cyl(torso_p, "BeltKeyRing", 0.030, 0.030, 0.010, m_brass, segs=8, loc=(0.175 * w_sc, -0.02, -0.02), rot=(0, math.pi / 2, 0))
        lp_box(torso_p, "BeltKeys", (0.015, 0.042, 0.072), m_brass, loc=(0.185 * w_sc, -0.02, -0.065))
    if cfg.get("scarf", None):
        m_sc = make_ps1_mat("PS1Scarf", cfg["scarf"], tex_path=os.path.join(FACE_DIR, "ps1_cloth_wool.png"))
        lp_loft(torso_p, "Scarf", [
            (torso_h - 0.03, 0.118 * w_sc, 0.110 * w_sc, 0.002),
            (torso_h + 0.04, 0.112 * w_sc, 0.106 * w_sc, 0.002),
        ], m_sc, segs=10)
    if cfg.get("stripe", None):
        m_st = make_ps1_mat("PS1Stripe", cfg["stripe"])
        lp_loft(torso_p, "JacketStripe", [
            (torso_h * 0.58, 0.215 * w_sc, 0.136 * w_sc, -0.003),
            (torso_h * 0.72, 0.222 * w_sc, 0.134 * w_sc, -0.002),
        ], m_st, segs=10)

    # --- ORGANIC SCULPTED HEAD + SCULPTED HAIR (NO CUBE HEADS!) ---
    head_p = make_empty("HeadPivot", torso_p, loc=(0, 0, torso_h + 0.005))
    _, h_sx, h_sy, h_sz, h_base_z = build_organic_head(
        head_p, h_sc, head_sc, m_face, m_skin,
        jaw_w=float(cfg.get("jaw_width", 1.0)),
        nose_len=float(cfg.get("nose_len", 1.0)),
        cheek_w=float(cfg.get("cheek_width", 1.0)),
    )
    build_organic_hair(head_p, cfg.get("hair_style", "short_parted"), h_sx, h_sy, h_sz, h_base_z, h_sc, head_sc, m_hair, cfg)

    # --- ANATOMICAL ARMS: Rounded Shoulder Deltoid -> Upper Arm -> Elbow -> Tapered Forearm -> Sculpted Hand! ---
    hand_mat = m_dark if cfg.get("gloves", False) else m_skin
    arm_l = make_empty("ArmL_Pivot", torso_p, loc=(-0.228 * w_sc * chest_w, 0.004, torso_h * 0.88))
    arm_r = make_empty("ArmR_Pivot", torso_p, loc=(0.228 * w_sc * chest_w, 0.004, torso_h * 0.88))

    for ap, nm, sgn in [(arm_l, "L", -1.0), (arm_r, "R", 1.0)]:
        u_len = 0.285 * h_sc * arm_len
        f_len = 0.265 * h_sc * arm_len
        # Contoured sleeve with rounded deltoid cap, upper arm, slight elbow bend, tapered forearm & wrist cuff
        arm_rings = [
            (-(u_len + f_len),        0.036 * w_sc, 0.038 * w_sc, -0.044),  # Wrist cuff
            (-(u_len + f_len * 0.45), 0.045 * w_sc, 0.047 * w_sc, -0.022),  # Forearm muscle
            (-u_len,                  0.046 * w_sc, 0.048 * w_sc, 0.004),   # Elbow joint
            (-u_len * 0.45,           0.054 * w_sc, 0.056 * w_sc, 0.002),   # Bicep / sleeve
            (0.012 * h_sc,            0.062 * w_sc, 0.064 * w_sc, 0.000),   # Rounded deltoid shoulder cap
            (0.042 * h_sc,            0.036 * w_sc, 0.038 * w_sc, 0.002),   # Shoulder top dome
        ]
        lp_loft(ap, f"ArmSleeve_{nm}", arm_rings, m_jacket, segs=8, smooth=False)

        # Sculpted low-poly Hand (wrist -> palm -> tapered fingers + thumb!)
        hz_hand = -(u_len + f_len)
        hand_rings = [
            (hz_hand - 0.115 * h_sc, 0.020 * h_sc, 0.034 * h_sc, -0.060),  # Fingertips
            (hz_hand - 0.065 * h_sc, 0.024 * h_sc, 0.044 * h_sc, -0.056),  # Knuckles
            (hz_hand - 0.015 * h_sc, 0.026 * h_sc, 0.040 * h_sc, -0.048),  # Palm
            (hz_hand + 0.008 * h_sc, 0.028 * h_sc, 0.030 * h_sc, -0.044),  # Wrist
        ]
        lp_loft(ap, f"Hand_{nm}", hand_rings, hand_mat, segs=6, smooth=True)
        # Sculpted Thumb on inner front side of hand
        lp_cyl(ap, f"Thumb_{nm}", 0.010 * h_sc, 0.013 * h_sc, 0.046 * h_sc, hand_mat, segs=6,
               loc=(-sgn * 0.022 * h_sc, -0.075, hz_hand - 0.045 * h_sc), rot=(0.45, sgn * 0.25, 0))

    # Character Hand Props
    prop = cfg.get("hand_prop", "")
    if prop == "flashlight":
        m_torch = make_ps1_mat("VargaTorch", (0.14, 0.15, 0.16), metallic=0.45, roughness=0.55)
        m_lens = make_ps1_mat("VargaTorchLens", (0.96, 0.88, 0.62), roughness=0.25)
        ty = -0.145
        tz = -0.58 * h_sc * arm_len
        lp_cyl(arm_r, "VargaFlashlightBody", 0.022, 0.022, 0.22, m_torch, segs=8, loc=(0, ty, tz), rot=(math.pi / 2, 0, 0))
        lp_cyl(arm_r, "VargaFlashlightHead", 0.036, 0.025, 0.06, m_lens, segs=8, loc=(0, ty - 0.12, tz), rot=(math.pi / 2, 0, 0))
        make_empty("VargaFlashlightTip", arm_r, loc=(0, ty - 0.16, tz))
    elif prop == "shopping_bag":
        m_bag = make_ps1_mat("PS1Bag", (0.44, 0.34, 0.24), tex_path=os.path.join(FACE_DIR, "ps1_cloth_wool.png"))
        lp_box(arm_r, "ShoppingBag", (0.14, 0.25, 0.28), m_bag, loc=(0.04, -0.06, -0.74 * h_sc * arm_len), taper_top=0.88)
    elif prop == "grocery_bag":
        m_bag = make_ps1_mat("PS1GroceryBag", (0.56, 0.42, 0.26))
        lp_box(arm_r, "GroceryBag", (0.17, 0.23, 0.33), m_bag, loc=(0.05, -0.10, -0.60 * h_sc * arm_len), taper_top=0.92)
    elif prop == "tote_bag":
        m_bag = make_ps1_mat("PS1Tote", (0.28, 0.18, 0.16))
        lp_box(arm_l, "ToteBag", (0.12, 0.25, 0.25), m_bag, loc=(-0.04, -0.06, -0.72 * h_sc * arm_len), taper_top=0.88)
    elif prop == "crate":
        m_cr = make_ps1_mat("PS1Crate", (0.44, 0.32, 0.18))
        lp_box(arm_r, "DeliveryCrate", (0.34, 0.26, 0.22), m_cr, loc=(-0.22, -0.22, -0.46 * h_sc * arm_len))

    export_glb(root, cfg["filename"])


def build_ps1_iveta():
    clear_scene()
    root = make_empty("Char_Iveta_PS1")
    m_face = make_ps1_mat("IvetaFace", (1.0, 1.0, 1.0), tex_path=os.path.join(FACE_DIR, "ps1_face_iveta.png"))
    m_skin = make_ps1_mat("IvetaSkin", (0.59, 0.54, 0.50))
    m_hair = make_ps1_mat("IvetaHair", (1.0, 1.0, 1.0), tex_path=os.path.join(FACE_DIR, "ps1_hair_dark.png"))
    m_coat = make_ps1_mat("IvetaCoat", (0.38, 0.33, 0.27), tex_path=os.path.join(FACE_DIR, "ps1_cloth_wool.png"))
    m_pants = make_ps1_mat("IvetaPants", (0.14, 0.15, 0.18))
    m_dark = make_ps1_mat("IvetaDark", (0.10, 0.09, 0.09))
    m_bag = make_ps1_mat("IvetaBag", (0.30, 0.14, 0.12))
    m_paper = make_ps1_mat("IvetaDoc", (0.80, 0.76, 0.66))

    body = make_empty("IvetaPose", root, loc=(0, 0, 0.14), rot=(0.0, math.radians(88), math.radians(12)))
    lp_loft(body, "CoatBody", [
        (-0.28, 0.20, 0.13, 0.0),
        (0.02,  0.17, 0.11, 0.0),
        (0.42,  0.20, 0.12, 0.0),
        (0.54,  0.11, 0.09, 0.0),
    ], m_coat, segs=10)
    head_p = make_empty("HeadPivot", body, loc=(0, 0, 0.53))
    _, sx, sy, sz, bz = build_organic_head(head_p, 0.94, 1.00, m_face, m_skin, jaw_w=0.90, nose_len=0.92, cheek_w=0.94)
    build_organic_hair(head_p, "shoulder_bob", sx, sy, sz, bz, 0.94, 1.00, m_hair, {})

    lp_cyl(body, "LegL", 0.048, 0.068, 0.72, m_pants, segs=8, loc=(-0.08, 0.02, -0.52), rot=(0.18, 0, 0))
    lp_cyl(body, "LegR", 0.048, 0.068, 0.72, m_pants, segs=8, loc=(0.08, -0.03, -0.52), rot=(0.26, 0, 0))
    lp_cyl(body, "ArmL", 0.038, 0.048, 0.52, m_coat, segs=8, loc=(-0.20, -0.06, 0.26), rot=(0.40, 0.15, 0))
    lp_cyl(body, "ArmR", 0.038, 0.048, 0.52, m_coat, segs=8, loc=(0.20, -0.04, 0.24), rot=(0.25, -0.18, 0))

    lp_box(root, "IvetaHandbag", (0.28, 0.12, 0.20), m_bag, loc=(0.45, -0.42, 0.10), rot=(0.15, 0.10, 0.65))
    lp_box(root, "DamagedPhone", (0.18, 0.20, 0.09), m_dark, loc=(0.76, -0.28, 0.045), rot=(0, 0, -0.45))
    lp_box(root, "DetachedHandset", (0.22, 0.055, 0.048), m_dark, loc=(0.94, -0.44, 0.03), rot=(0.1, 0.0, 0.85))
    lp_box(root, "IvetaDoc", (0.22, 0.28, 0.012), m_paper, loc=(0.22, -0.52, 0.008), rot=(0, 0, 0.32))
    export_glb(root, "char_iveta.glb")


def build_ps1_fp_guard_body():
    clear_scene()
    root = make_empty("FP_GuardBody_PS1")
    m_jacket = make_ps1_mat("MartinPS1Jacket", (0.76, 0.82, 0.90), tex_path=os.path.join(FACE_DIR, "ps1_cloth_navy.png"))
    m_sweater = make_ps1_mat("MartinPS1Sweater", (0.30, 0.31, 0.33))
    m_trouser = make_ps1_mat("MartinPS1Pants", (0.10, 0.11, 0.14), tex_path=os.path.join(FACE_DIR, "ps1_cloth_navy.png"))
    m_dark = make_ps1_mat("MartinPS1Belt", (0.07, 0.06, 0.06))
    m_brass = make_ps1_mat("MartinPS1Brass", (0.68, 0.54, 0.24), metallic=0.48, roughness=0.48)

    lp_loft(root, "TorsoJacket", [
        (0.86, 0.175, 0.115, 0.02),
        (1.12, 0.205, 0.130, 0.018),
        (1.36, 0.220, 0.125, 0.020),
    ], m_jacket, segs=10)
    lp_box(root, "SweaterInsert", (0.14, 0.04, 0.26), m_sweater, loc=(0, -0.098, 1.24))
    lp_box(root, "MartinSecurityBadge", (0.052, 0.015, 0.062), m_brass, loc=(0.105, -0.108, 1.26))
    lp_loft(root, "UtilityBelt", [(0.84, 0.185, 0.122, 0.02), (0.895, 0.185, 0.122, 0.02)], m_dark, segs=10)
    lp_box(root, "BeltBuckle", (0.060, 0.022, 0.058), m_brass, loc=(0, -0.106, 0.87))
    lp_box(root, "RadioHolster", (0.070, 0.088, 0.12), m_dark, loc=(-0.20, 0.0, 0.84))
    lp_box(root, "KeyPouch", (0.068, 0.078, 0.095), m_dark, loc=(0.20, -0.02, 0.85))
    lp_loft(root, "PelvisTrousers", [(0.70, 0.155, 0.102, 0.02), (0.85, 0.172, 0.112, 0.02)], m_trouser, segs=10)

    for sx, side in [(-0.10, "L"), (0.10, "R")]:
        lp_loft(root, f"Leg_{side}", [
            (0.08, 0.050, 0.054, 0.012),
            (0.32, 0.060, 0.064, 0.014),
            (0.46, 0.058, 0.062, 0.002),
            (0.74, 0.080, 0.084, 0.010),
        ], m_trouser, segs=8, loc=(sx, 0.0, 0.0))
        lp_loft(root, f"BootFoot_{side}", [
            (0.00, 0.054, 0.130, -0.042),
            (0.05, 0.052, 0.122, -0.036),
            (0.09, 0.048, 0.074, 0.004),
        ], m_dark, segs=8, loc=(sx, 0.0, 0.0))
    export_glb(root, "fp_guard_body.glb")


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
        export_apply=False,
    )
    print(f"EXPORTED_ORGANIC_PS1_CHAR: {filename} ({os.path.getsize(out_path)} bytes)")


PS1_SPECS = [
    {
        "filename": "char_varga.glb", "root_name": "Char_JozefVarga_PS1",
        "face_tex": "ps1_face_varga.png", "cloth_tex": "ps1_cloth_navy.png", "hair_tex": "ps1_hair_grey.png",
        "height_scale": 1.02, "width_scale": 1.07, "chest_scale": 1.06, "head_scale": 1.04, "arm_scale": 1.02,
        "stoop_rad": 0.045, "shoulder_asym": 0.015, "jaw_width": 1.06, "nose_len": 1.08, "cheek_width": 1.04,
        "skin": (0.70, 0.56, 0.47), "hair": (0.34, 0.34, 0.35), "hair_style": "receding",
        "jacket": (0.64, 0.66, 0.72), "shirt": (0.68, 0.68, 0.64), "pants": (0.26, 0.27, 0.29),
        "badge": True, "keyring": True, "hand_prop": "flashlight",
    },
    {
        "filename": "char_martin.glb", "root_name": "Char_MartinKovac_PS1",
        "face_tex": "ps1_face_martin.png", "cloth_tex": "ps1_cloth_navy.png", "hair_tex": "ps1_hair_brown.png",
        "height_scale": 1.00, "width_scale": 0.98, "chest_scale": 1.00, "head_scale": 1.00, "arm_scale": 1.00,
        "stoop_rad": 0.02, "shoulder_asym": 0.01, "jaw_width": 0.98, "nose_len": 1.00, "cheek_width": 0.98,
        "skin": (0.72, 0.59, 0.50), "hair": (0.21, 0.16, 0.12), "hair_style": "short_parted",
        "jacket": (0.72, 0.78, 0.88), "shirt": (0.34, 0.35, 0.37), "pants": (0.14, 0.15, 0.18),
        "badge": True, "keyring": True,
    },
    {
        "filename": "char_anna.glb", "root_name": "Char_Anna_PS1",
        "face_tex": "ps1_face_anna.png", "cloth_tex": "ps1_cloth_wool.png", "hair_tex": "ps1_hair_silver.png",
        "height_scale": 0.90, "width_scale": 0.91, "chest_scale": 0.92, "head_scale": 1.03, "arm_scale": 1.00,
        "stoop_rad": 0.11, "shoulder_asym": -0.022, "jaw_width": 0.90, "nose_len": 0.96, "cheek_width": 0.98,
        "skin": (0.74, 0.61, 0.53), "hair": (0.69, 0.68, 0.66), "hair_style": "elder_curls",
        "jacket": (0.86, 0.80, 0.75), "shirt": (0.74, 0.70, 0.62), "pants": (0.16, 0.15, 0.17),
        "skirt": True, "scarf": (0.48, 0.34, 0.24), "hand_prop": "shopping_bag",
    },
    {
        "filename": "char_dana.glb", "root_name": "Char_Dana_PS1",
        "face_tex": "ps1_face_dana.png", "cloth_tex": "ps1_cloth_wool.png", "hair_tex": "ps1_hair_brown.png",
        "height_scale": 0.95, "width_scale": 0.88, "chest_scale": 0.92, "head_scale": 1.00, "arm_scale": 1.00,
        "stoop_rad": 0.02, "shoulder_asym": 0.012, "jaw_width": 0.88, "nose_len": 0.92, "cheek_width": 0.96,
        "skin": (0.75, 0.60, 0.51), "hair": (0.34, 0.24, 0.16), "hair_style": "shoulder_bob",
        "jacket": (0.84, 0.74, 0.66), "shirt": (0.72, 0.70, 0.66), "pants": (0.15, 0.16, 0.18),
        "apron": True,
    },
    {
        "filename": "char_zuzana.glb", "root_name": "Char_Zuzana_PS1",
        "face_tex": "ps1_face_zuzana.png", "cloth_tex": "ps1_cloth_burgundy.png", "hair_tex": "ps1_hair_dark.png",
        "height_scale": 0.94, "width_scale": 0.93, "chest_scale": 0.94, "head_scale": 1.00, "arm_scale": 1.00,
        "stoop_rad": 0.03, "shoulder_asym": -0.014, "jaw_width": 0.92, "nose_len": 0.96, "cheek_width": 0.96,
        "skin": (0.72, 0.58, 0.49), "hair": (0.19, 0.14, 0.11), "hair_style": "bun", "glasses_3d": True,
        "jacket": (0.84, 0.64, 0.66), "shirt": (0.70, 0.66, 0.60), "pants": (0.17, 0.17, 0.18),
    },
    {
        "filename": "char_peter.glb", "root_name": "Char_Peter_PS1",
        "face_tex": "ps1_face_peter.png", "cloth_tex": "ps1_cloth_apron.png", "hair_tex": "ps1_hair_brown.png",
        "height_scale": 0.78, "width_scale": 0.76, "chest_scale": 0.88, "head_scale": 1.12, "arm_scale": 0.98,
        "stoop_rad": 0.02, "shoulder_asym": 0.01, "jaw_width": 0.88, "nose_len": 0.84, "cheek_width": 1.02,
        "skin": (0.77, 0.64, 0.55), "hair": (0.26, 0.19, 0.12), "hair_style": "messy_youth",
        "jacket": (0.62, 0.86, 0.88), "stripe": (0.80, 0.56, 0.20), "shirt": (0.72, 0.72, 0.70), "pants": (0.18, 0.24, 0.34),
    },
    {
        "filename": "char_milan.glb", "root_name": "Char_Milan_PS1",
        "face_tex": "ps1_face_milan.png", "cloth_tex": "ps1_cloth_navy.png", "hair_tex": "ps1_hair_dark.png",
        "height_scale": 0.98, "width_scale": 0.90, "chest_scale": 0.95, "head_scale": 1.03, "arm_scale": 1.04,
        "stoop_rad": 0.10, "shoulder_asym": -0.028, "jaw_width": 0.94, "nose_len": 1.04, "cheek_width": 0.92,
        "skin": (0.64, 0.56, 0.51), "hair": (0.22, 0.16, 0.12), "hair_style": "short_parted",
        "jacket": (0.68, 0.70, 0.78), "shirt": (0.36, 0.35, 0.32), "pants": (0.13, 0.13, 0.15), "badge": True,
    },
    {
        "filename": "char_roman.glb", "root_name": "Char_RomanKral_PS1",
        "face_tex": "ps1_face_roman.png", "cloth_tex": "ps1_cloth_brown.png", "hair_tex": "ps1_hair_slate.png",
        "height_scale": 1.06, "width_scale": 1.06, "chest_scale": 1.08, "head_scale": 1.01, "arm_scale": 1.05,
        "stoop_rad": 0.055, "shoulder_asym": 0.028, "jaw_width": 1.08, "nose_len": 1.08, "cheek_width": 1.02,
        "skin": (0.65, 0.52, 0.45), "hair": (0.18, 0.18, 0.19), "hair_style": "slick_cropped",
        "jacket": (0.76, 0.64, 0.54), "shirt": (0.32, 0.32, 0.32), "pants": (0.15, 0.15, 0.14),
        "long_coat": True, "gloves": True, "keyring": True,
    },
    {
        "filename": "char_resident_a.glb", "root_name": "Char_ResidentA_PS1",
        "face_tex": "ps1_face_res_a.png", "cloth_tex": "ps1_cloth_olive.png", "hair_tex": "ps1_hair_grey.png",
        "height_scale": 0.97, "width_scale": 0.99, "chest_scale": 1.00, "head_scale": 1.02, "arm_scale": 1.00,
        "stoop_rad": 0.06, "shoulder_asym": -0.018, "jaw_width": 1.02, "nose_len": 1.04, "cheek_width": 1.00,
        "skin": (0.69, 0.56, 0.47), "hair": (0.46, 0.46, 0.44), "hair_style": "cap", "cap_col": (0.20, 0.22, 0.18),
        "jacket": (0.76, 0.80, 0.72), "shirt": (0.62, 0.58, 0.50), "pants": (0.20, 0.19, 0.18),
        "long_coat": True, "hand_prop": "grocery_bag",
    },
    {
        "filename": "char_resident_b.glb", "root_name": "Char_ResidentB_PS1",
        "face_tex": "ps1_face_res_b.png", "cloth_tex": "ps1_cloth_burgundy.png", "hair_tex": "ps1_hair_auburn.png",
        "height_scale": 0.92, "width_scale": 0.86, "chest_scale": 0.90, "head_scale": 1.00, "arm_scale": 1.00,
        "stoop_rad": 0.015, "shoulder_asym": 0.012, "jaw_width": 0.88, "nose_len": 0.92, "cheek_width": 0.96,
        "skin": (0.75, 0.61, 0.53), "hair": (0.38, 0.19, 0.12), "hair_style": "shoulder_bob",
        "jacket": (0.86, 0.64, 0.68), "shirt": (0.70, 0.68, 0.64), "pants": (0.16, 0.18, 0.24),
        "scarf": (0.60, 0.54, 0.42), "hand_prop": "tote_bag",
    },
    {
        "filename": "char_resident_c.glb", "root_name": "Char_ResidentC_PS1",
        "face_tex": "ps1_face_res_c.png", "cloth_tex": "ps1_cloth_navy.png", "hair_tex": "ps1_hair_dark.png",
        "height_scale": 1.01, "width_scale": 1.03, "chest_scale": 1.04, "head_scale": 1.01, "arm_scale": 1.02,
        "stoop_rad": 0.03, "shoulder_asym": -0.015, "jaw_width": 1.03, "nose_len": 1.02, "cheek_width": 1.00,
        "skin": (0.68, 0.54, 0.46), "hair": (0.20, 0.15, 0.11), "hair_style": "cap", "cap_col": (0.14, 0.18, 0.26),
        "jacket": (0.68, 0.80, 0.94), "shirt": (0.48, 0.46, 0.42), "pants": (0.14, 0.20, 0.30),
        "gloves": True, "hand_prop": "crate",
    },
    {
        "filename": "char_distant_figure.glb", "root_name": "Char_DistantFigure_PS1",
        "face_tex": "ps1_face_distant_a.png", "cloth_tex": "ps1_cloth_brown.png", "hair_tex": "ps1_hair_slate.png",
        "height_scale": 1.05, "width_scale": 0.96, "chest_scale": 0.98, "head_scale": 1.02, "arm_scale": 1.06,
        "stoop_rad": 0.07, "shoulder_asym": 0.025, "jaw_width": 0.96, "nose_len": 1.04, "cheek_width": 0.94,
        "skin": (0.50, 0.44, 0.40), "hair": (0.14, 0.14, 0.14), "hair_style": "cap", "cap_col": (0.10, 0.11, 0.12),
        "jacket": (0.34, 0.35, 0.38), "shirt": (0.18, 0.18, 0.18), "pants": (0.10, 0.10, 0.11),
        "long_coat": True, "gloves": True,
    },
]


if __name__ == "__main__":
    for spec in PS1_SPECS:
        build_ps1_character(spec)
    build_ps1_iveta()
    build_ps1_fp_guard_body()
    print("ALL_ORGANIC_PS1_CHARACTERS_EXPORTED=14")
