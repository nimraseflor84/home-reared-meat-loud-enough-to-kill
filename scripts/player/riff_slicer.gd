extends PlayerBase

# Riff Slicer: Kleiner, Latzhose, weißes Shirt, wilder Bart/Haare (6. ganz rechts)
# Passive: Durchdringt mehrere Gegner
# Ultimate: Solo des Untergangs (Laser-Riff)

func _ready() -> void:
	character_id = "riff_slicer"
	max_hp = 95
	move_speed = 210.0
	base_damage = 22.0
	attack_speed = 0.85
	ultimate_cooldown = 16.0
	pierce = 1
	add_to_group("players")
	super._ready()

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	var flash   = _hit_flash > 0
	# ── South Park Stil ──
	var skin      = Color(0.98, 0.82, 0.66) if not flash else Color(1, 1, 1)
	var tank      = Color(0.95, 0.92, 0.88)   # weißes Tank-Top
	var pants     = Color(0.22, 0.26, 0.40)    # dunkle Jeans
	var suspender = Color(0.32, 0.18, 0.06)    # dunkle Leder-Hosenträger
	var straw     = Color(0.82, 0.72, 0.40)    # Strohhut
	var beard     = Color(0.32, 0.20, 0.10)
	var _wc   = sin(_anim_time * 5.0)
	var bob   = _wc * 0.8
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.6
	var arm_l = _wc * 0.6

	# Schuhe (breit, flach – South Park)
	draw_rect(Rect2(-14, 27 + bob + leg_l * 0.25, 13, 5), Color(0.12, 0.08, 0.04))
	draw_rect(Rect2(-1,  27 + bob + leg_r * 0.25, 13, 5), Color(0.12, 0.08, 0.04))

	# Beine (dunkle Jeans)
	draw_rect(Rect2(-11, 14 + bob + leg_l * 0.25, 9, 14), pants)
	draw_rect(Rect2(2,   14 + bob + leg_r * 0.25, 9, 14), pants)

	# Tank-Top Torso (weiß)
	draw_rect(Rect2(-11, -8 + bob, 22, 22), tank)

	# Hosenträger (über Tank-Top)
	draw_line(Vector2(-7, 14 + bob), Vector2(-4, -8 + bob), suspender, 3)
	draw_line(Vector2(7,  14 + bob), Vector2(4,  -8 + bob), suspender, 3)

	# Arme (Haut sichtbar – Kurzarm-Tank-Top)
	draw_rect(Rect2(-19, -3 + bob + arm_l, 7, 13), skin)
	draw_rect(Rect2(12,  -3 + bob + arm_r, 7, 13), skin)

	# Mitten-Hände (SP: runde Klumpen)
	draw_circle(Vector2(-19, 9 + bob + arm_l), 6, skin)
	draw_circle(Vector2(19,  9 + bob + arm_r), 6, skin)

	# Kopf
	draw_circle(Vector2(0, -24 + bob), 16, skin)

	# Strohhut (breit, Südstaaten-Stil)
	draw_rect(Rect2(-22, -38 + bob, 44, 6), straw)    # Krempe (sehr breit)
	draw_rect(Rect2(-10, -54 + bob, 20, 18), straw)   # Krone
	draw_line(Vector2(-10, -38 + bob), Vector2(10, -38 + bob), straw.darkened(0.3), 2)  # Band

	# Zerzauster Vollbart
	var bpts = PackedVector2Array([
		Vector2(-12, -18 + bob), Vector2(-14, -12 + bob),
		Vector2(-9,  -7  + bob), Vector2(0,   -5  + bob),
		Vector2(9,   -7  + bob), Vector2(14,  -12 + bob),
		Vector2(12,  -18 + bob),
	])
	draw_colored_polygon(bpts, beard)

	# Augenbrauen (SP: dicke diagonale Linien)
	draw_line(Vector2(-12, -30 + bob), Vector2(-3, -28 + bob), beard, 3.0)
	draw_line(Vector2(3,   -28 + bob), Vector2(12, -30 + bob), beard, 3.0)

	# Augen (nach innen geneigte Ovale – authentisch South Park)
	var tilt = 0.25; var ew = 5.5; var eh = 3.5
	var lepts = PackedVector2Array(); var repts = PackedVector2Array()
	for i in range(10):
		var a = i * TAU / 10.0; var ox = cos(a) * ew; var oy = sin(a) * eh
		lepts.append(Vector2(-6 + ox*cos(tilt) - oy*sin(tilt), -27 + bob + ox*sin(tilt) + oy*cos(tilt)))
		repts.append(Vector2(6 + ox*cos(-tilt) - oy*sin(-tilt), -27 + bob + ox*sin(-tilt) + oy*cos(-tilt)))
	draw_colored_polygon(lepts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_colored_polygon(repts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_circle(Vector2(-6, -27 + bob), 2.0, Color(0.05, 0.05, 0.05))
	draw_circle(Vector2(6,  -27 + bob), 2.0, Color(0.05, 0.05, 0.05))

func _auto_attack() -> void:
	var dir = get_direction_to_nearest_enemy()
	for offset in [-0.15, 0.0, 0.15]:
		spawn_projectile(dir.rotated(offset), -1, 450.0, pierce)
	if randf() < double_strike_chance:
		spawn_projectile(dir.rotated(PI / 6.0))
	emit_signal("attacked")

func _use_ultimate() -> void:
	var ult_damage = get_total_damage() * 5.0
	if has_upgrade("power_chord"):
		ult_damage *= 1.4
	for i in range(8):
		var angle = i * TAU / 8.0 + _anim_time
		spawn_projectile(Vector2(cos(angle), sin(angle)), ult_damage, 700.0, 99)
	spawn_shockwave(120.0 * (1.0 + aoe_radius_bonus), ult_damage * 0.5)
	AudioManager.play_ultimate_sfx()
	super._use_ultimate()

func _draw_death() -> void:
	var t = _death_anim
	var skin    = Color(0.80, 0.60, 0.42)
	var overall = Color(0.85, 0.83, 0.78)
	var hair    = Color(0.28, 0.18, 0.10)
	var blood   = Color(0.72, 0.04, 0.04)
	var guitar  = Color(0.65, 0.10, 0.05)
	if t < 0.5:
		# Body intact, Flying-V guitar descending and spinning
		draw_rect(Rect2(-9, 10, 8, 12), overall)
		draw_rect(Rect2(1, 10, 8, 12), overall)
		draw_rect(Rect2(-10, -6, 20, 18), overall)
		draw_rect(Rect2(-9, -8, 18, 10), Color(0.92, 0.90, 0.88))
		draw_line(Vector2(-10, -3), Vector2(-16, 5), skin, 4)
		draw_line(Vector2(10, -3), Vector2(16, 5), skin, 4)
		draw_circle(Vector2(0, -26), 10, skin)
		for i in range(12):
			var ba = float(i) / 12.0 * TAU - PI / 2.0
			var hlen = 10.0 + sin(float(i) * 0.9) * 3.5
			draw_line(Vector2(cos(ba), sin(ba)) * 9.0 + Vector2(0, -26),
				Vector2(cos(ba), sin(ba)) * (9.0 + hlen) + Vector2(0, -26), hair, 2.0)
		draw_circle(Vector2(-3, -28), 1.8, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(3, -28), 1.8, Color(0.1, 0.1, 0.1))
		# Guitar falling from above, spinning
		var gy = -90.0 + (t / 0.5) * 80.0
		var gr = t * 12.0
		var gx = sin(gr) * 6.0
		draw_line(Vector2(gx - 12, gy - 8), Vector2(gx + 12, gy + 8), guitar, 5)
		draw_line(Vector2(gx - 10, gy + 6), Vector2(gx, gy - 12), guitar, 6)
		draw_line(Vector2(gx + 10, gy + 6), Vector2(gx, gy - 12), guitar, 6)
	else:
		# Body split diagonally (top-left vs bottom-right)
		var st = min((t - 0.5) * 2.2, 1.0)
		var tl = Vector2(-st * 14.0, -st * 10.0)
		var br = Vector2(st * 14.0, st * 10.0)
		# Top-left half (head + upper-left body)
		draw_circle(Vector2(0, -26) + tl, 10, skin)
		draw_rect(Rect2(-10 + tl.x, -6 + tl.y, 12, 14), overall)
		draw_line(Vector2(-10, -3) + tl, Vector2(-16, 5) + tl, skin, 4)
		# Bottom-right half
		draw_rect(Rect2(-2 + br.x, -4 + br.y, 12, 14), overall)
		draw_rect(Rect2(-9 + br.x, 10 + br.y, 8, 12), overall)
		draw_rect(Rect2(1 + br.x, 10 + br.y, 8, 12), overall)
		draw_line(Vector2(10, -3) + br, Vector2(16, 5) + br, skin, 4)
		# Blood along diagonal cut line
		for i in range(9):
			var bx = -16.0 + float(i) * 4.0
			var by = bx * 0.65
			draw_circle(Vector2(bx, by), 3.5, blood)
		draw_circle(Vector2(0, 22), min(st * 28.0, 22.0), Color(blood.r, blood.g, blood.b, 0.7))
		# Guitar embedded in ground
		draw_line(Vector2(2, -5), Vector2(2, -38), guitar, 5)
		draw_line(Vector2(2, -12), Vector2(-14, -32), guitar, 6)
		draw_line(Vector2(2, -12), Vector2(18, -32), guitar, 6)
	# Particles
	var a = max(0.0, 1.0 - t * 0.35)
	for p in _death_ptcls:
		draw_circle(p["pos"], p["size"] * max(0.1, a), Color(p["col"].r, p["col"].g, p["col"].b, a))
