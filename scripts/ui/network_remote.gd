extends Control
## Netzwerk Co-op: Client-Seite.
## Phone 2 sendet Touch-Input an Host und sieht P2-HP + Wave-Info.

const _JOY_RADIUS  := 90.0
const _DEAD_ZONE   := 14.0
const _ULT_RADIUS  := 55.0
const _DASH_RADIUS := 42.0

var _joy_touch: int    = -1
var _joy_center: Vector2
var _joy_cur: Vector2
var _ult_touch: int    = -1
var _dash_touch: int   = -1

var _send_timer: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.add_volume_widget(self)

func _process(delta: float) -> void:
	_send_timer += delta
	if _send_timer >= 0.033:  # ~30fps
		_send_timer = 0.0
		_send_input()
	queue_redraw()

func _send_input() -> void:
	var dir = Vector2.ZERO
	if _joy_touch >= 0:
		var delta_v = _joy_cur - _joy_center
		if delta_v.length() > _DEAD_ZONE:
			dir = delta_v.normalized()
	var buttons: int = 0
	if _dash_touch >= 0: buttons |= 1
	if _ult_touch  >= 0: buttons |= 2
	GameManager.rpc_id(1, "_rpc_recv_p2_input", dir.x, dir.y, buttons)

func _draw() -> void:
	var s := get_viewport_rect().size

	# Hintergrund
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.04, 0.02, 0.10))

	# Wave + HP Info (oben Mitte)
	var info_text = "Wave %d  |  P2 HP: %d / %d" % [
		GameManager.net_current_wave,
		GameManager.net_p2_hp,
		max(GameManager.net_p2_max_hp, 1)
	]
	draw_string(ThemeDB.fallback_font, Vector2(s.x * 0.5 - 180, 40),
		info_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.8, 0.9, 1.0, 0.9))

	# HP-Balken
	var hp_pct = float(GameManager.net_p2_hp) / float(max(GameManager.net_p2_max_hp, 1))
	hp_pct = clampf(hp_pct, 0.0, 1.0)
	draw_rect(Rect2(s.x * 0.2, 54, s.x * 0.6, 14), Color(0.1, 0.0, 0.2))
	draw_rect(Rect2(s.x * 0.2, 54, s.x * 0.6 * hp_pct, 14),
		Color(0.2 + 0.8 * (1.0 - hp_pct), 0.6 * hp_pct, 0.9 * hp_pct))

	var joy_base  := Vector2(s.x * 0.18, s.y * 0.74)
	var ult_pos   := Vector2(s.x * 0.87, s.y * 0.74)
	var dash_pos  := Vector2(s.x * 0.73, s.y * 0.82)

	# Joystick – äußerer Ring
	draw_arc(joy_base, _JOY_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.18), 3.0)

	# Joystick – Knopf
	if _joy_touch >= 0:
		var thumb := _joy_center + (_joy_cur - _joy_center).limit_length(_JOY_RADIUS)
		draw_circle(thumb, 38.0, Color(1.0, 1.0, 1.0, 0.35))
	else:
		draw_circle(joy_base, 38.0, Color(1.0, 1.0, 1.0, 0.22))

	# Richtungspfeile
	var ac := Color(1, 1, 1, 0.10)
	var ar := 18.0
	draw_line(joy_base + Vector2(-_JOY_RADIUS + 6, 0), joy_base + Vector2(-_JOY_RADIUS + 6 + ar, 0), ac, 2.0)
	draw_line(joy_base + Vector2( _JOY_RADIUS - 6, 0), joy_base + Vector2( _JOY_RADIUS - 6 - ar, 0), ac, 2.0)
	draw_line(joy_base + Vector2(0, -_JOY_RADIUS + 6), joy_base + Vector2(0, -_JOY_RADIUS + 6 + ar), ac, 2.0)
	draw_line(joy_base + Vector2(0,  _JOY_RADIUS - 6), joy_base + Vector2(0,  _JOY_RADIUS - 6 - ar), ac, 2.0)

	# ULT-Button
	var ua := _ult_touch >= 0
	draw_circle(ult_pos, _ULT_RADIUS, Color(0.6, 0.1, 0.75, 0.45 if ua else 0.28))
	draw_arc(ult_pos, _ULT_RADIUS, 0.0, TAU, 48, Color(0.85, 0.3, 1.0, 0.7 if ua else 0.4), 2.5)
	draw_string(ThemeDB.fallback_font, ult_pos + Vector2(-16, 7), "ULT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.9 if ua else 0.65))

	# DASH-Button
	var da := _dash_touch >= 0
	draw_circle(dash_pos, _DASH_RADIUS, Color(0.1, 0.45, 0.85, 0.45 if da else 0.28))
	draw_arc(dash_pos, _DASH_RADIUS, 0.0, TAU, 48, Color(0.3, 0.75, 1.0, 0.7 if da else 0.4), 2.5)
	draw_string(ThemeDB.fallback_font, dash_pos + Vector2(-22, 7), "DASH",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.9 if da else 0.65))

	# "P2 SPIELER" Label
	draw_string(ThemeDB.fallback_font, Vector2(s.x * 0.5 - 60, s.y * 0.5),
		"P2 CONTROLLER", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.4, 0.5, 0.6, 0.4))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)

func _on_touch(ev: InputEventScreenTouch) -> void:
	var s := get_viewport_rect().size
	var ult_pos  := Vector2(s.x * 0.87, s.y * 0.74)
	var dash_pos := Vector2(s.x * 0.73, s.y * 0.82)
	if ev.pressed:
		if ev.position.x > s.x * 0.60 and ev.position.distance_to(ult_pos) < _ULT_RADIUS + 20.0:
			_ult_touch = ev.index
			return
		if ev.position.x > s.x * 0.60 and ev.position.distance_to(dash_pos) < _DASH_RADIUS + 20.0:
			_dash_touch = ev.index
			return
		if ev.position.x < s.x * 0.50 and ev.position.y > s.y * 0.45:
			_joy_touch  = ev.index
			_joy_center = ev.position
			_joy_cur    = ev.position
	else:
		if ev.index == _joy_touch:
			_joy_touch = -1
		elif ev.index == _ult_touch:
			_ult_touch = -1
		elif ev.index == _dash_touch:
			_dash_touch = -1

func _on_drag(ev: InputEventScreenDrag) -> void:
	if ev.index == _joy_touch:
		_joy_cur = ev.position
