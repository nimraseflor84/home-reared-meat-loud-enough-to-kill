extends EnemyBase

var _zz_offset: float = 0.0
var _zz_dir: float = 1.0

func _ready() -> void:
	enemy_id = "verstimmte"
	max_hp = 15.0
	damage = 8.0
	move_speed = 160.0
	score_value = 80
	add_to_group("enemies")
	_death_anim_duration = 0.62
	super._ready()

func _move_toward_target(_delta: float) -> void:
	if not is_instance_valid(target):
		return
	# Zigzag movement
	_zz_offset += _delta * 3.0
	if abs(_zz_offset) > 1.5:
		_zz_dir *= -1.0
		_zz_offset = _zz_dir * 1.5
	var dir = (target.global_position - global_position).normalized()
	var perp = dir.rotated(PI / 2.0)
	velocity = (dir + perp * sin(_zz_offset) * 1.5).normalized() * move_speed * _slow_factor
	move_and_slide()

func _draw() -> void:
	if _dying: _draw_death(); return
	var flash    = _hit_flash > 0
	# ── South Park Stil ──
	var body_col = Color(0.92, 0.88, 0.12) if not flash else Color.WHITE
	var dark     = Color(0.45, 0.40, 0.05)
	var _wc   = sin(_anim_time * 7.0)
	var bob   = _wc * 1.8
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.7
	var arm_l = _wc * 0.7

	# Schuhe (breit, flach)
	draw_rect(Rect2(-12, 21 + leg_l * 0.3 + bob, 11, 5), dark)
	draw_rect(Rect2(-1,  21 + leg_r * 0.3 + bob, 11, 5), dark)

	# Beine (gelb)
	draw_rect(Rect2(-9, 12 + leg_l * 0.25 + bob, 7, 10), dark)
	draw_rect(Rect2(2,  12 + leg_r * 0.25 + bob, 7, 10), dark)

	# Körper (gelb, verrückt)
	draw_rect(Rect2(-11, -6 + bob, 22, 18), body_col)

	# Arme
	draw_rect(Rect2(-18, -3 + arm_l + bob, 7, 11), body_col)
	draw_rect(Rect2(11,  -3 + arm_r + bob, 7, 11), body_col)

	# Mitten-Hände (SP: runde Klumpen)
	draw_circle(Vector2(-17, 7 + arm_l + bob), 5, body_col)
	draw_circle(Vector2(17,  7 + arm_r + bob), 5, body_col)

	# Kopf (rund, gelb)
	draw_circle(Vector2(0, -20 + bob * 0.4), 13, body_col)

	# SPIKY HAAR (verrückt, zackig – verstimmt)
	for i in range(10):
		var angle  = -PI + float(i) / 10.0 * PI + sin(_anim_time * 8.0 + float(i)) * 0.18
		var spiky  = 11.0 + sin(_anim_time * 5.0 + float(i) * 1.3) * 3.5
		draw_line(
			Vector2(cos(angle), sin(angle)) * 12.0 + Vector2(0, -20 + bob * 0.4),
			Vector2(cos(angle), sin(angle)) * spiky + Vector2(0, -20 + bob * 0.4),
			dark, 3.0)

	# Verrückte Augenbrauen (zackig-exzentrisch für SP-Wahnsinnigen)
	draw_line(Vector2(-10, -26 + bob * 0.4), Vector2(-6, -24 + bob * 0.4), dark, 3.0)
	draw_line(Vector2(-6,  -26 + bob * 0.4), Vector2(-2, -24 + bob * 0.4), dark, 3.0)
	draw_line(Vector2(2,   -24 + bob * 0.4), Vector2(6,  -26 + bob * 0.4), dark, 3.0)
	draw_line(Vector2(6,   -24 + bob * 0.4), Vector2(10, -26 + bob * 0.4), dark, 3.0)

	# Quirlaugen (weiterhin verrückt – Charakter-Merkmal)
	draw_circle(Vector2(-4, -22 + bob * 0.4), 4.5, Color.WHITE)
	draw_circle(Vector2(4,  -22 + bob * 0.4), 4.5, Color.WHITE)
	draw_circle(Vector2(-4, -22 + bob * 0.4), 2.5, dark)
	draw_circle(Vector2(-3, -23 + bob * 0.4), 1.2, Color.WHITE)
	draw_circle(Vector2(4,  -22 + bob * 0.4), 2.5, dark)
	draw_circle(Vector2(5,  -23 + bob * 0.4), 1.2, Color.WHITE)

	# Offener Schreimund
	draw_arc(Vector2(0, -14 + bob * 0.4), 5, 0, PI, 8, dark, 3.0)
	draw_rect(Rect2(-4, -14 + bob * 0.4, 8, 5), dark)

func _draw_death() -> void:
	var t    = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	var body_col = Color(0.92, 0.88, 0.12)
	var dark     = Color(0.45, 0.40, 0.05)
	var blood    = Color(0.72, 0.0,  0.02)

	if t < 0.45:
		# Phase 1: Violentes Vibrieren, Haar explodiert
		var pt = t / 0.45
		var jx = sin(pt * 115.0) * pt * 12.0
		var jy = cos(pt *  88.0) * pt *  8.0
		draw_rect(Rect2(-11+jx, -6+jy, 22, 18), body_col)
		draw_rect(Rect2( -9+jx, 12+jy,  7, 10), dark)
		draw_rect(Rect2(  2+jx, 12+jy,  7, 10), dark)
		draw_circle(Vector2(jx, -20+jy), 13, body_col)
		# Haar – immer größer, irgendwann Meteore
		for i in range(16):
			var a  = -PI + float(i)/16.0*TAU
			var sl = 12.0 + pt*42.0 + sin(pt*28.0+float(i)*1.2)*8.0
			draw_line(Vector2(cos(a)*12+jx, sin(a)*12-20+jy),
			          Vector2(cos(a)*sl+jx, sin(a)*sl-20+jy), dark, 3.0)
		# Verrückte Augen (kreisende Pupillen)
		draw_circle(Vector2(-4+jx, -22+jy), 4.5, Color.WHITE)
		draw_circle(Vector2( 4+jx, -22+jy), 4.5, Color.WHITE)
		var sp = pt * TAU * 7.0
		draw_circle(Vector2(-4+cos(sp)*2+jx,    -22+sin(sp)*2+jy),    2.5, dark)
		draw_circle(Vector2( 4+cos(sp+PI)*2+jx, -22+sin(sp+PI)*2+jy), 2.5, dark)
	else:
		# Phase 2: GELBE EXPLOSION – Körper zerfällt mit Blut
		var pt = (t - 0.45) / 0.55
		# Gelber Blitz
		draw_circle(Vector2.ZERO, 22*(1.0-pt), Color(1.0, 0.95, 0.3, (1.0-pt)*0.85))
		# 13 gelbe Körperchunks radial
		for i in range(13):
			var a  = float(i)*TAU/13.0
			var d  = 5.0 + pt*70.0
			var sz = 6.5 - pt*4.5
			if sz > 0.1:
				draw_circle(Vector2(cos(a),sin(a))*d, sz, body_col)
		# 10 Bluttropfen
		for i in range(10):
			var a  = float(i)*TAU/10.0 + 0.32
			var d  = 3.0 + pt*50.0
			var sz = 4.0 - pt*3.0
			if sz > 0.1:
				draw_circle(Vector2(cos(a),sin(a))*d, sz, blood)
		# Augen fliegen raus
		draw_circle(Vector2(-16-pt*42, -22-pt*24), 4.5*(1.0-pt), Color.WHITE)
		draw_circle(Vector2( 16+pt*32, -22-pt*30), 4.5*(1.0-pt), Color.WHITE)
		# Blutlache
		draw_circle(Vector2(0, 12), pt*24.0, Color(0.52,0.0,0.01,0.78))
