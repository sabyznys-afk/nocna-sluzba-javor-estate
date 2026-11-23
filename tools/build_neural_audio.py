import math
import os
import subprocess
import sys
import tempfile
import uuid

# Guard caches onto D: before importing HF/PyTorch/kokoro
os.environ.setdefault("HF_HOME", r"D:\GameStudioTools\hf_cache")
os.environ.setdefault("TORCH_HOME", r"D:\GameStudioTools\torch_cache")
os.environ.setdefault("XDG_CACHE_HOME", r"D:\GameStudioTools\xdg_cache")
os.environ.setdefault("TMP", r"D:\GameStudioTools\tmp")
os.environ.setdefault("TEMP", r"D:\GameStudioTools\tmp")
os.environ.setdefault("HF_HUB_ETAG_TIMEOUT", "15")
os.environ.setdefault("HF_HUB_DOWNLOAD_TIMEOUT", "60")

import numpy as np
import soundfile as sf
from scipy import signal

OUT_DIR = r"D:\nocna-zmena-blok-14\assets\audio"
TMP_DIR = r"D:\GameStudioTools\tmp"
KOKORO_MODEL = r"D:\GameStudioTools\kokoro\kokoro-v1.0.onnx"
KOKORO_VOICES = r"D:\GameStudioTools\kokoro\voices-v1.0.bin"
FFMPEG_EXE = r"D:\GameStudioTools\ffmpeg\ffmpeg.exe"
if not os.path.exists(FFMPEG_EXE):
    FFMPEG_EXE = "ffmpeg"

os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(TMP_DIR, exist_ok=True)

SR = 44100


def ensure_stereo(audio: np.ndarray) -> np.ndarray:
    arr = np.asarray(audio, dtype=np.float32)
    if arr.ndim == 1:
        arr = np.stack([arr, arr], axis=1)
    elif arr.shape[1] == 1:
        arr = np.repeat(arr, 2, axis=1)
    return arr


def normalize_stereo(audio: np.ndarray, peak: float = 0.88) -> np.ndarray:
    arr = ensure_stereo(audio)
    mx = float(np.max(np.abs(arr)))
    if mx > 1e-6:
        arr = arr * (peak / mx)
    return np.clip(arr, -0.98, 0.98).astype(np.float32)


def encode_ogg(stereo_samples: np.ndarray, out_name: str, sr: int = SR, loop_fade: float = 0.0) -> str:
    arr = normalize_stereo(stereo_samples)
    if loop_fade > 0.0:
        n_fade = min(int(loop_fade * sr), arr.shape[0] // 4)
        if n_fade > 32:
            head = arr[:n_fade].copy()
            tail = arr[-n_fade:].copy()
            w = np.linspace(0.0, 1.0, n_fade, dtype=np.float32)[:, None]
            arr[:n_fade] = head * w + tail * (1.0 - w)
            arr = arr[:-n_fade]

    tmp_wav = os.path.join(TMP_DIR, f"{uuid.uuid4().hex}.wav")
    out_path = os.path.join(OUT_DIR, out_name)
    sf.write(tmp_wav, arr, sr, subtype="PCM_16")
    cmd = [
        FFMPEG_EXE, "-y", "-hide_banner", "-loglevel", "error",
        "-i", tmp_wav, "-c:a", "libvorbis", "-q:a", "5", out_path
    ]
    subprocess.run(cmd, check=True)
    if os.path.exists(tmp_wav):
        os.remove(tmp_wav)
    sz = os.path.getsize(out_path)
    print(f"AUDIO_OK: {out_name} ({sz} bytes)")
    return out_path


def apply_voice_filter(samples: np.ndarray, sr: int, ftype: str) -> np.ndarray:
    y = samples.astype(np.float32)
    rng = np.random.default_rng(1995)
    if ftype == "phone":
        sos = signal.butter(4, [340, 3100], btype="bandpass", fs=sr, output="sos")
        y = signal.sosfilt(sos, y)
        y = np.tanh(y * 2.1) * 0.72
        hiss = rng.normal(0.0, 0.006, size=len(y)).astype(np.float32)
        t = np.arange(len(y), dtype=np.float32) / sr
        hum = 0.004 * np.sin(2.0 * np.pi * 50.0 * t).astype(np.float32)
        y = y + hiss + hum
        stereo = np.stack([y, y * 0.96], axis=1)
    elif ftype == "radio":
        sos = signal.butter(4, [420, 2600], btype="bandpass", fs=sr, output="sos")
        y = signal.sosfilt(sos, y)
        y = np.tanh(y * 2.5) * 0.68
        t = np.arange(len(y), dtype=np.float32) / sr
        mod = 0.5 + 0.5 * np.sin(2.0 * np.pi * 3.1 * t)
        static = rng.normal(0.0, 0.018, size=len(y)).astype(np.float32) * (0.6 + 0.7 * mod)
        carrier = 0.008 * np.sin(2.0 * np.pi * 1004.0 * t).astype(np.float32)
        y = y + static + carrier
        stereo = np.stack([y, y], axis=1)
    elif ftype == "door":
        sos = signal.butter(3, [140, 2200], btype="lowpass", fs=sr, output="sos") if False else signal.butter(3, 1800, btype="lowpass", fs=sr, output="sos")
        y = signal.sosfilt(sos, y)
        # Subtle hallway delay reflection
        d1 = int(0.022 * sr)
        d2 = int(0.055 * sr)
        out = y.copy()
        if len(y) > d2:
            out[d1:] += y[:-d1] * 0.24
            out[d2:] += y[:-d2] * 0.12
        stereo = np.stack([out, np.roll(out, 18) * 0.95], axis=1)
    elif ftype == "bunker":
        sos = signal.butter(3, [110, 3800], btype="bandpass", fs=sr, output="sos")
        y = signal.sosfilt(sos, y)
        # Concrete cave reverb taps
        l_out = y.copy()
        r_out = y.copy()
        for ms, gain in [(31, 0.30), (67, 0.20), (113, 0.12), (179, 0.07)]:
            ds = int(ms * 0.001 * sr)
            if len(y) > ds:
                l_out[ds:] += y[:-ds] * gain
                r_out[ds + 12 if ds + 12 < len(y) else ds:] += y[: len(y) - (ds + 12 if ds + 12 < len(y) else ds)] * (gain * 0.92)
        t = np.arange(len(y), dtype=np.float32) / sr
        hum = 0.005 * np.sin(2.0 * np.pi * 62.0 * t).astype(np.float32)
        stereo = np.stack([l_out + hum, r_out - hum * 0.5], axis=1)
    elif ftype == "outdoor":
        sos = signal.butter(2, 4600, btype="lowpass", fs=sr, output="sos")
        y = signal.sosfilt(sos, y)
        l_out = y.copy()
        r_out = y.copy()
        ds1, ds2 = int(0.048 * sr), int(0.115 * sr)
        if len(y) > ds2:
            l_out[ds1:] += y[:-ds1] * 0.18
            r_out[ds2:] += y[:-ds2] * 0.14
        stereo = np.stack([l_out, r_out], axis=1)
    else:
        stereo = np.stack([y, y], axis=1)
    return normalize_stereo(stereo, peak=0.86)


def generate_kokoro_voices():
    from kokoro_onnx import Kokoro
    kokoro = Kokoro(KOKORO_MODEL, KOKORO_VOICES)

    lines = [
        ("voice_kovac_n1.ogg", "bm_george", 0.94, "phone",
         "Block fourteen dispatch, Kovac speaking. Welcome to your orientation night shift, rookie. Pick up a spare battery pack on the booth counter and press R to test your lantern reload. Equip your stun taser with two to clear weird static, tour all four ground zones, stamp three watchclocks, and mark any strange sightings in your field notebook. Stay alert."),
        ("voice_kovac_n2.ogg", "bm_george", 0.93, "phone",
         "Kovac on the line. Rain is thickening across the courtyard tonight. Tenants reported someone standing by the eastern Lada van, and Milan was seen loitering near the chapel shrine. Keep your stun baton charged and log every anomaly you witness."),
        ("voice_kovac_n3.ogg", "bm_george", 0.92, "phone",
         "Guardroom, Kovac here. Half the arcade breakers blew ten minutes ago. Flip the fusebox back on, check flat seven for Maria, and stay clear of the covered butcher hooks if they start swinging on their own."),
        ("voice_kovac_n4.ogg", "bm_george", 0.91, "phone",
         "Listen carefully. The red basement door under the chapel unlocked itself. Check the cellar ledger pages, flush the boiler pressure valve, and do not leave the fourth watchclock unstamped."),
        ("voice_kovac_n5.ogg", "bm_george", 0.90, "phone",
         "You made it to night five. Someone cut the street relays outside gate one. Hold the block together, descend to Bunker K four beneath the boiler hall, and pull the truth before dawn."),
        ("voice_elena_payphone.ogg", "af_bella", 0.93, "phone",
         "Please, if anyone picks up at Block fourteen, do not trust the ledger in flat nine. The men wearing gray coats took my brother down under the boiler stairs in nineteen ninety two."),
        ("voice_maria_n3.ogg", "bf_emma", 0.92, "door",
         "Is that the new night watchman? Do not open my chain latch. Something climbed out of the courtyard well around midnight and scratched at my shutters. Just leave my lantern oil outside."),
        ("voice_maria_n5.ogg", "bf_emma", 0.90, "door",
         "The thirteenth window on the east wall is glowing again. Take my key down to the cellar valve, stop the hum beneath our floorboards, and tell Elena her brother is still alive down there."),
        ("voice_jozef_bunker.ogg", "am_michael", 0.89, "bunker",
         "Stop! Do not touch the violet relay on unit K four. Seven guards signed this logbook before you, thinking they only watched empty stone. Either shut the core down forever, or take my stool and keep the silence."),
        ("voice_milan_n2.ogg", "am_adam", 0.91, "outdoor",
         "Hey, flashlight guy. You see those butcher chains moving with no wind? Pay me no mind, just keep that taser ready if the shadows near the shrine start walking."),
        ("loop_radio_504.ogg", "am_onyx", 0.86, "radio",
         "Station five zero four. Fourteen. Seven. Zero nine. Bunker K four alignment drifting. Repeat. Fourteen. Seven. Zero nine."),
    ]

    for fname, voice_id, spd, flt, text in lines:
        samples, sr = kokoro.create(text, voice=voice_id, speed=spd, lang="en-us")
        # Pad 0.15s clean tail and encode
        pad = np.zeros(int(0.15 * sr), dtype=np.float32)
        samples = np.concatenate([pad * 0.2, samples.astype(np.float32), pad])
        stereo = apply_voice_filter(samples, sr, flt)
        encode_ogg(stereo, fname, sr=sr, loop_fade=(0.35 if fname.startswith("loop_") else 0.0))


def synthesize_footsteps():
    # Crisp 0.42s multi-layer physical-modeling footsteps: heel transient + toe scuff + surface resonance
    rng_base = 700
    for surface in ("cobble", "wood", "metal"):
        for idx in range(1, 5):
            rng = np.random.default_rng(rng_base + hash((surface, idx)) % 10000)
            dur = 0.40 + rng.uniform(-0.02, 0.03)
            n = int(dur * SR)
            t = np.arange(n, dtype=np.float32) / SR
            out = np.zeros(n, dtype=np.float32)

            # Heel hit at 0.012s + sole slap at 0.058s
            t_heel = 0.012
            t_toe = 0.055 + rng.uniform(-0.008, 0.010)
            pitch_jit = rng.uniform(0.90, 1.12)

            if surface == "cobble":
                # Heavy rubber/leather boot on damp granite cobblestones
                e_heel = np.exp(-np.maximum(0.0, t - t_heel) * 78.0) * (t >= t_heel)
                e_toe = np.exp(-np.maximum(0.0, t - t_toe) * 58.0) * (t >= t_toe)
                body = (
                    0.55 * np.sin(2 * np.pi * (86.0 * pitch_jit) * np.maximum(0, t - t_heel)) * e_heel +
                    0.42 * np.sin(2 * np.pi * (118.0 * pitch_jit) * np.maximum(0, t - t_toe)) * e_toe
                )
                grit = rng.normal(0.0, 1.0, n).astype(np.float32)
                sos_grit = signal.butter(3, [900 * pitch_jit, 4200 * pitch_jit], btype="bandpass", fs=SR, output="sos")
                grit_bp = signal.sosfilt(sos_grit, grit)
                e_grit = np.exp(-np.maximum(0.0, t - t_heel) * 32.0) * (t >= t_heel)
                # Subtle wet grit splash on half the cobble steps
                wet_gain = 0.48 if idx % 2 == 0 else 0.34
                out = body + grit_bp * e_grit * wet_gain
                # Faint courtyard stone early reflection
                d = int(0.024 * SR)
                out[d:] += out[:-d] * 0.16

            elif surface == "wood":
                # Hollow aged tenement floorboards + dry creak harmonic
                e_heel = np.exp(-np.maximum(0.0, t - t_heel) * 46.0) * (t >= t_heel)
                e_toe = np.exp(-np.maximum(0.0, t - t_toe) * 38.0) * (t >= t_toe)
                f1 = 72.0 * pitch_jit
                f2 = 165.0 * pitch_jit
                thud = (
                    0.65 * np.sin(2 * np.pi * f1 * np.maximum(0, t - t_heel)) * e_heel +
                    0.40 * np.sin(2 * np.pi * f2 * np.maximum(0, t - t_toe)) * e_toe
                )
                # Subtle board creak on variations 2 & 4
                creak = np.zeros(n, dtype=np.float32)
                if idx in (2, 4):
                    cfreq = rng.uniform(380.0, 560.0) + 95.0 * np.sin(2 * np.pi * 16.0 * t)
                    c_env = np.exp(-np.maximum(0.0, t - 0.04) * 14.0) * (t >= 0.04) * (1.0 - np.exp(-np.maximum(0.0, t - 0.04) * 60.0))
                    creak = 0.18 * np.sin(2 * np.pi * np.cumsum(cfreq) / SR) * c_env
                grit = signal.sosfilt(signal.butter(2, [450, 2200], btype="bandpass", fs=SR, output="sos"),
                                      rng.normal(0.0, 0.25, n).astype(np.float32)) * e_heel
                out = thud + grit + creak

            else:  # metal grating / fire escape catwalk
                e_heel = np.exp(-np.maximum(0.0, t - t_heel) * 34.0) * (t >= t_heel)
                e_toe = np.exp(-np.maximum(0.0, t - t_toe) * 28.0) * (t >= t_toe)
                modes = [245.0, 512.0, 890.0, 1460.0]
                ring = np.zeros(n, dtype=np.float32)
                for mi, mf in enumerate(modes):
                    decay = np.exp(-np.maximum(0.0, t - t_heel) * (14.0 + mi * 7.0)) * (t >= t_heel)
                    ring += (0.28 / (mi + 1)) * np.sin(2 * np.pi * mf * pitch_jit * t) * decay
                clank = signal.sosfilt(signal.butter(3, [1200, 5800], btype="bandpass", fs=SR, output="sos"),
                                       rng.normal(0.0, 0.55, n).astype(np.float32)) * (e_heel + 0.6 * e_toe)
                low_punch = 0.48 * np.sin(2 * np.pi * 105.0 * np.maximum(0, t - t_heel)) * e_heel
                out = low_punch + ring + clank

            # Micro fade in/out for zero clicks
            fi = min(int(0.004 * SR), n // 8)
            fo = min(int(0.030 * SR), n // 4)
            out[:fi] *= np.linspace(0.0, 1.0, fi, dtype=np.float32)
            out[-fo:] *= np.linspace(1.0, 0.0, fo, dtype=np.float32)
            stereo = np.stack([out, np.roll(out, 7) * 0.96], axis=1)
            encode_ogg(stereo, f"sfx_step_{surface}_{idx}.ogg")


def synthesize_dsp_fallback(spec_name: str, dur: float, seed: int) -> tuple[np.ndarray, float]:
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    l = np.zeros(n, dtype=np.float32)
    r = np.zeros(n, dtype=np.float32)
    loop_f = 0.0

    if spec_name == "sfx_taser_zap.ogg":
        # Crackle + 100 Hz stun pulse bursts + high frequency arc spray
        gate = ((np.sin(2 * np.pi * 24.0 * t) > -0.25).astype(np.float32)) * np.exp(-t * 2.1)
        buzz = 0.42 * signal.sawtooth(2 * np.pi * 115.0 * t) * gate
        zaps = signal.sosfilt(signal.butter(3, [1800, 9500], btype="bandpass", fs=SR, output="sos"),
                              rng.normal(0.0, 1.0, n).astype(np.float32)) * gate
        l = buzz + zaps * 0.85
        r = buzz * 0.92 + np.roll(zaps, 23) * 0.85

    elif spec_name == "sfx_taser_equip.ogg":
        # Switch click + ascending capacitor charge whine
        click = np.exp(-np.maximum(0.0, t - 0.02) * 140.0) * (t >= 0.02) * rng.normal(0.0, 0.9, n).astype(np.float32)
        freq = 900.0 + 2600.0 * (t / dur)
        whine = 0.25 * np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.sin(np.pi * t / dur)
        l = click + whine
        r = np.roll(click, 8) + whine * 0.95

    elif spec_name == "sfx_battery_swap.ogg":
        # Slide latch (0.08s), drop thud (0.35s), spring snap (0.68s)
        c1 = np.exp(-np.maximum(0, t - 0.08) * 45.0) * (t >= 0.08) * signal.sosfilt(
            signal.butter(2, [1000, 4200], btype="bandpass", fs=SR, output="sos"), rng.normal(0, 0.7, n).astype(np.float32))
        c2 = np.exp(-np.maximum(0, t - 0.36) * 55.0) * (t >= 0.36) * np.sin(2 * np.pi * 140.0 * t) * 0.55
        c3 = np.exp(-np.maximum(0, t - 0.68) * 120.0) * (t >= 0.68) * signal.sosfilt(
            signal.butter(2, [1600, 6200], btype="bandpass", fs=SR, output="sos"), rng.normal(0, 0.9, n).astype(np.float32))
        l = c1 + c2 + c3
        r = l * 0.95 + np.roll(c3, 11) * 0.2

    elif spec_name == "sfx_notebook_open.ogg":
        # Leather flip + soft paper rustle
        rustle = signal.sosfilt(signal.butter(2, [1400, 7500], btype="bandpass", fs=SR, output="sos"),
                                rng.normal(0, 1.0, n).astype(np.float32))
        env = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 1.4
        thump = 0.32 * np.sin(2 * np.pi * 110.0 * t) * np.exp(-t * 18.0)
        l = rustle * env * 0.45 + thump
        r = np.roll(rustle, 19) * env * 0.45 + thump

    elif spec_name == "sfx_pencil_check.ogg":
        # Two crisp down-up graphite checkmark strokes
        s1 = np.exp(-((t - 0.11) / 0.032) ** 2)
        s2 = np.exp(-((t - 0.24) / 0.045) ** 2)
        scratch = signal.sosfilt(signal.butter(3, [2200, 7800], btype="bandpass", fs=SR, output="sos"),
                                 rng.normal(0, 1.0, n).astype(np.float32))
        l = scratch * (0.7 * s1 + 1.0 * s2)
        r = np.roll(l, 9)

    elif spec_name == "sfx_door_creak.ogg":
        # Stick-slip squeak harmonics swept smoothly downward
        f_creak = 285.0 - 95.0 * np.sin(np.pi * t / dur) + 38.0 * np.sin(2 * np.pi * 7.5 * t)
        phase = 2 * np.pi * np.cumsum(f_creak) / SR
        sq = (0.45 * np.sin(phase) + 0.28 * np.sin(2.01 * phase) + 0.18 * np.sin(3.04 * phase))
        sq *= np.sin(np.pi * t / dur) ** 0.7
        latch = 0.45 * np.exp(-np.maximum(0, t - (dur - 0.18)) * 75.0) * (t >= (dur - 0.18)) * rng.normal(0, 1, n)
        l = sq + latch
        r = np.roll(sq, 21) * 0.9 + latch

    elif spec_name == "sfx_chains_sway.ogg":
        # Metallic chain clinks swaying gently
        loop_f = 0.25
        for ct in (0.18, 0.52, 0.94, 1.38, 1.82):
            decay = np.exp(-np.maximum(0.0, t - ct) * 18.0) * (t >= ct)
            amp = rng.uniform(0.18, 0.34)
            clink = np.zeros(n, dtype=np.float32)
            for mf in (1850.0, 2940.0, 4420.0, 6100.0):
                clink += np.sin(2 * np.pi * (mf * rng.uniform(0.95, 1.05)) * np.maximum(0, t - ct)) * decay
            pan = rng.uniform(0.3, 0.7)
            l += clink * amp * pan
            r += clink * amp * (1.0 - pan)

    elif spec_name == "sfx_chair_crash.ogg":
        # Sharp hardwood slam + bounce + wood rattle
        imp1 = np.exp(-np.maximum(0, t - 0.05) * 32.0) * (t >= 0.05)
        imp2 = np.exp(-np.maximum(0, t - 0.24) * 26.0) * (t >= 0.24)
        wood = (0.7 * np.sin(2 * np.pi * 138.0 * t) + 0.35 * np.sin(2 * np.pi * 290.0 * t)) * (imp1 + 0.55 * imp2)
        clatter = signal.sosfilt(signal.butter(2, [400, 3400], btype="bandpass", fs=SR, output="sos"),
                                 rng.normal(0, 0.9, n).astype(np.float32)) * (imp1 + 0.7 * imp2)
        l = wood + clatter
        r = np.roll(wood + clatter, 17)

    elif spec_name == "sfx_distant_tram.ogg":
        # Loopable nocturnal city tram steel wheel rumble + rail flange squeal
        loop_f = 0.8
        noise = rng.normal(0, 1, n).astype(np.float32)
        rumble = signal.sosfilt(signal.butter(3, [42, 190], btype="bandpass", fs=SR, output="sos"), noise) * 0.9
        swell = 0.35 + 0.65 * (0.5 - 0.5 * np.cos(2 * np.pi * t / dur))
        # Periodic clack-clack rail joint
        clack = np.zeros(n, dtype=np.float32)
        for jt in (1.1, 1.38, 3.8, 4.08):
            env = np.exp(-np.maximum(0, t - jt) * 28.0) * (t >= jt)
            clack += 0.32 * np.sin(2 * np.pi * 145.0 * t) * env
        squeal = 0.06 * np.sin(2 * np.pi * 2180.0 * t) * np.exp(-((t - 2.6) / 0.75) ** 2)
        l = (rumble + clack + squeal) * swell
        r = (np.roll(rumble, 45) + clack * 0.9 + squeal * 1.1) * swell

    elif spec_name == "sfx_whisper_static.ogg":
        # Formant-filtered ghostly radio whisper over tape hiss
        noise = rng.normal(0, 1, n).astype(np.float32)
        env = (0.4 + 0.6 * np.abs(np.sin(2 * np.pi * 3.4 * t))) * np.sin(np.pi * np.clip(t / dur, 0, 1))
        f1 = signal.sosfilt(signal.butter(3, [650, 1250], btype="bandpass", fs=SR, output="sos"), noise)
        f2 = signal.sosfilt(signal.butter(3, [2100, 3200], btype="bandpass", fs=SR, output="sos"), noise)
        l = (f1 * 0.7 + f2 * 0.5) * env
        r = (np.roll(f1, 29) * 0.65 + np.roll(f2, -19) * 0.55) * env

    else:  # amb_rain_city.ogg
        loop_f = 1.2
        white_l = rng.normal(0, 1, n).astype(np.float32)
        white_r = rng.normal(0, 1, n).astype(np.float32)
        rain_l = signal.sosfilt(signal.butter(2, [450, 6800], btype="bandpass", fs=SR, output="sos"), white_l) * 0.35
        rain_r = signal.sosfilt(signal.butter(2, [450, 6800], btype="bandpass", fs=SR, output="sos"), white_r) * 0.35
        city_bed = signal.sosfilt(signal.butter(2, [48, 165], btype="bandpass", fs=SR, output="sos"),
                                  rng.normal(0, 1, n).astype(np.float32)) * 0.45
        l = rain_l + city_bed
        r = rain_r + np.roll(city_bed, 52)

    return np.stack([l, r], axis=1), loop_f


def build_sfx_specs():
    return [
        ("sfx_taser_zap.ogg", "sharp high voltage stun gun electric taser spark arc zap, clean sound effect", 1.3, 1401, 0.0),
        ("sfx_taser_equip.ogg", "plastic switch click and brief electronic capacitor whine, close mic foley", 0.65, 1402, 0.0),
        ("sfx_battery_swap.ogg", "sliding open flashlight battery hatch inserting dry cell closing snap click foley", 1.2, 1403, 0.0),
        ("sfx_notebook_open.ogg", "opening a small leather pocket notebook and turning crisp paper page foley", 0.7, 1404, 0.0),
        ("sfx_pencil_check.ogg", "short quick graphite pencil checkmark scratch stroke on rough paper", 0.5, 1405, 0.0),
        ("sfx_door_creak.ogg", "slow heavy rusted iron hinge and old wooden tenement door creaking open at night", 1.8, 1406, 0.0),
        ("sfx_chains_sway.ogg", "heavy hanging steel butcher chains swaying and clinking softly in an empty hall", 2.2, 1407, 0.25),
        ("sfx_chair_crash.ogg", "wooden chair dropping and slamming loudly onto stone cobblestone floor", 1.4, 1408, 0.0),
        ("sfx_distant_tram.ogg", "distant 1990s eastern european night tram rumbling over wet cobblestone streets", 6.0, 1409, 0.8),
        ("sfx_whisper_static.ogg", "eerie analog radio static burst with faint unrecognizable whispered voice transmission", 2.5, 1410, 0.0),
        ("amb_rain_city.ogg", "steady autumn night rain pattering on wet cobblestones and tin roofs in empty old city", 8.0, 1411, 1.2),
    ]


def try_upgrade_with_tangoflux(specs: list[tuple[str, str, float, int, float]]) -> bool:
    # Step A: ensure flan-t5-large finishes downloading within a bounded 60s child subprocess
    print("Checking/resuming huggingface snapshot cache for TangoFlux + flan-t5-large (max 65s)...")
    dl_code = (
        "import huggingface_hub.file_download as _fd\n"
        "_fd.are_symlinks_supported = lambda cache_dir=None: False\n"
        "from huggingface_hub import snapshot_download\n"
        "snapshot_download('declare-lab/TangoFlux', local_files_only=False)\n"
        "snapshot_download('google/flan-t5-large', allow_patterns=['*.json','*.txt','*.model','*.safetensors','model.safetensors'], local_files_only=False)\n"
        "print('HF_SNAPSHOTS_READY')\n"
    )
    try:
        res = subprocess.run([sys.executable, "-c", dl_code], timeout=65, check=True)
    except Exception as exc:
        print(f"TangoFlux cache resume skipped/timed out ({exc}); keeping layered physical-modeled DSP SFX.")
        return False

    try:
        import torch
        import huggingface_hub.file_download as _hf_fd
        _hf_fd.are_symlinks_supported = lambda cache_dir=None: False
        from tangoflux import TangoFluxInference

        if not torch.cuda.is_available():
            print("CUDA unavailable; keeping DSP SFX.")
            return False

        print("Loading TangoFluxInference ONCE onto RTX 4060 bfloat16...")
        model = TangoFluxInference(name="declare-lab/TangoFlux", device="cpu")
        model.model.to(dtype=torch.bfloat16).to("cuda")
        if hasattr(model, "vae") and model.vae is not None:
            model.vae.to(dtype=torch.bfloat16).to("cuda")

        for fname, prompt, dur, seed, loop_f in specs:
            try:
                torch.manual_seed(seed)
                with torch.inference_mode(), torch.autocast("cuda", dtype=torch.bfloat16):
                    audio = model.generate(prompt, steps=18, duration=dur)
                if isinstance(audio, torch.Tensor):
                    wav = audio.detach().float().cpu().numpy()
                else:
                    wav = np.asarray(audio, dtype=np.float32)
                if wav.ndim == 2 and wav.shape[0] <= 2 and wav.shape[1] > wav.shape[0]:
                    wav = wav.T
                stereo = ensure_stereo(wav)
                # Trim exact target duration at 44100 Hz (TangoFlux outputs 44.1 kHz)
                target_n = min(stereo.shape[0], int(dur * SR))
                stereo = stereo[:target_n]
                encode_ogg(stereo, fname, sr=SR, loop_fade=loop_f)
            except Exception as clip_exc:
                print(f"TangoFlux clip fallback for {fname}: {clip_exc}")
        return True
    except Exception as exc:
        print(f"TangoFlux CUDA inference fallback ({exc}); keeping layered DSP SFX.")
        return False


def main():
    print("=== PHASE 1: Kokoro-82M Neural Voices ===")
    generate_kokoro_voices()

    print("=== PHASE 2: Recreated Footsteps (12 variations) ===")
    synthesize_footsteps()

    print("=== PHASE 3: Stereo Physical-Modeled SFX Baseline (11 tracks) ===")
    specs = build_sfx_specs()
    for fname, _prompt, dur, seed, _lf in specs:
        stereo, loop_f = synthesize_dsp_fallback(fname, dur, seed)
        encode_ogg(stereo, fname, sr=SR, loop_fade=loop_f)

    if "--dsp-only" not in sys.argv:
        print("=== PHASE 4: TangoFlux RTX 4060 CUDA Upgrade Pass ===")
        try_upgrade_with_tangoflux(specs)

    print("NEURAL_AUDIO_PIPELINE_COMPLETE")


if __name__ == "__main__":
    main()
