extends PlayerBase

# Bassist: Größter, wildeste Haare, Flanellhemd offen, langer Bart (Mitte im Foto)
# Passive: Bodenwellen bei Kills
# Ultimate: Earthshaker Drop (Area-Explosion)

func _ready() -> void:
	character_id = "bassist"
	max_hp = 120
	move_speed = 160.0
	base_damage = 22.0
	attack_speed = 0.9
	ultimate_cooldown = 14.0
	add_to_group("players")
	super._ready()

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	var flash   = _hit_flash > 0
	# ── Chicken – Kappe, Sonnenbrille, rotes Flanellhemd ──
	var skin    = Color(0.98, 0.82, 0.66) if not flash else Color(1, 1, 1)
	var shirt   = Color(0.75, 0.12, 0.10)   # rotes Flanellhemd
	var p_line  = Color(0.30, 0.04, 0.03)   # dunkle Plaid-Linien
	var denim   = Color(0.28, 0.38, 0.58)
	var beard   = Color(0.32, 0.22, 0.10)
	var cap_col = Color(0.12, 0.10, 0.14)   # sehr dunkler Hut
	var glass_c = Color(0.06, 0.06, 0.08)   # Sonnenbrille
	var _wc   = sin(_anim_time * 4.0)
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

	# Rotes Flanellhemd Torso (kariert)
	draw_rect(Rect2(-14, -10 + bob, 28, 26), shirt)
	for y_off in [-6, 0, 6, 12]:
		draw_line(Vector2(-14, y_off + bob), Vector2(14, y_off + bob), p_line, 1.0)
	for x_off in [-10, -3, 4, 11]:
		draw_line(Vector2(x_off, -10 + bob), Vector2(x_off, 16 + bob), p_line, 1.0)

	# Arme
	draw_rect(Rect2(-22, -4 + bob + arm_l, 8, 15), shirt)
	draw_rect(Rect2(14,  -4 + bob + arm_r, 8, 15), shirt)

	# Hände
	draw_circle(Vector2(-21, 10 + bob + arm_l), 7, skin)
	draw_circle(Vector2(21,  10 + bob + arm_r), 7, skin)

	# Kopf
	draw_circle(Vector2(0, -26 + bob), 18, skin)

	# Breiter dunkler Hut (Wide-Brim)
	draw_rect(Rect2(-24, -40 + bob, 48, 6), cap_col)   # Krempe
	draw_rect(Rect2(-12, -58 + bob, 24, 20), cap_col)  # Krone
	draw_rect(Rect2(-13, -40 + bob, 26, 4), cap_col.darkened(0.2))  # Krempen-Übergang

	# Kinn-Bart (kurzer Vollbart)
	var bpts = PackedVector2Array([
		Vector2(-12, -18 + bob), Vector2(-14, -10 + bob),
		Vector2(-8,  -4  + bob), Vector2(0,   -2  + bob),
		Vector2(8,   -4  + bob), Vector2(14,  -10 + bob),
		Vector2(12,  -18 + bob),
	])
	draw_colored_polygon(bpts, beard)

	# Mund (leicht offen – neutral)
	draw_arc(Vector2(0, -20 + bob), 5, 0.2, PI - 0.2, 6, Color(0.12, 0.04, 0.04), 6)

	# Augenbrauen
	draw_line(Vector2(-14, -36 + bob), Vector2(-4, -34 + bob), beard, 3.5)
	draw_line(Vector2(4,   -34 + bob), Vector2(14, -36 + bob), beard, 3.5)

	# Sonnenbrille (zwei ovale Gläser + Steg)
	draw_circle(Vector2(-8, -30 + bob), 7, glass_c)
	draw_circle(Vector2(8,  -30 + bob), 7, glass_c)
	draw_line(Vector2(-1, -30 + bob), Vector2(1, -30 + bob), glass_c.lightened(0.2), 2)
	draw_line(Vector2(-15, -30 + bob), Vector2(-15, -26 + bob), glass_c.lightened(0.1), 2)
	draw_line(Vector2(15,  -30 + bob), Vector2(15,  -26 + bob), glass_c.lightened(0.1), 2)

func _auto_attack() -> void:
	var dir = get_direction_to_nearest_enemy()
	spawn_projectile(dir, get_total_damage() * 1.2, 350.0)
	for angle in [-0.3, 0.3]:
		spawn_projectile(dir.rotated(angle), get_total_damage() * 0.7, 300.0)
	if randf() < double_strike_chance:
		spawn_projectile(dir)
	emit_signal("attacked")

func _on_kill_passive(_enemy) -> void:
	spawn_shockwave(70.0 * (1.0 + aoe_radius_bonus), get_total_damage() * 1.5)

func _use_ultimate() -> void:
	var ult_damage = get_total_damage() * 4.0
	if has_upgrade("power_chord"):
		ult_damage *= 1.4
	for i in range(4):
		var sw = _SW_SCENE.instantiate()
		sw.global_position = global_position
		sw.radius = (100.0 + i * 60.0) * (1.0 + aoe_radius_bonus)
		sw.damage = ult_damage / (1.0 + i * 0.5)
		sw.expand_time = 0.2 + i * 0.1
		sw.shooter = self
		if has_upgrade("distortion_pedal"):
			sw.slow_factor = 0.4
			sw.slow_duration = 3.0
		get_tree().current_scene.add_child(sw)
	AudioManager.play_ultimate_sfx()
	super._use_ultimate()

func _draw_death() -> void:
	var t = _death_anim
	var skin    = Color(0.80, 0.60, 0.42)
	var flannel = Color(0.55, 0.22, 0.12)
	var denim   = Color(0.28, 0.38, 0.58)
	var hair    = Color(0.30, 0.20, 0.10)
	var blood   = Color(0.72, 0.04, 0.04)
	if t < 0.5:
		# Sub-bass compression rings crushing body inward
		var compress = t / 0.5
		var sc = 1.0 - compress * 0.55
		var bw = 24.0 * sc
		draw_rect(Rect2(-bw / 2, 8, bw, 16.0 * sc), denim)
		var tw = 28.0 * sc
		draw_rect(Rect2(-tw / 2, -10, tw, 22.0 * sc), flannel)
		draw_line(Vector2(-tw / 2, -6), Vector2(-tw / 2 - 8.0 * sc, 5), flannel, int(max(1.0, 7.0 * sc)))
		draw_line(Vector2(tw / 2, -6), Vector2(tw / 2 + 8.0 * sc, 5), flannel, int(max(1.0, 7.0 * sc)))
		draw_circle(Vector2(0, -24.0 * sc), 14.0 * sc, skin)
		# Wild hair compressed
		for i in range(16):
			var ba = float(i) / 16.0 * TAU - PI / 2.0
			var hlen = (14.0 + sin(float(i) * 0.8) * 4.0) * sc
			draw_line(
				Vector2(cos(ba), sin(ba)) * 12.0 * sc + Vector2(0, -24.0 * sc),
				Vector2(cos(ba), sin(ba)) * (12.0 * sc + hlen) + Vector2(0, -24.0 * sc),
				hair, max(1.0, 2.5 * sc))
		# Compression rings closing in
		for ri in range(3):
			var ring_r = (60.0 - compress * 55.0) * (1.0 + float(ri) * 0.4)
			if ring_r > 5:
				draw_arc(Vector2.ZERO, ring_r, 0, TAU, 20, Color(blood.r, blood.g, blood.b, 0.3 + float(ri) * 0.1), 3)
	elif t < 0.75:
		# EXPLOSION – body chunks fly outward
		var et = (t - 0.5) / 0.25
		var dist = et * 100.0
		var flash_a = max(0.0, 1.0 - et * 2.5)
		draw_circle(Vector2.ZERO, et * 70.0, Color(1.0, 0.6, 0.2, flash_a))
		for i in range(10):
			var angle = float(i) * TAU / 10.0
			var chunk = Vector2(cos(angle) * dist, sin(angle) * dist)
			var cs = max(0.5, 8.0 - et * 6.0)
			draw_circle(chunk, cs, [skin, flannel, denim, hair][i % 4])
		for i in range(12):
			var ba = float(i) * TAU / 12.0
			draw_line(Vector2.ZERO, Vector2(cos(ba) * dist * 0.6, sin(ba) * dist * 0.6), blood, 3)
	else:
		# Aftermath – scattered chunks, blood pool, bass string shrapnel
		var at = t - 0.75
		draw_circle(Vector2(0, 22), min(at * 50.0, 38.0), Color(blood.r, blood.g, blood.b, 0.7))
		for i in range(10):
			var angle = float(i) * TAU / 10.0
			draw_circle(Vector2(cos(angle) * 85.0, sin(angle) * 85.0), 3.0, [skin, flannel, denim, hair][i % 4])
		# Bass strings shooting out as shrapnel
		for i in range(4):
			var ba = float(i) * PI / 4.0 + 0.3
			var slen = min(at * 120.0, 90.0)
			draw_line(Vector2.ZERO, Vector2(cos(ba) * slen, sin(ba) * slen), Color(0.7, 0.7, 0.7), 2)
	# Particles
	var a = max(0.0, 1.0 - t * 0.35)
	for p in _death_ptcls:
		draw_circle(p["pos"], p["size"] * max(0.1, a), Color(p["col"].r, p["col"].g, p["col"].b, a))
