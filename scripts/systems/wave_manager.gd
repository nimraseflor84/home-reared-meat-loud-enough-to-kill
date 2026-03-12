extends Node
class_name WaveManager

var current_wave: int = 0
var enemies_this_wave: int = 0
var enemies_killed: int = 0
var wave_active: bool = false
var _spawn_timer: float = 0.0
var _spawn_interval: float = 2.0
var _enemies_to_spawn: int = 0
var _spawned: int = 0
var _boss_wave: bool = false
var boss_name: String = ""

signal wave_started(wave_number)
signal wave_completed(wave_number)
signal all_waves_completed()
signal boss_spawned()

const WAVE_CONFIG = {
	# Proberaum (Wellen 1-2)
	1:  {"count": 10, "types": ["sektierer", "stille"]},
	2:  {"count": 1,  "types": ["erzbischof"], "boss": true,
		"boss_name": "HOHER RAT DER ORTHODOXIE\nERZBISCHOF VIKTOR STUMMBERT",
		"extras": 5, "extras_type": "sektierer"},
	# Gefaengnis (Wellen 3-4)
	3:  {"count": 14, "types": ["waerter"]},
	4:  {"count": 1,  "types": ["gefchef"], "boss": true,
		"boss_name": "KNASTDIREKTOR\nDR. HORST KÄFIG",
		"extras": 3, "extras_type": "waerter"},
	# Farm (Welle 5) – direkt nach Boss, etwas entschärft
	5:  {"count": 13, "types": ["huhn", "wildschwein", "grossbauer"]},
	# Schweinestall (Wellen 6-7)
	6:  {"count": 18, "types": ["wildschwein", "headbanger"]},
	7:  {"count": 1,  "types": ["mega_schwein"], "boss": true,
		"boss_name": "MEGA-EBER\nBORSTE-BERND",
		"extras": 5, "extras_type": "wildschwein"},
	# Amerika (Welle 8)
	8:  {"count": 1,  "types": ["trump"], "boss": true,
		"boss_name": "DONALD TRUMP",
		"extras": 5, "extras_type": "cowboy"},
	# Truck (Welle 9)
	9:  {"count": 1,  "types": ["trucker"], "boss": true,
		"boss_name": "THUNDER-TRUCKER\nHEINZ",
		"extras": 4, "extras_type": "headbanger"},
	# Tonstudio (Welle 10)
	10: {"count": 22, "types": ["verstimmte", "headbanger", "security"]},
	# TV Studio (Welle 11)
	11: {"count": 1,  "types": ["tvstar"], "boss": true,
		"boss_name": "TV-GURU\nBERND GOLDMANN",
		"extras": 5, "extras_type": "security"},
	# Meppen (Wellen 12-13)
	12: {"count": 25, "types": ["stille", "verstimmte", "headbanger"]},
	13: {"count": 1,  "types": ["willi"], "boss": true,
		"boss_name": "RENTNERPAAR\nWILLI & GERLINDE SCHREI-STOPP",
		"boss2": "gerlinde",
		"extras": 6, "extras_type": "headbanger"},
	# Death Feast (Wellen 14-15)
	14: {"count": 28, "types": ["verstimmte", "headbanger"]},
	15: {"count": 1,  "types": ["dirigent"], "boss": true,
		"boss_name": "CEO DER STILLE\nHERR BÖSE",
		"extras": 8, "extras_type": "headbanger"},
}

const ENEMY_SCENE_RESOURCES = {
	# Standard-Gegner
	"sektierer":      preload("res://scenes/entities/enemies/enemy_sektierer.tscn"),
	"erzbischof":     preload("res://scenes/entities/enemies/enemy_erzbischof.tscn"),
	"stille":         preload("res://scenes/entities/enemies/enemy_stille.tscn"),
	"verstimmte":     preload("res://scenes/entities/enemies/enemy_verstimmte.tscn"),
	"headbanger":     preload("res://scenes/entities/enemies/enemy_headbanger.tscn"),
	# Farm
	"huhn":           preload("res://scenes/entities/enemies/enemy_huhn.tscn"),
	"wildschwein":    preload("res://scenes/entities/enemies/enemy_wildschwein.tscn"),
	"grossbauer":     preload("res://scenes/entities/enemies/enemy_grossbauer.tscn"),
	# Gefaengnis
	"waerter":        preload("res://scenes/entities/enemies/enemy_waerter.tscn"),
	"gefchef":        preload("res://scenes/entities/enemies/enemy_gefchef.tscn"),
	# Amerika
	"cowboy":         preload("res://scenes/entities/enemies/enemy_cowboy.tscn"),
	"sheriff":        preload("res://scenes/entities/enemies/enemy_sheriff.tscn"),
	"trump":          preload("res://scenes/entities/enemies/enemy_trump.tscn"),
	# Truck
	"trucker":        preload("res://scenes/entities/enemies/enemy_trucker.tscn"),
	# TV Studio
	"security":       preload("res://scenes/entities/enemies/enemy_security.tscn"),
	"tvstar":         preload("res://scenes/entities/enemies/enemy_tvstar.tscn"),
	# Meppen
	"buergermeister": preload("res://scenes/entities/enemies/enemy_buergermeister.tscn"),
	"willi":          preload("res://scenes/entities/enemies/enemy_willi.tscn"),
	"gerlinde":       preload("res://scenes/entities/enemies/enemy_gerlinde.tscn"),
	# Boss
	"mega_schwein":   preload("res://scenes/entities/enemies/enemy_mega_schwein.tscn"),
	"dirigent":       preload("res://scenes/entities/enemies/enemy_dirigent.tscn"),
}

const ENDLESS_BOSSES = [
	{"count": 1, "types": ["erzbischof"], "boss": true,
	 "boss_name": "ERZBISCHOF VIKTOR\nSTUMMBERT", "extras": 4, "extras_type": "sektierer"},
	{"count": 1, "types": ["gefchef"], "boss": true,
	 "boss_name": "KNASTDIREKTOR\nDR. HORST KÄFIG", "extras": 4, "extras_type": "waerter"},
	{"count": 1, "types": ["grossbauer"], "boss": true,
	 "boss_name": "DER GROSSBAUER", "extras": 5, "extras_type": "huhn"},
	{"count": 1, "types": ["mega_schwein"], "boss": true,
	 "boss_name": "MEGA-EBER\nBORSTE-BERND", "extras": 5, "extras_type": "wildschwein"},
	{"count": 1, "types": ["trump"], "boss": true,
	 "boss_name": "DONALD TRUMP", "extras": 6, "extras_type": "cowboy"},
	{"count": 1, "types": ["trucker"], "boss": true,
	 "boss_name": "THUNDER-TRUCKER\nHEINZ", "extras": 5, "extras_type": "headbanger"},
	{"count": 1, "types": ["tvstar"], "boss": true,
	 "boss_name": "TV-GURU\nBERND GOLDMANN", "extras": 6, "extras_type": "security"},
	{"count": 1, "types": ["willi"], "boss": true,
	 "boss_name": "WILLI & GERLINDE\nSCHREI-STOPP", "boss2": "gerlinde",
	 "extras": 6, "extras_type": "headbanger"},
	{"count": 1, "types": ["dirigent"], "boss": true,
	 "boss_name": "CEO DER STILLE\nHERR BÖSE", "extras": 8, "extras_type": "headbanger"},
	{"count": 1, "types": ["sheriff"], "boss": true,
	 "boss_name": "SHERIFF VON MEPPEN", "extras": 6, "extras_type": "cowboy"},
]

var _alive_enemies: int = 0
var _tracked_enemies: Array = []
var _current_config: Dictionary = {}

func _process(delta: float) -> void:
	if not wave_active:
		return

	_spawn_timer += delta
	if _spawned < _enemies_to_spawn and _spawn_timer >= _spawn_interval:
		_spawn_timer = 0.0
		_spawn_enemy()

	# Check wave completion only after all enemies are spawned
	if _spawned >= _enemies_to_spawn:
		if _alive_enemies <= 0:
			_complete_wave()
		else:
			# Fallback: check if tracked enemies are actually still alive
			var any_alive := false
			for e in _tracked_enemies:
				if is_instance_valid(e) and e.is_alive:
					any_alive = true
					break
			if not any_alive:
				_alive_enemies = 0
				_complete_wave()

func start_wave(wave_number: int) -> void:
	current_wave = wave_number
	GameManager.current_wave = wave_number
	enemies_killed = 0
	_spawned = 0
	_spawn_timer = 0.0
	_alive_enemies = 0
	_tracked_enemies.clear()
	_completing = false

	var config = WAVE_CONFIG.get(wave_number, _get_endless_config(wave_number))
	_current_config = config
	var count_mult = GameManager.DIFFICULTY_COUNT[GameManager.difficulty]
	_enemies_to_spawn = max(1, int(config["count"] * count_mult))
	_boss_wave = config.get("boss", false)
	boss_name  = config.get("boss_name", "ENDBOSS")
	wave_active = true

	if _boss_wave:
		_spawn_interval = 0.5
	else:
		_spawn_interval = max(0.35, 2.2 - wave_number * 0.1)

	emit_signal("wave_started", wave_number)

	# Extras bei Boss-Wellen
	var extras = config.get("extras", 0)
	var extras_type = config.get("extras_type", "headbanger")
	var extra_scene_res: PackedScene = ENEMY_SCENE_RESOURCES.get(extras_type, ENEMY_SCENE_RESOURCES["headbanger"])
	for i in range(extras):
		var e = extra_scene_res.instantiate()
		e.global_position = _get_spawn_position()
		e.connect("died", _on_enemy_died)
		_alive_enemies += 1
		_tracked_enemies.append(e)
		get_tree().current_scene.add_child(e)

	# Zweiten Boss spawnen falls definiert (z.B. Gerlinde neben Willi)
	var boss2_type = config.get("boss2", "")
	if boss2_type != "":
		var b2_res: PackedScene = ENEMY_SCENE_RESOURCES.get(boss2_type)
		if b2_res:
			var b2 = b2_res.instantiate()
			b2.global_position = _get_spawn_position()
			b2.connect("died", _on_enemy_died)
			_alive_enemies += 1
			_tracked_enemies.append(b2)
			get_tree().current_scene.add_child(b2)

func _get_endless_config(wave_number: int) -> Dictionary:
	# Jede 5. Welle: Boss rotiert durch alle Bosse
	if wave_number % 5 == 0:
		var idx = ((wave_number / 5) - 1) % ENDLESS_BOSSES.size()
		var cfg = ENDLESS_BOSSES[idx].duplicate()
		# Extras skalieren mit der Runde
		var extra_bonus = (wave_number / 5) - 1
		cfg["extras"] = cfg.get("extras", 4) + extra_bonus
		return cfg
	# Normale Welle: Gegner-Pool wächst mit der Zeit
	var round_num = wave_number - 15  # ab Wave 16 zählt Runde 1, 2, ...
	var count = 10 + wave_number * 2
	var types: Array
	if round_num <= 4:
		types = ["sektierer", "stille", "verstimmte", "headbanger"]
	elif round_num <= 9:
		types = ["verstimmte", "headbanger", "waerter", "security", "cowboy"]
	elif round_num <= 14:
		types = ["verstimmte", "headbanger", "security", "cowboy", "wildschwein", "huhn"]
	else:
		types = ["verstimmte", "headbanger", "security", "cowboy", "wildschwein",
				 "huhn", "sektierer", "waerter", "stille"]
	return {"count": count, "types": types}

func _spawn_enemy() -> void:
	if not wave_active:
		return
	var types = _current_config.get("types", ["stille"])
	var type = types[randi() % types.size()]
	var enemy_scene: PackedScene = ENEMY_SCENE_RESOURCES.get(type, ENEMY_SCENE_RESOURCES["stille"])
	var enemy = enemy_scene.instantiate()
	enemy.global_position = _get_spawn_position()
	enemy.connect("died", _on_enemy_died)
	_alive_enemies += 1
	_tracked_enemies.append(enemy)
	_spawned += 1
	get_tree().current_scene.add_child(enemy)

func _get_spawn_position() -> Vector2:
	var vp = get_viewport().get_visible_rect()
	var margin = 60.0
	var side = randi() % 4
	match side:
		0: return Vector2(randf_range(0, vp.size.x), -margin)
		1: return Vector2(randf_range(0, vp.size.x), vp.size.y + margin)
		2: return Vector2(-margin, randf_range(0, vp.size.y))
		_: return Vector2(vp.size.x + margin, randf_range(0, vp.size.y))

func _on_enemy_died(_enemy) -> void:
	enemies_killed += 1
	_alive_enemies -= 1

var _completing: bool = false

func _complete_wave() -> void:
	if _completing:
		return
	_completing = true
	wave_active = false
	# Warten bis Boss-Todesanimationen vollständig abgespielt sind
	var bosses = get_tree().get_nodes_in_group("bosses")
	var wait_time = 0.0
	for b in bosses:
		if is_instance_valid(b) and b.get("_dying") == true:
			var rem = b._death_anim_duration - b._death_anim_time
			wait_time = max(wait_time, rem)
	if wait_time > 0.0:
		await get_tree().create_timer(wait_time + 0.2, false).timeout
		if not is_inside_tree():
			return
	GameManager.run_stats["waves_cleared"] += 1
	emit_signal("wave_completed", current_wave)
	AudioManager.play_wave_complete_sfx()

func reset() -> void:
	current_wave = 0
	wave_active = false
	_spawned = 0
	enemies_killed = 0
	_alive_enemies = 0
	_tracked_enemies.clear()
	_completing = false
	_current_config = {}
