r"""
Generates 2 additional 512x512 seamless PBR texture triplets (gravel_wet, mud_leaves)
into D:\nocna-zmena-blok-14\assets\textures\ for Prompt 02 ground surface variation.
"""
import pathlib
import numpy as np
from PIL import Image
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
    nx, ny, nz = -dx, dy, np.ones_like(h)
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


def build_gravel_wet():
    macro = tileable_fbm(SIZE, seed=2101, octaves=(4, 8, 16), weights=(0.55, 0.30, 0.15))
    stones = tileable_fbm(SIZE, seed=2102, octaves=(32, 64, 128), weights=(0.45, 0.35, 0.20))
    wet = np.clip((macro - 0.56) * 3.5, 0.0, 1.0)
    pebble = (stones > 0.56).astype(np.float32) * (stones - 0.56) * 2.2
    height = np.clip(0.42 + stones * 0.48 + pebble * 0.12 - wet * 0.16, 0.0, 1.0)
    c_stone = np.array([0.23, 0.23, 0.22], dtype=np.float32)
    c_grit = np.array([0.14, 0.135, 0.125], dtype=np.float32)
    albedo = c_grit * (1.0 - stones[..., None] * 0.65) + c_stone * (stones[..., None] * 0.65)
    albedo *= (1.0 - wet[..., None] * 0.35)
    roughness = np.clip(0.84 - wet * 0.58 + pebble * 0.10, 0.12, 0.96)
    save_pbr("gravel_wet", albedo, height, roughness, norm_strength=4.2)


def build_mud_leaves():
    macro = tileable_fbm(SIZE, seed=2201)
    leaf_noise = tileable_fbm(SIZE, seed=2202, octaves=(16, 32, 64), weights=(0.40, 0.35, 0.25))
    leaf_mask = np.clip((leaf_noise - 0.58) * 3.2, 0.0, 1.0)
    puddle = np.clip((0.42 - macro) * 2.8, 0.0, 1.0)

    c_mud = np.array([0.10, 0.08, 0.06], dtype=np.float32)
    c_leaf_rust = np.array([0.28, 0.16, 0.07], dtype=np.float32)
    c_leaf_ochre = np.array([0.34, 0.24, 0.09], dtype=np.float32)
    leaf_tint = np.where((macro > 0.52)[..., None], c_leaf_ochre, c_leaf_rust)
    albedo = c_mud * (1.0 - leaf_mask[..., None]) + leaf_tint * leaf_mask[..., None]
    albedo *= (1.0 - puddle[..., None] * 0.28)
    height = np.clip(0.45 + macro * 0.25 + leaf_mask * 0.28 - puddle * 0.18, 0.0, 1.0)
    roughness = np.clip(0.82 - puddle * 0.62 + leaf_mask * 0.12, 0.10, 0.95)
    save_pbr("mud_leaves", albedo, height, roughness, norm_strength=3.6)


def main():
    build_gravel_wet()
    build_mud_leaves()
    print("PROMPT02_TEXTURES_COMPLETE")


if __name__ == "__main__":
    main()
