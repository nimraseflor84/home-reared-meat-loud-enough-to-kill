extends Node2D

var player = null           # P1 – rückwärtskompatible Referenz
var _players: Array = []   # alle Spieler (1 oder 2)
var rhythm_system = null
var crowd_meter_sys = null
var wave_manager = null
var upgrade_manager = null
var hud: Control

var _wave_transition_timer: float = 0.0
var _in_transition: bool = false
var _between_waves: bool = false
var _game_over: bool = false
var _paused: bool = false
var _pause_overlay: CanvasLayer = null
var _pause_screen = null
var _pause_elevator = null

# Visual state
var _anim_time: float = 0.0
var _screen_flash: float = 0.0
var _screen_flash_color: Color = Color.WHITE
var _current_map: String = "farm"

# Farm – Traktor
var _tractor_dir: int      = 0      # 0=L→R  1=R→L  2=T→B  3=B→T
var _tractor_progress: float = 0.0  # 0..1 Fortschritt über den Bildschirm
var _tractor_active: bool  = false
var _tractor_next: float   = 1.8    # Sekunden bis zur nächsten Fahrt
var _tractor_lane: float   = 0.5    # Position auf der Querachse (normiert 0..1)
var _tractor_blood: Array  = []     # [{ox,oy,r}] Blutflecken relativ zum Traktor
var _tractor_hit_cd: float = 0.0    # Schadenskooldown
const _TRACTOR_DUR    = 3.8          # Sekunden für eine komplette Überfahrt
const _TRACTOR_HALF_W = 36.0        # Halbe Breite der Kollisionsbox
const _TRACTOR_HALF_H = 28.0

# Proberaum – Lichtflackern
var _probe_flicker: float      = 1.0
var _probe_flicker_timer: float = 0.0
var _probe_flicker_active: bool = false
var _probe_flicker_next: float  = 8.0

func _ready() -> void:
	_setup_systems()
	_setup_hud()
	_spawn_players()
	# Apply pending upgrade from shop if any
	var pending = GameManager.run_stats.get("pending_upgrade", "")
	if pending != "":
		GameManager.run_stats.erase("pending_upgrade")
		for p in _players:
			if is_instance_valid(p):
				p.apply_upgrade_by_id(pending)
	# Apply all previously selected upgrades to all players
	for uid in GameManager.run_stats.get("upgrades_taken", []):
		if uid != pending:
			for p in _players:
				if is_instance_valid(p):
					p.apply_upgrade_by_id(uid)
	var next_wave = GameManager.current_wave + 1
	_current_map = _get_map_for_wave(next_wave)
	_start_wave_with_delay(next_wave)
	AudioManager.start_music()
	GameManager.add_volume_widget(self)

func _setup_systems() -> void:
	rhythm_system = load("res://scripts/systems/rhythm_system.gd").new()
	get_node("RhythmSystem").add_child(rhythm_system)

	crowd_meter_sys = load("res://scripts/systems/crowd_meter.gd").new()
	get_node("CrowdMeter").add_child(crowd_meter_sys)

	wave_manager = load("res://scripts/systems/wave_manager.gd").new()
	get_node("WaveManager").add_child(wave_manager)

	upgrade_manager = load("res://scripts/systems/upgrade_manager.gd").new()
	get_node("UpgradeManager").add_child(upgrade_manager)

	wave_manager.connect("wave_completed", _on_wave_completed)
	rhythm_system.connect("rhythm_hit", _on_rhythm_hit)
	rhythm_system.connect("beat_occurred", _on_beat)
	crowd_meter_sys.connect("level_changed", _on_crowd_level_changed)

func _setup_hud() -> void:
	var hud_canvas = get_node("HUD/HUDRoot")

	var hp_bg = ColorRect.new()
	hp_bg.name = "HPBarBG"
	hp_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hp_bg.position = Vector2(20, 24)
	hp_bg.size = Vector2(200, 18)
	hp_bg.color = Color(0.2, 0.0, 0.0)
	hud_canvas.add_child(hp_bg)

	var hp_bar = ColorRect.new()
	hp_bar.name = "HPBar"
	hp_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hp_bar.position = Vector2(20, 24)
	hp_bar.size = Vector2(200, 18)
	hp_bar.color = Color(0.9, 0.1, 0.1)
	hud_canvas.add_child(hp_bar)

	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.position = Vector2(20, 4)
	hp_label.size = Vector2(200, 18)
	hp_label.text = LocalizationManager.t("hud_hp")
	hp_label.add_theme_color_override("font_color", Color(1, 0.8, 0.8))
	hud_canvas.add_child(hp_label)

	var crowd_bg = ColorRect.new()
	crowd_bg.name = "CrowdBG"
	crowd_bg.position = Vector2(20, 58)
	crowd_bg.size = Vector2(200, 14)
	crowd_bg.color = Color(0.1, 0.0, 0.2)
	hud_canvas.add_child(crowd_bg)

	var crowd_bar = ColorRect.new()
	crowd_bar.name = "CrowdBar"
	crowd_bar.position = Vector2(20, 58)
	crowd_bar.size = Vector2(0, 14)
	crowd_bar.color = Color(0.8, 0.3, 1.0)
	hud_canvas.add_child(crowd_bar)

	var crowd_label = Label.new()
	crowd_label.name = "CrowdLabel"
	crowd_label.position = Vector2(20, 44)
	crowd_label.size = Vector2(200, 16)
	crowd_label.text = LocalizationManager.t("hud_crowd")
	crowd_label.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
	hud_canvas.add_child(crowd_label)

	# P2-HP-Bar (nur im Co-op sichtbar)
	if GameManager.player_count >= 2:
		var hp_label2 = Label.new()
		hp_label2.name = "P2HPLabel"
		hp_label2.position = Vector2(20, 78)
		hp_label2.size = Vector2(200, 16)
		hp_label2.text = "P2 HP"
		hp_label2.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0))
		hp_label2.add_theme_font_size_override("font_size", 14)
		hud_canvas.add_child(hp_label2)

		var hp_bg2 = ColorRect.new()
		hp_bg2.name = "P2HPBarBG"
		hp_bg2.position = Vector2(20, 96)
		hp_bg2.size = Vector2(200, 14)
		hp_bg2.color = Color(0.1, 0.0, 0.2)
		hud_canvas.add_child(hp_bg2)

		var hp_bar2 = ColorRect.new()
		hp_bar2.name = "P2HPBar"
		hp_bar2.position = Vector2(20, 96)
		hp_bar2.size = Vector2(200, 14)
		hp_bar2.color = Color(0.6, 0.2, 1.0)
		hud_canvas.add_child(hp_bar2)

	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	score_label.anchor_left = 1.0
	score_label.anchor_right = 1.0
	score_label.position = Vector2(-220, 8)
	score_label.size = Vector2(200, 26)
	score_label.text = LocalizationManager.t("hud_score_prefix") + "0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_color_override("font_color", Color(1, 1, 0.5))
	hud_canvas.add_child(score_label)

	var wave_label = Label.new()
	wave_label.name = "WaveLabel"
	wave_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	wave_label.anchor_left = 1.0
	wave_label.anchor_right = 1.0
	wave_label.position = Vector2(-220, 38)
	wave_label.size = Vector2(200, 26)
	wave_label.text = LocalizationManager.t("hud_wave_prefix") + "1"
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wave_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	hud_canvas.add_child(wave_label)

	var diff_label = Label.new()
	diff_label.name = "DiffLabel"
	diff_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	diff_label.anchor_left = 1.0
	diff_label.anchor_right = 1.0
	diff_label.position = Vector2(-220, 68)
	diff_label.size = Vector2(200, 20)
	diff_label.text = GameManager.DIFFICULTY_NAMES[GameManager.difficulty]
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	diff_label.add_theme_color_override("font_color", GameManager.DIFFICULTY_COLORS[GameManager.difficulty])
	diff_label.add_theme_font_size_override("font_size", 13)
	hud_canvas.add_child(diff_label)

	var combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	combo_label.anchor_left = 0.5
	combo_label.anchor_right = 0.5
	combo_label.position = Vector2(-100, 20)
	combo_label.size = Vector2(200, 40)
	combo_label.text = ""
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	hud_canvas.add_child(combo_label)

	var beat_indicator = ColorRect.new()
	beat_indicator.name = "BeatIndicator"
	beat_indicator.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	beat_indicator.anchor_top = 1.0
	beat_indicator.anchor_bottom = 1.0
	beat_indicator.position = Vector2(230, -30)
	beat_indicator.size = Vector2(20, 20)
	beat_indicator.color = Color(0.5, 0.5, 0.5, 0.3)
	hud_canvas.add_child(beat_indicator)

	var ult_label = Label.new()
	ult_label.name = "UltLabel"
	ult_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ult_label.anchor_top = 1.0
	ult_label.anchor_bottom = 1.0
	ult_label.position = Vector2(20, -60)
	ult_label.size = Vector2(200, 30)
	ult_label.text = LocalizationManager.t("hud_ult_ready")
	ult_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
	hud_canvas.add_child(ult_label)

	# Enemy counter (oben rechts, unter DiffLabel)
	var enemy_lbl = Label.new()
	enemy_lbl.name = "EnemyLabel"
	enemy_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	enemy_lbl.anchor_left = 1.0
	enemy_lbl.anchor_right = 1.0
	enemy_lbl.position = Vector2(-220, 91)
	enemy_lbl.size = Vector2(200, 20)
	enemy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enemy_lbl.text = ""
	enemy_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	enemy_lbl.add_theme_font_size_override("font_size", 13)
	hud_canvas.add_child(enemy_lbl)

	# Pause-Button (oben Mitte)
	var pause_btn = Button.new()
	pause_btn.name = "PauseBtn"
	pause_btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pause_btn.anchor_left = 0.5
	pause_btn.anchor_right = 0.5
	pause_btn.position = Vector2(-28, 10)
	pause_btn.size = Vector2(56, 36)
	pause_btn.text = "II"
	pause_btn.add_theme_font_size_override("font_size", 18)
	var p_sty = StyleBoxFlat.new()
	p_sty.bg_color = Color(0.1, 0.1, 0.18, 0.80)
	p_sty.border_color = Color(0.5, 0.5, 0.7)
	p_sty.set_border_width_all(1)
	p_sty.set_corner_radius_all(5)
	pause_btn.add_theme_stylebox_override("normal", p_sty)
	pause_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_btn.pressed.connect(_toggle_pause)
	hud_canvas.add_child(pause_btn)

	hud = hud_canvas

func _spawn_players() -> void:
	var char_ids = []
	if GameManager.player_count >= 2:
		char_ids = [GameManager.selected_characters[0], GameManager.selected_characters[1]]
	else:
		char_ids = [GameManager.selected_character]

	var spawn = get_node_or_null("PlayerSpawnPoint")
	var base_pos = spawn.global_position if spawn else Vector2(640, 360)
	# P1 leicht links, P2 leicht rechts vom Mittelpunkt
	var spawn_offsets = [Vector2(-60, 0), Vector2(60, 0)]

	for i in range(char_ids.size()):
		var char_id = char_ids[i]
		var scene_path = GameManager.CHARACTER_SCENES.get(char_id, GameManager.CHARACTER_SCENES["manni"])
		var pscene = load(scene_path)
		if not pscene:
			continue
		var p = pscene.instantiate()
		p.global_position = base_pos + spawn_offsets[i]
		p.player_index = i
		if i == 1:
			p._joy_device = 1  # P2 nutzt immer Joypad 1
		add_child(p)
		p.add_to_group("players")
		p.connect("died",         _on_player_died.bind(i))
		p.connect("hp_changed",   _on_player_hp_changed.bind(i))
		p.connect("attacked",     _on_player_attacked)
		p.connect("ultimate_used", _on_player_ultimate)
		_players.append(p)
		if i == 0:
			player = p
	if is_instance_valid(player):
		upgrade_manager.set_player(player)

func _start_wave_with_delay(wave_num: int) -> void:
	_in_transition = true
	_wave_transition_timer = 2.5
	_show_wave_banner(wave_num)

func _show_wave_banner(wave_num: int) -> void:
	if not hud:
		return
	# Remove old banner if exists
	var old = hud.get_node_or_null("WaveBanner")
	if old:
		old.queue_free()
	var old_sub = hud.get_node_or_null("LocationBanner")
	if old_sub:
		old_sub.queue_free()

	# Wave banner
	var banner = Label.new()
	banner.name = "WaveBanner"
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.anchor_left = 0.5
	banner.anchor_right = 0.5
	banner.anchor_top = 0.5
	banner.anchor_bottom = 0.5
	banner.position = Vector2(-200, -80)
	banner.size = Vector2(400, 60)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _is_boss_wave(wave_num):
		banner.text = LocalizationManager.t("boss_wave_banner") % [wave_num]
		banner.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	else:
		banner.text = LocalizationManager.t("wave_banner") % [wave_num]
		banner.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	banner.add_theme_font_size_override("font_size", 48)
	hud.add_child(banner)

	# Location subtitle banner
	var map_id = _get_map_for_wave(wave_num)
	var map_info = _MAP_INFO.get(map_id, {})
	var loc_banner = Label.new()
	loc_banner.name = "LocationBanner"
	loc_banner.set_anchors_preset(Control.PRESET_CENTER)
	loc_banner.anchor_left = 0.5
	loc_banner.anchor_right = 0.5
	loc_banner.anchor_top = 0.5
	loc_banner.anchor_bottom = 0.5
	loc_banner.position = Vector2(-250, -20)
	loc_banner.size = Vector2(500, 36)
	loc_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loc_banner.text = map_info.get("title", "") + "  –  " + map_info.get("subtitle", "")
	loc_banner.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	loc_banner.add_theme_font_size_override("font_size", 18)
	hud.add_child(loc_banner)

	var timer = get_tree().create_timer(2.5, false)
	timer.connect("timeout", func():
		if is_instance_valid(banner): banner.queue_free()
		if is_instance_valid(loc_banner): loc_banner.queue_free()
	)

	if _is_boss_wave(wave_num):
		var boss_warn_timer = get_tree().create_timer(2.6, false)
		boss_warn_timer.connect("timeout", _show_boss_warning)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action_pressed("ui_cancel") and not event.is_echo() and not _game_over and not _between_waves and not _in_transition:
		_toggle_pause()

func _toggle_pause() -> void:
	_paused = not _paused
	get_tree().paused = _paused
	if _paused:
		AudioManager.pause_music()
		AudioManager.play_elevator_music()
		_show_pause_overlay()
	else:
		AudioManager.stop_elevator_music()
		AudioManager.resume_music()
		_hide_pause_overlay()

func _show_pause_overlay() -> void:
	if is_instance_valid(_pause_overlay):
		_pause_overlay.visible = true
		if is_instance_valid(_pause_elevator):
			_pause_elevator.reset()
		if _pause_screen:
			_pause_screen.restart()
		return

	_pause_overlay = CanvasLayer.new()
	_pause_overlay.layer = 20
	_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_overlay)

	# Elevator animation as the bottom layer — Node2D _draw() is reliable
	var ElevatorClass = load("res://scripts/ui/elevator_scene.gd")
	if ElevatorClass:
		_pause_elevator = ElevatorClass.new()
		_pause_elevator.process_mode = Node.PROCESS_MODE_ALWAYS
		_pause_overlay.add_child(_pause_elevator)

	# Pause screen UI on top (black fade + buttons only, no elevator loading)
	var PauseScreenClass = load("res://scripts/ui/pause_screen.gd")
	_pause_screen = PauseScreenClass.new()
	_pause_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_overlay.add_child(_pause_screen)

	_pause_screen.resume_requested.connect(_toggle_pause)
	_pause_screen.main_menu_requested.connect(func():
		get_tree().paused = false
		_paused = false
		AudioManager.stop_elevator_music()
		GameManager.go_to_main_menu()
	)

func _hide_pause_overlay() -> void:
	if is_instance_valid(_pause_overlay):
		_pause_overlay.visible = false

func _process(delta: float) -> void:
	if _paused:
		return
	_anim_time += delta
	if _screen_flash > 0:
		_screen_flash -= delta * 3.0
	queue_redraw()

	if _current_map == "farm":
		_update_tractor(delta)
	if _current_map == "proberaum":
		_update_probe_flicker(delta)

	if _in_transition:
		_wave_transition_timer -= delta
		if _wave_transition_timer <= 0:
			_in_transition = false
			var next_wave = GameManager.current_wave + 1
			_current_map = _get_map_for_wave(next_wave)
			wave_manager.start_wave(next_wave)
			_update_wave_label(next_wave)
		return

	if _between_waves:
		return

	_update_hud(delta)

func _update_hud(_delta: float) -> void:
	if not hud:
		return

	var score_lbl = hud.get_node_or_null("ScoreLabel")
	if score_lbl:
		score_lbl.text = LocalizationManager.t("hud_score_prefix") + str(GameManager.score)

	var crowd_bar = hud.get_node_or_null("CrowdBar")
	if crowd_bar:
		crowd_bar.size.x = 200 * crowd_meter_sys.fill

	var ult_lbl = hud.get_node_or_null("UltLabel")
	if ult_lbl and is_instance_valid(player):
		if player.ultimate_timer <= 0:
			ult_lbl.text = LocalizationManager.t("hud_ult_ready")
			ult_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
		else:
			ult_lbl.text = "E: Ultimate [%.1fs]" % player.ultimate_timer
			ult_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	var beat_ind = hud.get_node_or_null("BeatIndicator")
	if beat_ind:
		var progress = rhythm_system.get_beat_progress()
		var pulse = abs(sin(progress * PI))
		beat_ind.color = Color(pulse, pulse * 0.5, 0.1, 0.8)

	var enemy_lbl = hud.get_node_or_null("EnemyLabel")
	if enemy_lbl and wave_manager.wave_active:
		var remaining = wave_manager._enemies_to_spawn - wave_manager.enemies_killed
		var alive = wave_manager._alive_enemies
		if alive > 0:
			enemy_lbl.text = str(alive) + LocalizationManager.t("hud_enemies_left")
		elif remaining > 0:
			enemy_lbl.text = str(remaining) + LocalizationManager.t("hud_enemies_spawn")
		else:
			enemy_lbl.text = ""
	elif enemy_lbl:
		enemy_lbl.text = ""

func _update_wave_label(wave_num: int) -> void:
	var wave_lbl = hud.get_node_or_null("WaveLabel")
	if wave_lbl:
		wave_lbl.text = LocalizationManager.t("hud_wave_prefix") + str(wave_num)

# ─────────────────────────────────────────────────────────────────────────────
# DRAW – Map-Hintergrund + Screen-Flash
# ─────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var vp = get_viewport_rect()
	_draw_map_background(vp)

	if _screen_flash > 0:
		draw_rect(Rect2(Vector2.ZERO, vp.size),
			Color(_screen_flash_color.r, _screen_flash_color.g, _screen_flash_color.b, _screen_flash * 0.15))

func _draw_map_background(vp: Rect2) -> void:
	match _current_map:
		"farm":         _draw_farm(vp)
		"prison":       _draw_prison(vp)
		"proberaum":    _draw_proberaum(vp)
		"schweinestall":_draw_schweinestall(vp)
		"amerika":      _draw_amerika(vp)
		"truck":        _draw_truck(vp)
		"tonstudio":    _draw_tonstudio(vp)
		"tv_studio":    _draw_tv_studio(vp)
		"meppen":       _draw_meppen(vp)
		"death_feast":  _draw_death_feast(vp)
		_:              _draw_farm(vp)

# ── Farm ─────────────────────────────────────────────────────────────────────
func _draw_farm(vp: Rect2) -> void:
	# ── Luftbild-Perspektive: Blick von oben auf den Hof ─────────────────────
	var w = vp.size.x
	var h = vp.size.y
	# Gras (gesamter Hintergrund)
	draw_rect(Rect2(0, 0, w, h), Color(0.28, 0.50, 0.18))
	# Feldstreifen an Rändern (oben/unten)
	for i in range(6):
		var fx2 = i * (w / 6.0)
		draw_rect(Rect2(fx2, 0,       w/6.0 - 2, h * 0.18), Color(0.22 + (i%2)*0.08, 0.44 + (i%2)*0.06, 0.12))
		draw_rect(Rect2(fx2, h*0.82,  w/6.0 - 2, h * 0.18), Color(0.22 + (i%2)*0.08, 0.44 + (i%2)*0.06, 0.12))
	# Zentraler Hofplatz (Erde)
	draw_rect(Rect2(w*0.18, h*0.18, w*0.64, h*0.64), Color(0.52, 0.38, 0.20))
	# Schlammpfütze Mitte
	draw_ellipse_approx(Vector2(w*0.5, h*0.5), Vector2(75, 40), Color(0.38, 0.26, 0.12))
	# Zaunpfosten + Latten (Draufsicht)
	for i in range(15):
		var fx2 = w*0.18 + i * (w*0.64/14.0)
		draw_rect(Rect2(fx2 - 3, h*0.16, 6, 12), Color(0.44, 0.28, 0.12))
		draw_rect(Rect2(fx2 - 3, h*0.80, 6, 12), Color(0.44, 0.28, 0.12))
	draw_line(Vector2(w*0.18, h*0.20), Vector2(w*0.82, h*0.20), Color(0.44, 0.28, 0.12), 3)
	draw_line(Vector2(w*0.18, h*0.80), Vector2(w*0.82, h*0.80), Color(0.44, 0.28, 0.12), 3)
	# Scheunendach von oben (dunkelrot, mit Firstlinie)
	draw_rect(Rect2(w*0.04, h*0.28, 130, 90), Color(0.52, 0.10, 0.08))
	draw_line(Vector2(w*0.04+65, h*0.28), Vector2(w*0.04+65, h*0.28+90), Color(0.35, 0.06, 0.05), 6)
	draw_rect(Rect2(w*0.04+45, h*0.28+30, 38, 28), Color(0.20, 0.12, 0.06))
	# Heuballen (Draufsicht: Kreise mit Spiralrillen)
	for i in range(4):
		var hbx = w*0.28 + i * 110.0
		var hby = h * 0.30
		draw_circle(Vector2(hbx, hby), 20, Color(0.75, 0.62, 0.20))
		draw_arc(Vector2(hbx, hby), 13, 0, TAU, 8, Color(0.58, 0.46, 0.12), 2)
		draw_arc(Vector2(hbx, hby),  7, 0, TAU, 6, Color(0.58, 0.46, 0.12), 1.5)
	# Hühnerstall (kleines Gebäude, Draufsicht)
	draw_rect(Rect2(w*0.76, h*0.24, 75, 55), Color(0.58, 0.46, 0.26))
	draw_line(Vector2(w*0.76+37, h*0.24), Vector2(w*0.76+37, h*0.24+55), Color(0.45, 0.34, 0.16), 4)
	# Wassertränke
	draw_rect(Rect2(w*0.74, h*0.58, 48, 20), Color(0.36, 0.26, 0.14))
	draw_rect(Rect2(w*0.74+3, h*0.58+3, 42, 14), Color(0.26, 0.46, 0.62))
	# Traktorspuren (Reifenspuren über den Hofplatz)
	draw_line(Vector2(0, h*0.44), Vector2(w, h*0.44), Color(0.45, 0.32, 0.16, 0.45), 5)
	draw_line(Vector2(0, h*0.52), Vector2(w, h*0.52), Color(0.45, 0.32, 0.16, 0.45), 5)

	# ── TRAKTOR – zufällige Richtungen ──────────────────────────────────────────
	if _tractor_active:
		var tp  = _get_tractor_world_pos()
		var ang := 0.0
		match _tractor_dir:
			0: ang =  0.0        # L→R
			1: ang =  PI         # R→L
			2: ang =  PI * 0.5   # T→B
			3: ang = -PI * 0.5   # B→T

		# Reifenspuren hinter dem Traktor (Weltkoordinaten, VOR Transform)
		_draw_tractor_tracks(tp, ang)

		# Traktor-Body mit Rotations-Transform zeichnen
		draw_set_transform(tp, ang, Vector2.ONE)
		draw_rect(Rect2(-32, -24,  64, 48), Color(0.12, 0.40, 0.12))         # Karosserie
		draw_rect(Rect2(-14, -18,  28, 22), Color(0.08, 0.28, 0.08))         # Kabine
		_draw_ellipse(Vector2(-22, -24), Vector2( 8, 5), Color(0.08, 0.08, 0.10))  # Rad vl
		_draw_ellipse(Vector2( 22, -24), Vector2( 8, 5), Color(0.08, 0.08, 0.10))  # Rad vr
		_draw_ellipse(Vector2(-28,  20), Vector2(12, 7), Color(0.08, 0.08, 0.10))  # Rad hl
		_draw_ellipse(Vector2( 28,  20), Vector2(12, 7), Color(0.08, 0.08, 0.10))  # Rad hr
		for si in range(3):  # Abgaswolke hinten
			draw_circle(Vector2(-38 - si*14, -10), 5 + si*3,
				Color(0.62, 0.60, 0.58, 0.38 - si*0.10))
		for bd in _tractor_blood:  # Blutflecken
			draw_circle(Vector2(bd.ox, bd.oy), bd.r, Color(0.68, 0.04, 0.04, 0.82))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)  # Transform zurücksetzen

# ── Traktor-Logik ─────────────────────────────────────────────────────────────
func _get_tractor_world_pos() -> Vector2:
	var vp := get_viewport_rect()
	var p   := _tractor_progress
	match _tractor_dir:
		0: return Vector2(-120.0 + p * (vp.size.x + 240.0), _tractor_lane * vp.size.y)
		1: return Vector2(vp.size.x + 120.0 - p * (vp.size.x + 240.0), _tractor_lane * vp.size.y)
		2: return Vector2(_tractor_lane * vp.size.x, -120.0 + p * (vp.size.y + 240.0))
		_: return Vector2(_tractor_lane * vp.size.x, vp.size.y + 120.0 - p * (vp.size.y + 240.0))

func _draw_tractor_tracks(tp: Vector2, ang: float) -> void:
	var vp  := get_viewport_rect()
	var col := Color(0.38, 0.26, 0.10, 0.55)
	# Spuroffset senkrecht zur Fahrtrichtung
	var perp := Vector2(-sin(ang), cos(ang))
	var s1   := tp + perp * (-18.0)   # linke Spur
	var s2   := tp + perp *  14.0     # rechte Spur
	var fwd  := Vector2(cos(ang), sin(ang))
	match _tractor_dir:
		0:  # L→R – Spur von linkem Rand bis Traktor
			draw_line(Vector2(0.0, s1.y), s1 - fwd * 32.0, col, 5)
			draw_line(Vector2(0.0, s2.y), s2 - fwd * 32.0, col, 5)
		1:  # R→L – Spur von rechtem Rand bis Traktor
			draw_line(Vector2(vp.size.x, s1.y), s1 - fwd * 32.0, col, 5)
			draw_line(Vector2(vp.size.x, s2.y), s2 - fwd * 32.0, col, 5)
		2:  # T→B – Spur von obem Rand bis Traktor
			draw_line(Vector2(s1.x, 0.0), s1 - fwd * 24.0, col, 5)
			draw_line(Vector2(s2.x, 0.0), s2 - fwd * 24.0, col, 5)
		3:  # B→T – Spur von unterem Rand bis Traktor
			draw_line(Vector2(s1.x, vp.size.y), s1 - fwd * 24.0, col, 5)
			draw_line(Vector2(s2.x, vp.size.y), s2 - fwd * 24.0, col, 5)

func _update_tractor(delta: float) -> void:
	if _tractor_hit_cd > 0.0:
		_tractor_hit_cd -= delta

	if _tractor_active:
		_tractor_progress += delta / _TRACTOR_DUR
		if _tractor_progress >= 1.0:
			_tractor_active   = false
			_tractor_progress = 0.0
			_tractor_blood.clear()
			_tractor_next = randf_range(3.0, 8.0)
		else:
			# Schaden wenn Spieler getroffen wird
			if _tractor_hit_cd <= 0.0 and not _in_transition and not _between_waves and not _game_over:
				var tp := _get_tractor_world_pos()
				for p in _players:
					if is_instance_valid(p) and p.is_alive and p.global_position.distance_to(tp) < 46.0:
						var dmg: float = (p.max_hp + p.max_hp_bonus) * 0.10
						p.take_damage(dmg)
						_tractor_blood.append({
							"ox": randf_range(-22.0, 22.0),
							"oy": randf_range(-16.0, 16.0),
							"r":  randf_range(4.0, 9.0),
						})
						_tractor_hit_cd = 1.2
						break
	else:
		_tractor_next -= delta
		if _tractor_next <= 0.0:
			_tractor_active   = true
			_tractor_progress = 0.0
			_tractor_dir      = randi() % 4
			_tractor_lane     = randf_range(0.30, 0.70)

func _update_probe_flicker(delta: float) -> void:
	if _probe_flicker_active:
		_probe_flicker_timer += delta
		_probe_flicker = 0.08 + abs(sin(_probe_flicker_timer * 22.0)) * 0.75
		if _probe_flicker_timer >= 1.4:
			_probe_flicker_active = false
			_probe_flicker        = 1.0
			_probe_flicker_next   = randf_range(7.0, 20.0)
	else:
		_probe_flicker_next -= delta
		if _probe_flicker_next <= 0.0:
			_probe_flicker_active = true
			_probe_flicker_timer  = 0.0

# ── Gefaengnis ───────────────────────────────────────────────────────────────
func _draw_prison(vp: Rect2) -> void:
	var w = vp.size.x
	var h = vp.size.y
	var t = _anim_time

	# === BETONWÄNDE (verwittert, mit Moos und Rissen) ===
	draw_rect(Rect2(0, 0, w, h), Color(0.20, 0.19, 0.22))
	var brng = RandomNumberGenerator.new()
	brng.seed = 4242
	for row in range(11):
		var off = 70 if row % 2 == 1 else 0
		for col in range(10):
			var bx = col * 140 - off - 10
			var by = row * 66
			var s = brng.randf_range(0.0, 0.05)
			draw_rect(Rect2(bx + 2, by + 2, 134, 62), Color(0.28 + s, 0.27 + s, 0.30 + s))
			if brng.randf() < 0.28:
				var mx = float(bx + 8 + brng.randi_range(0, 80))
				var my = float(by + 6 + brng.randi_range(0, 42))
				draw_circle(Vector2(mx, my), brng.randf_range(3.0, 10.0), Color(0.18, 0.26, 0.14, 0.30))
			if brng.randf() < 0.18:
				var cx = float(bx + brng.randi_range(10, 120))
				var cy = float(by + brng.randi_range(5, 55))
				draw_line(Vector2(cx, cy),
					Vector2(cx + brng.randf_range(-18.0, 18.0), cy + brng.randf_range(6.0, 22.0)),
					Color(0.14, 0.13, 0.16, 0.65), 1.0)
	# Fugen
	for row in range(12):
		draw_line(Vector2(0, row * 66), Vector2(w, row * 66), Color(0.11, 0.10, 0.13), 2.0)

	# === FLACKERNDE LEUCHTSTOFFRÖHREN ===
	var fl1 = 1.0
	if fmod(t, 8.3) < 0.20:
		fl1 = abs(sin(t * 55.0)) * 0.25
	var fl3 = clamp(0.35 + sin(t * 13.0) * 0.4 + sin(t * 5.7) * 0.25, 0.05, 1.0)
	var lamp_xs = [w * 0.22, w * 0.5, w * 0.78]
	var lamp_fls = [fl1, 1.0, fl3]
	for i in range(3):
		var lx = lamp_xs[i]
		var fl = lamp_fls[i]
		draw_line(Vector2(lx, 0), Vector2(lx, 5), Color(0.25, 0.24, 0.27), 2.0)
		draw_rect(Rect2(lx - 44, 4, 88, 8), Color(0.35, 0.34, 0.38))
		draw_rect(Rect2(lx - 40, 6, 80, 4), Color(0.82 * fl, 0.88 * fl, 0.78 * fl))
		var lpts = PackedVector2Array([
			Vector2(lx - 44, 12), Vector2(lx + 44, 12),
			Vector2(lx + 170, h * 0.62), Vector2(lx - 170, h * 0.62),
		])
		draw_colored_polygon(lpts, Color(0.88, 0.92, 0.78, 0.05 * fl))

	# === GITTERSTÄBE ===
	for i in range(15):
		var bx = i * 90.0 + 20
		draw_line(Vector2(bx + 4, 0), Vector2(bx + 4, h), Color(0.0, 0.0, 0.0, 0.28), 4.0)
		draw_line(Vector2(bx, 0), Vector2(bx, h), Color(0.20, 0.20, 0.23, 0.95), 5.0)
		draw_line(Vector2(bx - 1, 0), Vector2(bx - 1, h), Color(0.44, 0.44, 0.50, 0.35), 1.5)
	# Horizontale Querstreben
	for y in [h * 0.25, h * 0.5, h * 0.75]:
		draw_rect(Rect2(0, y - 5, w, 10), Color(0.15, 0.15, 0.18))
		draw_line(Vector2(0, y - 5), Vector2(w, y - 5), Color(0.32, 0.32, 0.36, 0.5), 1.5)

	# === ZELLENINHALT (Silhouetten) ===
	# Metallbett rechts
	var bed_x = w * 0.72; var bed_y = h * 0.30
	draw_rect(Rect2(bed_x - 4, bed_y - 18, 4, 40), Color(0.20, 0.19, 0.22))
	draw_rect(Rect2(bed_x + 86, bed_y - 18, 4, 40), Color(0.20, 0.19, 0.22))
	draw_rect(Rect2(bed_x, bed_y - 18, 86, 5), Color(0.20, 0.19, 0.22))
	draw_rect(Rect2(bed_x, bed_y, 86, 14), Color(0.14, 0.12, 0.10))
	draw_rect(Rect2(bed_x, bed_y, 86, 5), Color(0.24, 0.19, 0.15, 0.6))
	# Toilette links
	var tlt_x = w * 0.10; var tlt_y = h * 0.62
	draw_rect(Rect2(tlt_x - 8, tlt_y - 4, 18, 5), Color(0.40, 0.39, 0.44))
	draw_circle(Vector2(tlt_x, tlt_y + 4), 11, Color(0.38, 0.37, 0.42))
	draw_rect(Rect2(tlt_x - 8, tlt_y + 12, 16, 14), Color(0.32, 0.30, 0.35))
	# Graffiti-Strichliste (Tage gezählt)
	var gx0 = w * 0.54; var gy0 = h * 0.36
	for gi in range(10):
		var gsx = gx0 + (gi % 5) * 9.0
		var gsy = gy0 + (gi / 5) * 26.0
		if (gi % 5) < 4:
			draw_line(Vector2(gsx, gsy), Vector2(gsx, gsy + 18), Color(0.62, 0.56, 0.48, 0.55), 2.0)
		else:
			draw_line(Vector2(gsx - 28, gsy + 9), Vector2(gsx + 4, gsy + 9), Color(0.62, 0.56, 0.48, 0.55), 2.0)
	# Rotes Grafitti-X
	var gxr = w * 0.35; var gyr = h * 0.44
	draw_line(Vector2(gxr - 10, gyr - 10), Vector2(gxr + 10, gyr + 10), Color(0.70, 0.10, 0.06, 0.55), 3.0)
	draw_line(Vector2(gxr + 10, gyr - 10), Vector2(gxr - 10, gyr + 10), Color(0.70, 0.10, 0.06, 0.55), 3.0)

	# === SICHERHEITSKAMERA (schwenkt hin und her) ===
	var cam_sw  = sin(t * 0.55) * 55.0
	var cam_x   = w * 0.5 + cam_sw
	draw_rect(Rect2(w * 0.5 - 2, 0, 4, 22), Color(0.20, 0.19, 0.22))
	draw_rect(Rect2(cam_x - 14, 20, 28, 14), Color(0.14, 0.13, 0.16))
	draw_circle(Vector2(cam_x, 28), 6, Color(0.06, 0.06, 0.08))
	draw_circle(Vector2(cam_x, 28), 3, Color(0.04, 0.20, 0.40, 0.9))
	if int(t * 1.2) % 2 == 0:
		draw_circle(Vector2(cam_x + 11, 22), 3, Color(0.90, 0.06, 0.04))
	var ray_pts = PackedVector2Array([
		Vector2(cam_x - 5, 34), Vector2(cam_x + 5, 34),
		Vector2(cam_x + 38, 94), Vector2(cam_x - 38, 94),
	])
	draw_colored_polygon(ray_pts, Color(1.0, 0.85, 0.3, 0.10))

	# === SUCHSCHEINWERFER ===
	var sw_x = w * 0.5 + cos(t * 0.58) * w * 0.36
	var sw_pts = PackedVector2Array([
		Vector2(sw_x, 0),
		Vector2(sw_x - 110, h * 0.52),
		Vector2(sw_x + 110, h * 0.52),
	])
	draw_colored_polygon(sw_pts, Color(1.0, 0.96, 0.65, 0.07))
	draw_circle(Vector2(sw_x, 0), 9, Color(1.0, 0.96, 0.72, 0.6))

	# === BODEN (nass, Pfützen, Fugen) ===
	draw_rect(Rect2(0, h * 0.84, w, h * 0.16), Color(0.15, 0.14, 0.17))
	for fi in range(9):
		draw_line(Vector2(fi * 145.0, h * 0.84), Vector2(fi * 145.0, h), Color(0.10, 0.09, 0.12, 0.5), 1.5)
	draw_line(Vector2(0, h * 0.915), Vector2(w, h * 0.915), Color(0.10, 0.09, 0.12, 0.4), 1.5)
	# Pfützen mit animierten Tropfen-Wellen
	var puddle_data = [
		[w * 0.18, h * 0.88, 26.0, 13.0, 0.0],
		[w * 0.55, h * 0.91, 32.0, 12.0, 0.35],
		[w * 0.82, h * 0.87, 20.0, 10.0, 0.7],
	]
	for pd in puddle_data:
		var px = pd[0]; var py = pd[1]; var prw = pd[2]; var prh = pd[3]; var poffs = pd[4]
		var ppts = PackedVector2Array()
		for pi in range(12):
			var pa = float(pi) / 12.0 * TAU
			ppts.append(Vector2(px + cos(pa) * prw, py + sin(pa) * prh))
		draw_colored_polygon(ppts, Color(0.10, 0.12, 0.16, 0.55))
		draw_circle(Vector2(px - prw * 0.3, py - prh * 0.2), prh * 0.28, Color(0.50, 0.54, 0.60, 0.28))
		var drop_t = fmod(t * 0.75 + poffs, 1.0)
		var wave_r = drop_t * prw * 0.85
		if wave_r > 2.0:
			draw_arc(Vector2(px, py), wave_r, 0.0, TAU, 14, Color(0.35, 0.40, 0.50, (1.0 - drop_t) * 0.45), 1.2)

	# === DYNAMISCHES EVENT: Alarm-Sirene (alle 20 s) ===
	var et_prison = fmod(t, 20.0)
	if et_prison < 3.5:
		var flash_a = abs(sin(et_prison * 8.5)) * 0.24
		draw_rect(Rect2(0, 0, w, h), Color(0.95, 0.08, 0.06, flash_a))
		# Rotierende Alarmleuchten (2 Stück)
		var al_angle = et_prison * 6.0
		for ai in range(2):
			var al_x = w * (0.25 + float(ai) * 0.5)
			var al_pts = PackedVector2Array([
				Vector2(al_x, 0),
				Vector2(al_x + cos(al_angle + float(ai) * PI) * 150, h * 0.42),
				Vector2(al_x + cos(al_angle + float(ai) * PI + 0.55) * 150, h * 0.42),
			])
			draw_colored_polygon(al_pts, Color(1.0, 0.10, 0.05, 0.30))
		if int(et_prison * 4.0) % 2 == 0:
			draw_rect(Rect2(0, 0, w, 6), Color(1.0, 0.06, 0.06, 0.92))
			draw_rect(Rect2(0, h - 6, w, 6), Color(1.0, 0.06, 0.06, 0.92))

# ── Proberaum ────────────────────────────────────────────────────────────────
func _draw_proberaum(vp: Rect2) -> void:
	var w  = vp.size.x
	var h  = vp.size.y
	var t  = _anim_time
	var fl = _probe_flicker

	# ── Raum-Grundstruktur ─────────────────────────────────────────────────
	# Hinterwand (Schaumstoff-Platten, dunkelbraun)
	draw_rect(Rect2(0, 0, w, h * 0.62), Color(0.14 * fl, 0.11 * fl, 0.09 * fl))
	# Boden (verschlissener dunkelroter Teppich)
	for i in range(9):
		draw_rect(Rect2(i * (w / 8.5), h * 0.62, w / 8.5 - 1, h * 0.38),
			Color(0.26 + (i % 2) * 0.04, 0.06 + (i % 2) * 0.02, 0.06))
	# Decke
	draw_rect(Rect2(0, 0, w, 16), Color(0.10, 0.08, 0.07))
	# Schaumstoff-Raster an der Wand
	for j in range(5):
		var py = 16.0 + j * (h * 0.62 - 16) / 5.0
		draw_line(Vector2(0, py), Vector2(w, py), Color(0.07 * fl, 0.05 * fl, 0.04 * fl), 2.0)
	for i in range(10):
		var px = i * (w / 9.0)
		draw_line(Vector2(px, 16), Vector2(px, h * 0.62), Color(0.07 * fl, 0.05 * fl, 0.04 * fl), 2.0)

	# ── Deckenlicht (flackernd) ────────────────────────────────────────────
	for li in range(2):
		var lx = w * 0.28 + li * w * 0.44
		draw_rect(Rect2(lx - 18, 0, 36, 12), Color(0.22, 0.18, 0.14))
		draw_rect(Rect2(lx - 12, 12, 24, 8), Color(fl, fl * 0.92, fl * 0.72))
		draw_colored_polygon(PackedVector2Array([
			Vector2(lx - 10, 20), Vector2(lx + 10, 20),
			Vector2(lx + 110, h * 0.62), Vector2(lx - 110, h * 0.62),
		]), Color(fl * 0.14, fl * 0.13, fl * 0.10, 0.13))

	# ── Verstärker-Stack LINKS (Gitarre) ───────────────────────────────────
	for row in range(2):
		var ay = h * 0.20 + row * 82
		draw_rect(Rect2(22, ay, 92, 78), Color(0.08, 0.06, 0.05))
		draw_rect(Rect2(26, ay + 4, 84, 12), Color(0.16 * fl, 0.10 * fl, 0.07 * fl))
		draw_circle(Vector2(68, ay + 44), 25, Color(0.05, 0.04, 0.04))
		draw_circle(Vector2(68, ay + 44), 16, Color(0.11 * fl, 0.10 * fl, 0.11 * fl))
	# Logo-Streifen am Amp
	draw_rect(Rect2(24, h * 0.20 + 14, 88, 10), Color(0.18, 0.06, 0.04))

	# Gitarre 1 auf Ständer – Strat-Style, rot (kürzer als Bass)
	var gx = 128.0; var gy = h * 0.44
	draw_circle(Vector2(gx, gy),      13, Color(0.58, 0.08, 0.06))       # unterer Body
	draw_circle(Vector2(gx, gy - 22), 10, Color(0.58, 0.08, 0.06))       # oberer Body (Strat-Doppelausschnitt)
	draw_rect(Rect2(gx - 3, gy - 72, 6, 51), Color(0.45, 0.28, 0.10))   # Hals
	draw_rect(Rect2(gx - 5, gy - 80, 12, 9), Color(0.38, 0.22, 0.08))   # Kopfplatte
	for si in range(6):
		draw_line(Vector2(gx - 2 + si * 0.7, gy - 70),
			Vector2(gx - 2 + si * 0.6, gy - 10), Color(0.65, 0.65, 0.68, 0.8), 0.7)
	draw_line(Vector2(gx, gy + 13), Vector2(gx - 12, gy + 32), Color(0.45, 0.42, 0.40), 2)
	draw_line(Vector2(gx, gy + 13), Vector2(gx + 12, gy + 32), Color(0.45, 0.42, 0.40), 2)

	# Kleiner Combo-Amp (für Gitarre 2)
	var ca_x = 156.0; var ca_y = h * 0.30
	draw_rect(Rect2(ca_x, ca_y, 68, 56), Color(0.07, 0.05, 0.06))
	draw_rect(Rect2(ca_x + 4, ca_y + 3, 60, 9), Color(0.15 * fl, 0.09 * fl, 0.06 * fl))
	draw_circle(Vector2(ca_x + 34, ca_y + 37), 16, Color(0.04, 0.04, 0.05))
	draw_circle(Vector2(ca_x + 34, ca_y + 37), 10, Color(0.10 * fl, 0.10 * fl, 0.11 * fl))
	draw_rect(Rect2(ca_x + 4, ca_y + 14, 10, 6), Color(0.22, 0.10, 0.04))  # Logo-Streifen

	# Gitarre 2 auf Ständer – Les-Paul-Style, Sunburst (kürzer als Bass)
	var gx2 = 194.0; var gy2 = h * 0.44
	draw_circle(Vector2(gx2, gy2),      14, Color(0.52, 0.18, 0.03))      # Body groß
	draw_circle(Vector2(gx2, gy2),       8, Color(0.22, 0.06, 0.01))      # Sunburst-Kern
	draw_circle(Vector2(gx2 - 5, gy2 - 17), 9, Color(0.52, 0.18, 0.03))  # Obere Schulter
	draw_rect(Rect2(gx2 - 3, gy2 - 70, 5, 53), Color(0.42, 0.24, 0.08))  # Hals
	draw_rect(Rect2(gx2 - 5, gy2 - 78, 11, 9), Color(0.35, 0.18, 0.06))  # Kopfplatte
	for si in range(6):
		draw_line(Vector2(gx2 - 2 + si * 0.65, gy2 - 68),
			Vector2(gx2 - 2 + si * 0.55, gy2 - 10), Color(0.65, 0.65, 0.68, 0.8), 0.7)
	draw_line(Vector2(gx2, gy2 + 14), Vector2(gx2 - 11, gy2 + 32), Color(0.45, 0.42, 0.40), 2)
	draw_line(Vector2(gx2, gy2 + 14), Vector2(gx2 + 11, gy2 + 32), Color(0.45, 0.42, 0.40), 2)

	# ── Schlagzeug CENTER BACK ─────────────────────────────────────────────
	var dx = w * 0.5; var dy = h * 0.46
	draw_circle(Vector2(dx, dy + 20), 38, Color(0.12, 0.08, 0.06))
	draw_circle(Vector2(dx, dy + 20), 28, Color(0.20, 0.14, 0.11))
	draw_circle(Vector2(dx, dy + 20), 14, Color(0.06, 0.04, 0.04))
	draw_circle(Vector2(dx + 54, dy - 2), 20, Color(0.62, 0.60, 0.58))
	draw_circle(Vector2(dx + 54, dy - 2), 13, Color(0.82, 0.80, 0.78))
	draw_circle(Vector2(dx - 56, dy - 12), 17, Color(0.70, 0.66, 0.28))
	draw_circle(Vector2(dx - 56, dy - 18), 17, Color(0.76, 0.70, 0.30))
	draw_circle(Vector2(dx - 22, dy - 32), 15, Color(0.12, 0.08, 0.06))
	draw_circle(Vector2(dx - 22, dy - 32), 10, Color(0.20, 0.14, 0.11))
	draw_circle(Vector2(dx + 22, dy - 32), 15, Color(0.12, 0.08, 0.06))
	draw_circle(Vector2(dx + 22, dy - 32), 10, Color(0.20, 0.14, 0.11))
	draw_circle(Vector2(dx + 85, dy - 22), 22, Color(0.70, 0.63, 0.20, 0.9))
	draw_line(Vector2(dx + 32, dy - 10), Vector2(dx - 12, dy + 32), Color(0.58, 0.38, 0.14), 3)
	draw_line(Vector2(dx + 44, dy - 6),  Vector2(dx + 2,  dy + 34), Color(0.58, 0.38, 0.14), 3)

	# ── Bass-Verstärker RECHTS ─────────────────────────────────────────────
	draw_rect(Rect2(w - 132, h * 0.18, 108, 168), Color(0.08, 0.06, 0.06))
	draw_rect(Rect2(w - 128, h * 0.18 + 4, 100, 14), Color(0.16 * fl, 0.10 * fl, 0.07 * fl))
	for bi in range(2):
		for bj in range(2):
			draw_circle(Vector2(w - 112 + bi * 58, h * 0.18 + 58 + bj * 74), 26, Color(0.04, 0.04, 0.05))
			draw_circle(Vector2(w - 112 + bi * 58, h * 0.18 + 58 + bj * 74), 18, Color(0.10 * fl, 0.10 * fl, 0.11 * fl))

	# Bass auf Ständer (rechts)
	var bax = w - 162.0; var bay = h * 0.44
	draw_circle(Vector2(bax, bay), 16, Color(0.08, 0.18, 0.42))
	draw_circle(Vector2(bax, bay - 28), 12, Color(0.08, 0.18, 0.42))
	draw_rect(Rect2(bax - 3, bay - 92, 6, 66), Color(0.38, 0.22, 0.08))
	draw_rect(Rect2(bax - 5, bay - 100, 12, 10), Color(0.30, 0.18, 0.06))
	for si in range(4):
		draw_line(Vector2(bax - 1 + si * 0.9, bay - 90),
			Vector2(bax - 1 + si * 0.7, bay - 12), Color(0.65, 0.65, 0.68, 0.8), 0.8)
	draw_line(Vector2(bax, bay + 16), Vector2(bax - 13, bay + 37), Color(0.45, 0.42, 0.40), 2)
	draw_line(Vector2(bax, bay + 16), Vector2(bax + 13, bay + 37), Color(0.45, 0.42, 0.40), 2)

	# ── Banjo (an Wand rechts) ─────────────────────────────────────────────
	var bnx = w - 50.0; var bny = h * 0.28
	draw_circle(Vector2(bnx, bny), 17, Color(0.52, 0.38, 0.12))
	draw_circle(Vector2(bnx, bny), 12, Color(0.88, 0.80, 0.62))
	draw_circle(Vector2(bnx, bny),  5, Color(0.55, 0.40, 0.14))
	draw_rect(Rect2(bnx - 2, bny - 72, 5, 55), Color(0.40, 0.22, 0.06))
	draw_rect(Rect2(bnx - 5, bny - 75, 10, 6), Color(0.35, 0.18, 0.05))
	draw_line(Vector2(bnx, bny - 17), Vector2(bnx, bny - 28), Color(0.50, 0.48, 0.42), 3)
	draw_rect(Rect2(bnx - 4, bny - 30, 8, 5), Color(0.50, 0.48, 0.42))

	# ── Background Characters proben ───────────────────────────────────────
	_draw_proberaum_chars(vp, t, fl)

	# ── Sofa UNTEN MITTE (Rückenlehne am unteren Rand, Sitz zeigt nach oben) ──
	var sb_w = 310.0; var sb_x = w * 0.5 - sb_w * 0.5; var sb_y = h - 78.0
	# Beine
	for lx2 in [sb_x + 10, sb_x + sb_w - 22]:
		draw_rect(Rect2(lx2, sb_y + 62, 14, 14), Color(0.28, 0.18, 0.08))
	# Sitzfläche (vorne / oben im Bild)
	draw_rect(Rect2(sb_x, sb_y, sb_w, 42), Color(0.38, 0.22, 0.14))
	# Rückenlehne (hinten / ganz unten)
	draw_rect(Rect2(sb_x, sb_y + 40, sb_w, 36), Color(0.46, 0.28, 0.18))
	# Armlehnen links/rechts
	draw_rect(Rect2(sb_x - 16, sb_y - 2, 18, 78), Color(0.42, 0.25, 0.16))
	draw_rect(Rect2(sb_x + sb_w - 2, sb_y - 2, 18, 78), Color(0.42, 0.25, 0.16))
	# Sitzkissen (4 Stück)
	for ki in range(4):
		draw_rect(Rect2(sb_x + 4 + ki * 75, sb_y + 4, 68, 32), Color(0.50, 0.32, 0.20))
		draw_line(Vector2(sb_x + 4 + ki * 75, sb_y + 4),
			Vector2(sb_x + 4 + ki * 75, sb_y + 36), Color(0.30, 0.18, 0.10), 1.5)

	# ── Sofa LINKS (Rückenlehne am linken Rand, Sitz zeigt nach rechts) ───
	var sl_h = 220.0; var sl_x = 0.0; var sl_y = h * 0.66
	# Beine
	for ly2 in [sl_y + 12, sl_y + sl_h - 24]:
		draw_rect(Rect2(sl_x + 60, ly2, 14, 14), Color(0.28, 0.18, 0.08))
	# Rückenlehne (ganz links)
	draw_rect(Rect2(sl_x, sl_y, 36, sl_h), Color(0.26, 0.30, 0.50))
	# Sitzfläche (rechts davon)
	draw_rect(Rect2(sl_x + 34, sl_y, 42, sl_h), Color(0.20, 0.24, 0.40))
	# Armlehnen oben/unten
	draw_rect(Rect2(sl_x, sl_y - 16, 78, 18), Color(0.22, 0.26, 0.44))
	draw_rect(Rect2(sl_x, sl_y + sl_h - 2, 78, 18), Color(0.22, 0.26, 0.44))
	# Sitzkissen (3 Stück, vertikal gestapelt)
	for ki in range(3):
		draw_rect(Rect2(sl_x + 36, sl_y + 6 + ki * 70, 34, 62), Color(0.28, 0.34, 0.55))
		draw_line(Vector2(sl_x + 36, sl_y + 6 + ki * 70),
			Vector2(sl_x + 70, sl_y + 6 + ki * 70), Color(0.16, 0.20, 0.36), 1.5)
	# Kleinkram auf dem Sitz: Setlist
	draw_rect(Rect2(sl_x + 38, sl_y + 90, 28, 18), Color(0.86, 0.84, 0.76))
	for li in range(3):
		draw_line(Vector2(sl_x + 41, sl_y + 93 + li * 5),
			Vector2(sl_x + 63, sl_y + 93 + li * 5), Color(0.30, 0.28, 0.22), 0.9)

	# ── Tisch VOR dem unteren Sofa (zwischen Sofa-unten und Sofa-links) ────
	var tx = sb_x - 30.0; var ty = h * 0.72; var tw = sb_w + 60.0; var th = 44.0
	# Tischbeine
	for lx2 in [tx + 10, tx + tw - 24]:
		draw_rect(Rect2(lx2, ty + th, 14, 18), Color(0.34, 0.22, 0.08))
	# Tischplatte
	# Tischrahmen (dunkle Kante)
	draw_rect(Rect2(tx, ty, tw, th), Color(0.30, 0.28, 0.26))
	# Fliesentisch – Fliesen-Raster (helle/dunkle Abwechslung)
	var tile_w = 28.0; var tile_h = 20.0
	var cols_t = int(ceil((tw - 4) / tile_w))
	var rows_t = int(ceil((th - 4) / tile_h))
	var tile_colors = [
		Color(0.82, 0.80, 0.78), Color(0.72, 0.70, 0.68),
		Color(0.76, 0.60, 0.55), Color(0.68, 0.74, 0.72),
		Color(0.80, 0.76, 0.62),
	]
	for row in range(rows_t):
		for col in range(cols_t):
			var fx = tx + 2 + col * tile_w
			var fy = ty + 2 + row * tile_h
			var fw = min(tile_w - 1, tx + tw - 2 - fx)
			var fh = min(tile_h - 1, ty + th - 2 - fy)
			if fw > 0 and fh > 0:
				var cidx = (row * 3 + col * 2) % tile_colors.size()
				draw_rect(Rect2(fx, fy, fw, fh), tile_colors[cidx])
	# Fugennetz (dünne dunkle Linien)
	for col in range(1, cols_t):
		draw_line(Vector2(tx + 2 + col * tile_w - 1, ty + 2),
			Vector2(tx + 2 + col * tile_w - 1, ty + th - 2), Color(0.22, 0.20, 0.18), 1.0)
	for row in range(1, rows_t):
		draw_line(Vector2(tx + 2, ty + 2 + row * tile_h - 1),
			Vector2(tx + tw - 2, ty + 2 + row * tile_h - 1), Color(0.22, 0.20, 0.18), 1.0)
	# 23 Bierflaschen in 2 Reihen dicht gedrängt
	var bottle_rng = RandomNumberGenerator.new()
	bottle_rng.seed = 12345
	var b_cols_arr = [Color(0.35,0.25,0.08), Color(0.12,0.32,0.08)]
	for bi2 in range(23):
		var col2 = bi2 % 12
		var row2 = bi2 / 12
		var bx2 = tx + 14 + col2 * 32 + (row2 * 8)
		var bby = ty - 22 + row2 * 12
		var bc2 = b_cols_arr[bi2 % 2]
		var tilt = bottle_rng.randf_range(-0.06, 0.06)
		draw_rect(Rect2(bx2 + tilt * 8, bby, 7, 22), bc2)
		draw_rect(Rect2(bx2 + 1 + tilt * 6, bby - 10, 4, 11), bc2.lightened(0.14))
		draw_rect(Rect2(bx2 + 1 + tilt * 5, bby - 7, 2, 7), Color(1, 1, 1, 0.17))
	# Aschenbecher (rechts auf dem Tisch)
	draw_circle(Vector2(tx + tw - 22, ty + 20), 10, Color(0.45, 0.43, 0.40))
	draw_circle(Vector2(tx + tw - 22, ty + 20),  6, Color(0.22, 0.20, 0.18))
	for ki in range(3):
		var ka2 = float(ki) / 3.0 * TAU
		draw_line(Vector2(tx + tw - 22 + cos(ka2)*4, ty + 20 + sin(ka2)*3),
			Vector2(tx + tw - 22 + cos(ka2)*11, ty + 20 + sin(ka2)*6),
			Color(0.88, 0.86, 0.82), 2.0)
		draw_circle(Vector2(tx + tw - 22 + cos(ka2)*11, ty + 20 + sin(ka2)*6),
			2, Color(0.78, 0.22, 0.04))

	# ── Kabel (rechte Seite, weg von den Möbeln) ───────────────────────────
	var crng = RandomNumberGenerator.new()
	crng.seed = 77777
	for ci in range(5):
		var c1 = Vector2(crng.randf_range(w * 0.72, w - 20), crng.randf_range(h * 0.64, h - 12))
		var c2 = Vector2(crng.randf_range(w * 0.72, w - 20), crng.randf_range(h * 0.64, h - 12))
		draw_line(c1, c2, Color(0.14, 0.10, 0.06, 0.88), 2.5)

func _draw_proberaum_chars(vp: Rect2, t: float, fl: float) -> void:
	var w = vp.size.x; var h = vp.size.y
	var selected = GameManager.selected_character

	# Position und Hauptfarbe je Charakter
	var chars = {
		"bassist":     {"pos": Vector2(w - 188, h * 0.50), "col": Color(0.1,  0.2,  0.55)},
		"riff_slicer": {"pos": Vector2(168,     h * 0.50), "col": Color(0.85, 0.45, 0.10)},
		"manni":       {"pos": Vector2(w * 0.50 - 65, h * 0.40), "col": Color(0.2,  0.4,  0.9)},
		"shouter":     {"pos": Vector2(w * 0.38, h * 0.50), "col": Color(0.9,  0.2,  0.2)},
		"dreads":      {"pos": Vector2(w * 0.60, h * 0.50), "col": Color(0.2,  0.7,  0.3)},
		"distortion":  {"pos": Vector2(w * 0.76, h * 0.46), "col": Color(0.55, 0.18, 0.85)},
	}

	for cid in chars:
		if cid == selected:
			continue
		var cd   = chars[cid]
		var cp   = cd["pos"]
		var col  = cd["col"]
		var bob  = sin(t * 2.5 + cp.x * 0.015) * 1.8
		var dark = col.darkened(0.35)
		var lcol = Color(col.r * fl, col.g * fl, col.b * fl)
		var ldark = Color(dark.r * fl, dark.g * fl, dark.b * fl)
		var skin = Color(0.80 * fl, 0.65 * fl, 0.52 * fl)
		var s    = 1.1   # Skalierungsfaktor

		# Schuhe
		draw_rect(Rect2(cp.x - 11*s, cp.y + 22*s + bob, 10*s, 4*s), Color(0.18*fl, 0.18*fl, 0.22*fl))
		draw_rect(Rect2(cp.x + 1*s,  cp.y + 22*s + bob, 10*s, 4*s), Color(0.18*fl, 0.18*fl, 0.22*fl))
		# Beine
		draw_rect(Rect2(cp.x - 9*s, cp.y + 12*s + bob, 7*s, 11*s), ldark)
		draw_rect(Rect2(cp.x + 2*s, cp.y + 12*s + bob, 7*s, 11*s), ldark)
		# Körper
		draw_rect(Rect2(cp.x - 11*s, cp.y - 6*s + bob, 22*s, 19*s), lcol)
		# Arme
		draw_rect(Rect2(cp.x - 18*s, cp.y - 3*s + bob, 7*s, 12*s), lcol)
		draw_rect(Rect2(cp.x + 11*s, cp.y - 3*s + bob, 7*s, 12*s), lcol)
		# Kopf
		draw_circle(Vector2(cp.x, cp.y - 20*s + bob), 13*s, skin)

		# Charakter-spezifische Details
		match cid:
			"dreads":
				for di in range(5):
					var da = -PI * 0.8 + float(di) / 4.0 * PI * 1.6
					draw_line(
						Vector2(cp.x + cos(da)*11*s, cp.y - 20*s + bob + sin(da)*11*s),
						Vector2(cp.x + cos(da)*20*s, cp.y - 14*s + bob),
						Color(0.22*fl, 0.16*fl, 0.06*fl), 3.0)
			"shouter":
				# Hühnerschnabel
				draw_colored_polygon(PackedVector2Array([
					Vector2(cp.x + 11*s, cp.y - 20*s + bob),
					Vector2(cp.x + 20*s, cp.y - 18*s + bob),
					Vector2(cp.x + 11*s, cp.y - 15*s + bob),
				]), Color(0.90*fl, 0.70*fl, 0.10*fl))
			"manni":
				# Cap
				draw_rect(Rect2(cp.x - 15*s, cp.y - 30*s + bob, 30*s, 6*s),
					Color(0.08, 0.08, 0.50))
				draw_rect(Rect2(cp.x - 11*s, cp.y - 40*s + bob, 22*s, 12*s),
					Color(0.08, 0.08, 0.50))
			"distortion":
				# Langer Bart
				draw_rect(Rect2(cp.x - 4*s, cp.y - 12*s + bob, 8*s, 10*s),
					Color(0.22*fl, 0.18*fl, 0.22*fl))
			"riff_slicer":
				# Bandana
				draw_rect(Rect2(cp.x - 13*s, cp.y - 28*s + bob, 26*s, 10*s),
					Color(0.80*fl, 0.08*fl, 0.08*fl))

		# Instrument-Interaktion (Armbewegung passt zum Bob)
		match cid:
			"bassist", "riff_slicer":
				# Spielt Gitarre/Bass: rechter Arm schlägt die Saiten
				var strum = sin(t * 4.0 + cp.x * 0.02) * 8.0
				draw_line(Vector2(cp.x + 8*s, cp.y - 2*s + bob),
					Vector2(cp.x + 18*s, cp.y + 5*s + bob + strum),
					Color(0.80*fl, 0.65*fl, 0.50*fl), 3.0)
			"manni":
				# Schlagzeug: Arme mit Sticks
				var beat = sin(t * 5.0) * 10.0
				draw_line(Vector2(cp.x - 10*s, cp.y + bob),
					Vector2(cp.x - 22*s, cp.y + 12*s + bob + beat), Color(0.58*fl,0.38*fl,0.14*fl), 2)
				draw_line(Vector2(cp.x + 10*s, cp.y + bob),
					Vector2(cp.x + 22*s, cp.y + 12*s + bob - beat), Color(0.58*fl,0.38*fl,0.14*fl), 2)
			"shouter":
				# Mikrofonständer davor
				draw_line(Vector2(cp.x, cp.y + 22*s + bob),
					Vector2(cp.x, cp.y - 28*s + bob), Color(0.55*fl, 0.53*fl, 0.50*fl), 2)
				draw_circle(Vector2(cp.x, cp.y - 28*s + bob), 5*s, Color(0.30*fl, 0.28*fl, 0.26*fl))

# ── Schweinestall ────────────────────────────────────────────────────────────
func _draw_schweinestall(vp: Rect2) -> void:
	var w = vp.size.x
	var h = vp.size.y
	var t = _anim_time

	# === DECKE: Holzdielen mit Balken ===
	# Hintergrundholz (dunkle Holzfarbe)
	draw_rect(Rect2(0, 0, w, h), Color(0.30, 0.18, 0.08))
	# Holzdielen-Streifen (abwechselnd hell/dunkel)
	for i in range(12):
		var bx = i * (w / 11.0)
		var col_bright = (i % 2 == 0)
		draw_rect(Rect2(bx, 0, w / 11.0 - 3, h * 0.46),
			Color(0.38 if col_bright else 0.28, 0.22 if col_bright else 0.16, 0.10 if col_bright else 0.06))
	# Holzmaserung (horizontale Linien)
	var wood_rng = RandomNumberGenerator.new()
	wood_rng.seed = 7777
	for i in range(18):
		var wy = wood_rng.randf_range(0, h * 0.46)
		var wx = wood_rng.randf_range(0, w)
		draw_line(Vector2(wx, wy), Vector2(wx + wood_rng.randf_range(40, 120), wy), Color(0.20, 0.12, 0.05, 0.40), 1.0)

	# === DECKENBALKEN (dicke horizontale Träger) ===
	for bi in range(3):
		var by = h * (0.12 + bi * 0.12)
		draw_rect(Rect2(0, by - 6, w, 14), Color(0.22, 0.13, 0.05))
		draw_rect(Rect2(0, by - 6, w, 3), Color(0.35, 0.22, 0.10))
		draw_rect(Rect2(0, by + 6, w, 2), Color(0.16, 0.10, 0.04))

	# === HÄNGENDE LATERNEN (warm glühend) ===
	var lantern_xs = [w * 0.15, w * 0.38, w * 0.62, w * 0.85]
	for li in range(4):
		var lx = lantern_xs[li]
		var sway = sin(t * 0.8 + float(li) * 1.2) * 4.0  # leichtes Schaukeln
		var lflicker = 0.85 + sin(t * 7.3 + float(li) * 2.1) * 0.08
		# Aufhängung
		draw_line(Vector2(lx, 0), Vector2(lx + sway, 38), Color(0.28, 0.18, 0.08), 2)
		# Laterne Körper
		var lp = Vector2(lx + sway, 42)
		draw_rect(Rect2(lp.x - 9, lp.y - 4, 18, 22), Color(0.55, 0.38, 0.12))
		draw_rect(Rect2(lp.x - 7, lp.y - 1, 14, 16), Color(lflicker * 0.95, lflicker * 0.72, lflicker * 0.22))
		draw_circle(lp + Vector2(0, 8), 4, Color(lflicker, lflicker * 0.82, lflicker * 0.28))
		# Lichtkegel (warm, schwach)
		var lcone = PackedVector2Array([
			lp + Vector2(-10, 18), lp + Vector2(10, 18),
			lp + Vector2(55, h * 0.46), lp + Vector2(-55, h * 0.46),
		])
		draw_colored_polygon(lcone, Color(lflicker * 0.50, lflicker * 0.36, lflicker * 0.08, 0.12))

	# === BODEN (schlammig, Dreck) ===
	draw_rect(Rect2(0, h * 0.46, w, h * 0.54), Color(0.30, 0.18, 0.07))
	# Boden-Maserung (Schlamm-Textur)
	var mud_rng = RandomNumberGenerator.new()
	mud_rng.seed = 3456
	for mi in range(40):
		var mx = mud_rng.randf_range(0, w)
		var my = h * 0.48 + mud_rng.randf_range(0, h * 0.50)
		draw_ellipse_approx(Vector2(mx, my), Vector2(mud_rng.randf_range(5, 22), mud_rng.randf_range(3, 10)),
			Color(0.22 + mud_rng.randf() * 0.08, 0.12 + mud_rng.randf() * 0.06, 0.04, 0.50))

	# === SCHLAMMPFÜTZEN (dunkel, glänzend) ===
	var puddle_data2 = [
		[w * 0.12, h * 0.62, 60.0, 22.0], [w * 0.35, h * 0.75, 80.0, 28.0],
		[w * 0.58, h * 0.58, 55.0, 18.0], [w * 0.78, h * 0.70, 70.0, 25.0],
		[w * 0.50, h * 0.88, 90.0, 30.0],
	]
	for pd2 in puddle_data2:
		var px2 = pd2[0]; var py2 = pd2[1]; var prw2 = pd2[2]; var prh2 = pd2[3]
		draw_ellipse_approx(Vector2(px2, py2), Vector2(prw2, prh2), Color(0.18, 0.10, 0.04))
		# Spiegelglanz
		draw_ellipse_approx(Vector2(px2 - prw2*0.25, py2 - prh2*0.2),
			Vector2(prw2 * 0.35, prh2 * 0.28), Color(0.35, 0.22, 0.10, 0.35))
		# Animierte Tropfen-Wellen
		var drop_t2 = fmod(t * 0.6 + px2 * 0.002, 1.0)
		var wave_r2 = drop_t2 * prw2 * 0.8
		if wave_r2 > 3.0:
			var wpts2 = PackedVector2Array()
			for wpi in range(12):
				var wa2 = float(wpi) / 12.0 * TAU
				wpts2.append(Vector2(px2 + cos(wa2) * wave_r2, py2 + sin(wa2) * wave_r2 * 0.4))
			draw_polyline(wpts2 + wpts2.slice(0, 1), Color(0.30, 0.20, 0.08, (1.0 - drop_t2) * 0.50), 1.0)

	# === STROH (Bodenbedeckung) ===
	var straw_rng2 = RandomNumberGenerator.new()
	straw_rng2.seed = 54321
	for si in range(40):
		var sx2 = straw_rng2.randf_range(0, w)
		var sy2 = h * 0.48 + straw_rng2.randf_range(0, h * 0.50)
		var ex2 = sx2 + straw_rng2.randf_range(-38, 38)
		var ey2 = sy2 + straw_rng2.randf_range(-6, 6)
		var straw_bright = 0.55 + straw_rng2.randf() * 0.25
		draw_line(Vector2(sx2, sy2), Vector2(ex2, ey2),
			Color(straw_bright, straw_bright * 0.82, straw_bright * 0.20, 0.75), 2.0)

	# === HEUBALLEN (gestapelt an der Seite) ===
	for hbi in range(3):
		var hbx2 = 28.0; var hby2 = h * 0.50 + hbi * 45.0
		draw_ellipse_approx(Vector2(hbx2, hby2 + 18), Vector2(35, 20), Color(0.68, 0.56, 0.18))
		draw_arc(Vector2(hbx2, hby2 + 18), 22, 0, TAU, 8, Color(0.52, 0.42, 0.12), 2.5)
		draw_arc(Vector2(hbx2, hby2 + 18), 12, 0, TAU, 6, Color(0.52, 0.42, 0.12), 1.5)
		# Bindfaden
		draw_line(Vector2(hbx2 - 35, hby2 + 18), Vector2(hbx2 + 35, hby2 + 18), Color(0.38, 0.28, 0.08), 2)

	# === HOLZPFOSTEN-ABTRENNUNG (Stallboxen) ===
	for pi2 in range(3):
		var px3 = 200.0 + pi2 * 380
		# Senkrechter Hauptpfosten
		draw_rect(Rect2(px3 - 6, h * 0.46, 14, h * 0.54), Color(0.42, 0.26, 0.10))
		draw_line(Vector2(px3 - 6, h * 0.46), Vector2(px3 - 6, h), Color(0.55, 0.36, 0.14), 2)
		draw_line(Vector2(px3 + 8, h * 0.46), Vector2(px3 + 8, h), Color(0.28, 0.16, 0.06), 1.5)
		# Horizontale Querlatten
		for ji in range(5):
			var qy2 = h * 0.48 + float(ji) * (h * 0.52 / 5.0)
			draw_rect(Rect2(px3 + 6, qy2, 72, 10), Color(0.48, 0.30, 0.12))
			draw_line(Vector2(px3 + 6, qy2), Vector2(px3 + 78, qy2), Color(0.60, 0.40, 0.16), 1.5)

	# === FUTTERTROG (mit animiertem Inhalt) ===
	draw_rect(Rect2(w * 0.35, h - 62, 210, 36), Color(0.40, 0.26, 0.12))
	draw_rect(Rect2(w * 0.35 + 6, h - 56, 198, 24), Color(0.24, 0.15, 0.07))
	# Trog-Inhalt: Matsch/Futter (leicht animiert)
	var trog_fill = 0.55 + sin(t * 0.4) * 0.04
	draw_rect(Rect2(w * 0.35 + 8, h - 52, 194, int(20 * trog_fill)), Color(0.35, 0.22, 0.10))
	# Trog-Beine
	for tbi in [w * 0.36, w * 0.35 + 190]:
		draw_rect(Rect2(tbi, h - 26, 10, 26), Color(0.32, 0.20, 0.08))

	# === WERKZEUG AN DER WAND ===
	# Mistgabel
	draw_line(Vector2(w - 50, h * 0.22), Vector2(w - 50, h * 0.48), Color(0.45, 0.28, 0.10), 5)
	draw_line(Vector2(w - 58, h * 0.22), Vector2(w - 58, h * 0.30), Color(0.58, 0.58, 0.60), 3)
	draw_line(Vector2(w - 50, h * 0.22), Vector2(w - 50, h * 0.30), Color(0.58, 0.58, 0.60), 3)
	draw_line(Vector2(w - 42, h * 0.22), Vector2(w - 42, h * 0.30), Color(0.58, 0.58, 0.60), 3)
	draw_line(Vector2(w - 62, h * 0.22), Vector2(w - 38, h * 0.22), Color(0.58, 0.58, 0.60), 3)
	# Eimer
	draw_rect(Rect2(w - 80, h * 0.40, 22, 20), Color(0.42, 0.38, 0.32))
	draw_rect(Rect2(w - 80, h * 0.40, 22, 4), Color(0.55, 0.50, 0.44))
	draw_arc(Vector2(w - 69, h * 0.40), 11, PI, TAU, 8, Color(0.42, 0.38, 0.32), 2)  # Henkel
	# Schaufel (links an der Wand)
	draw_line(Vector2(45, h * 0.20), Vector2(45, h * 0.46), Color(0.42, 0.26, 0.10), 5)
	draw_colored_polygon(PackedVector2Array([
		Vector2(36, h * 0.20), Vector2(54, h * 0.20),
		Vector2(58, h * 0.30), Vector2(32, h * 0.30),
	]), Color(0.55, 0.55, 0.58))

	# === KLEINE PIGS IN DEN BOXEN (hinter den Latten) ===
	# Animierte Schweinchensilhouetten
	for pigi in range(2):
		var pig_x = 310.0 + pigi * 380.0
		var pig_y = h * 0.68
		var pig_bob = sin(t * 2.0 + float(pigi) * 1.5) * 2.0
		draw_ellipse_approx(Vector2(pig_x, pig_y + pig_bob), Vector2(28, 18), Color(0.88, 0.62, 0.65))
		draw_circle(Vector2(pig_x + 22, pig_y + pig_bob), 14, Color(0.88, 0.62, 0.65))
		draw_ellipse_approx(Vector2(pig_x + 26, pig_y + pig_bob), Vector2(9, 7), Color(0.78, 0.48, 0.52))
		draw_circle(Vector2(pig_x + 24, pig_y - 2 + pig_bob), 2, Color(0.50, 0.22, 0.28))
		draw_circle(Vector2(pig_x + 28, pig_y - 2 + pig_bob), 2, Color(0.50, 0.22, 0.28))
		# Öhrchen
		draw_colored_polygon(PackedVector2Array([
			Vector2(pig_x + 16, pig_y - 16 + pig_bob),
			Vector2(pig_x + 11, pig_y - 24 + pig_bob),
			Vector2(pig_x + 20, pig_y - 22 + pig_bob),
		]), Color(0.85, 0.55, 0.60))
		# Trotting legs
		var trot = sin(t * 4.0 + float(pigi)) * 5.0
		draw_rect(Rect2(pig_x - 18, pig_y + 14 + pig_bob + trot, 8, 10), Color(0.82, 0.58, 0.62))
		draw_rect(Rect2(pig_x - 8, pig_y + 14 + pig_bob - trot, 8, 10), Color(0.82, 0.58, 0.62))
		draw_rect(Rect2(pig_x + 6, pig_y + 14 + pig_bob + trot, 8, 10), Color(0.82, 0.58, 0.62))

	# === SCHMUTZIGE WÄNDE (Spritzer, Graffiti) ===
	var wall_rng = RandomNumberGenerator.new()
	wall_rng.seed = 9191
	for wi2 in range(12):
		var wx2 = wall_rng.randf_range(0, w)
		var wy2 = wall_rng.randf_range(0, h * 0.44)
		draw_circle(Vector2(wx2, wy2), wall_rng.randf_range(3, 14),
			Color(0.22, 0.12, 0.05, 0.38 + wall_rng.randf() * 0.25))

	# === DYNAMISCHES EVENT: Schwein büxt aus (alle 14 s) ────────────────────
	var et_sau = fmod(_anim_time, 14.0)
	if et_sau < 4.0:
		var ep_sau = et_sau / 4.0
		var sx2 = -60.0 + ep_sau * (w + 120.0)
		var sy2 = h * 0.62
		draw_ellipse_approx(Vector2(sx2, sy2), Vector2(26, 18), Color(0.92, 0.66, 0.70))
		draw_circle(Vector2(sx2 + 20, sy2), 14, Color(0.92, 0.66, 0.70))
		draw_ellipse_approx(Vector2(sx2 + 24, sy2), Vector2(9, 7), Color(0.82, 0.50, 0.55))
		draw_circle(Vector2(sx2 + 22, sy2 - 2), 2, Color(0.55, 0.25, 0.30))
		draw_circle(Vector2(sx2 + 26, sy2 - 2), 2, Color(0.55, 0.25, 0.30))
		draw_ellipse_approx(Vector2(sx2 + 15, sy2 - 16), Vector2(5, 8), Color(0.88, 0.60, 0.65))
		var leg_off = sin(et_sau * 14.0) * 8.0
		draw_rect(Rect2(sx2 - 14, sy2 + 14, 8, 10 + leg_off), Color(0.88, 0.62, 0.66))
		draw_rect(Rect2(sx2 - 4, sy2 + 14, 8, 10 - leg_off), Color(0.88, 0.62, 0.66))
		draw_rect(Rect2(sx2 + 6, sy2 + 14, 8, 10 + leg_off), Color(0.88, 0.62, 0.66))
		for pi3 in range(5):
			draw_ellipse_approx(Vector2(sx2 - 40 - pi3 * 24, sy2 + 20), Vector2(6, 4), Color(0.32, 0.20, 0.08, 0.65))
		if ep_sau < 0.5:
			var bx2 = sx2 + 30.0; var by2 = sy2 - 36.0
			draw_rect(Rect2(bx2, by2, 44, 22), Color(1.0, 1.0, 1.0, 0.88))
			draw_rect(Rect2(bx2, by2, 44, 22), Color(0.80, 0.50, 0.55, 0.9), false, 1.5)
			draw_arc(Vector2(bx2 + 7, by2 + 11), 5, 0, TAU, 8, Color(0.55, 0.18, 0.22), 2)
			draw_line(Vector2(bx2 + 16, by2 + 6), Vector2(bx2 + 16, by2 + 16), Color(0.55, 0.18, 0.22), 2)
			draw_line(Vector2(bx2 + 21, by2 + 6), Vector2(bx2 + 21, by2 + 16), Color(0.55, 0.18, 0.22), 2)
			draw_line(Vector2(bx2 + 21, by2 + 6), Vector2(bx2 + 26, by2 + 16), Color(0.55, 0.18, 0.22), 2)
			draw_line(Vector2(bx2 + 26, by2 + 6), Vector2(bx2 + 26, by2 + 16), Color(0.55, 0.18, 0.22), 2)
			draw_line(Vector2(bx2 + 31, by2 + 6), Vector2(bx2 + 31, by2 + 16), Color(0.55, 0.18, 0.22), 2)
			draw_line(Vector2(bx2 + 31, by2 + 11), Vector2(bx2 + 37, by2 + 6), Color(0.55, 0.18, 0.22), 2)
			draw_line(Vector2(bx2 + 31, by2 + 11), Vector2(bx2 + 37, by2 + 16), Color(0.55, 0.18, 0.22), 2)

# ── Amerika ──────────────────────────────────────────────────────────────────
func _draw_amerika(vp: Rect2) -> void:
	var w = vp.size.x
	var h = vp.size.y
	var t = _anim_time
	var horizon = h * 0.45

	# === SKY GRADIENT (3 bands) ===
	draw_rect(Rect2(0, 0, w, horizon * 0.35), Color(0.05, 0.10, 0.45))
	draw_rect(Rect2(0, horizon * 0.35, w, horizon * 0.35), Color(0.22, 0.40, 0.72))
	draw_rect(Rect2(0, horizon * 0.70, w, horizon * 0.30), Color(0.58, 0.68, 0.85))

	# === STARS ===
	var star_rng = RandomNumberGenerator.new()
	star_rng.seed = 11223
	for i in range(55):
		var sx = star_rng.randf_range(0, w)
		var sy = star_rng.randf_range(0, horizon * 0.72)
		var twinkle = 0.5 + abs(sin(t * (1.2 + star_rng.randf() * 2.0) + star_rng.randf() * TAU)) * 0.5
		draw_circle(Vector2(sx, sy), star_rng.randf_range(0.8, 2.2), Color(1, 1, 0.9, twinkle * 0.85))

	# === SUN with heat shimmer ===
	var sun_x = w * 0.78; var sun_y = horizon * 0.38
	# Heat shimmer rings
	for shi in range(3):
		var shimmer_r = 38.0 + shi * 18.0 + sin(t * 3.0 + shi * 1.3) * 4.0
		draw_arc(Vector2(sun_x, sun_y), shimmer_r, 0, TAU, 20,
			Color(1.0, 0.85, 0.30, 0.06 - shi * 0.015), 3.0)
	draw_circle(Vector2(sun_x, sun_y), 32, Color(1.0, 0.95, 0.50, 0.95))
	draw_circle(Vector2(sun_x, sun_y), 24, Color(1.0, 1.0, 0.75, 1.0))
	# Sun rays
	for ri in range(12):
		var ra = float(ri) / 12.0 * TAU + t * 0.05
		draw_line(Vector2(sun_x + cos(ra) * 34, sun_y + sin(ra) * 34),
			Vector2(sun_x + cos(ra) * 52, sun_y + sin(ra) * 52),
			Color(1.0, 0.92, 0.45, 0.55), 2.0)

	# === DISTANT MESAS / MOUNTAINS (layered) ===
	# Far layer (blue-tinted)
	var mesa_rng = RandomNumberGenerator.new()
	mesa_rng.seed = 44556
	for i in range(6):
		var mx = mesa_rng.randf_range(-60.0, w - 80.0)
		var mw = mesa_rng.randf_range(180.0, 340.0)
		var mh2 = mesa_rng.randf_range(55.0, 120.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(mx, horizon), Vector2(mx + mw * 0.2, horizon - mh2),
			Vector2(mx + mw * 0.5, horizon - mh2 * 1.1),
			Vector2(mx + mw * 0.8, horizon - mh2 * 0.7), Vector2(mx + mw, horizon)
		]), Color(0.38 + i * 0.025, 0.32 + i * 0.015, 0.42 - i * 0.01))
	# Near layer (warm terra cotta)
	var mesa_rng2 = RandomNumberGenerator.new()
	mesa_rng2.seed = 55667
	for i in range(4):
		var mx2 = mesa_rng2.randf_range(-40.0, w - 120.0)
		var mw2 = mesa_rng2.randf_range(140.0, 260.0)
		var mh3 = mesa_rng2.randf_range(40.0, 85.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(mx2, horizon),
			Vector2(mx2 + mw2 * 0.15, horizon - mh3),
			Vector2(mx2 + mw2 * 0.85, horizon - mh3),
			Vector2(mx2 + mw2, horizon)
		]), Color(0.58 + i * 0.02, 0.34 + i * 0.01, 0.22))

	# === DESERT GROUND ===
	draw_rect(Rect2(0, horizon, w, h - horizon), Color(0.72, 0.55, 0.28))
	# Sand texture with random dots / ripples
	var sand_rng = RandomNumberGenerator.new()
	sand_rng.seed = 99012
	for i in range(80):
		var sdx = sand_rng.randf_range(0, w)
		var sdy = horizon + sand_rng.randf_range(0, h - horizon)
		var sdr = sand_rng.randf_range(0.8, 3.5)
		var sda = sand_rng.randf_range(0.08, 0.22)
		draw_circle(Vector2(sdx, sdy), sdr, Color(0.62, 0.46, 0.20, sda))
	# Sand ripple lines
	var ripple_rng = RandomNumberGenerator.new()
	ripple_rng.seed = 13579
	for ri2 in range(18):
		var ry2 = horizon + ripple_rng.randf_range(10, h - horizon - 5)
		var rx2 = ripple_rng.randf_range(0, w * 0.6)
		var rlen = ripple_rng.randf_range(30, 110)
		draw_line(Vector2(rx2, ry2), Vector2(rx2 + rlen, ry2 + ripple_rng.randf_range(-2, 2)),
			Color(0.60, 0.44, 0.20, 0.28), 1.0)

	# === ROAD (perspective) ===
	var road_left_bot  = w * 0.08
	var road_right_bot = w * 0.92
	var road_left_hor  = w * 0.44
	var road_right_hor = w * 0.56
	draw_colored_polygon(PackedVector2Array([
		Vector2(road_left_hor, horizon), Vector2(road_right_hor, horizon),
		Vector2(road_right_bot, h), Vector2(road_left_bot, h)
	]), Color(0.22, 0.21, 0.23))
	# Road edges
	draw_line(Vector2(road_left_hor, horizon), Vector2(road_left_bot, h), Color(0.50, 0.46, 0.24), 3.0)
	draw_line(Vector2(road_right_hor, horizon), Vector2(road_right_bot, h), Color(0.50, 0.46, 0.24), 3.0)
	# Animated center dashes
	for i in range(10):
		var prog = fmod(t * 0.35 + i * 0.1, 1.0)
		var ydash = horizon + prog * (h - horizon)
		var xdash = lerp(w * 0.50, w * 0.50, prog)
		var dw = lerp(2.0, 14.0, prog)
		var dh2 = lerp(6.0, 36.0, prog)
		draw_rect(Rect2(xdash - dw * 0.5, ydash, dw, dh2), Color(0.90, 0.84, 0.20, 0.85))
	# Road surface cracks / tar patches
	var crack_rng = RandomNumberGenerator.new()
	crack_rng.seed = 24680
	for ci in range(8):
		var cy2 = horizon + crack_rng.randf_range(20, h - horizon - 20)
		var cx2 = lerp(road_left_bot, road_right_bot, crack_rng.randf_range(0.2, 0.8))
		draw_line(Vector2(cx2, cy2), Vector2(cx2 + crack_rng.randf_range(-22, 22), cy2 + crack_rng.randf_range(5, 18)),
			Color(0.14, 0.13, 0.15, 0.50), 1.2)

	# === FENCE POSTS along road edge ===
	for fi in range(14):
		var fp = float(fi) / 13.0
		var fy2 = horizon + fp * (h - horizon)
		var fxl = lerp(road_left_hor, road_left_bot, fp) - lerp(4.0, 28.0, fp)
		var fxr = lerp(road_right_hor, road_right_bot, fp) + lerp(4.0, 28.0, fp)
		var post_h = lerp(4.0, 22.0, fp)
		draw_rect(Rect2(fxl - 2, fy2, 4, post_h), Color(0.52, 0.38, 0.18))
		draw_rect(Rect2(fxr - 2, fy2, 4, post_h), Color(0.52, 0.38, 0.18))
		if fi > 0:
			var fp_prev = float(fi - 1) / 13.0
			var fy2p = horizon + fp_prev * (h - horizon)
			var fxlp = lerp(road_left_hor, road_left_bot, fp_prev) - lerp(4.0, 28.0, fp_prev)
			var fxrp = lerp(road_right_hor, road_right_bot, fp_prev) + lerp(4.0, 28.0, fp_prev)
			draw_line(Vector2(fxl, fy2 + post_h * 0.4), Vector2(fxlp, fy2p + lerp(4.0, 22.0, fp_prev) * 0.4),
				Color(0.52, 0.38, 0.18, 0.75), 1.5)
			draw_line(Vector2(fxr, fy2 + post_h * 0.4), Vector2(fxrp, fy2p + lerp(4.0, 22.0, fp_prev) * 0.4),
				Color(0.52, 0.38, 0.18, 0.75), 1.5)

	# === CACTI (varied sizes, both sides) ===
	var cactus_data = [
		[w * 0.04, horizon + 8,  1.00],
		[w * 0.14, horizon + 18, 1.35],
		[w * 0.22, horizon + 6,  0.70],
		[w * 0.76, horizon + 12, 1.20],
		[w * 0.86, horizon + 20, 1.50],
		[w * 0.94, horizon + 5,  0.65],
	]
	for cd in cactus_data:
		var cx2: float = cd[0]; var cy2: float = cd[1]; var cs: float = cd[2]
		var cg = Color(0.12, 0.46, 0.16)
		var cg2 = Color(0.08, 0.36, 0.12)
		# Main trunk
		draw_rect(Rect2(cx2 - 7 * cs, cy2, 14 * cs, 75 * cs), cg)
		draw_rect(Rect2(cx2 - 4 * cs, cy2, 8 * cs, 75 * cs), cg2)
		# Left arm
		draw_rect(Rect2(cx2 - 26 * cs, cy2 + 22 * cs, 20 * cs, 8 * cs), cg)
		draw_rect(Rect2(cx2 - 26 * cs, cy2 + 10 * cs, 8 * cs, 20 * cs), cg)
		# Right arm
		draw_rect(Rect2(cx2 + 7 * cs, cy2 + 32 * cs, 20 * cs, 8 * cs), cg)
		draw_rect(Rect2(cx2 + 18 * cs, cy2 + 16 * cs, 8 * cs, 24 * cs), cg)
		# Spines
		for spi in range(5):
			var spy = cy2 + spi * 14 * cs
			draw_line(Vector2(cx2 - 7 * cs, spy), Vector2(cx2 - 12 * cs, spy - 3 * cs), Color(0.88, 0.86, 0.72, 0.7), 1.0)
			draw_line(Vector2(cx2 + 7 * cs, spy), Vector2(cx2 + 12 * cs, spy - 3 * cs), Color(0.88, 0.86, 0.72, 0.7), 1.0)

	# === WANTED POSTER on fence post (left side near-ish) ===
	var wp_x = road_left_bot - 50.0; var wp_y = h - 140.0
	draw_rect(Rect2(wp_x - 2, h - 160, 5, 60), Color(0.50, 0.35, 0.14))  # post
	draw_rect(Rect2(wp_x - 20, wp_y, 44, 56), Color(0.88, 0.82, 0.58))  # paper
	draw_rect(Rect2(wp_x - 20, wp_y, 44, 56), Color(0.55, 0.38, 0.18, 0.4), false, 1.5)  # border
	draw_rect(Rect2(wp_x - 16, wp_y + 4, 36, 18), Color(0.60, 0.20, 0.08))  # red banner
	# Wanted face (rough circle + hat)
	draw_circle(Vector2(wp_x + 2, wp_y + 36), 10, Color(0.78, 0.62, 0.46))
	draw_rect(Rect2(wp_x - 7, wp_y + 25, 18, 4), Color(0.25, 0.18, 0.08))
	draw_rect(Rect2(wp_x - 4, wp_y + 18, 11, 8), Color(0.25, 0.18, 0.08))

	# === AMERICAN FLAG (top right, on post) ===
	draw_rect(Rect2(w - 88, 8, 4, 72), Color(0.52, 0.38, 0.18))  # flagpole
	draw_rect(Rect2(w - 84, 8, 62, 38), Color(0.82, 0.10, 0.10))
	for fi2 in range(6):
		draw_rect(Rect2(w - 84, 8 + fi2 * 6, 62, 3), Color(1, 1, 1, 0.85) if fi2 % 2 == 0 else Color(0.82, 0.10, 0.10))
	draw_rect(Rect2(w - 84, 8, 25, 20), Color(0.10, 0.14, 0.55))
	for si2 in range(6):
		draw_circle(Vector2(w - 79 + (si2 % 3) * 7, 12 + (si2 / 3) * 7), 1.5, Color(1, 1, 1, 0.9))

	# === VULTURES circling in sky ===
	for vi in range(3):
		var v_orbit_r = 38.0 + vi * 22.0
		var v_speed = 0.28 + vi * 0.12
		var v_angle = t * v_speed + float(vi) * TAU / 3.0
		var v_cx = w * 0.58; var v_cy = horizon * 0.30
		var vx = v_cx + cos(v_angle) * v_orbit_r
		var vy = v_cy + sin(v_angle) * v_orbit_r * 0.45
		# Vulture silhouette: body + wings
		draw_circle(Vector2(vx, vy), 4, Color(0.06, 0.05, 0.04))
		var wing_spread = sin(t * 3.5 + vi) * 0.18
		draw_line(Vector2(vx - 2, vy), Vector2(vx - 14 + sin(wing_spread) * 4, vy + sin(wing_spread) * 3),
			Color(0.08, 0.06, 0.05), 3.0)
		draw_line(Vector2(vx + 2, vy), Vector2(vx + 14 - sin(wing_spread) * 4, vy + sin(wing_spread) * 3),
			Color(0.08, 0.06, 0.05), 3.0)

	# === HEAT HAZE at horizon ===
	var haze_alpha = 0.04 + sin(t * 0.7) * 0.015
	draw_rect(Rect2(0, horizon - 6, w, 12), Color(1.0, 0.90, 0.55, haze_alpha))

	# === DYNAMISCHES EVENT: Tumbleweed rollt durch (alle 13 s) ───────────────
	var et_tw = fmod(_anim_time, 13.0)
	if et_tw < 4.5:
		var ep_tw = et_tw / 4.5
		var twx = w + 60.0 - ep_tw * (w + 120.0)
		var twy = h * 0.72
		var roll_angle = ep_tw * TAU * 3.0
		draw_circle(Vector2(twx, twy), 18, Color(0.55, 0.38, 0.18, 0.7))
		for ri in range(8):
			var ra = roll_angle + float(ri) / 8.0 * TAU
			draw_line(Vector2(twx, twy),
				Vector2(twx + cos(ra) * 18, twy + sin(ra) * 18),
				Color(0.42, 0.28, 0.12, 0.8), 2.0)
		draw_circle(Vector2(twx, twy), 10, Color(0.62, 0.45, 0.22, 0.5))
		draw_circle(Vector2(twx, twy),  4, Color(0.38, 0.26, 0.12, 0.6))
		# Second smaller tumbleweed trailing
		var twx2 = twx + 38; var twy2 = h * 0.76
		draw_circle(Vector2(twx2, twy2), 11, Color(0.55, 0.38, 0.18, 0.5))
		for ri2 in range(6):
			var ra2 = roll_angle * 1.2 + float(ri2) / 6.0 * TAU
			draw_line(Vector2(twx2, twy2),
				Vector2(twx2 + cos(ra2) * 11, twy2 + sin(ra2) * 11),
				Color(0.42, 0.28, 0.12, 0.55), 1.5)
		for di in range(3):
			draw_circle(Vector2(twx + 24 + di * 14, twy + 5 + di * 3),
				5 + di * 3, Color(0.70, 0.58, 0.32, 0.28 - di * 0.07))

# ── Fahrender Truck ───────────────────────────────────────────────────────────
func _draw_truck(vp: Rect2) -> void:
	var w = vp.size.x
	var h = vp.size.y
	var t = _anim_time
	var horizon = h * 0.52

	# === NIGHT SKY (gradient bands) ===
	draw_rect(Rect2(0, 0, w, horizon * 0.45), Color(0.02, 0.04, 0.12))
	draw_rect(Rect2(0, horizon * 0.45, w, horizon * 0.55), Color(0.06, 0.09, 0.22))
	# Stars streaking (motion blur)
	for i in range(40):
		var sx = fmod(i * 233.7 + t * 220.0, w + 120) - 120
		var sy = fmod(i * 97.3, horizon * 0.88)
		var streak = 12.0 + fmod(i * 31.1, 28.0)
		draw_line(Vector2(sx, sy), Vector2(sx + streak, sy), Color(1, 1, 0.9, 0.35), 1.2)

	# === DISTANT CITYSCAPE / HILLS on horizon ===
	# Hills (dark silhouette)
	var hill_rng = RandomNumberGenerator.new()
	hill_rng.seed = 31415
	for hi in range(7):
		var hx = hi * (w / 6.0) - 40
		var hh2 = 35.0 + hill_rng.randf_range(0, 55)
		draw_colored_polygon(PackedVector2Array([
			Vector2(hx, horizon),
			Vector2(hx + (w / 6.0) * 0.5, horizon - hh2),
			Vector2(hx + w / 6.0, horizon)
		]), Color(0.08, 0.10, 0.16))
	# City lights (distant flickering dots)
	var city_rng = RandomNumberGenerator.new()
	city_rng.seed = 27182
	for ci2 in range(30):
		var clx = city_rng.randf_range(0, w)
		var cly = horizon - city_rng.randf_range(4, 45)
		var flicker = 0.4 + abs(sin(t * (2.0 + city_rng.randf() * 3.0) + city_rng.randf() * TAU)) * 0.6
		var clight_col = [Color(1.0, 0.9, 0.5), Color(0.4, 0.8, 1.0), Color(1.0, 0.4, 0.3)][city_rng.randi() % 3]
		draw_circle(Vector2(clx, cly), city_rng.randf_range(0.8, 2.0), Color(clight_col.r, clight_col.g, clight_col.b, flicker * 0.8))

	# === ROAD SURFACE (perspective) ===
	# Road base
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.5, horizon), Vector2(w * 0.5, horizon),
		Vector2(w, h), Vector2(0, h)
	]), Color(0.14, 0.14, 0.16))
	# Road edges (perspective)
	draw_line(Vector2(w * 0.50, horizon), Vector2(0, h), Color(0.50, 0.46, 0.22), 4.0)
	draw_line(Vector2(w * 0.50, horizon), Vector2(w, h), Color(0.50, 0.46, 0.22), 4.0)

	# Road surface cracks / tar patches
	var tar_rng = RandomNumberGenerator.new()
	tar_rng.seed = 86420
	for tpi in range(10):
		var tpy = horizon + tar_rng.randf_range(10, h - horizon - 10)
		var prog_t = (tpy - horizon) / (h - horizon)
		var road_half = lerp(0.0, w * 0.5, prog_t)
		var tpx = lerp(w * 0.5 - road_half + 20, w * 0.5 + road_half - 20, tar_rng.randf())
		var tpw = lerp(6.0, 40.0, prog_t) * tar_rng.randf_range(0.6, 1.4)
		var tph2 = lerp(3.0, 14.0, prog_t)
		draw_rect(Rect2(tpx - tpw * 0.5, tpy, tpw, tph2), Color(0.10, 0.10, 0.12, 0.65))
		# Crack lines extending from patch
		draw_line(Vector2(tpx, tpy), Vector2(tpx + tar_rng.randf_range(-18, 18), tpy + tar_rng.randf_range(4, 14)),
			Color(0.08, 0.08, 0.10, 0.55), 1.0)

	# === CENTER DASHES (moving with perspective) ===
	for i in range(10):
		var progress = fmod(t * 0.55 + i * 0.10, 1.0)
		var yd = horizon + progress * (h - horizon)
		var dw = lerp(2.0, 14.0, progress)
		var dh2 = lerp(6.0, 38.0, progress)
		draw_rect(Rect2(w * 0.5 - dw * 0.5, yd, dw, dh2), Color(0.90, 0.84, 0.20, 0.85 * (0.4 + progress * 0.6)))

	# === GUARDRAILS (perspective, with posts) ===
	# Left guardrail
	var grail_pts_l = PackedVector2Array([
		Vector2(w * 0.50 - 2, horizon + 2), Vector2(w * 0.50 + 2, horizon + 2),
		Vector2(w * 0.14, h - 2), Vector2(w * 0.08, h - 2)
	])
	draw_colored_polygon(grail_pts_l, Color(0.55, 0.52, 0.50, 0.70))
	# Right guardrail
	var grail_pts_r = PackedVector2Array([
		Vector2(w * 0.50 - 2, horizon + 2), Vector2(w * 0.50 + 2, horizon + 2),
		Vector2(w * 0.92, h - 2), Vector2(w * 0.86, h - 2)
	])
	draw_colored_polygon(grail_pts_r, Color(0.55, 0.52, 0.50, 0.70))
	# Guardrail reflection glint
	for gi in range(8):
		var gp = float(gi) / 7.0
		var glx = lerp(w * 0.50, w * 0.10, gp)
		var grx = lerp(w * 0.50, w * 0.90, gp)
		var gy2 = horizon + gp * (h - horizon)
		draw_circle(Vector2(glx, gy2), lerp(1.0, 4.0, gp), Color(0.85, 0.84, 0.78, 0.4 * gp))
		draw_circle(Vector2(grx, gy2), lerp(1.0, 4.0, gp), Color(0.85, 0.84, 0.78, 0.4 * gp))

	# === HIGHWAY SIGNS on poles (right shoulder) ===
	# Green sign
	draw_rect(Rect2(w * 0.72, h * 0.38, 6, h * 0.22), Color(0.30, 0.28, 0.26))
	draw_rect(Rect2(w * 0.68, h * 0.34, 90, 40), Color(0.10, 0.42, 0.18))
	draw_rect(Rect2(w * 0.68, h * 0.34, 90, 40), Color(1, 1, 1, 0.7), false, 1.5)
	for sli in range(3):
		draw_rect(Rect2(w * 0.70, h * 0.36 + sli * 10, 50, 5), Color(1, 1, 1, 0.6))
	# Distance sign
	draw_rect(Rect2(w * 0.82, h * 0.42, 4, h * 0.16), Color(0.30, 0.28, 0.26))
	draw_rect(Rect2(w * 0.78, h * 0.38, 52, 26), Color(0.72, 0.68, 0.20))
	draw_rect(Rect2(w * 0.78, h * 0.38, 52, 26), Color(0, 0, 0, 0.65), false, 1.5)

	# === TREES rushing past ===
	for i in range(6):
		# Left side
		var tx2 = fmod(i * 214.0 + t * 310.0, w + 90) - 90
		var tree_h = 80.0 + fmod(i * 31.7, 40)
		draw_rect(Rect2(tx2, h * 0.28, 12, tree_h), Color(0.08, 0.20, 0.06))
		draw_circle(Vector2(tx2 + 6, h * 0.28), 22.0 + fmod(i * 7.3, 10), Color(0.10, 0.28, 0.08))
		draw_circle(Vector2(tx2 + 6, h * 0.22), 16.0 + fmod(i * 5.1, 8), Color(0.08, 0.24, 0.06))
		# Right side
		var tx3 = fmod(i * 214.0 + 107.0 + t * 310.0, w + 90) - 90
		draw_rect(Rect2(w - tx3 - 12, h * 0.26, 12, tree_h * 0.9), Color(0.08, 0.20, 0.06))
		draw_circle(Vector2(w - tx3 - 6, h * 0.26), 20.0 + fmod(i * 6.2, 9), Color(0.10, 0.28, 0.08))

	# === TRUCK CABIN (player's vehicle, bottom of screen) ===
	draw_rect(Rect2(0, h - 95, 145, 95), Color(0.28, 0.14, 0.08))       # lower body
	draw_rect(Rect2(15, h - 175, 110, 85), Color(0.24, 0.11, 0.06))     # cabin top
	draw_rect(Rect2(22, h - 165, 96, 62), Color(0.12, 0.22, 0.32, 0.75))  # windshield
	# Windshield wiper
	var wiper_angle = sin(t * 1.8) * 0.4 - 0.2
	draw_line(Vector2(65, h - 107), Vector2(65 + sin(wiper_angle) * 72, h - 107 - cos(wiper_angle) * 55),
		Color(0.60, 0.58, 0.56), 2.5)
	# Dashboard glow
	draw_rect(Rect2(22, h - 105, 96, 12), Color(0.28, 0.42, 0.28, 0.45))
	draw_circle(Vector2(58, h - 100), 7, Color(0.20, 0.90, 0.20, 0.55))  # speedometer
	draw_circle(Vector2(82, h - 100), 5, Color(0.90, 0.50, 0.10, 0.45))  # fuel gauge
	# Side mirror
	draw_rect(Rect2(128, h - 155, 22, 14), Color(0.20, 0.10, 0.06))
	draw_rect(Rect2(130, h - 153, 18, 10), Color(0.08, 0.14, 0.22, 0.7))

	# === ONCOMING HEADLIGHTS (approaching vehicle) ===
	var hl = fmod(t * 0.28, 1.0)
	if hl > 0.45:
		var alpha = (hl - 0.45) / 0.55
		var hx1 = w * 0.44; var hx2 = w * 0.56
		var hy2 = horizon + 4.0
		draw_circle(Vector2(hx1, hy2), 5 + alpha * 6, Color(1.0, 0.95, 0.70, alpha * 0.75))
		draw_circle(Vector2(hx2, hy2), 5 + alpha * 6, Color(1.0, 0.95, 0.70, alpha * 0.75))
		# Light cones
		draw_colored_polygon(PackedVector2Array([
			Vector2(hx1 - 3, hy2), Vector2(hx1 + 3, hy2),
			Vector2(hx1 + 35, hy2 + 30), Vector2(hx1 - 35, hy2 + 30)
		]), Color(1.0, 0.95, 0.70, alpha * 0.15))
		draw_colored_polygon(PackedVector2Array([
			Vector2(hx2 - 3, hy2), Vector2(hx2 + 3, hy2),
			Vector2(hx2 + 35, hy2 + 30), Vector2(hx2 - 35, hy2 + 30)
		]), Color(1.0, 0.95, 0.70, alpha * 0.15))

	# === DYNAMISCHES EVENT: Polizei überholt DRAMATISCH (alle 16 s) ─────────
	var et_cop = fmod(_anim_time, 16.0)
	if et_cop < 5.0:
		var ep_cop = et_cop / 5.0
		var cop_y = h + 40.0 - ep_cop * (h + 120.0)
		var cop_x = w * 0.64

		# Flashing light glow on road
		var blink_cop = int(_anim_time * 10.0) % 2
		var glow_col = Color(0.1, 0.3, 1.0, 0.22) if blink_cop == 0 else Color(1.0, 0.1, 0.1, 0.22)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cop_x - 30, cop_y), Vector2(cop_x + 60, cop_y),
			Vector2(cop_x + 100, cop_y + 80), Vector2(cop_x - 80, cop_y + 80)
		]), glow_col)

		# Police car body
		draw_rect(Rect2(cop_x, cop_y - 28, 42, 60), Color(0.88, 0.90, 0.96))  # white body
		draw_rect(Rect2(cop_x + 4, cop_y - 22, 34, 34), Color(0.80, 0.84, 0.90, 0.85))  # windows
		draw_rect(Rect2(cop_x, cop_y - 5, 42, 10), Color(0.14, 0.16, 0.62))  # stripe
		# Light bar
		draw_rect(Rect2(cop_x + 6, cop_y - 38, 30, 10), Color(0.18, 0.18, 0.20))
		draw_circle(Vector2(cop_x + 12, cop_y - 33), 6,
			Color(0.1, 0.3, 1.0, 0.95) if blink_cop == 0 else Color(0.2, 0.2, 0.4, 0.5))
		draw_circle(Vector2(cop_x + 30, cop_y - 33), 6,
			Color(1.0, 0.1, 0.1, 0.95) if blink_cop == 0 else Color(0.4, 0.2, 0.2, 0.5))
		# Light cone from bar
		var cone_col = Color(0.1, 0.3, 1.0, 0.18) if blink_cop == 0 else Color(1.0, 0.1, 0.1, 0.18)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cop_x + 8, cop_y - 28), Vector2(cop_x + 16, cop_y - 28),
			Vector2(cop_x + 50, cop_y - 80), Vector2(cop_x - 28, cop_y - 80)
		]), cone_col)
		# Wheels
		draw_circle(Vector2(cop_x + 8, cop_y + 34), 10, Color(0.10, 0.10, 0.12))
		draw_circle(Vector2(cop_x + 34, cop_y + 34), 10, Color(0.10, 0.10, 0.12))
		draw_circle(Vector2(cop_x + 8, cop_y + 34), 5, Color(0.35, 0.34, 0.36))
		draw_circle(Vector2(cop_x + 34, cop_y + 34), 5, Color(0.35, 0.34, 0.36))

# ── Tonstudio Soundlodge ─────────────────────────────────────────────────────
func _draw_tonstudio(vp: Rect2) -> void:
	var w = vp.size.x
	var h = vp.size.y
	# Dark studio
	draw_rect(Rect2(0, 0, w, h), Color(0.06, 0.05, 0.08))
	# Acoustic panels (walls top and sides)
	for i in range(6):
		var px = i * 215.0
		draw_rect(Rect2(px + 2, 2, 210, 55), Color(0.12, 0.1, 0.08))
		for j in range(7):
			for k in range(2):
				draw_colored_polygon(PackedVector2Array([
					Vector2(px + 5 + j * 30, 5 + k * 28),
					Vector2(px + 19 + j * 30, 5 + k * 28),
					Vector2(px + 12 + j * 30, 30 + k * 28)
				]), Color(0.08, 0.06, 0.05))
	# Mixing console (center bottom)
	draw_rect(Rect2(w * 0.2, h - 90, w * 0.6, 90), Color(0.12, 0.1, 0.08))
	draw_rect(Rect2(w * 0.22, h - 80, w * 0.56, 70), Color(0.08, 0.07, 0.06))
	# Faders
	for i in range(16):
		var fx = w * 0.23 + i * (w * 0.54 / 16.0)
		draw_rect(Rect2(fx, h - 75, 6, 55), Color(0.18, 0.18, 0.2))
		var fader_y = h - 75 + fmod(i * 17.3, 40.0)
		draw_rect(Rect2(fx - 3, fader_y, 12, 8), Color(0.7, 0.7, 0.75))
	# VU meters
	for i in range(8):
		var mx = w * 0.65 + i * 40.0
		draw_rect(Rect2(mx, h - 140, 18, 50), Color(0.05, 0.05, 0.06))
		var level = (sin(_anim_time * 3.0 + i * 0.8) * 0.5 + 0.5)
		draw_rect(Rect2(mx + 2, h - 138 + (1.0 - level) * 46, 14, level * 46), Color(0.1 + level * 0.8, 0.8 - level * 0.5, 0.1))
	# Recording light
	var blink = int(_anim_time * 2.0) % 2
	draw_circle(Vector2(w - 40, 35), 14, Color(0.7 + blink * 0.3, 0.05, 0.05))
	draw_circle(Vector2(w - 40, 35), 8, Color(1.0 * blink, 0.1 * blink, 0.1 * blink))
	# Speaker monitors
	draw_rect(Rect2(30, h * 0.5, 70, 100), Color(0.1, 0.08, 0.07))
	draw_circle(Vector2(65, h * 0.5 + 35), 22, Color(0.06, 0.06, 0.07))
	draw_circle(Vector2(65, h * 0.5 + 80), 12, Color(0.06, 0.06, 0.07))
	draw_rect(Rect2(w - 100, h * 0.5, 70, 100), Color(0.1, 0.08, 0.07))
	draw_circle(Vector2(w - 65, h * 0.5 + 35), 22, Color(0.06, 0.06, 0.07))
	draw_circle(Vector2(w - 65, h * 0.5 + 80), 12, Color(0.06, 0.06, 0.07))

	# === ANIMIERTER EQUALIZER (Wanddisplay) ===
	for eqi in range(12):
		var eq_x = w * 0.22 + eqi * (w * 0.56 / 12.0)
		var eq_h = 20.0 + abs(sin(_anim_time * (2.0 + eqi * 0.3) + eqi)) * 55.0
		var eq_col = Color(0.1 + eqi * 0.07, 0.8 - eqi * 0.04, 0.1)
		if eq_h > 50: eq_col = Color(0.8, 0.6, 0.0)
		if eq_h > 65: eq_col = Color(0.9, 0.1, 0.0)
		draw_rect(Rect2(eq_x, h * 0.28 - eq_h, 18, eq_h), eq_col)
	draw_rect(Rect2(w * 0.22, h * 0.25, w * 0.56, 4), Color(0.04, 0.04, 0.05))  # Rahmen unten

	# === MIKROFON AUF STÄNDER (Mitte) ===
	var mic_x = w * 0.5; var mic_y = h * 0.38
	draw_line(Vector2(mic_x, mic_y + 60), Vector2(mic_x, h - 90), Color(0.40, 0.40, 0.44), 3)
	draw_line(Vector2(mic_x - 20, h - 90), Vector2(mic_x + 20, h - 90), Color(0.40, 0.40, 0.44), 3)
	draw_rect(Rect2(mic_x - 8, mic_y + 42, 16, 20), Color(0.30, 0.30, 0.34))
	draw_ellipse_approx(Vector2(mic_x, mic_y + 28), Vector2(12, 16), Color(0.22, 0.22, 0.25))
	# Gitter des Mikrofons
	for gri in range(3):
		draw_arc(Vector2(mic_x, mic_y + 28), 5 + gri * 3, 0, TAU, 10, Color(0.40, 0.40, 0.44), 1.0)

	# === KOPFHÖRER (am Tisch) ===
	draw_arc(Vector2(w * 0.35, h - 100), 12, PI, TAU, 8, Color(0.18, 0.18, 0.20), 5)
	draw_circle(Vector2(w * 0.35 - 12, h - 100), 8, Color(0.14, 0.14, 0.16))
	draw_circle(Vector2(w * 0.35 + 12, h - 100), 8, Color(0.14, 0.14, 0.16))

	# === DYNAMISCHES EVENT: Kaffeetasse fällt vom Mischpult (alle 18 s) ─────
	var et_cup = fmod(_anim_time, 18.0)
	if et_cup < 2.5:
		var ep_cup = et_cup / 2.5
		var cup_x = w * 0.58
		var cup_y = h - 90.0 + ep_cup * 100.0
		if ep_cup < 0.7:
			draw_rect(Rect2(cup_x - 8, cup_y - 12, 16, 14), Color(0.72, 0.50, 0.32))
			draw_rect(Rect2(cup_x - 6, cup_y - 10, 12, 10), Color(0.25, 0.15, 0.08))
			draw_rect(Rect2(cup_x + 8, cup_y - 8, 6, 8), Color(0.72, 0.50, 0.32))
		else:
			var splat_p = (ep_cup - 0.7) / 0.3
			draw_ellipse_approx(Vector2(cup_x, h - 14), Vector2(28 * splat_p, 8 * splat_p), Color(0.25, 0.14, 0.06, 0.85))
			for spi in range(6):
				var spangle = float(spi) / 6.0 * TAU
				draw_circle(Vector2(cup_x + cos(spangle) * 24 * splat_p, h - 14 + sin(spangle) * 10 * splat_p),
					3.0 * splat_p, Color(0.30, 0.18, 0.08, 0.75))

# ── TV Studio ────────────────────────────────────────────────────────────────
func _draw_tv_studio(vp: Rect2) -> void:
	var w = vp.size.x
	var h = vp.size.y
	var t = _anim_time

	# === STUDIO VOID (background) ===
	draw_rect(Rect2(0, 0, w, h), Color(0.06, 0.05, 0.10))

	# === STUDIO BACKDROP (cyclorama wall with gradient) ===
	draw_rect(Rect2(w * 0.05, h * 0.06, w * 0.90, h * 0.52), Color(0.10, 0.09, 0.16))
	draw_rect(Rect2(w * 0.05, h * 0.06, w * 0.90, h * 0.18), Color(0.08, 0.07, 0.14))
	# Backdrop decorative panels / set pieces
	for bpi in range(5):
		var bpx = w * 0.08 + bpi * (w * 0.84 / 4.0)
		draw_rect(Rect2(bpx - 22, h * 0.10, 44, h * 0.42), Color(0.12, 0.10, 0.18))
		draw_rect(Rect2(bpx - 20, h * 0.12, 40, h * 0.38), Color(0.08, 0.07, 0.13))
		# Panel inner glow
		var panel_glow = 0.3 + sin(t * 1.4 + bpi * 0.8) * 0.08
		draw_rect(Rect2(bpx - 16, h * 0.14, 32, h * 0.32), Color(0.14 * panel_glow, 0.12 * panel_glow, 0.22 * panel_glow))

	# === LIGHTING RIG (horizontal bar across top) ===
	draw_rect(Rect2(w * 0.02, 8, w * 0.96, 14), Color(0.18, 0.16, 0.20))
	for li in range(10):
		var lx2 = w * 0.04 + li * (w * 0.92 / 9.0)
		draw_line(Vector2(lx2, 22), Vector2(lx2, 36), Color(0.25, 0.22, 0.28), 2)
		# Light fixture
		draw_rect(Rect2(lx2 - 14, 36, 28, 20), Color(0.22, 0.20, 0.26))
		draw_circle(Vector2(lx2, 50), 10, Color(0.15, 0.14, 0.18))

	# === ANIMATED SPOTLIGHT BEAMS ===
	var spot_colors = [
		Color(1.0, 0.3, 0.3), Color(0.3, 0.6, 1.0), Color(0.3, 1.0, 0.5),
		Color(1.0, 0.8, 0.2), Color(0.9, 0.3, 1.0), Color(1.0, 0.5, 0.2)
	]
	for si in range(6):
		var s_lx = w * 0.08 + si * (w * 0.84 / 5.0)
		var sweep = sin(t * (0.55 + si * 0.13) + si * 0.8) * 0.28
		var s_end_x = s_lx + sin(sweep) * h * 0.44
		var sc = spot_colors[si]
		var beam_alpha = 0.07 + abs(sin(t * 0.6 + si)) * 0.04
		draw_colored_polygon(PackedVector2Array([
			Vector2(s_lx - 7, 56), Vector2(s_lx + 7, 56),
			Vector2(s_end_x + 70, h * 0.58), Vector2(s_end_x - 70, h * 0.58)
		]), Color(sc.r, sc.g, sc.b, beam_alpha))
		# Light circle at fixture
		var bright = 0.5 + abs(sin(t * 1.2 + si)) * 0.4
		draw_circle(Vector2(s_lx, 50), 12, Color(sc.r * bright, sc.g * bright, sc.b * bright, 0.85))
		# Spotlight pool on floor
		draw_ellipse_approx(Vector2(s_end_x, h * 0.59),
			Vector2(55.0 + abs(sin(sweep)) * 30, 12),
			Color(sc.r, sc.g, sc.b, 0.08))

	# === STAGE PLATFORM ===
	draw_rect(Rect2(w * 0.05, h * 0.56, w * 0.90, 16), Color(0.28, 0.24, 0.34))
	draw_rect(Rect2(w * 0.05, h * 0.56, w * 0.90, 5), Color(0.40, 0.36, 0.48))
	draw_rect(Rect2(w * 0.05, h * 0.56 + 13, w * 0.90, 3), Color(0.18, 0.15, 0.22))
	# Stage floor (shiny parquet)
	draw_rect(Rect2(0, h * 0.58, w, h * 0.42), Color(0.14, 0.12, 0.18))
	# Floor reflection lines
	for ri in range(9):
		draw_line(Vector2(0, h * 0.60 + ri * 48), Vector2(w, h * 0.60 + ri * 48),
			Color(1, 1, 1, 0.025 + (ri % 2) * 0.01))
	# Floor reflection of lights
	for si2 in range(6):
		var s_lx2 = w * 0.08 + si2 * (w * 0.84 / 5.0)
		var sc2 = spot_colors[si2]
		draw_ellipse_approx(Vector2(s_lx2, h * 0.72), Vector2(35, 18),
			Color(sc2.r, sc2.g, sc2.b, 0.06))

	# === CAMERA 1 on tripod (left side) ===
	var c1x = w * 0.12; var c1y = h * 0.38
	# Tripod legs
	draw_line(Vector2(c1x, c1y + 30), Vector2(c1x - 38, h * 0.58), Color(0.28, 0.26, 0.32), 2.5)
	draw_line(Vector2(c1x, c1y + 30), Vector2(c1x,      h * 0.58), Color(0.28, 0.26, 0.32), 2.5)
	draw_line(Vector2(c1x, c1y + 30), Vector2(c1x + 38, h * 0.58), Color(0.28, 0.26, 0.32), 2.5)
	# Tripod crossbar
	draw_line(Vector2(c1x - 24, h * 0.51), Vector2(c1x + 24, h * 0.51), Color(0.28, 0.26, 0.32), 1.5)
	# Camera body
	draw_rect(Rect2(c1x - 26, c1y - 18, 52, 36), Color(0.14, 0.13, 0.18))
	draw_rect(Rect2(c1x - 22, c1y - 14, 44, 28), Color(0.10, 0.09, 0.14))
	# Lens barrel
	draw_circle(Vector2(c1x + 30, c1y), 18, Color(0.08, 0.07, 0.10))
	draw_circle(Vector2(c1x + 30, c1y), 12, Color(0.04, 0.04, 0.06))
	draw_circle(Vector2(c1x + 30, c1y),  5, Color(0.08, 0.12, 0.22))
	# Viewfinder on top
	draw_rect(Rect2(c1x - 8, c1y - 30, 20, 14), Color(0.20, 0.18, 0.24))
	# Camera operator RED light
	var cam_rec = int(t * 1.4) % 2
	draw_circle(Vector2(c1x - 20, c1y - 14), 4, Color(0.9, 0.05, 0.05, 0.6 + cam_rec * 0.4))

	# === CAMERA 2 on tripod (right side) ===
	var c2x = w * 0.88; var c2y = h * 0.40
	draw_line(Vector2(c2x, c2y + 30), Vector2(c2x - 38, h * 0.58), Color(0.28, 0.26, 0.32), 2.5)
	draw_line(Vector2(c2x, c2y + 30), Vector2(c2x,      h * 0.58), Color(0.28, 0.26, 0.32), 2.5)
	draw_line(Vector2(c2x, c2y + 30), Vector2(c2x + 38, h * 0.58), Color(0.28, 0.26, 0.32), 2.5)
	draw_line(Vector2(c2x - 24, h * 0.51), Vector2(c2x + 24, h * 0.51), Color(0.28, 0.26, 0.32), 1.5)
	draw_rect(Rect2(c2x - 26, c2y - 18, 52, 36), Color(0.14, 0.13, 0.18))
	draw_circle(Vector2(c2x - 30, c2y), 18, Color(0.08, 0.07, 0.10))
	draw_circle(Vector2(c2x - 30, c2y), 12, Color(0.04, 0.04, 0.06))
	draw_circle(Vector2(c2x - 30, c2y),  5, Color(0.08, 0.12, 0.22))
	draw_rect(Rect2(c2x - 12, c2y - 30, 20, 14), Color(0.20, 0.18, 0.24))

	# === AUDIENCE SILHOUETTES ===
	var aud_rng = RandomNumberGenerator.new()
	aud_rng.seed = 62831
	for ai in range(32):
		var ax = 10.0 + ai * (w / 31.0)
		var row_offset = (ai % 3) * 18.0
		var ay = h * 0.68 + row_offset + aud_rng.randf_range(-6, 6)
		var head_size = 9.0 + aud_rng.randf_range(0, 5)
		# Body
		draw_rect(Rect2(ax - 8, ay, 16, 24), Color(0.06, 0.05, 0.09))
		# Head
		draw_circle(Vector2(ax, ay - 6), head_size, Color(0.07, 0.06, 0.10))
		# Clapping hands animation (some audience members)
		if ai % 4 == 0:
			var clap_phase = fmod(t * 3.2 + ai * 0.4, 1.0)
			var clap_spread = abs(sin(clap_phase * PI)) * 14.0
			draw_circle(Vector2(ax - clap_spread, ay + 14), 4, Color(0.08, 0.07, 0.11))
			draw_circle(Vector2(ax + clap_spread, ay + 14), 4, Color(0.08, 0.07, 0.11))
		elif ai % 4 == 1:
			# Raised arm
			var arm_wave = sin(t * 2.8 + ai) * 0.45
			draw_line(Vector2(ax, ay + 6),
				Vector2(ax + sin(arm_wave) * 16, ay - 22),
				Color(0.08, 0.07, 0.11), 3.5)

	# === APPLAUSE METER (right side) ===
	var meter_x = w - 52; var meter_y = h * 0.62
	draw_rect(Rect2(meter_x - 2, meter_y, 28, 80), Color(0.12, 0.10, 0.16))
	var applause_fill = 0.55 + sin(t * 2.1) * 0.30
	for ami in range(8):
		var abar_y = meter_y + 74 - ami * 10
		var lit = float(ami) / 8.0 < applause_fill
		var abar_col: Color
		if not lit:
			abar_col = Color(0.12, 0.10, 0.14)
		elif ami < 4:
			abar_col = Color(0.15, 0.80, 0.15)
		elif ami < 6:
			abar_col = Color(0.90, 0.75, 0.10)
		else:
			abar_col = Color(0.95, 0.15, 0.10)
		draw_rect(Rect2(meter_x, abar_y, 24, 8), abar_col)

	# === PROPS / SET PIECES ===
	# Podium / host desk
	draw_rect(Rect2(w * 0.42, h * 0.44, w * 0.16, 38), Color(0.22, 0.18, 0.28))
	draw_rect(Rect2(w * 0.42, h * 0.44, w * 0.16, 6), Color(0.32, 0.26, 0.40))
	draw_rect(Rect2(w * 0.43, h * 0.44 + 8, w * 0.14, 10), Color(0.16, 0.14, 0.22))
	# Microphone on desk
	var mic2_x = w * 0.50; var mic2_y = h * 0.44
	draw_line(Vector2(mic2_x, mic2_y + 2), Vector2(mic2_x, mic2_y - 16), Color(0.40, 0.38, 0.44), 2.0)
	draw_ellipse_approx(Vector2(mic2_x, mic2_y - 22), Vector2(7, 9), Color(0.22, 0.20, 0.26))
	# Monitor on desk
	draw_rect(Rect2(w * 0.44, h * 0.46, 24, 18), Color(0.08, 0.07, 0.11))
	draw_rect(Rect2(w * 0.445, h * 0.462, 20, 14), Color(0.10, 0.28, 0.44, 0.9))
	# Water glass
	draw_rect(Rect2(w * 0.56, h * 0.46 + 2, 10, 16), Color(0.28, 0.44, 0.58, 0.55))

	# === ON AIR SIGN ===
	var blink2 = int(t * 1.5) % 2
	draw_rect(Rect2(w * 0.5 - 72, 10, 144, 38), Color(0.18, 0.08, 0.08))
	draw_rect(Rect2(w * 0.5 - 70, 12, 140, 34), Color(0.58 + blink2 * 0.38, 0.04, 0.04))
	draw_rect(Rect2(w * 0.5 - 72, 10, 144, 38), Color(1, 0.3, 0.3, 0.5 + blink2 * 0.4), false, 2.0)

	# === TELEPROMPTER ===
	draw_rect(Rect2(w * 0.38, h * 0.18, w * 0.24, 94), Color(0.05, 0.04, 0.08))
	draw_rect(Rect2(w * 0.385, h * 0.19, w * 0.23, 84), Color(0.08, 0.24, 0.42, 0.92))
	# Scrolling text lines
	var scroll_off = fmod(t * 14.0, 14.0)
	for tli in range(6):
		var tly = h * 0.20 + tli * 13.0 - scroll_off
		if tly > h * 0.19 and tly < h * 0.19 + 80:
			var line_w = 55.0 + fmod(tli * 37.3, 60.0)
			draw_rect(Rect2(w * 0.40, tly, line_w, 5), Color(1.0, 1.0, 1.0, 0.55))

	# === DYNAMISCHES EVENT: Kamera kippt um (alle 15 s) ─────────────────────
	var et_cam = fmod(_anim_time, 15.0)
	if et_cam < 3.2:
		var ep_cam = et_cam / 3.2
		var cam_cx = c1x; var cam_cy2 = c1y
		var tilt = ep_cam * PI * 0.5
		draw_line(Vector2(cam_cx, cam_cy2 + 20),
			Vector2(cam_cx + sin(tilt) * 60, cam_cy2 + 20 + cos(tilt) * 60 - 60),
			Color(0.35, 0.32, 0.35), 4)
		if ep_cam < 0.7:
			draw_rect(Rect2(cam_cx - 30 + sin(tilt) * 30, cam_cy2 - 20 + (1.0 - cos(tilt)) * 30, 60, 40), Color(0.15, 0.15, 0.18))
		else:
			draw_rect(Rect2(cam_cx - 10, cam_cy2 + 35, 60, 15), Color(0.15, 0.15, 0.18))
			for spi in range(5):
				var spangle = spi * 0.55 - 0.8
				var sdist = (ep_cam - 0.7) / 0.3 * 28.0
				draw_line(Vector2(cam_cx + 30, cam_cy2 + 42),
					Vector2(cam_cx + 30 + cos(spangle) * sdist, cam_cy2 + 42 + sin(spangle) * sdist),
					Color(1.0, 0.8, 0.1, (1.0 - (ep_cam - 0.7) / 0.3) * 0.9), 2.0)

# ── Meppen ───────────────────────────────────────────────────────────────────
func _draw_meppen(vp: Rect2) -> void:
	# ── Luftbild-Perspektive: Blick von oben auf den Marktplatz ─────────────
	var w = vp.size.x
	var h = vp.size.y
	var t = _anim_time

	# === COBBLESTONE BASE ===
	draw_rect(Rect2(0, 0, w, h), Color(0.54, 0.52, 0.50))
	var cob_rng = RandomNumberGenerator.new()
	cob_rng.seed = 20241
	for row in range(16):
		for col in range(22):
			var off_m = 36 if row % 2 == 1 else 0
			var stone_var = cob_rng.randf_range(-0.03, 0.04)
			var base_bright = 0.50 + (row + col) % 2 * 0.07 + stone_var
			draw_rect(Rect2(col * 68 - off_m, row * 50, 66, 48),
				Color(base_bright, base_bright * 0.96, base_bright * 0.93))
			# Occasional moss / stain on stone
			if cob_rng.randf() < 0.12:
				draw_circle(Vector2(col * 68 - off_m + cob_rng.randf_range(5, 55),
					row * 50 + cob_rng.randf_range(4, 38)),
					cob_rng.randf_range(3, 9), Color(0.38, 0.44, 0.30, 0.28))
	# Stone joints (horizontal + vertical lines)
	for row2 in range(17):
		draw_line(Vector2(0, row2 * 50), Vector2(w, row2 * 50), Color(0.36, 0.34, 0.32, 0.55), 1.2)
	for col2 in range(23):
		draw_line(Vector2(col2 * 68, 0), Vector2(col2 * 68, h), Color(0.36, 0.34, 0.32, 0.40), 0.8)

	# === STREETS (crossing the square) ===
	draw_rect(Rect2(w * 0.46, 0, w * 0.08, h), Color(0.34, 0.32, 0.30))
	draw_rect(Rect2(0, h * 0.46, w, h * 0.08), Color(0.34, 0.32, 0.30))
	# Asphalt texture on roads
	var asp_rng = RandomNumberGenerator.new()
	asp_rng.seed = 55443
	for aspi in range(14):
		var ax2 = asp_rng.randf_range(w * 0.46, w * 0.54)
		var ay2 = asp_rng.randf_range(0, h)
		draw_circle(Vector2(ax2, ay2), asp_rng.randf_range(2, 7), Color(0.28, 0.27, 0.25, 0.35))
	for aspi2 in range(14):
		var ax3 = asp_rng.randf_range(0, w)
		var ay3 = asp_rng.randf_range(h * 0.46, h * 0.54)
		draw_circle(Vector2(ax3, ay3), asp_rng.randf_range(2, 7), Color(0.28, 0.27, 0.25, 0.35))
	# Road markings
	for i in range(9):
		draw_rect(Rect2(w * 0.493, i * (h / 8.0) + 8, 10, 38), Color(0.85, 0.80, 0.25, 0.72))
		draw_rect(Rect2(i * (w / 8.0) + 8, h * 0.493, 38, 10), Color(0.85, 0.80, 0.25, 0.72))
	# Crosswalk (Zebrastreifen) at intersection
	for zi in range(6):
		draw_rect(Rect2(w * 0.46, h * 0.48 + zi * 8, w * 0.08, 4), Color(0.85, 0.84, 0.82, 0.65))
		draw_rect(Rect2(w * 0.48 + zi * 8, h * 0.46, 4, h * 0.08), Color(0.85, 0.84, 0.82, 0.65))

	# === MARKET FOUNTAIN ===
	var fc = Vector2(w * 0.5, h * 0.5)
	draw_circle(fc, 58, Color(0.68, 0.66, 0.64))       # outer rim
	draw_circle(fc, 50, Color(0.26, 0.40, 0.55))       # water
	draw_circle(fc, 46, Color(0.28, 0.42, 0.58, 0.9))  # water inner
	draw_circle(fc, 14, Color(0.65, 0.62, 0.58))       # central column
	draw_circle(fc,  9, Color(0.55, 0.52, 0.48))
	# Animated water ripples
	for wri in range(3):
		var wr_phase = fmod(t * 0.6 + wri * 0.33, 1.0)
		var wr_rad = wr_phase * 44.0
		if wr_rad > 2.0:
			draw_arc(fc, wr_rad, 0, TAU, 18, Color(0.55, 0.70, 0.88, (1.0 - wr_phase) * 0.40), 1.2)
	# Fountain spray (animated dots)
	for fsi in range(8):
		var fsa = float(fsi) / 8.0 * TAU + t * 0.5
		var fsph = fmod(t * 1.8 + float(fsi) * 0.4, 1.0)
		var fsr = 4.0 + fsph * 18.0
		draw_circle(Vector2(fc.x + cos(fsa) * fsr, fc.y + sin(fsa) * fsr * 0.6 - fsph * 8),
			1.5 + (1.0 - fsph) * 2, Color(0.55, 0.75, 0.95, (1.0 - fsph) * 0.6))

	# === CHURCH / STEEPLE (top-down, detailed) ===
	var ch_x = w * 0.06; var ch_y = h * 0.06
	# Church nave
	draw_rect(Rect2(ch_x, ch_y + 44, 80, 60), Color(0.44, 0.42, 0.40))
	draw_line(Vector2(ch_x + 40, ch_y + 44), Vector2(ch_x + 40, ch_y + 104), Color(0.34, 0.32, 0.30, 0.4), 3)
	# Tower top-down
	draw_rect(Rect2(ch_x + 8, ch_y, 64, 50), Color(0.38, 0.36, 0.34))
	draw_rect(Rect2(ch_x + 16, ch_y + 8, 48, 34), Color(0.32, 0.30, 0.28))
	# Cross on top
	draw_line(Vector2(ch_x + 40, ch_y + 10), Vector2(ch_x + 40, ch_y + 40), Color(0.75, 0.72, 0.68), 5)
	draw_line(Vector2(ch_x + 24, ch_y + 22), Vector2(ch_x + 56, ch_y + 22), Color(0.75, 0.72, 0.68), 5)
	# Church windows (viewed from above as dark rectangles)
	for cwi in range(3):
		draw_rect(Rect2(ch_x + 6 + cwi * 24, ch_y + 52, 14, 10), Color(0.20, 0.24, 0.32))

	# === BUILDING FACADES (top-down with windows) ===
	var roof_cols = [Color(0.64, 0.28, 0.16), Color(0.46, 0.43, 0.40), Color(0.36, 0.30, 0.56),
		Color(0.56, 0.48, 0.34), Color(0.28, 0.38, 0.24), Color(0.52, 0.34, 0.22),
		Color(0.40, 0.36, 0.56), Color(0.60, 0.42, 0.22)]
	var hpos = [Vector2(w*0.18, h*0.05), Vector2(w*0.40, h*0.05), Vector2(w*0.62, h*0.05),
		Vector2(w*0.76, h*0.12), Vector2(w*0.05, h*0.58), Vector2(w*0.76, h*0.58),
		Vector2(w*0.18, h*0.80), Vector2(w*0.58, h*0.80)]
	var hsizes = [Vector2(82, 60), Vector2(76, 52), Vector2(88, 60), Vector2(70, 58),
		Vector2(80, 54), Vector2(74, 62), Vector2(86, 58), Vector2(78, 56)]
	for i in range(hpos.size()):
		var hx2 = hpos[i].x; var hy2 = hpos[i].y
		var bw2 = hsizes[i].x; var bh2 = hsizes[i].y
		draw_rect(Rect2(hx2, hy2, bw2, bh2), roof_cols[i % roof_cols.size()])
		# Ridge line
		draw_line(Vector2(hx2 + bw2 * 0.5, hy2 + 2), Vector2(hx2 + bw2 * 0.5, hy2 + bh2 - 2),
			Color(0, 0, 0, 0.20), 3)
		# Chimney
		draw_rect(Rect2(hx2 + 12, hy2 - 9, 16, 14), Color(0.34, 0.30, 0.28))
		draw_rect(Rect2(hx2 + 13, hy2 - 8, 14, 5), Color(0.24, 0.22, 0.20))
		# Windows (viewed from above: small dark rectangles in rows)
		for wi3 in range(3):
			for wj3 in range(2):
				draw_rect(Rect2(hx2 + 8 + wi3 * (bw2 * 0.28), hy2 + 8 + wj3 * 18,
					12, 8), Color(0.18, 0.20, 0.26))
				# Window light (some randomly lit)
				if (i + wi3 + wj3) % 3 != 0:
					draw_rect(Rect2(hx2 + 9 + wi3 * (bw2 * 0.28), hy2 + 9 + wj3 * 18,
						10, 6), Color(0.82, 0.72, 0.40, 0.65))

	# === MARKET STALLS (Marktbuden, top-down) ===
	var stall_positions = [
		Vector2(w * 0.28, h * 0.28), Vector2(w * 0.62, h * 0.28),
		Vector2(w * 0.28, h * 0.68), Vector2(w * 0.62, h * 0.68)
	]
	var stall_colors = [Color(0.80, 0.18, 0.12), Color(0.14, 0.40, 0.16), Color(0.18, 0.22, 0.72), Color(0.72, 0.62, 0.12)]
	for sti in range(4):
		var stx = stall_positions[sti].x; var sty = stall_positions[sti].y
		var stc = stall_colors[sti]
		draw_rect(Rect2(stx - 28, sty - 18, 56, 36), stc)
		draw_rect(Rect2(stx - 26, sty - 16, 52, 32), stc.darkened(0.25))
		# Striped awning
		for stri in range(6):
			draw_rect(Rect2(stx - 28 + stri * 9, sty - 18, 4, 36), Color(1, 1, 1, 0.22))
		# Goods on stall (small dots)
		for gi2 in range(8):
			draw_circle(Vector2(stx - 20 + gi2 * 6, sty + sti * 0.5),
				2.5, Color(0.90, 0.60, 0.22, 0.75))

	# === BEER GARDEN TABLES ===
	var bg_rng = RandomNumberGenerator.new()
	bg_rng.seed = 11122
	for bgi in range(5):
		var bgx = w * 0.20 + bgi * (w * 0.60 / 4.0) + bg_rng.randf_range(-12, 12)
		var bgy = h * 0.82 + bg_rng.randf_range(-8, 8)
		# Table top
		draw_ellipse_approx(Vector2(bgx, bgy), Vector2(22, 14), Color(0.52, 0.38, 0.18))
		draw_ellipse_approx(Vector2(bgx, bgy), Vector2(18, 10), Color(0.62, 0.48, 0.24))
		# Beer glasses (tiny circles)
		for bci in range(4):
			var bca = float(bci) / 4.0 * TAU
			draw_circle(Vector2(bgx + cos(bca) * 12, bgy + sin(bca) * 7), 3,
				Color(0.88, 0.78, 0.22, 0.8))
			draw_circle(Vector2(bgx + cos(bca) * 12, bgy + sin(bca) * 7), 2,
				Color(0.95, 0.88, 0.55, 0.7))
		# Bench seats
		draw_rect(Rect2(bgx - 26, bgy - 22, 52, 7), Color(0.44, 0.30, 0.14))
		draw_rect(Rect2(bgx - 26, bgy + 16, 52, 7), Color(0.44, 0.30, 0.14))

	# === NIEDERSACHSEN FLAGS / BANNERS on lamp posts ===
	var lamp_positions = [w * 0.30, w * 0.50, w * 0.70]
	for lpi in range(3):
		var lpx = lamp_positions[lpi]; var lpy = h * 0.32
		draw_circle(Vector2(lpx, lpy), 5, Color(0.42, 0.40, 0.36))  # post top
		draw_rect(Rect2(lpx - 3, lpy, 6, 36), Color(0.38, 0.36, 0.32))  # pole
		# Niedersachsen-Flagge: oben schwarz, unten gold
		var wave_a = sin(t * 1.8 + lpi * 0.7) * 2.0
		var fwave  = sin(t * 1.8 + lpi * 0.7 + 0.4) * 1.0
		draw_rect(Rect2(lpx + 3, lpy + 4,  26, 9), Color(0.10, 0.10, 0.10))  # schwarz
		draw_rect(Rect2(lpx + 3, lpy + 13, 26, 9), Color(0.90, 0.78, 0.08))  # gold
		# Sachsenross (stilisiertes weißes Pferd auf schwarzem Streifen)
		var hx = lpx + 3; var hy = lpy + 4
		draw_circle(Vector2(hx + 10, hy + 5), 3.5, Color(0.94, 0.94, 0.94))   # Rumpf
		draw_circle(Vector2(hx + 14, hy + 3), 2.2, Color(0.94, 0.94, 0.94))   # Hals
		draw_circle(Vector2(hx + 17, hy + 2), 2.0, Color(0.94, 0.94, 0.94))   # Kopf
		draw_line(Vector2(hx + 8,  hy + 8), Vector2(hx + 7,  hy + 13), Color(0.94, 0.94, 0.94), 1.5)  # Hinterbein
		draw_line(Vector2(hx + 11, hy + 8), Vector2(hx + 12, hy + 13), Color(0.94, 0.94, 0.94), 1.5)  # Hinterbein 2
		draw_line(Vector2(hx + 13, hy + 7), Vector2(hx + 11, hy + 3),  Color(0.94, 0.94, 0.94), 1.5)  # Vorderbein erhoben
		draw_line(Vector2(hx + 10, hy + 8), Vector2(hx + 9,  hy + 13), Color(0.94, 0.94, 0.94), 1.2)  # Vorderbein
		# Flatterndes Flaggenkanten-Detail
		draw_line(Vector2(lpx + 29, lpy + 6  + fwave), Vector2(lpx + 34 + wave_a, lpy + 4),
			Color(0.10, 0.10, 0.10, 0.55), 1.5)
		draw_line(Vector2(lpx + 29, lpy + 19 + fwave), Vector2(lpx + 34 + wave_a, lpy + 22),
			Color(0.90, 0.78, 0.08, 0.55), 1.5)

	# === BÄUME (Allee entlang beider Straßen) ===
	var tc_out = Color(0.20, 0.36, 0.14)
	var tc_mid = Color(0.16, 0.30, 0.10)
	var tc_in  = Color(0.12, 0.24, 0.08)
	# Allee entlang der HORIZONTALEN Strasse (links und rechts der Kreuzung)
	var hallee_xs = [w*0.08, w*0.20, w*0.32, w*0.64, w*0.76, w*0.88]
	for axi in range(hallee_xs.size()):
		var atx = hallee_xs[axi]
		for aty in [h * 0.455, h * 0.545]:
			draw_ellipse_approx(Vector2(atx + 5, aty + 5), Vector2(20, 9), Color(0, 0, 0, 0.16))
			draw_circle(Vector2(atx, aty), 22, tc_out)
			draw_circle(Vector2(atx, aty), 14, tc_mid)
			draw_circle(Vector2(atx, aty),  5, tc_in)
	# Allee entlang der VERTIKALEN Strasse (oberhalb und unterhalb der Kreuzung)
	var vallee_ys = [h*0.08, h*0.20, h*0.32, h*0.64, h*0.76, h*0.88]
	for ayi in range(vallee_ys.size()):
		var aty2 = vallee_ys[ayi]
		for atx2 in [w * 0.455, w * 0.545]:
			draw_ellipse_approx(Vector2(atx2 + 5, aty2 + 5), Vector2(20, 9), Color(0, 0, 0, 0.16))
			draw_circle(Vector2(atx2, aty2), 22, tc_out)
			draw_circle(Vector2(atx2, aty2), 14, tc_mid)
			draw_circle(Vector2(atx2, aty2),  5, tc_in)

	# === PARKING LINES ===
	for pli in range(7):
		draw_rect(Rect2(w * 0.20 + pli * 50, h * 0.90, 46, 5), Color(0.85, 0.84, 0.82, 0.60))
		draw_line(Vector2(w * 0.20 + pli * 50, h * 0.88),
			Vector2(w * 0.20 + pli * 50, h * 0.96), Color(0.70, 0.68, 0.65, 0.45), 1.0)

	# === DYNAMISCHES EVENT: Polizeiauto fährt durch (alle 16 s) ─────────────
	var et_mep = fmod(_anim_time, 16.0)
	if et_mep < 5.0:
		var ep_mep = et_mep / 5.0
		var mepx = -80.0 + ep_mep * (w + 160.0)
		var mepy = h * 0.50
		draw_rect(Rect2(mepx - 22, mepy - 14, 44, 28), Color(0.88, 0.90, 0.96))  # white body
		draw_rect(Rect2(mepx - 22, mepy - 5, 44, 10), Color(0.14, 0.16, 0.62))    # stripe
		draw_rect(Rect2(mepx - 10, mepy - 14, 20, 12), Color(0.80, 0.84, 0.90, 0.85))  # windshield
		var blink_mep = int(_anim_time * 8.0) % 2
		draw_circle(Vector2(mepx - 8, mepy - 20), 6,
			Color(0.1, 0.3, 1.0, 0.95) if blink_mep == 0 else Color(1.0, 0.15, 0.15, 0.95))
		draw_circle(Vector2(mepx + 8, mepy - 20), 6,
			Color(1.0, 0.15, 0.15, 0.95) if blink_mep == 0 else Color(0.1, 0.3, 1.0, 0.95))
		# Light glow on road
		var glow_c = Color(0.1, 0.3, 1.0, 0.18) if blink_mep == 0 else Color(1.0, 0.15, 0.15, 0.18)
		draw_ellipse_approx(Vector2(mepx, mepy - 8), Vector2(38, 18), glow_c)
		# Headlight cones
		draw_colored_polygon(PackedVector2Array([
			Vector2(mepx + 20, mepy - 10), Vector2(mepx + 20, mepy + 10),
			Vector2(mepx + 58, mepy + 18), Vector2(mepx + 58, mepy - 18)
		]), Color(1.0, 0.95, 0.6, 0.25))
		# Wheels
		for wli in range(4):
			var wlx = mepx - 18 + (wli % 2) * 36; var wly = mepy - 14 + (wli / 2) * 28
			draw_circle(Vector2(wlx, wly), 5, Color(0.12, 0.10, 0.14))
			draw_circle(Vector2(wlx, wly), 3, Color(0.30, 0.28, 0.32))

# ── Death Feast Bühne ─────────────────────────────────────────────────────────
func _draw_death_feast(vp: Rect2) -> void:
	var w = vp.size.x
	var h = vp.size.y
	var t = _anim_time

	# === BLACK SKY with smoke/haze ===
	draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.01, 0.03))
	# Stars (static)
	var star_rng2 = RandomNumberGenerator.new()
	star_rng2.seed = 77665
	for i in range(50):
		var sx2 = star_rng2.randf_range(0, w)
		var sy2 = star_rng2.randf_range(0, h * 0.38)
		draw_circle(Vector2(sx2, sy2), star_rng2.randf_range(0.6, 1.8), Color(1, 1, 1, star_rng2.randf_range(0.3, 0.8)))
	# Smoke drifting upward
	var smoke_rng = RandomNumberGenerator.new()
	smoke_rng.seed = 13579
	for smi in range(8):
		var sm_base_x = smoke_rng.randf_range(w * 0.1, w * 0.9)
		var sm_phase = fmod(t * 0.18 + smi * 0.125, 1.0)
		var sm_y = h * 0.56 - sm_phase * h * 0.55
		var sm_r = sm_phase * 32.0 + 8.0
		draw_circle(Vector2(sm_base_x + sin(sm_phase * 4.5 + smi) * 18, sm_y),
			sm_r, Color(0.20, 0.15, 0.22, (1.0 - sm_phase) * 0.12))

	# === STAGE BACKDROP (black drape with spiky metal band logo) ===
	draw_rect(Rect2(w * 0.04, h * 0.08, w * 0.92, h * 0.48), Color(0.05, 0.03, 0.07))
	# Torn drape texture
	var drape_rng = RandomNumberGenerator.new()
	drape_rng.seed = 31415
	for dri in range(12):
		var drx = drape_rng.randf_range(w * 0.04, w * 0.96)
		draw_line(Vector2(drx, h * 0.08), Vector2(drx + drape_rng.randf_range(-8, 8), h * 0.56),
			Color(0.08, 0.05, 0.10, 0.35), drape_rng.randf_range(1.0, 2.5))

	# === BAND LOGO (skull) in center backdrop ===
	var skull_cx = w * 0.5; var skull_cy = h * 0.28
	# Skull outer glow (pulsing)
	var skull_pulse = 0.12 + abs(sin(t * 1.2)) * 0.06
	draw_circle(Vector2(skull_cx, skull_cy), 82, Color(0.55, 0.05, 0.05, skull_pulse))
	# Skull base circle
	draw_circle(Vector2(skull_cx, skull_cy), 68, Color(0.12, 0.08, 0.14))
	draw_circle(Vector2(skull_cx, skull_cy), 58, Color(0.08, 0.05, 0.10))
	# Skull eye sockets
	draw_circle(Vector2(skull_cx - 22, skull_cy - 8), 14, Color(0.02, 0.01, 0.03))
	draw_circle(Vector2(skull_cx + 22, skull_cy - 8), 14, Color(0.02, 0.01, 0.03))
	# Eye glow (animated)
	var eye_glow = abs(sin(t * 2.2)) * 0.7 + 0.3
	draw_circle(Vector2(skull_cx - 22, skull_cy - 8), 7, Color(0.90, 0.12, 0.04, eye_glow * 0.8))
	draw_circle(Vector2(skull_cx + 22, skull_cy - 8), 7, Color(0.90, 0.12, 0.04, eye_glow * 0.8))
	# Teeth
	for thi in range(6):
		draw_rect(Rect2(skull_cx - 25 + thi * 9, skull_cy + 30, 7, 14),
			Color(0.80, 0.76, 0.70, 0.7))
	# Radiating spikes (metal aesthetic)
	for si3 in range(12):
		var sa3 = float(si3) / 12.0 * TAU + t * 0.04
		var spike_inner = 70.0; var spike_outer = 90.0 + fmod(si3 * 7.3, 18)
		draw_line(Vector2(skull_cx + cos(sa3) * spike_inner, skull_cy + sin(sa3) * spike_inner),
			Vector2(skull_cx + cos(sa3) * spike_outer, skull_cy + sin(sa3) * spike_outer),
			Color(0.65, 0.08, 0.06, 0.45), 2.5)

	# === SPEAKER STACKS (both sides, detailed) ===
	for side_i in range(2):
		var sp_x = (w * 0.04) if side_i == 0 else (w * 0.80)
		for row2 in range(4):
			var sp_y = h * 0.18 + row2 * 82
			# Cabinet
			draw_rect(Rect2(sp_x, sp_y, 105, 78), Color(0.07, 0.05, 0.05))
			draw_rect(Rect2(sp_x + 2, sp_y + 2, 101, 74), Color(0.05, 0.04, 0.04))
			# Metal corners
			for cni in range(4):
				var cnx = sp_x + (cni % 2) * 100; var cny = sp_y + (cni / 2) * 72
				draw_circle(Vector2(cnx + 4, cny + 4), 5, Color(0.35, 0.32, 0.28))
			# Speaker cone
			draw_circle(Vector2(sp_x + 52, sp_y + 38), 30, Color(0.04, 0.03, 0.04))
			draw_circle(Vector2(sp_x + 52, sp_y + 38), 22, Color(0.06, 0.05, 0.06))
			draw_circle(Vector2(sp_x + 52, sp_y + 38), 10, Color(0.12, 0.10, 0.12))
			# Speaker pulsing with rhythm (wobble effect)
			var spulse = abs(sin(t * 4.5 + row2 * 0.8)) * 2.5
			draw_circle(Vector2(sp_x + 52, sp_y + 38), 22 + spulse,
				Color(0.10, 0.08, 0.10, 0.22))
			# Brand label strip
			draw_rect(Rect2(sp_x + 6, sp_y + 4, 50, 8), Color(0.22, 0.08, 0.06))

	# === STAGE PLATFORM ===
	draw_rect(Rect2(w * 0.04, h * 0.55, w * 0.92, 20), Color(0.32, 0.25, 0.12))
	draw_rect(Rect2(w * 0.04, h * 0.55, w * 0.92, 5), Color(0.48, 0.38, 0.18))
	draw_rect(Rect2(w * 0.04, h * 0.55 + 17, w * 0.92, 3), Color(0.20, 0.15, 0.07))
	# Stage front edge glow
	var edge_glow = 0.12 + sin(t * 2.8) * 0.04
	draw_rect(Rect2(w * 0.04, h * 0.55 + 18, w * 0.92, 4), Color(1.0, 0.55, 0.10, edge_glow))

	# === STAGE FLOOR ===
	draw_rect(Rect2(0, h * 0.57, w, h * 0.43), Color(0.06, 0.04, 0.08))
	# Stage floor boards
	var board_rng = RandomNumberGenerator.new()
	board_rng.seed = 24680
	for bri2 in range(12):
		var br_x = w * 0.04 + bri2 * (w * 0.92 / 11.0)
		draw_line(Vector2(br_x, h * 0.55), Vector2(br_x, h * 0.72),
			Color(0.14, 0.10, 0.06, 0.45), 1.2)

	# === LIGHTING RIG on stage ===
	draw_rect(Rect2(w * 0.04, h * 0.08, w * 0.92, 10), Color(0.18, 0.14, 0.12))
	# Rig support trusses (diagonal lines)
	for tri in range(8):
		var trx = w * 0.04 + tri * (w * 0.92 / 7.0)
		draw_line(Vector2(trx, h * 0.08), Vector2(trx + 10, h * 0.18),
			Color(0.25, 0.20, 0.18, 0.5), 1.5)
		draw_line(Vector2(trx, h * 0.18), Vector2(trx + 10, h * 0.08),
			Color(0.25, 0.20, 0.18, 0.5), 1.5)

	# === ANIMATED LIGHT BEAMS (dramatic, moving) ===
	var light_colors_df = [Color(1.0, 0.10, 0.10), Color(0.10, 0.28, 1.0), Color(0.0, 1.0, 0.28),
		Color(1.0, 0.52, 0.0), Color(0.85, 0.0, 1.0), Color(1.0, 0.90, 0.0)]
	for li2 in range(6):
		var l_x = w * 0.08 + li2 * (w * 0.84 / 5.0)
		var sweep2 = sin(t * (0.65 + li2 * 0.18) + li2 * 1.1) * 0.35
		var end_x2 = l_x + sin(sweep2) * h * 0.45
		var lc2 = light_colors_df[li2]
		var beam_a = 0.09 + abs(sin(t * 0.9 + li2 * 0.55)) * 0.05
		draw_colored_polygon(PackedVector2Array([
			Vector2(l_x - 6, h * 0.10 + 10), Vector2(l_x + 6, h * 0.10 + 10),
			Vector2(end_x2 + 68, h * 0.55), Vector2(end_x2 - 68, h * 0.55)
		]), Color(lc2.r, lc2.g, lc2.b, beam_a))
		# Light fixture (par can)
		draw_rect(Rect2(l_x - 12, h * 0.08, 24, 18), Color(0.22, 0.18, 0.16))
		var lbright = 0.5 + abs(sin(t * 1.5 + li2)) * 0.5
		draw_circle(Vector2(l_x, h * 0.08 + 14), 11, Color(lc2.r * lbright, lc2.g * lbright, lc2.b * lbright, 0.9))
		# Spotlight pool on stage
		draw_ellipse_approx(Vector2(end_x2, h * 0.56),
			Vector2(52.0 + abs(sin(sweep2)) * 30, 11),
			Color(lc2.r, lc2.g, lc2.b, 0.10))

	# === PYRO / FIRE at stage edges ===
	for pi4 in range(7):
		var fx2 = w * 0.08 + pi4 * (w * 0.84 / 6.0)
		var flame_h2 = 28 + sin(t * 9.0 + pi4 * 1.4) * 18
		var flame_c = 0.48 + sin(t * 6.0 + pi4) * 0.30
		# Outer flame (orange)
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx2 - 12, h * 0.55 + 20),
			Vector2(fx2, h * 0.55 + 20 - flame_h2),
			Vector2(fx2 + 12, h * 0.55 + 20)
		]), Color(1.0, flame_c, 0.0, 0.88))
		# Inner flame (yellow-white)
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx2 - 6, h * 0.55 + 20),
			Vector2(fx2, h * 0.55 + 20 - flame_h2 * 0.65),
			Vector2(fx2 + 6, h * 0.55 + 20)
		]), Color(1.0, 0.90, 0.25, 0.78))
		# Ember sparks
		for ei in range(3):
			var spark_phase = fmod(t * 2.2 + pi4 * 0.3 + ei * 0.4, 1.0)
			draw_circle(Vector2(fx2 + sin(spark_phase * 5 + ei) * 10,
				h * 0.55 + 20 - flame_h2 - spark_phase * 20),
				1.5 * (1.0 - spark_phase), Color(1.0, 0.65, 0.10, 1.0 - spark_phase))

	# === BEER / FOOD TABLES (stage-front left and right) ===
	for tbl_side in range(2):
		var tb_x = (w * 0.02) if tbl_side == 0 else (w * 0.80)
		var tb_y = h * 0.60
		draw_rect(Rect2(tb_x, tb_y, 120, 48), Color(0.22, 0.16, 0.08))
		draw_rect(Rect2(tb_x, tb_y, 120, 6), Color(0.32, 0.24, 0.12))
		# Beer steins
		for bsti in range(5):
			var bsx2 = tb_x + 10 + bsti * 22
			draw_rect(Rect2(bsx2, tb_y + 8, 14, 22), Color(0.68, 0.58, 0.20, 0.85))
			draw_rect(Rect2(bsx2 + 2, tb_y + 8, 10, 14), Color(0.85, 0.72, 0.28, 0.7))
			draw_rect(Rect2(bsx2 + 4, tb_y + 8, 6, 5), Color(1.0, 0.96, 0.88, 0.5))  # foam
			draw_rect(Rect2(bsx2 + 14, tb_y + 12, 5, 8), Color(0.55, 0.45, 0.16, 0.8))  # handle
		# Skull decoration on table cloth
		draw_circle(Vector2(tb_x + 60, tb_y + 28), 10, Color(0.28, 0.22, 0.10))
		draw_circle(Vector2(tb_x + 60, tb_y + 28),  6, Color(0.18, 0.14, 0.06))
		draw_circle(Vector2(tb_x + 56, tb_y + 27),  3, Color(0.06, 0.04, 0.06))
		draw_circle(Vector2(tb_x + 64, tb_y + 27),  3, Color(0.06, 0.04, 0.06))

	# === BAND AUF DER BÜHNE =====================================================
	var sy    = h * 0.50    # Bühnenboden-Referenz (Füße der Figuren)
	var skin  = Color(0.88, 0.72, 0.56)

	# ── DRUM KIT (Mitte hinten) ──────────────────────────────────────────────
	var dk_x = w * 0.50; var dk_y = sy - 10.0
	# Kick drum (pulsiert im Takt)
	draw_circle(Vector2(dk_x, dk_y + 14), 18, Color(0.55, 0.06, 0.06))
	draw_circle(Vector2(dk_x, dk_y + 14), 12, Color(0.10, 0.08, 0.10))
	draw_circle(Vector2(dk_x, dk_y + 14),  6, Color(0.65, 0.08, 0.06))
	var kp = abs(sin(t * 4.5)) * 3.0
	draw_arc(Vector2(dk_x, dk_y + 14), 18 + kp, 0, TAU, 14, Color(0.85, 0.10, 0.08, 0.28), 2.5)
	# Snare (links)
	draw_ellipse_approx(Vector2(dk_x - 26, dk_y + 4), Vector2(13, 6), Color(0.55, 0.06, 0.06))
	draw_ellipse_approx(Vector2(dk_x - 26, dk_y + 4), Vector2(9, 4),  Color(0.18, 0.14, 0.10))
	# Hi-Hat (links, zwei Becken leicht geöffnet)
	draw_circle(Vector2(dk_x - 44, dk_y - 3), 9, Color(0.72, 0.68, 0.28, 0.9))
	draw_circle(Vector2(dk_x - 44, dk_y - 7), 9, Color(0.72, 0.68, 0.28, 0.85))
	draw_line(Vector2(dk_x - 44, dk_y - 2), Vector2(dk_x - 42, dk_y + 20), Color(0.45, 0.42, 0.38), 2)
	# Tom 1 + Tom 2 (über Kick)
	draw_ellipse_approx(Vector2(dk_x - 14, dk_y - 3), Vector2(12, 6), Color(0.55, 0.06, 0.06))
	draw_ellipse_approx(Vector2(dk_x + 14, dk_y - 3), Vector2(12, 6), Color(0.55, 0.06, 0.06))
	# Floor Tom (rechts, mit Beinen)
	draw_ellipse_approx(Vector2(dk_x + 34, dk_y + 8), Vector2(14, 7), Color(0.55, 0.06, 0.06))
	draw_ellipse_approx(Vector2(dk_x + 34, dk_y + 8), Vector2(10, 5), Color(0.18, 0.14, 0.10))
	for fti in range(3): draw_line(Vector2(dk_x + 28 + fti * 6, dk_y + 14), Vector2(dk_x + 28 + fti * 6, dk_y + 24), Color(0.45, 0.42, 0.38), 1.5)
	# Crash + Ride Cymbal
	draw_circle(Vector2(dk_x + 46, dk_y - 8), 11, Color(0.72, 0.68, 0.28, 0.88))
	draw_circle(Vector2(dk_x - 6,  dk_y - 14), 9, Color(0.65, 0.60, 0.22, 0.85))
	# Drumhocker
	draw_circle(Vector2(dk_x, dk_y + 28), 8, Color(0.18, 0.14, 0.10))
	draw_line(Vector2(dk_x - 6, dk_y + 36), Vector2(dk_x - 8, dk_y + 44), Color(0.35, 0.30, 0.25), 2.5)
	draw_line(Vector2(dk_x + 6, dk_y + 36), Vector2(dk_x + 8, dk_y + 44), Color(0.35, 0.30, 0.25), 2.5)
	# MANNI (sitzt hinter Kit)
	var ma_bob = sin(t * 4.5) * 2.5
	var sl_s   = sin(t * 8.0) * 10.0; var sr_s = sin(t * 8.0 + PI) * 10.0
	draw_rect(Rect2(dk_x - 9, dk_y + 6  + ma_bob, 18, 12), Color(0.10, 0.10, 0.12))   # Shirt
	draw_rect(Rect2(dk_x - 7, dk_y + 18 + ma_bob,  7,  7), Color(0.18, 0.16, 0.28))   # linkes Bein
	draw_rect(Rect2(dk_x,     dk_y + 18 + ma_bob,  7,  7), Color(0.18, 0.16, 0.28))   # rechtes Bein
	draw_rect(Rect2(dk_x - 17, dk_y + 4 + ma_bob,  7,  9), skin)                       # linker Arm
	draw_rect(Rect2(dk_x + 10, dk_y + 4 + ma_bob,  7,  9), skin)                       # rechter Arm
	draw_line(Vector2(dk_x - 14, dk_y + 8 + ma_bob), Vector2(dk_x - 26, dk_y + 4 + sl_s), Color(0.72, 0.58, 0.30), 2.5)  # Stick L
	draw_line(Vector2(dk_x + 14, dk_y + 8 + ma_bob), Vector2(dk_x,      dk_y - 2 + sr_s), Color(0.72, 0.58, 0.30), 2.5)  # Stick R
	draw_circle(Vector2(dk_x, dk_y - 6 + ma_bob * 0.4), 11, skin)                      # Kopf
	draw_rect(Rect2(dk_x - 8, dk_y - 16 + ma_bob * 0.4, 16, 8), Color(0.15, 0.12, 0.08))  # Haare
	draw_circle(Vector2(dk_x - 3, dk_y - 7  + ma_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(dk_x + 3, dk_y - 7  + ma_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))

	# ── SHOUTER (Sänger, Frontmitte) mit Mikrophon-Ständer ──────────────────
	var sh_x = w * 0.48; var sh_y = sy
	draw_line(Vector2(sh_x, sh_y + 2), Vector2(sh_x, sh_y - 50), Color(0.42, 0.40, 0.38), 2.5)
	draw_line(Vector2(sh_x - 16, sh_y + 2), Vector2(sh_x + 16, sh_y + 2), Color(0.42, 0.40, 0.38), 2.5)
	draw_circle(Vector2(sh_x, sh_y - 50), 6, Color(0.30, 0.28, 0.26))
	draw_circle(Vector2(sh_x, sh_y - 50), 4, Color(0.20, 0.18, 0.18))
	var sh_wc = sin(t * 5.0); var sh_bob = sh_wc * 2.0
	var sh_al = sh_wc * 0.6; var sh_ar = -sh_wc * 0.6
	draw_rect(Rect2(sh_x - 12, sh_y + sh_bob,      10, 4), Color(0.10, 0.08, 0.06))  # Schuhe
	draw_rect(Rect2(sh_x + 2,  sh_y + sh_bob,      10, 4), Color(0.10, 0.08, 0.06))
	draw_rect(Rect2(sh_x - 10, sh_y - 12 + sh_bob,  8, 12), Color(0.14, 0.12, 0.22))
	draw_rect(Rect2(sh_x + 2,  sh_y - 12 + sh_bob,  8, 12), Color(0.14, 0.12, 0.22))
	draw_rect(Rect2(sh_x - 11, sh_y - 30 + sh_bob, 22, 20), Color(0.20, 0.18, 0.22))  # Shirt
	draw_rect(Rect2(sh_x - 20, sh_y - 26 + sh_al + sh_bob, 8, 14), Color(0.35, 0.08, 0.08))  # Lederjacken-Arm
	draw_rect(Rect2(sh_x + 12, sh_y - 26 + sh_ar + sh_bob, 8, 14), skin)              # Arm ans Mikro
	draw_circle(Vector2(sh_x, sh_y - 40 + sh_bob * 0.4), 12, skin)
	draw_arc(Vector2(sh_x, sh_y - 50 + sh_bob * 0.4), 9, PI * 0.05, PI * 0.95, 8, Color(0.18, 0.14, 0.08), 5)  # Haare
	draw_circle(Vector2(sh_x - 4, sh_y - 41 + sh_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(sh_x + 4, sh_y - 41 + sh_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))
	var sing_o = abs(sin(t * 6.5)) * 4.0
	draw_arc(Vector2(sh_x, sh_y - 34 + sh_bob * 0.4), sing_o + 2, 0, PI, 6, Color(0.18, 0.08, 0.06), 2.0)

	# ── BASSIST (links von Mitte) mit Bass-Cabinet ───────────────────────────
	var ba_x = w * 0.33; var ba_y = sy
	draw_rect(Rect2(ba_x - 28, ba_y - 60, 50, 54), Color(0.08, 0.06, 0.08))
	draw_rect(Rect2(ba_x - 26, ba_y - 58, 46, 50), Color(0.05, 0.04, 0.05))
	draw_circle(Vector2(ba_x - 3, ba_y - 34), 16, Color(0.04, 0.03, 0.04))
	draw_circle(Vector2(ba_x - 3, ba_y - 34), 10, Color(0.07, 0.05, 0.07))
	draw_circle(Vector2(ba_x - 3, ba_y - 34), 4,  Color(0.10, 0.08, 0.10))
	draw_circle(Vector2(ba_x - 3, ba_y - 34), 10 + abs(sin(t * 4.5)) * 2.0, Color(0.15, 0.10, 0.15, 0.18))
	var ba_wc = sin(t * 4.0); var ba_bob = ba_wc * 1.5
	var ba_ll = -ba_wc * 8.0; var ba_lr = ba_wc * 8.0
	draw_rect(Rect2(ba_x - 13, ba_y - 2 + ba_ll * 0.3 + ba_bob, 10, 12), Color(0.18, 0.14, 0.08))
	draw_rect(Rect2(ba_x + 3,  ba_y - 2 + ba_lr * 0.3 + ba_bob, 10, 12), Color(0.18, 0.14, 0.08))
	draw_rect(Rect2(ba_x - 11, ba_y - 14 + ba_ll * 0.25 + ba_bob, 8, 14), Color(0.12, 0.10, 0.18))
	draw_rect(Rect2(ba_x + 3,  ba_y - 14 + ba_lr * 0.25 + ba_bob, 8, 14), Color(0.12, 0.10, 0.18))
	draw_rect(Rect2(ba_x - 12, ba_y - 32 + ba_bob, 24, 20), Color(0.22, 0.20, 0.28))
	draw_rect(Rect2(ba_x - 21, ba_y - 28 + ba_bob, 8, 14), skin)
	draw_rect(Rect2(ba_x + 13, ba_y - 30 + ba_bob, 8, 14), skin)
	draw_circle(Vector2(ba_x, ba_y - 42 + ba_bob * 0.4), 12, skin)
	for bdi in range(6):
		var bdx = ba_x - 9 + bdi * 3.5
		draw_line(Vector2(bdx, ba_y - 52 + ba_bob * 0.4), Vector2(bdx + sin(t + bdi) * 2, ba_y - 30 + ba_bob * 0.4), Color(0.25, 0.18, 0.08), 2.5)
	draw_circle(Vector2(ba_x - 4, ba_y - 42 + ba_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(ba_x + 4, ba_y - 42 + ba_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))
	# Bass-Gitarre (Precision Bass, hängt schräg)
	var bg_ang = sin(t * 4.0) * 0.06
	var bg_off = Vector2(sin(bg_ang) * 18, 0)
	draw_colored_polygon(PackedVector2Array([
		bg_off + Vector2(ba_x + 14, ba_y - 28), bg_off + Vector2(ba_x + 30, ba_y - 20),
		bg_off + Vector2(ba_x + 28, ba_y - 4),  bg_off + Vector2(ba_x + 12, ba_y - 1),
		bg_off + Vector2(ba_x + 7,  ba_y - 14),
	]), Color(0.50, 0.28, 0.08))
	draw_line(bg_off + Vector2(ba_x + 20, ba_y - 22), Vector2(ba_x + 12, ba_y - 70 + ba_bob), Color(0.42, 0.22, 0.06), 5)
	for si_b in range(4):
		draw_line(bg_off + Vector2(ba_x + 16 + si_b * 1.5, ba_y - 18), Vector2(ba_x + 12 + si_b * 0.5, ba_y - 66 + ba_bob), Color(0.75, 0.72, 0.40, 0.6), 0.8)

	# ── DREADS (Leadgitarre, rechts von Mitte) mit Combo-Amp ─────────────────
	var dr_x = w * 0.64; var dr_y = sy
	draw_rect(Rect2(dr_x + 12, dr_y - 44, 40, 40), Color(0.08, 0.06, 0.08))
	draw_rect(Rect2(dr_x + 14, dr_y - 42, 36, 36), Color(0.05, 0.04, 0.05))
	draw_circle(Vector2(dr_x + 32, dr_y - 24), 13, Color(0.04, 0.03, 0.04))
	draw_circle(Vector2(dr_x + 32, dr_y - 24),  8, Color(0.07, 0.05, 0.07))
	draw_circle(Vector2(dr_x + 32, dr_y - 24),  8 + abs(sin(t * 6.0)) * 1.5, Color(0.18, 0.12, 0.18, 0.20))
	var dr_wc = sin(t * 5.0); var dr_bob = dr_wc * 1.8
	var dr_ll = -dr_wc * 9.0; var dr_lr = dr_wc * 9.0
	draw_rect(Rect2(dr_x - 13, dr_y - 2 + dr_ll * 0.3 + dr_bob, 10, 12), Color(0.12, 0.10, 0.08))
	draw_rect(Rect2(dr_x + 3,  dr_y - 2 + dr_lr * 0.3 + dr_bob, 10, 12), Color(0.12, 0.10, 0.08))
	draw_rect(Rect2(dr_x - 11, dr_y - 14 + dr_ll * 0.25 + dr_bob, 8, 14), Color(0.20, 0.18, 0.14))
	draw_rect(Rect2(dr_x + 3,  dr_y - 14 + dr_lr * 0.25 + dr_bob, 8, 14), Color(0.20, 0.18, 0.14))
	draw_rect(Rect2(dr_x - 12, dr_y - 32 + dr_bob, 24, 20), Color(0.45, 0.08, 0.06))  # rotes Shirt
	draw_rect(Rect2(dr_x - 21, dr_y - 28 + dr_bob, 8, 14), skin)
	draw_rect(Rect2(dr_x + 13, dr_y - 30 + dr_bob, 8, 14), skin)
	draw_circle(Vector2(dr_x, dr_y - 42 + dr_bob * 0.4), 12, skin)
	for dri in range(8):
		var dhx = dr_x - 10 + dri * 2.8
		var dswing = sin(t * 4.0 + dri * 0.7) * 5.0
		draw_line(Vector2(dhx, dr_y - 52 + dr_bob * 0.4), Vector2(dhx + dswing, dr_y - 28 + dr_bob * 0.4), Color(0.28, 0.18, 0.08), 3)
	draw_circle(Vector2(dr_x - 4, dr_y - 42 + dr_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(dr_x + 4, dr_y - 42 + dr_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))
	# E-Gitarre (Strat, rot)
	var gr_off = Vector2(sin(t * 5.0) * 0.05 * 15, 0)
	draw_colored_polygon(PackedVector2Array([
		gr_off + Vector2(dr_x - 16, dr_y - 22), gr_off + Vector2(dr_x - 5, dr_y - 11),
		gr_off + Vector2(dr_x - 9,  dr_y + 2),  gr_off + Vector2(dr_x - 20, dr_y - 2),
		gr_off + Vector2(dr_x - 24, dr_y - 14),
	]), Color(0.80, 0.08, 0.06))
	draw_line(gr_off + Vector2(dr_x - 11, dr_y - 18), Vector2(dr_x + 20, dr_y - 70 + dr_bob), Color(0.42, 0.22, 0.06), 4)
	for si_g in range(6):
		draw_line(gr_off + Vector2(dr_x - 13 + si_g, dr_y - 18), Vector2(dr_x + 20 + si_g * 0.3, dr_y - 66 + dr_bob), Color(0.78, 0.74, 0.44, 0.55), 0.7)
	# Whammy-Bar-Tremolo
	var whm = sin(t * 8.0 + PI * 0.5) * 2.5
	draw_line(gr_off + Vector2(dr_x - 8, dr_y - 6), gr_off + Vector2(dr_x - 6, dr_y - 6 + whm), Color(0.55, 0.52, 0.38), 1.5)

	# ── DISTORTION (Rhythmusgitarre links) mit Marshall-Stack ────────────────
	var di_x = w * 0.21; var di_y = sy
	for dsi in range(2):
		draw_rect(Rect2(di_x - 4, di_y - 45 - dsi * 40, 48, 38), Color(0.06, 0.05, 0.06))
		draw_rect(Rect2(di_x - 2, di_y - 43 - dsi * 40, 44, 34), Color(0.04, 0.03, 0.04))
		for dci in range(2):
			for dcj in range(2):
				draw_circle(Vector2(di_x + 7 + dci * 22, di_y - 36 + dcj * 18 - dsi * 40), 7, Color(0.04, 0.03, 0.04))
				draw_circle(Vector2(di_x + 7 + dci * 22, di_y - 36 + dcj * 18 - dsi * 40), 4, Color(0.06, 0.05, 0.06))
	draw_rect(Rect2(di_x - 2, di_y - 92, 44, 14), Color(0.10, 0.08, 0.06))
	draw_rect(Rect2(di_x + 2, di_y - 90, 36, 10), Color(0.14, 0.10, 0.06))
	var di_wc = sin(t * 5.0); var di_bob = di_wc * 1.6
	var di_ll = -di_wc * 9.0; var di_lr = di_wc * 9.0
	draw_rect(Rect2(di_x + 28, di_y - 2 + di_ll * 0.3 + di_bob, 10, 12), Color(0.10, 0.08, 0.06))
	draw_rect(Rect2(di_x + 42, di_y - 2 + di_lr * 0.3 + di_bob, 10, 12), Color(0.10, 0.08, 0.06))
	draw_rect(Rect2(di_x + 29, di_y - 14 + di_ll * 0.25 + di_bob, 8, 14), Color(0.14, 0.12, 0.20))
	draw_rect(Rect2(di_x + 41, di_y - 14 + di_lr * 0.25 + di_bob, 8, 14), Color(0.14, 0.12, 0.20))
	draw_rect(Rect2(di_x + 27, di_y - 32 + di_bob, 26, 20), Color(0.08, 0.06, 0.10))
	var di_aura = abs(sin(t * 3.0)) * 0.30
	draw_arc(Vector2(di_x + 40, di_y - 38 + di_bob), 22, 0, TAU, 12, Color(0.40, 0.20, 0.80, di_aura), 3.0)
	draw_rect(Rect2(di_x + 19, di_y - 28 + di_bob, 8, 14), skin)
	draw_rect(Rect2(di_x + 51, di_y - 30 + di_bob, 8, 14), skin)
	draw_circle(Vector2(di_x + 40, di_y - 42 + di_bob * 0.4), 12, skin)
	draw_rect(Rect2(di_x + 30, di_y - 54 + di_bob * 0.4, 20, 10), Color(0.10, 0.08, 0.10))
	draw_circle(Vector2(di_x + 36, di_y - 43 + di_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(di_x + 44, di_y - 43 + di_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))
	# E-Gitarre (schwarze SG)
	var dg_off = Vector2(sin(t * 5.0 + 0.8) * 0.04 * 12, 0)
	draw_colored_polygon(PackedVector2Array([
		dg_off + Vector2(di_x + 52, di_y - 22), dg_off + Vector2(di_x + 64, di_y - 13),
		dg_off + Vector2(di_x + 60, di_y + 2),  dg_off + Vector2(di_x + 46, di_y - 2),
		dg_off + Vector2(di_x + 44, di_y - 14),
	]), Color(0.08, 0.06, 0.08))
	draw_line(dg_off + Vector2(di_x + 53, di_y - 18), Vector2(di_x + 30, di_y - 70 + di_bob), Color(0.38, 0.20, 0.05), 4)
	for si_d in range(6):
		draw_line(dg_off + Vector2(di_x + 52 + si_d, di_y - 18), Vector2(di_x + 30 + si_d * 0.3, di_y - 66 + di_bob), Color(0.78, 0.74, 0.44, 0.55), 0.7)

	# ── RIFF SLICER (Keyboard / Synthesizer, rechts außen) ───────────────────
	var rs_x = w * 0.76; var rs_y = sy
	# Keyboard
	draw_rect(Rect2(rs_x - 30, rs_y - 38, 62, 22), Color(0.10, 0.10, 0.12))
	draw_rect(Rect2(rs_x - 28, rs_y - 36, 58, 18), Color(0.06, 0.06, 0.08))
	for ki in range(14):
		var kx2 = rs_x - 26 + ki * 4
		var kb = (ki % 7) in [1, 2, 4, 5, 6]
		draw_rect(Rect2(kx2, rs_y - 35, 3, 14 if not kb else 9), Color(0.92, 0.90, 0.88) if not kb else Color(0.06, 0.05, 0.06))
	draw_line(Vector2(rs_x - 22, rs_y - 16), Vector2(rs_x - 18, rs_y + 2), Color(0.35, 0.32, 0.28), 2.5)
	draw_line(Vector2(rs_x + 22, rs_y - 16), Vector2(rs_x + 18, rs_y + 2), Color(0.35, 0.32, 0.28), 2.5)
	# Rack / Effektgeräte links neben Keyboard
	draw_rect(Rect2(rs_x - 30, rs_y - 76, 24, 36), Color(0.08, 0.06, 0.08))
	for ri3 in range(4):
		draw_rect(Rect2(rs_x - 28, rs_y - 74 + ri3 * 9, 20, 7), Color(0.04, 0.04, 0.05))
		draw_rect(Rect2(rs_x - 22, rs_y - 72 + ri3 * 9,  6, 4), Color(0.05, 0.35, 0.08, 0.75))
	# RIFF SLICER Figur
	var rs_wc = sin(t * 5.0); var rs_bob = rs_wc * 1.5
	var rs_ll = -rs_wc * 8.0; var rs_lr = rs_wc * 8.0
	draw_rect(Rect2(rs_x - 12, rs_y - 2 + rs_ll * 0.3 + rs_bob, 10, 12), Color(0.20, 0.16, 0.06))
	draw_rect(Rect2(rs_x + 2,  rs_y - 2 + rs_lr * 0.3 + rs_bob, 10, 12), Color(0.20, 0.16, 0.06))
	draw_rect(Rect2(rs_x - 10, rs_y - 14 + rs_ll * 0.25 + rs_bob, 8, 14), Color(0.28, 0.24, 0.10))
	draw_rect(Rect2(rs_x + 2,  rs_y - 14 + rs_lr * 0.25 + rs_bob, 8, 14), Color(0.28, 0.24, 0.10))
	draw_rect(Rect2(rs_x - 12, rs_y - 32 + rs_bob, 24, 20), Color(0.30, 0.24, 0.08))
	draw_line(Vector2(rs_x - 5, rs_y - 32 + rs_bob), Vector2(rs_x - 3, rs_y - 50 + rs_bob), Color(0.22, 0.18, 0.06), 2)
	draw_line(Vector2(rs_x + 5, rs_y - 32 + rs_bob), Vector2(rs_x + 3, rs_y - 50 + rs_bob), Color(0.22, 0.18, 0.06), 2)
	draw_rect(Rect2(rs_x - 21, rs_y - 28 + rs_bob, 8, 14), skin)
	draw_rect(Rect2(rs_x + 13, rs_y - 28 + rs_bob, 8, 14), skin)
	draw_circle(Vector2(rs_x, rs_y - 44 + rs_bob * 0.4), 12, skin)
	draw_rect(Rect2(rs_x - 14, rs_y - 60 + rs_bob * 0.4, 28, 8), Color(0.22, 0.18, 0.12))   # Krempe
	draw_rect(Rect2(rs_x - 10, rs_y - 72 + rs_bob * 0.4, 20, 14), Color(0.18, 0.14, 0.08))  # Hut
	draw_circle(Vector2(rs_x - 4, rs_y - 44 + rs_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(rs_x + 4, rs_y - 44 + rs_bob * 0.4), 1.8, Color(0.1, 0.1, 0.1))
	# Finger-Bewegung auf Keyboard
	var fp1 = abs(sin(t * 6.5)) * 4.0; var fp2 = abs(sin(t * 6.5 + PI)) * 4.0
	draw_circle(Vector2(rs_x - 14, rs_y - 22 + rs_bob - fp1), 3, skin)
	draw_circle(Vector2(rs_x + 18, rs_y - 22 + rs_bob - fp2), 3, skin)

	# ── MONITOR-WEDGES (Bühnenboden vor den Musikern) ────────────────────────
	for mwi in range(4):
		var mwx = w * 0.28 + mwi * (w * 0.44 / 3.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(mwx - 18, sy + 4), Vector2(mwx + 18, sy + 4),
			Vector2(mwx + 12, sy + 14), Vector2(mwx - 12, sy + 14)
		]), Color(0.10, 0.08, 0.08))
		draw_circle(Vector2(mwx, sy + 9), 5, Color(0.04, 0.03, 0.04))

	# ── KABEL-SCHLANGEN (Bühnenboden) ────────────────────────────────────────
	var cab_rng = RandomNumberGenerator.new(); cab_rng.seed = 54321
	for cbi in range(8):
		var cx1 = cab_rng.randf_range(w * 0.18, w * 0.80)
		var cy1 = sy + 2 + cab_rng.randf() * 6
		var cx2 = cx1 + cab_rng.randf_range(-70, 70)
		var cy2 = sy + 4 + cab_rng.randf() * 8
		draw_line(Vector2(cx1, cy1), Vector2(cx2, cy2), Color(0.14, 0.12, 0.10, 0.55), 1.5)

	# === CROWD (moshing silhouettes, dense, animated) ===
	var crowd_rng = RandomNumberGenerator.new()
	crowd_rng.seed = 88776
	for ci3 in range(30):
		var cx3 = 8.0 + ci3 * (w / 29.0)
		var row_off = (ci3 % 4) * 14.0
		var cy3 = h * 0.70 + row_off + crowd_rng.randf_range(-8, 8)
		var head_sz = 9 + crowd_rng.randi_range(0, 5)
		# Body
		draw_rect(Rect2(cx3 - 9, cy3, 18, 28), Color(0.06, 0.04, 0.08))
		# Head
		draw_circle(Vector2(cx3, cy3 - 8), head_sz, Color(0.07, 0.05, 0.09))
		# Hair / details
		if ci3 % 5 == 0:
			# Mohawk
			draw_rect(Rect2(cx3 - 3, cy3 - 24, 6, 14), Color(0.80, 0.08, 0.06))
		elif ci3 % 5 == 2:
			# Long hair
			draw_rect(Rect2(cx3 - 8, cy3 - 18, 16, 20), Color(0.10, 0.08, 0.06))
		# Mosh movement
		var mosh_sway = sin(t * (2.4 + crowd_rng.randf() * 1.5) + ci3 * 0.55) * 5.0
		# Raised arms (all styles)
		var arm_mod = ci3 % 3
		if arm_mod == 0:
			var aa = sin(t * 3.0 + ci3) * 0.5
			draw_line(Vector2(cx3 + mosh_sway, cy3 + 6),
				Vector2(cx3 + mosh_sway - 18 + sin(aa) * 6, cy3 - 22),
				Color(0.08, 0.06, 0.10), 4.0)
		elif arm_mod == 1:
			var aa2 = sin(t * 2.5 + ci3 * 1.3) * 0.5
			draw_line(Vector2(cx3 + mosh_sway, cy3 + 6),
				Vector2(cx3 + mosh_sway + 18 + sin(aa2) * 6, cy3 - 18),
				Color(0.08, 0.06, 0.10), 4.0)
		else:
			# Both arms up (crowd surf handoff)
			draw_line(Vector2(cx3, cy3 + 6), Vector2(cx3 - 16, cy3 - 16), Color(0.08, 0.06, 0.10), 3.5)
			draw_line(Vector2(cx3, cy3 + 6), Vector2(cx3 + 16, cy3 - 14), Color(0.08, 0.06, 0.10), 3.5)
		# Light reflections from stage lights on crowd
		var refl_c = light_colors_df[ci3 % 6]
		draw_circle(Vector2(cx3, cy3 - 8), head_sz + 3, Color(refl_c.r, refl_c.g, refl_c.b, 0.06))

	# === DYNAMISCHES EVENT: Crowd-Surfer fliegt über die Menge (alle 19 s) ──
	var et_cs = fmod(_anim_time, 19.0)
	if et_cs < 5.5:
		var ep_cs = et_cs / 5.5
		var csx = -40.0 + ep_cs * (w + 80.0)
		var csy = h * 0.68 + sin(ep_cs * TAU * 2.0) * 12.0
		# Crowd surfer body
		draw_rect(Rect2(csx - 22, csy - 8, 44, 16), Color(0.25, 0.12, 0.28))
		draw_rect(Rect2(csx - 22, csy - 3, 44, 8), Color(0.60, 0.08, 0.06))  # shirt detail
		draw_circle(Vector2(csx + 24, csy), 10, Color(0.80, 0.62, 0.48))
		# Arms out
		draw_line(Vector2(csx - 10, csy - 4), Vector2(csx - 34, csy - 26), Color(0.80, 0.62, 0.48), 4)
		draw_line(Vector2(csx + 10, csy - 4), Vector2(csx + 36, csy - 24), Color(0.80, 0.62, 0.48), 4)
		# Supporting hands from crowd below
		for hi2 in range(7):
			var hpx2 = csx - 24 + hi2 * 8
			draw_rect(Rect2(hpx2 - 4, csy + 7, 8, 12), Color(0.10, 0.07, 0.12))
			draw_ellipse_approx(Vector2(hpx2, csy + 7), Vector2(5, 4), Color(0.18, 0.14, 0.20))
		# Spotlight following the surfer
		draw_colored_polygon(PackedVector2Array([
			Vector2(csx + 20, h * 0.10), Vector2(csx + 28, h * 0.10),
			Vector2(csx + 50, csy - 14), Vector2(csx + 10, csy - 14)
		]), Color(1.0, 0.90, 0.20, 0.10))

# ── Helper: Ellipse ───────────────────────────────────────────────────────────
func _draw_ellipse(center: Vector2, radii: Vector2, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(16):
		var a = i * TAU / 16.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, col)

func draw_ellipse_approx(center: Vector2, radii: Vector2, col: Color) -> void:
	_draw_ellipse(center, radii, col)

# ── Boss-Erkennung ───────────────────────────────────────────────────────────
func _is_boss_wave(n: int) -> bool:
	return n in [4, 7, 8, 9, 11, 13, 15]

# Zeigt dramatisches Boss-Highlight mit Name
func _show_boss_warning() -> void:
	if not hud:
		return
	AudioManager.play_boss_siren_sfx()
	_screen_flash = 3.0
	_screen_flash_color = Color(1.0, 0.0, 0.0)

	# Dunkler Overlay
	var overlay = ColorRect.new()
	overlay.name = "BossOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.0, 0.0, 0.0, 0.62)
	hud.add_child(overlay)

	# Roter Rahmen oben + unten
	var bar_top = ColorRect.new()
	bar_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar_top.anchor_bottom = 0.0
	bar_top.offset_bottom = 10
	bar_top.color = Color(0.9, 0.05, 0.05)
	hud.add_child(bar_top)
	var bar_bot = ColorRect.new()
	bar_bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar_bot.anchor_top = 1.0
	bar_bot.offset_top = -10
	bar_bot.color = Color(0.9, 0.05, 0.05)
	hud.add_child(bar_bot)

	# !! BOSS !!
	var title = Label.new()
	title.name = "BossTitle"
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.anchor_top = 0.5
	title.anchor_bottom = 0.5
	title.position = Vector2(-300, -148)
	title.size = Vector2(600, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "!! BOSS !!"
	title.add_theme_color_override("font_color", Color(1.0, 0.08, 0.08))
	title.add_theme_font_size_override("font_size", 54)
	hud.add_child(title)

	# Boss-Name (gold) – kleinere Schrift damit lange Namen (Rentnerpaar) nicht abgeschnitten werden
	var name_lbl = Label.new()
	name_lbl.name = "BossNameLabel"
	name_lbl.set_anchors_preset(Control.PRESET_CENTER)
	name_lbl.anchor_left = 0.5
	name_lbl.anchor_right = 0.5
	name_lbl.anchor_top = 0.5
	name_lbl.anchor_bottom = 0.5
	name_lbl.position = Vector2(-380, -80)
	name_lbl.size = Vector2(760, 140)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.text = wave_manager.boss_name
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.0))
	name_lbl.add_theme_font_size_override("font_size", 38)
	hud.add_child(name_lbl)

	# Naht! – nach unten verschoben damit kein Überlapp mit Boss-Name
	var sub = Label.new()
	sub.name = "BossSub"
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.anchor_left = 0.5
	sub.anchor_right = 0.5
	sub.anchor_top = 0.5
	sub.anchor_bottom = 0.5
	sub.position = Vector2(-280, 76)
	sub.size = Vector2(560, 34)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text = LocalizationManager.t("naht")
	sub.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
	sub.add_theme_font_size_override("font_size", 26)
	hud.add_child(sub)

	var t = get_tree().create_timer(3.2, false)
	t.connect("timeout", func():
		if is_instance_valid(overlay):  overlay.queue_free()
		if is_instance_valid(bar_top):  bar_top.queue_free()
		if is_instance_valid(bar_bot):  bar_bot.queue_free()
		if is_instance_valid(title):    title.queue_free()
		if is_instance_valid(name_lbl): name_lbl.queue_free()
		if is_instance_valid(sub):      sub.queue_free()
	)

# ── Map lookup (inline to avoid class_name scoping issues) ───────────────────
const _MapDB = preload("res://scripts/systems/map_database.gd")

func _get_map_for_wave(wave: int) -> String:
	if GameManager.endless_mode:
		return GameManager.endless_map
	return _MapDB.get_map_for_wave(wave)

const _MAP_INFO = {
	"farm":         {"title": "Die Farm",            "subtitle": "Irgendwo in Niedersachsen..."},
	"prison":       {"title": "Das Gefaengnis",       "subtitle": "3 Jahre wegen Laermbelaestigung"},
	"proberaum":    {"title": "Der Proberaum",        "subtitle": "Nachbarn wieder sauer..."},
	"schweinestall":{"title": "Der Schweinestall",    "subtitle": "Riecht nach Musik"},
	"amerika":      {"title": "Amerika",              "subtitle": "Road Trip from Hell"},
	"truck":        {"title": "Fahrender Truck",      "subtitle": "270 km/h auf der A31"},
	"tonstudio":    {"title": "Tonstudio Soundlodge", "subtitle": "Rhauderfehn, Ostfriesland..."},
	"tv_studio":    {"title": "TV Studio",            "subtitle": "Live on Air"},
	"meppen":       {"title": "Meppen",               "subtitle": "City of the Damned"},
	"death_feast":  {"title": "Death Feast",          "subtitle": "Buehne Andernach - letzte Chance!"},
}

# ─────────────────────────────────────────────────────────────────────────────
# Signal handlers
# ─────────────────────────────────────────────────────────────────────────────
func _on_beat() -> void:
	_screen_flash = 0.3
	_screen_flash_color = Color(0.5, 0.3, 0.8)

func _on_rhythm_hit(multiplier: float) -> void:
	for p in _players:
		if is_instance_valid(p):
			p.rhythm_damage_bonus = (multiplier - 1.0) * 0.25
	crowd_meter_sys.add_rhythm_hit(multiplier)
	_screen_flash = 0.5
	_screen_flash_color = Color(1.0, 0.8, 0.2)

	var combo_lbl = hud.get_node_or_null("ComboLabel")
	if combo_lbl:
		combo_lbl.text = "x%.1f COMBO!" % multiplier
		combo_lbl.add_theme_font_size_override("font_size", int(24 + multiplier * 4))

func _on_player_hp_changed(current: int, maximum: int, player_idx: int = 0) -> void:
	if not hud:
		return
	if player_idx == 0:
		var hp_bar = hud.get_node_or_null("HPBar")
		if hp_bar:
			hp_bar.size.x = 200.0 * (float(current) / float(maximum))
	else:
		var hp_bar2 = hud.get_node_or_null("P2HPBar")
		if hp_bar2:
			hp_bar2.size.x = 200.0 * (float(current) / float(maximum))

func _on_player_attacked() -> void:
	var multiplier = rhythm_system.register_attack()
	for p in _players:
		if is_instance_valid(p):
			p.rhythm_damage_bonus = (multiplier - 1.0) * 0.25
	crowd_meter_sys.add_kill()

func _on_player_ultimate() -> void:
	_screen_flash = 1.0
	_screen_flash_color = Color(1.0, 0.5, 0.0)

func _on_crowd_level_changed(_level: int) -> void:
	for p in _players:
		if is_instance_valid(p):
			p.crowd_damage_bonus = crowd_meter_sys.get_damage_bonus()

func _on_wave_completed(wave_number: int) -> void:
	_between_waves = true

	if GameManager.endless_mode:
		SaveManager.update_run_results()
		# Upgrade shop every 5 waves, otherwise auto-continue
		if wave_number % 5 == 0:
			GameManager.go_to_upgrade_shop()
		else:
			_show_wave_banner(wave_number + 1)
			_wave_transition_timer = 3.0
			_in_transition = true
			_between_waves = false
		return

	if wave_number >= 15:
		GameManager.run_stats["won"] = true
		SaveManager.update_run_results()
		GameManager.go_to_game_over()
		return

	SaveManager.update_run_results()
	GameManager.go_to_upgrade_shop()

func _on_player_died(_player_idx: int = 0) -> void:
	if _game_over:
		return
	# Prüfen ob noch ein anderer Spieler lebt
	var any_alive = false
	for p in _players:
		if is_instance_valid(p) and p.is_alive:
			any_alive = true
			break
	if any_alive:
		# Nur kurzer roter Flash – Mitspielerin noch am Leben
		_screen_flash = 2.5
		_screen_flash_color = Color(1.0, 0.1, 0.1)
		return
	# Alle Spieler tot → Game Over
	_game_over = true
	_show_death_effect()
	SaveManager.update_run_results()
	var timer = get_tree().create_timer(2.0, false)
	if GameManager.endless_mode:
		timer.connect("timeout", GameManager.go_to_endless_leaderboard)
	else:
		timer.connect("timeout", GameManager.go_to_game_over)

func _show_death_effect() -> void:
	_screen_flash = 3.0
	_screen_flash_color = Color(1.0, 0.0, 0.0)
