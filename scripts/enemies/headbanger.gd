extends EnemyBase

var _charging: bool = false
var _charge_timer: float = 0.0
const CHARGE_COOLDOWN = 3.0
const CHARGE_SPEED = 350.0
const CHARGE_DURATION = 0.5

func _ready() -> void:
	enemy_id = "headbanger"
	max_hp = 200.0
	damage = 25.0
	move_speed = 40.0
	score_value = 300
	add_to_group("enemies")
	_death_anim_duration = 0.72
	super._ready()

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	if not is_instance_valid(target):
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			target = players[0]
	_charge_timer += delta
	if _charging:
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * CHARGE_SPEED * _slow_factor
		move_and_slide()
		if _charge_timer >= CHARGE_DURATION:
			_charging = false
			_charge_timer = 0.0
		_check_contact_damage(delta)
	else:
		if _charge_timer >= CHARGE_COOLDOWN and is_instance_valid(target):
			var dist = global_position.distance_to(target.global_position)
			if dist < 400:
				_charging = true
				_charge_timer = 0.0
		else:
			var dir = (target.global_position - global_position).normalized()
			velocity = dir * move_speed * _slow_factor
			move_and_slide()
		_check_contact_damage(delta)

func _draw() -> void:
	if _dying: _draw_death(); return
	var flash    = _hit_flash > 0
	# ── South Park Stil ──
	var body_col = Color(0.15, 0.12, 0.10) if not flash else Color.WHITE  # schwarzes Metal-Shirt
	var skin     = Color(0.88, 0.72, 0.56) if not flash else Color.WHITE
	var hair_col = Color(0.14, 0.10, 0.06)
	var jean_col = Color(0.14, 0.12, 0.20)
	var spd      = 12.0 if _charging else 3.5
	var _wc   = sin(_anim_time * spd)
	var bob   = _wc * (2.5 if _charging else 1.5)
	var leg_r = _wc * (12.0 if _charging else 8.0)
	var leg_l = -leg_r
	var arm_r = -_wc * 0.7
	var arm_l = _wc * 0.7

	# Schuhe (breit, flach)
	draw_rect(Rect2(-12, 23 + leg_l * 0.35 + bob, 11, 5), Color(0.10, 0.08, 0.06))
	draw_rect(Rect2(-1,  23 + leg_r * 0.35 + bob, 11, 5), Color(0.10, 0.08, 0.06))

	# Beine (dunkle Jeans)
	draw_rect(Rect2(-9, 12 + leg_l * 0.28 + bob, 7, 12), jean_col)
	draw_rect(Rect2(2,  12 + leg_r * 0.28 + bob, 7, 12), jean_col)

	# Schwarzes Metal-Shirt
	draw_rect(Rect2(-11, -6 + bob, 22, 18), body_col)
	# Band-Logo Andeutung
	draw_line(Vector2(-7, -1 + bob), Vector2(7, -1 + bob), Color(0.65, 0.65, 0.65, 0.8), 1.5)
	draw_line(Vector2(-5,  3 + bob), Vector2(5,  3 + bob), Color(0.65, 0.65, 0.65, 0.5), 1.0)

	# Arme
	draw_rect(Rect2(-18, -3 + arm_l + bob, 7, 11), skin)
	draw_rect(Rect2(11,  -3 + arm_r + bob, 7, 11), skin)

	# Mitten-Hände (SP: runde Klumpen)
	draw_circle(Vector2(-17, 7 + arm_l + bob), 5, skin)
	draw_circle(Vector2(17,  7 + arm_r + bob), 5, skin)

	# Kopf
	draw_circle(Vector2(0, -20 + bob * 0.4), 12, skin)

	# LANGE HAAR-STRÄHNEN (schwingen beim Charge – ikonisch)
	var hair_count = 8
	for i in range(hair_count):
		var hx    = -10.0 + float(i) / (hair_count - 1) * 20.0
		var swing = (sin(_anim_time * 12.0 + float(i) * 0.5) * 9.0 if _charging else sin(_anim_time * 2.0 + float(i) * 0.6) * 3.0)
		var hlen  = 24.0 + (i % 3) * 6.0
		draw_line(Vector2(hx, -30 + bob * 0.4), Vector2(hx + swing, -30 + bob * 0.4 + hlen), hair_col, 3.5)

	# Böse Augenbrauen
	draw_line(Vector2(-8, -24 + bob * 0.4), Vector2(-2, -22 + bob * 0.4), hair_col, 2.5)
	draw_line(Vector2(2,  -22 + bob * 0.4), Vector2(8,  -24 + bob * 0.4), hair_col, 2.5)

	# Augen (nach innen geneigte Ovale – South Park)
	var tilt = 0.25; var ew = 4.0; var eh = 2.8
	var lepts = PackedVector2Array(); var repts = PackedVector2Array()
	for i in range(10):
		var a = i * TAU / 10.0; var ox = cos(a) * ew; var oy = sin(a) * eh
		lepts.append(Vector2(-4 + ox*cos(tilt) - oy*sin(tilt), -20 + bob * 0.4 + ox*sin(tilt) + oy*cos(tilt)))
		repts.append(Vector2(4 + ox*cos(-tilt) - oy*sin(-tilt), -20 + bob * 0.4 + ox*sin(-tilt) + oy*cos(-tilt)))
	draw_colored_polygon(lepts, Color.WHITE if not flash else Color.WHITE)
	draw_colored_polygon(repts, Color.WHITE if not flash else Color.WHITE)
	draw_circle(Vector2(-4, -20 + bob * 0.4), 1.8, Color(0.0, 0.0, 0.0))
	draw_circle(Vector2(4,  -20 + bob * 0.4), 1.8, Color(0.0, 0.0, 0.0))

	# Ladeindikator
	if _charge_timer / CHARGE_COOLDOWN > 0.7 and not _charging:
		draw_circle(Vector2.ZERO, 5, Color(1.0, 0.3, 0.0, (_charge_timer / CHARGE_COOLDOWN - 0.7) / 0.3))

func _draw_death() -> void:
	var t       = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	var skin    = Color(0.88, 0.72, 0.56)
	var hair    = Color(0.14, 0.10, 0.06)
	var shirt   = Color(0.15, 0.12, 0.10)
	var jean    = Color(0.14, 0.12, 0.20)
	var blood   = Color(0.72, 0.0,  0.02)

	if t < 0.42:
		# Phase 1: Kopf saust nach UNTEN – fataler Headbang
		var pt    = t / 0.42
		var head_y = -20.0 + pt*pt * 58.0   # beschleunigt nach unten
		# Körper (leicht vorgebeugt)
		draw_rect(Rect2(-11, -6+pt*4, 22, 18), shirt)
		draw_rect(Rect2( -9, 12,       7, 12), jean)
		draw_rect(Rect2(  2, 12,       7, 12), jean)
		# Kopf donnert nach unten
		draw_circle(Vector2(pt*4, head_y), 12, skin)
		# Haar peitscht brutal vorwärts
		for i in range(8):
			var hx    = -10.0 + float(i)/7.0*20.0
			var sweep = pt*pt * (28.0 + float(i)*4.0)
			draw_line(Vector2(hx, -30+pt*4), Vector2(hx+sweep*0.5, head_y+20+sweep), hair, 4.5)
		# Blut erscheint am Hals
		if pt > 0.65:
			var bpt = (pt-0.65)/0.35
			for k in range(3):
				draw_circle(Vector2(-2+float(k)*2, -8+pt*6), 2.5*bpt, blood)
	else:
		# Phase 2: Kopf am Boden, Hals blutet stark
		var pt     = (t - 0.42) / 0.58
		var hg     = 36.0   # head on ground y
		# Körper zusammengesackt
		draw_rect(Rect2(-11+pt*6, 2,  22, 16), shirt)
		draw_rect(Rect2( -9,      12,  7, 12), jean)
		draw_rect(Rect2(  2,      12,  7, 12), jean)
		# Kopf liegt am Boden
		draw_circle(Vector2(6+pt*4, hg), 12, skin)
		# Haar auf dem Boden
		for i in range(8):
			var hx = float(i)*3.5 - 14.0
			draw_line(Vector2(hx, hg-4), Vector2(hx+sin(float(i))*6, hg+20+float(i)*2), hair, 4.0)
		# BLUT FONTÄNE aus dem Halsstumpf
		for k in range(7):
			var ba  = PI*0.15 + float(k)*PI*0.12 - PI*0.4
			var bl  = pt * (14.0 + float(k)*5.0)
			draw_line(Vector2(0, -5), Vector2(cos(ba)*bl, -5+sin(ba)*bl), blood, 3.5)
		# Blutlachen (am Kopf + am Hals)
		draw_circle(Vector2(6, hg+4), pt*28.0, Color(0.52,0.0,0.01,0.82))
		draw_circle(Vector2(0,  -2),  pt*16.0, Color(0.52,0.0,0.01,0.78))
