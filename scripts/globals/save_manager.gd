extends Node

const SAVE_PATH = "user://save_data.json"

var save_data: Dictionary = {
	"high_score": 0,
	"unlocked_characters": ["manni"],
	"best_wave": 0,
	"total_kills": 0,
	"endless_leaderboard": [],
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
		"master_vol": 1.0,
		"music_vol": 0.8,
		"sfx_vol": 1.0,
	}
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_text) == OK:
			var loaded = json.get_data()
			# Merge with defaults to handle missing keys
			for key in save_data:
				if loaded.has(key):
					save_data[key] = loaded[key]

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

func reset_highscore() -> void:
	save_data["high_score"] = 0
	save_data["best_wave"] = 0
	save_data["total_kills"] = 0
	save_data["endless_leaderboard"] = []
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
