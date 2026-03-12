extends PlayerBase

# Chicken – Sänger: Kappe, Sonnenbrille, kariertes Shirt
# Passive: Gezielte Schallstrahlen, hohe Reichweite
# Ultimate: Feedback Collapse (Giant Soundburst)

const BEAM_RANGE = 600.0

func _ready() -> void:
	character_id = "shouter"
	max_hp = 90
	move_speed = 190.0
	base_damage = 28.0
	attack_speed = 0.8
	ultimate_cooldown = 14.0
	add_to_group("players")
	super._ready()

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	var flash   = _hit_flash > 0
	# ── South Park Stil (Armin-Design: goldene Haare, Schrei-Mund) ──
	var skin    = Color(0.98, 0.82, 0.66) if not flash else Color(1, 1, 1)
	var flannel = Color(0.58, 0.22, 0.12)   # rotes Flanellhemd
	var f_dark  = Color(0.08, 0.04, 0.04)   # schwarz für rot-schwarzes Plaid
	var denim   = Color(0.28, 0.38, 0.58)
	var beard   = Color(0.32, 0.22, 0.10)
	var _wc   = sin(_anim_time * 5.0)
	var bob   = _wc * 0.8
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.6
	var arm_l = _wc * 0.6

	# Schuhe (breit, flach – South Park)
	draw_rect(Rect2(-15, 29 + bob + leg_l * 0.25, 14, 6), Color(0.12, 0.08, 0.04))
	draw_rect(Rect2(-1,  29 + bob + leg_r * 0.25, 14, 6), Color(0.12, 0.08, 0.04))

	# Beine (Jeans-Shorts)
	draw_rect(Rect2(-12, 16 + bob + leg_l * 0.25, 10, 14), denim)
	draw_rect(Rect2(2,   16 + bob + leg_r * 0.25, 10, 14), denim)

	# Flanellhemd Torso (rot-schwarz kariert)
	draw_rect(Rect2(-14, -10 + bob, 28, 26), flannel)
	for y_off in [-6, 0, 6, 12]:
		draw_line(Vector2(-14, y_off + bob), Vector2(14, y_off + bob), f_dark, 1.0)
	for x_off in [-10, -3, 4, 11]:
		draw_line(Vector2(x_off, -10 + bob), Vector2(x_off, 16 + bob), f_dark, 1.0)

	# Arme (kräftige Stubs)
	draw_rect(Rect2(-22, -4 + bob + arm_l, 8, 15), flannel)
	draw_rect(Rect2(14,  -4 + bob + arm_r, 8, 15), flannel)

	# Mitten-Hände (SP: runde Klumpen)
	draw_circle(Vector2(-21, 10 + bob + arm_l), 7, skin)
	draw_circle(Vector2(21,  10 + bob + arm_r), 7, skin)

	# Kopf (groß)
	draw_circle(Vector2(0, -26 + bob), 18, skin)

	# Lange goldene Haare (bis zu den Knien – ikonisch)
	var gold = Color(0.92, 0.80, 0.22)
	for i in range(14):
		var hx = -17.0 + float(i) * 2.6
		var swing = sin(_anim_time * 1.6 + float(i) * 0.65) * 7.0
		var hpts = PackedVector2Array()
		for step in range(8):
			var s = float(step) / 7.0
			hpts.append(Vector2(hx + swing * s * s, -44.0 + bob + s * 110.0))
		draw_polyline(hpts, gold, 3.5)

	# Langer Vollbart (bis auf die Brust)
	var bpts = PackedVector2Array([
		Vector2(-15, -18 + bob), Vector2(-18, -10 + bob),
		Vector2(-12, -4  + bob), Vector2(0,   0   + bob),
		Vector2(12,  -4  + bob), Vector2(18,  -10 + bob),
		Vector2(15,  -18 + bob),
	])
	draw_colored_polygon(bpts, beard)

	# Weit aufgerissener Schrei-Mund (South Park)
	draw_arc(Vector2(0, -19 + bob), 9, 0.08, PI - 0.08, 8, Color(0.05, 0.02, 0.02), 14)

	# Augenbrauen (SP: dicke diagonale Linien)
	draw_line(Vector2(-14, -34 + bob), Vector2(-4, -32 + bob), beard, 3.5)
	draw_line(Vector2(4,   -32 + bob), Vector2(14, -34 + bob), beard, 3.5)

	# Augen (nach innen geneigte Ovale)
	var tilt = 0.25; var ew = 7.0; var eh = 4.5
	var lepts = PackedVector2Array(); var repts = PackedVector2Array()
	for i in range(10):
		var a = i * TAU / 10.0; var ox = cos(a) * ew; var oy = sin(a) * eh
		lepts.append(Vector2(-8 + ox*cos(tilt) - oy*sin(tilt), -30 + bob + ox*sin(tilt) + oy*cos(tilt)))
		repts.append(Vector2(8 + ox*cos(-tilt) - oy*sin(-tilt), -30 + bob + ox*sin(-tilt) + oy*cos(-tilt)))
	draw_colored_polygon(lepts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_colored_polygon(repts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_circle(Vector2(-8, -30 + bob), 2.5, Color(0.05, 0.05, 0.05))
	draw_circle(Vector2(8,  -30 + bob), 2.5, Color(0.05, 0.05, 0.05))

func _auto_attack() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best_target: Node2D = null
	var best_dist = BEAM_RANGE
	for e in enemies:
		if is_instance_valid(e):
			var d = global_position.distance_to(e.global_position)
			if d < best_dist:
				best_dist = d
				best_target = e
	if best_target:
		var dir = (best_target.global_position - global_position).normalized()
		spawn_projectile(dir, -1, 550.0)
		if randf() < double_strike_chance:
			spawn_projectile(dir)
	emit_signal("attacked")

func _use_ultimate() -> void:
	var proj_count = 24
	var ult_damage = get_total_damage() * 4.0
	if has_upgrade("power_chord"):
		ult_damage *= 1.4
	for i in range(proj_count):
		var angle = i * TAU / proj_count
		spawn_projectile(Vector2(cos(angle), sin(angle)), ult_damage, 500.0, 99)
	AudioManager.play_ultimate_sfx()
	super._use_ultimate()

func _draw_death() -> void:
	var t = _death_anim
	var skin  = Color(0.82, 0.62, 0.44)
	var shirt = Color(0.45, 0.35, 0.25)
	var cap   = Color(0.25, 0.25, 0.30)
	var blood = Color(0.72, 0.04, 0.04)
	var drop = min(t * 12.0, 20.0)
	# Blood pool
	if t > 0.6:
		draw_circle(Vector2(0, 22), min((t - 0.6) * 30.0, 24.0), Color(blood.r, blood.g, blood.b, 0.75))
	# Body
	draw_rect(Rect2(-9, 10 + drop, 8, 12), Color(0.3, 0.3, 0.4))
	draw_rect(Rect2(1, 10 + drop, 8, 12), Color(0.3, 0.3, 0.4))
	draw_rect(Rect2(-12, -8 + drop, 24, 20), shirt)
	draw_line(Vector2(-12, -4 + drop), Vector2(-18, 5 + drop), skin, 5)
	draw_line(Vector2(12, -4 + drop), Vector2(18, 5 + drop), skin, 5)
	if t < 0.55:
		# Head swelling, cap wobbling off
		var swell = 1.0 + t * 0.7 + sin(t * 22.0) * 0.07
		var hr = 11.0 * swell
		draw_circle(Vector2(0, -26 + drop), hr, skin)
		# Cap flying off
		var cap_y = -37.0 + drop - t * 50.0
		var cap_x = t * 20.0
		draw_rect(Rect2(-11 + cap_x, cap_y, 22, 10), cap)
		# Bulging eyes
		var er = 2.0 + t * 3.5
		draw_circle(Vector2(-4, -29 + drop), er, Color(0.9, 0.9, 0.9))
		draw_circle(Vector2(4, -29 + drop), er, Color(0.9, 0.9, 0.9))
		draw_circle(Vector2(-4, -29 + drop), er * 0.5, Color(0.1, 0.05, 0.5))
		draw_circle(Vector2(4, -29 + drop), er * 0.5, Color(0.1, 0.05, 0.5))
		# Wide screaming mouth
		draw_arc(Vector2(0, -21 + drop), 5.0 + t * 6.0, 0.0, PI, 8, Color(0.05, 0.0, 0.0), 5)
	else:
		# Head chunks fly outward
		var et = t - 0.55
		for i in range(8):
			var angle = float(i) * TAU / 8.0
			var dist = et * 90.0
			var chunk_pos = Vector2(cos(angle) * dist, -26 + drop + sin(angle) * dist)
			draw_circle(chunk_pos, max(1.0, 7.0 - et * 5.0), skin)
		# Radial blood spray
		for i in range(12):
			var angle = float(i) * TAU / 12.0
			var bd = min(et * 60.0, 44.0)
			draw_line(Vector2(0, -26 + drop),
				Vector2(cos(angle) * bd, -26 + drop + sin(angle) * bd), blood, 2)
		# Neck stump blood fountain
		var fh = min(et * 45.0, 35.0)
		draw_line(Vector2(0, -6 + drop), Vector2(0, -6 + drop - fh), blood, 7)
	# Particles
	var a = max(0.0, 1.0 - t * 0.35)
	for p in _death_ptcls:
		draw_circle(p["pos"], p["size"] * max(0.1, a), Color(p["col"].r, p["col"].g, p["col"].b, a))
