extends PlayerBase

# Distortion: Kariertes Shirt, mittelgroß, ordentlichere Haare (5. von links im Foto)
# Passive: Verlangsamt Gegner im Aura
# Ultimate: Wall of Noise (Sound-Barriere-Explosion)

const SLOW_RADIUS = 120.0
const SLOW_FACTOR = 0.5

func _ready() -> void:
	character_id = "distortion"
	max_hp = 105
	move_speed = 170.0
	base_damage = 20.0
	attack_speed = 1.1
	ultimate_cooldown = 15.0
	add_to_group("players")
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_apply_slow_aura()

func _apply_slow_aura() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var radius = SLOW_RADIUS * (1.0 + aoe_radius_bonus)
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= radius:
			if e.has_method("apply_slow"):
				e.apply_slow(SLOW_FACTOR, 0.2)

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	var flash  = _hit_flash > 0
	# ── South Park Stil ──
	var skin    = Color(0.96, 0.80, 0.64) if not flash else Color(1, 1, 1)
	var overall = Color(0.22, 0.38, 0.68)   # Latzhose denim blau
	var ov_dark = Color(0.16, 0.28, 0.52)
	var green   = Color(0.22, 0.55, 0.22)   # grünes Karohemd
	var g_dark  = Color(0.14, 0.38, 0.14)
	var hair    = Color(0.22, 0.18, 0.12)
	var _wc   = sin(_anim_time * 5.0)
	var bob   = _wc * 0.8
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.6
	var arm_l = _wc * 0.6

	# Slow-Aura-Ring (halbtransparent, im Hintergrund)
	var aura_alpha = 0.10 + sin(_anim_time * 3) * 0.05
	var aura_r = SLOW_RADIUS * (1.0 + aoe_radius_bonus)
	draw_arc(Vector2.ZERO, aura_r, 0, TAU, 32, Color(0.4, 0.6, 1.0, aura_alpha), 1.5)

	# Schuhe (breit, flach – South Park)
	draw_rect(Rect2(-14, 27 + bob + leg_l * 0.25, 13, 5), Color(0.12, 0.08, 0.04))
	draw_rect(Rect2(-1,  27 + bob + leg_r * 0.25, 13, 5), Color(0.12, 0.08, 0.04))

	# Beine (Latzhose denim)
	draw_rect(Rect2(-11, 14 + bob + leg_l * 0.25, 9, 14), overall)
	draw_rect(Rect2(2,   14 + bob + leg_r * 0.25, 9, 14), overall)

	# Arme (grünes Karohemd – unter Latzhose sichtbar)
	draw_rect(Rect2(-20, -3 + bob + arm_l, 8, 13), green)
	for y_off in [-1, 4, 9]:
		draw_line(Vector2(-20, y_off + bob + arm_l), Vector2(-12, y_off + bob + arm_l), g_dark, 1.0)
	draw_rect(Rect2(12,  -3 + bob + arm_r, 8, 13), green)
	for y_off in [-1, 4, 9]:
		draw_line(Vector2(12, y_off + bob + arm_r), Vector2(20, y_off + bob + arm_r), g_dark, 1.0)

	# Latzhosen-Torso (Brust-Latz, bedeckt das grüne Hemd)
	draw_rect(Rect2(-12, -8 + bob, 24, 22), overall)

	# Latzhosen-Träger (Y-Form)
	draw_line(Vector2(-8, -8 + bob), Vector2(-3, -24 + bob), ov_dark, 3)
	draw_line(Vector2(8,  -8 + bob), Vector2(3,  -24 + bob), ov_dark, 3)

	# Mitten-Hände (SP: runde Klumpen)
	draw_circle(Vector2(-19, 9 + bob + arm_l), 6, skin)
	draw_circle(Vector2(19,  9 + bob + arm_r), 6, skin)

	# Kopf
	draw_circle(Vector2(0, -24 + bob), 15, skin)

	# Geordnete Haare (nach oben gestylt)
	draw_arc(Vector2(0, -24 + bob), 15, PI, 0, 14, hair, 5)
	for i in range(5):
		var hx = -8.0 + float(i) * 4.0
		draw_line(Vector2(hx, -38 + bob), Vector2(hx + 1.0, -24 + bob), hair, 2.5)

	# Kurzer Bart
	draw_arc(Vector2(0, -19 + bob), 7, 0.1, PI - 0.1, 8, Color(0.28, 0.18, 0.10), 2.5)

	# Augenbrauen (SP: dicke diagonale Linien)
	draw_line(Vector2(-12, -30 + bob), Vector2(-3, -28 + bob), hair, 3.0)
	draw_line(Vector2(3,   -28 + bob), Vector2(12, -30 + bob), hair, 3.0)

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

func _auto_attack() -> void:
	var dir = get_direction_to_nearest_enemy()
	spawn_projectile(dir, -1, 380.0)
	spawn_projectile(dir.rotated(PI / 4.0),  get_total_damage() * 0.6, 300.0)
	spawn_projectile(dir.rotated(-PI / 4.0), get_total_damage() * 0.6, 300.0)
	if randf() < double_strike_chance:
		spawn_projectile(dir.rotated(PI / 2.0))
	emit_signal("attacked")

func _use_ultimate() -> void:
	var ult_damage = get_total_damage() * 3.5
	if has_upgrade("power_chord"):
		ult_damage *= 1.4
	var sw_scene = load("res://scenes/entities/projectiles/shockwave.tscn")
	if sw_scene:
		var sw = sw_scene.instantiate()
		sw.global_position = global_position
		sw.radius = 300.0 * (1.0 + aoe_radius_bonus)
		sw.damage = ult_damage
		sw.slow_factor = 0.3
		sw.slow_duration = 4.0
		sw.shooter = self
		get_tree().current_scene.add_child(sw)
	AudioManager.play_ultimate_sfx()
	super._use_ultimate()

func _draw_death() -> void:
	var t = _death_anim
	var skin   = Color(0.80, 0.62, 0.44)
	var shirt  = Color(0.28, 0.38, 0.55)
	var blood  = Color(0.72, 0.04, 0.04)
	var purple = Color(0.7, 0.2, 1.0)
	var spark  = Color(0.9, 0.8, 1.0)
	if t < 0.6:
		# Body convulsing with purple lightning electrocution
		var jitter = sin(t * 45.0) * min(t * 8.0, 5.0)
		var jy = sin(t * 60.0) * min(t * 5.0, 3.0)
		draw_rect(Rect2(-9 + jitter, 8 + jy, 18, 14), Color(0.22, 0.22, 0.30))
		draw_rect(Rect2(-11 + jitter, -8 + jy, 22, 18), shirt)
		draw_line(Vector2(-11 + jitter, -4 + jy), Vector2(-17 + jitter, 5 + jy), skin, 4)
		draw_line(Vector2(11 + jitter, -4 + jy), Vector2(17 + jitter, 5 + jy), skin, 4)
		var head_col = skin.lerp(purple, t * 1.2)
		draw_circle(Vector2(jitter, -22 + jy), 10, head_col)
		# Electrocuted X eyes
		draw_line(Vector2(-5 + jitter, -25 + jy), Vector2(-3 + jitter, -23 + jy), spark, 2)
		draw_line(Vector2(-3 + jitter, -25 + jy), Vector2(-5 + jitter, -23 + jy), spark, 2)
		draw_line(Vector2(5 + jitter, -25 + jy), Vector2(3 + jitter, -23 + jy), spark, 2)
		draw_line(Vector2(3 + jitter, -25 + jy), Vector2(5 + jitter, -23 + jy), spark, 2)
		# Purple lightning zigzag arcs
		for li in range(4):
			var lx = -20.0 + float(li) * 14.0
			var zig = sin(t * 35.0 + float(li) * 2.0) * 12.0
			draw_line(Vector2(lx, -40), Vector2(lx + zig, -25), purple, 2)
			draw_line(Vector2(lx + zig, -25), Vector2(lx - zig * 0.5, -10), purple, 2)
			draw_line(Vector2(lx - zig * 0.5, -10), Vector2(lx, 10), purple, 2)
		# Purple glow pulse
		var aura_a = sin(t * 30.0) * 0.15 + 0.1
		draw_arc(Vector2.ZERO, 25, 0, TAU, 16, Color(purple.r, purple.g, purple.b, aura_a), 8)
	else:
		# Body exploded
		var et = t - 0.6
		# Purple explosion flash
		var flash_a = max(0.0, 0.6 - et * 1.5)
		draw_circle(Vector2.ZERO, min(et * 60.0, 50.0), Color(purple.r, purple.g, purple.b, flash_a))
		# Body chunks flying outward
		for i in range(10):
			var angle = float(i) * TAU / 10.0
			var dist = et * 75.0
			var chunk = Vector2(cos(angle) * dist, sin(angle) * dist)
			var cs = max(0.5, 6.0 - et * 4.0)
			var chunk_col = [skin, shirt, Color(0.22, 0.22, 0.30)][i % 3]
			draw_circle(chunk, cs, chunk_col)
		# Blood radial spray
		for i in range(8):
			var ba = float(i) * TAU / 8.0 + 0.2
			var bd = min(et * 50.0, 38.0)
			draw_line(Vector2.ZERO, Vector2(cos(ba) * bd, sin(ba) * bd), blood, 3)
		draw_circle(Vector2(0, 22), min(et * 30.0, 24.0), Color(blood.r, blood.g, blood.b, 0.7))
		# Lingering electric sparks
		for i in range(6):
			var sx = sin(float(i) * 1.2 + et * 5.0) * 20.0
			var sy = cos(float(i) * 0.9 + et * 4.0) * 15.0
			draw_circle(Vector2(sx, sy - 10), max(0.5, 2.0 - et), spark)
	# Particles
	var a = max(0.0, 1.0 - t * 0.35)
	for p in _death_ptcls:
		draw_circle(p["pos"], p["size"] * max(0.1, a), Color(p["col"].r, p["col"].g, p["col"].b, a))
