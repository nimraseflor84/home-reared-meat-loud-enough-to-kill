extends EnemyBase

# Knastdirektor Dr. Horst Käfig
# Angriff:  Schlagstöcke werfen (rotierende Projektile)
# Spezial:  Gefängnisausbruch – 3 Gefangene stürmen aus dem Off

const _GEFANGENER_SCENE = preload("res://scenes/entities/enemies/enemy_gefangener.tscn")

const BATON_CD      = 2.2    # Sekunden zwischen Würfen
const BATON_SPEED   = 235.0
const BATON_RANGE   = 520.0  # maximale Reichweite
const AUSBRUCH_CD   = 14.0   # Spezialfähigkeit-Cooldown
const PHASE2_HP     = 0.5

var _baton_timer: float    = 1.0
var _ausbruch_timer: float = 7.0   # erstes Ausbruch nach 7 s
var _phase2: bool          = false
var _alarm_anim: float     = -1.0  # 0 .. 1.0 – roter Alarm-Blitz

# Schlagstöcke als interne Projektile:
# {pos: Vector2, vel: Vector2, angle: float, angle_vel: float, dmg: float}
var _batons: Array = []

func _ready() -> void:
	enemy_id             = "gefchef"
	max_hp               = 650.0
	damage               = 28.0
	move_speed           = 84.0
	score_value          = 1700
	_death_anim_duration = 1.6
	add_to_group("bosses")
	super._ready()

# ── Update ────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not is_alive or _dying:
		super._process(delta)
		return

	# Alarm-Animation
	if _alarm_anim >= 0.0:
		_alarm_anim += delta
		if _alarm_anim >= 1.0:
			_alarm_anim = -1.0

	# Batons bewegen & Treffer prüfen
	for i in range(_batons.size() - 1, -1, -1):
		var bt = _batons[i]
		bt["pos"]   += bt["vel"] * delta
		bt["angle"] += bt["angle_vel"] * delta
		var too_far = bt["pos"].distance_to(global_position) > BATON_RANGE
		var hit = false
		if is_instance_valid(target):
			if bt["pos"].distance_to(target.global_position) < 22.0:
				if target.has_method("take_damage"):
					target.take_damage(bt["dmg"])
				if target.has_method("apply_knockback"):
					target.apply_knockback(bt["vel"].normalized() * 280.0)
				hit = true
		if hit or too_far:
			_batons.remove_at(i)

	super._process(delta)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if not _phase2 and current_hp <= max_hp * PHASE2_HP:
		_phase2   = true
		move_speed = 144.0
		_baton_timer = 0.0  # sofort einen Baton werfen

	_baton_timer += delta
	if is_instance_valid(target) and _baton_timer >= BATON_CD:
		var dist = global_position.distance_to(target.global_position)
		if dist > 70.0:
			_baton_timer = 0.0
			_throw_baton()

	_ausbruch_timer -= delta
	if _ausbruch_timer <= 0.0:
		_ausbruch_timer = AUSBRUCH_CD
		_do_ausbruch()

	super._physics_process(delta)

# ── Aktionen ──────────────────────────────────────────────────────────────────
func _throw_baton() -> void:
	if not is_instance_valid(target):
		return
	var dir = (target.global_position - global_position).normalized()
	# Phase 2: zwei Batons in leichtem Fächer
	var angles = [0.0] if not _phase2 else [-0.18, 0.18]
	for a in angles:
		_batons.append({
			"pos":       global_position + dir.rotated(a) * 30.0,
			"vel":       dir.rotated(a) * BATON_SPEED,
			"angle":     0.0,
			"angle_vel": 9.0 * (1.0 if a >= 0.0 else -1.0),
			"dmg":       damage * 0.85,
		})
	AudioManager.play_projectile_sfx(0)

func _do_ausbruch() -> void:
	_alarm_anim = 0.0
	AudioManager.play_boss_siren_sfx()
	for i in range(3):
		var prisoner = _GEFANGENER_SCENE.instantiate()
		prisoner.global_position = _ausbruch_spawn_pos()
		get_tree().current_scene.add_child(prisoner)

func _ausbruch_spawn_pos() -> Vector2:
	var vp  = get_viewport().get_visible_rect()
	var mg  = 55.0
	match randi() % 4:
		0: return Vector2(randf_range(0, vp.size.x), -mg)
		1: return Vector2(randf_range(0, vp.size.x), vp.size.y + mg)
		2: return Vector2(-mg, randf_range(0, vp.size.y))
		_: return Vector2(vp.size.x + mg, randf_range(0, vp.size.y))

func _on_dying_process(_delta: float) -> void:
	_batons.clear()

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if _dying:
		_draw_death()
		return
	if not is_alive:
		return

	var bob   = sin(_anim_time * 3.0) * 1.5
	var flash = _hit_flash > 0
	_draw_body(bob, flash)
	_draw_batons()

	if _alarm_anim >= 0.0:
		_draw_alarm(bob)

func _draw_body(bob: float, flash: bool) -> void:
	var skin   = Color(0.88, 0.78, 0.68) if not flash else Color.WHITE
	var navy   = Color(0.08, 0.12, 0.32)
	var dnavy  = Color(0.05, 0.08, 0.22)
	var gold   = Color(0.88, 0.74, 0.12)
	var dgold  = Color(0.55, 0.44, 0.06)
	var white  = Color(0.95, 0.93, 0.90)
	var black  = Color(0.08, 0.08, 0.10)
	var baton  = Color(0.52, 0.32, 0.08)

	# Polierte schwarze Stiefel
	draw_rect(Rect2(-18, 28+bob, 15, 8), black)
	draw_rect(Rect2(3,   28+bob, 15, 8), black)
	draw_line(Vector2(-18, 28+bob), Vector2(-3, 28+bob), Color(0.4,0.4,0.45), 1.5)
	draw_line(Vector2(3,   28+bob), Vector2(18, 28+bob), Color(0.4,0.4,0.45), 1.5)

	# Hosen (navy, Uniformstreifen)
	draw_rect(Rect2(-16, 14+bob, 13, 16), navy)
	draw_rect(Rect2(3,   14+bob, 13, 16), navy)
	draw_line(Vector2(-9, 14+bob), Vector2(-9, 30+bob), gold, 2)
	draw_line(Vector2(9,  14+bob), Vector2(9,  30+bob), gold, 2)

	# Torso (dicke Uniform-Jacke)
	draw_rect(Rect2(-18, -14+bob, 36, 30), navy)
	# Weißes Hemd am Kragen sichtbar
	draw_rect(Rect2(-6, -14+bob, 12, 8), white)
	# Schwarze Krawatte
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3, -10+bob), Vector2(3, -10+bob), Vector2(2, 8+bob), Vector2(-2, 8+bob)
	]), black)
	# Uniformknöpfe
	for ky in [-4.0, 2.0, 8.0]:
		draw_circle(Vector2(0, ky+bob), 2.5, gold)

	# Goldenes Abzeichen auf linker Brust (Stern)
	var bx = -10.0;  var by = -4.0+bob
	draw_circle(Vector2(bx, by), 8, gold)
	draw_circle(Vector2(bx, by), 5, dgold)
	for si in range(6):
		var ang = float(si) * TAU / 6.0
		draw_line(Vector2(bx, by), Vector2(bx+cos(ang)*8, by+sin(ang)*8), gold, 2)

	# Schulterklappen (Epauletten)
	draw_rect(Rect2(-26, -14+bob, 10, 6), gold)
	draw_rect(Rect2(16,  -14+bob, 10, 6), gold)
	for ex in [-24.0, -21.0, -18.0]:
		draw_line(Vector2(ex, -14+bob), Vector2(ex, -8+bob), dgold, 1.5)
	for ex in [18.0, 21.0, 24.0]:
		draw_line(Vector2(ex, -14+bob), Vector2(ex, -8+bob), dgold, 1.5)

	# Arme
	draw_rect(Rect2(-26, -8+bob, 8, 18), navy)
	draw_rect(Rect2(18,  -8+bob, 8, 18), navy)
	# Hände
	draw_circle(Vector2(-24, 10+bob), 7, skin)
	draw_circle(Vector2(24,  10+bob), 7, skin)

	# Schlagstock an der Hüfte (wenn kein Baton aktiv)
	if _batons.is_empty():
		draw_line(Vector2(26, -6+bob), Vector2(30, 14+bob), baton, 5)
		draw_circle(Vector2(26, -6+bob), 5, baton.darkened(0.2))

	# Kopf (rund, etwas aufgedunsen – Büro-Typ)
	draw_circle(Vector2(0, -28+bob), 20, skin)
	# Doppelkinn
	draw_arc(Vector2(0, -16+bob), 14, 0.2, PI-0.2, 8, skin.darkened(0.12), 8)

	# Mütze (Dienstmütze navy mit gold)
	draw_rect(Rect2(-22, -44+bob, 44, 8), navy)   # Schirmmütze Krempe
	draw_rect(Rect2(-18, -58+bob, 36, 16), navy)  # Kappe oben
	draw_rect(Rect2(-20, -44+bob, 40, 4), dnavy)  # Schattenkante
	draw_line(Vector2(-18, -44+bob), Vector2(18, -44+bob), gold, 3)  # goldener Streifen
	# Abzeichen auf Mütze (Adler/Stern)
	draw_circle(Vector2(0, -50+bob), 6, gold)
	for si in range(5):
		var ang = float(si) * TAU / 5.0 - PI*0.5
		draw_line(Vector2(0, -50+bob),
			Vector2(cos(ang)*7, -50+bob+sin(ang)*7), gold, 2)

	# Augen (kalt, schmal)
	draw_rect(Rect2(-10, -30+bob, 8, 4), Color(0.92,0.90,0.85))
	draw_rect(Rect2(2,   -30+bob, 8, 4), Color(0.92,0.90,0.85))
	draw_circle(Vector2(-7, -29+bob), 2, black)
	draw_circle(Vector2(5,  -29+bob), 2, black)
	draw_line(Vector2(-12,-32+bob), Vector2(-2,-30+bob), Color(0.18,0.12,0.05), 3)
	draw_line(Vector2(2,  -30+bob), Vector2(12,-32+bob), Color(0.18,0.12,0.05), 3)

	# Mund (schmaler, abweisender Strich)
	draw_line(Vector2(-7, -21+bob), Vector2(7, -21+bob), Color(0.22,0.12,0.06), 3)

	# Phase 2: Gesicht rötet sich
	if _phase2:
		draw_circle(Vector2(0, -28+bob), 20, Color(0.75, 0.20, 0.15, 0.30))

func _draw_batons() -> void:
	var baton_c = Color(0.52, 0.32, 0.08)
	var grip_c  = Color(0.22, 0.14, 0.04)
	for bt in _batons:
		var lp  = to_local(bt["pos"])
		var ang = bt["angle"]
		var hw  = 14.0;  var hh = 4.0
		# Rotiertes Rechteck als Polygon
		var pts = PackedVector2Array([
			lp + Vector2(-hw, -hh).rotated(ang),
			lp + Vector2( hw, -hh).rotated(ang),
			lp + Vector2( hw,  hh).rotated(ang),
			lp + Vector2(-hw,  hh).rotated(ang),
		])
		draw_colored_polygon(pts, baton_c)
		# Griffbereich dunkler
		var gpts = PackedVector2Array([
			lp + Vector2(-hw, -hh).rotated(ang),
			lp + Vector2(-hw+8, -hh).rotated(ang),
			lp + Vector2(-hw+8,  hh).rotated(ang),
			lp + Vector2(-hw,    hh).rotated(ang),
		])
		draw_colored_polygon(gpts, grip_c)
		# Kugelkopf
		draw_circle(lp + Vector2(hw, 0).rotated(ang), 5.5, baton_c.darkened(0.2))

func _draw_alarm(bob: float) -> void:
	var at  = _alarm_anim
	var alf = sin(at * TAU * 3.0) * 0.5 + 0.5  # blinken
	# Roter Alarm-Schein um den Körper
	draw_circle(Vector2(0, -10+bob), 38, Color(0.85, 0.08, 0.05, alf * 0.45))
	# "AUSBRUCH!" Text-Ersatz: orangefarbene Streifen
	for i in range(3):
		var yy = -55.0 - float(i) * 10.0 + bob
		var al = max(0.0, 1.0 - at * 1.2) * alf
		draw_line(Vector2(-28, yy), Vector2(28, yy), Color(1.0, 0.55, 0.0, al), 3)

# ── Todesanimation ────────────────────────────────────────────────────────────
func _draw_death() -> void:
	var t     = _death_anim_time
	var navy  = Color(0.08, 0.12, 0.32)
	var skin  = Color(0.82, 0.70, 0.58)
	var gold  = Color(0.88, 0.74, 0.12)
	var blood = Color(0.70, 0.04, 0.04)
	var black = Color(0.08, 0.08, 0.10)

	var fall  = min(t * 50.0, 38.0)
	var lean  = min(t * 1.8, 1.0)

	# Blutlache
	if t > 0.35:
		draw_circle(Vector2(0, 36), min((t-0.35)*34.0, 28.0), Color(blood.r,blood.g,blood.b,0.70))

	# Beine auseinander
	draw_rect(Rect2(-16 + fall*0.2, 14+fall*0.45, 13, 16), navy)
	draw_rect(Rect2(3   + fall*0.2, 14+fall*0.45, 13, 16), navy)
	# Torso kippt zurück
	draw_rect(Rect2(-18 + fall*0.25*lean, -14+fall*lean, 36, 30), navy)
	# Abzeichen fliegt ab
	var gx = -10.0 - t*25.0;  var gy = -4.0 - t*40.0
	draw_circle(Vector2(gx, gy), 8, gold)
	# Mütze fliegt ab
	var hx = t*28.0;  var hy = -44.0 - t*52.0
	draw_rect(Rect2(-22+hx, hy, 44, 8), navy)
	draw_rect(Rect2(-18+hx, hy-16, 36, 16), navy)
	# Kopf rollt weg
	draw_circle(Vector2(fall*0.55, -28+fall*0.85), 20, skin)
	# Schlagstöcke fliegen auseinander
	for i in range(2):
		var bx = (-1.0 if i == 0 else 1.0) * (20.0 + t*50.0)
		var by = -10.0 - t*30.0
		var pts = PackedVector2Array([
			Vector2(bx-14, by-4), Vector2(bx+14, by-4),
			Vector2(bx+14, by+4), Vector2(bx-14, by+4),
		])
		draw_colored_polygon(pts, Color(0.52,0.32,0.08))

	# Fade-out letzte 0.3 s
	modulate.a = 1.0 - max(0.0, (t - 1.3) / 0.3)
