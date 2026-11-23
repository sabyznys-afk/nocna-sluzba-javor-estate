r"""
Generates Master Prompt 03 graphical identity assets into D:\nocna-zmena-blok-14\assets\graphics\:
- Logos: logo_night_shift.png, logo_nocna_sluzba.png
- Main Key Art: key_art_main.png (1920x1080)
- 6 Chapter Cards: chapter_night_1.png .. chapter_night_6.png (1280x720)
- 4 Loading Artworks: loading_plan, loading_dossier, loading_cassette, loading_notebook (1280x720)
- 14 Coherent Icons (64x64 transparent): notebook, keys, flashlight, headphones, radio, map,
  building, door, recording, objective, save, settings, audio, accessibility
- UI Textures: notebook_paper_bg.png, javor_blueprint_map.png (accurate world coordinate map)
"""
import math
import pathlib
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(r"D:\nocna-zmena-blok-14")
FONTS = ROOT / "assets" / "fonts"
GFX = ROOT / "assets" / "graphics"

FONT_SANS = str(FONTS / "bahnschrift.ttf")
FONT_MONO = str(FONTS / "consola.ttf")
FONT_MONO_B = str(FONTS / "consolab.ttf")


def fnt(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def add_film_grain(img: Image.Image, strength: float = 9.0, seed: int = 1996) -> Image.Image:
    rng = np.random.default_rng(seed)
    arr = np.asarray(img, dtype=np.float32)
    noise = rng.normal(0.0, strength, size=arr.shape[:2])[:, :, None]
    if arr.shape[2] == 4:
        arr[:, :, :3] = np.clip(arr[:, :, :3] + noise, 0, 255)
    else:
        arr = np.clip(arr + noise, 0, 255)
    return Image.fromarray(arr.astype(np.uint8), mode=img.mode)


def add_vignette(img: Image.Image, strength: float = 0.65) -> Image.Image:
    w, h = img.size
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    nx = (xx / w - 0.5) * 2.0
    ny = (yy / h - 0.5) * 2.0
    r2 = nx * nx + ny * ny
    vig = np.clip(1.0 - r2 * strength * 0.55, 0.22, 1.0)[:, :, None]
    arr = np.asarray(img, dtype=np.float32)
    arr[:, :, :3] *= vig
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), mode=img.mode)


def radial_glow(base: Image.Image, cx: int, cy: int, radius: int, color: tuple, intensity: float = 0.85) -> Image.Image:
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for step in range(18, 0, -1):
        frac = step / 18.0
        r = int(radius * frac)
        alpha = int(255 * intensity * ((1.0 - frac) ** 2.1) * 0.35)
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(color[0], color[1], color[2], alpha))
    return Image.alpha_composite(base.convert("RGBA"), overlay)


def build_logos() -> None:
    out_dir = GFX / "logos"
    out_dir.mkdir(parents=True, exist_ok=True)
    specs = [
        ("logo_night_shift.png", "NIGHT SHIFT", "THE JAVOR ESTATE  •  NOVÝ BROD  •  1996", "SHIFT LOG #04 // 22:00–06:00"),
        ("logo_nocna_sluzba.png", "NOČNÁ SLUŽBA", "SÍDLISKO JAVOR  •  NOVÝ BROD  •  1996", "ZMENOVÝ DENNÍK #04 // 22:00–06:00"),
    ]
    rng = np.random.default_rng(199601)
    for fname, main_t, sub_t, stamp_t in specs:
        img = Image.new("RGBA", (1024, 300), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        # Subtle administrative header bar & amber vertical marker
        d.rectangle((26, 36, 36, 224), fill=(214, 158, 78, 245))
        d.line((54, 40, 960, 40), fill=(155, 150, 134, 110), width=2)
        d.line((54, 222, 960, 222), fill=(155, 150, 134, 110), width=2)
        # Spaced distressed typography
        title_font = fnt(FONT_SANS, 92)
        cx = 56
        for idx, ch in enumerate(main_t):
            jitter_y = int(rng.integers(-2, 3))
            d.text((cx + 3, 66 + jitter_y + 3), ch, font=title_font, fill=(10, 12, 13, 180))
            d.text((cx, 66 + jitter_y), ch, font=title_font, fill=(228, 220, 200, 248))
            bbox = d.textbbox((0, 0), ch, font=title_font)
            cx += (bbox[2] - bbox[0]) + (12 if ch != " " else 22)
        # Subtitle & administrative code
        d.text((58, 174), sub_t, font=fnt(FONT_MONO_B, 25), fill=(214, 158, 78, 240))
        d.text((58, 236), stamp_t, font=fnt(FONT_MONO, 19), fill=(152, 160, 154, 210))
        # Subtle printed ink distress speckles (transparent cutouts)
        arr = np.asarray(img, dtype=np.uint8).copy()
        mask = rng.random((300, 1024)) < 0.018
        arr[mask, 3] = (arr[mask, 3].astype(np.float32) * 0.45).astype(np.uint8)
        Image.fromarray(arr, mode="RGBA").save(out_dir / fname)
        print(f"GFX_OK: logos/{fname}")


def draw_panelak_silhouette(d: ImageDraw.ImageDraw, x0: int, y0: int, w: int, h: int, seed: int, lit_win: tuple = None, blackout: bool = False) -> None:
    rng = np.random.default_rng(seed)
    d.rectangle((x0, y0, x0 + w, y0 + h), fill=(18, 23, 27, 255))
    # Panel grid seams
    for px in range(x0, x0 + w, 34):
        d.line((px, y0, px, y0 + h), fill=(26, 33, 38, 170), width=1)
    for py in range(y0, y0 + h, 36):
        d.line((x0, py, x0 + w, py), fill=(12, 16, 19, 190), width=2)
    cols = max(2, (w - 20) // 36)
    rows = max(3, (h - 30) // 38)
    for r in range(rows):
        for c in range(cols):
            wx = x0 + 14 + c * 36
            wy = y0 + 18 + r * 38
            is_hero = (lit_win is not None and lit_win == (r, c))
            if is_hero:
                d.rectangle((wx, wy, wx + 22, wy + 20), fill=(242, 188, 96, 255))
                # Faint standing silhouette behind curtain
                d.ellipse((wx + 8, wy + 4, wx + 14, wy + 10), fill=(72, 50, 32, 210))
                d.rectangle((wx + 6, wy + 10, wx + 16, wy + 20), fill=(62, 42, 28, 210))
            elif (not blackout) and rng.random() < 0.08:
                col = (196, 148, 84, 210) if rng.random() < 0.7 else (104, 138, 172, 195)
                d.rectangle((wx, wy, wx + 22, wy + 20), fill=col)
            else:
                d.rectangle((wx, wy, wx + 22, wy + 20), fill=(12, 17, 22, 235))


def build_key_art() -> None:
    out_dir = GFX / "key_art"
    out_dir.mkdir(parents=True, exist_ok=True)
    w, h = 1920, 1080
    # Overcast cold November night sky gradient
    yy = np.linspace(0.0, 1.0, h, dtype=np.float32)[:, None]
    sky = np.zeros((h, w, 4), dtype=np.uint8)
    sky[:, :, 0] = np.clip(11 + yy * 16, 0, 255).astype(np.uint8)
    sky[:, :, 1] = np.clip(16 + yy * 20, 0, 255).astype(np.uint8)
    sky[:, :, 2] = np.clip(24 + yy * 22, 0, 255).astype(np.uint8)
    sky[:, :, 3] = 255
    img = Image.fromarray(sky, mode="RGBA")
    d = ImageDraw.Draw(img)

    # Distant forest treeline & 1990s Panelák apartment skyline
    for bx, by, bw, bh, sd, hero in [
        (80, 240, 360, 440, 11, None),
        (490, 120, 450, 560, 22, (3, 7)), # Building B hero illuminated window!
        (990, 210, 410, 470, 33, None),
        (1450, 260, 390, 420, 44, None),
    ]:
        draw_panelak_silhouette(d, bx, by, bw, bh, sd, lit_win=hero)

    # Wet asphalt / pedestrian path perspective receding toward Building B
    d.rectangle((0, 660, w, h), fill=(15, 19, 21, 255))
    d.polygon([(520, 1080), (1400, 1080), (1050, 660), (850, 660)], fill=(25, 30, 33, 255))
    # Wet amber reflection streaks from sodium lamps
    for rx, rw in [(390, 36), (1320, 32), (760, 26)]:
        for sy in range(685, 1060, 10):
            alpha = max(12, int(85 * (1.0 - (sy - 685) / 420.0)))
            d.rectangle((rx - rw // 2, sy, rx + rw // 2, sy + 4), fill=(218, 152, 68, alpha))

    # Sodium streetlamp poles
    for lx in (390, 1320):
        d.line((lx, 360, lx, 690), fill=(32, 37, 40, 255), width=8)
        d.line((lx, 360, lx + (42 if lx < 900 else -42), 348), fill=(38, 44, 48, 255), width=6)

    img = radial_glow(img, 432, 355, 220, (242, 168, 72), 0.95)
    img = radial_glow(img, 1278, 355, 210, (242, 168, 72), 0.90)
    img = radial_glow(img, 766, 254, 110, (248, 196, 105), 0.85) # Warm hero window glow!

    # Foreground lone night guard viewed from behind (dark jacket, padded headphones, flashlight beam)
    d = ImageDraw.Draw(img)
    gx, gy = 955, 790
    # Flashlight beam cone into wet path
    beam = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(beam)
    bd.polygon([(gx + 54, gy + 36), (gx + 210, 650), (gx - 60, 650)], fill=(236, 212, 152, 42))
    beam = beam.filter(ImageFilter.GaussianBlur(18))
    img = Image.alpha_composite(img, beam)
    d = ImageDraw.Draw(img)

    # Guard shoulders & dark coat
    d.polygon([(gx - 115, 1080), (gx - 95, gy - 10), (gx + 95, gy - 10), (gx + 120, 1080)], fill=(12, 15, 17, 255))
    # Collar rim light from sodium lamp
    d.line((gx - 95, gy - 10, gx + 95, gy - 10), fill=(135, 105, 62, 160), width=4)
    # Head & iconic retro padded headphones headband + earcups!
    d.ellipse((gx - 42, gy - 108, gx + 42, gy - 20), fill=(15, 18, 20, 255))
    d.arc((gx - 48, gy - 116, gx + 48, gy - 24), 185, 355, fill=(145, 138, 122, 235), width=6)
    d.rounded_rectangle((gx - 54, gy - 82, gx - 36, gy - 44), radius=6, fill=(58, 56, 52, 255), outline=(175, 140, 82, 210), width=2)
    d.rounded_rectangle((gx + 36, gy - 82, gx + 54, gy - 44), radius=6, fill=(58, 56, 52, 255), outline=(175, 140, 82, 210), width=2)

    # Subtle falling rain streaks
    rng = np.random.default_rng(199609)
    for _ in range(380):
        rx = int(rng.integers(0, w))
        ry = int(rng.integers(0, h))
        rl = int(rng.integers(14, 34))
        d.line((rx, ry, rx - 3, ry + rl), fill=(170, 188, 202, 42), width=1)

    # Title overlay upper-left
    logo = Image.open(GFX / "logos" / "logo_night_shift.png").convert("RGBA").resize((720, 210), Image.Resampling.LANCZOS)
    img.alpha_composite(logo, (64, 52))

    img = add_vignette(add_film_grain(img, 6.5, 99), 0.72)
    img.convert("RGB").save(out_dir / "key_art_main.png", optimize=True)
    print("GFX_OK: key_art/key_art_main.png")


def build_chapter_cards() -> None:
    out_dir = GFX / "chapters"
    out_dir.mkdir(parents=True, exist_ok=True)
    chapters = [
        (1, "NIGHT 1: THE ROUTINE", "11.11.1996 • 22:00", "courtyard"),
        (2, "NIGHT 2: THE RESIDENTS", "12.11.1996 • 22:00", "window"),
        (3, "NIGHT 3: THE RECORDINGS", "13.11.1996 • 22:00", "cassette"),
        (4, "NIGHT 4: THE WRONG FLOOR", "14.11.1996 • 22:00", "elevator"),
        (5, "NIGHT 5: BELOW THE ESTATE", "15.11.1996 • 22:00", "basement"),
        (6, "NIGHT 6: THE LAST PATROL", "16.11.1996 • 03:17", "blackout"),
    ]
    w, h = 1280, 720
    for num, title, sub, motif in chapters:
        img = Image.new("RGBA", (w, h), (14, 18, 20, 255))
        d = ImageDraw.Draw(img)
        if motif == "courtyard":
            draw_panelak_silhouette(d, 70, 120, 320, 380, 101)
            draw_panelak_silhouette(d, 460, 70, 360, 430, 102, lit_win=(2, 4))
            draw_panelak_silhouette(d, 880, 130, 330, 370, 103)
            d.rectangle((0, 490, w, h), fill=(18, 22, 23, 255))
            img = radial_glow(img, 360, 260, 160, (226, 160, 68), 0.85)
        elif motif == "window":
            draw_panelak_silhouette(d, 220, 40, 840, 640, 202, lit_win=(3, 10))
            img = radial_glow(img, 600, 178, 170, (245, 185, 86), 0.95)
        elif motif == "cassette":
            # CRT Monitor glow + Maxell C-60 cassette on dark desk
            d.rectangle((0, 420, w, h), fill=(26, 22, 18, 255))
            d.rounded_rectangle((720, 120, 1140, 430), radius=12, fill=(36, 40, 38, 255), outline=(88, 94, 86, 255), width=4)
            d.rounded_rectangle((755, 152, 1085, 380), radius=16, fill=(28, 52, 42, 255))
            d.text((785, 180), "CAM-03 PARK  02:15", font=fnt(FONT_MONO_B, 22), fill=(142, 214, 158, 220))
            # Cassette shell foreground left
            d.rounded_rectangle((170, 330, 590, 580), radius=10, fill=(32, 34, 36, 255), outline=(120, 118, 108, 255), width=3)
            d.rectangle((205, 365, 555, 455), fill=(216, 206, 184, 255))
            d.text((225, 382), "C-60  MILAN ŠVEC  09.11.96", font=fnt(FONT_MONO_B, 20), fill=(36, 32, 28, 255))
            d.ellipse((255, 475, 325, 545), fill=(16, 18, 20, 255), outline=(185, 150, 92, 240), width=4)
            d.ellipse((435, 475, 505, 545), fill=(16, 18, 20, 255), outline=(185, 150, 92, 240), width=4)
            img = radial_glow(img, 920, 260, 220, (105, 180, 130), 0.55)
        elif motif == "elevator":
            # Concrete stairwell & elevator doors + glowing "47" indicator
            d.rectangle((0, 0, w, h), fill=(24, 28, 29, 255))
            d.rectangle((420, 170, 860, 680), fill=(42, 48, 49, 255), outline=(80, 88, 86, 255), width=6)
            d.line((640, 170, 640, 680), fill=(14, 16, 17, 255), width=8)
            d.rectangle((560, 92, 720, 152), fill=(16, 18, 18, 255), outline=(125, 118, 102, 255), width=3)
            d.text((612, 103), "47", font=fnt(FONT_MONO_B, 38), fill=(224, 132, 62, 255))
            img = radial_glow(img, 640, 122, 150, (224, 132, 62), 0.75)
        elif motif == "basement":
            # Vanishing-point concrete maintenance corridor + overhead pipes
            d.rectangle((0, 0, w, h), fill=(12, 14, 15, 255))
            d.polygon([(0, 0), (490, 240), (490, 480), (0, h)], fill=(26, 28, 27, 255))
            d.polygon([(w, 0), (790, 240), (790, 480), (w, h)], fill=(24, 26, 25, 255))
            d.polygon([(490, 480), (790, 480), (w, h), (0, h)], fill=(20, 22, 21, 255))
            d.rectangle((560, 270, 720, 480), fill=(64, 26, 22, 255), outline=(110, 48, 42, 255), width=4)
            img = radial_glow(img, 640, 220, 180, (198, 145, 76), 0.65)
        else:
            # Blackout estate at 03:17
            draw_panelak_silhouette(d, 90, 120, 340, 420, 601, blackout=True)
            draw_panelak_silhouette(d, 470, 60, 360, 480, 602, blackout=True)
            draw_panelak_silhouette(d, 870, 130, 330, 410, 603, blackout=True)
            d.rectangle((0, 520, w, h), fill=(9, 11, 12, 255))
            d.text((545, 290), "03:17", font=fnt(FONT_MONO_B, 68), fill=(181, 68, 58, 235))
            img = radial_glow(img, 640, 325, 210, (181, 68, 58), 0.55)

        d = ImageDraw.Draw(img)
        # Consistent lower-left chapter administrative card band
        d.rectangle((0, 540, w, h), fill=(12, 16, 17, 218))
        d.line((0, 540, w, 540), fill=(214, 158, 78, 185), width=2)
        d.rectangle((54, 574, 62, 676), fill=(214, 158, 78, 240))
        d.text((84, 574), title, font=fnt(FONT_SANS, 48), fill=(228, 220, 200, 255))
        d.text((86, 636), sub + "  •  SÍDLISKO JAVOR, NOVÝ BROD", font=fnt(FONT_MONO, 22), fill=(214, 158, 78, 235))
        img = add_vignette(add_film_grain(img, 7.0, 300 + num), 0.58)
        img.convert("RGB").save(out_dir / f"chapter_night_{num}.png", optimize=True)
        print(f"GFX_OK: chapters/chapter_night_{num}.png")


def build_loading_screens() -> None:
    out_dir = GFX / "loading"
    out_dir.mkdir(parents=True, exist_ok=True)
    w, h = 1280, 720
    specs = [
        ("loading_plan.png", "MUNICIPAL HOUSING ARCHIVE — PLAN 84-B", "SÍDLISKO JAVOR • BLOCKS A–F • SCALE 1:500"),
        ("loading_dossier.png", "SECURITY OFFICE DOSSIER — FILE #114", "TEMP. WATCHMAN CONTRACT • NOVÝ BROD 1996"),
        ("loading_cassette.png", "ANALOG AUDIO RECORD — C-60 MAGNETIC TAPE", "RECORDING DECK 50.4 Hz • NOISE REDUCTION OFF"),
        ("loading_notebook.png", "SHIFT LOGBOOK — PATROL OBSERVATIONS", "KEEP ALL ENTRIES DATED AND SIGNED BEFORE 06:00"),
    ]
    for idx, (fname, hdr, sub) in enumerate(specs):
        img = Image.new("RGBA", (w, h), (16, 20, 21, 255))
        d = ImageDraw.Draw(img)
        # Subtle drafting grid
        for gx in range(0, w, 40):
            d.line((gx, 0, gx, h), fill=(28, 36, 35, 120), width=1)
        for gy in range(0, h, 40):
            d.line((0, gy, w, gy), fill=(28, 36, 35, 120), width=1)
        # Center framed document plate
        d.rectangle((140, 110, 1140, 560), fill=(26, 32, 30, 235), outline=(145, 138, 116, 210), width=2)
        d.rectangle((154, 124, 1126, 546), outline=(105, 102, 92, 130), width=1)
        d.text((185, 155), hdr, font=fnt(FONT_MONO_B, 28), fill=(214, 158, 78, 245))
        d.line((185, 198, 1095, 198), fill=(145, 138, 116, 160), width=1)
        d.text((185, 216), sub, font=fnt(FONT_MONO, 20), fill=(195, 190, 174, 220))
        # Schematic architectural wireframe sketch
        for rx, ry, rw, rh, lbl in [
            (220, 290, 180, 70, "BLK A"), (460, 270, 200, 75, "BLK B (8F)"),
            (720, 290, 180, 70, "BLK C"), (480, 420, 180, 68, "BLK D"),
            (260, 440, 95, 52, "VRÁTNICA"), (760, 400, 140, 88, "OBCHODY"),
        ]:
            d.rectangle((rx, ry, rx + rw, ry + rh), outline=(214, 158, 78, 170), width=2)
            d.text((rx + 12, ry + 20), lbl, font=fnt(FONT_MONO, 16), fill=(208, 200, 178, 200))
        img = add_vignette(add_film_grain(img, 5.5, 410 + idx), 0.55)
        img.convert("RGB").save(out_dir / fname, optimize=True)
        print(f"GFX_OK: loading/{fname}")


def build_icons() -> None:
    out_dir = GFX / "icons"
    out_dir.mkdir(parents=True, exist_ok=True)
    fg = (224, 212, 182, 255)
    acc = (214, 158, 78, 255)
    names = [
        "icon_notebook", "icon_keys", "icon_flashlight", "icon_headphones",
        "icon_radio", "icon_map", "icon_building", "icon_door",
        "icon_recording", "icon_objective", "icon_save", "icon_settings",
        "icon_audio", "icon_accessibility"
    ]
    for nm in names:
        img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        if nm == "icon_notebook":
            d.rounded_rectangle((14, 10, 52, 54), radius=4, outline=fg, width=3)
            d.line((22, 10, 22, 54), fill=acc, width=3)
            for y in (22, 31, 40):
                d.line((28, y, 45, y), fill=fg, width=2)
        elif nm == "icon_keys":
            d.ellipse((12, 20, 32, 40), outline=acc, width=3)
            d.line((32, 30, 54, 30), fill=fg, width=3)
            d.line((44, 30, 44, 39), fill=fg, width=3)
            d.line((51, 30, 51, 37), fill=fg, width=3)
        elif nm == "icon_flashlight":
            d.rectangle((10, 26, 38, 38), outline=fg, width=3)
            d.polygon([(38, 24), (50, 18), (50, 46), (38, 40)], outline=acc, width=3)
            d.line((54, 24, 60, 20), fill=acc, width=2)
            d.line((54, 32, 61, 32), fill=acc, width=2)
            d.line((54, 40, 60, 44), fill=acc, width=2)
        elif nm == "icon_headphones":
            d.arc((12, 12, 52, 52), 180, 360, fill=fg, width=4)
            d.rounded_rectangle((10, 32, 21, 50), radius=4, fill=acc)
            d.rounded_rectangle((43, 32, 54, 50), radius=4, fill=acc)
        elif nm == "icon_radio":
            d.line((20, 8, 20, 22), fill=acc, width=3)
            d.rounded_rectangle((14, 22, 50, 54), radius=4, outline=fg, width=3)
            d.rectangle((20, 28, 44, 36), outline=acc, width=2)
            for x in (22, 30, 38):
                d.ellipse((x, 42, x + 4, 46), fill=fg)
        elif nm == "icon_map":
            d.polygon([(8, 16), (24, 12), (40, 18), (56, 12), (56, 50), (40, 54), (24, 48), (8, 52)], outline=fg, width=3)
            d.line((24, 12, 24, 48), fill=acc, width=2)
            d.line((40, 18, 40, 54), fill=acc, width=2)
        elif nm == "icon_building":
            d.rectangle((16, 10, 48, 54), outline=fg, width=3)
            for r in (16, 26, 36):
                for c in (22, 34):
                    d.rectangle((c, r, c + 6, r + 6), fill=acc if (r == 26 and c == 34) else fg)
        elif nm == "icon_door":
            d.rectangle((18, 10, 46, 54), outline=fg, width=3)
            d.ellipse((36, 31, 41, 36), fill=acc)
        elif nm == "icon_recording":
            d.rounded_rectangle((8, 18, 56, 48), radius=4, outline=fg, width=3)
            d.ellipse((16, 26, 28, 38), outline=acc, width=3)
            d.ellipse((36, 26, 48, 38), outline=acc, width=3)
        elif nm == "icon_objective":
            d.ellipse((14, 14, 50, 50), outline=fg, width=3)
            d.ellipse((24, 24, 40, 40), outline=acc, width=3)
            d.ellipse((30, 30, 34, 34), fill=acc)
        elif nm == "icon_save":
            d.rectangle((12, 12, 52, 52), outline=fg, width=3)
            d.rectangle((20, 12, 44, 26), outline=acc, width=2)
            d.rectangle((20, 34, 44, 52), outline=fg, width=2)
        elif nm == "icon_settings":
            d.ellipse((22, 22, 42, 42), outline=acc, width=3)
            for ang in range(0, 360, 45):
                rad = math.radians(ang)
                x1, y1 = 32 + int(math.cos(rad) * 14), 32 + int(math.sin(rad) * 14)
                x2, y2 = 32 + int(math.cos(rad) * 22), 32 + int(math.sin(rad) * 22)
                d.line((x1, y1, x2, y2), fill=fg, width=4)
        elif nm == "icon_audio":
            d.polygon([(12, 26), (22, 26), (34, 16), (34, 48), (22, 38), (12, 38)], outline=fg, width=3)
            d.arc((32, 20, 48, 44), -55, 55, fill=acc, width=3)
            d.arc((36, 14, 56, 50), -55, 55, fill=fg, width=2)
        elif nm == "icon_accessibility":
            d.ellipse((27, 10, 37, 20), outline=acc, width=3)
            d.line((16, 26, 48, 26), fill=fg, width=3)
            d.line((32, 26, 32, 40), fill=fg, width=3)
            d.line((32, 40, 22, 54), fill=fg, width=3)
            d.line((32, 40, 42, 54), fill=fg, width=3)
        img.save(out_dir / f"{nm}.png")
    print(f"GFX_OK: {len(names)} unified analog icons generated")


def build_ui_textures() -> None:
    out_dir = GFX / "ui"
    out_dir.mkdir(parents=True, exist_ok=True)
    # 1. Aged Notebook Paper Spread (1024x720)
    w, h = 1024, 720
    rng = np.random.default_rng(199677)
    base = np.zeros((h, w, 3), dtype=np.float32)
    base[:, :, 0] = 216
    base[:, :, 1] = 205
    base[:, :, 2] = 180
    # Warm paper mottling + center spine shadow
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    spine = np.exp(-((xx - w * 0.5) / 36.0) ** 2) * 38.0
    edges = (np.abs(xx / w - 0.5) * 2.0) ** 3 * 22.0 + (np.abs(yy / h - 0.5) * 2.0) ** 3 * 18.0
    mottle = rng.normal(0.0, 4.5, (h, w))
    for c in range(3):
        base[:, :, c] = np.clip(base[:, :, c] - spine - edges + mottle, 120, 240)
    paper = Image.fromarray(base.astype(np.uint8), mode="RGB")
    d = ImageDraw.Draw(paper)
    # Ruled blue-grey notebook lines & margin
    for ly in range(74, h - 42, 26):
        d.line((36, ly, w // 2 - 22, ly), fill=(154, 158, 150), width=1)
        d.line((w // 2 + 22, ly, w - 36, ly), fill=(154, 158, 150), width=1)
    d.line((88, 36, 88, h - 36), fill=(176, 128, 118), width=1)
    d.line((w // 2 + 72, 36, w // 2 + 72, h - 36), fill=(176, 128, 118), width=1)
    # Subtle coffee ring stain corner
    d.arc((780, 520, 910, 650), 0, 360, fill=(172, 152, 120), width=4)
    paper.save(out_dir / "notebook_paper_bg.png", optimize=True)
    print("GFX_OK: ui/notebook_paper_bg.png")

    # 2. Accurate Top-Down Sídlisko Javor Printed Maintenance Map (world X:-110..+100 -> 1024, Z:-84..+66 -> 720, North UP!)
    mw, mh = 1024, 720
    mimg = Image.new("RGB", (mw, mh), (206, 198, 178))
    md = ImageDraw.Draw(mimg)

    def w2p(wx: float, wz: float) -> tuple:
        # North (+Z) UP on printed maintenance plan!
        px = int((wx - (-110.0)) / 210.0 * (mw - 80) + 40)
        py = int((66.0 - wz) / 150.0 * (mh - 80) + 40)
        return (px, py)

    def draw_wrect(x1: float, z1: float, x2: float, z2: float, fill: tuple, outline: tuple = (62, 58, 50), label: str = "") -> None:
        p1 = w2p(min(x1, x2), max(z1, z2))
        p2 = w2p(max(x1, x2), min(z1, z2))
        md.rectangle((p1[0], p1[1], p2[0], p2[1]), fill=fill, outline=outline, width=2)
        if label:
            md.text((p1[0] + 6, p1[1] + 5), label, font=fnt(FONT_MONO_B, 14), fill=(32, 30, 26))

    # Forest & Park zones
    draw_wrect(-108, 52, 98, 66, (176, 182, 162), (110, 116, 102), "NORTH FOREST")
    draw_wrect(-28, -20, 28, 24, (184, 192, 168), (96, 108, 86), "CENTRAL PARK")
    # Roads
    draw_wrect(-106, -80, 96, -72, (132, 130, 124), (82, 80, 76), "MAIN ROAD (NOVÝ BROD)")
    draw_wrect(-56.6, -72, -51.4, 60, (142, 140, 134), (92, 90, 86))
    draw_wrect(59.3, -72, 64.7, 60, (142, 140, 134), (92, 90, 86))
    draw_wrect(4, -65, 46, -41, (150, 148, 140), (88, 86, 80), "PARKING")
    # Buildings matching exact coordinates in residential_district!
    draw_wrect(-46, 32, -18, 44, (166, 152, 128), (44, 40, 34), "BLOCK A (5F)")
    draw_wrect(-13, 36, 17, 48, (158, 142, 116), (44, 40, 34), "BLOCK B (8F)")
    draw_wrect(24, 30, 52, 42, (166, 152, 128), (44, 40, 34), "BLOCK C (5F)")
    draw_wrect(-10, -36, 18, -24, (176, 156, 122), (44, 40, 34), "BLOCK D (6F)")
    draw_wrect(68, -28, 80, 0, (166, 152, 128), (44, 40, 34), "BLK E")
    draw_wrect(-74, 2, -62, 30, (156, 144, 126), (44, 40, 34), "BLK F")
    draw_wrect(42, 6, 56, 22, (186, 168, 132), (62, 54, 42), "JEDNOTA")
    draw_wrect(42, -8, 56, 4, (186, 168, 132), (62, 54, 42), "VEČIERKA")
    draw_wrect(42, -25, 56, -11, (180, 162, 130), (62, 54, 42), "OPRAV.")
    draw_wrect(-22.5, -60, -13.5, -52, (198, 164, 108), (110, 62, 34), "VRÁTNICA")
    draw_wrect(-92, -62.5, -56, -55, (156, 152, 142), (56, 54, 48), "GARAGES 01-10")
    draw_wrect(-79, -19, -65, -9, (168, 154, 146), (72, 48, 42), "TRAFO")
    draw_wrect(-78, -40, -60, -24, (168, 148, 140), (72, 48, 42), "KOTOLŇA")

    # Border & Compass Rose
    md.rectangle((18, 18, mw - 18, mh - 18), outline=(56, 52, 44), width=3)
    md.text((34, 24), "SÍDLISKO JAVOR — MAINTENANCE PLAN 1984 / REV. 1996", font=fnt(FONT_MONO_B, 17), fill=(44, 40, 34))
    md.text((mw - 92, 26), "N ↑", font=fnt(FONT_MONO_B, 22), fill=(150, 56, 44))
    mimg = add_film_grain(mimg, 5.0, 1984)
    mimg.save(out_dir / "javor_blueprint_map.png", optimize=True)
    print("GFX_OK: ui/javor_blueprint_map.png")


if __name__ == "__main__":
    build_logos()
    build_key_art()
    build_chapter_cards()
    build_loading_screens()
    build_icons()
    build_ui_textures()
    print("PROMPT03_GRAPHICS_COMPLETE")
