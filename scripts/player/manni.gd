extends "res://scripts/player/player_base.gd"

# Manni: Staemmig, Latzhose, kurze Haare, dicker Bart
# Passive: Kills erhoehen Angriffstempo
# Ultimate: Double Bass Inferno (360deg Shockwave)

const PASSIVE_ATTACK_SPEED_PER_KILL = 0.03
const MAX_PASSIVE_STACKS = 10
var passive_stacks: int = 0

# Drum Roll Dash: 3 schnelle kurze Spruenge mit Afterimages
const DRUM_HOP_DISTANCE: float = 70.0
const DRUM_HOP_INTERVAL: float = 0.06   # Zeit zwischen den Spruengen
const DRUM_HOPS_TOTAL: int = 2          # zusaetzliche Spruenge nach dem ersten Dash
var _drum_hops_remaining: int = 0
var _drum_hop_timer: float = 0.0
var _afterimages: Array = []  # {pos: Vector2, age: float}

# Blast Beat Frenzy Ultimate
const FRENZY_DURATION: float = 3.0
const FRENZY_ATK_SPEED_MULT: float = 3.0
const FRENZY_KNOCKBACK_CHANCE: float = 0.30
var _frenzy_timer: float = 0.0
var _frenzy_flash: float = 0.0

func _ready() -> void:
	character_id = "manni"
	max_hp = 110
	move_speed = 185.0
	# 22 -> 27: Manni war als Default-Charakter 42% unter dem DPS-Median
	# (Balancing-Simulation Run #11)
	base_damage = 27.0
	attack_speed = 1.2
	ultimate_cooldown = 12.0
	add_to_group("players")
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	# Afterimages altern lassen
	if not _afterimages.is_empty():
		for ai in _afterimages:
			ai["age"] += delta
		# Alte entfernen
		var i: int = _afterimages.size() - 1
		while i >= 0:
			if _afterimages[i]["age"] >= 0.35:
				_afterimages.remove_at(i)
			i -= 1
		queue_redraw()
	# Frenzy-Flash modulate
	if _frenzy_timer > 0.0:
		_frenzy_timer -= delta
		_frenzy_flash += delta
		# Rapides Flackern zwischen Rot/Gelb
		var phase: float = sin(_frenzy_flash * 30.0)
		if phase > 0.0:
			modulate = Color(1.0, 0.85, 0.2, 1.0)
		else:
			modulate = Color(1.0, 0.25, 0.15, 1.0)
		if _frenzy_timer <= 0.0:
			_frenzy_timer = 0.0
			# Frenzy-Boost zurueckdrehen: x = bonus_before, bonus_after = bonus_before + 2*(1+bonus_before) -> bonus_before = (bonus_after - 2) / 3
			attack_speed_bonus = (attack_speed_bonus - (FRENZY_ATK_SPEED_MULT - 1.0)) / FRENZY_ATK_SPEED_MULT
			modulate = Color.WHITE

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Drum Roll Dash: nachgereihte kurze Hops nach Initial-Dash
	if _drum_hops_remaining > 0:
		_drum_hop_timer -= delta
		if _drum_hop_timer <= 0.0:
			_do_drum_hop()
			_drum_hops_remaining -= 1
			_drum_hop_timer = DRUM_HOP_INTERVAL

func _on_dash_start() -> void:
	# Erste Afterimage sofort an Startposition
	_afterimages.append({"pos": global_position, "age": 0.0})
	# Plane 2 weitere Hops nach Ablauf des initialen Dashs
	_drum_hops_remaining = DRUM_HOPS_TOTAL
	_drum_hop_timer = _DASH_DURATION + DRUM_HOP_INTERVAL

func _on_dash_tick(_delta: float) -> void:
	# Periodisch Afterimage waehrend des Initial-Dashs spawnen
	if _afterimages.is_empty() or _afterimages[-1]["age"] > 0.04:
		_afterimages.append({"pos": global_position, "age": 0.0})

func _do_drum_hop() -> void:
	# Kurzer instantaner Sprung in Dash-Richtung
	_afterimages.append({"pos": global_position, "age": 0.0})
	var target: Vector2 = global_position + _dash_dir * DRUM_HOP_DISTANCE
	var vp = get_viewport_rect().size
	target.x = clamp(target.x, 32.0, vp.x - 32.0)
	target.y = clamp(target.y, 32.0, vp.y - 32.0)
	global_position = target
	_dash_flash = 0.12
	_afterimages.append({"pos": global_position, "age": 0.0})

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	# Afterimages der Drum Roll Dash: faded Silhouetten der frueheren Positionen
	if not _afterimages.is_empty():
		for ai in _afterimages:
			var age: float = ai["age"]
			var alpha: float = clamp(0.55 - age * 1.6, 0.0, 0.55)
			if alpha <= 0.0:
				continue
			var offs: Vector2 = (ai["pos"] as Vector2) - global_position
			# Vereinfachte Silhouette: Kopf + Torso als gefuellte Formen mit reduziertem Alpha
			var ghost_col = Color(0.55, 0.85, 1.0, alpha)
			draw_circle(offs + Vector2(0, -26), 17, ghost_col)
			draw_rect(Rect2(offs + Vector2(-13, -8), Vector2(26, 22)), ghost_col)
			draw_rect(Rect2(offs + Vector2(-11, 14), Vector2(9, 14)), ghost_col)
			draw_rect(Rect2(offs + Vector2(2, 14), Vector2(9, 14)), ghost_col)
	var flash   = _hit_flash > 0
	# -- South Park Stil --
	var skin    = Color(0.98, 0.82, 0.66) if not flash else Color(1, 1, 1)
	var overall = Color(0.18, 0.28, 0.55)   # dunkelblaue Latzhose
	var beanie  = Color(0.82, 0.72, 0.52)   # beige/tan Cap (wie im Bild)
	var beard   = Color(0.30, 0.18, 0.08)   # Vollbart
	var stick_c = Color(0.68, 0.48, 0.22)   # Trommelstoecke
	var _wc   = sin(_anim_time * 5.0)
	var bob   = _wc * 0.8
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.6
	var arm_l = _wc * 0.6
	var drum_l = sin(_anim_time * 8.0) * 6.0
	var drum_r = sin(_anim_time * 8.0 + PI) * 6.0

	# Schuhe (breit, flach - South Park)
	draw_rect(Rect2(-14, 27 + bob + leg_l * 0.25, 13, 5), Color(0.12, 0.08, 0.04))
	draw_rect(Rect2(-1,  27 + bob + leg_r * 0.25, 13, 5), Color(0.12, 0.08, 0.04))

	# Beine (Latzhose, kurze Stubs)
	draw_rect(Rect2(-11, 14 + bob + leg_l * 0.25, 9, 14), overall)
	draw_rect(Rect2(2,   14 + bob + leg_r * 0.25, 9, 14), overall)

	# Latzhosen-Torso (flach, breit)
	draw_rect(Rect2(-13, -8 + bob, 26, 22), overall)

	# Latzhosen-Traeger (Y-Form, simpel - flache Farbe)
	draw_line(Vector2(-8, -8 + bob), Vector2(-3, -24 + bob), Color(0.38, 0.50, 0.80), 3)
	draw_line(Vector2(8,  -8 + bob), Vector2(3,  -24 + bob), Color(0.38, 0.50, 0.80), 3)

	# Arme (kurze Stubs)
	draw_rect(Rect2(-21, -3 + bob + arm_l, 8, 13), overall)
	draw_rect(Rect2(13,  -3 + bob + arm_r, 8, 13), overall)

	# Mitten-Haende (SP: runde Klumpen)
	draw_circle(Vector2(-20, 9 + bob + arm_l), 6, skin)
	draw_circle(Vector2(20,  9 + bob + arm_r), 6, skin)

	# Trommelstoecke in den Haenden
	draw_line(Vector2(-18, 10 + bob + arm_l), Vector2(-26, 22 + bob + arm_l + drum_l), stick_c, 3.0)
	draw_circle(Vector2(-26, 22 + bob + arm_l + drum_l), 3.5, stick_c)
	draw_line(Vector2(21,  10 + bob + arm_r), Vector2(29,  22 + bob + arm_r + drum_r), stick_c, 3.0)
	draw_circle(Vector2(29,  22 + bob + arm_r + drum_r), 3.5, stick_c)

	# Kopf (gross, rund - South Park typisch)
	draw_circle(Vector2(0, -26 + bob), 17, skin)

	# Beanie-Muetze (bedeckt obere Kopfhaelfte)
	var bp = PackedVector2Array([
		Vector2(-17, -28 + bob), Vector2(-14, -36 + bob),
		Vector2(-7,  -44 + bob), Vector2(0,   -46 + bob),
		Vector2(7,   -44 + bob), Vector2(14,  -36 + bob),
		Vector2(17,  -28 + bob),
	])
	draw_colored_polygon(bp, beanie)
	draw_line(Vector2(-17, -28 + bob), Vector2(17, -28 + bob), beanie.darkened(0.3), 3)  # Buendchen

	# Vollbart (untere Gesichtshaelfte)
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

	# Augen (nach innen geneigte Ovale - authentisch South Park)
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
	var stack_cap: int = MAX_PASSIVE_STACKS
	if has_upgrade("manni_blast_beats"):
		stack_cap += 5
	for i in range(passive_stacks):
		var angle = i * TAU / max(1, stack_cap) - PI / 2.0
		draw_circle(Vector2(cos(angle), sin(angle)) * 30, 2.5, Color(1.0, 0.8, 0.2, 0.8))

	# Level-Up Text Overlay
	_draw_levelup_text()

func _auto_attack() -> void:
	var dir = get_direction_to_nearest_enemy()
	spawn_projectile(dir)
	if randf() < double_strike_chance:
		spawn_projectile(dir.rotated(0.12))
	# Blast Beat Frenzy: 30% Knockback-Chance bei jedem Treffer
	if _frenzy_timer > 0.0 and randf() < FRENZY_KNOCKBACK_CHANCE:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e):
				var to_e: Vector2 = e.global_position - global_position
				if to_e.length() < 220.0:
					if e.has_method("apply_knockback"):
						e.apply_knockback(to_e.normalized() * 420.0)
	emit_signal("attacked")
	AudioManager.play_hit_sfx()

# Signature: Blast Beat Barrage - Doppelschlaege nach vorne UND hinten, im Takt.
# Mehr Abdeckung, dafuer pro Stick weniger Schaden und kuerzere Reichweite.
func _auto_attack_signature() -> void:
	var dir = get_direction_to_nearest_enemy()
	var d: float = get_total_damage() * 0.6
	spawn_projectile(dir.rotated(-0.09), d, 300.0)
	spawn_projectile(dir.rotated(0.09), d, 300.0)
	spawn_projectile(-dir, d, 300.0)
	if randf() < double_strike_chance:
		spawn_projectile(dir, d, 300.0)
	if _frenzy_timer > 0.0 and randf() < FRENZY_KNOCKBACK_CHANCE:
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e):
				var to_e: Vector2 = e.global_position - global_position
				if to_e.length() < 220.0 and e.has_method("apply_knockback"):
					e.apply_knockback(to_e.normalized() * 420.0)
	emit_signal("attacked")
	AudioManager.play_hit_sfx()

func _use_ultimate() -> void:
	# Blast Beat Frenzy: 3s lang verdreifachte Angriffsgeschwindigkeit
	# Mechanik: temporaerer attack_speed_bonus-Boost (Faktor 3 = +200%)
	# Rueckabwicklung erfolgt in _process wenn _frenzy_timer <= 0
	if _frenzy_timer <= 0.0:
		# Nur boosten wenn nicht schon aktiv
		attack_speed_bonus += (FRENZY_ATK_SPEED_MULT - 1.0) * (1.0 + attack_speed_bonus)
		_frenzy_timer = FRENZY_DURATION
		_frenzy_flash = 0.0
	# Kleine begleitende Schockwelle als visuelles Feedback
	var main_sw = _SW_SCENE.instantiate()
	main_sw.global_position = global_position
	main_sw.radius = 140.0 * (1.0 + aoe_radius_bonus)
	var sw_damage: float = get_total_damage() * 1.5
	# power_chord wirkte bei Manni als einzigem Charakter nicht (Audit Run #11)
	if has_upgrade("power_chord"):
		sw_damage *= 1.5
	main_sw.damage = sw_damage
	main_sw.shooter = self
	if has_upgrade("distortion_pedal"):
		main_sw.slow_factor = 0.4
		main_sw.slow_duration = 3.0
	get_tree().current_scene.add_child(main_sw)

	# Double Kick: extra (vierter) Schockwellen-Ring mit groesserem Radius
	if has_upgrade("manni_double_kick"):
		var extra = _SW_SCENE.instantiate()
		extra.global_position = global_position
		extra.radius = 220.0 * (1.0 + aoe_radius_bonus)
		extra.damage = get_total_damage() * 1.2
		extra.shooter = self
		if extra.has_method("set"):
			extra.set("expand_time", 0.55)
		get_tree().current_scene.add_child(extra)

	AudioManager.play_ultimate_sfx()
	super._use_ultimate()

func _on_kill_passive(_enemy) -> void:
	# Blast Beats upgrade raises the cap from 10 to 15
	var cap: int = MAX_PASSIVE_STACKS
	if has_upgrade("manni_blast_beats"):
		cap += 5
	if passive_stacks < cap:
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
	# Drumsticks flying in from both sides (arrive at t~0.35)
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
