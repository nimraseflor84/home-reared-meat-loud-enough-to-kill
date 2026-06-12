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
	"settings": {
		"sfx_volume": 1.0,
		"music_volume": 0.8,
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
	# Top-level merge: uebernimmt geladene Werte, behaelt neue Default-Keys
	for key in save_data:
		if loaded.has(key) and typeof(loaded[key]) == typeof(save_data[key]):
			save_data[key] = loaded[key]
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
	save_data["total_kills"] += gm.run_stats.get("kills", 0)

	# Unlock characters based on waves cleared
	_check_unlocks()
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
