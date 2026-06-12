extends Control

# Pause-Bildschirm: schwarze Überblende + Buttons
# ElevatorScene läuft als Geschwister-Node direkt in der CanvasLayer (game_scene.gd)

signal resume_requested()
signal main_menu_requested()
signal options_requested()
signal restart_requested()

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

	# Buttons werden in einer vertikalen Reihe unten zentriert dargestellt.
	# Reihenfolge von unten nach oben: Hauptmenue, Run neustarten, Optionen, Weiter spielen
	var btn_w: float = 320.0
	var btn_h: float = 44.0
	var spacing: float = 10.0
	var bottom_margin: float = 36.0

	# Y-Positionen berechnen (von unten nach oben)
	var y_main: float    = h - bottom_margin - btn_h
	var y_restart: float = y_main - btn_h - spacing
	var y_options: float = y_restart - btn_h - spacing
	var y_cont: float    = y_options - btn_h - spacing

	# 2. Weiter spielen (primaerer gruener Knopf, ganz oben)
	var cont = _make_button(LocalizationManager.t("continue_btn"), Vector2(btn_w, btn_h),
		Vector2(cx - btn_w * 0.5, y_cont),
		Color(0.06, 0.28, 0.08, 0.92), Color(0.25, 0.85, 0.35),
		Color(0.88, 1.0, 0.88), 18)
	cont.name = "ContBtn"
	cont.pressed.connect(func(): resume_requested.emit())
	add_child(cont)
	cont.call_deferred("grab_focus")

	# 3. Optionen (neutral grau-blau)
	var opt = _make_button(LocalizationManager.t("options_btn"), Vector2(btn_w, btn_h),
		Vector2(cx - btn_w * 0.5, y_options),
		Color(0.08, 0.12, 0.22, 0.92), Color(0.30, 0.55, 0.85),
		Color(0.85, 0.92, 1.0), 16)
	opt.name = "OptBtn"
	opt.pressed.connect(func(): options_requested.emit())
	add_child(opt)

	# 4. Run neustarten (orange/warnung)
	var restart_btn = _make_button(LocalizationManager.t("restart_run"), Vector2(btn_w, btn_h),
		Vector2(cx - btn_w * 0.5, y_restart),
		Color(0.32, 0.18, 0.03, 0.92), Color(0.95, 0.55, 0.10),
		Color(1.0, 0.88, 0.70), 16)
	restart_btn.name = "RestartBtn"
	restart_btn.pressed.connect(func(): restart_requested.emit())
	add_child(restart_btn)

	# 5. Hauptmenue (rot, abschliessend)
	var menu = _make_button(LocalizationManager.t("main_menu"), Vector2(btn_w, btn_h),
		Vector2(cx - btn_w * 0.5, y_main),
		Color(0.28, 0.03, 0.03, 0.85), Color(0.75, 0.15, 0.15),
		Color(1.0, 0.75, 0.75), 15)
	menu.name = "MenuBtn"
	menu.pressed.connect(func(): main_menu_requested.emit())
	add_child(menu)

func _make_button(text: String, size_v: Vector2, pos: Vector2, bg: Color, border: Color, font_col: Color, font_size: int) -> Button:
	var b = Button.new()
	b.text = text
	b.size = size_v
	b.position = pos
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", font_col)
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	var sbh = sb.duplicate()
	sbh.bg_color = Color(bg.r + 0.08, bg.g + 0.08, bg.b + 0.08, bg.a)
	b.add_theme_stylebox_override("hover", sbh)
	var sbp = sb.duplicate()
	sbp.bg_color = Color(bg.r + 0.14, bg.g + 0.14, bg.b + 0.14, bg.a)
	b.add_theme_stylebox_override("pressed", sbp)
	return b

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
