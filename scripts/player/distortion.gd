extends "res://scripts/player/player_base.gd"

# Distortion: Kariertes Shirt, mittelgross, ordentlichere Haare (5. von links im Foto)
# Passive: Verlangsamt Gegner im Aura
# Ultimate: Wall of Noise (Sound-Barriere-Explosion)

const SLOW_RADIUS = 120.0
const SLOW_FACTOR = 0.5

# Phase Shift Dash: intangibel waehrend des Dashs
var _phase_collision_layer: int = -1
var _phase_collision_mask: int = -1
var _phase_dmg_reduction_saved: float = -1.0   # -1 = inaktiv, sonst gespeicherter Wert

# Feedback Loop Ultimate
const FEEDBACK_MAX_RADIUS: float = 300.0
const FEEDBACK_DURATION: float = 1.0
const FEEDBACK_SLOW_FACTOR: float = 0.4   # 60% slow = factor 0.4
const FEEDBACK_SLOW_DURATION: float = 3.0
var _feedback_timer: float = 0.0
var _feedback_hit: Array = []

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
	# Der super-Early-Return schuetzt den Subclass-Code nicht: ohne diesen Guard
	# slowte ein toter Distortion dauerhaft alle Gegner weiter (Audit Run #11)
	if not is_alive or _is_remote:
		return
	_apply_slow_aura()
	# Phase Shift: Collision + Damage-Reduction wiederherstellen sobald Dash vorbei
	if _phase_collision_layer >= 0 and _dash_timer <= 0.0:
		collision_layer = _phase_collision_layer
		collision_mask  = _phase_collision_mask
		_phase_collision_layer = -1
		_phase_collision_mask  = -1
		if _phase_dmg_reduction_saved >= 0.0:
			damage_reduction = _phase_dmg_reduction_saved
			_phase_dmg_reduction_saved = -1.0
	# Feedback Loop Ring expandieren + Feinde durch den Ring slowen
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		var t_progress: float = 1.0 - (_feedback_timer / FEEDBACK_DURATION)
		var current_radius: float = FEEDBACK_MAX_RADIUS * t_progress
		var prev_radius: float = FEEDBACK_MAX_RADIUS * max(0.0, t_progress - delta / FEEDBACK_DURATION)
		var ult_damage: float = get_total_damage() * 1.2
		if has_upgrade("power_chord"):
			ult_damage *= 1.4
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if not is_instance_valid(e) or e in _feedback_hit:
				continue
			var dist: float = global_position.distance_to(e.global_position)
			# Wenn dieser Tick die Ringkante den Feind passiert hat
			if dist >= prev_radius and dist <= current_radius:
				_feedback_hit.append(e)
				if e.has_method("apply_slow"):
					e.apply_slow(FEEDBACK_SLOW_FACTOR, FEEDBACK_SLOW_DURATION)
				if e.has_method("take_damage"):
					e.take_damage(ult_damage, self)
		queue_redraw()
		if _feedback_timer <= 0.0:
			_feedback_hit.clear()

func _on_dash_start() -> void:
	# Phase Shift: intangibel waehrend des Dashs - Collision + Damage-Reduction
	if _phase_collision_layer < 0:
		_phase_collision_layer = collision_layer
		_phase_collision_mask  = collision_mask
		collision_layer = 0
		collision_mask  = 0
		# 100% Damage-Reduction = unverwundbar (rein logisch ueber take_damage)
		_phase_dmg_reduction_saved = damage_reduction
		damage_reduction = 1.0

var _overdrive_tick: float = 0.0

func _apply_slow_aura() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var field_bonus: float = 0.0
	var slow_factor: float = SLOW_FACTOR
	if has_upgrade("distortion_feedback_field"):
		field_bonus = 0.30
		slow_factor = 0.35  # haerterer Slow (statt 0.5 -> 0.35)
	var radius = SLOW_RADIUS * (1.0 + aoe_radius_bonus + field_bonus)
	# Overdrive Amp: slowed enemies in our field also take continuous tick damage
	_overdrive_tick -= get_physics_process_delta_time()
	var tick_damage: float = 0.0
	if has_upgrade("distortion_overdrive_amp") and _overdrive_tick <= 0.0:
		_overdrive_tick = 0.4
		tick_damage = get_total_damage() * 0.25
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= radius:
			if e.has_method("apply_slow"):
				e.apply_slow(slow_factor, 0.2)
			if tick_damage > 0.0 and e.has_method("take_damage"):
				e.take_damage(tick_damage, self)

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	var flash  = _hit_flash > 0
	# -- South Park Stil --
	var skin    = Color(0.96, 0.80, 0.64) if not flash else Color(1, 1, 1)
	var overall = Color(0.22, 0.38, 0.68)   # Latzhose denim blau
	var ov_dark = Color(0.16, 0.28, 0.52)
	var green   = Color(0.22, 0.55, 0.22)   # gruenes Karohemd
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

	# Feedback Loop Ultimate: expandierender Ring mit Alpha-Decay
	if _feedback_timer > 0.0:
		var t_progress: float = 1.0 - (_feedback_timer / FEEDBACK_DURATION)
		var radius: float = FEEDBACK_MAX_RADIUS * t_progress
		# Alpha-Decay: am Anfang voll, am Ende ausgefadet
		var alpha: float = 0.85 * (1.0 - t_progress)
		var col_ring = Color(0.7, 0.2, 1.0, alpha)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, col_ring, 6.0)
		# Innerer Echo-Ring (etwas kleiner)
		var inner_r: float = radius * 0.85
		if inner_r > 5.0:
			draw_arc(Vector2.ZERO, inner_r, 0.0, TAU, 48, Color(0.95, 0.7, 1.0, alpha * 0.5), 3.0)
		# Dezenter ausgefuellter Bereich
		draw_circle(Vector2.ZERO, radius, Color(0.7, 0.2, 1.0, alpha * 0.08))

	# Phase Shift: ghosty Anzeige waehrend Dashs (Wellenlinien-Aura)
	if _phase_collision_layer >= 0:
		for i in range(3):
			var ph_r: float = 22.0 + float(i) * 8.0 + sin(_anim_time * 18.0 + float(i)) * 3.0
			draw_arc(Vector2.ZERO, ph_r, 0.0, TAU, 24, Color(0.7, 0.4, 1.0, 0.5 - float(i) * 0.12), 2.0)

	# Schuhe (breit, flach - South Park)
	draw_rect(Rect2(-14, 27 + bob + leg_l * 0.25, 13, 5), Color(0.12, 0.08, 0.04))
	draw_rect(Rect2(-1,  27 + bob + leg_r * 0.25, 13, 5), Color(0.12, 0.08, 0.04))

	# Beine (Latzhose denim)
	draw_rect(Rect2(-11, 14 + bob + leg_l * 0.25, 9, 14), overall)
	draw_rect(Rect2(2,   14 + bob + leg_r * 0.25, 9, 14), overall)

	# Arme (gruenes Karohemd - unter Latzhose sichtbar)
	draw_rect(Rect2(-20, -3 + bob + arm_l, 8, 13), green)
	for y_off in [-1, 4, 9]:
		draw_line(Vector2(-20, y_off + bob + arm_l), Vector2(-12, y_off + bob + arm_l), g_dark, 1.0)
	draw_rect(Rect2(12,  -3 + bob + arm_r, 8, 13), green)
	for y_off in [-1, 4, 9]:
		draw_line(Vector2(12, y_off + bob + arm_r), Vector2(20, y_off + bob + arm_r), g_dark, 1.0)

	# Latzhosen-Torso (Brust-Latz, bedeckt das gruene Hemd)
	draw_rect(Rect2(-12, -8 + bob, 24, 22), overall)

	# Latzhosen-Traeger (Y-Form)
	draw_line(Vector2(-8, -8 + bob), Vector2(-3, -24 + bob), ov_dark, 3)
	draw_line(Vector2(8,  -8 + bob), Vector2(3,  -24 + bob), ov_dark, 3)

	# Mitten-Haende (SP: runde Klumpen)
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

	# Level-Up Text Overlay
	_draw_levelup_text()

func _auto_attack() -> void:
	var dir = get_direction_to_nearest_enemy()
	spawn_projectile(dir, -1, 380.0)
	spawn_projectile(dir.rotated(PI / 4.0),  get_total_damage() * 0.6, 300.0)
	spawn_projectile(dir.rotated(-PI / 4.0), get_total_damage() * 0.6, 300.0)
	if randf() < double_strike_chance:
		spawn_projectile(dir.rotated(PI / 2.0))
	emit_signal("attacked")

# Signature: Feedback Drone - dauerhafte Verzerrungs-Aura um den Spieler, die
# Feinde ringsum verlangsamt und tickt. Kaum Reichweite, reine Kontrolle/Tank.
func _auto_attack_signature() -> void:
	var radius: float = 170.0 * (1.0 + aoe_radius_bonus)
	var dmg: float = get_total_damage() * 0.4
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) < radius:
			if e.has_method("take_damage"):
				e.take_damage(dmg, self)
			if e.has_method("apply_slow"):
				e.apply_slow(0.55, 0.6)
	# Sichtbare Aura-Pulse (Schaden 0, synchron zum Angriffstakt)
	var sw = _SW_SCENE.instantiate()
	sw.global_position = global_position
	sw.radius = radius
	sw.damage = 0.0
	sw.shooter = self
	if sw.has_method("set"):
		sw.set("expand_time", 0.25)
	get_tree().current_scene.add_child(sw)
	emit_signal("attacked")

func _on_kill_passive(enemy) -> void:
	# Distortion Field: Kill verlangsamt alle Feinde im Nahbereich der Todesposition
	if not is_instance_valid(enemy):
		return
	var kill_pos: Vector2 = enemy.global_position
	var nearby = get_tree().get_nodes_in_group("enemies")
	for e in nearby:
		if is_instance_valid(e) and e.has_method("apply_slow"):
			if e.global_position.distance_to(kill_pos) < 100.0:
				e.apply_slow(0.45, 2.5)  # 55% langsamer fuer 2.5s

func _use_ultimate() -> void:
	# Feedback Loop: expandierender Distortion-Ring slowt ALLE Feinde die er passiert
	_feedback_timer = FEEDBACK_DURATION
	_feedback_hit.clear()
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
