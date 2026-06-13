extends Node

const SAVE_PATH = "user://save_data.json"
const SAVE_TMP_PATH = "user://save_data.json.tmp"
const SAVE_VERSION = 2

var save_data: Dictionary = {
	"version": SAVE_VERSION,
	"high_score": 0,
	"unlocked_characters": ["manni"],
	"best_wave": 0,
	"total_kills": 0,
	"endless_leaderboard": [],
	"tutorial_seen": false,
	"seen_enemy_lore": [],
	"unlocked_maps": [],
	"unlocked_weapons": [],
	"pause_count": 0,
	"settings": {
		"sfx_volume": 1.0,
		"music_volume": 0.8,
		# Bus-Lautstaerken aus dem Options-Sound-Panel (Keys muessen hier
		# stehen, sonst verwirft der Settings-Merge sie beim Laden)
		"master_vol": 1.0,
		"music_vol": 0.8,
		"sfx_vol": 1.0,
		"music_enabled": true,
		"proj_sfx_enabled": true,
		"fullscreen": false,
		"language": "de",
		"screen_shake": true,
		"particles": "high",
		"vsync": true,
		"show_fps": false,
		"controller_deadzone": 0.15,
	}
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	# Atomic save: erst in .tmp schreiben, dann umbenennen.
	# Verhindert korrupte JSON wenn das Spiel während des Writes crasht.
	save_data["version"] = SAVE_VERSION
	var file = FileAccess.open(SAVE_TMP_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(SAVE_TMP_PATH),
			ProjectSettings.globalize_path(SAVE_PATH)
		)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json_text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(json_text) != OK:
		# Corrupt JSON: Defaults beibehalten, alte Datei nicht ueberschreiben
		push_warning("SaveManager: save_data.json corrupt, using defaults")
		return
	var loaded = json.get_data()
	if not (loaded is Dictionary):
		push_warning("SaveManager: save_data.json is not a dictionary, using defaults")
		return
	# Top-level merge: uebernimmt geladene Werte, behaelt neue Default-Keys.
	# WICHTIG: JSON liefert Zahlen immer als float, die Defaults sind int -
	# ohne die int/float-Toleranz gingen high_score, best_wave, total_kills
	# und pause_count bei jedem Spielstart verloren (Audit Run #11, P0).
	for key in save_data:
		if not loaded.has(key):
			continue
		var lv = loaded[key]
		if typeof(lv) == typeof(save_data[key]):
			save_data[key] = lv
		elif save_data[key] is int and lv is float:
			save_data[key] = int(lv)
		elif save_data[key] is float and lv is int:
			save_data[key] = float(lv)
	# Deep merge fuer "settings": neue Setting-Keys behalten ihren Default
	if loaded.has("settings") and loaded["settings"] is Dictionary:
		for skey in save_data["settings"]:
			if loaded["settings"].has(skey):
				save_data["settings"][skey] = loaded["settings"][skey]
	# Save-Versioning: alte Saves migrieren statt zu crashen
	var loaded_version: int = int(loaded.get("version", 1))
	if loaded_version < SAVE_VERSION:
		_migrate_save(loaded_version)

func _migrate_save(from_version: int) -> void:
	# Fehlende Keys mit Defaults setzen. save_data hält bereits die Defaults
	# aus der Initialisierung; die obige Merge-Logik hat nur existierende
	# Keys überschrieben. Wir stellen sicher, dass die Datei nach Migration
	# in der neuen Version geschrieben wird.
	save_data["version"] = SAVE_VERSION
	save_game()

func update_run_results() -> void:
	var gm = GameManager
	if gm.score > save_data["high_score"]:
		save_data["high_score"] = gm.score
	if gm.current_wave > save_data["best_wave"]:
		save_data["best_wave"] = gm.current_wave
	# Nur das Delta seit dem letzten Aufruf addieren - update_run_results()
	# laeuft mehrfach pro Run (jede Welle + Tod), das kumulative run_stats["kills"]
	# wuerde sonst quadratisch mehrfach gezaehlt (Audit Run #11, P1)
	var run_kills: int = int(gm.run_stats.get("kills", 0))
	var credited: int = int(gm.run_stats.get("kills_credited", 0))
	save_data["total_kills"] += maxi(0, run_kills - credited)
	gm.run_stats["kills_credited"] = run_kills

	# Unlock characters based on waves cleared
	_check_unlocks()
	# Signature-Waffe freischalten: Story-Sieg auf Drink Fight Die! (Stufe 3)
	# oder hoeher. Gilt fuer den/die im Run gespielten Charakter(e).
	if bool(gm.run_stats.get("won", false)) and not gm.endless_mode and int(gm.difficulty) >= 3:
		var run_chars: Array = []
		if gm.player_count >= 2:
			run_chars = [gm.selected_characters[0], gm.selected_characters[1]]
		else:
			run_chars = [gm.selected_character]
		for cid in run_chars:
			if cid != "" and cid not in save_data["unlocked_weapons"]:
				save_data["unlocked_weapons"].append(cid)
				gm.run_stats["weapon_just_unlocked"] = cid
	# Bonus fuer den schwersten Grad (Bolognese Bloodbath, Stufe 4):
	# Bonus-Charakter Toxo und die Giftstadt-Map freischalten.
	if bool(gm.run_stats.get("won", false)) and not gm.endless_mode and int(gm.difficulty) >= 4:
		if "toxo" not in save_data["unlocked_characters"]:
			save_data["unlocked_characters"].append("toxo")
			gm.run_stats["bonus_unlocked"] = "toxo"
		if "giftstadt" not in save_data.get("unlocked_maps", []):
			save_data["unlocked_maps"].append("giftstadt")
	save_game()

func _check_unlocks() -> void:
	var best = save_data["best_wave"]
	if best >= 3 and "shouter" not in save_data["unlocked_characters"]:
		save_data["unlocked_characters"].append("shouter")
	if best >= 5 and "dreads" not in save_data["unlocked_characters"]:
		save_data["unlocked_characters"].append("dreads")
	if best >= 7 and "riff_slicer" not in save_data["unlocked_characters"]:
		save_data["unlocked_characters"].append("riff_slicer")
	if best >= 10 and "distortion" not in save_data["unlocked_characters"]:
		save_data["unlocked_characters"].append("distortion")
	if best >= 12 and "bassist" not in save_data["unlocked_characters"]:
		save_data["unlocked_characters"].append("bassist")

func is_character_unlocked(char_id: String) -> bool:
	return char_id in save_data["unlocked_characters"]

# -- Signature-Waffen ----------------------------------------------------------
func is_weapon_unlocked(char_id: String) -> bool:
	return char_id in save_data.get("unlocked_weapons", [])

func unlock_weapon(char_id: String) -> bool:
	if char_id in save_data.get("unlocked_weapons", []):
		return false
	save_data["unlocked_weapons"].append(char_id)
	save_game()
	return true

# Schaltet einen Geheimcharakter frei. Liefert true wenn er NEU freigeschaltet
# wurde (fuer den Unlock-Toast), false wenn er bereits freigeschaltet war.
func unlock_secret_character(char_id: String) -> bool:
	if char_id in save_data["unlocked_characters"]:
		return false
	save_data["unlocked_characters"].append(char_id)
	save_game()
	return true

# -- Geheime Maps (Eastereggs) ---------------------------------------------------
func is_map_unlocked(map_id: String) -> bool:
	return map_id in save_data.get("unlocked_maps", [])

# Schaltet eine geheime Map frei. Liefert true nur bei Neu-Freischaltung.
func unlock_secret_map(map_id: String) -> bool:
	if map_id in save_data.get("unlocked_maps", []):
		return false
	save_data["unlocked_maps"].append(map_id)
	save_game()
	return true

# Zaehlt jede Pause mit (Easteregg: 30 Pausen schalten die Strand-Map frei,
# die Band hat sich den Urlaub aus dem Pausenmenue verdient). Liefert den Stand.
func increment_pause_count() -> int:
	save_data["pause_count"] = int(save_data.get("pause_count", 0)) + 1
	save_game()
	return save_data["pause_count"]

func get_total_kills() -> int:
	return int(save_data.get("total_kills", 0))

func get_high_score() -> int:
	return save_data["high_score"]

func is_tutorial_seen() -> bool:
	return bool(save_data.get("tutorial_seen", false))

func mark_tutorial_seen() -> void:
	save_data["tutorial_seen"] = true
	save_game()

func reset_highscore() -> void:
	# Setzt nur Highscore-Stats zurück. best_wave, endless_leaderboard und
	# unlocked_characters bleiben erhalten, damit freigeschaltete Charaktere
	# nicht verloren gehen.
	save_data["high_score"] = 0
	save_data["total_kills"] = 0
	save_game()

func add_endless_score(entry_name: String, entry_score: int, entry_wave: int, map_id: String) -> void:
	var entry = {
		"name":  entry_name.to_upper().left(3),
		"score": entry_score,
		"wave":  entry_wave,
		"map":   map_id,
	}
	var lb: Array = save_data.get("endless_leaderboard", [])
	lb.append(entry)
	lb.sort_custom(func(a, b): return a["score"] > b["score"])
	if lb.size() > 10:
		lb = lb.slice(0, 10)
	save_data["endless_leaderboard"] = lb
	save_game()

func get_endless_leaderboard() -> Array:
	return save_data.get("endless_leaderboard", [])

func get_setting(key: String) -> Variant:
	return save_data["settings"].get(key, null)

func set_setting(key: String, value: Variant) -> void:
	save_data["settings"][key] = value
	save_game()

func get_option(key: String, default: Variant = null) -> Variant:
	return save_data["settings"].get(key, default)

func set_option(key: String, value: Variant) -> void:
	save_data["settings"][key] = value
	save_game()
