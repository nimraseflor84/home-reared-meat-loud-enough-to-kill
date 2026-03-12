extends EnemyBase

var _preferred_dist: float = 200.0
var _strafe_timer: float = 0.0
var _strafe_dir: float = 1.0
const SHOOT_INTERVAL = 2.5
var _bullet_script: GDScript = null

func _ready() -> void:
	max_hp = 50.0
	damage = 12.0
	move_speed = 95.0
	score_value = 180
	enemy_id = "cowboy"
	_death_anim_duration = 0.65
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if not is_alive or not is_instance_valid(target):
		return
	_strafe_timer += delta
	if _strafe_timer > 1.2:
		_strafe_timer = 0.0
		_strafe_dir *= -1.0
	_shoot_timer += delta
	if _shoot_timer >= SHOOT_INTERVAL:
		_shoot_timer = 0.0
		_shoot_at_player()

func _move_toward_target(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var dist = global_position.distance_to(target.global_position)
	var dir = (target.global_position - global_position).normalized()
	var perp = Vector2(-dir.y, dir.x) * _strafe_dir
	if dist > _preferred_dist + 40:
		velocity = dir * move_speed * _slow_factor
	elif dist < _preferred_dist - 40:
		velocity = -dir * move_speed * 0.7 * _slow_factor
	else:
		velocity = perp * move_speed * 0.8 * _slow_factor
	move_and_slide()

func _shoot_at_player() -> void:
	if not is_instance_valid(target):
		return
	# Compile bullet script once, reuse for every shot
	if _bullet_script == null:
		var script_src = "extends Area2D\nvar vel = Vector2.ZERO\nvar dmg = 0.0\nvar life = 2.5\nfunc _ready():\n\tvel = get_meta('velocity')\n\tdmg = get_meta('damage')\n\tlife = get_meta('lifetime')\n\tbody_entered.connect(_on_body)\nfunc _process(d):\n\tlife -= d\n\tif life <= 0: queue_free()\n\tposition += vel * d\n\tqueue_redraw()\nfunc _draw():\n\tdraw_circle(Vector2.ZERO, 6, Color(0.9, 0.7, 0.1))\nfunc _on_body(b):\n\tif b.has_method('take_damage'): b.take_damage(dmg)\n\tqueue_free()\n"
		var scr = GDScript.new()
		scr.source_code = script_src
		scr.reload()
		_bullet_script = scr
	# Spawn a simple bullet projectile
	var bullet = Area2D.new()
	bullet.add_to_group("enemy_projectiles")
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	bullet.add_child(col)
	var vel = (target.global_position - global_position).normalized() * 280.0
	bullet.set_meta("velocity", vel)
	bullet.set_meta("damage", damage * 0.7)
	bullet.set_meta("lifetime", 2.5)
	bullet.position = global_position
	bullet.script = _bullet_script
	get_tree().current_scene.add_child(bullet)

func _draw() -> void:
	if _dying: _draw_death(); return
	var flash     = _hit_flash > 0
	# ── South Park Stil (Cowboy) ──
	var shirt_col = Color(0.68, 0.32, 0.12) if not flash else Color.WHITE
	var jean_col  = Color(0.20, 0.30, 0.60)
	var skin_col  = Color(0.98, 0.80, 0.60) if not flash else Color.WHITE
	var hat_col   = Color(0.58, 0.42, 0.20)
	var _wc   = sin(_anim_time * 5.5)
	var bob   = _wc * 1.5
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.7
	var arm_l = _wc * 0.7

	# Beine (Jeans)
	draw_rect(Rect2(-10, 14 + leg_l * 0.3 + bob, 8, 14), jean_col)
	draw_rect(Rect2(2,   14 + leg_r * 0.3 + bob, 8, 14), jean_col)

	# Cowboy-Stiefel (breit, flach – South Park)
	draw_rect(Rect2(-13, 27 + leg_l * 0.35 + bob, 13, 6), Color(0.28, 0.18, 0.08))
	draw_rect(Rect2(-1,  27 + leg_r * 0.35 + bob, 13, 6), Color(0.28, 0.18, 0.08))

	# Shirt Torso
	draw_rect(Rect2(-12, -8 + bob, 24, 22), shirt_col)

	# Gürtelschnalle (gold)
	draw_rect(Rect2(-5, 10 + bob, 10, 6), Color(0.82, 0.68, 0.10))

	# Arme (Stubs)
	draw_rect(Rect2(-20, -3 + arm_l + bob, 8, 13), shirt_col)
	draw_rect(Rect2(12,  -3 + arm_r + bob, 8, 13), shirt_col)

	# Mitten-Hände (SP: runde Klumpen, Haut-Farbe)
	draw_circle(Vector2(-19, 9 + arm_l + bob), 6, skin_col)
	draw_circle(Vector2(19,  9 + arm_r + bob), 6, skin_col)

	# Kopf
	draw_circle(Vector2(0, -22 + bob * 0.4), 15, skin_col)

	# Cowboyhut (ikonisch, groß – South Park)
	draw_rect(Rect2(-18, -36 + bob * 0.4, 36, 10), hat_col)       # Krempe (breit)
	draw_rect(Rect2(-10, -50 + bob * 0.4, 20, 16), hat_col)        # Krone
	draw_line(Vector2(-10, -36 + bob * 0.4), Vector2(10, -36 + bob * 0.4), Color(0.35, 0.20, 0.05), 2)  # Hutband
	draw_line(Vector2(-18, -29 + bob * 0.4), Vector2(-22, -24 + bob * 0.4), hat_col, 3)
	draw_line(Vector2(18,  -29 + bob * 0.4), Vector2(22,  -24 + bob * 0.4), hat_col, 3)

	# Augenbrauen (SP: dicke diagonale Linien, fast zusammenlaufend)
	draw_line(Vector2(-12, -28 + bob * 0.4), Vector2(-3, -26 + bob * 0.4), Color(0.30, 0.15, 0.04), 3.0)
	draw_line(Vector2(3,   -26 + bob * 0.4), Vector2(12, -28 + bob * 0.4), Color(0.30, 0.15, 0.04), 3.0)

	# Schnauzbart (typisch Cowboy)
	draw_arc(Vector2(-3, -14 + bob * 0.4), 4, 0.1, PI - 0.1, 6, Color(0.30, 0.15, 0.04), 2.5)
	draw_arc(Vector2(3,  -14 + bob * 0.4), 4, 0.1, PI - 0.1, 6, Color(0.30, 0.15, 0.04), 2.5)

	# Augen (nach innen geneigte Ovale – authentisch South Park)
	var tilt = 0.25; var ew = 5.5; var eh = 3.5
	var lepts = PackedVector2Array(); var repts = PackedVector2Array()
	for i in range(10):
		var a = i * TAU / 10.0; var ox = cos(a) * ew; var oy = sin(a) * eh
		lepts.append(Vector2(-6 + ox*cos(tilt) - oy*sin(tilt), -24 + bob * 0.4 + ox*sin(tilt) + oy*cos(tilt)))
		repts.append(Vector2(6 + ox*cos(-tilt) - oy*sin(-tilt), -24 + bob * 0.4 + ox*sin(-tilt) + oy*cos(-tilt)))
	draw_colored_polygon(lepts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_colored_polygon(repts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_circle(Vector2(-6, -24 + bob * 0.4), 2.0, Color(0.12, 0.08, 0.04))
	draw_circle(Vector2(6,  -24 + bob * 0.4), 2.0, Color(0.12, 0.08, 0.04))

func _draw_death() -> void:
	var t        = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	var shirt    = Color(0.68, 0.32, 0.12)
	var jean_col = Color(0.20, 0.30, 0.60)
	var skin_col = Color(0.98, 0.80, 0.60)
	var hat_col  = Color(0.58, 0.42, 0.20)
	var blood    = Color(0.72, 0.0,  0.02)

	if t < 0.38:
		# Phase 1: Dreht sich (vom Schuss getroffen), Hut fliegt hoch
		var pt  = t / 0.38
		var rot = pt * PI * 0.65   # halbe Drehung
		draw_set_transform(Vector2.ZERO, rot, Vector2.ONE)
		draw_rect(Rect2(-12, -8, 24, 22), shirt)
		draw_rect(Rect2(-10, 14,  8, 14), jean_col)
		draw_rect(Rect2(  2, 14,  8, 14), jean_col)
		draw_circle(Vector2(0, -22), 15, skin_col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# Hut fliegt nach oben-links
		var hx = -pt*35.0; var hy = -38.0 - pt*55.0
		draw_rect(Rect2(hx-18, hy, 36, 10), hat_col)
		draw_rect(Rect2(hx-10, hy-14, 20, 16), hat_col)
		# Bluteinschuss an Brust
		if pt > 0.5:
			var bpt = (pt-0.5)/0.5
			for k in range(5):
				var ba = float(k)*TAU/5.0
				draw_circle(Vector2(cos(ba)*bpt*8, -5+sin(ba)*bpt*6), 2.5*bpt, blood)
	else:
		# Phase 2: Zusammenbruch – knirscht in den Dreck
		var pt = (t - 0.38) / 0.62
		var sy = pt*pt * 35.0  # sackt nach unten
		draw_rect(Rect2(-12, -8+sy, 24, 22), shirt)
		draw_rect(Rect2(-10, 14+sy,  8, 14), jean_col)
		draw_rect(Rect2(  2, 14+sy,  8, 14), jean_col)
		draw_circle(Vector2(pt*8, -22+sy*0.4), 15, skin_col)
		# Schnauzbart noch sichtbar
		draw_arc(Vector2(-3+pt*8, -14+sy*0.4), 4, 0.1, PI-0.1, 6, Color(0.30,0.15,0.04), 2.5)
		# Hut liegt daneben (weit weg)
		draw_rect(Rect2(-55, -8+sy+20, 36, 10), hat_col)
		draw_rect(Rect2(-47, -8+sy+6,  20, 16), hat_col)
		# BLUT Fontäne aus der Brustschusswunde
		for k in range(8):
			var ba  = -PI*0.7 + float(k)*PI*0.2
			var bl  = pt*(14.0 + float(k)*4.0)
			draw_line(Vector2(2, -2+sy*0.3), Vector2(2+cos(ba)*bl, -2+sy*0.3+sin(ba)*bl), blood, 3.0)
		# Großer Blutfleck
		draw_circle(Vector2(0, 28+sy), pt*26.0, Color(0.52,0.0,0.01,0.80))
