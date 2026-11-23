r"""
Generates 6 subtle analog UI & story feedback SFX into D:\nocna-zmena-blok-14\assets\audio\:
- sfx_ui_hover.ogg
- sfx_ui_press.ogg
- sfx_page_turn.ogg
- sfx_cassette_click.ogg
- sfx_intercom_buzz.ogg
- sfx_power_out.ogg
"""
import os
import pathlib
import subprocess
import uuid
import numpy as np
import soundfile as sf
from scipy import signal

os.environ.setdefault("TMP", r"D:\GameStudioTools\tmp")
os.environ.setdefault("TEMP", r"D:\GameStudioTools\tmp")

OUT_DIR = pathlib.Path(r"D:\nocna-zmena-blok-14\assets\audio")
TMP_DIR = pathlib.Path(r"D:\GameStudioTools\tmp")
SR = 44100


def save_ogg(sig: np.ndarray, name: str, peak: float = 0.72) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    arr = np.asarray(sig, dtype=np.float32)
    if arr.ndim == 1:
        arr = np.stack([arr, arr], axis=1)
    mx = float(np.max(np.abs(arr)))
    if mx > 1e-6:
        arr = arr * (peak / mx)
    tmp_wav = TMP_DIR / f"{uuid.uuid4().hex}.wav"
    out_ogg = OUT_DIR / name
    sf.write(str(tmp_wav), np.clip(arr, -0.96, 0.96), SR, subtype="PCM_16")
    subprocess.run(
        ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", str(tmp_wav), "-c:a", "libvorbis", "-q:a", "5", str(out_ogg)],
        check=True,
    )
    if tmp_wav.exists():
        tmp_wav.unlink()
    print(f"P3_AUDIO_OK: {name} ({out_ogg.stat().st_size} bytes)")


def main() -> None:
    rng = np.random.default_rng(199603)

    # 1. Soft UI hover micro-tick
    t = np.arange(int(0.045 * SR), dtype=np.float32) / SR
    sig = np.sin(2 * np.pi * 1120.0 * t) * np.exp(-t * 145.0) * 0.45
    save_ogg(sig, "sfx_ui_hover.ogg", 0.35)

    # 2. Tactile Bakelite button press
    t = np.arange(int(0.095 * SR), dtype=np.float32) / SR
    n1 = signal.sosfilt(signal.butter(2, [400, 2600], btype="bandpass", fs=SR, output="sos"), rng.normal(0, 0.7, t.size).astype(np.float32))
    sig = (np.sin(2 * np.pi * 320.0 * t) * np.exp(-t * 90.0) + n1 * np.exp(-t * 75.0) * 0.5)
    save_ogg(sig, "sfx_ui_press.ogg", 0.58)

    # 3. Paper page turn rustle
    t = np.arange(int(0.38 * SR), dtype=np.float32) / SR
    noise = rng.normal(0, 1.0, t.size).astype(np.float32)
    rustle = signal.sosfilt(signal.butter(2, [950, 5600], btype="bandpass", fs=SR, output="sos"), noise)
    env = np.sin(np.pi * t / 0.38) ** 1.3 * (0.7 + 0.3 * np.sin(2 * np.pi * 9.0 * t))
    save_ogg(np.stack([rustle * env, np.roll(rustle * env, 18)], axis=1), "sfx_page_turn.ogg", 0.62)

    # 4. Walkman cassette mechanical click + latch
    t = np.arange(int(0.32 * SR), dtype=np.float32) / SR
    c1 = np.exp(-np.maximum(0, t - 0.02) * 110.0) * (t >= 0.02) * np.sin(2 * np.pi * 480.0 * t)
    c2 = np.exp(-np.maximum(0, t - 0.14) * 95.0) * (t >= 0.14) * np.sin(2 * np.pi * 260.0 * t)
    whirr = np.sin(2 * np.pi * 118.0 * t) * 0.12 * (t > 0.15) * np.exp(-(t - 0.15) * 6.0)
    save_ogg(c1 * 0.8 + c2 * 0.9 + whirr, "sfx_cassette_click.ogg", 0.68)

    # 5. 1980s Apartment Intercom Buzzer (Apartment 47!)
    t = np.arange(int(1.25 * SR), dtype=np.float32) / SR
    buzz = (np.sin(2 * np.pi * 150.0 * t) + 0.6 * np.sin(2 * np.pi * 300.0 * t) + 0.35 * np.sin(2 * np.pi * 450.0 * t))
    gate = ((t > 0.05) & (t < 0.52)) | ((t > 0.68) & (t < 1.15))
    sig = signal.sosfilt(signal.butter(2, [120, 1800], btype="bandpass", fs=SR, output="sos"), buzz * gate.astype(np.float32))
    save_ogg(sig, "sfx_intercom_buzz.ogg", 0.72)

    # 6. 03:17 Estate Power Failure (transformer breaker clunk + descending 50Hz hum)
    t = np.arange(int(2.1 * SR), dtype=np.float32) / SR
    clunk = np.sin(2 * np.pi * 88.0 * t) * np.exp(-t * 28.0) * 1.1
    freq_sweep = 55.0 * np.exp(-t * 1.15) + 14.0
    phase = 2 * np.pi * np.cumsum(freq_sweep) / SR
    hum_down = np.sin(phase) * np.exp(-t * 1.35) * 0.65
    save_ogg(clunk + hum_down, "sfx_power_out.ogg", 0.82)
    print("PROMPT03_AUDIO_COMPLETE")


if __name__ == "__main__":
    main()
