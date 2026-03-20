extends PlayerBase

# Manni: Stämmig, Latzhose, kurze Haare, dicker Bart
# Passive: Kills erhöhen Angriffstempo
# Ultimate: Double Bass Inferno (360° Shockwave)

const PASSIVE_ATTACK_SPEED_PER_KILL = 0.03
const MAX_PASSIVE_STACKS = 10
var passive_stacks: int = 0

func _ready() -> void:
	character_id = "manni"
	max_hp = 110
	move_speed = 185.0
	base_damage = 22.0
	attack_speed = 1.2
	ultimate_cooldown = 12.0
	add_to_group("players")
	super._ready()

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	var flash   = _hit_flash > 0
	# ── South Park Stil ──
	var skin    = Color(0.98, 0.82, 0.66) if not flash else Color(1, 1, 1)
	var overall = Color(0.18, 0.28, 0.55)   # dunkelblaue Latzhose
	var beanie  = Color(0.82, 0.72, 0.52)   # beige/tan Cap (wie im Bild)
	var beard   = Color(0.30, 0.18, 0.08)   # Vollbart
	var stick_c = Color(0.68, 0.48, 0.22)   # Trommelstöcke
	var _wc   = sin(_anim_time * 5.0)
	var bob   = _wc * 0.8
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.6
	var arm_l = _wc * 0.6
	var drum_l = sin(_anim_time * 8.0) * 6.0
	var drum_r = sin(_anim_time * 8.0 + PI) * 6.0

	# Schuhe (breit, flach – South Park)
	draw_rect(Rect2(-14, 27 + bob + leg_l * 0.25, 13, 5), Color(0.12, 0.08, 0.04))
	draw_rect(Rect2(-1,  27 + bob + leg_r * 0.25, 13, 5), Color(0.12, 0.08, 0.04))

	# Beine (Latzhose, kurze Stubs)
	draw_rect(Rect2(-11, 14 + bob + leg_l * 0.25, 9, 14), overall)
	draw_rect(Rect2(2,   14 + bob + leg_r * 0.25, 9, 14), overall)

	# Latzhosen-Torso (flach, breit)
	draw_rect(Rect2(-13, -8 + bob, 26, 22), overall)

	# Latzhosen-Träger (Y-Form, simpel – flache Farbe)
	draw_line(Vector2(-8, -8 + bob), Vector2(-3, -24 + bob), Color(0.38, 0.50, 0.80), 3)
	draw_line(Vector2(8,  -8 + bob), Vector2(3,  -24 + bob), Color(0.38, 0.50, 0.80), 3)

	# Arme (kurze Stubs)
	draw_rect(Rect2(-21, -3 + bob + arm_l, 8, 13), overall)
	draw_rect(Rect2(13,  -3 + bob + arm_r, 8, 13), overall)

	# Mitten-Hände (SP: runde Klumpen)
	draw_circle(Vector2(-20, 9 + bob + arm_l), 6, skin)
	draw_circle(Vector2(20,  9 + bob + arm_r), 6, skin)

	# Trommelstöcke in den Händen
	draw_line(Vector2(-18, 10 + bob + arm_l), Vector2(-26, 22 + bob + arm_l + drum_l), stick_c, 3.0)
	draw_circle(Vector2(-26, 22 + bob + arm_l + drum_l), 3.5, stick_c)
	draw_line(Vector2(21,  10 + bob + arm_r), Vector2(29,  22 + bob + arm_r + drum_r), stick_c, 3.0)
	draw_circle(Vector2(29,  22 + bob + arm_r + drum_r), 3.5, stick_c)

	# Kopf (groß, rund – South Park typisch)
	draw_circle(Vector2(0, -26 + bob), 17, skin)

	# Beanie-Mütze (bedeckt obere Kopfhälfte)
	var bp = PackedVector2Array([
		Vector2(-17, -28 + bob), Vector2(-14, -36 + bob),
		Vector2(-7,  -44 + bob), Vector2(0,   -46 + bob),
		Vector2(7,   -44 + bob), Vector2(14,  -36 + bob),
		Vector2(17,  -28 + bob),
	])
	draw_colored_polygon(bp, beanie)
	draw_line(Vector2(-17, -28 + bob), Vector2(17, -28 + bob), beanie.darkened(0.3), 3)  # Bündchen

	# Vollbart (untere Gesichtshälfte)
	var bpts = PackedVector2Array([
		Vector2(-14, -20 + bob), Vector2(-17, -13 + bob),
		Vector2(-11, -8  + bob), Vector2(0,   -6 + bob),
		Vector2(11,  -8  + bob), Vector2(17,  -13 + bob),
		Vector2(14,  -20 + bob),
	])
	draw_colored_polygon(bpts, beard)

	# Augenbrauen (SP: dicke diagonale Linien, fast zusammenlaufend)
	draw_line(Vector2(-13, -33 + bob), Vector2(-3, -31 + bob), beard, 3.0)
	draw_line(Vector2(3,   -31 + bob), Vector2(13, -33 + bob), beard, 3.0)

	# Augen (nach innen geneigte Ovale – authentisch South Park)
	var tilt = 0.25; var ew = 6.0; var eh = 4.0
	var lepts = PackedVector2Array(); var repts = PackedVector2Array()
	for i in range(10):
		var a = i * TAU / 10.0; var ox = cos(a) * ew; var oy = sin(a) * eh
		lepts.append(Vector2(-7 + ox*cos(tilt) - oy*sin(tilt), -29 + bob + ox*sin(tilt) + oy*cos(tilt)))
		repts.append(Vector2(7 + ox*cos(-tilt) - oy*sin(-tilt), -29 + bob + ox*sin(-tilt) + oy*cos(-tilt)))
	draw_colored_polygon(lepts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_colored_polygon(repts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_circle(Vector2(-7, -29 + bob), 2.2, Color(0.05, 0.05, 0.05))
	draw_circle(Vector2(7,  -29 + bob), 2.2, Color(0.05, 0.05, 0.05))

	# Passive Stacks als kleine Punkte
	for i in range(passive_stacks):
		var angle = i * TAU / MAX_PASSIVE_STACKS - PI / 2.0
		draw_circle(Vector2(cos(angle), sin(angle)) * 30, 2.5, Color(1.0, 0.8, 0.2, 0.8))

func _auto_attack() -> void:
	var dir = get_direction_to_nearest_enemy()
	spawn_projectile(dir)
	if randf() < double_strike_chance:
		spawn_projectile(dir.rotated(0.12))
	emit_signal("attacked")
	AudioManager.play_hit_sfx()

func _use_ultimate() -> void:
	var sw_scene = load("res://scenes/entities/projectiles/shockwave.tscn")
	if sw_scene:
		var sw = sw_scene.instantiate()
		sw.global_position = global_position
		sw.radius = 200.0 * (1.0 + aoe_radius_bonus)
		sw.damage = get_total_damage() * 3.0
		sw.shooter = self
		if has_upgrade("distortion_pedal"):
			sw.slow_factor = 0.4
			sw.slow_duration = 3.0
		get_tree().current_scene.add_child(sw)
		for i in range(1, 3):
			var sw2 = sw_scene.instantiate()
			sw2.global_position = global_position
			sw2.radius = 200.0 * (1.0 + aoe_radius_bonus) * (1.0 + i * 0.3)
			sw2.damage = get_total_damage()
			sw2.expand_time = 0.3 + i * 0.15
			sw2.shooter = self
			get_tree().current_scene.add_child(sw2)
	AudioManager.play_ultimate_sfx()
	super._use_ultimate()

func _on_kill_passive(_enemy) -> void:
	if passive_stacks < MAX_PASSIVE_STACKS:
		passive_stacks += 1
		attack_speed_bonus += PASSIVE_ATTACK_SPEED_PER_KILL

func _draw_death() -> void:
	var t = _death_anim
	var skin    = Color(0.82, 0.62, 0.44)
	var overall = Color(0.22, 0.32, 0.60)
	var blood   = Color(0.72, 0.04, 0.04)
	var stick_c = Color(0.65, 0.45, 0.20)
	var drop = min(t * 14.0, 22.0)
	# Growing blood pool
	if t > 0.45:
		draw_circle(Vector2(0, 24), min((t - 0.45) * 32.0, 26.0), Color(blood.r, blood.g, blood.b, 0.75))
	# Body sinking
	draw_rect(Rect2(-10, 10 + drop, 9, 12), overall)
	draw_rect(Rect2(1, 10 + drop, 9, 12), overall)
	draw_rect(Rect2(-13, -6 + drop, 26, 18), overall)
	draw_rect(Rect2(-11, -8 + drop, 22, 8), skin)
	draw_line(Vector2(-13, -4 + drop), Vector2(-20, 4 + drop), skin, 6)
	draw_line(Vector2(13, -4 + drop), Vector2(20, 4 + drop), skin, 6)
	# Drumsticks flying in from both sides (arrive at t≈0.35)
	var sp = min(t / 0.35, 1.0)
	var sx = (1.0 - sp) * 85.0
	draw_line(Vector2(-sx - 18, -28 + drop), Vector2(-sx, -28 + drop), stick_c, 3)
	draw_circle(Vector2(-sx, -28 + drop), 5.0, stick_c)
	draw_line(Vector2(sx + 18, -28 + drop), Vector2(sx, -28 + drop), stick_c, 3)
	draw_circle(Vector2(sx, -28 + drop), 5.0, stick_c)
	if t < 0.45:
		# Head intact
		draw_circle(Vector2(0, -28 + drop), 12, skin)
		draw_arc(Vector2(0, -28 + drop), 12, PI, 0, 14, Color(0.25, 0.15, 0.08), 5)
		draw_circle(Vector2(-4, -30 + drop), 2.0, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(4, -30 + drop), 2.0, Color(0.1, 0.1, 0.1))
	else:
		# Head split in two halves flying apart
		var st = min((t - 0.45) * 2.0, 1.0)
		var lx = -st * 16.0
		var rx =  st * 16.0
		var fy = -st * 8.0
		draw_arc(Vector2(lx, -28 + drop + fy), 12, PI * 0.5, PI * 1.5, 10, skin, 14)
		draw_arc(Vector2(rx, -28 + drop + fy), 12, -PI * 0.5, PI * 0.5, 10, skin, 14)
		# Blood fountain from neck stump
		var fh = min(st * 48.0, 40.0)
		draw_line(Vector2(0, -16 + drop), Vector2(0, -16 + drop - fh), blood, 7)
		draw_line(Vector2(0, -16 + drop), Vector2(-9, -16 + drop - fh * 0.65), blood, 4)
		draw_line(Vector2(0, -16 + drop), Vector2(9, -16 + drop - fh * 0.65), blood, 4)
	# Blood particles
	var a = max(0.0, 1.0 - t * 0.35)
	for p in _death_ptcls:
		draw_circle(p["pos"], p["size"] * max(0.1, a), Color(p["col"].r, p["col"].g, p["col"].b, a))
