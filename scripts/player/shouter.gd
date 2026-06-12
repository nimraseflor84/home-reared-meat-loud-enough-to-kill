extends "res://scripts/player/player_base.gd"

# Chicken - Saenger: Kappe, Sonnenbrille, kariertes Shirt
# Passive: Gezielte Schallstrahlen, hohe Reichweite
# Ultimate: Feedback Collapse (Giant Soundburst)

const BEAM_RANGE = 600.0

# Sonic Burst Teleport-Dash
const TELEPORT_DISTANCE: float = 120.0
const TELEPORT_FLASH_DURATION: float = 0.25
var _tp_origin: Vector2 = Vector2.ZERO
var _tp_dest: Vector2 = Vector2.ZERO
var _tp_flash_timer: float = 0.0

# Death Scream Ultimate
const SCREAM_RANGE: float = 420.0
const SCREAM_ARC: float = PI    # 180 Grad Kegel
var _scream_timer: float = 0.0
var _scream_dir: Vector2 = Vector2.RIGHT

# The Brown Note Upgrade: every 3rd shout is a crit
var _brown_note_counter: int = 0

func _ready() -> void:
	character_id = "shouter"
	max_hp = 90
	move_speed = 190.0
	base_damage = 28.0
	attack_speed = 0.9
	# Death Scream Ultimate: 8s Cooldown laut Spec
	ultimate_cooldown = 8.0
	add_to_group("players")
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if _tp_flash_timer > 0.0:
		_tp_flash_timer -= delta
		queue_redraw()
	if _scream_timer > 0.0:
		_scream_timer -= delta
		queue_redraw()

func _on_dash_start() -> void:
	# Sonic Burst: instant teleport 120px in Dash-Richtung
	# Unterbinde die normale Dash-Geschwindigkeit
	_tp_origin = global_position
	var target: Vector2 = global_position + _dash_dir * TELEPORT_DISTANCE
	var vp = get_viewport_rect().size
	target.x = clamp(target.x, 32.0, vp.x - 32.0)
	target.y = clamp(target.y, 32.0, vp.y - 32.0)
	global_position = target
	_tp_dest = global_position
	_tp_flash_timer = TELEPORT_FLASH_DURATION
	# Deaktiviere reisende Dash-Velocity (Teleport ist instant)
	_dash_timer = 0.0

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	# Sonic Burst: weisser Flash am Ursprung und Ziel
	if _tp_flash_timer > 0.0:
		var fa: float = clamp(_tp_flash_timer / TELEPORT_FLASH_DURATION, 0.0, 1.0)
		var origin_offset: Vector2 = _tp_origin - global_position
		var col_flash = Color(1.0, 1.0, 1.0, fa * 0.85)
		# Origin-Flash: groesserer halbtransparenter Kreis + dunner Ring
		draw_circle(origin_offset, 22.0 * (1.0 - fa) + 10.0, col_flash)
		draw_arc(origin_offset, 28.0, 0.0, TAU, 24, Color(1.0, 0.8, 0.4, fa), 2.5)
		# Dest-Flash am aktuellen Standort
		draw_circle(Vector2.ZERO, 18.0 * (1.0 - fa) + 8.0, col_flash)
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 24, Color(1.0, 0.8, 0.4, fa), 2.5)
	# Death Scream Cone Visualisierung
	if _scream_timer > 0.0:
		var sa: float = clamp(_scream_timer / 0.55, 0.0, 1.0)
		var cone_range: float = SCREAM_RANGE * (1.0 + aoe_radius_bonus)
		var ang: float = _scream_dir.angle()
		var col_scream = Color(1.0, 0.25, 0.15, 0.18 + 0.25 * sa)
		# 180-Grad-Sektor als Polygon
		var pts: PackedVector2Array = PackedVector2Array()
		pts.append(Vector2.ZERO)
		var segs: int = 24
		for i in range(segs + 1):
			var a: float = ang - PI * 0.5 + float(i) / float(segs) * PI
			pts.append(Vector2(cos(a), sin(a)) * cone_range)
		draw_colored_polygon(pts, col_scream)
		# Drei pulsierende Schallwellen-Arcs
		for i in range(3):
			var pulse: float = clamp((1.0 - sa) - float(i) * 0.15, 0.0, 1.0)
			var r: float = pulse * cone_range
			draw_arc(Vector2.ZERO, r, ang - PI * 0.5, ang + PI * 0.5, 24, Color(1.0, 0.5, 0.2, 0.6 * sa), 3.0)
	var flash   = _hit_flash > 0
	# -- South Park Stil (Armin-Design: goldene Haare, Schrei-Mund) --
	var skin    = Color(0.98, 0.82, 0.66) if not flash else Color(1, 1, 1)
	var flannel = Color(0.58, 0.22, 0.12)   # rotes Flanellhemd
	var f_dark  = Color(0.08, 0.04, 0.04)   # schwarz fuer rot-schwarzes Plaid
	var denim   = Color(0.28, 0.38, 0.58)
	var beard   = Color(0.32, 0.22, 0.10)
	var _wc   = sin(_anim_time * 5.0)
	var bob   = _wc * 0.8
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.6
	var arm_l = _wc * 0.6

	# Schuhe (breit, flach - South Park)
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

	# Arme (kraeftige Stubs)
	draw_rect(Rect2(-22, -4 + bob + arm_l, 8, 15), flannel)
	draw_rect(Rect2(14,  -4 + bob + arm_r, 8, 15), flannel)

	# Mitten-Haende (SP: runde Klumpen)
	draw_circle(Vector2(-21, 10 + bob + arm_l), 7, skin)
	draw_circle(Vector2(21,  10 + bob + arm_r), 7, skin)

	# Kopf (gross)
	draw_circle(Vector2(0, -26 + bob), 18, skin)

	# Lange goldene Haare (bis zu den Knien - ikonisch)
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

	# Level-Up Text Overlay
	_draw_levelup_text()

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
		# Brown Note: every third shout deals 2x damage
		var dmg: float = -1.0
		if has_upgrade("shouter_brown_note"):
			_brown_note_counter += 1
			if _brown_note_counter >= 3:
				_brown_note_counter = 0
				dmg = get_total_damage() * 2.0
		spawn_projectile(dir, dmg, 550.0)
		if randf() < double_strike_chance:
			spawn_projectile(dir)
	emit_signal("attacked")

func _on_kill_passive(_enemy) -> void:
	# Precision Focus: Kill setzt den Angriffs-Timer zurueck -> sofortiger naechster Schuss
	# Belohnt praezises Spielen mit unmittelbarem Feedback
	attack_timer = attack_speed * (1.0 + attack_speed_bonus) * 0.85

func _use_ultimate() -> void:
	# Death Scream: 180-Grad-Schallkegel der ALLEN Feinden in Reichweite Schaden tut
	var ult_damage: float = get_total_damage() * 4.5
	if has_upgrade("power_chord"):
		ult_damage *= 1.4
	_scream_dir = _dash_dir
	if _scream_dir == Vector2.ZERO:
		_scream_dir = Vector2.RIGHT
	_scream_timer = 0.55
	var cone_range: float = SCREAM_RANGE * (1.0 + aoe_radius_bonus)
	var half_arc: float = SCREAM_ARC * 0.5
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var to_e: Vector2 = e.global_position - global_position
		var dist: float = to_e.length()
		if dist > cone_range or dist < 1.0:
			continue
		# Winkel pruefen
		var dot_val: float = to_e.normalized().dot(_scream_dir)
		var angle: float = acos(clamp(dot_val, -1.0, 1.0))
		if angle <= half_arc:
			if e.has_method("take_damage"):
				e.take_damage(ult_damage, self)
			if e.has_method("apply_knockback"):
				e.apply_knockback(to_e.normalized() * 360.0)
	# distortion_pedal: Slow-Shockwave als Bonus
	if has_upgrade("distortion_pedal"):
		var sw = _SW_SCENE.instantiate()
		sw.global_position = global_position
		sw.radius = 200.0 * (1.0 + aoe_radius_bonus)
		sw.damage = 0.0
		sw.slow_factor = 0.4
		sw.slow_duration = 3.0
		sw.shooter = self
		get_tree().current_scene.add_child(sw)
	# Screen-Flash + Camera Shake
	_request_screen_shake(7.0, 0.4)
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
