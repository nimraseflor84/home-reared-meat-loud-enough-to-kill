extends Control

var _upgrade_choices: Array = []
var _anim_time: float = 0.0
var _wave_num: int = 0
var _icon_areas: Array = []

func _ready() -> void:
	_wave_num = GameManager.current_wave
	_upgrade_choices = UpgradeDB.get_random_upgrades(3, GameManager.run_stats.get("upgrades_taken", []))
	_build_ui()
	GameManager.add_volume_widget(self)

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()
	for icon in _icon_areas:
		if is_instance_valid(icon):
			icon.queue_redraw()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.03, 0.09)
	add_child(bg)

	# Title
	var title = Label.new()
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.position = Vector2(-400, 25)
	title.size = Vector2(800, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = LocalizationManager.t("backstage_upgrades")
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	title.add_theme_font_size_override("font_size", 48)
	add_child(title)

	var sub = Label.new()
	sub.set_anchors_preset(PRESET_CENTER_TOP)
	sub.anchor_left = 0.5
	sub.anchor_right = 0.5
	sub.position = Vector2(-300, 100)
	sub.size = Vector2(600, 35)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text = LocalizationManager.t("wave_cleared_sub") % [_wave_num]
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	sub.add_theme_font_size_override("font_size", 22)
	add_child(sub)

	# Upgrade cards
	var card_width = 280.0
	var card_height = 340.0
	var total_width = _upgrade_choices.size() * card_width + (_upgrade_choices.size() - 1) * 40.0
	var start_x = (1280.0 - total_width) / 2.0

	var _first_card_btn: Button = null
	for i in range(_upgrade_choices.size()):
		var upgrade = _upgrade_choices[i]
		var x = start_x + i * (card_width + 40.0)
		var y = 155.0
		var card_btn = _create_upgrade_card(upgrade, Vector2(x, y), Vector2(card_width, card_height), i)
		if _first_card_btn == null:
			_first_card_btn = card_btn
	if _first_card_btn:
		_first_card_btn.call_deferred("grab_focus")

	# Skip button
	var skip_btn = Button.new()
	skip_btn.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	skip_btn.anchor_left = 1.0
	skip_btn.anchor_right = 1.0
	skip_btn.anchor_top = 1.0
	skip_btn.anchor_bottom = 1.0
	skip_btn.position = Vector2(-200, -70)
	skip_btn.size = Vector2(180, 50)
	skip_btn.text = LocalizationManager.t("skip")
	skip_btn.pressed.connect(_on_skip)
	add_child(skip_btn)

func _create_upgrade_card(upgrade: Dictionary, pos: Vector2, size: Vector2, index: int) -> Button:
	var rarity = upgrade.get("rarity", "common")
	var rarity_colors = {
		"common": Color(0.5, 0.8, 0.5),
		"rare": Color(0.3, 0.5, 1.0),
		"epic": Color(0.8, 0.3, 1.0),
	}
	var border_color = rarity_colors.get(rarity, Color.WHITE)

	var card = Control.new()
	card.position = pos
	card.size = size
	add_child(card)

	# Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.08, 0.2)
	card.add_child(bg)

	# Rarity banner
	var rarity_banner = ColorRect.new()
	rarity_banner.position = Vector2(0, 0)
	rarity_banner.size = Vector2(size.x, 8)
	rarity_banner.color = border_color
	card.add_child(rarity_banner)

	# Category icon area (drawn)
	var icon_area = Control.new()
	icon_area.name = "Icon"
	icon_area.position = Vector2(size.x/2 - 50, 25)
	icon_area.size = Vector2(100, 100)
	var category = upgrade.get("category", "weapon")
	var cat_color = _category_color(category)
	icon_area.draw.connect(_draw_upgrade_icon.bind(icon_area, category, cat_color))
	card.add_child(icon_area)
	_icon_areas.append(icon_area)

	# Upgrade name
	var name_lbl = Label.new()
	name_lbl.position = Vector2(10, 135)
	name_lbl.size = Vector2(size.x - 20, 45)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text = upgrade.get("name", "???")
	name_lbl.add_theme_color_override("font_color", border_color)
	name_lbl.add_theme_font_size_override("font_size", 22)
	card.add_child(name_lbl)

	# Rarity label
	var rarity_lbl = Label.new()
	rarity_lbl.position = Vector2(10, 180)
	rarity_lbl.size = Vector2(size.x - 20, 25)
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_lbl.text = rarity.to_upper()
	rarity_lbl.add_theme_color_override("font_color", border_color.lightened(0.2))
	rarity_lbl.add_theme_font_size_override("font_size", 14)
	card.add_child(rarity_lbl)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.position = Vector2(15, 215)
	desc_lbl.size = Vector2(size.x - 30, 80)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.text = upgrade.get("desc", "")
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(desc_lbl)

	# Select button
	var btn = Button.new()
	btn.position = Vector2(20, size.y - 60)
	btn.size = Vector2(size.x - 40, 50)
	btn.text = "TAKE IT!"
	btn.add_theme_font_size_override("font_size", 20)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = border_color.darkened(0.4)
	btn_style.border_color = border_color
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = border_color.darkened(0.1)
	btn_hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", btn_hover)
	var upgrade_id = upgrade.get("id", "")
	btn.pressed.connect(func(): _select_upgrade(upgrade_id))
	card.add_child(btn)
	return btn

func _draw_upgrade_icon(canvas: Control, category: String, color: Color) -> void:
	var c = canvas.size / 2.0
	var t = _anim_time
	match category:
		"weapon":
			# Sword shape
			canvas.draw_line(c + Vector2(0, -40), c + Vector2(0, 30), color, 4.0)
			canvas.draw_line(c + Vector2(-15, -10), c + Vector2(15, -10), color, 3.0)
			canvas.draw_circle(c + Vector2(0, 35), 5, color)
		"stats":
			# Heart shape
			canvas.draw_arc(c + Vector2(-12, -10), 14, -PI, 0, 8, Color(0.9, 0.2, 0.2), 3.0)
			canvas.draw_arc(c + Vector2(12, -10), 14, -PI, 0, 8, Color(0.9, 0.2, 0.2), 3.0)
			var heart = PackedVector2Array([c + Vector2(-26, -10), c + Vector2(0, 30), c + Vector2(26, -10)])
			canvas.draw_colored_polygon(heart, Color(0.9, 0.2, 0.2))
		"ability":
			# Lightning bolt
			canvas.draw_line(c + Vector2(10, -40), c + Vector2(-8, 5), Color(1.0, 0.9, 0.1), 4.0)
			canvas.draw_line(c + Vector2(-8, 5), c + Vector2(8, 5), Color(1.0, 0.9, 0.1), 4.0)
			canvas.draw_line(c + Vector2(8, 5), c + Vector2(-10, 40), Color(1.0, 0.9, 0.1), 4.0)
		"rhythm":
			# Music note
			canvas.draw_circle(c + Vector2(-5, 20), 10, color)
			canvas.draw_line(c + Vector2(5, 20), c + Vector2(5, -30), color, 3.0)
			canvas.draw_line(c + Vector2(5, -30), c + Vector2(25, -20), color, 3.0)
			canvas.draw_line(c + Vector2(25, -20), c + Vector2(25, -10), color, 3.0)
			canvas.draw_circle(c + Vector2(25, -10), 7, color)
		_:
			# Star
			for j in range(5):
				var angle = j * TAU / 5.0 - PI / 2.0
				canvas.draw_line(c, c + Vector2(cos(angle), sin(angle)) * 35, color, 3.0)

func _category_color(category: String) -> Color:
	match category:
		"weapon": return Color(1.0, 0.5, 0.2)
		"stats": return Color(0.9, 0.2, 0.3)
		"ability": return Color(1.0, 0.9, 0.1)
		"rhythm": return Color(0.4, 0.8, 1.0)
		"special": return Color(0.8, 0.3, 1.0)
		_: return Color.WHITE

func _select_upgrade(upgrade_id: String) -> void:
	GameManager.run_stats["upgrades_taken"].append(upgrade_id)
	# Apply to player via UpgradeManager (accessed in game scene)
	# Store for when game scene resumes
	GameManager.run_stats["pending_upgrade"] = upgrade_id
	_go_to_next_wave()

func _on_skip() -> void:
	_go_to_next_wave()

func _go_to_next_wave() -> void:
	var next_wave = GameManager.current_wave + 1
	# Check for story scene
	var story_scene = GameManager.get_story_scene_for_wave(_wave_num)
	if not story_scene.is_empty():
		GameManager.change_scene(story_scene)
	else:
		GameManager.go_to_game()
