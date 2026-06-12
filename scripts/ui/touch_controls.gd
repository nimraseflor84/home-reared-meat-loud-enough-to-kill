extends Control
## Virtual Touch Controls – wird nur auf Android/iOS geladen.
## Linker Bereich: Joystick (Bewegung), rechter Bereich: Ultimate-Button.
## Injiziert die InputMap-Aktionen move_up/down/left/right und ultimate.

const _JOYSTICK_RADIUS := 90.0
const _DEAD_ZONE       := 14.0
const _ULT_RADIUS      := 55.0
const _DASH_RADIUS     := 42.0

var _joy_touch: int    = -1
var _joy_center: Vector2
var _joy_cur: Vector2

var _ult_touch: int  = -1
var _dash_touch: int = -1

func _ready() -> void:
	if not (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		queue_free()
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var s := get_viewport_rect().size
	var joy_base  := Vector2(s.x * 0.18, s.y * 0.74)
	var ult_pos   := Vector2(s.x * 0.87, s.y * 0.74)
	var dash_pos  := Vector2(s.x * 0.73, s.y * 0.82)

	# Joystick – äußerer Ring
	draw_arc(joy_base, _JOYSTICK_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.18), 3.0)

	# Joystick – Knopf
	if _joy_touch >= 0:
		var thumb := _joy_center + (_joy_cur - _joy_center).limit_length(_JOYSTICK_RADIUS)
		draw_circle(thumb, 38.0, Color(1.0, 1.0, 1.0, 0.35))
	else:
		draw_circle(joy_base, 38.0, Color(1.0, 1.0, 1.0, 0.22))

	# Richtungspfeile (Orientierungshilfe)
	var arrow_col := Color(1, 1, 1, 0.10)
	var ar := 18.0
	draw_line(joy_base + Vector2(-_JOYSTICK_RADIUS + 6, 0), joy_base + Vector2(-_JOYSTICK_RADIUS + 6 + ar, 0), arrow_col, 2.0)
	draw_line(joy_base + Vector2( _JOYSTICK_RADIUS - 6, 0), joy_base + Vector2( _JOYSTICK_RADIUS - 6 - ar, 0), arrow_col, 2.0)
	draw_line(joy_base + Vector2(0, -_JOYSTICK_RADIUS + 6), joy_base + Vector2(0, -_JOYSTICK_RADIUS + 6 + ar), arrow_col, 2.0)
	draw_line(joy_base + Vector2(0,  _JOYSTICK_RADIUS - 6), joy_base + Vector2(0,  _JOYSTICK_RADIUS - 6 - ar), arrow_col, 2.0)

	# Ultimate-Button
	var ult_active := _ult_touch >= 0
	draw_circle(ult_pos, _ULT_RADIUS, Color(0.6, 0.1, 0.75, 0.45 if ult_active else 0.28))
	draw_arc(ult_pos, _ULT_RADIUS, 0.0, TAU, 48,
		Color(0.85, 0.3, 1.0, 0.7 if ult_active else 0.4), 2.5)
	draw_string(ThemeDB.fallback_font, ult_pos + Vector2(-16, 7), "ULT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.9 if ult_active else 0.65))

	# Dash-Button
	var dash_active := _dash_touch >= 0
	draw_circle(dash_pos, _DASH_RADIUS, Color(0.1, 0.45, 0.85, 0.45 if dash_active else 0.28))
	draw_arc(dash_pos, _DASH_RADIUS, 0.0, TAU, 48,
		Color(0.3, 0.75, 1.0, 0.7 if dash_active else 0.4), 2.5)
	draw_string(ThemeDB.fallback_font, dash_pos + Vector2(-22, 7), "DASH",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.9 if dash_active else 0.65))

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
		# Ultimate: rechte Bildschirmhälfte, nah am Button
		if ev.position.x > s.x * 0.60 and ev.position.distance_to(ult_pos) < _ULT_RADIUS + 20.0:
			_ult_touch = ev.index
			Input.action_press("ultimate")
			queue_redraw()
			return
		# Dash-Button
		if ev.position.x > s.x * 0.60 and ev.position.distance_to(dash_pos) < _DASH_RADIUS + 20.0:
			_dash_touch = ev.index
			Input.action_press("dash")
			queue_redraw()
			return
		# Joystick: linke Bildschirmhälfte, untere 55 %
		if ev.position.x < s.x * 0.50 and ev.position.y > s.y * 0.45:
			_joy_touch  = ev.index
			_joy_center = ev.position
			_joy_cur    = ev.position
			queue_redraw()
	else:
		if ev.index == _joy_touch:
			_joy_touch = -1
			_clear_movement()
			queue_redraw()
		elif ev.index == _ult_touch:
			_ult_touch = -1
			Input.action_release("ultimate")
			queue_redraw()
		elif ev.index == _dash_touch:
			_dash_touch = -1
			Input.action_release("dash")
			queue_redraw()

func _on_drag(ev: InputEventScreenDrag) -> void:
	if ev.index != _joy_touch:
		return
	_joy_cur = ev.position
	_apply_movement()
	queue_redraw()

func _apply_movement() -> void:
	var delta := _joy_cur - _joy_center
	if delta.length() < _DEAD_ZONE:
		_clear_movement()
		return
	var norm     := delta.normalized()
	var strength := minf(delta.length() / _JOYSTICK_RADIUS, 1.0)

	if norm.x < -0.25: Input.action_press("move_left",  strength)
	else:              Input.action_release("move_left")
	if norm.x >  0.25: Input.action_press("move_right", strength)
	else:              Input.action_release("move_right")
	if norm.y < -0.25: Input.action_press("move_up",    strength)
	else:              Input.action_release("move_up")
	if norm.y >  0.25: Input.action_press("move_down",  strength)
	else:              Input.action_release("move_down")

func _clear_movement() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
