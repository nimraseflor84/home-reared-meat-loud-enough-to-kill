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

# ── Endless Mode ──────────────────────────────────────────────────────────────
var endless_mode: bool = false
var endless_map: String = "farm"

# ── Difficulty ────────────────────────────────────────────────────────────────
var difficulty: int = 2  # 0=VeryEasy … 4=VeryHard

const DIFFICULTY_NAMES = [
	"Access Denied",
	"Vomit Blood",
	"Brootal Destroy",
	"Drink Fight Die!",
	"Bolognese Bloodbath",
]
const DIFFICULTY_COLORS = [
	Color(0.20, 0.90, 0.30),   # grün
	Color(0.75, 0.90, 0.10),   # gelbgrün
	Color(1.00, 0.55, 0.05),   # orange
	Color(0.95, 0.15, 0.10),   # rot
	Color(0.60, 0.00, 0.10),   # dunkelblutrot
]
# HP-Multiplikator pro Schwierigkeitsgrad
const DIFFICULTY_HP   = [0.35, 0.65, 1.0, 1.6, 2.8]
# Schaden-Multiplikator
const DIFFICULTY_DMG  = [0.35, 0.65, 1.0, 1.4, 2.0]
# Gegneranzahl-Multiplikator
const DIFFICULTY_COUNT = [0.45, 0.70, 1.0, 1.45, 2.1]
# Wahrscheinlichkeit dass ein Gegner fernkämpft (0=nie)
const DIFFICULTY_SHOOT = [0.0, 0.0, 0.0, 0.40, 0.80]

# Character scene paths
const CHARACTER_SCENES = {
	"manni": "res://scenes/entities/players/player_manni.tscn",
	"shouter": "res://scenes/entities/players/player_shouter.tscn",
	"dreads": "res://scenes/entities/players/player_dreads.tscn",
	"riff_slicer": "res://scenes/entities/players/player_riff_slicer.tscn",
	"distortion": "res://scenes/entities/players/player_distortion.tscn",
	"bassist": "res://scenes/entities/players/player_bassist.tscn",
}

const CHARACTER_INFO = {
	"manni": {"name": "Manny", "desc": "Drumstick master. Kills increase attack speed.", "color": Color(0.2, 0.4, 0.9)},
	"shouter": {"name": "Chicken", "desc": "Growler. Low-frequency death beams. High precision.", "color": Color(0.9, 0.2, 0.2)},
	"dreads": {"name": "Nik", "desc": "Inhale Screamer. Dreadlock whip. Can grab & throw enemies.", "color": Color(0.2, 0.8, 0.3)},
	"riff_slicer": {"name": "Andz", "desc": "String blades pierce multiple enemies.", "color": Color(0.9, 0.5, 0.1)},
	"distortion": {"name": "Grindhouse", "desc": "Distortion fields slow nearby enemies.", "color": Color(0.6, 0.2, 0.9)},
	"bassist": {"name": "Armin", "desc": "Sub-bass waves. Ground shockwaves on kills.", "color": Color(0.1, 0.2, 0.6)},
}

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
	# UI-Aktionen mit Joypad belegen (Menü-Navigation & Bestätigung)
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

	# Linken Analog-Stick ebenfalls für UI-Navigation nutzen
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
	# SystemFont mit fettem Rock/Metal-Stil – Impact als Hauptfont, Fallbacks für alle Plattformen
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

	# Theme auf Root-Window setzen → alle Controls erben den Font automatisch
	var theme = Theme.new()
	theme.default_font = font
	theme.set_font("font", "Label",    font)
	theme.set_font("font", "Button",   font)
	theme.set_font("font", "LineEdit", font)
	theme.set_font("font", "RichTextLabel", font)
	# Schriftgrößen aus dem Theme übernehmen (individuelle Overrides bleiben erhalten)
	theme.set_font_size("font_size", "Label",    20)
	theme.set_font_size("font_size", "Button",   20)
	theme.default_font_size = 20

	call_deferred("_apply_theme", theme)

func _apply_theme(theme: Theme) -> void:
	if get_tree():
		get_tree().root.theme = theme

func reset_run_stats() -> void:
	run_stats = {
		"kills": 0,
		"rhythm_hits": 0,
		"damage_dealt": 0,
		"waves_cleared": 0,
		"upgrades_taken": [],
	}

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
	return pow(1.08, current_wave)

func get_wave_damage_multiplier() -> float:
	return pow(1.04, current_wave)

func change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

# Lautstärke-Widget in eine Szene einbetten (CanvasLayer damit immer im Vordergrund)
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
	change_scene("res://scenes/game.tscn")

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

func get_story_scene_for_wave(wave: int) -> String:
	match wave:
		5: return "res://scenes/story/act2_intro.tscn"
		10: return "res://scenes/story/act3_intro.tscn"
		15: return "res://scenes/story/finale.tscn"
		_: return ""
