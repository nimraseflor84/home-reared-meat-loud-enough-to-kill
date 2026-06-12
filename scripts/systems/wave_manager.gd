extends Node

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
# Wird bei jedem Spawn mit dem Gegnertyp emittiert. Die Game-Szene nutzt das,
# um beim allerersten Kontakt mit einem Typ eine Lore-Zeile einzublenden.
signal enemy_type_spawned(type: String)

# Boss-Namen sind Dictionaries mit Sprach-Keys (de/en/fr/es/uk).
# Eigennamen bleiben in allen Sprachen gleich, nur Titel/Beschreibungen
# werden uebersetzt. Aufgeloest wird in _resolve_boss_name().
const WAVE_CONFIG = {
	# Proberaum (Wellen 1-2)
	1:  {"count": 10, "types": ["sektierer", "stille"]},
	2:  {"count": 1,  "types": ["erzbischof"], "boss": true,
		"boss_name": {
			"de": "HOHER RAT DER ORTHODOXIE\nERZBISCHOF VIKTOR STUMMBERT",
			"en": "HIGH COUNCIL OF ORTHODOXY\nARCHBISHOP VIKTOR STUMMBERT",
			"fr": "HAUT CONSEIL DE L'ORTHODOXIE\nARCHEVÊQUE VIKTOR STUMMBERT",
			"es": "ALTO CONSEJO DE LA ORTODOXIA\nARZOBISPO VIKTOR STUMMBERT",
			"uk": "ВИЩА РАДА ОРТОДОКСІЇ\nАРХІЄПИСКОП ВІКТОР ШТУМБЕРТ"},
		"extras": 5, "extras_type": "sektierer"},
	# Gefaengnis (Wellen 3-4)
	3:  {"count": 14, "types": ["waerter"]},
	4:  {"count": 1,  "types": ["gefchef"], "boss": true,
		"boss_name": {
			"de": "KNASTDIREKTOR\nDR. HORST KAeFIG",
			"en": "PRISON WARDEN\nDR. HORST KAEFIG",
			"fr": "DIRECTEUR DE PRISON\nDR. HORST KAEFIG",
			"es": "DIRECTOR DE LA PRISIÓN\nDR. HORST KAEFIG",
			"uk": "НАЧАЛЬНИК В'ЯЗНИЦІ\nД-Р ГОРСТ КЕФІГ"},
		"extras": 3, "extras_type": "waerter"},
	# Farm (Welle 5) - direkt nach Boss, etwas entschaerft
	5:  {"count": 13, "types": ["huhn", "wildschwein", "grossbauer"]},
	# Schweinestall (Wellen 6-7)
	6:  {"count": 18, "types": ["wildschwein", "headbanger", "farm_schwein"]},
	7:  {"count": 1,  "types": ["mega_schwein"], "boss": true,
		"boss_name": {
			"de": "MEGA-EBER\nBORSTE-BERND",
			"en": "MEGA BOAR\nBRISTLE-BERND",
			"fr": "MÉGA-SANGLIER\nBORSTE-BERND",
			"es": "MEGA JABALÍ\nBORSTE-BERND",
			"uk": "МЕГА-КАБАН\nБОРСТЕ-БЕРНД"},
		"extras": 5, "extras_type": "wildschwein"},
	# Amerika (Welle 8)
	8:  {"count": 1,  "types": ["trump"], "boss": true,
		"boss_name": {
			"de": "DONALD TRUMP", "en": "DONALD TRUMP", "fr": "DONALD TRUMP",
			"es": "DONALD TRUMP", "uk": "ДОНАЛЬД ТРАМП"},
		"extras": 5, "extras_type": "cowboy"},
	# Truck (Welle 9)
	9:  {"count": 1,  "types": ["trucker"], "boss": true,
		"boss_name": {
			"de": "THUNDER-TRUCKER\nHEINZ",
			"en": "THUNDER TRUCKER\nHEINZ",
			"fr": "ROUTIER DU TONNERRE\nHEINZ",
			"es": "CAMIONERO DEL TRUENO\nHEINZ",
			"uk": "ГРОМОВИЙ ДАЛЕКОБІЙНИК\nГАЙНЦ"},
		"extras": 4, "extras_type": "headbanger"},
	# Tonstudio (Welle 10)
	10: {"count": 22, "types": ["verstimmte", "headbanger", "security"]},
	# TV Studio (Welle 11)
	11: {"count": 1,  "types": ["tvstar"], "boss": true,
		"boss_name": {
			"de": "TV-GURU\nBERND GOLDMANN",
			"en": "TV GURU\nBERND GOLDMANN",
			"fr": "GOUROU TÉLÉ\nBERND GOLDMANN",
			"es": "GURÚ DE LA TV\nBERND GOLDMANN",
			"uk": "ТЕЛЕГУРУ\nБЕРНД ГОЛЬДМАНН"},
		"extras": 5, "extras_type": "security"},
	# Meppen (Wellen 12-13)
	12: {"count": 25, "types": ["stille", "verstimmte", "headbanger"]},
	13: {"count": 1,  "types": ["willi"], "boss": true,
		"boss_name": {
			"de": "RENTNERPAAR\nWILLI & GERLINDE SCHREI-STOPP",
			"en": "RETIRED COUPLE\nWILLI & GERLINDE SCREAM-STOP",
			"fr": "COUPLE DE RETRAITÉS\nWILLI & GERLINDE SCHREI-STOPP",
			"es": "PAREJA DE JUBILADOS\nWILLI & GERLINDE SCHREI-STOPP",
			"uk": "ПОДРУЖЖЯ ПЕНСІОНЕРІВ\nВІЛЛІ ТА ГЕРЛІНДА ШРАЙ-ШТОП"},
		"boss2": "gerlinde",
		"extras": 6, "extras_type": "headbanger"},
	# Death Feast (Wellen 14-15)
	14: {"count": 28, "types": ["verstimmte", "headbanger"]},
	15: {"count": 1,  "types": ["dirigent"], "boss": true,
		# Name an die Story angeglichen: Akt III enthuellt Dr. Victor Stille
		# als CEO von SoundCorp und Dirigent ("HERR BOeSE" war inkonsistent)
		"boss_name": {
			"de": "CEO VON SOUNDCORP\nDR. VICTOR STILLE",
			"en": "CEO OF SOUNDCORP\nDR. VICTOR STILLE",
			"fr": "PDG DE SOUNDCORP\nDR. VICTOR STILLE",
			"es": "CEO DE SOUNDCORP\nDR. VICTOR STILLE",
			"uk": "CEO SOUNDCORP\nД-Р ВІКТОР ШТІЛЛЕ"},
		"extras": 8, "extras_type": "headbanger"},
}

# All enemy scenes preloaded at compile time (class-level consts).
# Compile-time preload evaluates in declaration order — enemy_base.gd is
# declared first, so it is in the GDScript cache before any subclass scene is
# compiled. This permanently solves the "Could not resolve class" cascade that
# occurred when sequential runtime load() calls evicted enemy_base.gd from the
# GDScript internal cache between iterations.
# enemy_base MUST be first:
const _PRELOAD_BASE   = preload("res://scripts/enemies/enemy_base.gd")
# scenes (in wave order):
const _SC_SEKTIERER   = preload("res://scenes/entities/enemies/enemy_sektierer.tscn")
const _SC_ERZBISCHOF  = preload("res://scenes/entities/enemies/enemy_erzbischof.tscn")
const _SC_STILLE      = preload("res://scenes/entities/enemies/enemy_stille.tscn")
const _SC_VERSTIMMTE  = preload("res://scenes/entities/enemies/enemy_verstimmte.tscn")
const _SC_HEADBANGER  = preload("res://scenes/entities/enemies/enemy_headbanger.tscn")
const _SC_HUHN        = preload("res://scenes/entities/enemies/enemy_huhn.tscn")
const _SC_WILDSCHWEIN = preload("res://scenes/entities/enemies/enemy_wildschwein.tscn")
const _SC_GROSSBAUER  = preload("res://scenes/entities/enemies/enemy_grossbauer.tscn")
const _SC_WAERTER     = preload("res://scenes/entities/enemies/enemy_waerter.tscn")
const _SC_GEFCHEF     = preload("res://scenes/entities/enemies/enemy_gefchef.tscn")
const _SC_COWBOY      = preload("res://scenes/entities/enemies/enemy_cowboy.tscn")
const _SC_SHERIFF     = preload("res://scenes/entities/enemies/enemy_sheriff.tscn")
const _SC_TRUMP       = preload("res://scenes/entities/enemies/enemy_trump.tscn")
const _SC_TRUCKER     = preload("res://scenes/entities/enemies/enemy_trucker.tscn")
const _SC_SECURITY    = preload("res://scenes/entities/enemies/enemy_security.tscn")
const _SC_TVSTAR      = preload("res://scenes/entities/enemies/enemy_tvstar.tscn")
const _SC_BUERGERMEISTER = preload("res://scenes/entities/enemies/enemy_buergermeister.tscn")
const _SC_WILLI       = preload("res://scenes/entities/enemies/enemy_willi.tscn")
const _SC_GERLINDE    = preload("res://scenes/entities/enemies/enemy_gerlinde.tscn")
const _SC_MEGA_SCHWEIN = preload("res://scenes/entities/enemies/enemy_mega_schwein.tscn")
const _SC_FARM_SCHWEIN = preload("res://scenes/entities/enemies/enemy_farm_animal.tscn")
const _SC_DIRIGENT    = preload("res://scenes/entities/enemies/enemy_dirigent.tscn")

var _scenes: Dictionary = {}

func _ensure_scenes() -> void:
	if not _scenes.is_empty():
		return
	# All scenes were preloaded at compile time — just assign to the lookup dict.
	_scenes = {
		"sektierer":      _SC_SEKTIERER,
		"erzbischof":     _SC_ERZBISCHOF,
		"stille":         _SC_STILLE,
		"verstimmte":     _SC_VERSTIMMTE,
		"headbanger":     _SC_HEADBANGER,
		"huhn":           _SC_HUHN,
		"wildschwein":    _SC_WILDSCHWEIN,
		"grossbauer":     _SC_GROSSBAUER,
		"waerter":        _SC_WAERTER,
		"gefchef":        _SC_GEFCHEF,
		"cowboy":         _SC_COWBOY,
		"sheriff":        _SC_SHERIFF,
		"trump":          _SC_TRUMP,
		"trucker":        _SC_TRUCKER,
		"security":       _SC_SECURITY,
		"tvstar":         _SC_TVSTAR,
		"buergermeister": _SC_BUERGERMEISTER,
		"willi":          _SC_WILLI,
		"gerlinde":       _SC_GERLINDE,
		"mega_schwein":   _SC_MEGA_SCHWEIN,
		"farm_schwein":   _SC_FARM_SCHWEIN,
		"dirigent":       _SC_DIRIGENT,
	}

func _get_scene(type: String) -> PackedScene:
	_ensure_scenes()
	return _scenes.get(type, _scenes.get("stille"))

const ENDLESS_BOSSES = [
	{"count": 1, "types": ["erzbischof"], "boss": true,
	 "boss_name": {
		"de": "ERZBISCHOF VIKTOR\nSTUMMBERT", "en": "ARCHBISHOP VIKTOR\nSTUMMBERT",
		"fr": "ARCHEVÊQUE VIKTOR\nSTUMMBERT", "es": "ARZOBISPO VIKTOR\nSTUMMBERT",
		"uk": "АРХІЄПИСКОП ВІКТОР\nШТУМБЕРТ"},
	 "extras": 4, "extras_type": "sektierer"},
	{"count": 1, "types": ["gefchef"], "boss": true,
	 "boss_name": {
		"de": "KNASTDIREKTOR\nDR. HORST KAeFIG", "en": "PRISON WARDEN\nDR. HORST KAEFIG",
		"fr": "DIRECTEUR DE PRISON\nDR. HORST KAEFIG", "es": "DIRECTOR DE LA PRISIÓN\nDR. HORST KAEFIG",
		"uk": "НАЧАЛЬНИК В'ЯЗНИЦІ\nД-Р ГОРСТ КЕФІГ"},
	 "extras": 4, "extras_type": "waerter"},
	{"count": 1, "types": ["grossbauer"], "boss": true,
	 "boss_name": {
		"de": "DER GROSSBAUER", "en": "THE FARM BARON", "fr": "LE GRAND FERMIER",
		"es": "EL GRAN TERRATENIENTE", "uk": "ВЕЛИКИЙ ФЕРМЕР"},
	 "extras": 5, "extras_type": "huhn"},
	{"count": 1, "types": ["mega_schwein"], "boss": true,
	 "boss_name": {
		"de": "MEGA-EBER\nBORSTE-BERND", "en": "MEGA BOAR\nBRISTLE-BERND",
		"fr": "MÉGA-SANGLIER\nBORSTE-BERND", "es": "MEGA JABALÍ\nBORSTE-BERND",
		"uk": "МЕГА-КАБАН\nБОРСТЕ-БЕРНД"},
	 "extras": 5, "extras_type": "wildschwein"},
	{"count": 1, "types": ["trump"], "boss": true,
	 "boss_name": {
		"de": "DONALD TRUMP", "en": "DONALD TRUMP", "fr": "DONALD TRUMP",
		"es": "DONALD TRUMP", "uk": "ДОНАЛЬД ТРАМП"},
	 "extras": 6, "extras_type": "cowboy"},
	{"count": 1, "types": ["trucker"], "boss": true,
	 "boss_name": {
		"de": "THUNDER-TRUCKER\nHEINZ", "en": "THUNDER TRUCKER\nHEINZ",
		"fr": "ROUTIER DU TONNERRE\nHEINZ", "es": "CAMIONERO DEL TRUENO\nHEINZ",
		"uk": "ГРОМОВИЙ ДАЛЕКОБІЙНИК\nГАЙНЦ"},
	 "extras": 5, "extras_type": "headbanger"},
	{"count": 1, "types": ["tvstar"], "boss": true,
	 "boss_name": {
		"de": "TV-GURU\nBERND GOLDMANN", "en": "TV GURU\nBERND GOLDMANN",
		"fr": "GOUROU TÉLÉ\nBERND GOLDMANN", "es": "GURÚ DE LA TV\nBERND GOLDMANN",
		"uk": "ТЕЛЕГУРУ\nБЕРНД ГОЛЬДМАНН"},
	 "extras": 6, "extras_type": "security"},
	{"count": 1, "types": ["willi"], "boss": true,
	 "boss_name": {
		"de": "WILLI & GERLINDE\nSCHREI-STOPP", "en": "WILLI & GERLINDE\nSCREAM-STOP",
		"fr": "WILLI & GERLINDE\nSCHREI-STOPP", "es": "WILLI & GERLINDE\nSCHREI-STOPP",
		"uk": "ВІЛЛІ ТА ГЕРЛІНДА\nШРАЙ-ШТОП"},
	 "boss2": "gerlinde",
	 "extras": 6, "extras_type": "headbanger"},
	{"count": 1, "types": ["dirigent"], "boss": true,
	 "boss_name": {
		"de": "CEO VON SOUNDCORP\nDR. VICTOR STILLE", "en": "CEO OF SOUNDCORP\nDR. VICTOR STILLE",
		"fr": "PDG DE SOUNDCORP\nDR. VICTOR STILLE", "es": "CEO DE SOUNDCORP\nDR. VICTOR STILLE",
		"uk": "CEO SOUNDCORP\nД-Р ВІКТОР ШТІЛЛЕ"},
	 "extras": 8, "extras_type": "headbanger"},
	{"count": 1, "types": ["sheriff"], "boss": true,
	 "boss_name": {
		"de": "SHERIFF VON MEPPEN", "en": "SHERIFF OF MEPPEN", "fr": "SHÉRIF DE MEPPEN",
		"es": "SHERIFF DE MEPPEN", "uk": "ШЕРИФ МЕППЕНА"},
	 "extras": 6, "extras_type": "cowboy"},
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
				if is_instance_valid(e):
					var alive_val = e.get("is_alive")
					# bare CharacterBody2D (script failed) has no is_alive -> skip
					if alive_val == null:
						continue
					if alive_val != false:
						any_alive = true
						break
			if not any_alive:
				_alive_enemies = 0
				_complete_wave()

func start_wave(wave_number: int) -> void:
	_ensure_scenes()  # Load enemy scenes lazily on first wave
	current_wave = wave_number
	GameManager.current_wave = wave_number
	enemies_killed = 0
	_spawned = 0
	_spawn_timer = 0.0
	_alive_enemies = 0
	_tracked_enemies.clear()
	_completing = false
	# Gleicher Seed auf beiden Geraeten -> identische Spawn-Positionen
	if GameManager.network_mode > 0:
		seed(GameManager.net_seed + wave_number * 1000)

	var config = WAVE_CONFIG.get(wave_number, _get_endless_config(wave_number))
	_current_config = config
	var count_mult = GameManager.DIFFICULTY_COUNT[GameManager.difficulty]
	# Hard-Cap fuer Endless: nie mehr als 60 Gegner pro Welle, sonst sackt die
	# Performance auf Mid-Range Geraeten ab und das Spielfeld wird unleserlich.
	var max_per_wave: int = 60
	_enemies_to_spawn = clamp(int(config["count"] * count_mult), 1, max_per_wave)
	_boss_wave = config.get("boss", false)
	boss_name  = _resolve_boss_name(config.get("boss_name", "ENDBOSS"))
	wave_active = true

	if _boss_wave:
		_spawn_interval = 0.5
	else:
		# Glattere Spawn-Rate: wave 1 ~1.96s, wave 5 ~1.60s, wave 10 ~1.15s,
		# wave 15 ~0.70s, ab wave 18 floor bei 0.45s.
		_spawn_interval = max(0.45, 2.05 - wave_number * 0.09)

	emit_signal("wave_started", wave_number)

	# Extras bei Boss-Wellen
	var extras = config.get("extras", 0)
	var extras_type = config.get("extras_type", "headbanger")
	var extra_scene_res: PackedScene = _get_scene(extras_type)
	for i in range(extras):
		var e = extra_scene_res.instantiate()
		if e.get("is_alive") == null:
			e.queue_free()
			continue
		e.global_position = _get_spawn_position()
		e.connect("died", _on_enemy_died)
		_alive_enemies += 1
		_tracked_enemies.append(e)
		get_tree().current_scene.add_child(e)
		emit_signal("enemy_type_spawned", extras_type)

	# Zweiten Boss spawnen falls definiert (z.B. Gerlinde neben Willi)
	var boss2_type = config.get("boss2", "")
	if boss2_type != "":
		var b2_res: PackedScene = _get_scene(boss2_type)
		if b2_res:
			var b2 = b2_res.instantiate()
			if b2.get("is_alive") == null:
				b2.queue_free()
			else:
				b2.global_position = _get_spawn_position()
				b2.connect("died", _on_enemy_died)
				_alive_enemies += 1
				_tracked_enemies.append(b2)
				get_tree().current_scene.add_child(b2)
				emit_signal("enemy_type_spawned", boss2_type)

func _get_endless_config(wave_number: int) -> Dictionary:
	# Jede 5. Welle: Boss rotiert durch alle Bosse
	if wave_number % 5 == 0:
		var idx = ((wave_number / 5) - 1) % ENDLESS_BOSSES.size()
		var cfg = ENDLESS_BOSSES[idx].duplicate()
		# Extras skalieren mit der Runde
		var extra_bonus = (wave_number / 5) - 1
		cfg["extras"] = cfg.get("extras", 4) + extra_bonus
		return cfg
	# Normale Welle: Gegner-Pool waechst mit der Zeit. Lineare Steigerung
	# reduziert von +2 pro Wave auf +1.5 - in Verbindung mit dem 60er Cap
	# in start_wave bleibt die spaete Endless-Phase noch lesbar.
	var round_num = wave_number - 15  # ab Wave 16 zaehlt Runde 1, 2, ...
	var count = 12 + int(wave_number * 1.5)
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
	var enemy_scene: PackedScene = _get_scene(type)
	var enemy = enemy_scene.instantiate()
	_spawned += 1
	# Guard: if script failed to load, is_alive property won't exist
	if enemy.get("is_alive") == null:
		push_warning("WaveManager: enemy '" + type + "' script not loaded (no is_alive). script=" + str(enemy.get_script()))
		enemy.queue_free()
		return
	if type.begins_with("farm_"):
		enemy.animal_type = type.substr(5)
	enemy.global_position = _get_spawn_position()
	enemy.connect("died", _on_enemy_died)
	_alive_enemies += 1
	_tracked_enemies.append(enemy)
	get_tree().current_scene.add_child(enemy)
	emit_signal("enemy_type_spawned", type)

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
	# Im Netzwerk-Modus: nur der Host bestimmt den Abschluss
	if GameManager.network_mode == 2:
		# Client: lokal "fertig", aber kein Szenen-Wechsel - wartet auf Host-RPC
		return
	# Warten bis Boss-Todesanimationen vollstaendig abgespielt sind
	# Typ-sicher: Felder nur lesen wenn sie tatsaechlich existieren
	var bosses = get_tree().get_nodes_in_group("bosses")
	var wait_time = 0.0
	for b in bosses:
		if not is_instance_valid(b):
			continue
		if b.get("_dying") == true:
			var anim_dur = b.get("_death_anim_duration")
			var anim_time = b.get("_death_anim_time")
			if anim_dur != null and anim_time != null:
				var rem = float(anim_dur) - float(anim_time)
				wait_time = max(wait_time, rem)
	if wait_time > 0.0:
		await get_tree().create_timer(wait_time + 0.2, false).timeout
		if not is_inside_tree():
			return
	GameManager.run_stats["waves_cleared"] += 1
	emit_signal("wave_completed", current_wave)
	AudioManager.play_wave_complete_sfx()

# Loest einen Boss-Namen in der aktiven Sprache auf.
# Akzeptiert String (Altformat) oder Dictionary mit Sprach-Keys.
func _resolve_boss_name(raw) -> String:
	if raw is Dictionary:
		var lang: String = LocalizationManager.current_language
		return raw.get(lang, raw.get("en", raw.get("de", "ENDBOSS")))
	return str(raw)

func reset() -> void:
	current_wave = 0
	wave_active = false
	_spawned = 0
	enemies_killed = 0
	_alive_enemies = 0
	_tracked_enemies.clear()
	_completing = false
	_current_config = {}
