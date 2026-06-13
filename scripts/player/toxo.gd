extends "res://scripts/player/player_base.gd"

# TOXO - Bonus-Geheimcharakter (originaler Toxic-Held, Hommage, keine fremde Marke).
# Mutierter Held aus dem Giftfass: gruene Haut, zerfetzte Latzhose, Mopp, leuchtende Augen.
# Freischaltung: schwersten Grad (Bolognese Bloodbath) im Story-Mode durchspielen.
#
# Waffe:    Toxische Schleim-Blobs (Projektiltyp 8)
# Ultimate: Meltdown - grosse Giftwelle (Schaden + starker Slow) plus Screen-Shake
# Passive:  Mutation - Kills hinterlassen eine Giftwolke (Slow) und heilen 2 LP

const KILL_HEAL: int = 2
const KILL_SLOW_RADIUS: float = 110.0

var _ooze: float = 0.0  # Tropf-Animation

func _ready() -> void:
	character_id = "toxo"
	max_hp = 130
	move_speed = 195.0
	base_damage = 26.0
	attack_speed = 1.1
	ultimate_cooldown = 14.0
	add_to_group("players")
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	_ooze += delta

func _auto_attack() -> void:
	var dir = get_direction_to_nearest_enemy()
	spawn_projectile(dir, -1, 360.0)
	spawn_projectile(dir.rotated(0.22), get_total_damage() * 0.6, 320.0)
	spawn_projectile(dir.rotated(-0.22), get_total_damage() * 0.6, 320.0)
	if randf() < double_strike_chance:
		spawn_projectile(dir, get_total_damage() * 0.6, 360.0)
	emit_signal("attacked")

func _on_kill_passive(enemy) -> void:
	# Mutation: kleine Heilung plus Giftwolke (Slow) an der Todesposition
	heal(KILL_HEAL)
	if not is_instance_valid(enemy):
		return
	var pos: Vector2 = enemy.global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_method("apply_slow"):
			if e.global_position.distance_to(pos) < KILL_SLOW_RADIUS:
				e.apply_slow(0.5, 2.0)

func _use_ultimate() -> void:
	# Meltdown: grosse Giftwelle mit Schaden und starkem Slow
	var ult_damage: float = get_total_damage() * 4.0
	if has_upgrade("power_chord"):
		ult_damage *= 1.4
	var sw = _SW_SCENE.instantiate()
	sw.global_position = global_position
	sw.radius = 230.0 * (1.0 + aoe_radius_bonus)
	sw.damage = ult_damage
	sw.slow_factor = 0.35
	sw.slow_duration = 3.5
	sw.shooter = self
	if sw.has_method("set"):
		sw.set("expand_time", 0.45)
	get_tree().current_scene.add_child(sw)
	_request_screen_shake(8.0, 0.4)
	AudioManager.play_ultimate_sfx()
	super._use_ultimate()

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	var flash = _hit_flash > 0
	var skin   = Color(0.45, 0.78, 0.30) if not flash else Color(1, 1, 1)  # Giftgruen
	var skin_d = Color(0.30, 0.58, 0.20)
	var overall = Color(0.40, 0.30, 0.10)   # zerfetzte Latzhose
	var glow   = Color(0.75, 1.0, 0.25)     # leuchtende Augen / Schleim
	var mop_c  = Color(0.55, 0.40, 0.22)
	var _wc = sin(_anim_time * 5.0)
	var bob = _wc * 0.8
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_l = _wc * 0.6

	# Schuhe
	draw_rect(Rect2(-14, 27 + bob + leg_l * 0.25, 13, 5), Color(0.12, 0.10, 0.06))
	draw_rect(Rect2(-1, 27 + bob + leg_r * 0.25, 13, 5), Color(0.12, 0.10, 0.06))
	# Beine (gruene Haut)
	draw_rect(Rect2(-11, 14 + bob + leg_l * 0.25, 9, 14), skin)
	draw_rect(Rect2(2, 14 + bob + leg_r * 0.25, 9, 14), skin)
	# Zerfetzte Latzhose
	draw_rect(Rect2(-13, -8 + bob, 26, 22), overall)
	draw_line(Vector2(-8, -8 + bob), Vector2(-3, -22 + bob), overall.lightened(0.2), 3)
	draw_line(Vector2(8, -8 + bob), Vector2(3, -22 + bob), overall.lightened(0.2), 3)
	# Arme (gruen, kraeftig)
	draw_rect(Rect2(-21, -3 + bob + arm_l, 8, 13), skin)
	draw_rect(Rect2(13, -3 + bob - arm_l, 8, 13), skin)
	draw_circle(Vector2(-20, 9 + bob + arm_l), 6, skin)
	draw_circle(Vector2(20, 9 + bob - arm_l), 6, skin)
	# Mopp in der rechten Hand
	draw_line(Vector2(20, 8 + bob - arm_l), Vector2(30, -16 + bob - arm_l), mop_c, 3.0)
	for i in range(5):
		draw_line(Vector2(30, -16 + bob - arm_l), Vector2(26 + i * 2, -26 + bob - arm_l + sin(_anim_time * 6 + i) * 2.0), Color(0.85, 0.80, 0.55), 2.0)
	# Kopf (gross, gruen, beulig)
	draw_circle(Vector2(0, -26 + bob), 17, skin)
	draw_circle(Vector2(-9, -30 + bob), 5, skin_d)   # Beule
	draw_circle(Vector2(8, -22 + bob), 4, skin_d)    # Beule
	# Leuchtende Augen
	draw_circle(Vector2(-6, -28 + bob), 4.0, glow)
	draw_circle(Vector2(7, -28 + bob), 4.0, glow)
	draw_circle(Vector2(-6, -28 + bob), 1.8, Color(0.05, 0.10, 0.0))
	draw_circle(Vector2(7, -28 + bob), 1.8, Color(0.05, 0.10, 0.0))
	# Zorniges Maul
	draw_arc(Vector2(0, -19 + bob), 6, 0.1, PI - 0.1, 8, Color(0.10, 0.20, 0.05), 3)
	# Tropfender Schleim (animiert)
	for i in range(4):
		var dx = -12.0 + i * 8.0
		var dy = 12.0 + fmod(_ooze * 18.0 + i * 7.0, 16.0)
		draw_circle(Vector2(dx, dy + bob), 2.5, Color(glow.r, glow.g, glow.b, 0.7))
	_draw_levelup_text()

func _draw_death() -> void:
	var t = _death_anim
	var skin = Color(0.40, 0.70, 0.26)
	var glow = Color(0.75, 1.0, 0.25)
	var drop = min(t * 16.0, 26.0)
	# Schmilzt zu einer Giftpfuetze
	if t > 0.2:
		draw_ellipse_local(Vector2(0, 24), Vector2(min((t) * 36.0, 34.0), min(t * 12.0, 12.0)), Color(glow.r, glow.g, glow.b, 0.55))
	var melt = 1.0 - min(t * 0.8, 0.85)
	draw_rect(Rect2(-13 * melt, -8 + drop, 26 * melt, 22 * melt), skin)
	if t < 0.6:
		draw_circle(Vector2(0, -26 + drop), 17 * melt, skin)
		draw_circle(Vector2(-6, -28 + drop), 4.0 * melt, glow)
		draw_circle(Vector2(7, -28 + drop), 4.0 * melt, glow)
	for p in _death_ptcls:
		var a = max(0.0, 1.0 - t * 0.35)
		draw_circle(p["pos"], p["size"] * max(0.1, a), Color(glow.r, glow.g, glow.b, a * 0.8))

# Kleine lokale Ellipse (das Game nutzt anderswo Helfer; hier eigenstaendig)
func draw_ellipse_local(center: Vector2, radii: Vector2, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(20):
		var a = float(i) / 20.0 * TAU
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, col)
