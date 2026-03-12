extends EnemyBase

var _zigzag_timer: float = 0.0
var _zigzag_dir: float = 1.0

func _ready() -> void:
	max_hp = 15.0
	damage = 5.0
	move_speed = 190.0
	score_value = 80
	enemy_id = "huhn"
	_death_anim_duration = 0.55
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	_zigzag_timer += delta
	if _zigzag_timer > 0.35:
		_zigzag_timer = 0.0
		_zigzag_dir *= -1.0

func _move_toward_target(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var dir = (target.global_position - global_position).normalized()
	var perp = Vector2(-dir.y, dir.x) * _zigzag_dir * 0.6
	velocity = (dir + perp).normalized() * move_speed * _slow_factor
	move_and_slide()

func _draw() -> void:
	if _dying: _draw_death(); return
	var flash    = _hit_flash > 0
	# ── South Park Stil (Huhn) ──
	var body_col = Color(0.95, 0.55, 0.12) if not flash else Color.WHITE
	var wing_col = Color(0.88, 0.82, 0.72)
	var beak_col = Color(1.0, 0.80, 0.05)
	var red_col  = Color(0.95, 0.08, 0.08)
	var _wc   = sin(_anim_time * 8.0)
	var bob   = _wc * 1.5
	var lk    = _wc * 5.0
	var wf    = abs(_wc) * 6.0 - 1.0

	# Beine (dünne gelbe Stiele mit Zehen – alternierend)
	draw_line(Vector2(-4, 14 + bob), Vector2(-6 - lk, 24), beak_col, 3.0)
	draw_line(Vector2(4,  14 + bob), Vector2(6 + lk,  24), beak_col, 3.0)
	draw_line(Vector2(-6 - lk, 24), Vector2(-11 - lk, 24), beak_col, 2.0)
	draw_line(Vector2(6 + lk,  24), Vector2(11 + lk,  24), beak_col, 2.0)

	# Runder Körper (South Park: flacher Kreis)
	draw_circle(Vector2(0, 4 + bob), 14, body_col)

	# Flügel-Stubs (flattern)
	draw_rect(Rect2(-19, -1 + bob - wf, 8, 10), wing_col)
	draw_rect(Rect2(11,  -1 + bob - wf, 8, 10), wing_col)

	# Kleiner Kopf
	draw_circle(Vector2(0, -14 + bob * 0.4), 10, body_col)

	# Kamm (3 rote Zacken)
	draw_circle(Vector2(-2, -23 + bob * 0.4), 4,   red_col)
	draw_circle(Vector2(3,  -25 + bob * 0.4), 3.5, red_col)
	draw_circle(Vector2(8,  -22 + bob * 0.4), 3,   red_col)

	# Schnabel (Dreieck)
	var beak = PackedVector2Array([Vector2(9, -15 + bob * 0.4), Vector2(17, -14 + bob * 0.4), Vector2(9, -12 + bob * 0.4)])
	draw_colored_polygon(beak, beak_col)

	# Auge
	draw_circle(Vector2(4, -16 + bob * 0.4), 3,   Color.WHITE)
	draw_circle(Vector2(5, -16 + bob * 0.4), 1.8, Color(0.05, 0.05, 0.05))

func _draw_death() -> void:
	var t       = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	var body_col = Color(0.95, 0.55, 0.12)
	var beak_col = Color(1.0,  0.80, 0.05)
	var red_col  = Color(0.95, 0.08, 0.08)
	var blood    = Color(0.72, 0.0,  0.02)

	if t < 0.38:
		# Phase 1: Federn fliegen ab, Körper schrumpft
		var pt = t / 0.38
		var sc = 1.0 - pt * 0.45
		draw_circle(Vector2(0,  4*sc), 14*sc, body_col)
		draw_circle(Vector2(0, -14*sc), 10*sc, body_col)
		# Beine zucken (panikartiges Flattern)
		var kick = sin(pt * TAU * 4.0) * 9.0
		draw_line(Vector2(-4, 14), Vector2(-6+kick,  24), beak_col, 3.0)
		draw_line(Vector2( 4, 14), Vector2( 6-kick,  24), beak_col, 3.0)
		draw_line(Vector2(-6+kick, 24), Vector2(-12+kick, 24), beak_col, 2.0)
		draw_line(Vector2( 6-kick, 24), Vector2( 12-kick, 24), beak_col, 2.0)
		# 16 Federn fliegen radial (orange Blobs)
		for i in range(16):
			var a  = float(i)*TAU/16.0 + float(i)*0.18
			var d  = 5.0 + pt*48.0
			var sz = 4.5 - pt*1.5
			if sz > 0.1:
				draw_circle(Vector2(cos(a),sin(a))*d, sz,
					Color(0.95, 0.55+float(i%3)*0.10, 0.12))
		# Kamm fliegt ab
		draw_circle(Vector2(-2 - pt*18, -23 - pt*22), 4*(1.0-pt), red_col)
	else:
		# Phase 2: KÖRPER EXPLODIERT – Fleisch und Blut
		var pt = (t - 0.38) / 0.62
		# Orangefarbener Flash
		draw_circle(Vector2(0, 4), 14*(1.0-pt), Color(1.0, 0.65, 0.25, (1.0-pt)*0.75))
		# 11 Körperchunks radial
		for i in range(11):
			var a  = float(i)*TAU/11.0
			var d  = 5.0 + pt*58.0
			var sz = 6.0 - pt*4.5
			if sz > 0.1:
				draw_circle(Vector2(cos(a),sin(a))*d, sz, body_col)
		# 9 Bluttropfen
		for i in range(9):
			var a  = float(i)*TAU/9.0 + 0.35
			var d  = 3.0 + pt*42.0
			var sz = 3.8 - pt*2.8
			if sz > 0.1:
				draw_circle(Vector2(cos(a),sin(a))*d, sz, blood)
		# Beine laufen noch weiter (losgelöst)
		draw_line(Vector2(-4-pt*14, 14+pt*10), Vector2(-6-pt*18, 24+pt*6), beak_col, 3.0)
		draw_line(Vector2( 4+pt*12, 14+pt*8),  Vector2( 6+pt*16, 24+pt*9), beak_col, 3.0)
		# Blutlache
		draw_circle(Vector2(0, 12), pt*20.0, Color(0.52,0.0,0.01,0.78))
