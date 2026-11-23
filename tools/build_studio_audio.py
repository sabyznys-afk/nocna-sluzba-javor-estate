r"""
Studio audio, music, SFX, and Piper TTS voice acting builder for NOČNÁ ZMENA: BLOK 14.
Uses FluidSynth 2.6.3 + GeneralUser-GS.sf2, Piper TTS 1.8.0, Python numpy/scipy, and FFmpeg 9.1.
Outputs mastered .ogg files into D:\nocna-zmena-blok-14\assets\audio\.
"""
import math
import pathlib
import struct
import subprocess
import wave
import numpy as np
from scipy.signal import butter, sosfilt

OUT_DIR = pathlib.Path(r"D:\nocna-zmena-blok-14\assets\audio")
TMP_DIR = pathlib.Path(r"D:\nocna-zmena-blok-14\tools\_tmp_audio")

FLUIDSYNTH = r"C:\Users\arnos\scoop\apps\fluidsynth\current\bin\fluidsynth.exe"
SOUNDFONT = r"D:\GameStudioTools\soundfonts\GeneralUser-GS.sf2"
PIPER_EXE = r"D:\GameStudioTools\piper-venv\Scripts\piper.exe"
VOICE_SK = r"D:\GameStudioTools\voices\sk_SK-lili-medium.onnx"
VOICE_EN_M = r"D:\GameStudioTools\voices\en_US-ryan-medium.onnx"
VOICE_EN_F = r"D:\GameStudioTools\voices\en_US-lessac-medium.onnx"
FFMPEG = "ffmpeg"

SR = 44100


def run_cmd(args: list):
    res = subprocess.run(args, capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(args)}\nSTDERR: {res.stderr}")


def write_wav_stereo(path: pathlib.Path, left: np.ndarray, right: np.ndarray):
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(1e-6, float(max(np.max(np.abs(left)), np.max(np.abs(right)))))
    scale = min(1.0, 0.92 / peak)
    l_i16 = np.clip(left * scale * 32767.0, -32768, 32767).astype("<i2")
    r_i16 = np.clip(right * scale * 32767.0, -32768, 32767).astype("<i2")
    interleaved = np.empty(len(l_i16) * 2, dtype="<i2")
    interleaved[0::2] = l_i16
    interleaved[1::2] = r_i16
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(interleaved.tobytes())


def butter_bp(sig: np.ndarray, low: float, high: float, order: int = 3) -> np.ndarray:
    nyq = SR * 0.5
    lo = max(15.0, low) / nyq
    hi = min(nyq * 0.95, high) / nyq
    sos = butter(order, [lo, hi], btype="band", output="sos")
    return sosfilt(sos, sig)


def butter_lp(sig: np.ndarray, cutoff: float, order: int = 3) -> np.ndarray:
    sos = butter(order, min(cutoff / (SR * 0.5), 0.95), btype="low", output="sos")
    return sosfilt(sos, sig)


def butter_hp(sig: np.ndarray, cutoff: float, order: int = 2) -> np.ndarray:
    sos = butter(order, max(cutoff / (SR * 0.5), 0.001), btype="high", output="sos")
    return sosfilt(sos, sig)


def seamless_loop(sig: np.ndarray, xf_samples: int = 22050) -> np.ndarray:
    """Crossfades tail into start so loops are sample-accurate clickless."""
    n = len(sig)
    xf = min(xf_samples, n // 4)
    w = np.linspace(0.0, 1.0, xf, dtype=np.float64)
    out = sig.copy()
    out[:xf] = sig[:xf] * w + sig[-xf:] * (1.0 - w)
    return out[:-xf]


def ffmpeg_master(in_wav: pathlib.Path, out_ogg: pathlib.Path, af: str = "", q: int = 6):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    cmd = [FFMPEG, "-y", "-loglevel", "error", "-i", str(in_wav)]
    if af:
        cmd += ["-af", af]
    cmd += ["-c:a", "libvorbis", "-q:a", str(q), str(out_ogg)]
    run_cmd(cmd)
    print(f"MASTERED_OGG={out_ogg.name}")


# -----------------------------------------------------------------------------
# Pure-Python Standard MIDI File Writer -> FluidSynth Renderer
# -----------------------------------------------------------------------------
def _varlen(val: int) -> bytes:
    buf = [val & 0x7F]
    val >>= 7
    while val:
        buf.append((val & 0x7F) | 0x80)
        val >>= 7
    return bytes(reversed(buf))


def write_midi(path: pathlib.Path, tempo_bpm: int, tracks: list, tpq: int = 480):
    """tracks: list of dicts {'program': int, 'channel': int, 'notes': [(beat, dur_beats, pitch, vel)]}"""
    path.parent.mkdir(parents=True, exist_ok=True)
    chunks = []
    # Tempo meta track
    us_per_quarter = int(60_000_000 / tempo_bpm)
    meta_bytes = bytearray()
    meta_bytes += b"\x00\xFF\x51\x03" + us_per_quarter.to_bytes(3, "big")
    meta_bytes += b"\x00\xFF\x2F\x00"
    chunks.append(b"MTrk" + struct.pack(">I", len(meta_bytes)) + bytes(meta_bytes))

    for tr in tracks:
        ch = tr["channel"] & 0x0F
        prog = tr["program"] & 0x7F
        events = []
        for beat, dur, pitch, vel in tr["notes"]:
            t0 = max(0, int(beat * tpq))
            t1 = max(t0 + 10, int((beat + dur) * tpq))
            events.append((t0, 0x90 | ch, pitch & 0x7F, vel & 0x7F))
            events.append((t1, 0x80 | ch, pitch & 0x7F, 0))
        events.sort(key=lambda e: (e[0], e[1]))
        tbytes = bytearray()
        tbytes += b"\x00" + bytes([0xC0 | ch, prog])
        last_t = 0
        for tick, st, d1, d2 in events:
            tbytes += _varlen(tick - last_t)
            tbytes += bytes([st, d1, d2])
            last_t = tick
        tbytes += b"\x00\xFF\x2F\x00"
        chunks.append(b"MTrk" + struct.pack(">I", len(tbytes)) + bytes(tbytes))

    hdr = b"MThd" + struct.pack(">IHHH", 6, 1, len(chunks), tpq)
    path.write_bytes(hdr + b"".join(chunks))


def render_midi(midi_path: pathlib.Path, wav_path: pathlib.Path):
    run_cmd([FLUIDSYNTH, "-ni", "-F", str(wav_path), "-r", str(SR), SOUNDFONT, str(midi_path)])


def build_music_and_stingers():
    # 1. Menu Theme: 24s (24 beats @ 60 BPM) haunting upright piano + cello pedal + bell
    menu_mid = TMP_DIR / "menu.mid"
    menu_wav = TMP_DIR / "menu.wav"
    piano_notes = [
        (0.0, 2.0, 50, 64), (1.0, 2.0, 57, 56), (2.5, 1.5, 62, 62), (4.0, 2.0, 65, 58),
        (6.0, 2.5, 64, 60), (8.5, 2.0, 61, 52), (10.5, 2.0, 57, 55),
        (12.0, 2.0, 50, 66), (13.2, 1.8, 58, 58), (15.0, 2.0, 62, 64), (17.5, 2.0, 60, 56),
        (19.5, 2.5, 56, 54), (22.0, 2.0, 53, 50),
    ]
    cello_notes = [
        (0.0, 8.0, 38, 62), (8.0, 4.0, 37, 58), (12.0, 8.0, 38, 64), (20.0, 4.0, 36, 56),
    ]
    bell_notes = [(4.0, 4.0, 74, 48), (16.0, 4.0, 69, 44)]
    write_midi(menu_mid, 60, [
        {"channel": 0, "program": 3, "notes": piano_notes},   # Honky-tonk / detuned upright piano
        {"channel": 1, "program": 42, "notes": cello_notes},  # Cello
        {"channel": 2, "program": 14, "notes": bell_notes},   # Distant tubular bell
    ])
    render_midi(menu_mid, menu_wav)
    ffmpeg_master(menu_wav, OUT_DIR / "music_menu_theme.ogg",
                  af="atrim=0:24,afade=t=in:st=0:d=0.6,afade=t=out:st=22.5:d=1.5,aecho=0.8:0.88:70|140:0.35|0.22,lowpass=f=6800,loudnorm=I=-19:TP=-1.5", q=6)

    # 2. Tension Drone: 20s dark strings + choir + contrabass
    drone_mid = TMP_DIR / "drone.mid"
    drone_wav = TMP_DIR / "drone.wav"
    write_midi(drone_mid, 60, [
        {"channel": 0, "program": 48, "notes": [(0.0, 10.0, 38, 68), (10.0, 10.0, 39, 70)]},
        {"channel": 1, "program": 52, "notes": [(2.0, 8.0, 50, 52), (10.5, 9.0, 51, 56)]},
        {"channel": 2, "program": 89, "notes": [(0.0, 19.5, 45, 54)]},
    ])
    render_midi(drone_mid, drone_wav)
    ffmpeg_master(drone_wav, OUT_DIR / "music_tension_drone.ogg",
                  af="atrim=0:20,afade=t=in:st=0:d=1.2,afade=t=out:st=18.5:d=1.5,lowpass=f=2400,aecho=0.85:0.9:80|170:0.45|0.3,loudnorm=I=-20:TP=-1.5", q=6)

    # 3. Anomaly Stinger: 3.5s orchestral dissonance + timpani impact
    sting_mid = TMP_DIR / "sting.mid"
    sting_wav = TMP_DIR / "sting.wav"
    write_midi(sting_mid, 120, [
        {"channel": 0, "program": 44, "notes": [(0.0, 3.2, 62, 92), (0.0, 3.2, 63, 92), (0.0, 3.2, 69, 86)]},
        {"channel": 1, "program": 60, "notes": [(0.0, 2.2, 38, 100)]},
        {"channel": 2, "program": 47, "notes": [(0.0, 1.5, 38, 110)]},
    ])
    render_midi(sting_mid, sting_wav)
    ffmpeg_master(sting_wav, OUT_DIR / "sfx_anomaly_sting.ogg",
                  af="atrim=0:3.8,aecho=0.8:0.88:55|130:0.42|0.25,loudnorm=I=-15:TP=-1.5", q=6)


def build_ambience_and_loops():
    rng = np.random.default_rng(1995)

    # 1. amb_rain_city.ogg (16s seamless stereo rain + wind + distant rumble + faint 50Hz)
    dur = 17.0
    n = int(SR * dur)
    t = np.arange(n, dtype=np.float64) / SR
    wl = rng.normal(0.0, 1.0, n)
    wr = rng.normal(0.0, 1.0, n)
    rain_hi_l = butter_bp(wl, 2400, 7500) * 0.28
    rain_hi_r = butter_bp(wr, 2500, 7600) * 0.28
    rain_mid_l = butter_bp(wl, 550, 1800) * 0.34
    rain_mid_r = butter_bp(wr, 520, 1750) * 0.34
    wind_mod = 0.65 + 0.35 * np.sin(t * 0.7) * np.cos(t * 0.29)
    wind_l = butter_bp(wl, 140, 420) * 0.45 * wind_mod
    wind_r = butter_bp(wr, 150, 440) * 0.45 * (1.2 - 0.4 * wind_mod)
    rumble = butter_lp(wl + wr, 95) * 0.32
    hum = np.sin(math.tau * 50.0 * t) * 0.045

    l_mix = seamless_loop(rain_hi_l + rain_mid_l + wind_l + rumble + hum, SR)
    r_mix = seamless_loop(rain_hi_r + rain_mid_r + wind_r + rumble + hum, SR)
    wav = TMP_DIR / "amb_rain.wav"
    write_wav_stereo(wav, l_mix, r_mix)
    ffmpeg_master(wav, OUT_DIR / "amb_rain_city.ogg", af="loudnorm=I=-21:TP=-1.5", q=6)

    # 2. loop_sodium_buzz.ogg (4.5s -> 4s seamless 100Hz/200Hz streetlamp ballast)
    dur = 4.5
    n = int(SR * dur)
    t = np.arange(n, dtype=np.float64) / SR
    buzz = (np.sin(math.tau * 100.0 * t) * 0.42 +
            np.sin(math.tau * 200.0 * t) * 0.24 +
            np.sin(math.tau * 300.0 * t) * 0.14 +
            butter_bp(rng.normal(0.0, 1.0, n), 1200, 3800) * 0.12)
    b_loop = seamless_loop(buzz, int(0.5 * SR))
    write_wav_stereo(TMP_DIR / "buzz.wav", b_loop, b_loop)
    ffmpeg_master(TMP_DIR / "buzz.wav", OUT_DIR / "loop_sodium_buzz.ogg", af="loudnorm=I=-20:TP=-1.5", q=5)

    # 3. loop_boiler_roar.ogg (6.5s -> 6s deep boiler fire roar + steam hiss)
    dur = 6.5
    n = int(SR * dur)
    t = np.arange(n, dtype=np.float64) / SR
    noise = rng.normal(0.0, 1.0, n)
    roar = butter_lp(noise, 180) * 0.85
    hiss = butter_bp(noise, 2600, 6800) * (0.14 + 0.08 * np.sin(t * 2.1))
    clank_pulse = np.sin(math.tau * 62.0 * t) * 0.12
    boil = seamless_loop(roar + hiss + clank_pulse, int(0.5 * SR))
    write_wav_stereo(TMP_DIR / "boiler.wav", boil, boil)
    ffmpeg_master(TMP_DIR / "boiler.wav", OUT_DIR / "loop_boiler_roar.ogg", af="loudnorm=I=-18:TP=-1.5", q=5)

    # 4. loop_clock_tick.ogg (2.0s exact 1Hz mechanical pendulum tick-tock)
    n = SR * 2
    sig = np.zeros(n, dtype=np.float64)
    for pos_s, f_hi in [(0.05, 1950.0), (1.05, 1520.0)]:
        i0 = int(pos_s * SR)
        seg = int(0.075 * SR)
        tt = np.arange(seg, dtype=np.float64) / SR
        env = np.exp(-tt * 75.0)
        wood_res = np.sin(math.tau * 340.0 * tt) * 0.45 + np.sin(math.tau * f_hi * tt) * 0.35
        click = butter_bp(rng.normal(0.0, 1.0, seg), 1200, 5200) * 0.5
        sig[i0:i0 + seg] += (wood_res + click) * env
    write_wav_stereo(TMP_DIR / "tick.wav", sig, sig)
    ffmpeg_master(TMP_DIR / "tick.wav", OUT_DIR / "loop_clock_tick.ogg", af="aecho=0.8:0.8:32:0.22,loudnorm=I=-18:TP=-1.5", q=5)

    # 5. loop_k4_hum.ogg (6.5s -> 6s ominous 50Hz / 50.4Hz pulsing resonator coil)
    dur = 6.5
    n = int(SR * dur)
    t = np.arange(n, dtype=np.float64) / SR
    k4 = (np.sin(math.tau * 50.0 * t) * 0.48 +
          np.sin(math.tau * 50.4 * t) * 0.38 +
          np.sin(math.tau * 150.0 * t) * 0.14 +
          np.sin(math.tau * 880.0 * t) * (0.04 + 0.03 * np.sin(t * 1.4)))
    k4_l = seamless_loop(k4, int(0.5 * SR))
    write_wav_stereo(TMP_DIR / "k4.wav", k4_l, k4_l)
    ffmpeg_master(TMP_DIR / "k4.wav", OUT_DIR / "loop_k4_hum.ogg", af="loudnorm=I=-18:TP=-1.5", q=5)

    # 6. loop_radio_504.ogg (Piper English whisper numbers + shortwave static)
    rad_voice_wav = TMP_DIR / "radio_voice.wav"
    run_cmd([PIPER_EXE, "-m", VOICE_EN_F, "-f", str(rad_voice_wav), "--length-scale", "1.18", "--",
             "Attention. Sector K four. Fifty point four hertz. Nobody leaves after three."])
    with wave.open(str(rad_voice_wav), "rb") as wf:
        raw_bytes = wf.readframes(wf.getnframes())
        vsr = wf.getframerate()
    samples = np.frombuffer(raw_bytes, dtype="<i2").astype(np.float64) / 32768.0
    if vsr != SR:
        # Linear resample to 44100
        x_old = np.linspace(0.0, 1.0, len(samples))
        x_new = np.linspace(0.0, 1.0, int(len(samples) * SR / vsr))
        samples = np.interp(x_new, x_old, samples)
    tt = np.arange(len(samples), dtype=np.float64) / SR
    static_bed = butter_bp(rng.normal(0.0, 1.0, len(samples)), 500, 3200) * 0.16 + np.sin(math.tau * 890.0 * tt) * 0.04
    rad_mix = samples * 0.78 + static_bed
    rad_mix_wav = TMP_DIR / "radio_mix.wav"
    write_wav_stereo(rad_mix_wav, rad_mix, rad_mix)
    ffmpeg_master(rad_mix_wav, OUT_DIR / "loop_radio_504.ogg",
                  af="highpass=f=420,lowpass=f=2400,aecho=0.8:0.85:40|90:0.32|0.2,loudnorm=I=-18:TP=-1.5", q=5)


def build_foley_sfx():
    rng = np.random.default_rng(9511)

    # Cobblestone footsteps (2 crisp wet heel-toe variants)
    for idx, pitch_mul in [(1, 1.0), (2, 1.12)]:
        n = int(SR * 0.24)
        t = np.arange(n, dtype=np.float64) / SR
        heel = (np.sin(math.tau * 115.0 * pitch_mul * t) * 0.55 +
                butter_bp(rng.normal(0.0, 1.0, n), 700, 3200) * 0.7) * np.exp(-t * 38.0)
        toe_shift = int(0.065 * SR)
        toe_t = np.maximum(0.0, t - 0.065)
        toe = np.where(np.arange(n) >= toe_shift,
                       butter_bp(rng.normal(0.0, 1.0, n), 1200, 4600) * 0.45 * np.exp(-toe_t * 52.0), 0.0)
        s = heel + toe
        w = TMP_DIR / f"step_c{idx}.wav"
        write_wav_stereo(w, s, s * 0.96)
        ffmpeg_master(w, OUT_DIR / f"sfx_step_cobble_{idx}.ogg", af="aecho=0.8:0.85:38:0.18,loudnorm=I=-16:TP=-1.5", q=5)

    # Wood gallery step
    n = int(SR * 0.26)
    t = np.arange(n, dtype=np.float64) / SR
    wood = (np.sin(math.tau * 98.0 * t) * 0.65 + np.sin(math.tau * 195.0 * t) * 0.35 +
            butter_bp(rng.normal(0.0, 1.0, n), 350, 1600) * 0.45) * np.exp(-t * 24.0)
    write_wav_stereo(TMP_DIR / "step_w.wav", wood, wood)
    ffmpeg_master(TMP_DIR / "step_w.wav", OUT_DIR / "sfx_step_wood.ogg", af="loudnorm=I=-16:TP=-1.5", q=5)

    # Metal stair/grate step
    n = int(SR * 0.28)
    t = np.arange(n, dtype=np.float64) / SR
    met = (np.sin(math.tau * 410.0 * t) * 0.4 + np.sin(math.tau * 760.0 * t) * 0.32 +
           butter_bp(rng.normal(0.0, 1.0, n), 1400, 5200) * 0.4) * np.exp(-t * 22.0)
    write_wav_stereo(TMP_DIR / "step_m.wav", met, met)
    ffmpeg_master(TMP_DIR / "step_m.wav", OUT_DIR / "sfx_step_metal.ogg", af="aecho=0.8:0.85:28:0.25,loudnorm=I=-16:TP=-1.5", q=5)

    # Flashlight click
    n = int(SR * 0.09)
    t = np.arange(n, dtype=np.float64) / SR
    clk = (np.sin(math.tau * 1450.0 * t) * 0.5 + butter_bp(rng.normal(0.0, 1.0, n), 1800, 6200) * 0.7) * np.exp(-t * 110.0)
    write_wav_stereo(TMP_DIR / "flash.wav", clk, clk)
    ffmpeg_master(TMP_DIR / "flash.wav", OUT_DIR / "sfx_flashlight.ogg", af="loudnorm=I=-15:TP=-1.5", q=5)

    # Watchman's Clock double brass stamp
    n = int(SR * 0.45)
    t = np.arange(n, dtype=np.float64) / SR
    st1 = (np.sin(math.tau * 520.0 * t) * 0.5 + np.sin(math.tau * 1180.0 * t) * 0.35 +
           butter_bp(rng.normal(0.0, 1.0, n), 900, 3800) * 0.45) * np.exp(-t * 42.0)
    t2 = np.maximum(0.0, t - 0.14)
    st2 = np.where(t >= 0.14, (np.sin(math.tau * 690.0 * t2) * 0.55 + np.sin(math.tau * 1420.0 * t2) * 0.4) * np.exp(-t2 * 48.0), 0.0)
    write_wav_stereo(TMP_DIR / "stamp.wav", st1 + st2, st1 + st2)
    ffmpeg_master(TMP_DIR / "stamp.wav", OUT_DIR / "sfx_clock_stamp.ogg", af="loudnorm=I=-15:TP=-1.5", q=5)

    # 1995 Rotary Twin-Bell Phone Ring
    n = int(SR * 1.45)
    t = np.arange(n, dtype=np.float64) / SR
    ring_gate = ((t < 0.85) & ((np.floor(t * 24.0) % 2) == 0)).astype(np.float64)
    bell = (np.sin(math.tau * 1340.0 * t) * 0.42 + np.sin(math.tau * 1785.0 * t) * 0.38 + np.sin(math.tau * 2680.0 * t) * 0.22)
    ring = bell * (0.28 + 0.72 * ring_gate) * np.where(t < 0.9, 1.0, np.exp(-(t - 0.9) * 9.0))
    write_wav_stereo(TMP_DIR / "ring.wav", ring, ring)
    ffmpeg_master(TMP_DIR / "ring.wav", OUT_DIR / "sfx_phone_ring.ogg", af="aecho=0.8:0.8:25:0.22,loudnorm=I=-15:TP=-1.5", q=5)

    # Heavy Iron Bulkhead Door
    n = int(SR * 0.9)
    t = np.arange(n, dtype=np.float64) / SR
    groan = (np.sin(math.tau * (78.0 + 18.0 * np.sin(t * 7.0)) * t) * 0.55 +
             butter_bp(rng.normal(0.0, 1.0, n), 180, 950) * 0.45) * np.exp(-t * 3.8)
    thud = np.where(t >= 0.45, np.sin(math.tau * 56.0 * (t - 0.45)) * np.exp(-(t - 0.45) * 14.0), 0.0)
    write_wav_stereo(TMP_DIR / "door.wav", groan + thud, groan + thud)
    ffmpeg_master(TMP_DIR / "door.wav", OUT_DIR / "sfx_door_iron.ogg", af="aecho=0.8:0.85:48|105:0.32|0.2,loudnorm=I=-15:TP=-1.5", q=5)

    # VHS Static Burst
    n = int(SR * 0.55)
    t = np.arange(n, dtype=np.float64) / SR
    env = np.sin(math.pi * t / 0.55) ** 0.7
    stat = (rng.normal(0.0, 1.0, n) * 0.55 + np.sin(math.tau * 50.0 * t) * 0.32) * env
    write_wav_stereo(TMP_DIR / "static.wav", stat, rng.normal(0.0, 0.55, n) * env)
    ffmpeg_master(TMP_DIR / "static.wav", OUT_DIR / "sfx_static_burst.ogg", af="loudnorm=I=-15:TP=-1.5", q=5)

    # UI Blip
    n = int(SR * 0.08)
    t = np.arange(n, dtype=np.float64) / SR
    blip = np.sin(math.tau * 680.0 * t) * np.exp(-t * 42.0) * 0.6
    write_wav_stereo(TMP_DIR / "blip.wav", blip, blip)
    ffmpeg_master(TMP_DIR / "blip.wav", OUT_DIR / "sfx_ui_blip.ogg", af="loudnorm=I=-18:TP=-1.5", q=5)


def build_voice_lines():
    lines = [
        ("voice_kovac_n1", VOICE_EN_M, 1.0,
         "Dvorak? Kovac here. Welcome to Kovac Security. Stamp all four Watchman's Clocks, secure the Watchmaker's shutter, check Flat 7, and inspect CCTV. Do NOT touch the red door in the Boiler Room.",
         "highpass=f=320,lowpass=f=3100,acompressor=threshold=-18dB:ratio=4,loudnorm=I=-15:TP=-1.5"),
        ("voice_kovac_n2", VOICE_EN_M, 1.0,
         "Storm is rolling in. At one in the morning a white Mercedes van backs into the gate. You stay inside the booth and log Gate Quiet. Also reset the Arcade fusebox and lock the Notary Office.",
         "highpass=f=320,lowpass=f=3100,acompressor=threshold=-18dB:ratio=4,loudnorm=I=-15:TP=-1.5"),
        ("voice_kovac_n3", VOICE_EN_M, 1.0,
         "Marek, ignore whatever is on Camera 2 tonight, just coaxial crosstalk. Climb up to the rooftop antenna mast, silence any howling TVs in the flats, and leave old Maria alone.",
         "highpass=f=340,lowpass=f=2900,acompressor=threshold=-18dB:ratio=5,loudnorm=I=-15:TP=-1.5"),
        ("voice_kovac_n4", VOICE_EN_M, 0.96,
         "Boiler pressure is red-lining! Get down to the Boiler Room and bleed the steam valve right now. Hruska's men are clearing storage tonight. Stay out of their way and stay out of the Red Door.",
         "highpass=f=340,lowpass=f=2900,acompressor=threshold=-18dB:ratio=5,loudnorm=I=-15:TP=-1.5"),
        ("voice_kovac_n5", VOICE_EN_M, 1.04,
         "You opened the red door, didn't you, Dvorak? Hruska is bringing fifty thousand Deutschmarks at midnight. Sign I saw nothing, or don't walk out at dawn.",
         "highpass=f=340,lowpass=f=2800,acompressor=threshold=-18dB:ratio=5,loudnorm=I=-15:TP=-1.5"),
        ("voice_elena_payphone", VOICE_EN_F, 0.94,
         "Can anyone hear me? Look inside the Watchmaker's grandfather clock before they seal the concrete! Please, don't let Hruska demolish Block 14!",
         "highpass=f=380,lowpass=f=2600,aecho=0.8:0.86:45|95:0.35|0.22,loudnorm=I=-15:TP=-1.5"),
        ("voice_maria_n3", VOICE_EN_F, 1.14,
         "Thank you, Marek. In nineteen fifty-three they didn't dig a well down there. They sealed voices inside the stone.",
         "highpass=f=180,lowpass=f=1800,aecho=0.8:0.8:22:0.18,loudnorm=I=-16:TP=-1.5"),
        ("voice_maria_n5", VOICE_EN_F, 1.12,
         "I'm afraid, Marek. Snow is falling into the sky and Hruska is waiting at the gate. Please help me escape through the back alley.",
         "highpass=f=180,lowpass=f=1800,aecho=0.8:0.8:22:0.18,loudnorm=I=-16:TP=-1.5"),
        ("voice_jozef_bunker", VOICE_EN_M, 1.24,
         "Zero three fourteen. All locks fast. Don't look at the thirteenth window. Someone has to hold the frequency at dawn.",
         "lowpass=f=3400,aecho=0.85:0.9:65|140|230:0.45|0.28|0.16,loudnorm=I=-16:TP=-1.5"),
    ]
    for name, model, lscale, text, af in lines:
        raw_wav = TMP_DIR / f"{name}.wav"
        run_cmd([PIPER_EXE, "-m", model, "-f", str(raw_wav), "--length-scale", str(lscale), "--", text])
        ffmpeg_master(raw_wav, OUT_DIR / f"{name}.ogg", af=af, q=5)


def cleanup_tmp():
    if TMP_DIR.exists():
        for f in TMP_DIR.iterdir():
            f.unlink(missing_ok=True)
        TMP_DIR.rmdir()


def main():
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    build_music_and_stingers()
    build_ambience_and_loops()
    build_foley_sfx()
    build_voice_lines()
    cleanup_tmp()
    print("ALL_STUDIO_AUDIO_BUILT")


if __name__ == "__main__":
    main()
