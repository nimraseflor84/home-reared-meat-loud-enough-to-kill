extends Control

var _anim_time: float = 0.0
var _won: bool = false

func _ready() -> void:
	_won = GameManager.run_stats.get("won", false)
	_build_ui()
	GameManager.add_volume_widget(self)
	if not _won:
		AudioManager.play_evil_laugh()

func _process(delta: float) -> void:
	_anim_time += delta
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

	# Stats panel
	var stats_data = [
		[LocalizationManager.t("stat_final_score"), str(GameManager.score)],
		[LocalizationManager.t("stat_waves"), str(GameManager.run_stats.get("waves_cleared", 0))],
		[LocalizationManager.t("stat_kills"), str(GameManager.run_stats.get("kills", 0))],
		[LocalizationManager.t("stat_rhythm"), str(GameManager.run_stats.get("rhythm_hits", 0))],
		[LocalizationManager.t("stat_highscore"), str(SaveManager.get_high_score())],
	]

	var y_start = 180.0
	for i in range(stats_data.size()):
		var stat_name = stats_data[i][0]
		var stat_val = stats_data[i][1]

		var row = Control.new()
		row.set_anchors_preset(PRESET_CENTER_TOP)
		row.anchor_left = 0.5
		row.anchor_right = 0.5
		row.position = Vector2(-300, y_start + i * 50)
		row.size = Vector2(600, 45)
		add_child(row)

		var name_lbl = Label.new()
		name_lbl.position = Vector2(0, 0)
		name_lbl.size = Vector2(350, 45)
		name_lbl.text = stat_name + ":"
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
		name_lbl.add_theme_font_size_override("font_size", 24)
		row.add_child(name_lbl)

		var val_lbl = Label.new()
		val_lbl.position = Vector2(360, 0)
		val_lbl.size = Vector2(240, 45)
		val_lbl.text = stat_val
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		val_lbl.add_theme_font_size_override("font_size", 24)
		row.add_child(val_lbl)

	# Upgrades taken
	var upgrades_taken = GameManager.run_stats.get("upgrades_taken", [])
	if upgrades_taken.size() > 0:
		var upg_title = Label.new()
		upg_title.set_anchors_preset(PRESET_CENTER_TOP)
		upg_title.anchor_left = 0.5
		upg_title.anchor_right = 0.5
		upg_title.position = Vector2(-300, y_start + stats_data.size() * 50 + 20)
		upg_title.size = Vector2(600, 30)
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
		upg_lbl.position = Vector2(-300, y_start + stats_data.size() * 50 + 55)
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
