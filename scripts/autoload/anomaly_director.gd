extends Node

signal anomaly_triggered(anomaly_id: String)
signal anomaly_resolved(anomaly_id: String, action: String, outcome_text: String)

var active_anomaly_ids: Array[String] = []
var resolved_anomalies: Dictionary = {}

const ANOMALIES: Array[Dictionary] = [
	{
		"id": "ANOM_01",
		"title_sk": "Trináste okno",
		"title_en": "The Thirteenth Window",
		"category": "Architectural",
		"min_night": 1,
		"cctv_only": false,
		"zone": "Courtyard East Wall",
		"description": "A thirteenth dark window manifests on the second floor where solid damp brick existed on the blueprint.",
		"distortion_investigate": 12.0,
		"distortion_contain": -3.0,
		"codex_lore": "Jozef marked twelve east windows in chalk. On nights when K-4 wakes, the thirteenth looks back."
	},
	{
		"id": "ANOM_02",
		"title_sk": "Predĺžená pavlač",
		"title_en": "Endless Gallery",
		"category": "Architectural",
		"min_night": 2,
		"cctv_only": false,
		"zone": "2nd-Floor Gallery",
		"description": "The timber balcony stretches endlessly into fog until you kill your halogen beam and step backward.",
		"distortion_investigate": 14.0,
		"distortion_contain": -2.0,
		"codex_lore": "Looking straight ahead feeds the loop; walking blind restores the historic perimeter."
	},
	{
		"id": "ANOM_03",
		"title_sk": "Nesprávne dvere",
		"title_en": "Mismatched Threshold",
		"category": "Architectural",
		"min_night": 3,
		"cctv_only": false,
		"zone": "Flat 9 Door",
		"description": "Opening Flat 9's apartment door reveals the steam-choked concrete descent into the Boiler Room instead of a flat.",
		"distortion_investigate": 15.0,
		"distortion_contain": 0.0,
		"codex_lore": "Doorways inside Block 14 lose spatial ownership after 02:14."
	},
	{
		"id": "ANOM_04",
		"title_sk": "Chýbajúci schod",
		"title_en": "Ghost Step",
		"category": "Architectural",
		"min_night": 1,
		"cctv_only": false,
		"zone": "Attic Stairwell",
		"description": "An extra 14th stone step forms at the stair landing; stepping on it sounds like ankle-deep cold water.",
		"distortion_investigate": 8.0,
		"distortion_contain": -2.0,
		"codex_lore": "Masons counted thirteen treads in 1898. The fourteenth is wet with cellar rain."
	},
	{
		"id": "ANOM_05",
		"title_sk": "Zazděná brána",
		"title_en": "Bricked Exit",
		"category": "Architectural",
		"min_night": 4,
		"cctv_only": false,
		"zone": "Main Carriage Gate",
		"description": "For twenty seconds after 03:00, the wrought-iron gate becomes seamless damp plaster covered in 1953 chalk marks.",
		"distortion_investigate": 16.0,
		"distortion_contain": 2.0,
		"codex_lore": "The block insists nobody leaves before the dawn tape finishes recording."
	},
	{
		"id": "ANOM_06",
		"title_sk": "Zrkadlový byt",
		"title_en": "Mirrored Flat 7",
		"category": "Architectural",
		"min_night": 2,
		"cctv_only": false,
		"zone": "Flat 7",
		"description": "Furniture sits mirrored against the opposite plaster wall while the bathroom mirror reflects an open corridor behind a locked door.",
		"distortion_investigate": 12.0,
		"distortion_contain": -4.0,
		"codex_lore": "Last vacated in 1991. Someone left a wet footprint inside the cracked mirror frame."
	},
	{
		"id": "ANOM_07",
		"title_sk": "Čierna voda",
		"title_en": "Black Well Water",
		"category": "Architectural",
		"min_night": 1,
		"cctv_only": false,
		"zone": "Flat 7 Sink & Courtyard Well",
		"description": "Rusty pipes and dry well stones ooze thick, ink-black liquid that drifts upward like soot in fog.",
		"distortion_investigate": 10.0,
		"distortion_contain": -3.0,
		"codex_lore": "Municipal water was shut off to Flat 7 in August. What runs from the faucet smells of iron and ozone."
	},
	{
		"id": "ANOM_08",
		"title_sk": "Dvojník pri vrátnici",
		"title_en": "Booth Doppelgänger",
		"category": "CCTV-Only",
		"min_night": 1,
		"cctv_only": true,
		"zone": "CAM-03 (Booth Exterior)",
		"description": "Camera 3 captures a guard in Marek's exact SBS uniform staring silently into the booth window—invisible to the naked eye.",
		"distortion_investigate": 11.0,
		"distortion_contain": -2.0,
		"codex_lore": "Do not open the booth latch while he stands on CAM-03. Wait for the static cut."
	},
	{
		"id": "ANOM_09",
		"title_sk": "Denné vysielanie 1953",
		"title_en": "1953 Daylight Feed",
		"category": "CCTV-Only",
		"min_night": 3,
		"cctv_only": true,
		"zone": "CAM-02 (Gallery)",
		"description": "Camera 2 broadcasts bright overcast 1953 afternoon footage of men in wool coats carrying steel cylinders downstairs.",
		"distortion_investigate": 14.0,
		"distortion_contain": -3.0,
		"codex_lore": "Kovac blames 'cable crosstalk'. The coaxial lines inside Block 14 were never connected to town cable."
	},
	{
		"id": "ANOM_10",
		"title_sk": "Prázdna šachta",
		"title_en": "Open Well Lid",
		"category": "CCTV-Only",
		"min_night": 2,
		"cctv_only": true,
		"zone": "CAM-01 (Courtyard)",
		"description": "On CAM-01 the heavy concrete well cap slides sideways while pale static hands grip the brick rim.",
		"distortion_investigate": 12.0,
		"distortion_contain": -2.0,
		"codex_lore": "Stepping outside shows the brass padlock untouched and cold."
	},
	{
		"id": "ANOM_11",
		"title_sk": "Škodovka bez šoféra",
		"title_en": "Phantom Favorit Lights",
		"category": "CCTV-Only",
		"min_night": 2,
		"cctv_only": true,
		"zone": "CAM-01 (Courtyard)",
		"description": "The parked Škoda Favorit flashes its headlights in rhythmic Morse bursts (`50.4`) visible only on black-and-white CCTV.",
		"distortion_investigate": 10.0,
		"distortion_contain": -1.0,
		"codex_lore": "Its battery was removed last winter."
	},
	{
		"id": "ANOM_12",
		"title_sk": "Postava na zábradlí",
		"title_en": "Gallery Rail Watcher",
		"category": "CCTV-Only",
		"min_night": 3,
		"cctv_only": true,
		"zone": "CAM-02 (2F Gallery)",
		"description": "An impossibly tall, narrow figure leans directly over the 2nd-floor gallery balustrade toward Camera 2.",
		"distortion_investigate": 13.0,
		"distortion_contain": -2.0,
		"codex_lore": "Measured against the post height, the figure exceeds two and a half meters."
	},
	{
		"id": "ANOM_13",
		"title_sk": "Dátum na páske",
		"title_en": "Corrupted VCR Timestamp",
		"category": "CCTV-Only",
		"min_night": 4,
		"cctv_only": true,
		"zone": "CAM-04 (Arcade Passage)",
		"description": "Camera 4's date display flickers violently between 1995 and 1953 as a figure drags a heavy canvas sack past the Watchmaker's.",
		"distortion_investigate": 15.0,
		"distortion_contain": 0.0,
		"codex_lore": "A duplicate of Elena's field bag appears in three separate frames across forty years."
	},
	{
		"id": "ANOM_14",
		"title_sk": "Mŕtva linka",
		"title_en": "Dead Payphone Ring",
		"category": "Acoustic",
		"min_night": 3,
		"cctv_only": false,
		"zone": "Arcade Payphone",
		"description": "The disconnected wall payphone rings at 03:00; lifting the receiver plays Elena Kralova's warning over a 1953 reel tape.",
		"distortion_investigate": 16.0,
		"distortion_contain": -4.0,
		"codex_lore": "The copper drop line was cut inside the junction box five years ago."
	},
	{
		"id": "ANOM_15",
		"title_sk": "Spätný chod hodín",
		"title_en": "Backward Watchmaker Clocks",
		"category": "Acoustic",
		"min_night": 2,
		"cctv_only": false,
		"zone": "Watchmaker's (Arcade)",
		"description": "Every mechanical timepiece behind the Watchmaker's grille spins counterclockwise in harsh metallic sync until 02:14.",
		"distortion_investigate": 11.0,
		"distortion_contain": -3.0,
		"codex_lore": "Only the grandfather clock inside retains Elena's hidden camera film untouched."
	},
	{
		"id": "ANOM_16",
		"title_sk": "Mŕtvy kanál v bytoch",
		"title_en": "Vacant Flat TV Bleed",
		"category": "Acoustic",
		"min_night": 3,
		"cctv_only": false,
		"zone": "Gallery Flats",
		"description": "Locked, empty flats glow cold Channel-3 blue and roar with 50Hz white noise despite corridor breakers pulled down.",
		"distortion_investigate": 14.0,
		"distortion_contain": -5.0,
		"codex_lore": "The rooftop STA amplifier feeds power downward rather than receiving from town."
	},
	{
		"id": "ANOM_17",
		"title_sk": "Ihličková tlačiareň",
		"title_en": "1954 Eviction Printout",
		"category": "Acoustic",
		"min_night": 2,
		"cctv_only": false,
		"zone": "Notary Office (Arcade)",
		"description": "An unplugged dot-matrix printer clatters furiously in the dark, printing eviction decrees signed in 1954 and 1995 ending with Marek's name.",
		"distortion_investigate": 12.0,
		"distortion_contain": -3.0,
		"codex_lore": "Eastern Invest Ltd. bought more than brick and title deeds."
	},
	{
		"id": "ANOM_18",
		"title_sk": "Frekvencia 50.4 Hz",
		"title_en": "Hidden Radio Broadcast",
		"category": "Acoustic",
		"min_night": 2,
		"cctv_only": false,
		"zone": "Block Radios (x5)",
		"description": "Transistor radios hidden around Block 14 hum distorted 1950s radio plays interrupted by whispered resident names.",
		"distortion_investigate": 10.0,
		"distortion_contain": -4.0,
		"codex_lore": "Tuning all five radios locks the player's pulse into K-4's standing wave."
	},
	{
		"id": "ANOM_19",
		"title_sk": "Ozvena pečiatky",
		"title_en": "Delayed Clock Stamp",
		"category": "Acoustic",
		"min_night": 3,
		"cctv_only": false,
		"zone": "Watchman's Clocks",
		"description": "Punching a Watchman's Clock echoes three seconds later with a second brass stamp from an empty archway behind you.",
		"distortion_investigate": 9.0,
		"distortion_contain": 0.0,
		"codex_lore": "Someone else is still finishing Jozef's October route."
	},
	{
		"id": "ANOM_20",
		"title_sk": "Telefón zo dňa 00",
		"title_en": "Self-Dialing Booth Phone",
		"category": "Acoustic",
		"min_night": 4,
		"cctv_only": false,
		"zone": "Guard Booth Desk",
		"description": "The booth rotary phone rings sharply; lifting the handset replays your own voice logging checkpoints from two hours earlier.",
		"distortion_investigate": 13.0,
		"distortion_contain": -2.0,
		"codex_lore": "Every word spoken near the courtyard well enters the bunker archive."
	},
	{
		"id": "ANOM_21",
		"title_sk": "Sneh do neba",
		"title_en": "Upward Snowfall",
		"category": "Time-Slip",
		"min_night": 5,
		"cctv_only": false,
		"zone": "Inner Courtyard",
		"description": "Cold grey ash-snow detaches from wet cobblestones and drifts steadily upward into the dark sky.",
		"distortion_investigate": 15.0,
		"distortion_contain": 2.0,
		"codex_lore": "November 17 inside Block 14 flows opposite to the bells outside the iron gate."
	},
	{
		"id": "ANOM_22",
		"title_sk": "Bzučiaca lampa",
		"title_en": "Staring Sodium Lamp",
		"category": "Time-Slip",
		"min_night": 1,
		"cctv_only": false,
		"zone": "Courtyard Center",
		"description": "The central sodium streetlamp cuts black the instant you stare directly at its bulb, humming back on only in peripheral vision.",
		"distortion_investigate": 7.0,
		"distortion_contain": -2.0,
		"codex_lore": "Old sodium arcs react poorly when K-4 draws current from the gate transformer."
	},
	{
		"id": "ANOM_23",
		"title_sk": "Zaschnutá krv z 1953",
		"title_en": "Weeping Plaster Names",
		"category": "Time-Slip",
		"min_night": 4,
		"cctv_only": false,
		"zone": "Bunker K-4 Corridor",
		"description": "Sweating concrete arches bleed rust-colored streaks spelling archived secret police file numbers (`K-4/112`, `K-4/118`).",
		"distortion_investigate": 14.0,
		"distortion_contain": -2.0,
		"codex_lore": "Lime mortar remembers every dossier burned against the vault bricks."
	},
	{
		"id": "ANOM_24",
		"title_sk": "Anténny oblúk",
		"title_en": "STA Corona Discharge",
		"category": "Time-Slip",
		"min_night": 3,
		"cctv_only": false,
		"zone": "Rooftop STA Mast",
		"description": "The shared roof television mast crackles with cold blue static arcs aligned magnetically with the medieval well below.",
		"distortion_investigate": 13.0,
		"distortion_contain": -5.0,
		"codex_lore": "Built as a passive community aerial in 1961 — wired secretly into a 1953 basement coil."
	},
	{
		"id": "ANOM_25",
		"title_sk": "Cudzí dych v kotolni",
		"title_en": "Freezing Steam",
		"category": "Time-Slip",
		"min_night": 4,
		"cctv_only": false,
		"zone": "Boiler Room",
		"description": "Scalding furnace gauges read 140°C while pressurized steam pipes cake over in crystalline frost.",
		"distortion_investigate": 12.0,
		"distortion_contain": -3.0,
		"codex_lore": "Thermal energy is drained straight into the subterranean vault."
	},
	{
		"id": "ANOM_26",
		"title_sk": "Okno do roku 1953",
		"title_en": "1953 Time-Slip Aperture",
		"category": "Time-Slip",
		"min_night": 6,
		"cctv_only": false,
		"zone": "Courtyard / Bunker K-4",
		"description": "A total phase reversal peels back 42 years of decay, revealing Block 14 on November 17, 1953.",
		"distortion_investigate": 20.0,
		"distortion_contain": -10.0,
		"codex_lore": "Only Tape 00 replayed through the STA mast forces the broadcast back to its opening frame."
	},
	{
		"id": "ANOM_27",
		"title_sk": "Tieňový nájomník",
		"title_en": "Shadow Tenant",
		"category": "Entity",
		"min_night": 3,
		"cctv_only": false,
		"zone": "2F Gallery & Courtyard",
		"description": "Tall, interlaced VHS silhouettes stand motionless along the gallery, freezing under direct halogen beam and surging static near.",
		"distortion_investigate": 16.0,
		"distortion_contain": -4.0,
		"codex_lore": "Keep your beam steady or kill your light and step softly past."
	},
	{
		"id": "ANOM_28",
		"title_sk": "Kurič",
		"title_en": "The Boiler Man",
		"category": "Entity",
		"min_night": 4,
		"cctv_only": false,
		"zone": "Boiler Room",
		"description": "A soot-blackened distortion patrols the cellar steam arches, lunging toward bright beams and sprinting boots.",
		"distortion_investigate": 18.0,
		"distortion_contain": -5.0,
		"codex_lore": "Crouch and dim your flashlight behind the coal bunker while bleeding the valve."
	},
	{
		"id": "ANOM_29",
		"title_sk": "Strážca Jozef — Projekcia",
		"title_en": "Jozef's Patrol Echo",
		"category": "Entity",
		"min_night": 2,
		"cctv_only": false,
		"zone": "Opposite Gallery",
		"description": "A half-transparent VHS phantom of former guard Jozef Bartos walks twelve paces ahead of you across the balcony.",
		"distortion_investigate": 13.0,
		"distortion_contain": 0.0,
		"codex_lore": "His ghost repeats the night Kovac locked him behind the Red Door."
	},
	{
		"id": "ANOM_30",
		"title_sk": "Ruka z kanála",
		"title_en": "Well Grate Reacher",
		"category": "Entity",
		"min_night": 4,
		"cctv_only": false,
		"zone": "Medieval Well",
		"description": "Pale static fingers press silently against the iron well grate whenever signal distortion climbs above 60%.",
		"distortion_investigate": 15.0,
		"distortion_contain": -4.0,
		"codex_lore": "Do not kneel beside the stones while Channel 3 hums underfoot."
	},
	{
		"id": "ANOM_31",
		"title_sk": "Svedok bez tváre",
		"title_en": "Faceless Flat 4 Watcher",
		"category": "Entity",
		"min_night": 5,
		"cctv_only": false,
		"zone": "Flat 4 Threshold",
		"description": "A blurred grey-coat figure stands outside Mrs. Maria's chained apartment door without knocking or breathing.",
		"distortion_investigate": 16.0,
		"distortion_contain": -4.0,
		"codex_lore": "Whether protector or collector, it leaves once Maria passes safely through the alley."
	},
	{
		"id": "ANOM_32",
		"title_sk": "Rezonátor K-4",
		"title_en": "Device K-4 Core",
		"category": "Entity",
		"min_night": 4,
		"cctv_only": false,
		"zone": "Bunker K-4",
		"description": "The living 1953 secret police electromagnetic coil mounted over the subterranean well, draining color into cold phosphor monochrome.",
		"distortion_investigate": 20.0,
		"distortion_contain": -8.0,
		"codex_lore": "Built to preserve confessions indefinitely. Now Block 14 itself is its magnetic tape."
	}
]


func get_all_anomalies() -> Array[Dictionary]:
	return ANOMALIES


func get_anomaly_by_id(anomaly_id: String) -> Dictionary:
	for entry: Dictionary in ANOMALIES:
		if str(entry.get("id", "")) == anomaly_id:
			return entry
	return {}


func prepare_night_anomalies(night: int) -> void:
	active_anomaly_ids.clear()
	resolved_anomalies.clear()

	# Scripted story anomalies guaranteed per night
	var scripted: Dictionary = {
		1: ["ANOM_01", "ANOM_04", "ANOM_07", "ANOM_08", "ANOM_22"],
		2: ["ANOM_02", "ANOM_06", "ANOM_10", "ANOM_11", "ANOM_15", "ANOM_17", "ANOM_18", "ANOM_29"],
		3: ["ANOM_03", "ANOM_09", "ANOM_12", "ANOM_14", "ANOM_16", "ANOM_19", "ANOM_24", "ANOM_27"],
		4: ["ANOM_05", "ANOM_13", "ANOM_20", "ANOM_23", "ANOM_25", "ANOM_28", "ANOM_30", "ANOM_32"],
		5: ["ANOM_01", "ANOM_05", "ANOM_14", "ANOM_16", "ANOM_21", "ANOM_27", "ANOM_31", "ANOM_32"],
		6: ["ANOM_26", "ANOM_32", "ANOM_09", "ANOM_21"]
	}

	var base_list: Array = scripted.get(night, ["ANOM_01", "ANOM_08"])
	for aid in base_list:
		active_anomaly_ids.append(str(aid))

	# Add 2-3 randomized bonus eligible anomalies for replayability across runs
	var candidates: Array[String] = []
	for entry: Dictionary in ANOMALIES:
		var aid: String = str(entry.get("id", ""))
		var min_n: int = int(entry.get("min_night", 1))
		if min_n <= night and not (aid in active_anomaly_ids):
			candidates.append(aid)

	candidates.shuffle()
	var bonus_count: int = mini(3, candidates.size())
	for i in range(bonus_count):
		active_anomaly_ids.append(candidates[i])


func is_active(anomaly_id: String) -> bool:
	return anomaly_id in active_anomaly_ids


func discover_anomaly(anomaly_id: String) -> void:
	if not anomaly_id in GameState.discovered_anomalies:
		GameState.discovered_anomalies.append(anomaly_id)
		GameState.save_meta()
	if not anomaly_id in GameState.logged_anomalies_this_night:
		GameState.logged_anomalies_this_night.append(anomaly_id)

	var entry: Dictionary = get_anomaly_by_id(anomaly_id)
	if bool(entry.get("cctv_only", false)):
		GameState.cctv_anomalies_logged += 1

	if anomaly_id == "ANOM_01":
		AchievementManager.unlock("ACH_13_13TH_WINDOW")
	if anomaly_id == "ANOM_14":
		AchievementManager.unlock("ACH_14_DEAD_LINE")

	AchievementManager.check_anomaly_achievements()


func handle_anomaly_response(anomaly_id: String, action: String) -> String:
	var entry: Dictionary = get_anomaly_by_id(anomaly_id)
	if entry.is_empty():
		return "Nothing unusual detected."

	discover_anomaly(anomaly_id)
	resolved_anomalies[anomaly_id] = action

	var title_en: String = str(entry.get("title_en", anomaly_id))
	var outcome: String = ""

	match action:
		"log":
			GameState.adjust_distortion(2.0)
			outcome = "Logged [%s] in the Guard Logbook and reported to Kovac." % title_en
		"contain":
			var delta_c: float = float(entry.get("distortion_contain", -3.0))
			GameState.adjust_distortion(delta_c)
			outcome = "Contained [%s]. Signal noise settled slightly." % title_en
		"investigate":
			var delta_i: float = float(entry.get("distortion_investigate", 12.0))
			GameState.adjust_distortion(delta_i)
			outcome = "Stepped closer to [%s]. Static surged (%+.0f%% Distortion)." % [title_en, delta_i]
		"ignore":
			GameState.adjust_distortion(-1.0)
			outcome = "Looked away from [%s] — 'I saw nothing.'" % title_en
		_:
			outcome = "Observed [%s]." % title_en

	emit_signal("anomaly_resolved", anomaly_id, action, outcome)
	GameState.save_meta()
	return outcome
