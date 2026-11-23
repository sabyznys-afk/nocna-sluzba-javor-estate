r"""
Prompt 09 Part 2.4 & 2.5 — Detailed Pixelated Character Face, Hair & Cloth Texture Generator:
Generates intentionally crafted, anatomically mapped PS1-era pixel-art face textures wrapped onto
organic low-poly human heads (cylindrical-frontal UV layout: u=0.5 front nose, u=0.35/0.65 eyes):
  - 256x256 for major characters (Jozef Varga, Martin Kovac, Anna Krizanova, Dana Bielikova,
    Milan Svec, Roman Kral, Iveta Hroncova)
  - 128x128 for ordinary NPCs (Zuzana, Peter, Resident A/B/C)
  - 64x64 for distant silhouette/anomaly figures (Distant A/B)
  - Pixelated hair strand textures & 1990s woven coat/wool/uniform fabric textures.
"""
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageEnhance

TEX_DIR = r"D:\nocna-zmena-blok-14\assets\textures"
FACE_DIR = os.path.join(TEX_DIR, "ps1_faces")
os.makedirs(FACE_DIR, exist_ok=True)

BAYER_4X4 = np.array([
    [0,  8,  2, 10],
    [12, 4, 14,  6],
    [3, 11,  1,  9],
    [15, 7, 13,  5],
], dtype=np.float32) / 16.0 - 0.5


def ps1_dither_quantize(pil_img: Image.Image, levels: int = 18, sat: float = 0.88, contrast: float = 1.12) -> Image.Image:
    im = ImageEnhance.Color(pil_img.convert("RGB")).enhance(sat)
    im = ImageEnhance.Contrast(im).enhance(contrast)
    arr = np.asarray(im, dtype=np.float32) / 255.0
    h, w, _ = arr.shape
    by = np.tile(BAYER_4X4, (h // 4 + 1, w // 4 + 1))[:h, :w]
    dithered = arr + (by[:, :, None] * 0.55) / float(levels)
    quant = np.floor(np.clip(dithered, 0.0, 1.0) * levels + 0.5) / float(levels)
    return Image.fromarray((quant * 255.0).astype(np.uint8), mode="RGB")


def draw_organic_pixel_face(filename: str, cfg: dict):
    """
    Renders a full cylindrical-frontal mapped face texture at 256x256, 128x128, or 64x64.
    UV Convention matching build_ps1_characters.py _build_organic_head():
      u in [0..1]: 0.50 = center front (nose/mouth), 0.36 & 0.64 = eyes, 0.21 & 0.79 = temples/ears, 0.0/1.0 = back skull
      v in [0..1] (image y = (1 - v) * H):
        y/H ~ 0.00..0.24 = crown/forehead hairline
        y/H ~ 0.24..0.38 = forehead
        y/H ~ 0.38..0.44 = brow ridge / eyebrows
        y/H ~ 0.44..0.53 = eyes (sclera, iris, pupil, eyelids, under-eye shadow)
        y/H ~ 0.50..0.67 = nose bridge, sides, tip & nostrils
        y/H ~ 0.68..0.77 = philtrum & mouth (upper lip, crease, lower lip)
        y/H ~ 0.78..0.90 = chin & jawline shadow
        y/H ~ 0.90..1.00 = sub-chin / neck transition
    """
    size = int(cfg.get("res", 128))
    W = H = size
    rng = np.random.default_rng(abs(hash(filename + "_p9")) % 999983)
    skin = np.array(cfg["skin"], dtype=np.float32)
    hair = np.array(cfg["hair"], dtype=np.float32)

    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    u = xx / float(W)
    vy = yy / float(H)  # 0 at top, 1 at bottom

    # Base organic skin canvas with anatomical 3D-aligned shading
    img = np.ones((H, W, 3), dtype=np.float32) * skin[None, None, :]

    # Distance from front center (u=0.5)
    du = np.abs(u - 0.5)

    # 1. Cranial wrap darkening toward temples/back + warm rosiness on cheeks/nose
    side_shade = np.clip(1.0 - 0.52 * (du / 0.5) ** 1.7, 0.52, 1.0)
    top_shade = np.where(vy < 0.20, 0.86 + 0.14 * (vy / 0.20), 1.0)
    jaw_shade = np.where(vy > 0.78, 1.0 - 0.36 * np.clip((vy - 0.78) / 0.22, 0.0, 1.0), 1.0)
    img *= (side_shade * top_shade * jaw_shade)[:, :, None]

    # 2. Forehead & cheekbone highlights (subtle light planes)
    fh_hi = np.exp(-(((u - 0.5) / 0.14) ** 2 + ((vy - 0.31) / 0.08) ** 2)) * 16.0
    chk_l = np.exp(-(((u - 0.36) / 0.065) ** 2 + ((vy - 0.59) / 0.07) ** 2))
    chk_r = np.exp(-(((u - 0.64) / 0.065) ** 2 + ((vy - 0.59) / 0.07) ** 2))
    cheek_warm = (chk_l + chk_r) * float(cfg.get("cheek_warmth", 1.0))
    img[:, :, 0] += fh_hi + cheek_warm * 14.0
    img[:, :, 1] += fh_hi * 0.92 + cheek_warm * 5.0
    img[:, :, 2] += fh_hi * 0.84 + cheek_warm * 3.0

    # 3. Eye socket orbital recesses & cheekbone hollows
    soc_l = np.exp(-(((u - 0.39) / 0.060) ** 2 + ((vy - 0.475) / 0.055) ** 2))
    soc_r = np.exp(-(((u - 0.61) / 0.060) ** 2 + ((vy - 0.475) / 0.055) ** 2))
    tired_k = float(cfg.get("tired", 0.35))
    socket_shadow = (soc_l + soc_r) * (0.20 + 0.16 * tired_k)
    img *= np.clip(1.0 - socket_shadow, 0.55, 1.0)[:, :, None]

    # Cheek hollow under zygomatic arch (gives strong low-poly human skull structure!)
    hol_l = np.exp(-(((u - 0.31) / 0.055) ** 2 + ((vy - 0.69) / 0.085) ** 2))
    hol_r = np.exp(-(((u - 0.69) / 0.055) ** 2 + ((vy - 0.69) / 0.085) ** 2))
    img *= np.clip(1.0 - (hol_l + hol_r) * 0.17, 0.65, 1.0)[:, :, None]

    # 4. Nose bridge highlight + nose side slope shadows + under-nose shadow
    nose_hi = np.exp(-(((u - 0.50) / 0.017) ** 2 + ((vy - 0.57) / 0.095) ** 2)) * 20.0
    nose_sh_l = np.exp(-(((u - 0.468) / 0.018) ** 2 + ((vy - 0.57) / 0.085) ** 2)) * 0.22
    nose_sh_r = np.exp(-(((u - 0.532) / 0.018) ** 2 + ((vy - 0.57) / 0.085) ** 2)) * 0.22
    nose_under = np.exp(-(((u - 0.50) / 0.042) ** 2 + ((vy - 0.655) / 0.020) ** 2)) * 0.34
    img += nose_hi[:, :, None]
    img *= np.clip(1.0 - nose_sh_l - nose_sh_r - nose_under, 0.55, 1.0)[:, :, None]

    # Chin highlight
    chin_hi = np.exp(-(((u - 0.50) / 0.050) ** 2 + ((vy - 0.82) / 0.045) ** 2)) * 13.0
    img += chin_hi[:, :, None]

    # Subtle organic mottled skin texture (pixel-scale pore/tone variation)
    coarse = rng.normal(0.0, 5.2, (max(8, H // 2), max(8, W // 2), 1))
    coarse_up = np.repeat(np.repeat(coarse, 2, axis=0), 2, axis=1)[:H, :W, :]
    fine = rng.normal(0.0, 3.0, (H, W, 1))
    img = np.clip(img + coarse_up + fine, 0.0, 255.0)

    # Back-of-head & crown hair base blend (seamless beneath 3D hair shell!)
    hair_mask = np.zeros((H, W), dtype=np.float32)
    hairline_y = float(cfg.get("hairline_y", 0.24))
    receding = bool(cfg.get("receding", False))
    for xi in range(W):
        ui = xi / float(W)
        # Higher hairline in center if receding, curving down toward temples & back!
        d_front = abs(ui - 0.5)
        if d_front < 0.24:
            edge = hairline_y - (0.065 * math.cos(d_front / 0.24 * math.pi * 0.5) if receding else 0.015 * math.sin(d_front * 22.0))
        elif d_front < 0.34:
            # Sideburns / temple taper
            t_side = (d_front - 0.24) / 0.10
            edge = hairline_y + t_side * 0.28
        else:
            # Back of skull covered down to nape
            edge = 0.78
        col_y = np.arange(H, dtype=np.float32) / float(H)
        # Pixelated hair strand variation along edge
        jitter = (rng.random() - 0.5) * 0.025
        hair_mask[:, xi] = np.clip((edge + jitter - col_y) * 32.0, 0.0, 1.0)

    # Textured hair strand lines
    strand = np.sin(xx * (1.2 if W >= 128 else 2.0) + np.sin(yy * 0.15) * 1.5) * 14.0
    hair_tex = np.clip(hair[None, None, :] + strand[:, :, None] + rng.normal(0, 5.0, (H, W, 1)), 0.0, 255.0)
    img = img * (1.0 - hair_mask[:, :, None]) + hair_tex * hair_mask[:, :, None]

    pil = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), mode="RGB")
    dr = ImageDraw.Draw(pil)

    def px(fx):
        return int(round(fx * W))

    def py(fy):
        return int(round(fy * H))

    def sc(v):
        return max(1, int(round(v * (W / 128.0))))

    hair_col = tuple(int(c) for c in cfg["hair"])
    brow_col = tuple(max(12, int(c * 0.78)) for c in cfg["hair"])
    dark_skin = tuple(max(15, int(c * 0.56)) for c in cfg["skin"])
    mid_shadow = tuple(max(18, int(c * 0.70)) for c in cfg["skin"])
    iris_col = tuple(int(c) for c in cfg.get("iris", (58, 72, 82)))
    lip_col = tuple(int(c) for c in cfg.get("lip", (142, 88, 82)))
    lip_dark = tuple(max(20, int(c * 0.52)) for c in lip_col)
    lip_hi = tuple(min(235, int(c * 1.18)) for c in lip_col)

    asym_y = float(cfg.get("asym_y", 0.004))

    # --- EYES (Detailed pixel anatomy: lid crease, lash line, sclera, iris, pupil, catchlight, under-eye) ---
    eye_specs = [
        (0.395, 0.470, -1),  # Left eye (viewer left)
        (0.605, 0.470 + asym_y, 1),  # Right eye
    ]
    for ex, ey, sgn in eye_specs:
        ew = 0.056
        eh = 0.026
        x0, x1 = px(ex - ew), px(ex + ew)
        y0, y1 = py(ey - eh), py(ey + eh)

        # Upper eyelid fold shadow
        dr.arc([x0 - sc(2), y0 - sc(5), x1 + sc(2), y1 + sc(1)], start=190, end=350, fill=dark_skin, width=sc(1.5))

        # Sclera (warm realistic off-white, slightly darker at corners)
        sclera_edge = (176, 168, 158)
        sclera_mid = (212, 208, 198)
        dr.ellipse([x0, y0, x1, y1], fill=sclera_edge)
        dr.ellipse([x0 + sc(2), y0 + sc(1), x1 - sc(2), y1 - sc(1)], fill=sclera_mid)

        # Iris ring + dark pupil + tiny catchlight
        ir_r = max(2, px(0.022))
        cx, cy = px(ex - sgn * 0.002), py(ey + 0.001)
        iris_ring = tuple(max(10, int(c * 0.60)) for c in iris_col)
        dr.ellipse([cx - ir_r, cy - ir_r, cx + ir_r, cy + ir_r], fill=iris_ring)
        if ir_r >= 3:
            dr.ellipse([cx - ir_r + 1, cy - ir_r + 1, cx + ir_r - 1, cy + ir_r - 1], fill=iris_col)
        pu_r = max(1, int(round(ir_r * 0.52)))
        dr.ellipse([cx - pu_r, cy - pu_r, cx + pu_r, cy + pu_r], fill=(16, 16, 20))
        # Subtle catchlight pixel (adds life & eerie focus under flashlight!)
        if W >= 128 and not cfg.get("hollow_eyes", False):
            cl = max(1, sc(0.8))
            dr.rectangle([cx - pu_r, cy - pu_r, cx - pu_r + cl - 1, cy - pu_r + cl - 1], fill=(224, 224, 218))

        # Upper lash rim (thick dark pixel outline) + subtle lower rim
        dr.arc([x0 - sc(1), y0 - sc(1), x1 + sc(1), y1], start=190, end=350, fill=(28, 22, 20), width=sc(2.0))
        dr.arc([x0, y0 + sc(1), x1, y1 + sc(1)], start=20, end=160, fill=mid_shadow, width=sc(1.2))

        # Tired lower eye bag line
        if tired_k >= 0.35:
            dr.arc([x0 - sc(1), y0 + sc(3), x1 + sc(1), y1 + sc(5)], start=25, end=155, fill=dark_skin, width=sc(1.0))

    # --- EYEBROWS (Shaped pixel strokes matching character temperament) ---
    brow_thick = sc(float(cfg.get("brow_thick", 2.6)))
    brow_arch = float(cfg.get("brow_arch", 0.012))
    # Left brow
    dr.line([
        (px(0.325), py(0.418)),
        (px(0.382), py(0.408 - brow_arch)),
        (px(0.452), py(0.416)),
    ], fill=brow_col, width=brow_thick, joint="curve")
    # Right brow
    dr.line([
        (px(0.548), py(0.416 + asym_y)),
        (px(0.618), py(0.408 - brow_arch + asym_y)),
        (px(0.675), py(0.418 + asym_y)),
    ], fill=brow_col, width=brow_thick, joint="curve")

    # --- NOSE DETAILS (Nostrils & alar creases matching 3D sculpted nose) ---
    dr.ellipse([px(0.464), py(0.630), px(0.488), py(0.646)], fill=(38, 26, 24))
    dr.ellipse([px(0.512), py(0.630), px(0.536), py(0.646)], fill=(38, 26, 24))
    dr.arc([px(0.448), py(0.605), px(0.478), py(0.648)], start=110, end=250, fill=dark_skin, width=sc(1.2))
    dr.arc([px(0.522), py(0.605), px(0.552), py(0.648)], start=290, end=70, fill=dark_skin, width=sc(1.2))

    # --- MOUTH (Upper lip, defined crease, fuller lower lip & chin dimple shadow) ---
    mw = float(cfg.get("mouth_w", 0.072))
    my = 0.728
    # Upper lip bow
    dr.polygon([
        (px(0.50 - mw), py(my)),
        (px(0.50 - mw * 0.35), py(my - 0.016)),
        (px(0.50), py(my - 0.010)),
        (px(0.50 + mw * 0.35), py(my - 0.016)),
        (px(0.50 + mw), py(my)),
        (px(0.50), py(my + 0.005)),
    ], fill=lip_col)
    # Lower lip
    dr.polygon([
        (px(0.50 - mw * 0.90), py(my + 0.003)),
        (px(0.50), py(my + 0.022)),
        (px(0.50 + mw * 0.90), py(my + 0.003)),
    ], fill=lip_hi)
    # Mouth line / parting crease
    dr.line([
        (px(0.50 - mw), py(my + 0.002)),
        (px(0.50), py(my + 0.005)),
        (px(0.50 + mw), py(my + 0.002)),
    ], fill=lip_dark, width=sc(1.4))
    # Under-lip chin shadow
    dr.line([(px(0.46), py(my + 0.032)), (px(0.54), py(my + 0.032))], fill=dark_skin, width=sc(1.2))

    # --- AGE WRINKLES (Subtle weathered creases blended naturally into skin tone) ---
    age_lvl = float(cfg.get("age_wrinkles", 0.0))
    if age_lvl > 0.0:
        w_col = tuple(max(20, int(c * 0.72)) for c in cfg["skin"])
        w_soft = tuple(max(20, int(c * 0.80)) for c in cfg["skin"])
        w_thick = max(1, sc(0.9))
        # Slightly curved forehead creases
        dr.arc([px(0.35), py(0.295), px(0.65), py(0.365)], start=200, end=340, fill=w_col, width=w_thick)
        dr.arc([px(0.38), py(0.330), px(0.62), py(0.390)], start=205, end=335, fill=w_soft, width=w_thick)
        # Subtle frown creases between brows
        dr.line([(px(0.487), py(0.400)), (px(0.487), py(0.432))], fill=w_col, width=w_thick)
        dr.line([(px(0.513), py(0.400)), (px(0.513), py(0.432))], fill=w_col, width=w_thick)
        # Soft curved nasolabial folds
        dr.arc([px(0.390), py(0.615), px(0.470), py(0.790)], start=145, end=235, fill=w_col, width=w_thick)
        dr.arc([px(0.530), py(0.615), px(0.610), py(0.790)], start=305, end=35, fill=w_col, width=w_thick)
        if age_lvl >= 0.8:
            # Subtle crow's feet & gentle cheek lines for older residents (Anna / Jozef)
            dr.line([(px(0.320), py(0.468)), (px(0.340), py(0.474))], fill=w_soft, width=w_thick)
            dr.line([(px(0.680), py(0.468)), (px(0.660), py(0.474))], fill=w_soft, width=w_thick)
            dr.line([(px(0.428), py(0.746)), (px(0.420), py(0.796))], fill=w_soft, width=w_thick)
            dr.line([(px(0.572), py(0.746)), (px(0.580), py(0.796))], fill=w_soft, width=w_thick)

    # --- STUBBLE / BEARD SHADOW / MUSTACHE (Organic elliptical feathering, zero box seam!) ---
    stubble_lvl = float(cfg.get("stubble", 0.0))
    if stubble_lvl > 0.0:
        arr_st = np.array(pil, dtype=np.float32)
        # Smooth anatomical jaw + chin + upper-lip beard ellipse
        jaw_dist = np.sqrt(((u - 0.50) / 0.19) ** 2 + ((vy - 0.80) / 0.13) ** 2)
        jaw_w = np.clip(1.0 - (jaw_dist - 0.55) / 0.55, 0.0, 1.0)
        lip_dist = np.sqrt(((u - 0.50) / 0.09) ** 2 + ((vy - 0.70) / 0.035) ** 2)
        lip_w = np.clip(1.0 - lip_dist, 0.0, 1.0) * 0.8
        beard_w = np.maximum(jaw_w, lip_w)
        # Exclude lips smoothly
        in_lips = (vy > 0.708) & (vy < 0.752) & (du < mw * 1.02)
        beard_w = np.where(in_lips, 0.0, beard_w)
        dots = rng.random((H, W)) < (0.45 * stubble_lvl * beard_w)
        arr_st[dots] *= (1.0 - 0.28 * stubble_lvl)
        arr_st *= (1.0 - 0.12 * stubble_lvl * beard_w)[:, :, None]
        pil = Image.fromarray(np.clip(arr_st, 0, 255).astype(np.uint8), mode="RGB")
        dr = ImageDraw.Draw(pil)

    if cfg.get("mustache", False):
        # Weathered 1990s Central European mustache (Jozef Varga!)
        m_col = tuple(max(24, int(c * 0.90)) for c in hair_col)
        m_hi = tuple(min(220, int(c * 1.12)) for c in hair_col)
        dr.polygon([
            (px(0.424), py(0.716)),
            (px(0.466), py(0.684)),
            (px(0.534), py(0.684)),
            (px(0.576), py(0.716)),
            (px(0.552), py(0.720)),
            (px(0.500), py(0.703)),
            (px(0.448), py(0.720)),
        ], fill=m_col)
        dr.line([(px(0.450), py(0.696)), (px(0.550), py(0.696))], fill=m_hi, width=max(1, sc(0.8)))

    # --- WEATHERED HEALED FACIAL SCAR (Roman Kral — organic tapered skin scar, not a paint bar) ---
    if cfg.get("scar", False):
        dr.line([(px(0.352), py(0.538)), (px(0.398), py(0.625)), (px(0.420), py(0.668))], fill=(128, 86, 78), width=sc(1.8))
        dr.line([(px(0.357), py(0.540)), (px(0.402), py(0.626)), (px(0.423), py(0.668))], fill=(192, 158, 146), width=sc(0.9))

    # --- SUBTLE PIXELATED GLASSES FRAME ON TEXTURE (Zuzana also gets 3D frames in Blender) ---
    if cfg.get("glasses", False):
        gc = (38, 34, 30)
        dr.rectangle([px(0.325), py(0.432), px(0.465), py(0.520)], outline=gc, width=sc(1.5))
        dr.rectangle([px(0.535), py(0.432), px(0.675), py(0.520)], outline=gc, width=sc(1.5))
        dr.line([(px(0.465), py(0.468)), (px(0.535), py(0.468))], fill=gc, width=sc(1.5))

    # Quantize & apply PS1 ordered dithering so it looks crisply hand-crafted in-engine!
    out = ps1_dither_quantize(pil, levels=20 if size >= 256 else 16, sat=0.88, contrast=1.10)
    out.save(os.path.join(FACE_DIR, filename))
    return size


def build_hair_and_cloth_textures():
    rng = np.random.default_rng(199609)

    # 128x128 Pixelated Hair Strand Swatches (gives hair real directional pixel texture!)
    hair_swatches = {
        "ps1_hair_grey.png":   ((94, 94, 96),   (58, 58, 62)),
        "ps1_hair_silver.png": ((176, 174, 168),(126, 124, 118)),
        "ps1_hair_brown.png":  ((86, 58, 38),   (48, 30, 18)),
        "ps1_hair_dark.png":   ((44, 34, 28),   (22, 18, 16)),
        "ps1_hair_auburn.png": ((104, 52, 34),  (62, 30, 20)),
        "ps1_hair_slate.png":  ((54, 54, 56),   (30, 30, 34)),
    }
    for fn, (c1, c2) in hair_swatches.items():
        W = H = 64
        arr = np.zeros((H, W, 3), dtype=np.float32)
        for x in range(W):
            col_bias = rng.uniform(-0.18, 0.18)
            for y in range(H):
                wave = 0.5 + 0.5 * math.sin(x * 0.95 + math.sin(y * 0.14) * 1.6)
                mix = np.clip(wave * 0.65 + col_bias + rng.uniform(0.0, 0.25), 0.0, 1.0)
                arr[y, x] = [c1[k] * mix + c2[k] * (1.0 - mix) for k in range(3)]
        out = ps1_dither_quantize(Image.fromarray(arr.astype(np.uint8)), levels=14, sat=0.88, contrast=1.12)
        out.save(os.path.join(FACE_DIR, fn))

    # 128x128 Pixelated 1990s Central European Fabric Weave Textures
    fabrics = {
        "ps1_cloth_navy.png":     ((36, 46, 66),  (22, 28, 42)),
        "ps1_cloth_brown.png":    ((68, 48, 34),  (42, 30, 22)),
        "ps1_cloth_wool.png":     ((112, 92, 78), (78, 62, 52)),
        "ps1_cloth_apron.png":    ((48, 96, 98),  (32, 68, 70)),
        "ps1_cloth_olive.png":    ((64, 72, 54),  (42, 48, 36)),
        "ps1_cloth_burgundy.png": ((94, 42, 46),  (60, 24, 28)),
    }
    for fn, (c1, c2) in fabrics.items():
        W = H = 128
        arr = np.zeros((H, W, 3), dtype=np.float32)
        for y in range(H):
            for x in range(W):
                twill = 1.0 if ((x + y) % 4 < 2) else 0.0
                seam = 0.72 if (x % 32 == 0 or y % 32 == 0) else 1.0
                mix = np.clip(twill * 0.45 + rng.uniform(0.15, 0.55), 0.0, 1.0)
                arr[y, x] = [(c1[k] * mix + c2[k] * (1.0 - mix)) * seam for k in range(3)]
        out = ps1_dither_quantize(Image.fromarray(arr.astype(np.uint8)), levels=14, sat=0.85, contrast=1.10)
        out.save(os.path.join(FACE_DIR, fn))

    print(f"GENERATED_P9_HAIR_SWATCHES={len(hair_swatches)} FABRICS={len(fabrics)}")


def main():
    specs = {
        # 256x256 Major Characters
        "ps1_face_varga.png":  {"res": 256, "skin": (180, 144, 120), "hair": (86, 86, 90),   "iris": (74, 88, 98),   "receding": True,  "age_wrinkles": 0.85, "tired": 0.45, "stubble": 0.45, "mustache": True,  "brow_thick": 3.4, "asym_y": 0.004},
        "ps1_face_martin.png": {"res": 256, "skin": (184, 150, 128), "hair": (54, 40, 30),   "iris": (72, 84, 68),   "receding": False, "age_wrinkles": 0.15, "tired": 0.55, "stubble": 0.35, "brow_thick": 2.6, "asym_y": 0.002},
        "ps1_face_anna.png":   {"res": 256, "skin": (188, 156, 136), "hair": (176, 174, 168),"iris": (86, 102, 112), "receding": False, "age_wrinkles": 1.0,  "tired": 0.40, "hairline_y": 0.25, "lip": (146, 96, 92), "brow_thick": 1.8, "brow_arch": 0.018, "asym_y": 0.003},
        "ps1_face_dana.png":   {"res": 256, "skin": (190, 152, 130), "hair": (88, 60, 40),   "iris": (88, 62, 46),   "receding": False, "age_wrinkles": 0.35, "tired": 0.50, "hairline_y": 0.23, "lip": (152, 82, 80), "brow_thick": 2.0, "brow_arch": 0.016, "cheek_warmth": 1.2, "asym_y": 0.002},
        "ps1_face_milan.png":  {"res": 256, "skin": (162, 142, 130), "hair": (56, 42, 32),   "iris": (64, 58, 52),   "receding": False, "age_wrinkles": 0.65, "tired": 0.90, "stubble": 0.78, "brow_thick": 2.8, "cheek_warmth": 0.4, "asym_y": 0.005},
        "ps1_face_roman.png":  {"res": 256, "skin": (166, 134, 114), "hair": (46, 46, 48),   "iris": (66, 74, 78),   "receding": False, "age_wrinkles": 0.60, "tired": 0.65, "stubble": 0.62, "scar": True, "brow_thick": 3.6, "brow_arch": -0.006, "cheek_warmth": 0.5, "asym_y": 0.005},
        "ps1_face_iveta.png":  {"res": 256, "skin": (150, 138, 128), "hair": (54, 36, 26),   "iris": (56, 62, 66),   "receding": False, "age_wrinkles": 0.30, "tired": 0.85, "lip": (118, 86, 86), "hollow_eyes": True, "cheek_warmth": 0.2, "asym_y": 0.002},

        # 128x128 Ordinary Estate NPCs
        "ps1_face_zuzana.png": {"res": 128, "skin": (184, 148, 126), "hair": (48, 36, 28),   "iris": (78, 62, 48),   "age_wrinkles": 0.50, "tired": 0.45, "glasses": True, "lip": (144, 86, 84), "brow_thick": 2.0, "brow_arch": 0.015, "asym_y": 0.003},
        "ps1_face_peter.png":  {"res": 128, "skin": (196, 162, 140), "hair": (68, 48, 32),   "iris": (72, 92, 76),   "age_wrinkles": 0.0,  "tired": 0.12, "cheek_warmth": 1.35, "brow_thick": 2.0, "mouth_w": 0.064, "asym_y": 0.001},
        "ps1_face_res_a.png":  {"res": 128, "skin": (176, 142, 118), "hair": (118, 116, 112),"iris": (68, 76, 80),   "age_wrinkles": 0.80, "tired": 0.45, "stubble": 0.40, "brow_thick": 3.0, "asym_y": 0.004},
        "ps1_face_res_b.png":  {"res": 128, "skin": (192, 156, 136), "hair": (98, 48, 32),   "iris": (74, 88, 66),   "age_wrinkles": 0.15, "tired": 0.30, "lip": (150, 84, 82), "brow_thick": 1.9, "brow_arch": 0.016, "cheek_warmth": 1.15, "asym_y": 0.002},
        "ps1_face_res_c.png":  {"res": 128, "skin": (172, 138, 116), "hair": (52, 38, 28),   "iris": (66, 56, 48),   "age_wrinkles": 0.40, "tired": 0.50, "stubble": 0.55, "brow_thick": 2.8, "asym_y": 0.003},

        # 64x64 Distant Silhouette / Encounter Figures
        "ps1_face_distant_a.png": {"res": 64, "skin": (132, 114, 102), "hair": (36, 34, 34), "iris": (30, 32, 34), "tired": 0.85, "hollow_eyes": True, "cheek_warmth": 0.2},
        "ps1_face_distant_b.png": {"res": 64, "skin": (122, 108, 98),  "hair": (44, 38, 34), "iris": (28, 30, 32), "tired": 0.90, "hollow_eyes": True, "cheek_warmth": 0.2},
    }

    counts = {256: 0, 128: 0, 64: 0}
    for fn, cfg in specs.items():
        r = draw_organic_pixel_face(fn, cfg)
        counts[r] = counts.get(r, 0) + 1
    build_hair_and_cloth_textures()
    print(f"GENERATED_P9_FACES_TOTAL={len(specs)} (256px={counts[256]}, 128px={counts[128]}, 64px={counts[64]})")


if __name__ == "__main__":
    main()
