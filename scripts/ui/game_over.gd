extends Control

var _anim_time: float = 0.0
var _won: bool = false
var _is_high_score: bool = false
var _high_score_banner: Label = null
var _quote_label: Label = null
var _quote_target_x: float = 0.0

func _ready() -> void:
	_won = GameManager.run_stats.get("won", false)
	# Run-Ende-Zeit festhalten BEVOR SaveManager den Highscore aktualisiert
	GameManager.mark_run_ended()
	# Highscore-Vergleich: SaveManager.update_run_results() wird vor dem Wechsel
	# zu game_over aufgerufen und ueberschreibt den High-Score in den Save-Daten.
	# Deshalb pruefen wir gegen den Snapshot 'high_score_before_run' (in reset_run_stats gesetzt).
	var pre_high: int = int(GameManager.run_stats.get("high_score_before_run", 0))
	_is_high_score = GameManager.score > 0 and GameManager.score > pre_high
	_build_ui()
	GameManager.add_volume_widget(self)
	if not _won:
		AudioManager.play_evil_laugh()

func _process(delta: float) -> void:
	_anim_time += delta
	# Highscore-Banner pulsieren lassen
	if _is_high_score and is_instance_valid(_high_score_banner):
		var pulse: float = 0.85 + 0.15 * sin(_anim_time * 6.0)
		var alpha: float = 0.7 + 0.3 * abs(sin(_anim_time * 3.0))
		_high_score_banner.modulate = Color(1.0, pulse, 0.25, alpha)
		var s: float = 1.0 + 0.05 * sin(_anim_time * 4.0)
		_high_score_banner.scale = Vector2(s, s)
		_high_score_banner.pivot_offset = _high_score_banner.size * 0.5
	# Spruch faehrt von links rein (deterministisch, Ease-Out), blendet ein und
	# pulsiert danach, damit man ihn auf jeden Fall bemerkt.
	if is_instance_valid(_quote_label):
		var qt: float = _anim_time - 0.35
		if qt < 0.0:
			qt = 0.0
		var p: float = clamp(qt / 0.6, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - p, 3.0)
		_quote_label.position.x = lerp(_quote_target_x - 1400.0, _quote_target_x, eased)
		_quote_label.modulate.a = clamp(qt / 0.4, 0.0, 1.0)
		if p >= 1.0:
			var qs: float = 1.0 + 0.05 * sin(_anim_time * 4.0)
			_quote_label.pivot_offset = _quote_label.size * 0.5
			_quote_label.scale = Vector2(qs, qs)
	queue_redraw()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.02, 0.06)
	add_child(bg)

	# Title
	var title = Label.new()
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.position = Vector2(-400, 60)
	title.size = Vector2(800, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _won:
		title.text = LocalizationManager.t("show_complete")
		title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	else:
		title.text = LocalizationManager.t("crowd_silent")
		title.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
	title.add_theme_font_size_override("font_size", 52)
	add_child(title)

	# Zufaelliger Spott-Spruch beim Tod (einer von 10, lokalisiert).
	# Beim Sieg gibt es nichts zu spotten.
	if not _won:
		var quote = Label.new()
		quote.set_anchors_preset(PRESET_CENTER_TOP)
		quote.anchor_left = 0.5
		quote.anchor_right = 0.5
		var quote_target := Vector2(-450, 172)
		quote.position = quote_target
		quote.size = Vector2(900, 32)
		quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quote.autowrap_mode = TextServer.AUTOWRAP_WORD
		quote.text = LocalizationManager.random_death_quote()
		quote.add_theme_color_override("font_color", Color(0.98, 0.82, 0.45))
		quote.add_theme_color_override("font_outline_color", Color.BLACK)
		quote.add_theme_constant_override("outline_size", 4)
		quote.add_theme_font_size_override("font_size", 22)
		add_child(quote)
		_quote_label = quote
		_quote_target_x = quote_target.x
		# Startet weit links ausserhalb und faehrt in _process deterministisch rein
		quote.position = Vector2(quote_target.x - 1400.0, quote_target.y)
		quote.modulate = Color(1, 1, 1, 0)

	# NEW HIGH SCORE banner - direkt unter dem Titel pulsierend
	if _is_high_score:
		_high_score_banner = Label.new()
		_high_score_banner.set_anchors_preset(PRESET_CENTER_TOP)
		_high_score_banner.anchor_left = 0.5
		_high_score_banner.anchor_right = 0.5
		_high_score_banner.position = Vector2(-400, 130)
		_high_score_banner.size = Vector2(800, 36)
		_high_score_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_high_score_banner.text = LocalizationManager.t("new_high_score")
		_high_score_banner.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25))
		_high_score_banner.add_theme_font_size_override("font_size", 30)
		add_child(_high_score_banner)

	# Freischalt-Hinweis bei Sieg: Bonus (schwerster Grad) hat Vorrang vor der Waffe
	var bonus_unlocked: String = String(GameManager.run_stats.get("bonus_unlocked", ""))
	var unlocked_weapon: String = String(GameManager.run_stats.get("weapon_just_unlocked", ""))
	var de: bool = LocalizationManager.current_language == "de"
	var unlock_msg: String = ""
	if bonus_unlocked != "":
		unlock_msg = "BONUS: Toxic-Held + Giftstadt freigeschaltet!" if de else "BONUS: Toxic hero + Toxic City unlocked!"
	elif unlocked_weapon != "":
		unlock_msg = "Signature-Waffe freigeschaltet!" if de else "Signature weapon unlocked!"
	if unlock_msg != "":
		var wl = Label.new()
		wl.set_anchors_preset(PRESET_CENTER_TOP)
		wl.anchor_left = 0.5
		wl.anchor_right = 0.5
		wl.position = Vector2(-450, 168)
		wl.size = Vector2(900, 30)
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wl.text = unlock_msg
		wl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.3) if bonus_unlocked != "" else Color(1.0, 0.85, 0.2))
		wl.add_theme_color_override("font_outline_color", Color.BLACK)
		wl.add_theme_constant_override("outline_size", 3)
		wl.add_theme_font_size_override("font_size", 22)
		add_child(wl)

	# Stats panel
	var dmg_val = GameManager.run_stats.get("damage_dealt", 0)
	var dmg_str: String = str(int(round(float(dmg_val))))
	var time_str: String = GameManager.format_time_seconds(GameManager.get_run_time_seconds())

	var stats_data = [
		[LocalizationManager.t("stat_final_score"), str(GameManager.score)],
		[LocalizationManager.t("stat_waves"), str(GameManager.run_stats.get("waves_cleared", 0))],
		[LocalizationManager.t("stat_kills"), str(GameManager.run_stats.get("kills", 0))],
		[LocalizationManager.t("stat_damage_dealt"), dmg_str],
		[LocalizationManager.t("stat_rhythm"), str(GameManager.run_stats.get("rhythm_hits", 0))],
		[LocalizationManager.t("stat_time_played"), time_str],
		[LocalizationManager.t("stat_highscore"), str(SaveManager.get_high_score())],
	]

	var y_start: float = 200.0
	var row_h: float = 42.0
	for i in range(stats_data.size()):
		var stat_name = stats_data[i][0]
		var stat_val = stats_data[i][1]

		var row = Control.new()
		row.set_anchors_preset(PRESET_CENTER_TOP)
		row.anchor_left = 0.5
		row.anchor_right = 0.5
		row.position = Vector2(-300, y_start + i * row_h)
		row.size = Vector2(600, row_h - 5)
		add_child(row)

		var name_lbl = Label.new()
		name_lbl.position = Vector2(0, 0)
		name_lbl.size = Vector2(350, row_h - 5)
		name_lbl.text = stat_name + ":"
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
		name_lbl.add_theme_font_size_override("font_size", 22)
		row.add_child(name_lbl)

		var val_lbl = Label.new()
		val_lbl.position = Vector2(360, 0)
		val_lbl.size = Vector2(240, row_h - 5)
		val_lbl.text = stat_val
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		# Highscore-Zeile hervorheben wenn neuer Rekord
		var is_highscore_row: bool = stat_name == LocalizationManager.t("stat_highscore") and _is_high_score
		if is_highscore_row:
			val_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25))
		else:
			val_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		val_lbl.add_theme_font_size_override("font_size", 22)
		row.add_child(val_lbl)

	# Upgrades taken
	var upgrades_taken = GameManager.run_stats.get("upgrades_taken", [])
	if upgrades_taken.size() > 0:
		var upg_title = Label.new()
		upg_title.set_anchors_preset(PRESET_CENTER_TOP)
		upg_title.anchor_left = 0.5
		upg_title.anchor_right = 0.5
		upg_title.position = Vector2(-300, y_start + stats_data.size() * row_h + 12)
		upg_title.size = Vector2(600, 28)
		upg_title.text = LocalizationManager.t("upgrades_lbl")
		upg_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
		upg_title.add_theme_font_size_override("font_size", 18)
		add_child(upg_title)

		var upg_names = []
		for uid in upgrades_taken:
			var upg = UpgradeDB.get_upgrade(uid)
			if not upg.is_empty():
				upg_names.append(upg.get("name", uid))

		var upg_lbl = Label.new()
		upg_lbl.set_anchors_preset(PRESET_CENTER_TOP)
		upg_lbl.anchor_left = 0.5
		upg_lbl.anchor_right = 0.5
		upg_lbl.position = Vector2(-300, y_start + stats_data.size() * row_h + 44)
		upg_lbl.size = Vector2(600, 60)
		upg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		upg_lbl.text = ", ".join(upg_names)
		upg_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		upg_lbl.add_theme_font_size_override("font_size", 14)
		upg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		add_child(upg_lbl)

	# Buttons
	var retry_btn = Button.new()
	retry_btn.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	retry_btn.anchor_left = 1.0
	retry_btn.anchor_right = 1.0
	retry_btn.anchor_top = 1.0
	retry_btn.anchor_bottom = 1.0
	retry_btn.position = Vector2(-280, -80)
	retry_btn.size = Vector2(260, 55)
	retry_btn.text = LocalizationManager.t("play_again")
	retry_btn.add_theme_font_size_override("font_size", 24)
	var retry_style = StyleBoxFlat.new()
	retry_style.bg_color = Color(0.1, 0.5, 0.15)
	retry_style.border_color = Color(0.3, 0.9, 0.4)
	retry_style.set_border_width_all(2)
	retry_style.set_corner_radius_all(8)
	retry_btn.add_theme_stylebox_override("normal", retry_style)
	retry_btn.pressed.connect(GameManager.go_to_character_select)
	add_child(retry_btn)
	retry_btn.call_deferred("grab_focus")

	var menu_btn = Button.new()
	menu_btn.set_anchors_preset(PRESET_BOTTOM_LEFT)
	menu_btn.anchor_top = 1.0
	menu_btn.anchor_bottom = 1.0
	menu_btn.position = Vector2(20, -80)
	menu_btn.size = Vector2(200, 55)
	menu_btn.text = LocalizationManager.t("main_menu")
	menu_btn.add_theme_font_size_override("font_size", 22)
	menu_btn.pressed.connect(GameManager.go_to_main_menu)
	add_child(menu_btn)

func _draw() -> void:
	# Animated particles
	var vp = get_viewport_rect()
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(30):
		rng.state = i * 12345
		var x = fmod(_anim_time * (20 + rng.randf() * 30) + rng.randf() * vp.size.x, vp.size.x)
		var y = fmod(_anim_time * (10 + rng.randf() * 20) + rng.randf() * vp.size.y, vp.size.y)
		var size = 2.0 + rng.randf() * 4.0
		var alpha = 0.3 + rng.randf() * 0.4
		if _won:
			draw_circle(Vector2(x, y), size, Color(1.0, 0.8, 0.1, alpha))
		else:
			draw_circle(Vector2(x, y), size, Color(0.6, 0.1, 0.2, alpha))
