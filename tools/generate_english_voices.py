r"""
Prompt 08 — Natural English Neural Voice Acting, Tutorial Dialogue, Spatial Ambient Speech &
Atmospheric World Reaction Generator (Piper en_US-ryan-medium.onnx + en_US-lessac-medium.onnx + FFmpeg DSP).

Synthesizes all organized .ogg voice assets under D:\nocna-zmena-blok-14\assets\audio\voices\:
  Characters/Jozef/      (51yo gruff calm male mentor — full tutorial + guided patrol lines)
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

Writes voice_registry.json with language="en" and full trigger/priority/spatial metadata.
"""
import json
import pathlib
import subprocess
import uuid
import wave
import numpy as np

PIPER_EXE = r"D:\GameStudioTools\piper-venv\Scripts\piper.exe"
EN_MALE_MODEL = r"D:\GameStudioTools\voices\en_US-ryan-medium.onnx"
EN_FEMALE_MODEL = r"D:\GameStudioTools\voices\en_US-lessac-medium.onnx"
OUT_ROOT = pathlib.Path(r"D:\nocna-zmena-blok-14\assets\audio\voices")
TMP_DIR = pathlib.Path(r"D:\GameStudioTools\_tmp")
TMP_DIR.mkdir(parents=True, exist_ok=True)

# Clean distinct English speaker profiles using native male (Ryan) and female (Lessac) Piper voices
SPEAKER_DSP = {
    "Jozef":  {"model": EN_MALE_MODEL,   "pitch": 0.90, "speed": 0.94, "eq": "bass=g=4:f=140,treble=g=-2:f=4200,acompressor=threshold=-18dB:ratio=3"},
    "Martin": {"model": EN_MALE_MODEL,   "pitch": 1.04, "speed": 1.00, "eq": "bass=g=1:f=160,treble=g=-1:f=5200"},
    "Anna":   {"model": EN_FEMALE_MODEL, "pitch": 0.89, "speed": 0.91, "eq": "treble=g=-3:f=3600,bass=g=1:f=180"},
    "Dana":   {"model": EN_FEMALE_MODEL, "pitch": 0.98, "speed": 1.00, "eq": "treble=g=-1:f=4600"},
    "Milan":  {"model": EN_MALE_MODEL,   "pitch": 0.97, "speed": 0.96, "eq": "bass=g=2:f=150,treble=g=-2:f=3800"},
    "Roman":  {"model": EN_MALE_MODEL,   "pitch": 0.82, "speed": 0.88, "eq": "bass=g=5:f=120,lowpass=f=3200,acompressor=threshold=-20dB:ratio=4"},
    "ResM":   {"model": EN_MALE_MODEL,   "pitch": 0.95, "speed": 0.98, "eq": "bass=g=2:f=150"},
    "ResF":   {"model": EN_FEMALE_MODEL, "pitch": 1.02, "speed": 1.02, "eq": "treble=g=-1:f=4800"},
}

ENV_FILTERS = {
    "clear":    "loudnorm=I=-15:TP=-1.5",
    "distant":  "highpass=f=220,lowpass=f=2200,aecho=0.8:0.82:42:0.20,volume=0.85,loudnorm=I=-18:TP=-2.0",
    "wall":     "highpass=f=120,lowpass=f=980,aecho=0.8:0.85:28:0.18,loudnorm=I=-18:TP=-2.0",
    "radio":    "highpass=f=420,lowpass=f=2400,acompressor=threshold=-20dB:ratio=5,acrusher=bits=10:mode=log:aa=1,loudnorm=I=-15:TP=-1.5",
    "phone":    "highpass=f=340,lowpass=f=2900,acompressor=threshold=-18dB:ratio=4,loudnorm=I=-15:TP=-1.5",
    "cassette": "highpass=f=220,lowpass=f=3100,vibrato=f=1.6:d=0.05,acompressor=threshold=-18dB:ratio=4,loudnorm=I=-15:TP=-1.5",
    "tv":       "highpass=f=260,lowpass=f=1450,aecho=0.8:0.8:24:0.18,loudnorm=I=-19:TP=-2.0",
}

VOICE_MANIFEST = [
    # --- JOZEF VARGA: 8-STAGE INTERACTIVE TUTORIAL LINES (Prompt 08 Part 3) ---
    {"id": "jozef_tut_welcome", "path": "Characters/Jozef/jozef_tut_welcome.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office", "trigger": "tut_stage_0",
     "text": "So you're Martin. Come inside, I'll show you what you'll be doing here. It's nothing complicated. Just watch the doors, write down your rounds, and never leave anything unlocked."},
    {"id": "jozef_tut_move", "path": "Characters/Jozef/jozef_tut_move.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office", "trigger": "tut_stage_1",
     "text": "Step over here by the desk and take a good look around the office so you know where everything sits."},
    {"id": "jozef_tut_notebook", "path": "Characters/Jozef/jozef_tut_notebook.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office", "trigger": "tut_stage_2",
     "text": "Everything important is written down in here. I don't expect you to remember the whole estate from memory. Open your notebook, check the map, and try writing a quick note."},
    {"id": "jozef_tut_inventory", "path": "Characters/Jozef/jozef_tut_inventory.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office", "trigger": "tut_stage_3",
     "text": "Your belt holds your torch, keys, radio, notebook, and taser. Scroll the mouse wheel or use the number keys to switch gear, and keep empty hands when you don't need tools."},
    {"id": "jozef_tut_flashlight", "path": "Characters/Jozef/jozef_tut_flashlight.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office", "trigger": "tut_stage_4",
     "text": "When something breaks down, your flashlight will save you. Take it out, switch it on and off, and shine it across a couple of things in here."},
    {"id": "jozef_tut_keys_doors", "path": "Characters/Jozef/jozef_tut_keys_doors.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office Door", "trigger": "tut_stage_5",
     "text": "Opening a door and unlocking it aren't the same thing. Take out your keys, look at the handle, try locking and unlocking it, and step through."},
    {"id": "jozef_tut_radio", "path": "Characters/Jozef/jozef_tut_radio.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office", "trigger": "tut_stage_6",
     "text": "Grab your handheld radio and run a quick channel check so dispatch knows you're on shift."},
    {"id": "jozef_tut_headphones", "path": "Characters/Jozef/jozef_tut_headphones.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office", "trigger": "tut_stage_7",
     "text": "I see you brought a Walkman. Music helps pass a quiet night, but be careful — with headphones on, you won't hear footsteps coming up behind you. Try them on and take them off."},

    # --- JOZEF VARGA: GUIDED PATROL LINES ---
    {"id": "jozef_office_intro_01", "path": "Characters/Jozef/jozef_office_intro_01.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office", "trigger": "n1_patrol_start",
     "text": "Write everything down. When something goes wrong, paper matters more than memory. Follow me — I'll walk you through your first patrol."},
    {"id": "jozef_gate_02", "path": "Characters/Jozef/jozef_gate_02.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Main Gate", "trigger": "companion_stop_gate",
     "text": "Come on. First we check the main entrance gate. People sometimes forget to lock it at night. Inspect the latch and log it in your notebook."},
    {"id": "jozef_parking_03", "path": "Characters/Jozef/jozef_parking_03.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Parking Lot", "trigger": "companion_stop_parking",
     "text": "Keep to the center walkway between the parked cars. Check the parking lot and garage lane on every single shift."},
    {"id": "jozef_blocka_04", "path": "Characters/Jozef/jozef_blocka_04.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Building A", "trigger": "companion_stop_blocka",
     "text": "Take a look at this door at Building A. Make sure it's shut and locked — residents leave it propped open. Then log it in your notebook."},
    {"id": "jozef_park_05", "path": "Characters/Jozef/jozef_park_05.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Central Park", "trigger": "companion_stop_park",
     "text": "Stick to the paved path through Central Park. In November fog it's easy to lose your bearings."},
    {"id": "jozef_wait_06", "path": "Characters/Jozef/jozef_wait_06.ogg", "speaker": "Jozef", "env": "clear", "priority": 8, "positional": True, "location": "Patrol Route", "trigger": "companion_wait",
     "text": "Martin, come on — don't fall behind in the fog. I'll wait right here for you."},
    {"id": "jozef_sound_07", "path": "Characters/Jozef/jozef_sound_07.ogg", "speaker": "Jozef", "env": "clear", "priority": 9, "positional": True, "location": "Central Park", "trigger": "companion_sound_react",
     "text": "Did you hear that? Hold on a second. Sometimes the wind rattles loose metal out here."},
    {"id": "jozef_shop_07", "path": "Characters/Jozef/jozef_shop_07.ogg", "speaker": "Jozef", "env": "clear", "priority": 9, "positional": True, "location": "Commercial Square", "trigger": "companion_stop_shop",
     "text": "Check the Newsstand shutters and Night Shop entrance here. Dana has worked this square for years — she notices strangers."},
    {"id": "jozef_return_08", "path": "Characters/Jozef/jozef_return_08.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Security Office", "trigger": "companion_end_patrol",
     "text": "Right, that's everything. You can handle the next rounds on your own. Log your notes at the desk and call me on the radio if anything feels off."},
    {"id": "jozef_n2_handoff", "path": "Characters/Jozef/jozef_n2_handoff.ogg", "speaker": "Jozef", "env": "clear", "priority": 10, "positional": True, "location": "Courtyard", "trigger": "n2_handoff",
     "text": "Someone reported footsteps in an empty flat in Building C. Check it out yourself tonight — I still have paperwork at the main office."},

    # --- MARTIN KOVAC (Protagonist) ---
    {"id": "martin_arrival_01", "path": "Characters/Martin/martin_arrival_01.ogg", "speaker": "Martin", "env": "clear", "priority": 8, "positional": False, "location": "Security Office", "trigger": "n1_start",
     "text": "First night shift at the Javor Estate. The November mist is rolling in off the pines."},
    {"id": "martin_reply_02", "path": "Characters/Martin/martin_reply_02.ogg", "speaker": "Martin", "env": "clear", "priority": 7, "positional": False, "location": "Patrol Route", "trigger": "n1_reply",
     "text": "Got it, Mr. Varga. Right behind you."},
    {"id": "martin_alone_03", "path": "Characters/Martin/martin_alone_03.ogg", "speaker": "Martin", "env": "clear", "priority": 8, "positional": False, "location": "Estate", "trigger": "n4_corridor",
     "text": "Somebody was just down here. Those boot prints are still wet."},
    {"id": "martin_blackout_04", "path": "Characters/Martin/martin_blackout_04.ogg", "speaker": "Martin", "env": "clear", "priority": 9, "positional": False, "location": "Estate", "trigger": "n6_blackout",
     "text": "Power's out across the entire estate. I need to reach Room Forty-Seven."},

    # --- ANNA KRIZANOVA (68, Resident Building A) ---
    {"id": "anna_building_a_01", "path": "Characters/Anna/anna_building_a_01.ogg", "speaker": "Anna", "env": "clear", "priority": 9, "positional": True, "location": "Building A", "trigger": "npc_anna_n1",
     "text": "You're the new night watchman? Milan used to work this estate before you. Quiet man — knew every stairwell lock by heart."},
    {"id": "anna_building_a_02", "path": "Characters/Anna/anna_building_a_02.ogg", "speaker": "Anna", "env": "clear", "priority": 9, "positional": True, "location": "Building A", "trigger": "npc_anna_n2",
     "text": "Last night past midnight someone crossed the yard wearing a dark maintenance coat. I couldn't see his face."},
    {"id": "anna_building_a_03", "path": "Characters/Anna/anna_building_a_03.ogg", "speaker": "Anna", "env": "clear", "priority": 9, "positional": True, "location": "Building A", "trigger": "npc_anna_n4",
     "text": "Be careful around Building B, young man. Folks around here don't like talking about Apartment Forty-Seven."},

    # --- DANA BIELIKOVA (39, Night Shop) ---
    {"id": "dana_night_shop_01", "path": "Characters/Dana/dana_night_shop_01.ogg", "speaker": "Dana", "env": "clear", "priority": 9, "positional": True, "location": "Night Shop", "trigger": "npc_dana_n1",
     "text": "Good evening, just closing up. Earlier someone stood by the northern apartment block for ten minutes without going inside."},
    {"id": "dana_night_shop_02", "path": "Characters/Dana/dana_night_shop_02.ogg", "speaker": "Dana", "env": "clear", "priority": 9, "positional": True, "location": "Night Shop", "trigger": "npc_dana_n2",
     "text": "Second night in a row somebody slipped down the back delivery alley. Definitely wasn't buying groceries."},
    {"id": "dana_night_shop_03", "path": "Characters/Dana/dana_night_shop_03.ogg", "speaker": "Dana", "env": "clear", "priority": 9, "positional": True, "location": "Night Shop", "trigger": "npc_dana_n4",
     "text": "My ceiling lights have been flickering for hours. If you pass the substation, tell Varga to get an electrician out here."},

    # --- MILAN SVEC (44, Former Guard — Cassette Recordings & Rescue) ---
    {"id": "milan_cassette_01", "path": "Characters/Milan/milan_cassette_01.ogg", "speaker": "Milan", "env": "cassette", "priority": 10, "positional": False, "location": "Delivery Alley", "trigger": "tape_milan_01",
     "text": "November twelfth. Someone has been shadowing my patrol. Apartment Forty-Seven isn't a real flat — an old maintenance corridor runs right under it."},
    {"id": "milan_cassette_02", "path": "Characters/Milan/milan_cassette_02.ogg", "speaker": "Milan", "env": "cassette", "priority": 10, "positional": False, "location": "Hidden Corridor", "trigger": "tape_milan_02",
     "text": "If the new guard finds this tape, I'm still down here past the boiler tunnel. Bring the maintenance key."},
    {"id": "milan_rescue_03", "path": "Characters/Milan/milan_rescue_03.ogg", "speaker": "Milan", "env": "clear", "priority": 10, "positional": True, "location": "Apartment 47 Room", "trigger": "n6_milan_rescue",
     "text": "Martin? Thank God. Roman Kral knows every cellar down here. Let's get to the north service gate before he cuts us off."},

    # --- ROMAN KRAL (46, Human Antagonist — Low Controlled Voice) ---
    {"id": "roman_unknown_voice_01", "path": "Characters/Roman/roman_unknown_voice_01.ogg", "speaker": "Roman", "env": "radio", "priority": 10, "positional": False, "location": "Radio CH-04", "trigger": "n6_radio_warning",
     "text": "You are not walking alone."},
    {"id": "roman_corridor_02", "path": "Characters/Roman/roman_corridor_02.ogg", "speaker": "Roman", "env": "distant", "priority": 8, "positional": True, "location": "Corridor", "trigger": "n6_pursuit",
     "text": "You shouldn't have come down here. Leave those keys and go home."},

    # --- RADIO & TELEPHONE COMMUNICATIONS ---
    {"id": "radio_varga_check_01", "path": "Radio/radio_varga_check_01.ogg", "speaker": "Jozef", "env": "radio", "priority": 9, "positional": False, "location": "VHF Radio", "trigger": "radio_hint",
     "text": "Martin, copy? Check your notebook for the next patrol checkpoint and make sure every door is locked."},
    {"id": "radio_varga_end_b", "path": "Radio/radio_varga_end_b.ogg", "speaker": "Jozef", "env": "radio", "priority": 10, "positional": False, "location": "Outer Service Gate", "trigger": "ending_b",
     "text": "Shift complete. Return to duty."},
    {"id": "radio_dispatch_02", "path": "Radio/radio_dispatch_02.ogg", "speaker": "ResM", "env": "radio", "priority": 8, "positional": False, "location": "VHF Radio", "trigger": "ambient_radio",
     "text": "Novy Brod Dispatch, Channel Four. Loud and clear, Martin. Next status check at oh-two-hundred hours."},
    {"id": "phone_varga_brief_01", "path": "Telephone/phone_varga_brief_01.ogg", "speaker": "Jozef", "env": "phone", "priority": 10, "positional": True, "location": "Security Office Phone", "trigger": "office_phone",
     "text": "Martin, it's Varga. Leave the old service doors alone tonight and stick strictly to your standard patrol."},

    # --- SPATIAL AMBIENT HUMAN SPEECH: RESIDENTS ---
    {"id": "resident_conv_01", "path": "AmbientSpeech/Residents/resident_conv_01.ogg", "speaker": "ResM", "env": "distant", "priority": 3, "positional": True, "location": "Building D Entrance", "trigger": "ambient_resident",
     "text": "Rain again, my boots never dry out in November. Did you grab bread from the grocery store?"},
    {"id": "resident_conv_02", "path": "AmbientSpeech/Residents/resident_conv_02.ogg", "speaker": "ResF", "env": "distant", "priority": 3, "positional": True, "location": "Building A Path", "trigger": "ambient_resident",
     "text": "Good evening, neighbor. That streetlamp by the park is flickering again — I reported it twice already."},
    {"id": "resident_conv_03", "path": "AmbientSpeech/Residents/resident_conv_03.ogg", "speaker": "ResM", "env": "distant", "priority": 3, "positional": True, "location": "Courtyard", "trigger": "ambient_resident",
     "text": "Hey, don't forget to lock the cellar door. Someone left the basement light on all week."},
    {"id": "resident_greeting_04", "path": "AmbientSpeech/Residents/resident_greeting_04.ogg", "speaker": "ResF", "env": "distant", "priority": 3, "positional": True, "location": "Building C Front", "trigger": "ambient_resident",
     "text": "Good evening, officer. Cold damp night out here, isn't it?"},

    # --- SPATIAL AMBIENT HUMAN SPEECH: BEHIND APARTMENT WALLS & WINDOWS ---
    {"id": "apt_muffled_conv_01", "path": "AmbientSpeech/Apartments/apt_muffled_conv_01.ogg", "speaker": "ResM", "env": "wall", "priority": 2, "positional": True, "location": "Building A Windows", "trigger": "ambient_apartment",
     "text": "Turn the television down a little, it's almost eleven and I have an early shift tomorrow."},
    {"id": "apt_muffled_conv_02", "path": "AmbientSpeech/Apartments/apt_muffled_conv_02.ogg", "speaker": "ResF", "env": "wall", "priority": 2, "positional": True, "location": "Building C Stairwell", "trigger": "ambient_apartment",
     "text": "Who is walking up the stairs this late? Check the peephole and make sure they shut the entrance door."},
    {"id": "apt_tv_news_03", "path": "AmbientSpeech/Apartments/apt_tv_news_03.ogg", "speaker": "ResM", "env": "tv", "priority": 2, "positional": True, "location": "Building D Flat 4", "trigger": "ambient_tv",
     "text": "Evening weather report. Heavy fog and cold drizzle will settle across the residential valleys overnight."},
    {"id": "apt_balcony_04", "path": "AmbientSpeech/Apartments/apt_balcony_04.ogg", "speaker": "ResF", "env": "distant", "priority": 2, "positional": True, "location": "Building B Balcony", "trigger": "ambient_apartment",
     "text": "Shut that window, the cold fog and boiler smoke are blowing straight inside."},

    # --- SPATIAL AMBIENT HUMAN SPEECH: SHOPS ---
    {"id": "shop_customer_01", "path": "AmbientSpeech/Shops/shop_customer_01.ogg", "speaker": "Dana", "env": "distant", "priority": 3, "positional": True, "location": "Night Shop", "trigger": "ambient_shop",
     "text": "Here you go, twenty-four crowns. Fresh bread delivery won't arrive until six in the morning."},
    {"id": "shop_closing_02", "path": "AmbientSpeech/Shops/shop_closing_02.ogg", "speaker": "ResF", "env": "distant", "priority": 3, "positional": True, "location": "Newsstand", "trigger": "ambient_shop",
     "text": "Newspapers are stacked up — just counting the cash drawer and rolling down the shutter."},
    {"id": "shop_phone_03", "path": "AmbientSpeech/Shops/shop_phone_03.ogg", "speaker": "Dana", "env": "distant", "priority": 3, "positional": True, "location": "Night Shop", "trigger": "ambient_shop",
     "text": "Yes, I'm locking up now. I'll be home in half an hour once I check in with the night guard."},
]


def synthesize_voice(entry):
    out_path = OUT_ROOT / entry["path"]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    raw_wav = TMP_DIR / f"piper_en_{uuid.uuid4().hex}.wav"

    sp = SPEAKER_DSP[entry["speaker"]]
    p_cmd = [PIPER_EXE, "--model", sp["model"], "--output_file", str(raw_wav)]
    res = subprocess.run(p_cmd, input=entry["text"].encode("utf-8"), capture_output=True)
    if res.returncode != 0 or not raw_wav.exists():
        raise RuntimeError(f"Piper failed on {entry['id']}: {res.stderr.decode('utf-8', 'ignore')}")

    pitch = float(sp["pitch"])
    speed = float(sp["speed"])
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
    norm = np.clip(samples / peak * 0.85, -1.0, 1.0)
    pcm16 = (norm * 32767.0).astype(np.int16)
    with wave.open(str(tmp_w), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(pcm16.tobytes())
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp_w), "-c:a", "libvorbis", "-q:a", "5", str(out_path)],
        check=True,
    )
    tmp_w.unlink(missing_ok=True)


def generate_world_reaction_sfx():
    sr = 22050
    rng = np.random.default_rng(199608)

    t = np.linspace(0, 1.8, int(sr * 1.8), endpoint=False)
    sig = np.zeros_like(t)
    for start in [0.15, 0.72]:
        mask = (t >= start) & (t < start + 0.22)
        lt = t[mask] - start
        env = np.sin(np.pi * lt / 0.22) ** 1.4
        f0 = 260.0 - 95.0 * (lt / 0.22)
        bark = (np.sin(2 * np.pi * np.cumsum(f0) / sr) * 0.6 + np.sin(2 * np.pi * np.cumsum(f0 * 2.1) / sr) * 0.35 + rng.normal(0, 0.22, lt.size)) * env
        sig[mask] += bark
    sig = np.convolve(sig, np.ones(9) / 9.0, mode="same")
    sig[3500:] += sig[:-3500] * 0.28
    _write_env_ogg("Environment/env_dog_bark_distant.ogg", sig, sr)

    t = np.linspace(0, 3.2, int(sr * 3.2), endpoint=False)
    crank = (t < 1.1).astype(np.float32) * (0.5 + 0.5 * np.sin(2 * np.pi * 6.5 * t)) * (np.sin(2 * np.pi * 88 * t) + 0.5 * rng.normal(0, 0.4, t.size))
    idle_env = np.clip((t - 0.95) * 2.5, 0.0, 1.0) * np.clip((3.2 - t) * 1.4, 0.0, 1.0)
    idle = idle_env * (np.sin(2 * np.pi * 46 * t) * 0.7 + np.sin(2 * np.pi * 92 * t) * 0.4 + rng.normal(0, 0.18, t.size))
    car_sig = np.convolve(crank * 0.55 + idle * 0.75, np.ones(11) / 11.0, mode="same")
    _write_env_ogg("Environment/env_car_start_distant.ogg", car_sig, sr)

    t = np.linspace(0, 1.2, int(sr * 1.2), endpoint=False)
    slide = ((t >= 0.05) & (t < 0.65)).astype(np.float32) * rng.normal(0, 0.25, t.size) * np.sin(np.pi * np.clip((t - 0.05) / 0.6, 0, 1))
    thud = np.exp(-np.maximum(0.0, t - 0.68) * 28.0) * (t >= 0.68) * (np.sin(2 * np.pi * 115 * t) * 0.9 + rng.normal(0, 0.3, t.size))
    win_sig = np.convolve(slide + thud, np.ones(7) / 7.0, mode="same")
    _write_env_ogg("Environment/env_window_close.ogg", win_sig, sr)

    t = np.linspace(0, 2.2, int(sr * 2.2), endpoint=False)
    roll = ((t >= 0.1) & (t < 1.65)).astype(np.float32) * (0.6 + 0.4 * np.sin(2 * np.pi * 18.0 * t)) * rng.normal(0, 0.45, t.size)
    slam = np.exp(-np.maximum(0.0, t - 1.68) * 16.0) * (t >= 1.68) * (np.sin(2 * np.pi * 145 * t) + 0.6 * np.sin(2 * np.pi * 310 * t) + rng.normal(0, 0.5, t.size))
    shutter_sig = np.convolve(roll * 0.55 + slam * 0.9, np.ones(5) / 5.0, mode="same")
    _write_env_ogg("Environment/env_shutter_close.ogg", shutter_sig, sr)

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
            "language": "en",
            "text": item["text"],
            "location": item["location"],
            "trigger": item["trigger"],
            "priority": item["priority"],
            "positional": item["positional"],
        })
    generate_world_reaction_sfx()
    reg_path = OUT_ROOT / "voice_registry.json"
    reg_path.write_text(json.dumps({"language": "en", "voices": registry}, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"GENERATED_ENGLISH_VOICES={len(registry)} REGISTRY={reg_path}")


if __name__ == "__main__":
    main()
