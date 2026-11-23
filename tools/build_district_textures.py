r"""
Generates 3 new 512x512 seamless PBR texture triplets (asphalt_wet, panel_concrete, grass_autumn)
and 8 authentic 1992-1998 Central European district signs/maps into D:\nocna-zmena-blok-14\assets\textures\.
"""
import pathlib
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import gaussian_filter, sobel

OUT_DIR = pathlib.Path(r"D:\nocna-zmena-blok-14\assets\textures")
SIZE = 512


def tileable_fbm(size: int, seed: int, octaves=(4, 8, 16, 32, 64), weights=(0.42, 0.28, 0.16, 0.09, 0.05)) -> np.ndarray:
    rng = np.random.default_rng(seed)
    acc = np.zeros((size, size), dtype=np.float32)
    for freq, w in zip(octaves, weights):
        grid = rng.uniform(0.0, 1.0, (freq, freq)).astype(np.float32)
        step = size // freq
        up = np.repeat(np.repeat(grid, step, axis=0), step, axis=1)
        sigma = max(1.0, step * 0.55)
        smooth = gaussian_filter(up, sigma=sigma, mode="wrap")
        smin, smax = smooth.min(), smooth.max()
        if smax > smin:
            smooth = (smooth - smin) / (smax - smin)
        acc += smooth * w
    amin, amax = acc.min(), acc.max()
    return (acc - amin) / max(1e-6, amax - amin)


def height_to_normal(h: np.ndarray, strength: float = 3.2) -> np.ndarray:
    dx = sobel(h, axis=1, mode="wrap") * (strength / 8.0)
    dy = sobel(h, axis=0, mode="wrap") * (strength / 8.0)
    nx = -dx
    ny = dy
    nz = np.ones_like(h)
    norm = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-6
    r = np.clip((nx / norm) * 0.5 + 0.5, 0.0, 1.0)
    g = np.clip((ny / norm) * 0.5 + 0.5, 0.0, 1.0)
    b = np.clip((nz / norm) * 0.5 + 0.5, 0.0, 1.0)
    return (np.stack([r, g, b], axis=-1) * 255.0).astype(np.uint8)


def save_pbr(name: str, albedo_rgb: np.ndarray, height: np.ndarray, roughness: np.ndarray, norm_strength: float = 3.2):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    alb_u8 = (np.clip(albedo_rgb, 0.0, 1.0) * 255.0).astype(np.uint8)
    nrm_u8 = height_to_normal(height, strength=norm_strength)
    rgh_u8 = (np.clip(roughness, 0.04, 1.0) * 255.0).astype(np.uint8)
    Image.fromarray(alb_u8, mode="RGB").save(OUT_DIR / f"{name}_albedo.png")
    Image.fromarray(nrm_u8, mode="RGB").save(OUT_DIR / f"{name}_normal.png")
    Image.fromarray(rgh_u8, mode="L").save(OUT_DIR / f"{name}_roughness.png")
    print(f"SAVED_PBR={name}")


def build_asphalt_wet():
    coarse = tileable_fbm(SIZE, seed=1101, octaves=(4, 8, 16), weights=(0.55, 0.30, 0.15))
    grit = tileable_fbm(SIZE, seed=1102, octaves=(32, 64, 128), weights=(0.45, 0.35, 0.20))
    crack_field = tileable_fbm(SIZE, seed=1103, octaves=(8, 16, 32), weights=(0.5, 0.3, 0.2))
    cracks = np.clip(1.0 - np.abs(crack_field - 0.5) * 26.0, 0.0, 1.0) ** 1.8
    puddles = np.clip((coarse - 0.54) * 3.8, 0.0, 1.0)

    height = np.clip(0.55 + grit * 0.35 - cracks * 0.45 - puddles * 0.15, 0.0, 1.0)
    base_col = np.array([0.075, 0.080, 0.088], dtype=np.float32)
    speck_col = np.array([0.13, 0.135, 0.14], dtype=np.float32)
    albedo = base_col * (1.0 - grit[..., None] * 0.45) + speck_col * (grit[..., None] * 0.35)
    albedo *= (1.0 - cracks[..., None] * 0.55)
    albedo *= (1.0 - puddles[..., None] * 0.38)
    roughness = np.clip(0.78 - puddles * 0.64 + grit * 0.12, 0.08, 0.94)
    save_pbr("asphalt_wet", albedo, height, roughness, norm_strength=3.6)


def build_panel_concrete():
    y, x = np.mgrid[0:SIZE, 0:SIZE]
    fbm = tileable_fbm(SIZE, seed=1201)
    fine = tileable_fbm(SIZE, seed=1202, octaves=(16, 32, 64), weights=(0.4, 0.35, 0.25))
    streak = tileable_fbm(SIZE, seed=1203, octaves=(4, 8, 16), weights=(0.5, 0.3, 0.2))
    # Vertical weathering streaks
    v_streak = gaussian_filter(streak, sigma=(18.0, 2.0), mode="wrap")
    v_streak = (v_streak - v_streak.min()) / max(1e-6, v_streak.max() - v_streak.min())

    # Prefab panel grid (4 columns x 2 rows per tile)
    sx = np.abs(((x % (SIZE // 4)) - (SIZE // 8)))
    sy = np.abs(((y % (SIZE // 2)) - (SIZE // 4)))
    seam_x = (x % (SIZE // 4) < 5).astype(np.float32)
    seam_y = (y % (SIZE // 2) < 5).astype(np.float32)
    seams = np.clip(seam_x + seam_y, 0.0, 1.0)

    height = np.clip(0.62 + fbm * 0.20 + fine * 0.14 - seams * 0.48, 0.0, 1.0)
    col_slab = np.array([0.34, 0.345, 0.34], dtype=np.float32)
    col_stain = np.array([0.20, 0.205, 0.195], dtype=np.float32)
    albedo = col_slab * (1.0 - v_streak[..., None] * 0.45) + col_stain * (v_streak[..., None] * 0.45)
    albedo = albedo * (0.86 + 0.18 * fine[..., None])
    albedo *= (1.0 - seams[..., None] * 0.42)
    roughness = np.clip(0.76 + fine * 0.15 + seams * 0.10, 0.50, 0.96)
    save_pbr("panel_concrete", albedo, height, roughness, norm_strength=3.8)


def build_grass_autumn():
    fbm = tileable_fbm(SIZE, seed=1301)
    blades = tileable_fbm(SIZE, seed=1302, octaves=(32, 64, 128), weights=(0.45, 0.35, 0.20))
    soil_mask = np.clip((0.52 - fbm) * 2.5, 0.0, 1.0)
    leaf_mask = np.clip((blades - 0.68) * 3.5, 0.0, 1.0)

    col_grass = np.array([0.13, 0.16, 0.08], dtype=np.float32)
    col_soil = np.array([0.14, 0.11, 0.08], dtype=np.float32)
    col_leaf = np.array([0.28, 0.18, 0.08], dtype=np.float32)

    albedo = col_grass * (1.0 - soil_mask[..., None]) + col_soil * soil_mask[..., None]
    albedo = albedo * (0.8 + 0.35 * blades[..., None])
    albedo = albedo * (1.0 - leaf_mask[..., None] * 0.65) + col_leaf * (leaf_mask[..., None] * 0.65)
    height = np.clip(fbm * 0.45 + blades * 0.55, 0.0, 1.0)
    roughness = np.clip(0.84 - soil_mask * 0.18 + blades * 0.08, 0.58, 0.96)
    save_pbr("grass_autumn", albedo, height, roughness, norm_strength=3.2)


def load_font(size: int, serif: bool = False):
    candidates = [
        r"C:\Windows\Fonts\timesbd.ttf" if serif else r"C:\Windows\Fonts\arialbd.ttf",
        r"C:\Windows\Fonts\arial.ttf",
        r"C:\Windows\Fonts\segoeui.ttf",
    ]
    for path in candidates:
        if pathlib.Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def weather_overlay(img: Image.Image, seed: int, rust_str: float = 0.65) -> Image.Image:
    w, h = img.size
    arr = np.asarray(img, dtype=np.float32) / 255.0
    grime = tileable_fbm(max(w, h), seed=seed)[:h, :w]
    rust = np.clip((grime - 0.65) * 2.7, 0.0, rust_str)
    rust_col = np.array([0.22, 0.11, 0.06], dtype=np.float32)
    arr = arr * (0.72 + 0.28 * grime[..., None])
    arr = arr * (1.0 - rust[..., None]) + rust_col * rust[..., None]
    return Image.fromarray((np.clip(arr, 0.0, 1.0) * 255.0).astype(np.uint8), mode="RGB")


def make_weathered_sign(filename: str, bg_rgb: tuple, border_rgb: tuple, text_rgb: tuple,
                        line1: str, line2: str, w: int = 512, h: int = 256, seed: int = 950):
    img = Image.new("RGB", (w, h), bg_rgb)
    draw = ImageDraw.Draw(img)
    draw.rectangle([10, 10, w - 11, h - 11], outline=border_rgb, width=6)
    f1 = load_font(38 if len(line1) > 14 else 46)
    f2 = load_font(22)

    bbox1 = draw.textbbox((0, 0), line1, font=f1)
    tw1, th1 = bbox1[2] - bbox1[0], bbox1[3] - bbox1[1]
    draw.text(((w - tw1) / 2, h * 0.30 - th1 / 2), line1, font=f1, fill=text_rgb)

    if line2:
        bbox2 = draw.textbbox((0, 0), line2, font=f2)
        tw2, th2 = bbox2[2] - bbox2[0], bbox2[3] - bbox2[1]
        draw.text(((w - tw2) / 2, h * 0.68 - th2 / 2), line2, font=f2, fill=text_rgb)

    for bx, by in [(22, 22), (w - 23, 22), (22, h - 23), (w - 23, h - 23)]:
        draw.ellipse([bx - 5, by - 5, bx + 5, by + 5], fill=(55, 50, 48), outline=(25, 22, 20))

    weather_overlay(img, seed=seed).save(OUT_DIR / filename)
    print(f"SAVED_SIGN={filename}")


def make_billboard():
    w, h = 512, 512
    img = Image.new("RGB", (w, h), (168, 160, 138))
    draw = ImageDraw.Draw(img)
    draw.rectangle([16, 16, w - 17, h - 17], outline=(42, 38, 34), width=10)
    # Retro 1995 promo stripe
    draw.rectangle([28, 28, w - 29, 175], fill=(128, 34, 28))
    f1 = load_font(44)
    f2 = load_font(26)
    f3 = load_font(22)
    draw.text((48, 62), "ELEKTROKOV '95", font=f1, fill=(238, 228, 200))
    draw.text((48, 122), "REPAIRS • RADIOS • ANTENNAS", font=f3, fill=(230, 198, 120))
    # Torn missing person notice glued to lower half
    draw.rectangle([60, 220, 452, 468], fill=(208, 198, 175), outline=(65, 55, 45), width=4)
    draw.text((92, 245), "HĽADÁ SA / MISSING", font=f2, fill=(140, 22, 22))
    draw.text((92, 295), "ELENA K. (26) • LAST SEEN", font=f3, fill=(28, 26, 26))
    draw.text((92, 330), "NEAR SECTOR C • NOV 1995", font=f3, fill=(28, 26, 26))
    draw.text((92, 388), "REPORT TO GUARD OFFICE", font=f3, fill=(58, 52, 48))
    weather_overlay(img, seed=961, rust_str=0.45).save(OUT_DIR / "billboard_1995.png")
    print("SAVED_SIGN=billboard_1995.png")


def make_district_map():
    w, h = 512, 512
    img = Image.new("RGB", (w, h), (188, 182, 160))
    draw = ImageDraw.Draw(img)
    draw.rectangle([10, 10, w - 11, h - 11], outline=(35, 42, 52), width=6)
    f_hdr = load_font(24)
    f_lbl = load_font(16)
    draw.text((34, 22), "SECTOR PLAN — HOUSING DISTRICT (1995)", font=f_hdr, fill=(24, 34, 52))
    # North edge
    draw.text((220, 56), "N  (FOREST)", font=f_lbl, fill=(45, 75, 42))
    # Blocks A, B, C top row
    for bx, tag in [(85, "BLOK A"), (225, "BLOK B (8F)"), (365, "BLOK C")]:
        draw.rectangle([bx, 84, bx + 85, 134], fill=(120, 125, 130), outline=(30, 34, 38), width=3)
        draw.text((bx + 8, 100), tag, font=f_lbl, fill=(240, 240, 235))
    # Central park
    draw.rectangle([160, 180, 325, 295], fill=(138, 162, 122), outline=(45, 68, 42), width=2)
    draw.text((195, 225), "CENTRAL PARK", font=f_lbl, fill=(22, 34, 20))
    # Block F + Tech + Garages West
    draw.rectangle([42, 175, 125, 230], fill=(120, 125, 130), outline=(30, 34, 38), width=3)
    draw.text((52, 194), "BLOK F", font=f_lbl, fill=(240, 240, 235))
    draw.rectangle([38, 260, 125, 315], fill=(145, 118, 92), outline=(30, 34, 38), width=2)
    draw.text((44, 278), "BOILER/TECH", font=f_lbl, fill=(24, 22, 20))
    draw.rectangle([42, 345, 135, 392], fill=(108, 108, 110), outline=(30, 34, 38), width=2)
    draw.text((50, 360), "GARAGES", font=f_lbl, fill=(235, 235, 230))
    # Shops & Block E East
    draw.rectangle([358, 180, 425, 310], fill=(156, 132, 105), outline=(30, 34, 38), width=2)
    draw.text((366, 236), "SHOPS", font=f_lbl, fill=(25, 22, 20))
    draw.rectangle([438, 250, 488, 330], fill=(120, 125, 130), outline=(30, 34, 38), width=3)
    draw.text((442, 282), "BLK E", font=f_lbl, fill=(240, 240, 235))
    # Block D & Parking & Guard Office South
    draw.rectangle([205, 325, 295, 370], fill=(158, 144, 118), outline=(30, 34, 38), width=3)
    draw.text((222, 338), "BLOK D", font=f_lbl, fill=(24, 22, 20))
    draw.rectangle([250, 388, 365, 445], fill=(95, 98, 102), outline=(30, 34, 38), width=2)
    draw.text((272, 408), "PARKING", font=f_lbl, fill=(235, 235, 230))
    draw.rectangle([155, 405, 225, 452], fill=(42, 72, 108), outline=(220, 200, 140), width=3)
    draw.text((162, 420), "GUARD HQ", font=f_lbl, fill=(245, 235, 205))
    draw.text((34, 470), "MAIN GATE ->", font=f_lbl, fill=(135, 30, 24))
    weather_overlay(img, seed=962, rust_str=0.35).save(OUT_DIR / "district_map_1995.png")
    print("SAVED_SIGN=district_map_1995.png")


def main():
    build_asphalt_wet()
    build_panel_concrete()
    build_grass_autumn()

    make_weathered_sign("sign_jednota.png", (134, 26, 24), (234, 226, 204), (242, 236, 222),
                        "POTRAVINY JEDNOTA", "OPEN DAILY 06:00 - 19:00", seed=951)
    make_weathered_sign("sign_vecierka.png", (22, 52, 98), (222, 188, 68), (242, 214, 96),
                        "VEČIERKA", "NIGHT MARKET • 18:00 - 06:00", seed=952)
    make_weathered_sign("sign_trafika.png", (38, 62, 46), (208, 202, 182), (232, 226, 205),
                        "TRAFIKA", "PRESS • TOBACCO • TRANSIT", seed=953)
    make_weathered_sign("sign_opravovna.png", (52, 42, 34), (186, 152, 86), (228, 206, 148),
                        "OPRAVOVŇA", "ELECTRO • RADIO • LOCKS", seed=954)
    make_weathered_sign("sign_trafostanica.png", (202, 156, 24), (24, 22, 20), (22, 20, 18),
                        "POZOR! TRAFOSTANICA", "HIGH VOLTAGE • KEEP OUT", seed=955)
    make_weathered_sign("sign_bus_stop.png", (32, 74, 128), (226, 226, 220), (238, 238, 232),
                        "ZASTÁVKA MHD", "LINE 14 • NIGHT SERVICE SUSPENDED", seed=956)
    make_billboard()
    make_district_map()
    print("DISTRICT_TEXTURES_COMPLETE")


if __name__ == "__main__":
    main()
