r"""
Generates 8 seamless 512x512 PBR texture triplets (*_albedo.png, *_normal.png, *_roughness.png)
and 6 authentic weathered 1995 Slovak metal/paper signs into D:\nocna-zmena-blok-14\assets\textures\.
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
        # Upsample cleanly using periodic FFT / bilinear wrap
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
    # Periodic Sobel derivatives on heightmap [0..1]
    dx = sobel(h, axis=1, mode="wrap") * (strength / 8.0)
    dy = sobel(h, axis=0, mode="wrap") * (strength / 8.0)
    nx = -dx
    ny = dy  # OpenGL / Godot +Y tangent orientation
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


def build_cobble():
    # Cellular stone blocks + wet reflective puddle masks
    y, x = np.mgrid[0:SIZE, 0:SIZE]
    rows = 12
    cols = 8
    ch = SIZE / rows
    cw = SIZE / cols
    row_idx = (y // ch).astype(np.int32)
    x_shifted = (x + (row_idx % 2) * (cw * 0.5)) % SIZE
    col_idx = (x_shifted // cw).astype(np.int32)

    u = (x_shifted % cw) / cw * 2.0 - 1.0
    v = (y % ch) / ch * 2.0 - 1.0
    # Rounded stone pillow profile
    dist = np.maximum(np.abs(u) ** 2.4, np.abs(v) ** 2.4)
    stone_dome = np.clip(1.0 - dist, 0.0, 1.0) ** 0.45

    rng = np.random.default_rng(101)
    cell_tint = rng.uniform(0.75, 1.18, (rows, cols))
    tint_map = cell_tint[row_idx % rows, col_idx % cols]

    micro = tileable_fbm(SIZE, seed=102, octaves=(8, 16, 32, 64), weights=(0.35, 0.3, 0.2, 0.15))
    puddle_noise = tileable_fbm(SIZE, seed=103, octaves=(2, 4, 8), weights=(0.55, 0.3, 0.15))
    puddles = np.clip((0.46 - puddle_noise) * 4.5, 0.0, 1.0)

    height = np.clip(stone_dome * 0.82 + micro * 0.18, 0.0, 1.0)
    mortar = (stone_dome < 0.18).astype(np.float32)

    # Dark wet basalt stone colors
    base = np.stack([
        0.13 * tint_map * (0.65 + 0.35 * micro),
        0.14 * tint_map * (0.65 + 0.35 * micro),
        0.16 * tint_map * (0.65 + 0.35 * micro),
    ], axis=-1)
    mortar_col = np.array([0.055, 0.058, 0.062], dtype=np.float32)
    albedo = base * (1.0 - mortar[..., None]) + mortar_col * mortar[..., None]
    # Darken wet puddles slightly
    albedo *= (1.0 - puddles[..., None] * 0.32)

    roughness = np.clip(0.68 - stone_dome * 0.12 + micro * 0.16 - puddles * 0.56, 0.09, 0.92)
    save_pbr("cobble", albedo, height, roughness, norm_strength=4.8)


def build_plaster(name: str, c_hi: tuple, c_lo: tuple, seed: int):
    fbm = tileable_fbm(SIZE, seed=seed)
    fine = tileable_fbm(SIZE, seed=seed + 11, octaves=(16, 32, 64), weights=(0.45, 0.35, 0.2))
    # Vertical rain-drip grime streaks (stronger at bottom and top eaves)
    streak_x = tileable_fbm(SIZE, seed=seed + 22, octaves=(8, 16, 32), weights=(0.5, 0.3, 0.2))
    y_grad = np.linspace(0.0, 1.0, SIZE, dtype=np.float32)[:, None]
    damp = np.clip(np.sin(y_grad * np.pi) * 0.2 + (1.0 - y_grad) * 0.45 + y_grad * 0.65, 0.0, 1.0)
    streaks = np.clip((streak_x - 0.38) * 1.8 * damp, 0.0, 0.85)

    # Subtle exposed brick patch underneath chipped plaster
    chip_mask = np.clip((0.28 - fbm) * 7.0, 0.0, 1.0)
    height = np.clip(fbm * 0.65 + fine * 0.35 - chip_mask * 0.45, 0.0, 1.0)

    chi = np.array(c_hi, dtype=np.float32)
    clo = np.array(c_lo, dtype=np.float32)
    chip_col = np.array([0.24, 0.13, 0.10], dtype=np.float32)

    albedo = clo + (chi - clo) * (fbm * 0.7 + fine * 0.3)[..., None]
    albedo = albedo * (1.0 - streaks[..., None] * 0.42)
    albedo = albedo * (1.0 - chip_mask[..., None]) + chip_col * chip_mask[..., None]

    roughness = np.clip(0.84 + fine * 0.14 - streaks * 0.22, 0.48, 0.98)
    save_pbr(name, albedo, height, roughness, norm_strength=2.8)


def build_brick_cellar():
    y, x = np.mgrid[0:SIZE, 0:SIZE]
    rows, cols = 16, 8
    ch, cw = SIZE / rows, SIZE / cols
    row_idx = (y // ch).astype(np.int32)
    xs = (x + (row_idx % 2) * (cw * 0.5)) % SIZE
    col_idx = (xs // cw).astype(np.int32)

    u = (xs % cw) / cw
    v = (y % ch) / ch
    edge_u = np.minimum(u, 1.0 - u)
    edge_v = np.minimum(v, 1.0 - v)
    brick_mask = np.clip(np.minimum(edge_u * 14.0, edge_v * 9.0), 0.0, 1.0)

    rng = np.random.default_rng(303)
    cell_var = rng.uniform(0.68, 1.18, (rows, cols))
    var_map = cell_var[row_idx % rows, col_idx % cols]
    grit = tileable_fbm(SIZE, seed=304)
    soot = np.clip((grit - 0.52) * 2.1, 0.0, 0.75)

    height = np.clip(brick_mask * 0.78 + grit * 0.22, 0.0, 1.0)
    brick_col = np.stack([
        0.34 * var_map * (0.75 + 0.25 * grit),
        0.15 * var_map * (0.75 + 0.25 * grit),
        0.11 * var_map * (0.75 + 0.25 * grit),
    ], axis=-1)
    mortar_col = np.array([0.14, 0.13, 0.12], dtype=np.float32)
    albedo = mortar_col * (1.0 - brick_mask[..., None]) + brick_col * brick_mask[..., None]
    albedo *= (1.0 - soot[..., None] * 0.48)

    roughness = np.clip(0.88 - soot * 0.18 + (1.0 - brick_mask) * 0.08, 0.55, 0.98)
    save_pbr("brick_cellar", albedo, height, roughness, norm_strength=4.5)


def build_wood_gallery():
    y, x = np.mgrid[0:SIZE, 0:SIZE]
    planks = 8
    pw = SIZE / planks
    plank_idx = (x // pw).astype(np.int32)
    u = (x % pw) / pw
    groove = np.clip(np.minimum(u, 1.0 - u) * 24.0, 0.0, 1.0)

    rng = np.random.default_rng(404)
    p_var = rng.uniform(0.75, 1.15, planks)[plank_idx % planks]
    grain_noise = tileable_fbm(SIZE, seed=405, octaves=(8, 16, 64), weights=(0.45, 0.35, 0.2))
    grain = 0.5 + 0.5 * np.sin((x * 0.38 + grain_noise * 18.0))
    damp = tileable_fbm(SIZE, seed=406, octaves=(4, 8), weights=(0.6, 0.4))

    height = np.clip(groove * 0.68 + grain * 0.22 + grain_noise * 0.1, 0.0, 1.0)
    albedo = np.stack([
        0.22 * p_var * (0.65 + 0.35 * grain),
        0.15 * p_var * (0.65 + 0.35 * grain),
        0.10 * p_var * (0.65 + 0.35 * grain),
    ], axis=-1)
    albedo *= groove[..., None] * 0.8 + 0.2
    albedo *= (1.0 - np.clip((0.45 - damp) * 1.4, 0.0, 0.4)[..., None])

    roughness = np.clip(0.76 - damp * 0.35 + (1.0 - groove) * 0.2, 0.28, 0.95)
    save_pbr("wood_gallery", albedo, height, roughness, norm_strength=3.6)


def build_concrete():
    fbm = tileable_fbm(SIZE, seed=505)
    fine = tileable_fbm(SIZE, seed=506, octaves=(16, 32, 64), weights=(0.4, 0.35, 0.25))
    pits = np.clip((0.22 - fine) * 6.0, 0.0, 0.5)
    height = np.clip(fbm * 0.55 + fine * 0.45 - pits, 0.0, 1.0)
    val = 0.17 + 0.14 * fbm - pits * 0.08
    albedo = np.stack([val * 0.98, val * 1.0, val * 1.02], axis=-1)
    roughness = np.clip(0.84 + fine * 0.12 - (0.4 - fbm).clip(0.0, 0.4) * 0.5, 0.45, 0.98)
    save_pbr("concrete_dark", albedo, height, roughness, norm_strength=2.6)


def build_shutter_metal():
    y, x = np.mgrid[0:SIZE, 0:SIZE]
    rib = 0.5 + 0.5 * np.sin((y / SIZE) * np.pi * 2.0 * 24.0)
    grime = tileable_fbm(SIZE, seed=606)
    rust = np.clip((grime - 0.56) * 2.6, 0.0, 1.0)
    height = np.clip(rib * 0.82 + grime * 0.18, 0.0, 1.0)

    steel = np.array([0.22, 0.24, 0.26], dtype=np.float32) * (0.72 + 0.28 * rib[..., None])
    rust_col = np.array([0.32, 0.14, 0.07], dtype=np.float32)
    albedo = steel * (1.0 - rust[..., None]) + rust_col * rust[..., None]
    roughness = np.clip(0.38 + rust * 0.48 + grime * 0.12, 0.26, 0.92)
    save_pbr("shutter_metal", albedo, height, roughness, norm_strength=4.2)


def build_iron_rusted():
    fbm = tileable_fbm(SIZE, seed=707)
    fine = tileable_fbm(SIZE, seed=708, octaves=(16, 32, 64), weights=(0.4, 0.35, 0.25))
    rust = np.clip((fbm - 0.48) * 2.2, 0.0, 1.0)
    height = np.clip(fbm * 0.5 + fine * 0.5, 0.0, 1.0)
    metal_col = np.array([0.11, 0.12, 0.13], dtype=np.float32)
    rust_col = np.array([0.28, 0.12, 0.06], dtype=np.float32)
    albedo = metal_col * (1.0 - rust[..., None]) + rust_col * rust[..., None]
    albedo *= (0.75 + 0.25 * fine[..., None])
    roughness = np.clip(0.42 + rust * 0.46, 0.32, 0.95)
    save_pbr("iron_rusted", albedo, height, roughness, norm_strength=3.4)


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


def make_weathered_sign(filename: str, bg_rgb: tuple, border_rgb: tuple, text_rgb: tuple,
                        line1: str, line2: str, w: int = 512, h: int = 256, seed: int = 901):
    img = Image.new("RGB", (w, h), bg_rgb)
    draw = ImageDraw.Draw(img)
    draw.rectangle([10, 10, w - 11, h - 11], outline=border_rgb, width=6)

    f1 = load_font(42 if w == 512 and h == 256 else 36)
    f2 = load_font(20 if w == 512 and h == 512 else 22)

    bbox1 = draw.textbbox((0, 0), line1, font=f1)
    tw1, th1 = bbox1[2] - bbox1[0], bbox1[3] - bbox1[1]
    draw.text(((w - tw1) / 2, h * 0.28 - th1 / 2), line1, font=f1, fill=text_rgb)

    if line2:
        bbox2 = draw.textbbox((0, 0), line2, font=f2)
        tw2, th2 = bbox2[2] - bbox2[0], bbox2[3] - bbox2[1]
        draw.text(((w - tw2) / 2, h * 0.66 - th2 / 2), line2, font=f2, fill=text_rgb)

    # Corner mounting bolts
    for bx, by in [(24, 24), (w - 25, 24), (24, h - 25), (w - 25, h - 25)]:
        draw.ellipse([bx - 6, by - 6, bx + 6, by + 6], fill=(55, 50, 48), outline=(25, 22, 20))

    # Grime & rust scratch overlay
    arr = np.asarray(img, dtype=np.float32) / 255.0
    grime = tileable_fbm(max(w, h), seed=seed)[:h, :w]
    rust = np.clip((grime - 0.64) * 2.8, 0.0, 0.72)
    rust_col = np.array([0.24, 0.11, 0.06], dtype=np.float32)
    arr = arr * (0.68 + 0.32 * grime[..., None])
    arr = arr * (1.0 - rust[..., None]) + rust_col * rust[..., None]
    out_u8 = (np.clip(arr, 0.0, 1.0) * 255.0).astype(np.uint8)
    Image.fromarray(out_u8, mode="RGB").save(OUT_DIR / filename)
    print(f"SAVED_SIGN={filename}")


def main():
    build_cobble()
    build_plaster("plaster_ochre", (0.39, 0.32, 0.22), (0.21, 0.18, 0.14), seed=201)
    build_plaster("plaster_grey", (0.27, 0.28, 0.29), (0.14, 0.15, 0.16), seed=202)
    build_brick_cellar()
    build_wood_gallery()
    build_concrete()
    build_shutter_metal()
    build_iron_rusted()

    # 6 Authentic 1995 Weathered English Signs & Eviction Poster
    make_weathered_sign("sign_vratnica.png", (24, 46, 82), (220, 216, 205), (232, 228, 215),
                        "GUARD BOOTH", "KOVAC SECURITY • 24/7", seed=901)
    make_weathered_sign("sign_hodinarstvo.png", (42, 30, 22), (195, 165, 92), (225, 198, 128),
                        "WATCHMAKER", "CLOCK & WATCH REPAIR", seed=902)
    make_weathered_sign("sign_notar.png", (38, 42, 46), (165, 168, 170), (208, 210, 206),
                        "NOTARY OFFICE", "EASTERN INVEST LTD.", seed=903)
    make_weathered_sign("sign_kotolna.png", (128, 28, 22), (222, 208, 160), (235, 222, 185),
                        "BOILER ROOM", "AUTHORIZED STAFF ONLY!", seed=904)
    make_weathered_sign("sign_blok14.png", (118, 24, 24), (235, 232, 225), (240, 238, 232),
                        "BLOCK 14", "ST. CATHERINE'S COURTYARD", seed=905)
    make_weathered_sign("poster_1995.png", (186, 174, 146), (48, 42, 36), (32, 28, 26),
                        "EVICTION NOTICE", "DEADLINE: NOV 17, 1995 • DEMOLITION", w=512, h=512, seed=906)


if __name__ == "__main__":
    main()
