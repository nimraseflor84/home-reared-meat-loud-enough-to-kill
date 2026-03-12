extends Control

# Pause-Bildschirm: schwarze Überblende + Buttons
# ElevatorScene läuft als Geschwister-Node direkt in der CanvasLayer (game_scene.gd)

signal resume_requested()
signal main_menu_requested()

var _time: float = 0.0
var _phase: int = 0  # 0=warten  1=Überblende  2=Szene läuft

const FADE_DUR: float = 0.65

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func restart() -> void:
	_time = 0.0
	_phase = 0
	visible = true
	var bg = get_node_or_null("BlackBG")
	if bg:
		bg.color.a = 1.0

func _build_ui() -> void:
	var vp  = get_viewport().get_visible_rect()
	var w   = vp.size.x
	var h   = vp.size.y
	var cx  = w * 0.5

	# 1. Schwarzer Hintergrund
	var black_bg = ColorRect.new()
	black_bg.name     = "BlackBG"
	black_bg.position = Vector2.ZERO
	black_bg.size     = Vector2(w, h)
	black_bg.color    = Color(0, 0, 0, 1.0)
	black_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black_bg.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(black_bg)

	# 2. Weiter spielen – mittig unten
	var cont      = Button.new()
	cont.name     = "ContBtn"
	cont.text     = LocalizationManager.t("continue_btn")
	cont.size     = Vector2(300, 44)
	cont.position = Vector2(cx - 150, h - 104)
	cont.add_theme_font_size_override("font_size", 18)
	cont.add_theme_color_override("font_color", Color(0.88, 1.0, 0.88))
	cont.process_mode = Node.PROCESS_MODE_ALWAYS
	var s1 = StyleBoxFlat.new()
	s1.bg_color     = Color(0.06, 0.28, 0.08, 0.92)
	s1.border_color = Color(0.25, 0.85, 0.35)
	s1.set_border_width_all(2)
	s1.set_corner_radius_all(8)
	cont.add_theme_stylebox_override("normal", s1)
	var s1h = s1.duplicate()
	s1h.bg_color = Color(0.12, 0.45, 0.16, 0.95)
	cont.add_theme_stylebox_override("hover", s1h)
	var s1p = s1.duplicate()
	s1p.bg_color = Color(0.18, 0.60, 0.22)
	cont.add_theme_stylebox_override("pressed", s1p)
	cont.pressed.connect(func(): resume_requested.emit())
	add_child(cont)
	cont.call_deferred("grab_focus")

	# 3. Hauptmenü – mittig unten, direkt darunter
	var menu      = Button.new()
	menu.name     = "MenuBtn"
	menu.text     = LocalizationManager.t("main_menu")
	menu.size     = Vector2(220, 36)
	menu.position = Vector2(cx - 110, h - 52)
	menu.add_theme_font_size_override("font_size", 15)
	menu.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75))
	menu.process_mode = Node.PROCESS_MODE_ALWAYS
	var s2 = StyleBoxFlat.new()
	s2.bg_color     = Color(0.28, 0.03, 0.03, 0.85)
	s2.border_color = Color(0.75, 0.15, 0.15)
	s2.set_border_width_all(1)
	s2.set_corner_radius_all(6)
	menu.add_theme_stylebox_override("normal", s2)
	var s2h = s2.duplicate()
	s2h.bg_color = Color(0.45, 0.08, 0.08, 0.95)
	menu.add_theme_stylebox_override("hover", s2h)
	menu.pressed.connect(func(): main_menu_requested.emit())
	add_child(menu)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		resume_requested.emit()

func _process(delta: float) -> void:
	_time += delta
	match _phase:
		0:
			if _time >= FADE_DUR:
				_phase = 1
				_time = 0.0
		1:
			if _time >= FADE_DUR:
				_phase = 2
				_time = 0.0
		2:
			# Schwarzen ColorRect ausblenden → ElevatorScene (Geschwister) wird sichtbar
			var bg = get_node_or_null("BlackBG")
			if bg:
				bg.color.a = max(0.0, 1.0 - _time / FADE_DUR)
