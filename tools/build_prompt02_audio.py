r"""
Generates Prompt 02 audio assets into D:\nocna-zmena-blok-14\assets\audio\:
- music_walkman_tape.ogg (1990s warm analog Walkman cassette track rendered with FluidSynth + tape saturation/wow/hiss)
- sfx_step_grass_1..4.ogg, sfx_step_gravel_1..4.ogg
- sfx_headphones_on, sfx_headphones_off, sfx_keys_jingle, sfx_radio_squelch, sfx_watch_tick
- sfx_switch_click, sfx_drawer_open, sfx_breath_tired, sfx_breath_exhausted, sfx_jumpscare_sting
- loop_apartment_life.ogg, loop_forest_wind.ogg
"""
import os
import pathlib
import struct
import subprocess
import uuid
import numpy as np
import soundfile as sf
from scipy import signal

os.environ.setdefault("TMP", r"D:\GameStudioTools\tmp")
os.environ.setdefault("TEMP", r"D:\GameStudioTools\tmp")

OUT_DIR = pathlib.Path(r"D:\nocna-zmena-blok-14\assets\audio")
TMP_DIR = pathlib.Path(r"D:\GameStudioTools\tmp")
FLUIDSYNTH = r"C:\Users\arnos\scoop\apps\fluidsynth\current\bin\fluidsynth.exe"
SOUNDFONT = r"D:\GameStudioTools\soundfonts\GeneralUser-GS.sf2"
FFMPEG = "ffmpeg"
SR = 44100


def ensure_stereo(arr: np.ndarray) -> np.ndarray:
    a = np.asarray(arr, dtype=np.float32)
    if a.ndim == 1:
        a = np.stack([a, a], axis=1)
    elif a.shape[1] == 1:
        a = np.repeat(a, 2, axis=1)
    return a


def normalize_stereo(arr: np.ndarray, peak: float = 0.86) -> np.ndarray:
    a = ensure_stereo(arr)
    mx = float(np.max(np.abs(a)))
    if mx > 1e-6:
        a = a * (peak / mx)
    return np.clip(a, -0.98, 0.98).astype(np.float32)


def encode_ogg(stereo: np.ndarray, name: str, sr: int = SR, loop_fade: float = 0.0) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    arr = normalize_stereo(stereo)
    if loop_fade > 0.0:
        nf = min(int(loop_fade * sr), arr.shape[0] // 4)
        if nf > 32:
            head = arr[:nf].copy()
            tail = arr[-nf:].copy()
            w = np.linspace(0.0, 1.0, nf, dtype=np.float32)[:, None]
            arr[:nf] = head * w + tail * (1.0 - w)
            arr = arr[:-nf]

    tmp_wav = TMP_DIR / f"{uuid.uuid4().hex}.wav"
    out_ogg = OUT_DIR / name
    sf.write(str(tmp_wav), arr, sr, subtype="PCM_16")
    subprocess.run(
        [FFMPEG, "-y", "-hide_banner", "-loglevel", "error", "-i", str(tmp_wav), "-c:a", "libvorbis", "-q:a", "5", str(out_ogg)],
        check=True,
    )
    if tmp_wav.exists():
        tmp_wav.unlink()
    print(f"P2_AUDIO_OK: {name} ({out_ogg.stat().st_size} bytes)")


def _vlq(val: int) -> bytes:
    buf = [val & 0x7F]
    val >>= 7
    while val:
        buf.append((val & 0x7F) | 0x80)
        val >>= 7
    return bytes(reversed(buf))


def write_walkman_midi(mid_path: pathlib.Path) -> None:
    tpq = 480
    # Warm 1990s Central European nostalgic synth-ballad loop (A minor -> F -> C -> G, 92 BPM)
    events = []
    # Program changes: ch0 = 81 (Synth Lead / Rhodes), ch1 = 89 (Warm Pad), ch2 = 33 (Fingered Bass)
    events.append((0, bytes([0xC0, 4])))   # Electric Piano 1 (Rhodes!)
    events.append((0, bytes([0xC1, 89])))  # Warm Pad
    events.append((0, bytes([0xC2, 33])))  # Finger Bass
    events.append((0, bytes([0xC9, 0])))   # Standard drums

    progression = [
        (57, [69, 72, 76], [76, 79, 76, 72]), # Am
        (53, [65, 69, 72], [72, 74, 72, 69]), # F
        (48, [64, 67, 72], [72, 74, 76, 74]), # C
        (55, [62, 67, 71], [71, 69, 67, 64]), # G
    ]
    bar_ticks = tpq * 4
    for b_idx, (bass, chord, mel) in enumerate(progression * 2):
        t0 = b_idx * bar_ticks
        # Pad whole bar
        for n in chord:
            events.append((t0, bytes([0x91, n, 54])))
            events.append((t0 + bar_ticks - 20, bytes([0x81, n, 0])))
        # Walking 8th bass
        for step in range(4):
            bt = t0 + step * tpq
            events.append((bt, bytes([0x92, bass + (12 if step % 2 == 1 else 0), 74])))
            events.append((bt + int(tpq * 0.8), bytes([0x82, bass + (12 if step % 2 == 1 else 0), 0])))
        # Gentle electric piano melody
        for step, mn in enumerate(mel):
            mt = t0 + step * tpq + 120
            events.append((mt, bytes([0x90, mn, 78])))
            events.append((mt + int(tpq * 0.85), bytes([0x80, mn, 0])))
        # Muffled cassette drum beat (ch9)
        for q in range(4):
            dt = t0 + q * tpq
            if q in (0, 2):
                events.append((dt, bytes([0x99, 36, 72])))
                events.append((dt + 120, bytes([0x89, 36, 0])))
            else:
                events.append((dt, bytes([0x99, 38, 60])))
                events.append((dt + 120, bytes([0x89, 38, 0])))
            events.append((dt + tpq // 2, bytes([0x99, 42, 42])))
            events.append((dt + tpq // 2 + 80, bytes([0x89, 42, 0])))

    events.sort(key=lambda x: x[0])
    track_bytes = bytearray()
    # Set tempo 92 BPM (~652174 us/quarter)
    track_bytes += _vlq(0) + b"\xFF\x51\x03" + struct.pack(">I", 652174)[1:]
    last_t = 0
    for t_ev, msg in events:
        dt = max(0, t_ev - last_t)
        last_t = t_ev
        track_bytes += _vlq(dt) + msg
    track_bytes += _vlq(0) + b"\xFF\x2F\x00"

    hdr = b"MThd" + struct.pack(">IHHH", 6, 0, 1, tpq)
    trk = b"MTrk" + struct.pack(">I", len(track_bytes)) + bytes(track_bytes)
    mid_path.write_bytes(hdr + trk)


def build_walkman_music() -> None:
    if os.path.exists(FLUIDSYNTH) and os.path.exists(SOUNDFONT):
        mid_p = TMP_DIR / f"walkman_{uuid.uuid4().hex}.mid"
        wav_p = TMP_DIR / f"walkman_{uuid.uuid4().hex}.wav"
        write_walkman_midi(mid_p)
        subprocess.run(
            [FLUIDSYNTH, "-ni", "-q", "-F", str(wav_p), "-r", str(SR), SOUNDFONT, str(mid_p)],
            check=True,
        )
        data, _ = sf.read(str(wav_p), dtype="float32")
        if mid_p.exists():
            mid_p.unlink()
        if wav_p.exists():
            wav_p.unlink()
        arr = ensure_stereo(data)
    else:
        dur = 16.0
        n = int(dur * SR)
        t = np.arange(n, dtype=np.float32) / SR
        arr = np.zeros((n, 2), dtype=np.float32)
        for chord_i, freqs in enumerate([(220, 261.6, 329.6), (174.6, 220, 261.6), (130.8, 196, 261.6), (196, 246.9, 293.7)]):
            mask = ((t >= chord_i * 4.0) & (t < (chord_i + 1) * 4.0)).astype(np.float32)
            for f in freqs:
                s = 0.25 * np.sin(2 * np.pi * f * t)
                arr[:, 0] += s * mask
                arr[:, 1] += np.roll(s, 90) * mask

    # Apply nostalgic Walkman cassette filtering: warm midrange, rolled highs, gentle tape hiss
    sos = signal.butter(3, [90, 4600], btype="bandpass", fs=SR, output="sos")
    arr[:, 0] = signal.sosfilt(sos, arr[:, 0])
    arr[:, 1] = signal.sosfilt(sos, arr[:, 1])
    arr = np.tanh(arr * 1.45) * 0.72
    rng = np.random.default_rng(1994)
    hiss = rng.normal(0.0, 0.0045, size=arr.shape).astype(np.float32)
    encode_ogg(arr + hiss, "music_walkman_tape.ogg", loop_fade=0.8)


def build_surface_footsteps() -> None:
    # Grass & Gravel 4 variations each
    for surface in ("grass", "gravel"):
        for idx in range(1, 5):
            rng = np.random.default_rng(3100 + hash((surface, idx)) % 9000)
            dur = 0.42 + rng.uniform(-0.02, 0.03)
            n = int(dur * SR)
            t = np.arange(n, dtype=np.float32) / SR
            pj = rng.uniform(0.92, 1.10)
            noise = rng.normal(0.0, 1.0, n).astype(np.float32)
            if surface == "grass":
                env1 = np.exp(-np.maximum(0.0, t - 0.02) * 18.0) * (t >= 0.02)
                env2 = np.exp(-np.maximum(0.0, t - 0.10) * 14.0) * (t >= 0.10)
                swish = signal.sosfilt(signal.butter(2, [900 * pj, 5200 * pj], btype="bandpass", fs=SR, output="sos"), noise)
                thump = 0.36 * np.sin(2 * np.pi * 64.0 * pj * t) * np.exp(-np.maximum(0, t - 0.015) * 36.0)
                out = swish * (env1 * 0.48 + env2 * 0.36) + thump
            else:
                # Wet gravel crunch: scattered micro-stone clicks
                out = 0.34 * np.sin(2 * np.pi * 92.0 * pj * t) * np.exp(-np.maximum(0, t - 0.015) * 44.0)
                for _c in range(18):
                    ct = rng.uniform(0.012, 0.24)
                    ci = int(ct * SR)
                    if ci < n - 300:
                        burst = signal.sosfilt(signal.butter(2, [1400 * pj, 6400 * pj], btype="bandpass", fs=SR, output="sos"),
                                               rng.normal(0, 0.65, 300).astype(np.float32)) * np.exp(-np.arange(300) / 70.0)
                        out[ci:ci + 300] += burst * rng.uniform(0.4, 0.95)
            fi = min(int(0.004 * SR), n // 8)
            fo = min(int(0.030 * SR), n // 4)
            out[:fi] *= np.linspace(0.0, 1.0, fi, dtype=np.float32)
            out[-fo:] *= np.linspace(1.0, 0.0, fo, dtype=np.float32)
            stereo = np.stack([out, np.roll(out, 11) * 0.96], axis=1)
            encode_ogg(stereo, f"sfx_step_{surface}_{idx}.ogg")


def build_equipment_and_world_sfx() -> None:
    rng = np.random.default_rng(1996)

    # 1. Headphones on / off (soft padded leather thump + headband stretch snap)
    for tag, dur, f_start, f_end in [("on", 0.55, 220.0, 95.0), ("off", 0.50, 110.0, 260.0)]:
        n = int(dur * SR)
        t = np.arange(n, dtype=np.float32) / SR
        rustle = signal.sosfilt(signal.butter(2, [350, 2800], btype="bandpass", fs=SR, output="sos"), rng.normal(0, 0.5, n).astype(np.float32))
        thump = 0.45 * np.sin(2 * np.pi * np.linspace(f_start, f_end, n) * t) * np.exp(-np.maximum(0, t - 0.14) * 26.0)
        sig = (rustle * np.sin(np.pi * t / dur) * 0.5 + thump)
        encode_ogg(np.stack([sig, np.roll(sig, 14)], axis=1), f"sfx_headphones_{tag}.ogg")

    # 2. Brass Keys Jingle
    dur = 0.85
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    l = np.zeros(n, dtype=np.float32)
    r = np.zeros(n, dtype=np.float32)
    for kt in (0.04, 0.12, 0.21, 0.34, 0.48, 0.62):
        dec = np.exp(-np.maximum(0, t - kt) * 26.0) * (t >= kt)
        cl = sum(np.sin(2 * np.pi * f * rng.uniform(0.95, 1.05) * np.maximum(0, t - kt)) for f in (2800, 4350, 6200, 8100)) * dec * 0.22
        pan = rng.uniform(0.25, 0.75)
        l += cl * pan
        r += cl * (1.0 - pan)
    encode_ogg(np.stack([l, r], axis=1), "sfx_keys_jingle.ogg")

    # 3. Radio Squelch (PTT click + VHF noise burst + tail)
    dur = 0.72
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    sq = signal.sosfilt(signal.butter(3, [500, 3200], btype="bandpass", fs=SR, output="sos"), rng.normal(0, 0.9, n).astype(np.float32))
    env = np.where(t < 0.08, np.exp(-t * 45.0), np.where(t < 0.55, 0.45, np.exp(-(t - 0.55) * 40.0)))
    beep = 0.22 * np.sin(2 * np.pi * 1750.0 * t) * ((t > 0.02) & (t < 0.12)).astype(np.float32)
    sig = sq * env + beep
    encode_ogg(np.stack([sig, sig * 0.96], axis=1), "sfx_radio_squelch.ogg")

    # 4. Mechanical Wristwatch Tick
    dur = 0.8
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    sig = np.zeros(n, dtype=np.float32)
    for tt in (0.05, 0.30, 0.55):
        sig += np.sin(2 * np.pi * 3400.0 * np.maximum(0, t - tt)) * np.exp(-np.maximum(0, t - tt) * 140.0) * (t >= tt) * 0.4
    encode_ogg(np.stack([sig, sig], axis=1), "sfx_watch_tick.ogg")

    # 5. Wall Switch Snap & Drawer/Locker Slide
    for fname, dur, f0 in [("sfx_switch_click.ogg", 0.22, 1850.0), ("sfx_drawer_open.ogg", 0.68, 160.0)]:
        n = int(dur * SR)
        t = np.arange(n, dtype=np.float32) / SR
        if "switch" in fname:
            sig = np.sin(2 * np.pi * f0 * t) * np.exp(-t * 95.0) + rng.normal(0, 0.25, n) * np.exp(-t * 65.0)
        else:
            slide = signal.sosfilt(signal.butter(2, [220, 1400], btype="bandpass", fs=SR, output="sos"), rng.normal(0, 0.8, n).astype(np.float32))
            sig = slide * np.sin(np.pi * t / dur) + 0.35 * np.sin(2 * np.pi * f0 * t) * np.exp(-np.maximum(0, t - 0.52) * 45.0)
        encode_ogg(np.stack([sig, np.roll(sig, 9)], axis=1), fname)

    # 6. Stamina Heavy Breathing (Tired & Exhausted)
    for fname, rate, grit_lvl in [("sfx_breath_tired.ogg", 1.1, 0.38), ("sfx_breath_exhausted.ogg", 1.85, 0.72)]:
        dur = 1.9
        n = int(dur * SR)
        t = np.arange(n, dtype=np.float32) / SR
        breath_env = np.abs(np.sin(np.pi * t * rate)) ** 1.6
        air = signal.sosfilt(signal.butter(3, [380, 1950], btype="bandpass", fs=SR, output="sos"), rng.normal(0, 1.0, n).astype(np.float32))
        throat = signal.sosfilt(signal.butter(2, [190, 520], btype="bandpass", fs=SR, output="sos"), rng.normal(0, 0.7, n).astype(np.float32))
        sig = (air * 0.65 + throat * grit_lvl) * breath_env
        encode_ogg(np.stack([sig, np.roll(sig, 16)], axis=1), fname)

    # 7. Headphone Jumpscare Sting (sharp dissonant sub hit + static shriek)
    dur = 1.6
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    hit = 0.8 * np.sin(2 * np.pi * (95.0 * np.exp(-t * 2.5)) * t) * np.exp(-t * 3.8)
    dissonance = 0.45 * (np.sin(2 * np.pi * 620.0 * t) + np.sin(2 * np.pi * 662.0 * t) + np.sin(2 * np.pi * 1245.0 * t)) * np.exp(-t * 2.9)
    shriek = signal.sosfilt(signal.butter(2, [1100, 6800], btype="bandpass", fs=SR, output="sos"), rng.normal(0, 0.9, n).astype(np.float32)) * np.exp(-t * 4.5)
    sig = np.tanh((hit + dissonance + shriek) * 1.6)
    encode_ogg(np.stack([sig, -np.roll(sig, 18)], axis=1), "sfx_jumpscare_sting.ogg")

    # 8. Loop Layer B: Muffled Apartment Life (TV murmur + distant thuds/pipes)
    dur = 8.0
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / SR
    tv = signal.sosfilt(signal.butter(3, [220, 1100], btype="bandpass", fs=SR, output="sos"), rng.normal(0, 0.6, n).astype(np.float32))
    tv *= (0.45 + 0.55 * np.abs(np.sin(2 * np.pi * 2.3 * t)))
    # Distant muffled apartment door / dog woof burst around 4.8s
    woof_env = np.exp(-((t - 4.8) / 0.14) ** 2) + 0.7 * np.exp(-((t - 5.15) / 0.12) ** 2)
    woof = 0.35 * np.sin(2 * np.pi * 195.0 * t) * woof_env
    encode_ogg(np.stack([tv * 0.45 + woof, np.roll(tv * 0.45, 35) + woof * 0.8], axis=1), "loop_apartment_life.ogg", loop_fade=0.9)

    # 9. Loop Layer A: Cold Autumn Forest Wind in Pines
    n = int(8.0 * SR)
    t = np.arange(n, dtype=np.float32) / SR
    w_raw = rng.normal(0, 1.0, n).astype(np.float32)
    howl_f = 280.0 + 95.0 * np.sin(2 * np.pi * 0.18 * t)
    wind = signal.sosfilt(signal.butter(2, [180, 920], btype="bandpass", fs=SR, output="sos"), w_raw) * (0.4 + 0.5 * np.sin(2 * np.pi * 0.12 * t) ** 2)
    encode_ogg(np.stack([wind, np.roll(wind, 85)], axis=1), "loop_forest_wind.ogg", loop_fade=1.1)


def main():
    build_walkman_music()
    build_surface_footsteps()
    build_equipment_and_world_sfx()
    print("PROMPT02_AUDIO_COMPLETE")


if __name__ == "__main__":
    main()
