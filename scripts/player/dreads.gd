extends "res://scripts/player/player_base.gd"

# Nik - Inhale Screamer: Lange Dreadlocks bis zu den Knien, Hosentraeger, Taetowierungen
# Passive: Kann Gegner greifen & schleudern
# Ultimate: Rasta Rampage (Wirbel-AOE)

var whip_angles: Array[float] = []
var _whip_anim: float = 0.0
var _whip_active: bool = false

# Kill-Passive: Adrenalin-Schub
const KILL_SPEED_BONUS: float = 0.35   # +35% Bewegungsgeschwindigkeit
const KILL_SPEED_DURATION: float = 2.2
var _kill_speed_timer: float = 0.0

# Whip Launch Dash: trifft alle Feinde entlang des Dash-Pfads
const WHIP_LAUNCH_RADIUS: float = 36.0
var _whip_launch_origin: Vector2 = Vector2.ZERO
var _whip_launch_hit: Array = []   # Liste bereits getroffener Feinde (whitelist je Dash)

# Spinning Dread Tornado Ultimate
const TORNADO_DURATION: float = 1.5
const TORNADO_RADIUS: float = 80.0
const TORNADO_TICK: float = 0.1
const TORNADO_PULL_STRENGTH: float = 50.0
var _tornado_timer: float = 0.0
var _tornado_tick_timer: float = 0.0
var _tornado_rotation: float = 0.0

func _ready() -> void:
	character_id = "dreads"
	max_hp = 120
	move_speed = 200.0
	base_damage = 18.0
	attack_speed = 1.5
	ultimate_cooldown = 13.0
	add_to_group("players")
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	# Kill-Speed-Boost abklingen lassen
	if _kill_speed_timer > 0.0:
		_kill_speed_timer -= delta
		if _kill_speed_timer <= 0.0:
			_kill_speed_timer = 0.0
			speed_bonus -= KILL_SPEED_BONUS
	# Tornado-Visual aktualisieren
	if _tornado_timer > 0.0:
		_tornado_rotation += delta * 14.0
		queue_redraw()

func _on_kill_passive(_enemy) -> void:
	# Adrenalin-Schub: kurzer Geschwindigkeitsboost nach jedem Kill
	# Timer verlaengert sich bei mehreren Kills hintereinander
	if _kill_speed_timer <= 0.0:
		speed_bonus += KILL_SPEED_BONUS
	# Locked-In Upgrade verlaengert die Boost-Dauer um 1.5s
	var dur: float = KILL_SPEED_DURATION
	if has_upgrade("dreads_locked_in"):
		dur += 1.5
	_kill_speed_timer = dur

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	var flash     = _hit_flash > 0
	# -- South Park Stil --
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

	# Schuhe (breit, flach - South Park)
	draw_rect(Rect2(-14, 27 + bob + leg_l * 0.25, 13, 5), Color(0.12, 0.08, 0.04))
	draw_rect(Rect2(-1,  27 + bob + leg_r * 0.25, 13, 5), Color(0.12, 0.08, 0.04))

	# Beine (Jeans-Shorts)
	draw_rect(Rect2(-11, 14 + bob + leg_l * 0.25, 9, 14), denim)
	draw_rect(Rect2(2,   14 + bob + leg_r * 0.25, 9, 14), denim)

	# Tank-Top Torso
	draw_rect(Rect2(-11, -8 + bob, 22, 22), tank)

	# Hosentraeger (2 diagonale Linien)
	draw_line(Vector2(-7, 14 + bob), Vector2(-4, -8 + bob), suspender, 3)
	draw_line(Vector2(7,  14 + bob), Vector2(4,  -8 + bob), suspender, 3)

	# Arme (South Park Stubs, Haut sichtbar)
	draw_rect(Rect2(-19, -3 + bob + arm_l, 8, 13), skin)
	draw_rect(Rect2(11,  -3 + bob + arm_r, 8, 13), skin)

	# Mitten-Haende (SP: runde Klumpen)
	draw_circle(Vector2(-18, 9 + bob + arm_l), 6, skin)
	draw_circle(Vector2(18,  9 + bob + arm_r), 6, skin)

	# Kopf
	draw_circle(Vector2(0, -24 + bob), 16, skin)

	# Kurzer Bart
	draw_arc(Vector2(0, -19 + bob), 7, 0.15, PI - 0.15, 8, dread_col, 3)

	# Augenbrauen (SP: dicke diagonale Linien)
	draw_line(Vector2(-12, -30 + bob), Vector2(-3, -28 + bob), dread_col, 3.0)
	draw_line(Vector2(3,   -28 + bob), Vector2(12, -30 + bob), dread_col, 3.0)

	# Augen (nach innen geneigte Ovale - authentisch South Park)
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

	# DREADLOCKS - dicke Straenge die weit nach unten haengen (ikonisch South Park)
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
		for wa in whip_angles:
			var whip_end = Vector2(cos(wa), sin(wa)) * (180.0 * _whip_anim)
			draw_line(Vector2.ZERO, whip_end, dread_col, 4.0)
			draw_circle(whip_end, 5.0, Color(1.0, 0.8, 0.2))

	# Spinning Dread Tornado Visualisierung
	if _tornado_timer > 0.0:
		var radius: float = TORNADO_RADIUS * (1.0 + aoe_radius_bonus)
		var fade: float = clamp(_tornado_timer / TORNADO_DURATION, 0.0, 1.0)
		# Rotierende Dread-Linien wie ein Wirbel
		var lines: int = 12
		for i in range(lines):
			var base_a: float = float(i) / float(lines) * TAU + _tornado_rotation
			# Spiralfoermige Linie: vom Zentrum nach aussen mit Schwung
			var pts2: PackedVector2Array = PackedVector2Array()
			var steps: int = 8
			for s in range(steps + 1):
				var t_norm: float = float(s) / float(steps)
				var spiral_angle: float = base_a + t_norm * 1.2
				var r: float = radius * t_norm
				pts2.append(Vector2(cos(spiral_angle), sin(spiral_angle)) * r)
			if pts2.size() > 1:
				draw_polyline(pts2, Color(dread_col.r, dread_col.g, dread_col.b, 0.65 * fade), 3.0)
		# Schwacher Aura-Ring
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.8, 0.2, 0.25 * fade), 2.0)

	# Level-Up Text Overlay
	_draw_levelup_text()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _whip_active:
		_whip_anim += delta * 5.0
		if _whip_anim >= 1.0:
			_whip_active = false
			_whip_anim = 0.0
	# Tornado-Ultimate: Damage-Ticks & Pull
	if _tornado_timer > 0.0:
		_tornado_timer -= delta
		_tornado_tick_timer -= delta
		if _tornado_tick_timer <= 0.0:
			_tornado_tick_timer = TORNADO_TICK
			var radius: float = TORNADO_RADIUS * (1.0 + aoe_radius_bonus)
			var dmg: float = get_total_damage() * 0.5
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if not is_instance_valid(e):
					continue
				var to_e: Vector2 = e.global_position - global_position
				var dist: float = to_e.length()
				if dist < radius and dist > 1.0:
					if e.has_method("take_damage"):
						e.take_damage(dmg, self)
					# Sanftes Einsaugen
					e.global_position -= to_e.normalized() * TORNADO_PULL_STRENGTH * TORNADO_TICK

func _on_dash_start() -> void:
	# Whip Launch: Initialisiere Hit-Tracking fuer Dash-Pfad
	_whip_launch_origin = global_position
	_whip_launch_hit.clear()

func _on_dash_tick(_delta: float) -> void:
	# Damage entlang des Dash-Pfads (Distanz-Check zu allen Feinden)
	var dmg: float = get_total_damage() * 1.4
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e) or e in _whip_launch_hit:
			continue
		# Check Distanz zum aktuellen Standort
		if global_position.distance_to(e.global_position) < WHIP_LAUNCH_RADIUS:
			_whip_launch_hit.append(e)
			if e.has_method("take_damage"):
				e.take_damage(dmg, self)
			if e.has_method("apply_knockback"):
				var kb_dir: Vector2 = _dash_dir if _dash_dir != Vector2.ZERO else Vector2.RIGHT
				e.apply_knockback(kb_dir * 380.0)

func _auto_attack() -> void:
	whip_angles.clear()
	# Balancing Run #11: Peitsche traf vorher ALLE Gegner im 320er-Radius mit
	# vollem Schaden (+114% ueber dem DPS-Median in Welle 15). Jetzt: maximal
	# 4 Ziele pro Schlag, naechste zuerst, Radius 260.
	var in_range: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			var to_e = e.global_position - global_position
			if to_e.length() < 260.0:
				in_range.append({"e": e, "d": to_e.length_squared(), "v": to_e})
	in_range.sort_custom(func(a, b): return a["d"] < b["d"])
	var hits: int = 0
	for item in in_range:
		if hits >= 4:
			break
		var e = item["e"]
		var to_e: Vector2 = item["v"]
		e.take_damage(get_total_damage(), self)
		whip_angles.append(to_e.angle())
		hits += 1
		# Passive: 25% Chance auf Grab-and-Throw statt normalen Knockback
		if randf() < 0.25:
			_grab_and_throw(e, to_e)
		elif randf() < 0.3:
			e.apply_knockback(to_e.normalized().rotated(PI / 2.0) * 300.0)
	if not whip_angles.is_empty():
		_whip_active = true
		_whip_anim = 0.0
	if randf() < double_strike_chance:
		spawn_projectile(get_direction_to_nearest_enemy())
	emit_signal("attacked")

# Signature: Headbang Cyclone - dauerhafter Dread-Wirbel im Nahbereich, der
# alle Feinde ringsum trifft und wegschleudert. Kein gezieltes Greifen mehr.
func _auto_attack_signature() -> void:
	whip_angles.clear()
	var radius: float = 145.0 * (1.0 + aoe_radius_bonus)
	var dmg: float = get_total_damage() * 0.55
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var to_e: Vector2 = e.global_position - global_position
		var dist: float = to_e.length()
		if dist < radius and dist > 1.0:
			if e.has_method("take_damage"):
				e.take_damage(dmg, self)
			whip_angles.append(to_e.angle())
			if e.has_method("apply_knockback"):
				e.apply_knockback(to_e.normalized() * 180.0)
	if not whip_angles.is_empty():
		_whip_active = true
		_whip_anim = 0.0
	emit_signal("attacked")

func _grab_and_throw(enemy, to_enemy: Vector2) -> void:
	# Halte den Gegner kurz fest (Slow mit factor 0.0 = volle Bewegungssperre)
	if enemy.has_method("apply_slow"):
		enemy.apply_slow(0.0, 0.4)
	# Nach 0.4s: in zufaellige Richtung schleudern, aber nicht zum Spieler hin
	get_tree().create_timer(0.4).timeout.connect(func():
		if not is_instance_valid(enemy):
			return
		# Richtung weg vom Spieler als Basis, plus zufaellige Streuung
		var away = (enemy.global_position - global_position)
		if away.length() < 0.01:
			away = to_enemy
		var base_angle = away.angle()
		# +/- 60 Grad Streuung um die "weg vom Spieler"-Richtung
		var throw_angle = base_angle + randf_range(-PI / 3.0, PI / 3.0)
		var throw_dir = Vector2(cos(throw_angle), sin(throw_angle))
		var throw_force = 650.0
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(throw_dir * throw_force)
		# Visuelles Feedback: gelber Flash
		if "_hit_flash" in enemy:
			enemy._hit_flash = 0.3
	)

func _use_ultimate() -> void:
	# Spinning Dread Tornado: 1.5s schneller AOE-Damage + Einsaugen
	_tornado_timer = TORNADO_DURATION
	_tornado_tick_timer = 0.0
	_tornado_rotation = 0.0
	# distortion_pedal: Slow-Shockwave als Bonus
	if has_upgrade("distortion_pedal"):
		var sw = _SW_SCENE.instantiate()
		sw.global_position = global_position
		sw.radius = 160.0 * (1.0 + aoe_radius_bonus)
		sw.damage = 0.0
		sw.slow_factor = 0.4
		sw.slow_duration = 3.0
		sw.shooter = self
		get_tree().current_scene.add_child(sw)
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
		# Neck stretching - head pulled upward by dreads
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
		# Head ripped off - flying upward, blood fountain
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
