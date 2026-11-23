r"""
Imports, slices, normalizes, crossfade-loops, and encodes the user's 13 custom studio audio recordings
into D:\nocna-zmena-blok-14\assets\audio\*.ogg for NOČNÁ SLUŽBA / NIGHT SHIFT.
"""
import os
import pathlib
import subprocess
import uuid
import numpy as np
import soundfile as sf

os.environ.setdefault("TMP", r"D:\GameStudioTools\tmp")
os.environ.setdefault("TEMP", r"D:\GameStudioTools\tmp")

SRC_DIR = pathlib.Path(r"C:\Users\arnos\.gemini\antigravity\brain\fbc9b55e-32cb-4056-b58a-9ebb03b2602b\.user_uploaded")
OUT_DIR = pathlib.Path(r"D:\nocna-zmena-blok-14\assets\audio")
TMP_DIR = pathlib.Path(r"D:\GameStudioTools\tmp")
SR = 44100


def load_uploaded(idx: int) -> np.ndarray:
    matches = sorted(SRC_DIR.glob(f"uploaded_media_{idx}_*.mp3"))
    if not matches:
        raise FileNotFoundError(f"Missing uploaded_media_{idx}_*.mp3")
    tmp_wav = TMP_DIR / f"dec_{idx}_{uuid.uuid4().hex[:6]}.wav"
    subprocess.run(
        ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", str(matches[0]), "-ar", str(SR), "-ac", "2", str(tmp_wav)],
        check=True,
    )
    data, _ = sf.read(str(tmp_wav), dtype="float32")
    if tmp_wav.exists():
        tmp_wav.unlink()
    if data.ndim == 1:
        data = np.stack([data, data], axis=1)
    return data.astype(np.float32)


def normalize(arr: np.ndarray, peak: float = 0.85) -> np.ndarray:
    mx = float(np.max(np.abs(arr)))
    if mx > 1e-6:
        arr = arr * (peak / mx)
    return np.clip(arr, -0.98, 0.98).astype(np.float32)


def apply_fades(arr: np.ndarray, fade_in_s: float = 0.008, fade_out_s: float = 0.035) -> np.ndarray:
    out = arr.copy()
    n_in = min(int(fade_in_s * SR), out.shape[0] // 3)
    n_out = min(int(fade_out_s * SR), out.shape[0] // 2)
    if n_in > 4:
        w = 0.5 - 0.5 * np.cos(np.linspace(0.0, np.pi, n_in, dtype=np.float32))[:, None]
        out[:n_in] *= w
    if n_out > 4:
        w = 0.5 + 0.5 * np.cos(np.linspace(0.0, np.pi, n_out, dtype=np.float32))[:, None]
        out[-n_out:] *= w
    return out


def make_seamless_loop(arr: np.ndarray, fade_s: float = 2.0) -> np.ndarray:
    nf = min(int(fade_s * SR), arr.shape[0] // 4)
    if nf <= 32:
        return arr
    out = arr.copy()
    head = out[:nf].copy()
    tail = out[-nf:].copy()
    w = np.linspace(0.0, 1.0, nf, dtype=np.float32)[:, None]
    out[:nf] = head * w + tail * (1.0 - w)
    return out[:-nf]


def trim_slice(arr: np.ndarray, t0: float, t1: float, snap_onset: bool = False) -> np.ndarray:
    i0 = max(0, int(t0 * SR))
    i1 = min(arr.shape[0], int(t1 * SR))
    seg = arr[i0:i1].copy()
    if snap_onset and seg.shape[0] > int(0.08 * SR):
        # Trim leading silence up to 12ms before first 15%-peak transient so footsteps trigger with zero latency
        env = np.max(np.abs(seg), axis=1)
        pk = float(np.max(env))
        if pk > 1e-4:
            hits = np.where(env >= pk * 0.14)[0]
            if len(hits) > 0:
                start = max(0, int(hits[0]) - int(0.012 * SR))
                seg = seg[start:]
    return seg


def save_ogg(arr: np.ndarray, filename: str, peak: float = 0.85, q: str = "6") -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    normed = normalize(arr, peak=peak)
    tmp_wav = TMP_DIR / f"enc_{uuid.uuid4().hex[:8]}.wav"
    out_ogg = OUT_DIR / filename
    sf.write(str(tmp_wav), normed, SR, subtype="PCM_16")
    subprocess.run(
        ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", str(tmp_wav), "-c:a", "libvorbis", "-q:a", q, str(out_ogg)],
        check=True,
    )
    if tmp_wav.exists():
        tmp_wav.unlink()
    print(f"CUSTOM_OGG_OK: {filename:30s} dur={normed.shape[0]/SR:5.2f}s  size={out_ogg.stat().st_size} bytes")


def main() -> None:
    # 0. Subtle Tension Drone -> music_tension_drone.ogg (seamless loop)
    a0 = load_uploaded(0)
    save_ogg(make_seamless_loop(a0, 3.0), "music_tension_drone.ogg", peak=0.80, q="6")

    # 1. 1990s Walkman Cassette Track -> music_walkman_tape.ogg (seamless loop)
    a1 = load_uploaded(1)
    save_ogg(make_seamless_loop(a1, 1.8), "music_walkman_tape.ogg", peak=0.84, q="6")

    # 2. Main Theme (Cold Upright Piano & Rain) -> music_menu_theme.ogg (seamless loop)
    a2 = load_uploaded(2)
    save_ogg(make_seamless_loop(a2, 2.2), "music_menu_theme.ogg", peak=0.86, q="6")

    # 3. Echoing Stairwell Footsteps Running & Stopping -> sfx_upstairs_run.ogg + indoor sfx_step_wood_1..4.ogg
    a3 = load_uploaded(3)
    save_ogg(apply_fades(trim_slice(a3, 0.45, 14.35), 0.03, 0.15), "sfx_upstairs_run.ogg", peak=0.84, q="5")
    for idx, (s0, s1) in enumerate([(1.15, 1.72), (2.15, 2.75), (3.40, 4.00), (6.88, 7.50)], start=1):
        seg = apply_fades(trim_slice(a3, s0, s1, snap_onset=True), 0.006, 0.045)
        save_ogg(seg, f"sfx_step_wood_{idx}.ogg", peak=0.82, q="5")

    # 4. Player Tired & Exhausted Breathing -> sfx_breath_tired.ogg & sfx_breath_exhausted.ogg
    a4 = load_uploaded(4)
    save_ogg(apply_fades(trim_slice(a4, 0.12, 5.10), 0.04, 0.12), "sfx_breath_tired.ogg", peak=0.80, q="5")
    save_ogg(apply_fades(trim_slice(a4, 8.20, 13.85), 0.06, 0.16), "sfx_breath_exhausted.ogg", peak=0.84, q="5")

    # 5. Muffled Human Breathing Behind Closed Door -> sfx_breathing_door.ogg
    a5 = load_uploaded(5)
    save_ogg(apply_fades(trim_slice(a5, 0.20, 16.40), 0.08, 0.25), "sfx_breathing_door.ogg", peak=0.80, q="5")

    # 6. Foggy November Night Exterior Ambience -> amb_rain_city.ogg (seamless loop)
    a6 = load_uploaded(6)
    save_ogg(make_seamless_loop(a6, 2.5), "amb_rain_city.ogg", peak=0.78, q="6")

    # 7. Heavy Steel Door Handle, Seal, Handle Jiggle & Violent Bang
    a7 = load_uploaded(7)
    save_ogg(apply_fades(trim_slice(a7, 0.10, 1.15, snap_onset=True), 0.005, 0.04), "sfx_door_handle.ogg", peak=0.84, q="5")
    save_ogg(apply_fades(trim_slice(a7, 1.18, 2.02, snap_onset=True), 0.005, 0.05), "sfx_door_seal.ogg", peak=0.86, q="5")
    save_ogg(apply_fades(trim_slice(a7, 2.52, 3.38, snap_onset=True), 0.008, 0.05), "sfx_handle_jiggle.ogg", peak=0.82, q="5")
    save_ogg(apply_fades(trim_slice(a7, 3.40, 6.25, snap_onset=True), 0.004, 0.15), "sfx_door_bang.ogg", peak=0.92, q="6")

    # 9. Echoing Concrete/Metal Industrial Stairwell Steps -> sfx_step_metal_1..4.ogg
    a9 = load_uploaded(9)
    for idx, (s0, s1) in enumerate([(3.38, 3.95), (4.42, 5.02), (7.90, 8.48), (12.40, 13.08)], start=1):
        seg = apply_fades(trim_slice(a9, s0, s1, snap_onset=True), 0.006, 0.045)
        save_ogg(seg, f"sfx_step_metal_{idx}.ogg", peak=0.84, q="5")

    # 10. Wet Grass & Fallen Autumn Oak Leaves -> sfx_step_grass_1..4.ogg
    a10 = load_uploaded(10)
    for idx, (s0, s1) in enumerate([(0.20, 0.85), (1.55, 2.25), (3.95, 4.65), (7.90, 8.60)], start=1):
        seg = apply_fades(trim_slice(a10, s0, s1, snap_onset=True), 0.006, 0.045)
        save_ogg(seg, f"sfx_step_grass_{idx}.ogg", peak=0.82, q="5")

    # 11. Damp Park Gravel & Leaves -> sfx_step_gravel_1..4.ogg
    a11 = load_uploaded(11)
    for idx, (s0, s1) in enumerate([(0.95, 1.48), (1.50, 2.28), (3.68, 4.24), (5.95, 6.52)], start=1):
        seg = apply_fades(trim_slice(a11, s0, s1, snap_onset=True), 0.006, 0.045)
        save_ogg(seg, f"sfx_step_gravel_{idx}.ogg", peak=0.82, q="5")

    # 12. Heavy Guard Boots on Wet Asphalt & Cracked Concrete -> sfx_step_cobble_1..4.ogg
    a12 = load_uploaded(12)
    for idx, (s0, s1) in enumerate([(1.40, 1.95), (2.18, 2.70), (3.92, 4.45), (7.65, 8.20)], start=1):
        seg = apply_fades(trim_slice(a12, s0, s1, snap_onset=True), 0.005, 0.040)
        save_ogg(seg, f"sfx_step_cobble_{idx}.ogg", peak=0.86, q="5")

    print("ALL_CUSTOM_AUDIO_INTEGRATED_SUCCESSFULLY")


if __name__ == "__main__":
    main()
