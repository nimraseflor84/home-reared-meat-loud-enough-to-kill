extends "res://scripts/player/player_base.gd"

# PIMMEL - Geheimcharakter (Easteregg): Der Merch-Mann der Band.
# Sombrero, Sonnenbrille, Schnauzer, gelbes Hawaiihemd, Becher in der Hand.
# Freischaltung: 12 Upgrades in einem einzigen Run nehmen (siehe upgrade_shop.gd).
#
# Waffe:    Merch-Shirts als Boomerang-Wurf (prallen einmal von der Screenkante ab)
# Ultimate: Bauchladen-Rausch - Becher-Salve im Kreis + Slow-Welle
# Passive:  Verkaufsschlager - jeder 10. Kill laesst ein Merch-Paket fallen (+5 LP)

## Kills bis zum naechsten Merch-Paket (10 -> 6, Balancing Run #11:
## 0.43 LP/s war wirkungslos gegen jede Schwierigkeitsstufe)
const MERCH_PACKAGE_EVERY: int = 6
## Heilung pro Merch-Paket in LP
const MERCH_PACKAGE_HEAL: int = 5
## Anzahl Becher in der Ultimate-Salve
const ULT_CUP_COUNT: int = 12

var _merch_kill_counter: int = 0
# Becher-Schwapp-Animation nach Aktionen
var _cup_splash: float = 0.0

func _ready() -> void:
	character_id = "pimmel"
	max_hp = 110
	move_speed = 190.0
	base_damage = 26.0
	attack_speed = 1.0
	ultimate_cooldown = 14.0
	pierce = 1
	add_to_group("players")
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if _cup_splash > 0.0:
		_cup_splash -= delta
		queue_redraw()

func _auto_attack() -> void:
	# Merch-Shirt-Wurf: ein Shirt Richtung naechster Gegner, prallt 1x ab
	var dir = get_direction_to_nearest_enemy()
	_spawn_shirt(dir, -1.0)
	if randf() < double_strike_chance:
		_spawn_shirt(dir.rotated(PI / 8.0), -1.0)
	emit_signal("attacked")

# Signature: Bauchladen Blitz - drei Merch-Shirts gleichzeitig im Faecher,
# alle mit Boomerang-Bounce. Pro Shirt etwas weniger Schaden.
func _auto_attack_signature() -> void:
	var dir = get_direction_to_nearest_enemy()
	var d: float = get_total_damage() * 0.7
	_spawn_shirt(dir, d)
	_spawn_shirt(dir.rotated(0.35), d)
	_spawn_shirt(dir.rotated(-0.35), d)
	if randf() < double_strike_chance:
		_spawn_shirt(dir.rotated(PI / 8.0), -1.0)
	emit_signal("attacked")

# Spawnt ein Merch-Shirt-Projektil (proj_type 6) mit Boomerang-Bounce
func _spawn_shirt(dir: Vector2, dmg: float) -> void:
	var proj = _PROJ_SCENE.instantiate()
	proj.global_position = global_position
	proj.direction = dir
	proj.damage = dmg if dmg > 0.0 else get_total_damage()
	proj.speed = 380.0
	proj.pierce_count = pierce
	proj.bounce_count = 1 + extra_bounce
	proj.shooter = self
	proj.proj_type = 6   # Merch-Shirt
	get_tree().current_scene.add_child(proj)

func _on_kill_passive(_enemy) -> void:
	# Verkaufsschlager: jeder 10. Kill bringt ein Merch-Paket (+5 LP)
	_merch_kill_counter += 1
	if _merch_kill_counter >= MERCH_PACKAGE_EVERY:
		_merch_kill_counter = 0
		heal(MERCH_PACKAGE_HEAL)
		_cup_splash = 0.6

func _use_ultimate() -> void:
	# Bauchladen-Rausch: Becher-Salve im Kreis + Slow-Welle (Bier macht traege)
	var ult_damage: float = get_total_damage() * 2.5
	if has_upgrade("power_chord"):
		ult_damage *= 1.5
	for i in range(ULT_CUP_COUNT):
		var angle: float = float(i) * TAU / float(ULT_CUP_COUNT)
		var proj = _PROJ_SCENE.instantiate()
		proj.global_position = global_position
		proj.direction = Vector2(cos(angle), sin(angle))
		proj.damage = ult_damage
		proj.speed = 520.0
		proj.pierce_count = pierce + 2
		proj.bounce_count = 1 + extra_bounce
		proj.shooter = self
		proj.proj_type = 6
		get_tree().current_scene.add_child(proj)
	# Slow-Welle: verschuettetes Bier verlangsamt alles in der Naehe
	var sw = _SW_SCENE.instantiate()
	sw.global_position = global_position
	sw.radius = 150.0 * (1.0 + aoe_radius_bonus)
	sw.damage = get_total_damage() * 0.5
	sw.slow_factor = 0.5
	sw.slow_duration = 2.5
	sw.shooter = self
	get_tree().current_scene.add_child(sw)
	# distortion_pedal: zusaetzliche reine Slow-Welle (einheitlich mit allen Charakteren)
	if has_upgrade("distortion_pedal"):
		var sw2 = _SW_SCENE.instantiate()
		sw2.global_position = global_position
		sw2.radius = 160.0 * (1.0 + aoe_radius_bonus)
		sw2.damage = 0.0
		sw2.slow_factor = 0.4
		sw2.slow_duration = 3.0
		sw2.shooter = self
		get_tree().current_scene.add_child(sw2)
	_cup_splash = 0.8
	AudioManager.play_ultimate_sfx()
	super._use_ultimate()

func _draw() -> void:
	if _death_anim >= 0.0:
		_draw_death()
		return
	var flash = _hit_flash > 0
	# -- South Park Stil --
	var skin      = Color(0.95, 0.76, 0.58) if not flash else Color(1, 1, 1)
	var shirt     = Color(0.97, 0.80, 0.10)   # gelbes Hawaiihemd
	var flower_r  = Color(0.85, 0.25, 0.15)   # rote Hibiskus-Tupfer
	var flower_w  = Color(0.95, 0.95, 0.90)   # weisse Tupfer
	var shorts    = Color(0.16, 0.18, 0.30)   # dunkle Shorts
	var hat       = Color(0.93, 0.72, 0.12)   # Sombrero-Gelb
	var hat_dark  = Color(0.72, 0.52, 0.08)
	var tash      = Color(0.42, 0.26, 0.12)   # Schnauzer
	var cup       = Color(0.15, 0.35, 0.85)   # blauer Becher
	var _wc   = sin(_anim_time * 5.0)
	var bob   = _wc * 0.8
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.6
	var arm_l = _wc * 0.6

	# Schuhe (schwarze Slip-Ons mit weisser Sohle)
	draw_rect(Rect2(-14, 29 + bob + leg_l * 0.25, 13, 3), Color(0.92, 0.92, 0.88))
	draw_rect(Rect2(-1,  29 + bob + leg_r * 0.25, 13, 3), Color(0.92, 0.92, 0.88))
	draw_rect(Rect2(-14, 25 + bob + leg_l * 0.25, 13, 5), Color(0.08, 0.08, 0.08))
	draw_rect(Rect2(-1,  25 + bob + leg_r * 0.25, 13, 5), Color(0.08, 0.08, 0.08))

	# Nackte Beine (Shorts-Traeger)
	draw_rect(Rect2(-10, 16 + bob + leg_l * 0.25, 8, 10), skin)
	draw_rect(Rect2(2,   16 + bob + leg_r * 0.25, 8, 10), skin)

	# Shorts (dunkel, knielang)
	draw_rect(Rect2(-11, 8 + bob, 22, 10), shorts)

	# Hawaiihemd-Torso (gelb, leicht offen)
	draw_rect(Rect2(-12, -10 + bob, 24, 20), shirt)
	# Offener Kragen: Haut-Dreieck
	var chest = PackedVector2Array([
		Vector2(-3, -10 + bob), Vector2(3, -10 + bob), Vector2(0, -1 + bob),
	])
	draw_colored_polygon(chest, skin)
	# Hibiskus-Tupfer auf dem Hemd
	draw_circle(Vector2(-8, -5 + bob), 2.2, flower_r)
	draw_circle(Vector2(7,  -7 + bob), 2.0, flower_w)
	draw_circle(Vector2(8,   3 + bob), 2.2, flower_r)
	draw_circle(Vector2(-7,  4 + bob), 2.0, flower_w)
	draw_circle(Vector2(2,   6 + bob), 1.8, flower_r)

	# Arme (Kurzarm - Haut)
	draw_rect(Rect2(-19, -5 + bob + arm_l, 7, 12), shirt)
	draw_rect(Rect2(12,  -5 + bob + arm_r, 7, 12), shirt)
	draw_circle(Vector2(-19, 9 + bob + arm_l), 5, skin)
	draw_circle(Vector2(19,  9 + bob + arm_r), 5, skin)

	# Blauer Becher in der rechten Hand (mit Schwapp-Effekt nach Aktionen)
	draw_rect(Rect2(15, 2 + bob + arm_r, 9, 11), cup)
	draw_rect(Rect2(15, 2 + bob + arm_r, 9, 3), cup.lightened(0.3))
	if _cup_splash > 0.0:
		var sp = _cup_splash
		draw_circle(Vector2(19, -1 + bob + arm_r), 2.0 + sp * 3.0, Color(0.95, 0.85, 0.4, sp))

	# Kopf
	draw_circle(Vector2(0, -26 + bob), 16, skin)

	# Schnauzer (breit, buschig)
	var tpts = PackedVector2Array([
		Vector2(-8, -20 + bob), Vector2(8, -20 + bob),
		Vector2(6, -16 + bob), Vector2(-6, -16 + bob),
	])
	draw_colored_polygon(tpts, tash)

	# Sonnenbrille (zwei dunkle Glaeser + Steg)
	draw_rect(Rect2(-12, -32 + bob, 9, 7), Color(0.05, 0.05, 0.08))
	draw_rect(Rect2(3,   -32 + bob, 9, 7), Color(0.05, 0.05, 0.08))
	draw_line(Vector2(-3, -29 + bob), Vector2(3, -29 + bob), Color(0.05, 0.05, 0.08), 2.0)
	# Reflex in den Glaesern
	draw_line(Vector2(-10, -31 + bob), Vector2(-7, -28 + bob), Color(0.6, 0.7, 0.9, 0.6), 1.2)
	draw_line(Vector2(5, -31 + bob), Vector2(8, -28 + bob), Color(0.6, 0.7, 0.9, 0.6), 1.2)

	# Sombrero: riesige Krempe (Ellipse) + hohe Krone
	var brim = PackedVector2Array()
	for i in range(20):
		var a = float(i) * TAU / 20.0
		brim.append(Vector2(cos(a) * 30.0, -38.0 + bob + sin(a) * 7.0))
	draw_colored_polygon(brim, hat)
	# Krempen-Rand
	for i in range(20):
		var a1 = float(i) * TAU / 20.0
		var a2 = float(i + 1) * TAU / 20.0
		draw_line(Vector2(cos(a1) * 30.0, -38.0 + bob + sin(a1) * 7.0),
			Vector2(cos(a2) * 30.0, -38.0 + bob + sin(a2) * 7.0), hat_dark, 1.5)
	# Krone (hoher Kegel)
	var crown = PackedVector2Array([
		Vector2(-11, -38 + bob), Vector2(11, -38 + bob), Vector2(0, -60 + bob),
	])
	draw_colored_polygon(crown, hat)
	# Hutband
	draw_line(Vector2(-9, -41 + bob), Vector2(9, -41 + bob), Color(0.65, 0.18, 0.10), 3.0)

	# Level-Up Text Overlay
	_draw_levelup_text()

func _draw_death() -> void:
	var t = _death_anim
	var skin  = Color(0.95, 0.76, 0.58)
	var shirt = Color(0.97, 0.80, 0.10)
	var hat   = Color(0.93, 0.72, 0.12)
	var blood = Color(0.72, 0.04, 0.04)
	var cup   = Color(0.15, 0.35, 0.85)
	if t < 0.5:
		# Pimmel kippt langsam um, der Becher fliegt in hohem Bogen davon
		var lean = t * 2.0 * 0.6
		draw_set_transform(Vector2.ZERO, lean)
		draw_rect(Rect2(-11, 8, 22, 18), shirt)
		draw_circle(Vector2(0, -26), 14, skin)
		draw_rect(Rect2(-10, -32, 8, 6), Color(0.05, 0.05, 0.08))
		draw_rect(Rect2(2,   -32, 8, 6), Color(0.05, 0.05, 0.08))
		draw_set_transform(Vector2.ZERO, 0.0)
		# Becher fliegt weg
		var ct = t / 0.5
		var cpos = Vector2(20.0 + ct * 40.0, -10.0 - sin(ct * PI) * 35.0)
		draw_rect(Rect2(cpos.x, cpos.y, 8, 10), cup)
		# Bier-Tropfen
		for i in range(4):
			draw_circle(cpos + Vector2(-4.0 - float(i) * 5.0, 3.0 + float(i) * 4.0), 2.0, Color(0.95, 0.85, 0.4, 0.8))
	else:
		# Am Boden, nur der Sombrero liegt obenauf
		var st = min((t - 0.5) * 2.0, 1.0)
		draw_rect(Rect2(-16, 14, 32, 10), shirt)
		draw_circle(Vector2(-20, 18), 9, skin)
		# Sombrero liegt auf dem Koerper
		var brim = PackedVector2Array()
		for i in range(16):
			var a = float(i) * TAU / 16.0
			brim.append(Vector2(cos(a) * 26.0, 8.0 + sin(a) * 6.0))
		draw_colored_polygon(brim, hat)
		draw_circle(Vector2(0, 4), 9, hat.darkened(0.2))
		draw_circle(Vector2(8, 24), min(st * 24.0, 18.0), Color(blood.r, blood.g, blood.b, 0.7))
	# Particles
	var a = max(0.0, 1.0 - t * 0.35)
	for p in _death_ptcls:
		draw_circle(p["pos"], p["size"] * max(0.1, a), Color(p["col"].r, p["col"].g, p["col"].b, a))
