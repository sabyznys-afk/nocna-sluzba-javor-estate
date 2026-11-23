r"""
Prompt 07 Part 6 & Part 7 — Native Slovak Neural Voice Acting, Spatial Ambient Speech &
Atmospheric World Reaction Generator (Piper sk_SK-lili-medium.onnx + FFmpeg DSP).

Generates organized .ogg audio assets under D:\nocna-zmena-blok-14\assets\audio\voices\:
  Characters/Jozef/      (51yo rough calm male mentor)
  Characters/Martin/     (27yo restrained male protagonist)
  Characters/Anna/       (68yo calm older female resident)
  Characters/Dana/       (39yo direct tired shopkeeper)
  Characters/Milan/      (44yo quiet nervous former guard + cassette hiss)
  Characters/Roman/      (46yo low controlled restrained antagonist)
  AmbientSpeech/Residents/
  AmbientSpeech/Apartments/
  AmbientSpeech/Shops/
  Radio/
  Telephone/
  Environment/           (world reactions: distant dog bark, car starting, shutter closing, window closing, cough)

Also writes voice_registry.json with speaker, language, dialogue text, location, trigger, priority & positional metadata.
"""
import json
import math
import os
import pathlib
import subprocess
import uuid
import numpy as np
import soundfile as sf

PIPER_EXE = r"D:\GameStudioTools\piper-venv\Scripts\piper.exe"
SK_MODEL = r"D:\GameStudioTools\voices\sk_SK-lili-medium.onnx"
OUT_ROOT = pathlib.Path(r"D:\nocna-zmena-blok-14\assets\audio\voices")
TMP_DIR = pathlib.Path(r"D:\GameStudioTools\_tmp")
TMP_DIR.mkdir(parents=True, exist_ok=True)

# Voice timbre profiles applied cleanly via FFmpeg pitch/rate/EQ without robotic artifacts
# Piper sk_SK-lili-medium outputs 22050 Hz mono; shifting asetrate + compensating atempo shifts pitch & formant cleanly!
SPEAKER_DSP = {
    "Jozef":  {"pitch": 0.67, "speed": 0.94, "eq": "bass=g=4:f=140,treble=g=-3:f=4200,acompressor=threshold=-18dB:ratio=3"},
    "Martin": {"pitch": 0.75, "speed": 0.98, "eq": "bass=g=2:f=160,treble=g=-1:f=5000"},
    "Anna":   {"pitch": 0.87, "speed": 0.91, "eq": "treble=g=-3:f=3600,bass=g=1:f=180"},
    "Dana":   {"pitch": 0.95, "speed": 1.00, "eq": "treble=g=-1:f=4600"},
    "Milan":  {"pitch": 0.72, "speed": 0.96, "eq": "bass=g=2:f=150,treble=g=-2:f=3800"},
    "Roman":  {"pitch": 0.63, "speed": 0.88, "eq": "bass=g=5:f=120,lowpass=f=3200,acompressor=threshold=-20dB:ratio=4"},
    "ResM":   {"pitch": 0.71, "speed": 0.97, "eq": "bass=g=2:f=150"},
    "ResF":   {"pitch": 0.98, "speed": 1.02, "eq": "treble=g=-1:f=4800"},
}

ENV_FILTERS = {
    "clear":    "loudnorm=I=-15:TP=-1.5",
    "distant":  "highpass=f=220,lowpass=f=2100,aecho=0.8:0.82:45:0.22,volume=0.82,loudnorm=I=-18:TP=-2.0",
    "wall":     "highpass=f=120,lowpass=f=980,aecho=0.8:0.85:28:0.20,loudnorm=I=-18:TP=-2.0",
    "radio":    "highpass=f=420,lowpass=f=2300,acompressor=threshold=-20dB:ratio=5,acrusher=bits=10:mode=log:aa=1,loudnorm=I=-15:TP=-1.5",
    "phone":    "highpass=f=340,lowpass=f=2900,acompressor=threshold=-18dB:ratio=4,loudnorm=I=-15:TP=-1.5",
    "cassette": "highpass=f=220,lowpass=f=3100,vibrato=f=1.6:d=0.06,acompressor=threshold=-18dB:ratio=4,loudnorm=I=-15:TP=-1.5",
    "tv":       "highpass=f=260,lowpass=f=1450,aecho=0.8:0.8:24:0.18,loudnorm=I=-19:TP=-2.0",
}

VOICE_MANIFEST = [
    # --- JOZEF VARGA (Physical Companion Mentor — exact user lines + natural variations!) ---
    {"id": "jozef_office_intro_01", "path": "Characters/Jozef/jozef_office_intro_01.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office", "trigger": "n1_patrol_start",
     "text": "Všetko si zapisuj. Keď sa niečo stane, papier je dôležitejší než to, čo si pamätáš. Poď za mnou, ukážem ti obchôdzku."},
    {"id": "jozef_gate_02", "path": "Characters/Jozef/jozef_gate_02.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Main Gate", "trigger": "companion_stop_gate",
     "text": "Tak poď. Najskôr skontrolujeme hlavný vchod. V noci sa tu občas zabudne zamknúť."},
    {"id": "jozef_parking_03", "path": "Characters/Jozef/jozef_parking_03.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Parking Lot", "trigger": "companion_stop_parking",
     "text": "Pozri tie garáže. Túto časť musíš obísť pri každej službe."},
    {"id": "jozef_blocka_04", "path": "Characters/Jozef/jozef_blocka_04.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Building A", "trigger": "companion_stop_blocka",
     "text": "Tu si vždy skontroluj dvere. Niektorí obyvatelia ich nechávajú otvorené."},
    {"id": "jozef_park_05", "path": "Characters/Jozef/jozef_park_05.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Central Park", "trigger": "companion_stop_park",
     "text": "Drž sa chodníka. V tej hmle tu ľahko stratíš orientáciu."},
    {"id": "jozef_wait_06", "path": "Characters/Jozef/jozef_wait_06.ogg", "speaker": "Jozef", "env": "clear", "priority": 8, "positional": True, "location": "Patrol Route", "trigger": "companion_wait",
     "text": "Martin, poď, nezostávaj v tej hmle. Počkám ťa tu."},
    {"id": "jozef_sound_07", "path": "Characters/Jozef/jozef_sound_07.ogg", "speaker": "Jozef", "env": "clear", "priority": 9, "positional": True, "location": "Central Park", "trigger": "companion_sound_react",
     "text": "Počul si to? Počkaj chvíľu. Niekedy tu len vietor buchne plechom."},
    {"id": "jozef_shop_07", "path": "Characters/Jozef/jozef_shop_07.ogg", "speaker": "Jozef", "env": "clear", "priority": 9, "positional": True, "location": "Commercial Square", "trigger": "companion_stop_shop",
     "text": "Pri trafike a večierke skontroluj rolety aj zadnú uličku. Dana tu býva dlho."},
    {"id": "jozef_return_08", "path": "Characters/Jozef/jozef_return_08.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office", "trigger": "companion_end_patrol",
     "text": "Dobre. Teraz trasu poznáš. Zapíš si všetko do knihy a ozvi sa mi rádiom, keby niečo nesedelo."},
    {"id": "jozef_n2_handoff", "path": "Characters/Jozef/jozef_n2_handoff.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Courtyard", "trigger": "n2_handoff",
     "text": "V bloku C hlásili kroky z prázdneho bytu. Prejdi to tam sám, ja musím ešte skontrolovať výkaz."},

    # --- MARTIN KOVÁČ (Protagonist) ---
    {"id": "martin_arrival_01", "path": "Characters/Martin/martin_arrival_01.ogg", "speaker": "Martin", "env": "clear", "priority": 8, "positional": False, "location": "Security Office", "trigger": "n1_start",
     "text": "Prvá nočná na sídlisku Javor. Hmla je hustá, sotva vidno na pár metrov."},
    {"id": "martin_reply_02", "path": "Characters/Martin/martin_reply_02.ogg", "speaker": "Martin", "env": "clear", "priority": 7, "positional": False, "location": "Patrol Route", "trigger": "n1_reply",
     "text": "Dobre, pán Varga. Idem za vami."},
    {"id": "martin_alone_03", "path": "Characters/Martin/martin_alone_03.ogg", "speaker": "Martin", "env": "clear", "priority": 8, "positional": False, "location": "Estate", "trigger": "n4_corridor",
     "text": "Niekto tu bol. Tie stopy sú ešte čerstvé."},
    {"id": "martin_blackout_04", "path": "Characters/Martin/martin_blackout_04.ogg", "speaker": "Martin", "env": "clear", "priority": 9, "positional": False, "location": "Estate", "trigger": "n6_blackout",
     "text": "Vypadol prúd na celom sídlisku. Musím sa dostať k miestnosti štyridsaťsedem."},

    # --- ANNA KRÍŽANOVÁ (68, Resident Building A) ---
    {"id": "anna_building_a_01", "path": "Characters/Anna/anna_building_a_01.ogg", "speaker": "Anna", "env": "clear", "priority": 9, "positional": True, "location": "Building A", "trigger": "npc_anna_n1",
     "text": "Vy ste ten nový strážnik? Pred vami tu slúžil Milan. Bol to tichý človek, poznal každý vchod."},
    {"id": "anna_building_a_02", "path": "Characters/Anna/anna_building_a_02.ogg", "speaker": "Anna", "env": "clear", "priority": 9, "positional": True, "location": "Building A", "trigger": "npc_anna_n2",
     "text": "Včera po polnoci tu niekto prešiel cez dvor v tmavom montérkovom kabáte. Tvár som mu nevidela."},
    {"id": "anna_building_a_03", "path": "Characters/Anna/anna_building_a_03.ogg", "speaker": "Anna", "env": "clear", "priority": 9, "positional": True, "location": "Building A", "trigger": "npc_anna_n4",
     "text": "Dávajte si pozor pri bloku B, mladý pán. O tom byte štyridsaťsedem sa tu radšej nerozpráva."},

    # --- DANA BIELIKOVÁ (39, Večierka / Newsstand) ---
    {"id": "dana_night_shop_01", "path": "Characters/Dana/dana_night_shop_01.ogg", "speaker": "Dana", "env": "clear", "priority": 9, "positional": True, "location": "Večierka", "trigger": "npc_dana_n1",
     "text": "Dobrý večer, už pomaly zatváram. Pred chvíľou stál niekto pri severnom paneláku, neviem či tu býva."},
    {"id": "dana_night_shop_02", "path": "Characters/Dana/dana_night_shop_02.ogg", "speaker": "Dana", "env": "clear", "priority": 9, "positional": True, "location": "Večierka", "trigger": "npc_dana_n2",
     "text": "Už druhý večer niekto chodí do zadnej zásobovacej uličky. Určite nič nekupoval."},
    {"id": "dana_night_shop_03", "path": "Characters/Dana/dana_night_shop_03.ogg", "speaker": "Dana", "env": "clear", "priority": 9, "positional": True, "location": "Večierka", "trigger": "npc_dana_n4",
     "text": "Svetlo mi tu celé hodiny bliká. Ak pôjdete k trafostanici, povedzte Vargovi, nech to dá opraviť."},

    # --- MILAN ŠVEC (44, Former Guard — Cassette Recordings & Rescue) ---
    {"id": "milan_cassette_01", "path": "Characters/Milan/milan_cassette_01.ogg", "speaker": "Milan", "env": "cassette", "priority": 10, "positional": False, "location": "Delivery Alley", "trigger": "tape_milan_01",
     "text": "Dvanásteho novembra. Niekto ma na obchôdzke sleduje. Byt štyridsaťsedem nie je normálny byt, vedie tam stará servisná chodba."},
    {"id": "milan_cassette_02", "path": "Characters/Milan/milan_cassette_02.ogg", "speaker": "Milan", "env": "cassette", "priority": 10, "positional": False, "location": "Hidden Corridor", "trigger": "tape_milan_02",
     "text": "Ak toto nájde nový strážnik, stále som tu dole pri kotolni. Prineste údržbársky kľúč."},
    {"id": "milan_rescue_03", "path": "Characters/Milan/milan_rescue_03.ogg", "speaker": "Milan", "env": "clear", "priority": 10, "positional": True, "location": "Apartment 47 Room", "trigger": "n6_milan_rescue",
     "text": "Martin? Vďaka Bohu. Roman Král pozná každú pivnicu. Poďme k zadnej bráne, kým je ešte tma."},

    # --- ROMAN KRÁL (46, Human Antagonist — Quiet Controlled Voice) ---
    {"id": "roman_unknown_voice_01", "path": "Characters/Roman/roman_unknown_voice_01.ogg", "speaker": "Roman", "env": "radio", "priority": 10, "positional": False, "location": "Radio CH-04", "trigger": "n6_radio_warning",
     "text": "Nechodíš sám."},
    {"id": "roman_corridor_02", "path": "Characters/Roman/roman_corridor_02.ogg", "speaker": "Roman", "env": "distant", "priority": 8, "positional": True, "location": "Corridor", "trigger": "n6_pursuit",
     "text": "Nemal si sem chodiť. Vráť tie kľúče a choď domov."},

    # --- RADIO & TELEPHONE COMMUNICATIONS ---
    {"id": "radio_varga_check_01", "path": "Radio/radio_varga_check_01.ogg", "speaker": "Jozef", "env": "radio", "priority": 9, "positional": False, "location": "VHF Radio", "trigger": "radio_hint",
     "text": "Martin, ozvi sa. Pozri do zošita na ďalší bod obchôdzky a skontroluj zámky."},
    {"id": "radio_varga_end_b", "path": "Radio/radio_varga_end_b.ogg", "speaker": "Jozef", "env": "radio", "priority": 10, "positional": False, "location": "Outer Service Gate", "trigger": "ending_b",
     "text": "Zmena ukončená. Vráťte sa do služby."},
    {"id": "radio_dispatch_02", "path": "Radio/radio_dispatch_02.ogg", "speaker": "ResM", "env": "radio", "priority": 6, "positional": False, "location": "VHF Radio", "trigger": "ambient_radio",
     "text": "Centrála Nový Brod, linka štyri. Hlásenie bez mimoriadnych udalostí, kontrola o druhej nula nula."},
    {"id": "phone_varga_brief_01", "path": "Telephone/phone_varga_brief_01.ogg", "speaker": "Jozef", "env": "phone", "priority": 10, "positional": True, "location": "Security Office Phone", "trigger": "office_phone",
     "text": "Martin, tu Varga. Nechaj staré servisné dvere na pokoji a drž sa bežnej obchôdzky."},

    # --- SPATIAL AMBIENT HUMAN SPEECH: RESIDENTS (Exterior Courtyards & Entrances) ---
    {"id": "resident_conv_01", "path": "AmbientSpeech/Residents/resident_conv_01.ogg", "speaker": "ResM", "env": "distant", "priority": 3, "positional": True, "location": "Building D Entrance", "trigger": "ambient_resident",
     "text": "Zase prší, človek ani nevysuší topánky. Kúpil si ešte chlieb v Jednote?"},
    {"id": "resident_conv_02", "path": "AmbientSpeech/Residents/resident_conv_02.ogg", "speaker": "ResF", "env": "distant", "priority": 3, "positional": True, "location": "Building A Path", "trigger": "ambient_resident",
     "text": "Dobrý večer, sused. Tie lampy pri parku zase nesvietia, už som to hlásila dvakrát."},
    {"id": "resident_conv_03", "path": "AmbientSpeech/Residents/resident_conv_03.ogg", "speaker": "ResM", "env": "distant", "priority": 3, "positional": True, "location": "Courtyard", "trigger": "ambient_resident",
     "text": "Počúvaj, nezabudni zamknúť pivnicu. Minulý týždeň tam zase niekto nechal rozsvietené."},
    {"id": "resident_greeting_04", "path": "AmbientSpeech/Residents/resident_greeting_04.ogg", "speaker": "ResF", "env": "distant", "priority": 3, "positional": True, "location": "Building C Front", "trigger": "ambient_resident",
     "text": "Dobrý večer, pán strážnik. Chladná noc dnes, však?"},

    # --- SPATIAL AMBIENT HUMAN SPEECH: BEHIND APARTMENT WALLS & WINDOWS ---
    {"id": "apt_muffled_conv_01", "path": "AmbientSpeech/Apartments/apt_muffled_conv_01.ogg", "speaker": "ResM", "env": "wall", "priority": 2, "positional": True, "location": "Building A Windows", "trigger": "ambient_apartment",
     "text": "Stíš trochu ten televízor, už je skoro jedenásť a zajtra vstávam do práce."},
    {"id": "apt_muffled_conv_02", "path": "AmbientSpeech/Apartments/apt_muffled_conv_02.ogg", "speaker": "ResF", "env": "wall", "priority": 2, "positional": True, "location": "Building C Stairwell", "trigger": "ambient_apartment",
     "text": "Kto tam zase chodí po schodoch tak neskoro? Pozri cez kukátko, či nezabudli zavrieť vchod."},
    {"id": "apt_tv_news_03", "path": "AmbientSpeech/Apartments/apt_tv_news_03.ogg", "speaker": "ResM", "env": "tv", "priority": 2, "positional": True, "location": "Building D Flat 4", "trigger": "ambient_tv",
     "text": "Večerné správy. Na západnom a strednom Slovensku dnes v noci očakávame hustú hmlu a mrholenie."},
    {"id": "apt_balcony_04", "path": "AmbientSpeech/Apartments/apt_balcony_04.ogg", "speaker": "ResF", "env": "distant", "priority": 2, "positional": True, "location": "Building B Balcony", "trigger": "ambient_apartment",
     "text": "Zavri to okno, tiahne sem zima a dym z kotolne."},

    # --- SPATIAL AMBIENT HUMAN SPEECH: SHOPS (Trafika / Večierka) ---
    {"id": "shop_customer_01", "path": "AmbientSpeech/Shops/shop_customer_01.ogg", "speaker": "Dana", "env": "distant", "priority": 3, "positional": True, "location": "Večierka", "trigger": "ambient_shop",
     "text": "Nech sa páči, dvadsaťštyri korún. Pečivo príde zase až ráno o šiestej."},
    {"id": "shop_closing_02", "path": "AmbientSpeech/Shops/shop_closing_02.ogg", "speaker": "ResF", "env": "distant", "priority": 3, "positional": True, "location": "Trafika", "trigger": "ambient_shop",
     "text": "Noviny sú zrovnané, ešte skontrolujem kasu a spustím roletu."},
    {"id": "shop_phone_03", "path": "AmbientSpeech/Shops/shop_phone_03.ogg", "speaker": "Dana", "env": "distant", "priority": 3, "positional": True, "location": "Večierka", "trigger": "ambient_shop",
     "text": "Áno, už končím. O pol hodinu som doma, len odovzdám kľúče strážnikovi."},
]


def synthesize_voice(entry):
    out_path = OUT_ROOT / entry["path"]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    raw_wav = TMP_DIR / f"piper_{uuid.uuid4().hex}.wav"

    # Step 1: Synthesize native Slovak neural speech with Piper sk_SK-lili-medium
    p_cmd = [PIPER_EXE, "--model", SK_MODEL, "--output_file", str(raw_wav)]
    res = subprocess.run(p_cmd, input=entry["text"].encode("utf-8"), capture_output=True)
    if res.returncode != 0 or not raw_wav.exists():
        raise RuntimeError(f"Piper failed on {entry['id']}: {res.stderr.decode('utf-8', 'ignore')}")

    # Step 2: Apply speaker pitch/formant character + 1996 environment filter via FFmpeg
    sp = SPEAKER_DSP[entry["speaker"]]
    pitch = float(sp["pitch"])
    speed = float(sp["speed"])
    # Preserve natural speaking speed while shifting pitch + vocal tract character!
    atempo = max(0.5, min(2.0, speed / pitch))
    target_rate = int(round(22050.0 * pitch))

    chain = [
        f"asetrate={target_rate}",
        "aresample=22050",
        f"atempo={atempo:.4f}",
        sp["eq"],
        ENV_FILTERS[entry["env"]],
    ]
    af = ",".join(chain)
    ff_cmd = [
        "ffmpeg", "-y", "-loglevel", "error",
        "-i", str(raw_wav),
        "-af", af,
        "-ac", "1",
        "-c:a", "libvorbis", "-q:a", "5",
        str(out_path),
    ]
    ff = subprocess.run(ff_cmd, capture_output=True, text=True)
    raw_wav.unlink(missing_ok=True)
    if ff.returncode != 0:
        raise RuntimeError(f"FFmpeg failed on {entry['id']}: {ff.stderr}")


def _write_env_ogg(rel_path: str, samples: np.ndarray, sr: int = 22050):
    out_path = OUT_ROOT / rel_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_w = TMP_DIR / f"env_{uuid.uuid4().hex}.wav"
    peak = float(np.max(np.abs(samples))) + 1e-6
    norm = np.clip(samples / peak * 0.85, -1.0, 1.0).astype(np.float32)
    sf.write(str(tmp_w), norm, sr)
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp_w), "-c:a", "libvorbis", "-q:a", "5", str(out_path)],
        check=True,
    )
    tmp_w.unlink(missing_ok=True)


def generate_world_reaction_sfx():
    # Part 7: Grounded environmental reaction sounds (distant dog bark, car starting, window closing, shutter closing, cough)
    sr = 22050
    rng = np.random.default_rng(199607)

    # 1. Distant dog bark (two low-pass filtered resonant vocal barks echoing in fog)
    t = np.linspace(0, 1.8, int(sr * 1.8), endpoint=False)
    sig = np.zeros_like(t)
    for start in [0.15, 0.72]:
        mask = (t >= start) & (t < start + 0.22)
        lt = t[mask] - start
        env = np.sin(np.pi * lt / 0.22) ** 1.4
        f0 = 260.0 - 95.0 * (lt / 0.22)
        bark = (np.sin(2 * np.pi * np.cumsum(f0) / sr) * 0.6 + np.sin(2 * np.pi * np.cumsum(f0 * 2.1) / sr) * 0.35 + rng.normal(0, 0.22, lt.size)) * env
        sig[mask] += bark
    # Simple moving-average distance lowpass + echo
    sig = np.convolve(sig, np.ones(9) / 9.0, mode="same")
    sig[3500:] += sig[:-3500] * 0.28
    _write_env_ogg("Environment/env_dog_bark_distant.ogg", sig, sr)

    # 2. Old 1990s Skoda/Lada car starter cranking & idling away in street
    t = np.linspace(0, 3.2, int(sr * 3.2), endpoint=False)
    crank = (t < 1.1).astype(np.float32) * (0.5 + 0.5 * np.sin(2 * np.pi * 6.5 * t)) * (np.sin(2 * np.pi * 88 * t) + 0.5 * rng.normal(0, 0.4, t.size))
    idle_env = np.clip((t - 0.95) * 2.5, 0.0, 1.0) * np.clip((3.2 - t) * 1.4, 0.0, 1.0)
    idle = idle_env * (np.sin(2 * np.pi * 46 * t) * 0.7 + np.sin(2 * np.pi * 92 * t) * 0.4 + rng.normal(0, 0.18, t.size))
    car_sig = np.convolve(crank * 0.55 + idle * 0.75, np.ones(11) / 11.0, mode="same")
    _write_env_ogg("Environment/env_car_start_distant.ogg", car_sig, sr)

    # 3. Apartment wooden window sliding & latching shut
    t = np.linspace(0, 1.2, int(sr * 1.2), endpoint=False)
    slide = ((t >= 0.05) & (t < 0.65)).astype(np.float32) * rng.normal(0, 0.25, t.size) * np.sin(np.pi * np.clip((t - 0.05) / 0.6, 0, 1))
    thud = np.exp(-np.maximum(0.0, t - 0.68) * 28.0) * (t >= 0.68) * (np.sin(2 * np.pi * 115 * t) * 0.9 + rng.normal(0, 0.3, t.size))
    win_sig = np.convolve(slide + thud, np.ones(7) / 7.0, mode="same")
    _write_env_ogg("Environment/env_window_close.ogg", win_sig, sr)

    # 4. Shop corrugated metal shutter rolling down & clanking shut
    t = np.linspace(0, 2.2, int(sr * 2.2), endpoint=False)
    roll = ((t >= 0.1) & (t < 1.65)).astype(np.float32) * (0.6 + 0.4 * np.sin(2 * np.pi * 18.0 * t)) * rng.normal(0, 0.45, t.size)
    slam = np.exp(-np.maximum(0.0, t - 1.68) * 16.0) * (t >= 1.68) * (np.sin(2 * np.pi * 145 * t) + 0.6 * np.sin(2 * np.pi * 310 * t) + rng.normal(0, 0.5, t.size))
    shutter_sig = np.convolve(roll * 0.55 + slam * 0.9, np.ones(5) / 5.0, mode="same")
    _write_env_ogg("Environment/env_shutter_close.ogg", shutter_sig, sr)

    # 5. Muffled person coughing behind concrete apartment wall
    t = np.linspace(0, 1.4, int(sr * 1.4), endpoint=False)
    cough = np.zeros_like(t)
    for st_c in [0.18, 0.58]:
        m = (t >= st_c) & (t < st_c + 0.20)
        lt = t[m] - st_c
        env = np.exp(-lt * 11.0) * np.sin(np.pi * lt / 0.20)
        cough[m] += (rng.normal(0, 0.55, lt.size) + 0.5 * np.sin(2 * np.pi * 155 * lt)) * env
    cough = np.convolve(cough, np.ones(15) / 15.0, mode="same")
    _write_env_ogg("Environment/env_cough_wall.ogg", cough, sr)
    print("GENERATED_WORLD_REACTION_SFX=5")


def main():
    registry = []
    for item in VOICE_MANIFEST:
        synthesize_voice(item)
        registry.append({
            "id": item["id"],
            "file": "res://assets/audio/voices/" + item["path"],
            "speaker": item["speaker"],
            "language": "sk",
            "text": item["text"],
            "location": item["location"],
            "trigger": item["trigger"],
            "priority": item["priority"],
            "positional": item["positional"],
        })
    generate_world_reaction_sfx()
    reg_path = OUT_ROOT / "voice_registry.json"
    reg_path.write_text(json.dumps({"language": "sk", "voices": registry}, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"GENERATED_SLOVAK_VOICES={len(registry)} REGISTRY={reg_path}")


if __name__ == "__main__":
    main()
