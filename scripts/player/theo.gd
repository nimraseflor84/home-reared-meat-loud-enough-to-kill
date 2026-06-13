extends "res://scripts/player/player_base.gd"

# THEO - Geheimcharakter (Easteregg): Der Stagehand der Band.
# Geheimratsecken, Kinnbart, kariertes Flanellhemd, Gaffa-Rolle am Guertel.
# Freischaltung: eine Boss-Welle ohne Schaden ueberstehen (siehe game_scene.gd).
#
# Waffe:    Gaffa-Tape-Rollen, die mehrere Gegner durchschlagen
# Ultimate: PA-Drop - eine Lautsprecherbox kracht auf die dichteste Gegnergruppe
# Passive:  Schnelle Buehne - jeder Kill verkuerzt den Ultimate-Cooldown um 0,5s

## Cooldown-Verkuerzung pro Kill in Sekunden (0.5 -> 0.35, Balancing Run #11:
## Schneeball-Risiko in dichten Endless-Wellen mit amp_overdrive)
const KILL_CD_REDUCTION: float = 0.35
## Verzoegerung bis die PA-Box einschlaegt (Sekunden)
const PA_DROP_DELAY: float = 0.55
## Radius des PA-Einschlags (vor AoE-Bonus)
const PA_DROP_RADIUS: float = 180.0

# Laufende PA-Drops: {pos: Vector2, timer: float, damage: float}
var _pa_drops: Array = []

func _ready() -> void:
	character_id = "theo"
	max_hp = 100
	move_speed = 200.0
	base_damage = 26.0
	attack_speed = 0.9
	ultimate_cooldown = 16.0
	pierce = 2
	add_to_group("players")
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	# PA-Drops abarbeiten: nach Verzoegerung Schockwelle am Zielpunkt
	if _pa_drops.is_empty():
		return
	var i: int = _pa_drops.size() - 1
	while i >= 0:
		_pa_drops[i]["timer"] -= delta
		if _pa_drops[i]["timer"] <= 0.0:
			var drop = _pa_drops[i]
			var sw = _SW_SCENE.instantiate()
			sw.global_position = drop["pos"]
			sw.radius = PA_DROP_RADIUS * (1.0 + aoe_radius_bonus)
			sw.damage = drop["damage"]
			sw.slow_factor = 0.6
			sw.slow_duration = 1.5
			sw.shooter = self
			get_tree().current_scene.add_child(sw)
			_pa_drops.remove_at(i)
		i -= 1
	queue_redraw()

func _auto_attack() -> void:
	# Gaffa-Rolle: durchschlaegt mehrere Gegner (pierce 2 Basis)
	var dir = get_direction_to_nearest_enemy()
	_spawn_tape(dir)
	if randf() < double_strike_chance:
		_spawn_tape(dir.rotated(-PI / 10.0))
	emit_signal("attacked")

# Signature: Backline Rig - feuert Gaffa-Rollen auf die bis zu 3 naechsten
# Gegner gleichzeitig (Rig-Spray). Pro Rolle weniger Schaden.
func _auto_attack_signature() -> void:
	var ranked: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			ranked.append({"e": e, "d": global_position.distance_squared_to(e.global_position)})
	ranked.sort_custom(func(a, b): return a["d"] < b["d"])
	var n: int = min(3, ranked.size())
	if n == 0:
		_spawn_tape(get_direction_to_nearest_enemy(), get_total_damage() * 0.55)
	else:
		for i in range(n):
			var dir2: Vector2 = (ranked[i]["e"].global_position - global_position).normalized()
			_spawn_tape(dir2, get_total_damage() * 0.55)
	emit_signal("attacked")

func _spawn_tape(dir: Vector2, dmg: float = -1.0) -> void:
	var proj = _PROJ_SCENE.instantiate()
	proj.global_position = global_position
	proj.direction = dir
	proj.damage = dmg if dmg > 0.0 else get_total_damage()
	proj.speed = 430.0
	proj.pierce_count = pierce
	proj.bounce_count = extra_bounce
	proj.shooter = self
	proj.proj_type = 7   # Gaffa-Rolle
	get_tree().current_scene.add_child(proj)

func _on_kill_passive(_enemy) -> void:
	# Schnelle Buehne: Kills verkuerzen den Ultimate-Cooldown
	ultimate_timer = max(0.0, ultimate_timer - KILL_CD_REDUCTION)

func _use_ultimate() -> void:
	# PA-Drop: Box faellt auf den Schwerpunkt der dichtesten Gegnergruppe.
	# Ermittlung: Position des naechsten Gegners + Mittelwert seiner Nachbarn.
	var ult_damage: float = get_total_damage() * 4.0
	if has_upgrade("power_chord"):
		ult_damage *= 1.5
	var target_pos: Vector2 = global_position
	var nearest = get_nearest_enemy()
	if nearest != null and is_instance_valid(nearest):
		# Schwerpunkt aus dem naechsten Gegner und allen Gegnern in 200px um ihn
		var center: Vector2 = nearest.global_position
		var sum: Vector2 = center
		var count: int = 1
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or e == nearest:
				continue
			if center.distance_to(e.global_position) < 200.0:
				sum += e.global_position
				count += 1
		target_pos = sum / float(count)
	_pa_drops.append({"pos": target_pos, "timer": PA_DROP_DELAY, "damage": ult_damage})
	# distortion_pedal: Slow-Welle am eigenen Standort (einheitlich mit allen Charakteren)
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

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	# Fallende PA-Boxen zeichnen (relativ zur Spielerposition)
	for drop in _pa_drops:
		var progress: float = 1.0 - clamp(drop["timer"] / PA_DROP_DELAY, 0.0, 1.0)
		var offs: Vector2 = (drop["pos"] as Vector2) - global_position
		var box_y: float = offs.y - (1.0 - progress) * 320.0
		# Zielkreis am Boden
		draw_arc(offs, 26.0 + progress * 8.0, 0.0, TAU, 24, Color(1.0, 0.4, 0.1, 0.5 + progress * 0.4), 2.5)
		# Box (schwarz mit Speaker-Kreisen)
		draw_rect(Rect2(offs.x - 16, box_y - 22, 32, 26), Color(0.10, 0.10, 0.12))
		draw_circle(Vector2(offs.x, box_y - 14), 7, Color(0.25, 0.25, 0.28))
		draw_circle(Vector2(offs.x, box_y - 14), 3, Color(0.05, 0.05, 0.06))

	var flash = _hit_flash > 0
	# -- South Park Stil --
	var skin   = Color(0.96, 0.78, 0.62) if not flash else Color(1, 1, 1)
	var plaid  = Color(0.60, 0.16, 0.14)   # rotes Flanellhemd
	var plaid2 = Color(0.30, 0.08, 0.10)   # dunkle Karolinien
	var jeans  = Color(0.25, 0.32, 0.50)
	var boots  = Color(0.30, 0.20, 0.10)
	var hair   = Color(0.62, 0.48, 0.30)   # hellbraun
	var beard  = Color(0.55, 0.42, 0.26)
	var _wc   = sin(_anim_time * 5.0)
	var bob   = _wc * 0.8
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.6
	var arm_l = _wc * 0.6

	# Arbeitsstiefel
	draw_rect(Rect2(-14, 26 + bob + leg_l * 0.25, 13, 6), boots)
	draw_rect(Rect2(-1,  26 + bob + leg_r * 0.25, 13, 6), boots)

	# Jeans
	draw_rect(Rect2(-11, 12 + bob + leg_l * 0.25, 9, 15), jeans)
	draw_rect(Rect2(2,   12 + bob + leg_r * 0.25, 9, 15), jeans)

	# Flanellhemd-Torso (rot mit Karomuster)
	draw_rect(Rect2(-12, -9 + bob, 24, 22), plaid)
	# Karolinien (vertikal + horizontal)
	for vx in [-7, 0, 7]:
		draw_line(Vector2(vx, -9 + bob), Vector2(vx, 13 + bob), plaid2, 1.5)
	for hy in [-4, 3, 10]:
		draw_line(Vector2(-12, hy + bob), Vector2(12, hy + bob), plaid2, 1.5)

	# Gaffa-Rolle am Guertel (graue Rolle, Markenzeichen des Stagehands)
	draw_circle(Vector2(9, 12 + bob), 4.5, Color(0.55, 0.55, 0.55))
	draw_circle(Vector2(9, 12 + bob), 2.0, Color(0.12, 0.12, 0.12))

	# Arme (Flanell, hochgekrempelt: unterer Teil Haut)
	draw_rect(Rect2(-19, -4 + bob + arm_l, 7, 7), plaid)
	draw_rect(Rect2(12,  -4 + bob + arm_r, 7, 7), plaid)
	draw_rect(Rect2(-19, 3 + bob + arm_l, 7, 6), skin)
	draw_rect(Rect2(12,  3 + bob + arm_r, 7, 6), skin)
	draw_circle(Vector2(-19, 11 + bob + arm_l), 5, skin)
	draw_circle(Vector2(19,  11 + bob + arm_r), 5, skin)

	# Kopf
	draw_circle(Vector2(0, -25 + bob), 16, skin)

	# Kurzes Haar mit Geheimratsecken: nur Seiten und Hinterkopf,
	# hohe Stirn bleibt frei
	var hpts = PackedVector2Array([
		Vector2(-15, -28 + bob), Vector2(-13, -36 + bob),
		Vector2(-6,  -39 + bob), Vector2(0,   -36 + bob),
		Vector2(6,   -39 + bob), Vector2(13,  -36 + bob),
		Vector2(15,  -28 + bob), Vector2(12,  -31 + bob),
		Vector2(7,   -33 + bob), Vector2(0,   -31 + bob),
		Vector2(-7,  -33 + bob), Vector2(-12, -31 + bob),
	])
	draw_colored_polygon(hpts, hair)

	# Kinnbart (Goatee: Patch am Kinn, kein voller Bart)
	var gpts = PackedVector2Array([
		Vector2(-5, -14 + bob), Vector2(5, -14 + bob),
		Vector2(4, -8 + bob), Vector2(0, -6 + bob), Vector2(-4, -8 + bob),
	])
	draw_colored_polygon(gpts, beard)
	# Schmaler Oberlippenbart
	draw_line(Vector2(-4, -18 + bob), Vector2(4, -18 + bob), beard, 2.0)

	# Freundliches Grinsen (Theo lacht auf dem Foto)
	draw_arc(Vector2(0, -20 + bob), 6.0, 0.3, PI - 0.3, 10, Color(0.45, 0.25, 0.15), 1.5)

	# Augen (entspannt, leicht zusammengekniffen)
	draw_line(Vector2(-9, -27 + bob), Vector2(-3, -26 + bob), Color(0.1, 0.1, 0.1), 2.5)
	draw_line(Vector2(3,  -26 + bob), Vector2(9,  -27 + bob), Color(0.1, 0.1, 0.1), 2.5)

	# Level-Up Text Overlay
	_draw_levelup_text()

func _draw_death() -> void:
	var t = _death_anim
	var skin  = Color(0.96, 0.78, 0.62)
	var plaid = Color(0.60, 0.16, 0.14)
	var blood = Color(0.72, 0.04, 0.04)
	if t < 0.5:
		# Eine PA-Box faellt ausgerechnet auf den eigenen Stagehand
		draw_rect(Rect2(-11, -6, 22, 20), plaid)
		draw_circle(Vector2(0, -24), 14, skin)
		var by = -110.0 + (t / 0.5) * 86.0
		draw_rect(Rect2(-18, by, 36, 30), Color(0.10, 0.10, 0.12))
		draw_circle(Vector2(0, by + 15), 8, Color(0.25, 0.25, 0.28))
	else:
		# Box steht, nur Stiefel schauen drunter hervor
		var st = min((t - 0.5) * 2.0, 1.0)
		draw_rect(Rect2(-18, -24, 36, 38), Color(0.10, 0.10, 0.12))
		draw_circle(Vector2(0, -9), 8, Color(0.25, 0.25, 0.28))
		draw_rect(Rect2(-16, 14, 12, 6), Color(0.30, 0.20, 0.10))
		draw_rect(Rect2(4,   14, 12, 6), Color(0.30, 0.20, 0.10))
		draw_circle(Vector2(0, 20), min(st * 26.0, 20.0), Color(blood.r, blood.g, blood.b, 0.7))
		# Gaffa-Rolle ist weggerollt
		draw_circle(Vector2(26, 18), 4.5, Color(0.55, 0.55, 0.55))
	# Particles
	var a = max(0.0, 1.0 - t * 0.35)
	for p in _death_ptcls:
		draw_circle(p["pos"], p["size"] * max(0.1, a), Color(p["col"].r, p["col"].g, p["col"].b, a))
