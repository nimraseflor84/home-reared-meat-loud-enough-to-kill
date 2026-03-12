extends Control

var _anim_time: float = 0.0
var _bg_tex: Texture2D = null

func _ready() -> void:
	_bg_tex = load("res://HRM Cover SP.png")
	if not _bg_tex:
		_bg_tex = load("res://HRM Loud enough to kil.jpeg")
	queue_redraw()
	_build_ui()
	_add_volume_widget()
	AudioManager.start_music()

func _add_volume_widget() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	var widget_script = load("res://scripts/ui/volume_widget.gd")
	var widget = Control.new()
	widget.set_anchors_preset(Control.PRESET_FULL_RECT)
	widget.script = widget_script
	canvas.add_child(widget)

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

# Bild direkt zeichnen – size statt get_viewport_rect() für korrekte Größe
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.02, 0.08))
	if _bg_tex:
		var ts  = Vector2(_bg_tex.get_width(), _bg_tex.get_height())
		var sc  = min(size.x / ts.x, size.y / ts.y)
		var sz  = ts * sc
		var off = (size - sz) * 0.5
		draw_texture_rect(_bg_tex, Rect2(off, sz), false)

func _build_ui() -> void:
	# Dunkler Streifen nur am unteren Rand (Button-Leiste)
	var overlay = ColorRect.new()
	overlay.anchor_left   = 0.0
	overlay.anchor_right  = 1.0
	overlay.anchor_top    = 1.0
	overlay.anchor_bottom = 1.0
	overlay.offset_top    = -94.0
	overlay.color = Color(0.0, 0.0, 0.0, 0.88)
	add_child(overlay)

	# Highscore (oben links)
	var hs_label = Label.new()
	hs_label.set_anchors_preset(PRESET_TOP_LEFT)
	hs_label.position = Vector2(20, 16)
	hs_label.size     = Vector2(400, 28)
	var hs = SaveManager.get_high_score()
	hs_label.text = "Highscore: " + str(hs) if hs > 0 else ""
	hs_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	hs_label.add_theme_font_size_override("font_size", 20)
	add_child(hs_label)

	# 5 Buttons nebeneinander am unteren Rand
	var button_configs = [
		{"text": LocalizationManager.t("play"),        "color": Color(0.1, 0.7, 0.2),    "cb": _on_play_pressed},
		{"text": LocalizationManager.t("endless_mode"),"color": Color(0.75, 0.30, 0.05), "cb": _on_endless_pressed},
		{"text": LocalizationManager.t("leaderboard"), "color": Color(0.2, 0.3, 0.75),   "cb": _on_leaderboard_pressed},
		{"text": LocalizationManager.t("options"),     "color": Color(0.1, 0.35, 0.4),   "cb": _on_options_pressed},
		{"text": LocalizationManager.t("quit"),        "color": Color(0.65, 0.1, 0.1),   "cb": _on_quit_pressed},
	]
	var btn_w   = 216.0
	var btn_h   = 60.0
	var gap     = 10.0
	var total_w = button_configs.size() * btn_w + (button_configs.size() - 1) * gap
	var start_x = 80.0
	var _first_btn: Button = null
	for i in range(button_configs.size()):
		var cfg = button_configs[i]
		var btn = Button.new()
		btn.text = cfg["text"]
		btn.anchor_left   = 0.0
		btn.anchor_right  = 0.0
		btn.anchor_top    = 1.0
		btn.anchor_bottom = 1.0
		btn.position = Vector2(start_x + i * (btn_w + gap), -(btn_h + 17.0))
		btn.size     = Vector2(btn_w, btn_h)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(cfg["cb"])
		var sty = StyleBoxFlat.new()
		sty.bg_color     = cfg["color"].darkened(0.35)
		sty.border_color = cfg["color"]
		sty.set_border_width_all(2)
		sty.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", sty)
		var sty_h = StyleBoxFlat.new()
		sty_h.bg_color = cfg["color"].lightened(0.15)
		sty_h.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("hover", sty_h)
		add_child(btn)
		if _first_btn == null:
			_first_btn = btn
	if _first_btn:
		_first_btn.call_deferred("grab_focus")

func _on_play_pressed() -> void:
	GameManager.go_to_character_select()

func _on_endless_pressed() -> void:
	GameManager.go_to_map_select()

func _on_leaderboard_pressed() -> void:
	GameManager.go_to_endless_leaderboard()

func _on_options_pressed() -> void:
	GameManager.go_to_options()

func _on_quit_pressed() -> void:
	get_tree().quit()
