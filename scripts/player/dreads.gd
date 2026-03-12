extends PlayerBase

# Nik – Inhale Screamer: Lange Dreadlocks bis zu den Knien, Hosenträger, Tätowierungen
# Passive: Kann Gegner greifen & schleudern
# Ultimate: Rasta Rampage (Wirbel-AOE)

var whip_angle: float = 0.0
var _whip_anim: float = 0.0
var _whip_active: bool = false

func _ready() -> void:
	character_id = "dreads"
	max_hp = 120
	move_speed = 200.0
	base_damage = 18.0
	attack_speed = 1.5
	ultimate_cooldown = 13.0
	add_to_group("players")
	super._ready()

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	var flash     = _hit_flash > 0
	# ── South Park Stil ──
	var skin      = Color(0.72, 0.52, 0.36) if not flash else Color(1, 1, 1)  # dunklere Haut
	var dread_col = Color(0.32, 0.20, 0.08)
	var denim     = Color(0.28, 0.38, 0.58)
	var tank      = Color(0.60, 0.52, 0.38)   # Tank-Top
	var suspender = Color(0.55, 0.38, 0.18)
	var _wc   = sin(_anim_time * 5.0)
	var bob   = _wc * 0.8
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.6
	var arm_l = _wc * 0.6

	# Schuhe (breit, flach – South Park)
	draw_rect(Rect2(-14, 27 + bob + leg_l * 0.25, 13, 5), Color(0.12, 0.08, 0.04))
	draw_rect(Rect2(-1,  27 + bob + leg_r * 0.25, 13, 5), Color(0.12, 0.08, 0.04))

	# Beine (Jeans-Shorts)
	draw_rect(Rect2(-11, 14 + bob + leg_l * 0.25, 9, 14), denim)
	draw_rect(Rect2(2,   14 + bob + leg_r * 0.25, 9, 14), denim)

	# Tank-Top Torso
	draw_rect(Rect2(-11, -8 + bob, 22, 22), tank)

	# Hosenträger (2 diagonale Linien)
	draw_line(Vector2(-7, 14 + bob), Vector2(-4, -8 + bob), suspender, 3)
	draw_line(Vector2(7,  14 + bob), Vector2(4,  -8 + bob), suspender, 3)

	# Arme (South Park Stubs, Haut sichtbar)
	draw_rect(Rect2(-19, -3 + bob + arm_l, 8, 13), skin)
	draw_rect(Rect2(11,  -3 + bob + arm_r, 8, 13), skin)

	# Mitten-Hände (SP: runde Klumpen)
	draw_circle(Vector2(-18, 9 + bob + arm_l), 6, skin)
	draw_circle(Vector2(18,  9 + bob + arm_r), 6, skin)

	# Kopf
	draw_circle(Vector2(0, -24 + bob), 16, skin)

	# Kurzer Bart
	draw_arc(Vector2(0, -19 + bob), 7, 0.15, PI - 0.15, 8, dread_col, 3)

	# Augenbrauen (SP: dicke diagonale Linien)
	draw_line(Vector2(-12, -30 + bob), Vector2(-3, -28 + bob), dread_col, 3.0)
	draw_line(Vector2(3,   -28 + bob), Vector2(12, -30 + bob), dread_col, 3.0)

	# Augen (nach innen geneigte Ovale – authentisch South Park)
	var tilt = 0.25; var ew = 5.5; var eh = 3.5
	var lepts = PackedVector2Array(); var repts = PackedVector2Array()
	for i in range(10):
		var a = i * TAU / 10.0; var ox = cos(a) * ew; var oy = sin(a) * eh
		lepts.append(Vector2(-6 + ox*cos(tilt) - oy*sin(tilt), -26 + bob + ox*sin(tilt) + oy*cos(tilt)))
		repts.append(Vector2(6 + ox*cos(-tilt) - oy*sin(-tilt), -26 + bob + ox*sin(-tilt) + oy*cos(-tilt)))
	draw_colored_polygon(lepts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_colored_polygon(repts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_circle(Vector2(-6, -26 + bob), 2.0, Color(0.05, 0.05, 0.05))
	draw_circle(Vector2(6,  -26 + bob), 2.0, Color(0.05, 0.05, 0.05))

	# DREADLOCKS – dicke Stränge die weit nach unten hängen (ikonisch South Park)
	var dread_count = 10
	for i in range(dread_count):
		var t_f     = float(i) / (dread_count - 1)
		var start_x = -13.0 + t_f * 26.0
		var swing   = sin(_anim_time * 1.5 + float(i) * 0.8) * 5.0
		var dlen    = 32.0 + (i % 3) * 8.0
		var pts     = PackedVector2Array()
		for step in range(6):
			var s = float(step) / 5.0
			pts.append(Vector2(start_x + swing * s, -22.0 + bob + s * dlen))
		if pts.size() > 1:
			draw_polyline(pts, dread_col, 4.0)
		draw_circle(pts[-1], 3.0, dread_col.darkened(0.2))

	# Peitsch-Animation
	if _whip_active:
		var whip_end = Vector2(cos(whip_angle), sin(whip_angle)) * (90.0 * _whip_anim)
		draw_line(Vector2.ZERO, whip_end, dread_col, 4.0)
		draw_circle(whip_end, 5.0, Color(1.0, 0.8, 0.2))

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _whip_active:
		_whip_anim += delta * 5.0
		if _whip_anim >= 1.0:
			_whip_active = false
			_whip_anim = 0.0

func _auto_attack() -> void:
	var target = get_nearest_enemy()
	if target:
		whip_angle = (target.global_position - global_position).angle()
		_whip_active = true
		_whip_anim = 0.0
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e):
				var to_e = e.global_position - global_position
				if to_e.length() < 160.0 and abs(to_e.angle() - whip_angle) < 0.6:
					e.take_damage(get_total_damage(), self)
					if randf() < 0.3:
						e.apply_knockback(to_e.normalized().rotated(PI / 2.0) * 300.0)
	if randf() < double_strike_chance:
		spawn_projectile(get_direction_to_nearest_enemy())
	emit_signal("attacked")

func _use_ultimate() -> void:
	var ult_damage = get_total_damage() * 2.5
	if has_upgrade("power_chord"):
		ult_damage *= 1.4
	spawn_shockwave(150.0 * (1.0 + aoe_radius_bonus), ult_damage)
	for i in range(12):
		var angle = i * TAU / 12.0 + _anim_time
		spawn_projectile(Vector2(cos(angle), sin(angle)), ult_damage * 0.5, 300.0)
	AudioManager.play_ultimate_sfx()
	super._use_ultimate()

func _draw_death() -> void:
	var t = _death_anim
	var skin      = Color(0.80, 0.60, 0.42)
	var dread_col = Color(0.32, 0.20, 0.08)
	var denim     = Color(0.30, 0.40, 0.60)
	var suspender = Color(0.55, 0.38, 0.18)
	var blood     = Color(0.72, 0.04, 0.04)
	var drop = min(t * 10.0, 18.0)
	# Blood pool
	if t > 0.9:
		draw_circle(Vector2(0, 24), min((t - 0.9) * 38.0, 32.0), Color(blood.r, blood.g, blood.b, 0.75))
	# Body
	draw_rect(Rect2(-10, 6 + drop, 20, 14), denim)
	draw_rect(Rect2(-9, -8 + drop, 18, 16), skin)
	draw_line(Vector2(-7, 6 + drop), Vector2(-5, -20 + drop), suspender, 3)
	draw_line(Vector2(7, 6 + drop), Vector2(5, -20 + drop), suspender, 3)
	draw_line(Vector2(-9, -4 + drop), Vector2(-16, 4 + drop), skin, 4)
	draw_line(Vector2(9, -4 + drop), Vector2(16, 4 + drop), skin, 4)
	if t < 0.5:
		# Head + dreads flailing wildly
		draw_circle(Vector2(0, -20 + drop), 10, skin)
		draw_arc(Vector2(0, -16 + drop), 7, 0.1, PI - 0.1, 8, dread_col, 3)
		draw_circle(Vector2(-3, -22 + drop), 1.8, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(3, -22 + drop), 1.8, Color(0.1, 0.1, 0.1))
		for i in range(12):
			var ao = (float(i) / 12.0 - 0.5) * TAU * 0.7
			var start_x = sin(ao) * 9.0
			var swing = sin(t * 18.0 + float(i) * 0.6) * 14.0
			var dlen = 30.0 + (i % 3) * 8.0
			var pts = PackedVector2Array()
			for dstep in range(8):
				var ds = float(dstep) / 7.0
				pts.append(Vector2(start_x + swing * ds, -18.0 + drop + ds * dlen))
			if pts.size() > 1:
				draw_polyline(pts, dread_col, 3.5)
	elif t < 0.9:
		# Neck stretching – head pulled upward by dreads
		var pull = (t - 0.5) / 0.4
		var neck_len = pull * 28.0
		var head_y = -20.0 + drop - neck_len
		draw_line(Vector2(0, -8 + drop), Vector2(0, head_y + 10), skin, int(max(2, 8 - pull * 5)))
		draw_circle(Vector2(0, head_y), 10, skin)
		# Dreads coiling upward
		for i in range(8):
			var coil_x = sin(float(i) / 8.0 * TAU + t * 10.0) * 10.0
			draw_line(Vector2(0, head_y), Vector2(coil_x, head_y - 12.0 - float(i) * 4.0), dread_col, 4)
		# Blood seeping from stretched neck
		if pull > 0.5:
			var ba = (pull - 0.5) * 2.0
			draw_circle(Vector2(0, -8 + drop + 6), 4.0 * ba, Color(blood.r, blood.g, blood.b, ba))
	else:
		# Head ripped off – flying upward, blood fountain
		var ft = t - 0.9
		var head_y = -45.0 + drop - ft * 55.0
		var head_x = ft * 18.0
		draw_circle(Vector2(head_x, head_y), 10, skin)
		draw_arc(Vector2(head_x, head_y + 4), 7, 0.1, PI - 0.1, 8, dread_col, 3)
		# Dreads trailing from detached head
		for i in range(8):
			var da = (float(i) / 8.0 - 0.4) * PI
			draw_line(Vector2(head_x, head_y + 8),
				Vector2(head_x + sin(da) * 10, head_y + 8 + ft * 35.0 + cos(da) * 8),
				dread_col, 3)
		# Blood fountain from neck stump
		var fh = min(ft * 60.0, 48.0)
		draw_line(Vector2(0, -8 + drop), Vector2(0, -8 + drop - fh), blood, 8)
		draw_line(Vector2(0, -8 + drop), Vector2(-10, -8 + drop - fh * 0.6), blood, 4)
		draw_line(Vector2(0, -8 + drop), Vector2(10, -8 + drop - fh * 0.6), blood, 4)
	# Particles
	var a = max(0.0, 1.0 - t * 0.35)
	for p in _death_ptcls:
		draw_circle(p["pos"], p["size"] * max(0.1, a), Color(p["col"].r, p["col"].g, p["col"].b, a))
