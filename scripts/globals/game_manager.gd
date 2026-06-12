extends Node

# Game states
enum GameState { MENU, CHARACTER_SELECT, STORY, GAME, UPGRADE_SHOP, GAME_OVER }

var current_state: GameState = GameState.MENU
var selected_character: String = "manni"
var player_count: int = 1                          # 1 = Solo, 2 = Co-op
var selected_characters: Array = ["manni", "manni"] # [P1, P2]
var current_wave: int = 0
var score: int = 0
var run_stats: Dictionary = {}

# -- Endless Mode --------------------------------------------------------------
var endless_mode: bool = false
var endless_map: String = "farm"

# -- Difficulty ----------------------------------------------------------------
var difficulty: int = 2  # 0=VeryEasy ... 4=VeryHard

const DIFFICULTY_NAMES = [
	"Access Denied",
	"Vomit Blood",
	"Brootal Destroy",
	"Drink Fight Die!",
	"Bolognese Bloodbath",
]
const DIFFICULTY_COLORS = [
	Color(0.20, 0.90, 0.30),   # gruen
	Color(0.75, 0.90, 0.10),   # gelbgruen
	Color(1.00, 0.55, 0.05),   # orange
	Color(0.95, 0.15, 0.10),   # rot
	Color(0.60, 0.00, 0.10),   # dunkelblutrot
]
# HP-Multiplikator pro Schwierigkeitsgrad
# Very Easy bewusst niedrig (Tutorial-Tier), Very Hard fordernd aber nicht
# absurd: 2.4x reicht aus weil HP zusaetzlich mit Wave skaliert (1.07^wave).
const DIFFICULTY_HP   = [0.35, 0.65, 1.0, 1.5, 2.4]
# Schaden-Multiplikator - Hard/Very Hard etwas entschaerft
const DIFFICULTY_DMG  = [0.35, 0.65, 1.0, 1.35, 1.85]
# Gegneranzahl-Multiplikator - leicht nach unten korrigiert um Lag und
# unfaire Spike-Waves zu vermeiden
const DIFFICULTY_COUNT = [0.45, 0.72, 1.0, 1.4, 1.9]
# Wahrscheinlichkeit dass ein Gegner fernkaempft (0=nie). Very Hard von 0.80
# auf 0.55 reduziert - 0.80 fuehlte sich an als wuerde jeder Gegner schiessen,
# das war oppressiv. Hard bleibt bei 0.40 als spuerbarer Sprung.
const DIFFICULTY_SHOOT = [0.0, 0.0, 0.0, 0.40, 0.55]

# Character scene paths
const CHARACTER_SCENES = {
	"manni": "res://scenes/entities/players/player_manni.tscn",
	"shouter": "res://scenes/entities/players/player_shouter.tscn",
	"dreads": "res://scenes/entities/players/player_dreads.tscn",
	"riff_slicer": "res://scenes/entities/players/player_riff_slicer.tscn",
	"distortion": "res://scenes/entities/players/player_distortion.tscn",
	"bassist": "res://scenes/entities/players/player_bassist.tscn",
}

# Charakter-Beschreibungen als Sprach-Dictionaries (de/en/fr/es/uk).
# Aufloesung ueber char_desc() weiter unten.
const CHARACTER_INFO = {
	"manni": {"name": "Manny", "color": Color(0.2, 0.4, 0.9), "desc": {
		"de": "Drumstick-Meister. Kills erhöhen das Angriffstempo.",
		"en": "Drumstick master. Kills increase attack speed.",
		"fr": "Maître des baguettes. Les kills augmentent la vitesse d'attaque.",
		"es": "Maestro de las baquetas. Las bajas aumentan la velocidad de ataque.",
		"uk": "Майстер барабанних паличок. Вбивства прискорюють атаку."}},
	"shouter": {"name": "Chicken", "color": Color(0.9, 0.2, 0.2), "desc": {
		"de": "Growler. Niederfrequente Todesstrahlen. Hohe Präzision.",
		"en": "Growler. Low-frequency death beams. High precision.",
		"fr": "Growler. Rayons mortels à basse fréquence. Haute précision.",
		"es": "Growler. Rayos mortales de baja frecuencia. Alta precisión.",
		"uk": "Гроулер. Низькочастотні промені смерті. Висока точність."}},
	"dreads": {"name": "Nik", "color": Color(0.2, 0.8, 0.3), "desc": {
		"de": "Inhale-Screamer. Dreadlock-Peitsche. Packt und wirft Gegner.",
		"en": "Inhale Screamer. Dreadlock whip. Can grab & throw enemies.",
		"fr": "Inhale screamer. Fouet de dreadlocks. Attrape et projette les ennemis.",
		"es": "Inhale screamer. Látigo de rastas. Agarra y lanza enemigos.",
		"uk": "Інхейл-скрімер. Батіг із дредів. Хапає і кидає ворогів."}},
	"riff_slicer": {"name": "Andz", "color": Color(0.9, 0.5, 0.1), "desc": {
		"de": "Saiten-Klingen durchbohren mehrere Gegner.",
		"en": "String blades pierce multiple enemies.",
		"fr": "Des lames-cordes transpercent plusieurs ennemis.",
		"es": "Cuchillas de cuerda atraviesan a varios enemigos.",
		"uk": "Леза зі струн пронизують кількох ворогів."}},
	"distortion": {"name": "Grindhouse", "color": Color(0.6, 0.2, 0.9), "desc": {
		"de": "Verzerrungsfelder verlangsamen Gegner in der Nähe.",
		"en": "Distortion fields slow nearby enemies.",
		"fr": "Des champs de distorsion ralentissent les ennemis proches.",
		"es": "Campos de distorsión ralentizan a los enemigos cercanos.",
		"uk": "Поля дисторшну сповільнюють ворогів поруч."}},
	"bassist": {"name": "Armin", "color": Color(0.1, 0.2, 0.6), "desc": {
		"de": "Sub-Bass-Wellen. Boden-Schockwellen bei Kills.",
		"en": "Sub-bass waves. Ground shockwaves on kills.",
		"fr": "Ondes sub-basses. Ondes de choc au sol à chaque kill.",
		"es": "Ondas de subgraves. Ondas de choque al matar.",
		"uk": "Суб-басові хвилі. Ударні хвилі від вбивств."}},
}

# Liefert die Charakter-Beschreibung in der aktiven Sprache.
# Akzeptiert auch das alte String-Format als Fallback.
func char_desc(char_id: String) -> String:
	var d = CHARACTER_INFO.get(char_id, {}).get("desc", "")
	if d is Dictionary:
		return d.get(LocalizationManager.current_language, d.get("en", ""))
	return str(d)

signal state_changed(new_state)
signal wave_started(wave_number)
signal wave_completed(wave_number)
signal player_died()
signal score_changed(new_score)

var game_font: Font = null

func _ready() -> void:
	_setup_global_theme()
	_setup_controller_bindings()
	reset_run_stats()

func _setup_controller_bindings() -> void:
	# UI-Aktionen mit Joypad belegen (Menue-Navigation & Bestaetigung)
	var ui_joy = {
		"ui_accept": JOY_BUTTON_A,
		"ui_cancel": JOY_BUTTON_B,
		"ui_up":     JOY_BUTTON_DPAD_UP,
		"ui_down":   JOY_BUTTON_DPAD_DOWN,
		"ui_left":   JOY_BUTTON_DPAD_LEFT,
		"ui_right":  JOY_BUTTON_DPAD_RIGHT,
	}
	for action in ui_joy:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var already = false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton and ev.button_index == ui_joy[action]:
				already = true; break
		if not already:
			var ev = InputEventJoypadButton.new()
			ev.button_index = ui_joy[action]
			InputMap.action_add_event(action, ev)

	# Linken Analog-Stick ebenfalls fuer UI-Navigation nutzen
	var ui_axis = {
		"ui_left":  [JOY_AXIS_LEFT_X, -1.0],
		"ui_right": [JOY_AXIS_LEFT_X,  1.0],
		"ui_up":    [JOY_AXIS_LEFT_Y, -1.0],
		"ui_down":  [JOY_AXIS_LEFT_Y,  1.0],
	}
	for action in ui_axis:
		var axis_info = ui_axis[action]
		var already = false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadMotion and ev.axis == axis_info[0] and sign(ev.axis_value) == sign(axis_info[1]):
				already = true; break
		if not already:
			var ev = InputEventJoypadMotion.new()
			ev.axis = axis_info[0]
			ev.axis_value = axis_info[1]
			InputMap.action_add_event(action, ev)

	# Gameplay-Aktionen mit Joypad belegen
	var gameplay_joy = {
		"move_up":    [JOY_AXIS_LEFT_Y, -1.0],
		"move_down":  [JOY_AXIS_LEFT_Y,  1.0],
		"move_left":  [JOY_AXIS_LEFT_X, -1.0],
		"move_right": [JOY_AXIS_LEFT_X,  1.0],
		"attack":     JOY_BUTTON_A,
		"ultimate":   JOY_BUTTON_X,
	}
	for action in gameplay_joy:
		if not InputMap.has_action(action):
			continue
		var val = gameplay_joy[action]
		var already = false
		if val is Array:
			for ev in InputMap.action_get_events(action):
				if ev is InputEventJoypadMotion and ev.axis == val[0] and sign(ev.axis_value) == sign(val[1]):
					already = true; break
			if not already:
				var ev = InputEventJoypadMotion.new()
				ev.axis = val[0]
				ev.axis_value = val[1]
				InputMap.action_add_event(action, ev)
		else:
			for ev in InputMap.action_get_events(action):
				if ev is InputEventJoypadButton and ev.button_index == val:
					already = true; break
			if not already:
				var ev = InputEventJoypadButton.new()
				ev.button_index = val
				InputMap.action_add_event(action, ev)

func _setup_global_theme() -> void:
	# SystemFont mit fettem Rock/Metal-Stil - Impact als Hauptfont, Fallbacks fuer alle Plattformen
	var font = SystemFont.new()
	font.font_names = PackedStringArray([
		"Impact",
		"Arial Black",
		"Helvetica Neue",
		"Arial Bold",
		"Arial",
	])
	font.font_weight = 900
	font.font_italic = true
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	game_font = font

	# Theme auf Root-Window setzen -> alle Controls erben den Font automatisch
	var theme = Theme.new()
	theme.default_font = font
	theme.set_font("font", "Label",    font)
	theme.set_font("font", "Button",   font)
	theme.set_font("font", "LineEdit", font)
	theme.set_font("font", "RichTextLabel", font)
	# Schriftgroessen aus dem Theme uebernehmen (individuelle Overrides bleiben erhalten)
	theme.set_font_size("font_size", "Label",    20)
	theme.set_font_size("font_size", "Button",   20)
	theme.default_font_size = 20

	call_deferred("_apply_theme", theme)

func _apply_theme(theme: Theme) -> void:
	if get_tree():
		get_tree().root.theme = theme

func reset_run_stats() -> void:
	# Highscore VOR dem Run speichern, damit der Game-Over-Screen entscheiden
	# kann ob die Score-Anzeige ein neuer Rekord ist (SaveManager.update_run_results
	# wird vor dem Wechsel zu game_over aufgerufen und ueberschreibt sonst den Vergleichswert).
	# Beim ersten Aufruf in _ready() ist SaveManager als Autoload evtl. noch nicht im
	# Baum - dann faellt prev_high auf 0 zurueck. Vor jedem echten Run-Start wird
	# reset_run_stats nochmal aus start_new_run() aufgerufen wo SaveManager bereit ist.
	var prev_high: int = 0
	if get_tree() != null and get_tree().root.has_node("SaveManager"):
		prev_high = SaveManager.get_high_score()
	run_stats = {
		"kills": 0,
		"rhythm_hits": 0,
		"damage_dealt": 0,
		"waves_cleared": 0,
		"upgrades_taken": [],
		"start_time": Time.get_ticks_msec(),
		"end_time": 0,
		"high_score_before_run": prev_high,
	}

func add_damage_dealt(amount: float) -> void:
	if amount <= 0.0:
		return
	# Defensiv: damage_dealt koennte als int oder float gespeichert sein
	var cur = run_stats.get("damage_dealt", 0)
	run_stats["damage_dealt"] = float(cur) + amount

func get_run_time_seconds() -> float:
	var start_ms = run_stats.get("start_time", 0)
	if start_ms == 0:
		return 0.0
	var end_ms = run_stats.get("end_time", 0)
	if end_ms == 0:
		end_ms = Time.get_ticks_msec()
	return max(0.0, float(end_ms - start_ms) / 1000.0)

func mark_run_ended() -> void:
	if run_stats.get("end_time", 0) == 0:
		run_stats["end_time"] = Time.get_ticks_msec()

func format_time_seconds(total_seconds: float) -> String:
	var s: int = int(total_seconds)
	var minutes: int = s / 60
	var seconds: int = s % 60
	return "%02d:%02d" % [minutes, seconds]

func start_new_run() -> void:
	current_wave = 0
	score = 0
	selected_characters[0] = selected_character
	reset_run_stats()
	emit_signal("score_changed", score)

func add_score(points: int) -> void:
	score += points
	emit_signal("score_changed", score)

func add_kill() -> void:
	run_stats["kills"] += 1
	add_score(100)

func set_state(new_state: GameState) -> void:
	current_state = new_state
	emit_signal("state_changed", new_state)

func get_wave_difficulty_multiplier() -> float:
	# HP-Skalierung pro Welle. 1.07 statt 1.08 glaettet Wave 10+ ein wenig -
	# 1.07^15 = 2.76 (vorher 3.17), 1.07^20 = 3.87 (vorher 4.66).
	return pow(1.07, current_wave)

func get_wave_damage_multiplier() -> float:
	# Schaden-Skalierung pro Welle. 1.035 statt 1.04 - gleicher Grund.
	return pow(1.035, current_wave)

func change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

# Lautstaerke-Widget in eine Szene einbetten (CanvasLayer damit immer im Vordergrund)
func add_volume_widget(parent: Node) -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	parent.add_child(canvas)
	var widget_script = load("res://scripts/ui/volume_widget.gd")
	var widget = Control.new()
	widget.set_anchors_preset(Control.PRESET_FULL_RECT)
	widget.script = widget_script
	canvas.add_child(widget)

func go_to_main_menu() -> void:
	set_state(GameState.MENU)
	change_scene("res://scenes/main_menu.tscn")

func go_to_character_select() -> void:
	set_state(GameState.CHARACTER_SELECT)
	change_scene("res://scenes/character_select.tscn")

func start_game() -> void:
	start_new_run()
	endless_mode = false
	set_state(GameState.GAME)
	# Story-Mode startet mit Akt I. Vorher wurde act1_intro.tscn nie angezeigt,
	# weil direkt in game.tscn gewechselt wurde - der Spieler bekam den
	# Story-Einstieg (SoundCorp, Mutationsakkord) nie zu sehen.
	change_scene("res://scenes/story/act1_intro.tscn")

func start_endless_game() -> void:
	start_new_run()
	endless_mode = true
	set_state(GameState.GAME)
	change_scene("res://scenes/game.tscn")

func go_to_map_select() -> void:
	change_scene("res://scenes/map_select.tscn")

func go_to_endless_leaderboard() -> void:
	change_scene("res://scenes/endless_leaderboard.tscn")

func go_to_game() -> void:
	set_state(GameState.GAME)
	change_scene("res://scenes/game.tscn")

func go_to_upgrade_shop() -> void:
	set_state(GameState.UPGRADE_SHOP)
	change_scene("res://scenes/upgrade_shop.tscn")

func go_to_game_over() -> void:
	set_state(GameState.GAME_OVER)
	change_scene("res://scenes/game_over.tscn")

func go_to_options() -> void:
	change_scene("res://scenes/options.tscn")

func go_to_tutorial() -> void:
	change_scene("res://scenes/tutorial.tscn")

func go_to_credits() -> void:
	change_scene("res://scenes/credits.tscn")

func get_story_scene_for_wave(wave: int) -> String:
	# Story-Akte gibt es nur im Story-Mode. Ohne diesen Guard spielten die
	# Akte im Endless-Mode faelschlich nach Welle 5/10/15 ab.
	if endless_mode:
		return ""
	match wave:
		5: return "res://scenes/story/act2_intro.tscn"
		10: return "res://scenes/story/act3_intro.tscn"
		15: return "res://scenes/story/finale.tscn"
		_: return ""

# -- Netzwerk Co-op ------------------------------------------------------------
var network_mode: int = 0  # 0=aus, 1=host, 2=client
var _net_peer: ENetMultiplayerPeer = null

signal net_peer_connected
signal net_connected_to_host

func net_start_host() -> String:
	_net_peer = ENetMultiplayerPeer.new()
	_net_peer.create_server(7777, 1)
	multiplayer.multiplayer_peer = _net_peer
	multiplayer.peer_connected.connect(_on_net_peer_connected)
	network_mode = 1
	player_count = 2
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172.16."):
			return ip
	return "0.0.0.0"

func net_join(ip: String) -> Error:
	_net_peer = ENetMultiplayerPeer.new()
	var err = _net_peer.create_client(ip, 7777)
	if err != OK:
		_net_peer = null
		return err
	multiplayer.multiplayer_peer = _net_peer
	multiplayer.connected_to_server.connect(_on_net_connected_to_host)
	network_mode = 2
	return OK

func net_stop() -> void:
	if _net_peer:
		_net_peer.close()
		_net_peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	network_mode = 0
	player_count = 1

func _on_net_peer_connected(_id: int) -> void:
	emit_signal("net_peer_connected")

func _on_net_connected_to_host() -> void:
	emit_signal("net_connected_to_host")

var net_seed: int = 0

# -- Telemetrie fuer den Client-Bildschirm (network_remote.tscn) ---------------
# Werden vom Host ueber RPC aktualisiert; Defaults verhindern dass das
# Remote-UI auf undefinierte Variablen zugreift.
var net_current_wave: int = 0
var net_p2_hp: int = 0
var net_p2_max_hp: int = 1

@rpc("any_peer", "unreliable_ordered")
func _rpc_recv_p2_input(_dx: float, _dy: float, _buttons: int) -> void:
	# Wird vom Client-Geraet aufgerufen; Host wendet Input auf P2 an.
	# Tatsaechliche Logik laeuft im game_scene-Script ueber Player._apply_net_input.
	pass

func net_start_game_as_host() -> void:
	net_seed = randi()
	player_count = 2
	rpc("_rpc_client_start_game", net_seed,
		selected_characters[0], selected_characters[1])
	start_game()

@rpc("authority", "reliable")
func _rpc_client_start_game(seed: int, p1_char: String, p2_char: String) -> void:
	net_seed = seed
	selected_characters[0] = p1_char
	selected_characters[1] = p2_char
	player_count = 2
	start_game()
