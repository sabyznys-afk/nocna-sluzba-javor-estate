r"""
Generates Prompt 04 audio assets & icons:
- 9 new grounded spatial & interaction .ogg audio files in D:\nocna-zmena-blok-14\assets\audio\:
  * sfx_hotbar_scroll.ogg
  * sfx_door_handle.ogg
  * sfx_door_seal.ogg
  * sfx_door_bang.ogg
  * sfx_car_door_distant.ogg
  * sfx_upstairs_run.ogg
  * sfx_breathing_door.ogg
  * sfx_handle_jiggle.ogg
  * sfx_metal_impact.ogg
- 3 new unified 64x64 1990s hotbar icons in D:\nocna-zmena-blok-14\assets\graphics\icons\:
  * icon_hands.png
  * icon_watch.png
  * icon_taser.png
"""
import math
import os
import pathlib
import subprocess
import uuid
import numpy as np
import soundfile as sf
from PIL import Image, ImageDraw
from scipy import signal

os.environ.setdefault("TMP", r"D:\GameStudioTools\tmp")
os.environ.setdefault("TEMP", r"D:\GameStudioTools\tmp")

OUT_AUDIO = pathlib.Path(r"D:\nocna-zmena-blok-14\assets\audio")
OUT_ICONS = pathlib.Path(r"D:\nocna-zmena-blok-14\assets\graphics\icons")
TMP_DIR = pathlib.Path(r"D:\GameStudioTools\tmp")
FFMPEG = "ffmpeg"
SR = 44100


def ensure_stereo(arr: np.ndarray) -> np.ndarray:
    a = np.asarray(arr, dtype=np.float32)
    if a.ndim == 1:
        a = np.stack([a, a], axis=1)
    elif a.shape[1] == 1:
        a = np.repeat(a, 2, axis=1)
    return a


def normalize_stereo(arr: np.ndarray, peak: float = 0.85) -> np.ndarray:
    a = ensure_stereo(arr)
    mx = float(np.max(np.abs(a)))
    if mx > 1e-6:
        a = a * (peak / mx)
    return np.clip(a, -0.98, 0.98).astype(np.float32)


def encode_ogg(stereo: np.ndarray, name: str, peak: float = 0.84) -> None:
    OUT_AUDIO.mkdir(parents=True, exist_ok=True)
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    arr = normalize_stereo(stereo, peak=peak)
    tmp_wav = TMP_DIR / f"{uuid.uuid4().hex}.wav"
    out_ogg = OUT_AUDIO / name
    sf.write(str(tmp_wav), arr, SR, subtype="PCM_16")
    subprocess.run(
        [FFMPEG, "-y", "-hide_banner", "-loglevel", "error", "-i", str(tmp_wav), "-c:a", "libvorbis", "-q:a", "5", str(out_ogg)],
        check=True,
    )
    if tmp_wav.exists():
        tmp_wav.unlink()
    print(f"P4_AUDIO_OK: {name} ({out_ogg.stat().st_size} bytes)")


def build_audio() -> None:
    rng = np.random.default_rng(199604)

    # 1. sfx_hotbar_scroll.ogg — Subtle analog mechanical detent tick (0.065s)
    t = np.linspace(0, 0.065, int(SR * 0.065), endpoint=False)
    tick = (
        np.sin(2 * np.pi * 640 * t) * np.exp(-t * 95) * 0.65
        + np.sin(2 * np.pi * 1420 * t) * np.exp(-t * 140) * 0.35
        + rng.normal(0, 0.25, t.size) * np.exp(-t * 160)
    )
    encode_ogg(tick, "sfx_hotbar_scroll.ogg", peak=0.72)

    # 2. sfx_door_handle.ogg — Brass lever depress + spring latch click (0.34s)
    t = np.linspace(0, 0.34, int(SR * 0.34), endpoint=False)
    depress = np.sin(2 * np.pi * 310 * t) * np.exp(-((t - 0.04) / 0.03) ** 2) * 0.55
    spring = np.sin(2 * np.pi * (480 + 180 * t) * t) * np.exp(-((t - 0.14) / 0.05) ** 2) * 0.45
    latch = (
        np.sin(2 * np.pi * 1180 * np.maximum(0, t - 0.21))
        * np.exp(-np.maximum(0, t - 0.21) * 85)
        * (t >= 0.21)
        * 0.85
    )
    scrape = signal.lfilter(*signal.butter(2, [350 / (SR / 2), 2600 / (SR / 2)], btype="band"), rng.normal(0, 0.22, t.size)) * np.exp(-t * 9.0)
    encode_ogg(depress + spring + latch + scrape, "sfx_door_handle.ogg", peak=0.82)

    # 3. sfx_door_seal.ogg — Weighted rubber seal compression + metal latch thud (0.42s)
    t = np.linspace(0, 0.42, int(SR * 0.42), endpoint=False)
    thud = np.sin(2 * np.pi * (105 * np.exp(-t * 7.0) + 42) * t) * np.exp(-t * 16.0) * 0.9
    click = np.sin(2 * np.pi * 890 * np.maximum(0, t - 0.025)) * np.exp(-np.maximum(0, t - 0.025) * 90) * (t >= 0.025) * 0.5
    air = signal.lfilter(*signal.butter(2, 320 / (SR / 2), btype="low"), rng.normal(0, 0.4, t.size)) * np.exp(-t * 18.0)
    encode_ogg(thud + click + air, "sfx_door_seal.ogg", peak=0.86)

    # 4. sfx_door_bang.ogg — Heavy sudden fist/shoulder impact against Security Office door + frame rattle (1.15s)
    t = np.linspace(0, 1.15, int(SR * 1.15), endpoint=False)
    boom = np.sin(2 * np.pi * (88 * np.exp(-t * 5.0) + 38) * t) * np.exp(-t * 8.5) * 1.0
    wood_crack = signal.lfilter(*signal.butter(2, [180 / (SR / 2), 1800 / (SR / 2)], btype="band"), rng.normal(0, 0.65, t.size)) * np.exp(-t * 14.0)
    rattle = np.zeros_like(t)
    for rt, rf in [(0.09, 420), (0.19, 390), (0.31, 410)]:
        dt = np.maximum(0, t - rt)
        rattle += np.sin(2 * np.pi * rf * dt) * np.exp(-dt * 42) * (t >= rt) * 0.35
    encode_ogg(boom + wood_crack + rattle, "sfx_door_bang.ogg", peak=0.94)

    # 5. sfx_car_door_distant.ogg — Heavy 1990s sedan door slam echoing across wet parking lot (1.4s)
    t = np.linspace(0, 1.4, int(SR * 1.4), endpoint=False)
    slam = np.sin(2 * np.pi * (125 * np.exp(-t * 9.0) + 52) * t) * np.exp(-t * 12.0) * 0.85
    metal_latch = np.sin(2 * np.pi * 680 * t) * np.exp(-t * 48.0) * 0.45
    echo = np.roll(slam * 0.32, int(SR * 0.18)) + np.roll(slam * 0.16, int(SR * 0.39))
    tail_noise = signal.lfilter(*signal.butter(2, [140 / (SR / 2), 950 / (SR / 2)], btype="band"), rng.normal(0, 0.25, t.size)) * np.exp(-t * 4.5)
    encode_ogg(slam + metal_latch + echo + tail_noise, "sfx_car_door_distant.ogg", peak=0.78)

    # 6. sfx_upstairs_run.ogg — 5 hurried heavy boot impacts across concrete ceiling above player (1.85s)
    t = np.linspace(0, 1.85, int(SR * 1.85), endpoint=False)
    steps = np.zeros_like(t)
    for st_t, amp in [(0.05, 0.65), (0.38, 0.78), (0.70, 0.88), (1.01, 0.94), (1.32, 0.72)]:
        dt = np.maximum(0, t - st_t)
        mask = (t >= st_t).astype(np.float32)
        thump = np.sin(2 * np.pi * (96 * np.exp(-dt * 12) + 48) * dt) * np.exp(-dt * 16) * mask
        grit = signal.lfilter(*signal.butter(2, 420 / (SR / 2), btype="low"), rng.normal(0, 0.35, t.size)) * np.exp(-dt * 22) * mask
        steps += (thump + grit) * amp
    encode_ogg(steps, "sfx_upstairs_run.ogg", peak=0.84)

    # 7. sfx_breathing_door.ogg — Tense muffled human inhale/exhale right behind a closed wooden door (2.6s)
    t = np.linspace(0, 2.6, int(SR * 2.6), endpoint=False)
    raw = rng.normal(0, 0.45, t.size)
    breath_band = signal.lfilter(*signal.butter(3, [220 / (SR / 2), 1150 / (SR / 2)], btype="band"), raw)
    env = (
        np.exp(-((t - 0.55) / 0.32) ** 2) * 0.75
        + np.exp(-((t - 1.65) / 0.44) ** 2) * 0.95
    )
    vocal_formant = np.sin(2 * np.pi * 165 * t) * env * 0.12
    encode_ogg(breath_band * env + vocal_formant, "sfx_breathing_door.ogg", peak=0.74)

    # 8. sfx_handle_jiggle.ogg — Someone stealthily testing a locked door handle twice from outside (1.1s)
    t = np.linspace(0, 1.1, int(SR * 1.1), endpoint=False)
    jig = np.zeros_like(t)
    for jt, f1, f2 in [(0.08, 520, 1280), (0.24, 480, 1140), (0.58, 540, 1340), (0.76, 460, 1090)]:
        dt = np.maximum(0, t - jt)
        m = (t >= jt).astype(np.float32)
        jig += (np.sin(2 * np.pi * f1 * dt) * 0.55 + np.sin(2 * np.pi * f2 * dt) * 0.35) * np.exp(-dt * 48) * m
    scrape = signal.lfilter(*signal.butter(2, [400 / (SR / 2), 2400 / (SR / 2)], btype="band"), rng.normal(0, 0.18, t.size)) * np.exp(-((t - 0.45) / 0.35) ** 2)
    encode_ogg(jig + scrape, "sfx_handle_jiggle.ogg", peak=0.80)

    # 9. sfx_metal_impact.ogg — Resonant iron pipe / basement hatch clang echoing in courtyard (1.5s)
    t = np.linspace(0, 1.5, int(SR * 1.5), endpoint=False)
    modes = (
        np.sin(2 * np.pi * 284 * t) * np.exp(-t * 5.2) * 0.65
        + np.sin(2 * np.pi * 518 * t) * np.exp(-t * 7.8) * 0.48
        + np.sin(2 * np.pi * 876 * t) * np.exp(-t * 11.5) * 0.35
        + np.sin(2 * np.pi * 1410 * t) * np.exp(-t * 18.0) * 0.25
    )
    burst = signal.lfilter(*signal.butter(2, [200 / (SR / 2), 3200 / (SR / 2)], btype="band"), rng.normal(0, 0.5, t.size)) * np.exp(-t * 28.0)
    encode_ogg(modes + burst, "sfx_metal_impact.ogg", peak=0.85)


def build_icons() -> None:
    OUT_ICONS.mkdir(parents=True, exist_ok=True)
    fg = (224, 212, 182, 255)
    acc = (214, 158, 78, 255)

    # 1. icon_hands.png — Open security guard hand silhouette
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((20, 28, 46, 52), radius=5, outline=fg, width=3)
    for fx, fy in [(22, 12), (29, 9), (36, 10), (43, 14)]:
        d.line((fx, 28, fx, fy), fill=fg, width=3)
    d.line((20, 38, 12, 28), fill=acc, width=3)
    img.save(OUT_ICONS / "icon_hands.png")

    # 2. icon_watch.png — 1990s wrist watch face + strap
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle((25, 8, 39, 18), outline=fg, width=2)
    d.rectangle((25, 46, 39, 56), outline=fg, width=2)
    d.ellipse((16, 16, 48, 48), outline=fg, width=3)
    d.line((32, 32, 32, 22), fill=acc, width=3)
    d.line((32, 32, 41, 35), fill=acc, width=2)
    img.save(OUT_ICONS / "icon_watch.png")

    # 3. icon_taser.png — Compact stun device + high-voltage spark arc
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((12, 24, 42, 42), radius=4, outline=fg, width=3)
    d.line((42, 28, 48, 28), fill=acc, width=3)
    d.line((42, 38, 48, 38), fill=acc, width=3)
    d.line((50, 22, 56, 30), fill=acc, width=2)
    d.line((56, 30, 50, 34), fill=acc, width=2)
    d.line((50, 34, 57, 42), fill=acc, width=2)
    img.save(OUT_ICONS / "icon_taser.png")
    print("P4_ICONS_OK: icon_hands.png, icon_watch.png, icon_taser.png")


if __name__ == "__main__":
    build_audio()
    build_icons()
    print("PROMPT04_AUDIO_AND_ICONS_COMPLETE")
