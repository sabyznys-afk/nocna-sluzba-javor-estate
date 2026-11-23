r"""
Prompt 07 — Complete PS1 Texture Conversion & Pixel-Art Character Face / Logo Generator:
1. Converts all 15 world surface texture sets in D:\nocna-zmena-blok-14\assets\textures\ to
   true low-resolution 64x64 / 128x128 Bayer-dithered, limited-palette PS1 pixel art
   (desaturated 1996 Central European cold blue-grey, concrete, brick, damp asphalt, dirty yellow/beige).
2. Converts all 16 signage / poster / map textures to crisp 256x256 weathered PS1 pixel art
   with visible pixel structure & subtle dithering.
3. Generates 11 unique 64x64 hand-painted PS1 character face textures (simple eerie eyes,
   minimal weathered facial lines, subtle asymmetry, hairlines, scar for Roman, glasses for Zuzana)
   plus 4 low-res 64x64 pixelated 1990s fabric swatches into assets/textures/ps1_faces/.
4. Redesigns logo_nocna_sluzba.png and logo_night_shift.png into raw 1997 PS1 retro print/CRT
   typography (desaturated bone-white/dirty-amber, pixel irregularities, zero blood cliché).
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFont

TEX_DIR = r"D:\nocna-zmena-blok-14\assets\textures"
FACE_DIR = os.path.join(TEX_DIR, "ps1_faces")
LOGO_DIR = r"D:\nocna-zmena-blok-14\assets\graphics\logos"
os.makedirs(FACE_DIR, exist_ok=True)
os.makedirs(LOGO_DIR, exist_ok=True)

BAYER_4X4 = np.array([
    [0,  8,  2, 10],
    [12, 4, 14,  6],
    [3, 11,  1,  9],
    [15, 7, 13,  5],
], dtype=np.float32) / 16.0 - 0.5


def ps1_quantize_dither(img: Image.Image, target_w: int, target_h: int, levels: int = 12, sat: float = 0.72, contrast: float = 1.18, tint=(1.0, 1.0, 1.0)) -> Image.Image:
    im = img.convert("RGB").resize((target_w, target_h), Image.Resampling.BILINEAR)
    im = ImageEnhance.Color(im).enhance(sat)
    im = ImageEnhance.Contrast(im).enhance(contrast)
    arr = np.asarray(im, dtype=np.float32) / 255.0
    arr[:, :, 0] *= tint[0]
    arr[:, :, 1] *= tint[1]
    arr[:, :, 2] *= tint[2]
    by = np.tile(BAYER_4X4, (target_h // 4 + 1, target_w // 4 + 1))[:target_h, :target_w]
    dithered = arr + (by[:, :, None] * 0.85) / float(levels)
    quant = np.floor(np.clip(dithered, 0.0, 1.0) * levels + 0.5) / float(levels)
    return Image.fromarray((quant * 255.0).astype(np.uint8), mode="RGB")


def convert_world_textures():
    # Surface sets: 64x64 for organic/tiled ground, 128x128 for hero architectural walls/linoleum
    surface_specs = {
        "cobble":         (128, 10, 0.65, 1.24, (0.90, 0.94, 0.98)),
        "plaster_ochre":  (128, 12, 0.72, 1.20, (0.98, 0.93, 0.80)),
        "plaster_grey":   (128, 10, 0.60, 1.22, (0.88, 0.92, 0.95)),
        "brick_cellar":   (128, 12, 0.70, 1.26, (0.92, 0.86, 0.82)),
        "wood_gallery":   (128, 12, 0.72, 1.22, (0.94, 0.88, 0.80)),
        "concrete_dark":  (128, 10, 0.58, 1.24, (0.86, 0.90, 0.92)),
        "shutter_metal":  (128, 10, 0.60, 1.26, (0.86, 0.92, 0.96)),
        "iron_rusted":    (64,  10, 0.74, 1.28, (0.95, 0.86, 0.78)),
        "asphalt_wet":    (128, 10, 0.58, 1.25, (0.84, 0.90, 0.96)),
        "panel_concrete": (128, 10, 0.58, 1.28, (0.88, 0.92, 0.94)),
        "grass_autumn":   (64,  10, 0.68, 1.22, (0.86, 0.94, 0.82)),
        "gravel_wet":     (64,  10, 0.62, 1.25, (0.88, 0.92, 0.94)),
        "mud_leaves":     (64,  10, 0.68, 1.22, (0.92, 0.88, 0.80)),
        "linoleum_worn":  (128, 12, 0.72, 1.20, (0.94, 0.92, 0.84)),
        "terrazzo_tile":  (128, 12, 0.66, 1.22, (0.90, 0.92, 0.90)),
    }
    converted = 0
    for sname, (sz, lv, sat, ct, tint) in surface_specs.items():
        alb = os.path.join(TEX_DIR, f"{sname}_albedo.png")
        if os.path.exists(alb):
            im = Image.open(alb)
            out = ps1_quantize_dither(im, sz, sz, levels=lv, sat=sat, contrast=ct, tint=tint)
            out.save(alb)
            converted += 1
        # Downscale normal/roughness to matching 64x64 lightweight maps (keeps 45/45 texture files valid & tiny!)
        for suff in ["normal", "roughness"]:
            p = os.path.join(TEX_DIR, f"{sname}_{suff}.png")
            if os.path.exists(p):
                im = Image.open(p).resize((64, 64), Image.Resampling.NEAREST)
                im.save(p)
                converted += 1

    # Signage, Posters & Maps -> crisp 256x256 PS1 dithered pixel structure (keeping readable text!)
    signs = [
        "sign_vratnica", "sign_hodinarstvo", "sign_notar", "sign_kotolna",
        "sign_blok14", "poster_1995", "sign_jednota", "sign_vecierka",
        "sign_trafika", "sign_opravovna", "sign_trafostanica", "sign_bus_stop",
        "billboard_1995", "district_map_1995", "trafika_ads_1996", "grocery_posters_1996",
    ]
    for s in signs:
        p = os.path.join(TEX_DIR, f"{s}.png")
        if os.path.exists(p):
            im = Image.open(p)
            tw, th = (256, 256) if im.width == im.height else (256, max(96, int(256 * im.height / max(1, im.width))))
            out = ps1_quantize_dither(im, tw, th, levels=16, sat=0.76, contrast=1.18, tint=(0.96, 0.94, 0.88))
            out.save(p)
            converted += 1
    print(f"CONVERTED_PS1_WORLD_TEXTURES={converted}")


def draw_ps1_face(filename, cfg):
    # Authentic 64x64 hand-painted PS1 face texture mapped cleanly to front of angular low-poly head!
    W, H = 64, 64
    rng = np.random.default_rng(abs(hash(filename)) % 99991)
    skin = np.array(cfg["skin"], dtype=np.float32)
    img = np.zeros((H, W, 3), dtype=np.float32)
    img[:, :] = skin

    # Subtle mottled PS1 skin shading (darker under brow, cheekbones, jaw & sides)
    yy, xx = np.mgrid[0:H, 0:W]
    dx = (xx - 32.0) / 32.0
    dy = (yy - 32.0) / 32.0
    vign = 1.0 - 0.24 * (dx * dx) - 0.14 * np.maximum(0.0, dy)
    img *= vign[:, :, None]
    noise = (rng.random((H, W, 1)) - 0.5) * 14.0
    img = np.clip(img + noise, 0, 255)

    pil = Image.fromarray(img.astype(np.uint8), mode="RGB")
    dr = ImageDraw.Draw(pil)

    hair_c = tuple(int(c) for c in cfg["hair"])
    dark_skin = tuple(max(0, int(c * 0.62)) for c in cfg["skin"])
    bag_skin = tuple(max(0, int(c * 0.72)) for c in cfg["skin"])
    lip_c = tuple(int(c) for c in cfg.get("lip", (118, 72, 68)))

    # Hairline / forehead fringe
    fringe_y = int(cfg.get("fringe_y", 11))
    dr.rectangle([0, 0, W, fringe_y], fill=hair_c)
    if cfg.get("receding", False):
        dr.polygon([(14, fringe_y), (22, 4), (42, 4), (50, fringe_y)], fill=tuple(int(c) for c in cfg["skin"]))
    else:
        for hx in range(2, W - 2, 5):
            drop = int(rng.integers(1, 5))
            dr.rectangle([hx, fringe_y, hx + 3, fringe_y + drop], fill=hair_c)

    # Side hair framing for women / longer hair
    if cfg.get("side_hair", False):
        dr.rectangle([0, 0, 8, H], fill=hair_c)
        dr.rectangle([W - 9, 0, W, H], fill=hair_c)

    # Slight intentional PS1 uncanny asymmetry (1px offset on one eye/brow!)
    asym = int(cfg.get("asym", 1))
    ey_l = 27
    ey_r = 27 + asym

    # Dark eye sockets / tired shadows (classic Silent Hill / PS1 horror look)
    dr.rectangle([15, ey_l - 3, 27, ey_l + 6], fill=bag_skin)
    dr.rectangle([37, ey_r - 3, 49, ey_r + 6], fill=bag_skin)

    # Eyebrows
    brow_c = tuple(max(0, int(c * 0.8)) for c in hair_c)
    dr.rectangle([15, ey_l - 5, 27, ey_l - 3], fill=brow_c)
    dr.rectangle([37, ey_r - 5, 49, ey_r - 3], fill=brow_c)

    # Eyes (muted sclera + dark staring pupil)
    sclera = (196, 192, 182)
    pupil = (24, 26, 30)
    dr.rectangle([17, ey_l, 25, ey_l + 3], fill=sclera)
    dr.rectangle([20, ey_l, 23, ey_l + 3], fill=pupil)
    dr.rectangle([39, ey_r, 47, ey_r + 3], fill=sclera)
    dr.rectangle([41, ey_r, 44, ey_r + 3], fill=pupil)

    # Nose bridge & nostrils shadow
    dr.rectangle([30, 29, 33, 39], fill=bag_skin)
    dr.rectangle([28, 39, 36, 41], fill=dark_skin)
    dr.point((29, 40), fill=(35, 26, 24))
    dr.point((34, 40), fill=(35, 26, 24))

    # Mouth (simple stoic / tired expression)
    dr.rectangle([24, 47, 40, 49], fill=lip_c)
    dr.rectangle([25, 48, 39, 48], fill=(54, 34, 32))

    # Wrinkles (Varga 51, Anna 68, Older Resident)
    if cfg.get("wrinkles", False):
        dr.line([18, 17, 45, 17], fill=dark_skin)
        dr.line([21, 20, 42, 20], fill=dark_skin)
        dr.line([21, 41, 19, 48], fill=dark_skin)
        dr.line([43, 41, 45, 48], fill=dark_skin)

    # Stubble (Milan, Roman)
    if cfg.get("stubble", False):
        for sy in range(43, 62):
            for sx in range(14, 50):
                if (sx + sy) % 2 == 0 and rng.random() > 0.35:
                    p = pil.getpixel((sx, sy))
                    pil.putpixel((sx, sy), (max(0, p[0] - 28), max(0, p[1] - 26), max(0, p[2] - 24)))

    # Facial scar (Roman Král)
    if cfg.get("scar", False):
        dr.line([14, 33, 24, 45], fill=(118, 56, 52), width=2)
        dr.line([15, 33, 25, 45], fill=(168, 114, 102), width=1)

    # Glasses (Zuzana)
    if cfg.get("glasses", False):
        gc = (38, 34, 32)
        dr.rectangle([14, ey_l - 2, 28, ey_l + 6], outline=gc, width=1)
        dr.rectangle([36, ey_r - 2, 50, ey_r + 6], outline=gc, width=1)
        dr.line([29, ey_l + 1, 35, ey_r + 1], fill=gc)

    # Apply PS1 Bayer dithering & 12-level quantization
    out = ps1_quantize_dither(pil, W, H, levels=12, sat=0.82, contrast=1.15)
    out.save(os.path.join(FACE_DIR, filename))


def build_all_ps1_faces():
    specs = {
        "ps1_face_varga.png":  {"skin": (176, 140, 116), "hair": (76, 76, 78),  "receding": True, "wrinkles": True, "asym": 1},
        "ps1_face_anna.png":   {"skin": (186, 154, 134), "hair": (168, 166, 160), "fringe_y": 14, "wrinkles": True, "side_hair": True, "asym": 1},
        "ps1_face_dana.png":   {"skin": (188, 150, 128), "hair": (88, 62, 42),  "fringe_y": 12, "side_hair": True, "lip": (138, 74, 72), "asym": 0},
        "ps1_face_zuzana.png": {"skin": (182, 146, 124), "hair": (52, 38, 30),  "fringe_y": 12, "glasses": True, "asym": 1},
        "ps1_face_peter.png":  {"skin": (194, 160, 138), "hair": (64, 46, 32),  "fringe_y": 15, "asym": 0},
        "ps1_face_milan.png":  {"skin": (164, 144, 132), "hair": (58, 42, 32),  "fringe_y": 13, "stubble": True, "wrinkles": True, "asym": 1},
        "ps1_face_roman.png":  {"skin": (166, 132, 110), "hair": (46, 44, 44),  "fringe_y": 11, "stubble": True, "scar": True, "asym": 1},
        "ps1_face_iveta.png":  {"skin": (154, 138, 126), "hair": (58, 38, 28),  "fringe_y": 13, "side_hair": True, "asym": 0},
        "ps1_face_res_a.png":  {"skin": (178, 144, 120), "hair": (122, 120, 116), "fringe_y": 10, "wrinkles": True, "asym": 1},
        "ps1_face_res_b.png":  {"skin": (190, 154, 134), "hair": (92, 48, 34),  "fringe_y": 13, "side_hair": True, "asym": 0},
        "ps1_face_res_c.png":  {"skin": (174, 138, 116), "hair": (54, 40, 30),  "fringe_y": 12, "stubble": True, "asym": 1},
    }
    for fn, cfg in specs.items():
        draw_ps1_face(fn, cfg)

    # Pixelated 64x64 1990s fabric textures for clothing variation
    fabrics = {
        "ps1_cloth_navy.png":  ((26, 34, 48), (18, 24, 34)),
        "ps1_cloth_brown.png": ((56, 40, 28), (38, 28, 20)),
        "ps1_cloth_wool.png":  ((98, 78, 66), (74, 58, 48)),
        "ps1_cloth_apron.png": ((42, 86, 88), (30, 64, 66)),
    }
    rng = np.random.default_rng(1997)
    for fn, (c1, c2) in fabrics.items():
        arr = np.zeros((64, 64, 3), dtype=np.uint8)
        for y in range(64):
            for x in range(64):
                weave = ((x ^ y) & 1) * 0.5 + rng.random() * 0.5
                col = [int(c1[i] * weave + c2[i] * (1.0 - weave)) for i in range(3)]
                arr[y, x] = col
        Image.fromarray(arr, mode="RGB").save(os.path.join(FACE_DIR, fn))
    print(f"GENERATED_PS1_FACES={len(specs)} FABRICS={len(fabrics)}")


def build_ps1_retro_logos():
    # Part 4.2: Authentic 1997 retro print / CRT title treatment for NOČNÁ SLUŽBA & NIGHT SHIFT
    # Rendered at low 320x92 pixel resolution, slight printing grit & nearest-neighbor upscaled!
    font_path = r"D:\nocna-zmena-blok-14\assets\fonts\consolab.ttf"
    if not os.path.exists(font_path):
        font_path = r"C:\Windows\Fonts\consolab.ttf"

    for fname, main_txt, sub_txt in [
        ("logo_nocna_sluzba.png", "NOČNÁ SLUŽBA", "SÍDLISKO JAVOR  •  NOVEMBER 1996"),
        ("logo_night_shift.png",  "NIGHT SHIFT",  "THE JAVOR ESTATE  •  NOVEMBER 1996"),
    ]:
        lw, lh = 320, 96
        im = Image.new("RGBA", (lw, lh), (0, 0, 0, 0))
        dr = ImageDraw.Draw(im)
        f_big = ImageFont.truetype(font_path, 34) if os.path.exists(font_path) else ImageFont.load_default()
        f_sub = ImageFont.truetype(font_path, 12) if os.path.exists(font_path) else ImageFont.load_default()

        # Subtle dark offset drop shadow + dirty amber horizontal rule + desaturated bone-white ink
        dr.text((11, 15), main_txt, font=f_big, fill=(14, 16, 16, 235))
        dr.text((10, 14), main_txt, font=f_big, fill=(214, 206, 184, 255))
        dr.rectangle([10, 56, 304, 58], fill=(176, 118, 52, 230))
        dr.rectangle([10, 59, 240, 60], fill=(92, 98, 92, 200))
        dr.text((11, 67), sub_txt, font=f_sub, fill=(16, 18, 18, 220))
        dr.text((10, 66), sub_txt, font=f_sub, fill=(184, 174, 148, 245))

        # Subtle 1997 print/pixel irregularities (sparse 1px grain cutouts)
        rng = np.random.default_rng(199701 if "nocna" in fname else 199702)
        arr = np.array(im)
        mask = arr[:, :, 3] > 120
        grit = (rng.random((lh, lw)) < 0.045) & mask
        arr[grit, 0] = (arr[grit, 0] * 0.72).astype(np.uint8)
        arr[grit, 1] = (arr[grit, 1] * 0.72).astype(np.uint8)
        arr[grit, 2] = (arr[grit, 2] * 0.72).astype(np.uint8)
        out = Image.fromarray(arr, mode="RGBA").resize((640, 192), Image.Resampling.NEAREST)
        out.save(os.path.join(LOGO_DIR, fname))
    print("GENERATED_PS1_LOGOS=2")


if __name__ == "__main__":
    convert_world_textures()
    build_all_ps1_faces()
    build_ps1_retro_logos()
    print("PS1_TEXTURES_ALL_DONE")
