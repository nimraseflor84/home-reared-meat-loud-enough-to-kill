extends EnemyBase

var _charge_timer: float = 0.0
var _charge_cooldown: float = 3.5
var _is_charging: bool = false
var _charge_dir: Vector2 = Vector2.ZERO
var _charge_duration: float = 0.0

func _ready() -> void:
	max_hp = 85.0
	damage = 18.0
	move_speed = 65.0
	score_value = 200
	enemy_id = "wildschwein"
	_death_anim_duration = 0.65
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if not is_alive:
		return
	_charge_timer += delta
	if _is_charging:
		_charge_duration += delta
		if _charge_duration > 1.2:
			_is_charging = false
			_charge_duration = 0.0
	elif _charge_timer >= _charge_cooldown:
		_charge_timer = 0.0
		if is_instance_valid(target):
			_is_charging = true
			_charge_dir = (target.global_position - global_position).normalized()

func _move_toward_target(delta: float) -> void:
	if _is_charging:
		velocity = _charge_dir * 240.0 * _slow_factor
	else:
		if not is_instance_valid(target):
			return
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * move_speed * _slow_factor
	move_and_slide()

func _on_dying_process(_delta: float) -> void:
	var t = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	# Kippt auf Hauer nach vorne
	rotation = t * PI * 0.44

func _draw() -> void:
	if _dying: _draw_death(); return
	var flash    = _hit_flash > 0
	# ── South Park Stil (Wildschwein) ──
	var body_col = Color(0.52, 0.32, 0.18) if not flash else Color.WHITE
	var pink_col = Color(0.92, 0.68, 0.60)
	var tusk_col = Color(0.95, 0.90, 0.78)

	# 4-Bein Laufzyklus: vorne-links & hinten-rechts zusammen, vorne-rechts & hinten-links zusammen
	var _wc    = sin(_anim_time * 7.0)
	var bob    = _wc * 1.8
	# Beinpaare: Index 0=hinten-links, 1=vorne-links, 2=hinten-rechts, 3=vorne-rechts
	# lx-Werte: [-10, -3, 3, 10]
	var leg_0  = _wc * 5.0        # hinten-links
	var leg_1  = -_wc * 5.0       # vorne-links (gegenläufig)
	var leg_2  = -_wc * 5.0       # hinten-rechts (gegenläufig)
	var leg_3  = _wc * 5.0        # vorne-rechts

	# Beine (vier kurze Stubs)
	draw_rect(Rect2(-10.0, 14 + leg_0, 5, 8), body_col.darkened(0.2))
	draw_rect(Rect2(-3.0,  14 + leg_1, 5, 8), body_col.darkened(0.2))
	draw_rect(Rect2(3.0,   14 + leg_2, 5, 8), body_col.darkened(0.2))
	draw_rect(Rect2(10.0,  14 + leg_3, 5, 8), body_col.darkened(0.2))

	# Runder Körper (South Park: breiter, flacher Kreis)
	draw_circle(Vector2(0, 2 + bob), 18, body_col)

	# Rückenborsten (kurze Stacheln)
	for i in range(5):
		var bx = -8.0 + float(i) * 4.0
		draw_line(Vector2(bx, -14 + bob), Vector2(bx + sin(float(i)) * 2, -20 + bob), body_col.darkened(0.3), 3.0)

	# Ohren (Dreiecke oben)
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -12 + bob * 0.4), Vector2(-10, -22 + bob * 0.4), Vector2(-5, -12 + bob * 0.4)]), body_col)
	draw_colored_polygon(PackedVector2Array([Vector2(5, -12 + bob * 0.4), Vector2(10, -22 + bob * 0.4), Vector2(14, -12 + bob * 0.4)]), body_col)

	# Schnauze (runder Rosa-Kreis)
	draw_circle(Vector2(18, 2 + bob * 0.4), 9, pink_col)
	draw_circle(Vector2(15, 1 + bob * 0.4), 3, Color(0.25, 0.10, 0.10))
	draw_circle(Vector2(21, 1 + bob * 0.4), 3, Color(0.25, 0.10, 0.10))

	# Hauer
	draw_line(Vector2(16, 8 + bob * 0.4),  Vector2(26, 13 + bob * 0.4), tusk_col, 3.5)
	draw_line(Vector2(16, -4 + bob * 0.4), Vector2(26, -8 + bob * 0.4), tusk_col, 3.5)

	# Auge (rot, böse)
	draw_circle(Vector2(8, -6 + bob * 0.4), 5, Color(0.85, 0.12, 0.05))
	draw_circle(Vector2(9, -6 + bob * 0.4), 3, Color(0.0,  0.0,  0.0))

	# Charge-Highlight
	if _is_charging:
		draw_circle(Vector2(18, 2 + bob), 12, Color(1.0, 0.4, 0.0, 0.4))

func _draw_death() -> void:
	var t       = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	var body_col = Color(0.52, 0.32, 0.18)
	var pink_col = Color(0.92, 0.68, 0.60)
	var tusk_col = Color(0.95, 0.90, 0.78)
	var blood    = Color(0.72, 0.0,  0.02)

	# Körper (Rotation durch _on_dying_process, bleibt sichtbar)
	draw_circle(Vector2(0, 2), 18, body_col)
	# Ohren
	draw_colored_polygon(PackedVector2Array([Vector2(-14,-12),Vector2(-10,-22),Vector2(-5,-12)]), body_col)
	draw_colored_polygon(PackedVector2Array([Vector2(5,-12), Vector2(10,-22), Vector2(14,-12)]), body_col)
	# Rückenborsten
	for i in range(5):
		var bx = -8.0 + float(i)*4.0
		draw_line(Vector2(bx,-14), Vector2(bx+sin(float(i))*2,-20), body_col.darkened(0.3), 3.0)
	# Beine zucken (flailing)
	for idx in range(4):
		var lx = -10.0 + float(idx)*6.5
		var flail = sin(t*TAU*5.0 + float(idx)*0.8) * t * 10.0
		draw_rect(Rect2(lx, 14+flail, 5, 8), body_col.darkened(0.2))
	# Schnauze (im Boden eingebohrt)
	draw_circle(Vector2(18, 2), 9, pink_col)
	# Hauer – tief eingebohrt
	draw_line(Vector2(16,  8), Vector2(30, 15), tusk_col, 4.0)
	draw_line(Vector2(16, -4), Vector2(30,-10), tusk_col, 4.0)
	# BLUT aus der Schnauze
	for k in range(7):
		var ba  = float(k)*PI/6.0 - PI*0.25
		var bl  = t*(12.0 + float(k)*4.5)
		draw_line(Vector2(18, 2), Vector2(18+cos(ba)*bl, 2+sin(ba)*bl), blood, 3.0)
	# Großer Blutfleck
	draw_circle(Vector2(24, 8), t*22.0, Color(0.52,0.0,0.01,0.68))
