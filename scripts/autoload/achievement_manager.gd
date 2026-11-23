extends Node

signal achievement_unlocked(data: Dictionary)

const ACHIEVEMENTS: Array[Dictionary] = [
	# Progression & Story (6)
	{"id": "ACH_01_FIRST_STAMP", "title_sk": "Prvá pečiatka", "title_en": "First Stamp", "category": "Story", "description": "Complete Night 1 (First Shift)."},
	{"id": "ACH_02_BLACK_MARKET", "title_sk": "Čierny trh", "title_en": "Black Market", "category": "Story", "description": "Witness or log the Night 2 01:00 delivery."},
	{"id": "ACH_03_ON_THE_ROOF", "title_sk": "Na streche", "title_en": "On the Roof", "category": "Story", "description": "Reach the STA Rooftop Antenna Mast on Night 3."},
	{"id": "ACH_04_RED_DOOR", "title_sk": "Za červenými dverami", "title_en": "Behind the Red Door", "category": "Story", "description": "Unlock and enter Bunker K-4 on Night 4."},
	{"id": "ACH_05_WITNESS", "title_sk": "Svedok", "title_en": "The Witness", "category": "Story", "description": "Recover all 3 pieces of Elena Kralova's evidence."},
	{"id": "ACH_06_NOV_17", "title_sk": "17. november", "title_en": "November 17", "category": "Story", "description": "Survive Night 5 until 06:00."},

	# Endings (6)
	{"id": "ACH_07_ENDING_A", "title_sk": "Nevidel som nič", "title_en": "Ending A: I Saw Nothing", "category": "Ending", "description": "Unlock Ending A."},
	{"id": "ACH_08_ENDING_B", "title_sk": "Ranné správy", "title_en": "Ending B: Morning News", "category": "Ending", "description": "Unlock Ending B."},
	{"id": "ACH_09_ENDING_C", "title_sk": "Vypnutý prúd", "title_en": "Ending C: Power Cut", "category": "Ending", "description": "Unlock Ending C."},
	{"id": "ACH_10_ENDING_D", "title_sk": "Stála zmena", "title_en": "Ending D: The Permanent Shift", "category": "Ending", "description": "Unlock Ending D."},
	{"id": "ACH_11_ENDING_E", "title_sk": "Krvavý dvor", "title_en": "Ending E: Bloody Courtyard", "category": "Ending", "description": "Unlock Ending E."},
	{"id": "ACH_12_ENDING_F", "title_sk": "Páska 00: Archív", "title_en": "Ending F: Tape 00 Archive", "category": "Ending", "description": "Unlock Secret Ending F."},

	# Anomaly Hunting (5)
	{"id": "ACH_13_13TH_WINDOW", "title_sk": "Trináste okno", "title_en": "The Thirteenth Window", "category": "Anomaly", "description": "Discover ANOM_01 on the east courtyard wall."},
	{"id": "ACH_14_DEAD_LINE", "title_sk": "Mŕtva linka", "title_en": "Dead Line", "category": "Anomaly", "description": "Answer the unplugged Arcade Passage payphone."},
	{"id": "ACH_15_ARCHIVIST", "title_sk": "Archivár", "title_en": "Archivist", "category": "Anomaly", "description": "Discover 15 anomalies in the Anomaly Archive."},
	{"id": "ACH_16_BLIND_SPOT", "title_sk": "Slepá škvrna", "title_en": "Blind Spot", "category": "Anomaly", "description": "Log 5 CCTV-only anomalies via the booth monitor."},
	{"id": "ACH_17_FULL_CATALOG", "title_sk": "Kompletný katalóg", "title_en": "Complete Catalog", "category": "Anomaly", "description": "Discover all 32 anomalies in the Anomaly Archive."},

	# Moral & Character Paths (6)
	{"id": "ACH_18_GOOD_NEIGHBOR", "title_sk": "Dobrý sused", "title_en": "Good Neighbor", "category": "Moral", "description": "Deliver Mrs. Maria's medicine and evacuate her safely."},
	{"id": "ACH_19_MOLE_DEAL", "title_sk": "Dohoda s Krtkom", "title_en": "Deal with the Mole", "category": "Moral", "description": "Trade fairly with Milan 'The Mole' and preserve his alley route."},
	{"id": "ACH_20_MODEL_EMPLOYEE", "title_sk": "Vzorový zamestnanec", "title_en": "Model Employee", "category": "Moral", "description": "Never falsify a single Guard Logbook entry across 5 nights."},
	{"id": "ACH_21_DOUBLE_GAME", "title_sk": "Dvojitá hra", "title_en": "Double Game", "category": "Moral", "description": "Falsify all 5 Dawn Reports."},
	{"id": "ACH_22_JOZEF_LEGACY", "title_sk": "Jozefov odkaz", "title_en": "Jozef's Legacy", "category": "Moral", "description": "Collect all 8 torn logbook pages and 4 archival tapes."},
	{"id": "ACH_23_KEYMASTER", "title_sk": "Kľúčnik", "title_en": "Keymaster", "category": "Moral", "description": "Unlock Flat 7, Watchmaker's, Notary Office, Attic, and Bunker K-4."},

	# Skill & Mastery (5)
	{"id": "ACH_24_POWER_SAVER", "title_sk": "Šetrenie prúdom", "title_en": "Power Saver", "category": "Skill", "description": "Finish any night without swapping flashlight batteries."},
	{"id": "ACH_25_GHOST_IN_YARD", "title_sk": "Duch v dvore", "title_en": "Ghost in the Yard", "category": "Skill", "description": "Finish Night 5 without being spotted by Brano, Igor, or Hruska."},
	{"id": "ACH_26_CLOCKWORK", "title_sk": "Presný ako hodinky", "title_en": "Like Clockwork", "category": "Skill", "description": "Stamp every Watchman's Clock cleanly across the shift."},
	{"id": "ACH_27_NO_MERCY", "title_sk": "Bez zľutovania", "title_en": "No Mercy", "category": "Skill", "description": "Complete Hardcore Mode (No Mercy)."},
	{"id": "ACH_28_PLATINUM", "title_sk": "Platinová strážna kniha", "title_en": "Platinum Logbook", "category": "Mastery", "description": "Unlock all other 27 achievements."}
]


func get_all_achievements() -> Array[Dictionary]:
	return ACHIEVEMENTS


func get_achievement_by_id(ach_id: String) -> Dictionary:
	for a: Dictionary in ACHIEVEMENTS:
		if str(a.get("id", "")) == ach_id:
			return a
	return {}


func is_unlocked(ach_id: String) -> bool:
	return ach_id in GameState.unlocked_achievements


func unlock(ach_id: String) -> void:
	if ach_id in GameState.unlocked_achievements:
		return
	var entry: Dictionary = get_achievement_by_id(ach_id)
	if entry.is_empty():
		return

	GameState.unlocked_achievements.append(ach_id)
	GameState.save_meta()
	emit_signal("achievement_unlocked", entry)

	# Auto-check Platinum mastery once all other 27 achievements are unlocked
	if ach_id != "ACH_28_PLATINUM":
		check_platinum()


func check_platinum() -> void:
	if is_unlocked("ACH_28_PLATINUM"):
		return
	for a: Dictionary in ACHIEVEMENTS:
		var aid: String = str(a.get("id", ""))
		if aid != "ACH_28_PLATINUM" and not is_unlocked(aid):
			return
	unlock("ACH_28_PLATINUM")


func check_night_completion(night: int) -> void:
	if night == 1:
		unlock("ACH_01_FIRST_STAMP")
	elif night == 5:
		unlock("ACH_06_NOV_17")
		if int(GameState.story_flags.get("falsified_logs_count", 0)) == 0 and int(GameState.story_flags.get("truthful_logs_count", 0)) >= 5:
			unlock("ACH_20_MODEL_EMPLOYEE")
		if int(GameState.story_flags.get("falsified_logs_count", 0)) >= 5:
			unlock("ACH_21_DOUBLE_GAME")
		if not GameState.player_spotted:
			unlock("ACH_25_GHOST_IN_YARD")
		if bool(GameState.story_flags.get("all_clocks_on_time", false)):
			unlock("ACH_26_CLOCKWORK")
		if GameState.hardcore_mode:
			unlock("ACH_27_NO_MERCY")


func check_ending_achievements(ending_id: String) -> void:
	var map_ending: Dictionary = {
		"A": "ACH_07_ENDING_A",
		"B": "ACH_08_ENDING_B",
		"C": "ACH_09_ENDING_C",
		"D": "ACH_10_ENDING_D",
		"E": "ACH_11_ENDING_E",
		"F": "ACH_12_ENDING_F"
	}
	if map_ending.has(ending_id):
		unlock(str(map_ending[ending_id]))


func check_anomaly_achievements() -> void:
	if GameState.discovered_anomalies.size() >= 15:
		unlock("ACH_15_ARCHIVIST")
	if GameState.cctv_anomalies_logged >= 5:
		unlock("ACH_16_BLIND_SPOT")
	if GameState.discovered_anomalies.size() >= 32:
		unlock("ACH_17_FULL_CATALOG")


func check_collectible_achievements() -> void:
	if GameState.collected_pages.size() >= 8 and GameState.collected_tapes.size() >= 4:
		unlock("ACH_22_JOZEF_LEGACY")
	if bool(GameState.story_flags.get("helped_maria", false)) and bool(GameState.story_flags.get("evacuated_maria", false)):
		unlock("ACH_18_GOOD_NEIGHBOR")
