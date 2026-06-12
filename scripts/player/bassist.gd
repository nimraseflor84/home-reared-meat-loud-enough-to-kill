extends "res://scripts/player/player_base.gd"

# Bassist: Groesster, wildeste Haare, Flanellhemd offen, langer Bart (Mitte im Foto)
# Passive: Bodenwellen bei Kills
# Ultimate: Sub Bass Nuke (3 expandierende Schockwellen-Ringe)

# Bass Drop Dash
const BASS_DROP_RADIUS: float = 70.0
const BASS_DROP_KNOCKBACK: float = 480.0

# Sub Bass Nuke Ultimate
const NUKE_RING_COUNT: int = 3
const NUKE_DURATION: float = 1.5
const NUKE_BASE_RADIUS: float = 120.0
const NUKE_RING_GAP: float = 100.0

func _ready() -> void:
	character_id = "bassist"
	max_hp = 120
	move_speed = 160.0
	base_damage = 22.0
	attack_speed = 0.9
	# Sub Bass Nuke: 10s Cooldown laut Spec
	ultimate_cooldown = 10.0
	add_to_group("players")
	super._ready()

func _on_dash_start() -> void:
	# Bass Drop: am Ende des Dashs (also kurz danach, via Timer) eine Schockwelle
	# legen. Wir nutzen einen kleinen Delay damit der Slam visuell mit dem Dash
	# zusammenpasst. Knockback geht radial nach aussen.
	get_tree().create_timer(_DASH_DURATION * 0.6).timeout.connect(func():
		if not is_instance_valid(self) or not is_alive:
			return
		var radius: float = BASS_DROP_RADIUS * (1.0 + aoe_radius_bonus)
		var dmg: float = get_total_damage() * 1.6
		# Visuelle Schockwelle
		var sw = _SW_SCENE.instantiate()
		sw.global_position = global_position
		sw.radius = radius
		sw.damage = dmg
		sw.shooter = self
		if has_upgrade("distortion_pedal"):
			sw.slow_factor = 0.4
			sw.slow_duration = 3.0
		get_tree().current_scene.add_child(sw)
		# Manueller Knockback der Feinde im Radius (zusaetzlich zur Schockwelle)
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var to_e: Vector2 = e.global_position - global_position
			if to_e.length() < radius and to_e.length() > 0.5:
				if e.has_method("apply_knockback"):
					e.apply_knockback(to_e.normalized() * BASS_DROP_KNOCKBACK)
		_request_screen_shake(4.0, 0.18)
	)

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	var flash   = _hit_flash > 0
	# -- Chicken - Kappe, Sonnenbrille, rotes Flanellhemd --
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

	# Schuhe (breit, flach - South Park)
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

	# Haende
	draw_circle(Vector2(-21, 10 + bob + arm_l), 7, skin)
	draw_circle(Vector2(21,  10 + bob + arm_r), 7, skin)

	# Kopf
	draw_circle(Vector2(0, -26 + bob), 18, skin)

	# Breiter dunkler Hut (Wide-Brim)
	draw_rect(Rect2(-24, -40 + bob, 48, 6), cap_col)   # Krempe
	draw_rect(Rect2(-12, -58 + bob, 24, 20), cap_col)  # Krone
	draw_rect(Rect2(-13, -40 + bob, 26, 4), cap_col.darkened(0.2))  # Krempen-Uebergang

	# Kinn-Bart (kurzer Vollbart)
	var bpts = PackedVector2Array([
		Vector2(-12, -18 + bob), Vector2(-14, -10 + bob),
		Vector2(-8,  -4  + bob), Vector2(0,   -2  + bob),
		Vector2(8,   -4  + bob), Vector2(14,  -10 + bob),
		Vector2(12,  -18 + bob),
	])
	draw_colored_polygon(bpts, beard)

	# Mund (leicht offen - neutral)
	draw_arc(Vector2(0, -20 + bob), 5, 0.2, PI - 0.2, 6, Color(0.12, 0.04, 0.04), 6)

	# Augenbrauen
	draw_line(Vector2(-14, -36 + bob), Vector2(-4, -34 + bob), beard, 3.5)
	draw_line(Vector2(4,   -34 + bob), Vector2(14, -36 + bob), beard, 3.5)

	# Sonnenbrille (zwei ovale Glaeser + Steg)
	draw_circle(Vector2(-8, -30 + bob), 7, glass_c)
	draw_circle(Vector2(8,  -30 + bob), 7, glass_c)
	draw_line(Vector2(-1, -30 + bob), Vector2(1, -30 + bob), glass_c.lightened(0.2), 2)
	draw_line(Vector2(-15, -30 + bob), Vector2(-15, -26 + bob), glass_c.lightened(0.1), 2)
	draw_line(Vector2(15,  -30 + bob), Vector2(15,  -26 + bob), glass_c.lightened(0.1), 2)

	# Level-Up Text Overlay
	_draw_levelup_text()

# Low End Theory: every 4th hit fires an extra mini shockwave
var _low_end_counter: int = 0

func _auto_attack() -> void:
	var dir = get_direction_to_nearest_enemy()
	spawn_projectile(dir, get_total_damage() * 1.2, 350.0)
	for angle in [-0.3, 0.3]:
		spawn_projectile(dir.rotated(angle), get_total_damage() * 0.7, 300.0)
	if randf() < double_strike_chance:
		spawn_projectile(dir)
	# Low End Theory: kleine Schockwelle alle 4 Treffer
	if has_upgrade("bassist_low_end_theory"):
		_low_end_counter += 1
		if _low_end_counter >= 4:
			_low_end_counter = 0
			spawn_shockwave(55.0 * (1.0 + aoe_radius_bonus), get_total_damage() * 0.6)
	emit_signal("attacked")

func _on_kill_passive(_enemy) -> void:
	# Sub Frequency Upgrade: aoe_radius_bonus wurde schon global durch
	# apply_upgrade angewendet (0.40) - hier nur den Schadensteil hinzufuegen.
	var dmg_bonus: float = 1.0
	if has_upgrade("bassist_sub_frequency"):
		dmg_bonus = 1.25
	spawn_shockwave(70.0 * (1.0 + aoe_radius_bonus), get_total_damage() * 1.5 * dmg_bonus)

func _use_ultimate() -> void:
	# Sub Bass Nuke: 3 expandierende konzentrische Schockwellen ueber 1.5s
	# Jede Welle macht schweren Schaden + massiven Knockback (radial)
	var ult_damage: float = get_total_damage() * 4.0
	if has_upgrade("power_chord"):
		ult_damage *= 1.4
	# Verzoegerungen so dass alle Wellen ueber NUKE_DURATION verteilt starten
	# Welle 0 startet sofort, Welle 1 nach 0.5s, Welle 2 nach 1.0s
	for ring_idx in range(NUKE_RING_COUNT):
		var delay: float = float(ring_idx) * (NUKE_DURATION / float(NUKE_RING_COUNT))
		var ring_radius: float = (NUKE_BASE_RADIUS + float(ring_idx) * NUKE_RING_GAP) * (1.0 + aoe_radius_bonus)
		if delay <= 0.0:
			_spawn_nuke_ring(ring_radius, ult_damage)
		else:
			get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(self) and is_alive:
					_spawn_nuke_ring(ring_radius, ult_damage)
			)
	# Screen Shake 0.6s laut Spec
	_request_screen_shake(12.0, 0.6)
	AudioManager.play_ultimate_sfx()
	super._use_ultimate()

func _spawn_nuke_ring(radius: float, dmg: float) -> void:
	var sw = _SW_SCENE.instantiate()
	sw.global_position = global_position
	sw.radius = radius
	sw.damage = dmg
	sw.expand_time = 0.4
	sw.shooter = self
	if has_upgrade("distortion_pedal"):
		sw.slow_factor = 0.4
		sw.slow_duration = 3.0
	get_tree().current_scene.add_child(sw)
	# Massiver Knockback fuer jeden Feind innerhalb dieses Radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var to_e: Vector2 = e.global_position - global_position
		if to_e.length() < radius and to_e.length() > 0.5:
			if e.has_method("apply_knockback"):
				e.apply_knockback(to_e.normalized() * 620.0)

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
		# EXPLOSION - body chunks fly outward
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
		# Aftermath - scattered chunks, blood pool, bass string shrapnel
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
