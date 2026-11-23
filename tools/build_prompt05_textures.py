r"""
Generates Prompt 05 period-authentic 1996 interior textures & posters into
D:\nocna-zmena-blok-14\assets\textures\:
- trafika_ads_1996.png       (1996 Central European press, LOTO, phone cards, cigarettes & price list board)
- grocery_posters_1996.png   (1996 Jednota store specials & price board: Čerstvé pečivo, Mlieko, Káva Standard)
- linoleum_worn_albedo/normal/roughness.png (speckled worn 1996 institutional linoleum)
- terrazzo_tile_albedo/normal/roughness.png (Central European panelák lobby terrazzo floor tiles)
"""
import pathlib
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(r"D:\nocna-zmena-blok-14")
TEX_DIR = ROOT / "assets" / "textures"
FONTS = ROOT / "assets" / "fonts"
FONT_SANS = str(FONTS / "bahnschrift.ttf")
FONT_MONO = str(FONTS / "consola.ttf")
FONT_MONO_B = str(FONTS / "consolab.ttf")


def fnt(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def save_pbr_from_height(prefix: str, albedo_rgb: np.ndarray, height: np.ndarray, rough: np.ndarray) -> None:
    TEX_DIR.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.clip(albedo_rgb, 0, 255).astype(np.uint8), mode="RGB").save(TEX_DIR / f"{prefix}_albedo.png")
    Image.fromarray(np.clip(rough * 255.0, 0, 255).astype(np.uint8), mode="L").save(TEX_DIR / f"{prefix}_roughness.png")
    gy, gx = np.gradient(height.astype(np.float32))
    nx = -gx * 2.4
    ny = -gy * 2.4
    nz = np.ones_like(nx)
    norm = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-6
    nimg = np.stack([(nx / norm) * 0.5 + 0.5, (ny / norm) * 0.5 + 0.5, (nz / norm) * 0.5 + 0.5], axis=2)
    Image.fromarray(np.clip(nimg * 255.0, 0, 255).astype(np.uint8), mode="RGB").save(TEX_DIR / f"{prefix}_normal.png")
    print(f"P5_PBR_OK: {prefix} (albedo/normal/roughness)")


def build_pbr_floors() -> None:
    rng = np.random.default_rng(199605)
    sz = 512

    # 1. Worn institutional speckled linoleum (Security Office & Shops)
    base = np.zeros((sz, sz, 3), dtype=np.float32)
    base[:, :, 0] = 122
    base[:, :, 1] = 118
    base[:, :, 2] = 104
    mottle = rng.normal(0.0, 7.0, (sz, sz))
    for c in range(3):
        base[:, :, c] += mottle
    # Subtle wear streaks & flecks
    speck_mask = rng.random((sz, sz)) < 0.08
    base[speck_mask] *= 0.76
    speck_hi = rng.random((sz, sz)) < 0.04
    base[speck_hi] += 26.0
    # Tile seams every 128px
    h_map = rng.normal(0.5, 0.04, (sz, sz))
    rough = np.full((sz, sz), 0.56, dtype=np.float32) + rng.normal(0.0, 0.06, (sz, sz))
    for i in range(0, sz, 128):
        base[i:i + 2, :, :] *= 0.62
        base[:, i:i + 2, :] *= 0.62
        h_map[i:i + 2, :] -= 0.25
        h_map[:, i:i + 2] -= 0.25
        rough[i:i + 2, :] = 0.85
    save_pbr_from_height("linoleum_worn", base, h_map, np.clip(rough, 0.25, 0.92))

    # 2. Panelák Lobby Terrazzo Stone Tile
    tbase = np.zeros((sz, sz, 3), dtype=np.float32)
    tbase[:, :, 0] = 136
    tbase[:, :, 1] = 134
    tbase[:, :, 2] = 126
    tbase += rng.normal(0.0, 5.5, (sz, sz, 1))
    # Terrazzo stone aggregate chips
    for _ in range(1800):
        cx = int(rng.integers(0, sz - 6))
        cy = int(rng.integers(0, sz - 6))
        cw = int(rng.integers(2, 6))
        ch = int(rng.integers(2, 6))
        chip_col = rng.choice([76, 98, 168, 184])
        tbase[cy:cy + ch, cx:cx + cw, :] = chip_col + rng.normal(0, 6, 3)
    th = rng.normal(0.5, 0.03, (sz, sz))
    tr = np.full((sz, sz), 0.44, dtype=np.float32) + rng.normal(0.0, 0.05, (sz, sz))
    for i in range(0, sz, 128):
        tbase[i:i + 3, :, :] *= 0.52
        tbase[:, i:i + 3, :] *= 0.52
        th[i:i + 3, :] -= 0.35
        th[:, i:i + 3] -= 0.35
        tr[i:i + 3, :] = 0.90
    save_pbr_from_height("terrazzo_tile", tbase, th, np.clip(tr, 0.20, 0.95))


def build_1996_posters() -> None:
    TEX_DIR.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(199699)

    # 1. trafika_ads_1996.png (512x512)
    img = Image.new("RGB", (512, 512), (208, 198, 174))
    d = ImageDraw.Draw(img)
    d.rectangle((10, 10, 502, 502), outline=(44, 40, 36), width=5)
    # Top banner: DENNÁ TLAČ / NOVINY / TABAK
    d.rectangle((20, 20, 492, 96), fill=(32, 74, 58))
    d.text((40, 36), "TRAFIKA • TLAČ • TABAK", font=fnt(FONT_SANS, 38), fill=(236, 224, 188))
    # Left panel: LOTO / ŠPORTKA
    d.rectangle((24, 114, 246, 304), fill=(214, 168, 42), outline=(48, 38, 22), width=3)
    d.text((46, 128), "ŠPORTKA", font=fnt(FONT_SANS, 40), fill=(142, 26, 22))
    d.text((42, 184), "ŽREBOVANIE NEDEĽA", font=fnt(FONT_MONO_B, 17), fill=(34, 28, 20))
    d.text((42, 218), "TIKET ..... 12 Sk", font=fnt(FONT_MONO_B, 19), fill=(26, 24, 20))
    d.text((42, 250), "TELEFÓNNA KARTA", font=fnt(FONT_MONO_B, 17), fill=(22, 46, 98))
    d.text((42, 274), "50 / 100 IMPULZOV", font=fnt(FONT_MONO, 16), fill=(22, 46, 98))
    # Right panel: 1996 Price list & Cigarette brands
    d.rectangle((264, 114, 488, 304), fill=(226, 220, 202), outline=(52, 48, 44), width=3)
    d.text((280, 126), "CENNÍK 1996", font=fnt(FONT_MONO_B, 22), fill=(138, 32, 26))
    items = [
        "NOVINY DENNÍK  7 Sk",
        "TV PROGRAM    14 Sk",
        "CIGARETY      34 Sk",
        "ZÁPALKY        2 Sk",
        "MHD LÍSTOK     8 Sk",
        "KARTA 50 IMP 150 Sk",
    ]
    for idx, line in enumerate(items):
        d.text((276, 162 + idx * 22), line, font=fnt(FONT_MONO, 15), fill=(36, 34, 30))
    # Bottom strip: Opening hours
    d.rectangle((24, 324, 488, 486), fill=(46, 48, 52), outline=(196, 152, 74), width=3)
    d.text((46, 342), "OTVÁRACIE HODINY / HOURS", font=fnt(FONT_MONO_B, 22), fill=(224, 176, 86))
    d.text((46, 384), "PO – PIA: 05:30 – 23:00", font=fnt(FONT_MONO_B, 21), fill=(230, 224, 206))
    d.text((46, 418), "SOBOTA:   06:00 – 22:00", font=fnt(FONT_MONO_B, 21), fill=(230, 224, 206))
    d.text((46, 452), "NOČNÉ OKIENKO PRE STRÁŽNIKOV", font=fnt(FONT_MONO, 15), fill=(168, 176, 166))
    arr = np.clip(np.asarray(img, dtype=np.float32) + rng.normal(0, 7.0, (512, 512, 1)), 0, 255).astype(np.uint8)
    Image.fromarray(arr).save(TEX_DIR / "trafika_ads_1996.png")
    print("P5_TEX_OK: trafika_ads_1996.png")

    # 2. grocery_posters_1996.png (512x512)
    gimg = Image.new("RGB", (512, 512), (218, 210, 186))
    gd = ImageDraw.Draw(gimg)
    gd.rectangle((10, 10, 502, 502), outline=(58, 42, 28), width=5)
    gd.rectangle((20, 20, 492, 104), fill=(144, 38, 30))
    gd.text((48, 38), "POTRAVINY JEDNOTA", font=fnt(FONT_SANS, 42), fill=(242, 226, 182))
    rows = [
        ("CHLIEB KONZUMNÝ 1kg", "18.50 Sk"),
        ("MLIEKO POLOTUČNÉ 1L", "14.90 Sk"),
        ("KÁVA STANDARD 100g", "29.00 Sk"),
        ("MASLO ČERSTVÉ 250g", "32.50 Sk"),
        ("SALÁMA TRVANLIVÁ", "68.00 Sk"),
        ("BATÉRIA 4.5V PLOCHÁ", "24.00 Sk"),
    ]
    for idx, (lbl, pr) in enumerate(rows):
        y = 132 + idx * 54
        gd.rectangle((28, y, 484, y + 44), fill=(230, 224, 204), outline=(146, 134, 112), width=2)
        gd.text((42, y + 11), lbl, font=fnt(FONT_MONO_B, 19), fill=(36, 32, 28))
        gd.text((356, y + 10), pr, font=fnt(FONT_MONO_B, 21), fill=(154, 34, 26))
    gd.text((42, 466), "SÍDLISKO JAVOR • ZÁSOBOVANIE ZO ZADNEJ ULIČKY", font=fnt(FONT_MONO, 15), fill=(72, 66, 56))
    garr = np.clip(np.asarray(gimg, dtype=np.float32) + rng.normal(0, 6.5, (512, 512, 1)), 0, 255).astype(np.uint8)
    Image.fromarray(garr).save(TEX_DIR / "grocery_posters_1996.png")
    print("P5_TEX_OK: grocery_posters_1996.png")


if __name__ == "__main__":
    build_pbr_floors()
    build_1996_posters()
    print("PROMPT05_TEXTURES_COMPLETE")
