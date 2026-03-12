extends EnemyBase

# Donald Trump
# Angriff:   Lügen-Projektile (orange Sprechblasen)
# Spezial:   Toupet klappt zurück → Gesicht rot → Mr. Epstein im F36 fliegt herein
#            → Explosion → Trump angekohlt, zerfetzte Klamotten, Speed +20 %

const LUEGE_CD      = 2.4
const LUEGE_SPD     = 290.0
const LUEGE_RNG     = 560.0
const SPECIAL_CD    = 14.0

# Spezial-Phasen
const SP_NONE    = 0
const SP_HAIR    = 1   # Toupet klappt zurück   (0.9 s)
const SP_JET     = 2   # Jet fliegt herein       (variabel)
const SP_EXPLODE = 3   # Explosion               (0.7 s)

var _luege_timer: float    = 1.5
var _special_timer: float  = 8.0
var _sphase: int           = SP_NONE
var _sphase_t: float       = 0.0

var _phase2: bool          = false
var _charred: bool         = false   # nach Explosion dauerhaft
var _hair_angle: float     = 0.0    # 0 = normal, PI = umgeklappt
var _face_red: float       = 0.0    # 0..1 Rotfärbung

# Jet
var _jet_pos: Vector2      = Vector2.ZERO
var _jet_target: Vector2   = Vector2.ZERO
var _jet_alive: bool       = false

# Explosion
var _explode_r: float      = 0.0

# Lügen-Projektile
var _luegens: Array        = []   # {pos, vel, wobble, dmg}

func _ready() -> void:
	enemy_id             = "trump"
	max_hp               = 900.0
	damage               = 32.0
	move_speed           = 50.0
	score_value          = 2500
	_death_anim_duration = 1.6
	add_to_group("bosses")
	super._ready()

# ── Update ────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not is_alive or _dying:
		super._process(delta)
		return

	# Phase-2-Trigger bei 50 % HP → 3× Geschwindigkeit
	if not _phase2 and current_hp <= max_hp * 0.5:
		_phase2    = true
		move_speed *= 3.0

	# Lügen bewegen
	for i in range(_luegens.size() - 1, -1, -1):
		var l = _luegens[i]
		l["wobble"] += delta * 4.0
		l["pos"] += l["vel"] * delta
		var too_far = l["pos"].distance_to(global_position) > LUEGE_RNG
		var hit = false
		if is_instance_valid(target):
			if l["pos"].distance_to(target.global_position) < 22.0:
				if target.has_method("take_damage"):
					target.take_damage(l["dmg"])
				hit = true
		if hit or too_far:
			_luegens.remove_at(i)

	# Spezial-Phasen-Timer
	_sphase_t += delta
	match _sphase:
		SP_HAIR:
			# Toupet klappt zurück, Gesicht wird rot
			_hair_angle = min(_sphase_t / 0.9, 1.0) * PI
			_face_red   = min(_sphase_t / 0.9, 1.0)
			if _sphase_t >= 0.9:
				_start_jet()

		SP_JET:
			# Jet fliegt auf Trump zu
			if _jet_alive:
				var dir  = (_jet_target - _jet_pos).normalized()
				_jet_pos += dir * 400.0 * delta
				if _jet_pos.distance_to(_jet_target) < 30.0:
					_start_explosion()

		SP_EXPLODE:
			_explode_r += delta * 340.0
			if _sphase_t >= 0.7:
				_finish_special()

	super._process(delta)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if _sphase == SP_NONE:
		_luege_timer += delta
		if is_instance_valid(target) and _luege_timer >= LUEGE_CD:
			_luege_timer = 0.0
			_shoot_luege()
		_special_timer -= delta
		if _special_timer <= 0.0:
			_start_special()
		super._physics_process(delta)
	else:
		# Während Spezial: langsam oder stehen
		if _sphase == SP_EXPLODE:
			velocity = Vector2.ZERO
		else:
			velocity *= 0.85
		move_and_slide()

# ── Aktionen ──────────────────────────────────────────────────────────────────
func _shoot_luege() -> void:
	if not is_instance_valid(target): return
	var base_dir = (target.global_position - global_position).normalized()
	# 3 Lügen in leichtem Fächer
	for a in [-0.22, 0.0, 0.22]:
		var dir = base_dir.rotated(a)
		_luegens.append({
			"pos":    global_position + dir * 30.0,
			"vel":    dir * LUEGE_SPD,
			"wobble": randf() * TAU,
			"dmg":    damage * 0.80,
		})
	AudioManager.play_projectile_sfx(1)

func _start_special() -> void:
	_special_timer = SPECIAL_CD
	_sphase        = SP_HAIR
	_sphase_t      = 0.0
	_hair_angle    = 0.0
	_face_red      = 0.0

func _start_jet() -> void:
	_sphase      = SP_JET
	_sphase_t    = 0.0
	_jet_alive   = true
	_jet_target  = global_position
	# Jet kommt von zufälligem Bildschirmrand
	var vp       = get_viewport().get_visible_rect()
	var side     = randi() % 4
	match side:
		0: _jet_pos = Vector2(randf_range(0, vp.size.x), -80)
		1: _jet_pos = Vector2(randf_range(0, vp.size.x), vp.size.y + 80)
		2: _jet_pos = Vector2(-80, randf_range(0, vp.size.y))
		_: _jet_pos = Vector2(vp.size.x + 80, randf_range(0, vp.size.y))
	AudioManager.play_boss_siren_sfx()

func _start_explosion() -> void:
	_sphase      = SP_EXPLODE
	_sphase_t    = 0.0
	_jet_alive   = false
	_explode_r   = 0.0
	AudioManager.play_ultimate_sfx()
	# Nahschaden durch Explosion
	if is_instance_valid(target):
		if global_position.distance_to(target.global_position) < 120.0:
			if target.has_method("take_damage"):
				target.take_damage(damage * 2.5)
			if target.has_method("apply_knockback"):
				target.apply_knockback(
					(target.global_position - global_position).normalized() * 520.0
				)

func _finish_special() -> void:
	_sphase     = SP_NONE
	_sphase_t   = 0.0
	_charred    = true
	_face_red   = 0.0
	# Toupet weg, Speed +20 %
	move_speed  = move_speed * 1.20
	_explode_r  = 0.0
	_jet_alive  = false

func _on_dying_process(_delta: float) -> void:
	_luegens.clear()
	_jet_alive = false

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if _dying:
		_draw_death()
		return
	if not is_alive:
		return

	# Jet zeichnen (in Weltkoordinaten → local)
	if _jet_alive:
		_draw_jet(to_local(_jet_pos), (_jet_target - _jet_pos).normalized())

	# Explosion
	if _sphase == SP_EXPLODE:
		draw_circle(Vector2.ZERO, _explode_r,
			Color(1.0, 0.65, 0.1, max(0.0, 1.0 - _explode_r / 220.0)))
		draw_circle(Vector2.ZERO, _explode_r * 0.6,
			Color(1.0, 0.95, 0.5, max(0.0, 1.0 - _explode_r / 160.0)))
		return  # Körper während Explosion nicht zeichnen

	var _wc   = sin(_anim_time * 3.5)
	var bob   = _wc * 1.5
	var leg_r = _wc * 9.0
	var leg_l = -leg_r
	var arm_r = -leg_r * 0.7
	var arm_l = leg_r * 0.7
	var flash = _hit_flash > 0
	_draw_body(bob, leg_l, leg_r, arm_l, arm_r, flash)
	_draw_luegens()

func _draw_body(bob: float, leg_l: float, leg_r: float, arm_l: float, arm_r: float, flash: bool) -> void:
	var orange = Color(0.90, 0.52, 0.14) if not flash else Color.WHITE
	var charr  = Color(0.14, 0.10, 0.08)   # verkohlt
	var suit   = Color(0.10, 0.12, 0.28)   # dunkler Anzug
	var white  = Color(0.94, 0.92, 0.88)
	var red    = Color(0.85, 0.06, 0.06)   # Krawatte
	var yel    = Color(0.92, 0.82, 0.28)   # Haare

	# Gesichtsfarbe: normal orange → rot bei Special
	var face_c = orange
	if _face_red > 0.0:
		face_c = Color(
			orange.r * (1.0-_face_red) + 0.88 * _face_red,
			orange.g * (1.0-_face_red) + 0.08 * _face_red,
			orange.b * (1.0-_face_red) + 0.06 * _face_red
		)
	if flash:
		face_c = Color.WHITE

	# Anzug zerfetzt (gezackte Kanten wenn charred)
	if _charred:
		_draw_tattered_suit(bob, leg_l, leg_r, arm_l, arm_r, charr, suit)
	else:
		_draw_clean_suit(bob, leg_l, leg_r, arm_l, arm_r, suit, white, red)

	# Kopf
	var hb = bob * 0.4
	draw_circle(Vector2(0, -28+hb), 20, face_c)

	# Verkohlte Flecken
	if _charred:
		draw_circle(Vector2(-6, -26+hb), 6, Color(charr.r, charr.g, charr.b, 0.80))
		draw_circle(Vector2(8,  -24+hb), 4, Color(charr.r, charr.g, charr.b, 0.70))
		draw_circle(Vector2(-2, -32+hb), 5, Color(charr.r, charr.g, charr.b, 0.60))

	# Haar / Toupet
	if not _charred:
		_draw_hair(hb, yel)
	# Wenn charred: kahl (kein Haar)

	# Augen (kleine blaue Punkte, nah zusammen)
	draw_circle(Vector2(-4, -30+hb), 3, white)
	draw_circle(Vector2(4,  -30+hb), 3, white)
	draw_circle(Vector2(-4, -30+hb), 1.5, Color(0.28, 0.48, 0.72))
	draw_circle(Vector2(4,  -30+hb), 1.5, Color(0.28, 0.48, 0.72))

	# Schmollmund (klein, trotzig)
	draw_arc(Vector2(0, -22+hb), 6, PI*0.15, PI*0.85, 6, Color(0.68, 0.30, 0.20), 4)

	# Phase-2 / Special: Mund weit offen
	if _sphase == SP_HAIR or _face_red > 0.5:
		var mo = _face_red * 8.0
		draw_arc(Vector2(0, -21+hb), 6+mo*0.5, 0.1, PI-0.1, 6, Color(0.1,0.04,0.02), int(4+mo))

func _draw_clean_suit(bob: float, leg_l: float, leg_r: float, arm_l: float, arm_r: float, suit: Color, white: Color, red: Color) -> void:
	# Stiefel / Schuhe
	draw_rect(Rect2(-16, 28 + leg_l * 0.4 + bob, 14, 7), Color(0.08,0.06,0.04))
	draw_rect(Rect2(2,   28 + leg_r * 0.4 + bob, 14, 7), Color(0.08,0.06,0.04))
	# Hosen
	draw_rect(Rect2(-14, 14 + leg_l * 0.3 + bob, 11, 16), suit)
	draw_rect(Rect2(3,   14 + leg_r * 0.3 + bob, 11, 16), suit)
	# Anzug-Jacke
	draw_rect(Rect2(-16, -12+bob, 32, 28), suit)
	# Weißes Hemd Kragen
	draw_rect(Rect2(-5, -12+bob, 10, 10), white)
	# Sehr lange rote Krawatte
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3, -8+bob), Vector2(3, -8+bob),
		Vector2(5, 20+bob), Vector2(-5, 20+bob)
	]), red)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, 20+bob), Vector2(5, 20+bob), Vector2(0, 28+bob)
	]), red)
	# Revers
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -12+bob), Vector2(-14, -4+bob), Vector2(-5, 2+bob)
	]), white)
	draw_colored_polygon(PackedVector2Array([
		Vector2(5, -12+bob), Vector2(14, -4+bob), Vector2(5, 2+bob)
	]), white)
	# Knöpfe
	for ky in [-2.0, 4.0, 10.0]:
		draw_circle(Vector2(-6, ky+bob), 2, Color(0.75,0.72,0.68))
	# Arme
	draw_rect(Rect2(-24, -8 + arm_l + bob, 8, 20), suit)
	draw_rect(Rect2(16,  -8 + arm_r + bob, 8, 20), suit)
	# Kleine Hände
	draw_circle(Vector2(-22, 11 + arm_l + bob), 6, Color(0.88,0.50,0.14))
	draw_circle(Vector2(22,  11 + arm_r + bob), 6, Color(0.88,0.50,0.14))

func _draw_tattered_suit(bob: float, leg_l: float, leg_r: float, arm_l: float, arm_r: float, charr: Color, suit: Color) -> void:
	var dsuit = suit.darkened(0.4)
	# Schuhe – verkohlt
	draw_rect(Rect2(-16, 28 + leg_l * 0.4 + bob, 14, 7), charr)
	draw_rect(Rect2(2,   28 + leg_r * 0.4 + bob, 14, 7), charr)
	# Hosen – zerfetzt (gezackte Unterkante)
	draw_rect(Rect2(-14, 14 + leg_l * 0.3 + bob, 11, 12), dsuit)
	draw_rect(Rect2(3,   14 + leg_r * 0.3 + bob, 11, 12), dsuit)
	for tx in [-12.0, -8.0, -4.0, 4.0, 8.0, 12.0]:
		draw_line(Vector2(tx, 26+bob), Vector2(tx + randf_range(-3,3), 32+bob), dsuit, 3)
	# Jacke zerfetzt
	draw_rect(Rect2(-16, -12+bob, 32, 26), dsuit)
	# Verkohlte Flecken auf Jacke
	draw_circle(Vector2(-8, 4+bob), 8,  Color(charr.r,charr.g,charr.b,0.75))
	draw_circle(Vector2(10, -2+bob), 6, Color(charr.r,charr.g,charr.b,0.65))
	draw_circle(Vector2(-4, 10+bob), 5, Color(charr.r,charr.g,charr.b,0.55))
	# Krawatte verbrannt – hängendes Stück
	draw_line(Vector2(0, -8+bob), Vector2(2, 14+bob), Color(0.55,0.04,0.04), 5)
	draw_line(Vector2(2, 14+bob), Vector2(-4, 18+bob), Color(0.35,0.02,0.02), 4)
	# Arme
	draw_rect(Rect2(-24, -8 + arm_l + bob, 8, 18), dsuit)
	draw_rect(Rect2(16,  -8 + arm_r + bob, 8, 18), dsuit)
	draw_circle(Vector2(-22, 11 + arm_l + bob), 6, Color(0.78,0.40,0.10))
	draw_circle(Vector2(22,  11 + arm_r + bob), 6, Color(0.78,0.40,0.10))

func _draw_hair(bob: float, yel: Color) -> void:
	# Toupet: Winkel 0 = normal (links-rechts geschwungen), PI = umgeklappt
	var ha    = _hair_angle
	var pivot = Vector2(0, -44+bob)

	if ha < PI * 0.5:
		# Normal bis halb umgeklappt
		var lean = sin(ha) * 10.0  # seitlicher Versatz beim Umklappen
		# Comb-over: geschwungene Linien von rechts nach links
		for i in range(8):
			var sx = 16.0 - float(i) * 3.5
			var ex = -16.0 + float(i) * 1.5
			draw_line(
				Vector2(sx + lean, -38+bob),
				Vector2(ex + lean, -48+bob),
				yel, 3.5
			)
		# Haarvolumen-Unterlage
		draw_arc(Vector2(lean, -44+bob), 16, PI, TAU, 10, yel, 8)
	else:
		# Toupet klappt zurück – sichtbar als Scheibe
		var flip  = (ha - PI*0.5) / (PI*0.5)   # 0..1
		# Kahlköpfiger Schädel sichtbar
		draw_circle(Vector2(0, -44+bob), 16, Color(0.82,0.50,0.14))
		# Toupet als Scheibe die sich zurückklappt (perspective-squish)
		var w = (1.0 - flip) * 32.0 + 6.0
		var tpts = PackedVector2Array([
			Vector2(-w*0.5,  -38+bob), Vector2(w*0.5, -38+bob),
			Vector2(w*0.5+4, -50+bob), Vector2(-w*0.5-4, -50+bob),
		])
		draw_colored_polygon(tpts, yel)
		# Haare auf der Unterseite des Toupets sichtbar
		for i in range(5):
			var hx = -8.0 + float(i) * 4.0
			draw_line(Vector2(hx, -50+bob), Vector2(hx+2, -58+bob), yel.darkened(0.2), 2.5)

func _draw_jet(pos: Vector2, dir: Vector2) -> void:
	var angle    = dir.angle()
	var jet_c    = Color(0.65, 0.68, 0.72)    # Silber
	var cockpit  = Color(0.28, 0.62, 0.88)    # Blaues Cockpit
	var red_c    = Color(0.82, 0.08, 0.06)
	var white_c  = Color(0.94, 0.92, 0.88)

	# Rauchwolke hinter Jet
	for i in range(4):
		var smoke_pos = pos - dir * (25.0 + float(i) * 14.0)
		var sa = 0.35 - float(i) * 0.08
		draw_circle(smoke_pos, 5.0 + float(i)*2.5, Color(0.75,0.72,0.68, sa))

	# Jet-Körper (elongiertes Rechteck in Flugrichtung)
	var right = dir.rotated(PI*0.5)
	var nose  = pos + dir * 28.0
	var tail  = pos - dir * 22.0

	# Rumpf
	var body = PackedVector2Array([
		nose,
		pos + right * 6.0 - dir * 8.0,
		tail + right * 3.0,
		tail - right * 3.0,
		pos - right * 6.0 - dir * 8.0,
	])
	draw_colored_polygon(body, jet_c)

	# Delta-Flügel
	var wing_l = PackedVector2Array([
		pos - dir * 4.0,
		pos + right * 22.0 - dir * 18.0,
		pos + right * 8.0  + dir * 2.0,
	])
	var wing_r = PackedVector2Array([
		pos - dir * 4.0,
		pos - right * 22.0 - dir * 18.0,
		pos - right * 8.0  + dir * 2.0,
	])
	draw_colored_polygon(wing_l, jet_c.darkened(0.15))
	draw_colored_polygon(wing_r, jet_c.darkened(0.15))

	# Leitwerk
	var tail_l = PackedVector2Array([
		tail, tail + right * 10.0 + dir * 8.0, tail + right * 3.0
	])
	var tail_r = PackedVector2Array([
		tail, tail - right * 10.0 + dir * 8.0, tail - right * 3.0
	])
	draw_colored_polygon(tail_l, jet_c.darkened(0.2))
	draw_colored_polygon(tail_r, jet_c.darkened(0.2))

	# Cockpit (blaues Dreieck)
	draw_colored_polygon(PackedVector2Array([
		nose - dir * 10.0 + right * 4.0,
		nose - dir * 10.0 - right * 4.0,
		nose - dir * 22.0,
	]), cockpit)

	# US-Farben auf Flügel (rote Streifen)
	draw_line(pos + right*10.0 - dir*10.0, pos + right*18.0 - dir*16.0, red_c, 2)
	draw_line(pos - right*10.0 - dir*10.0, pos - right*18.0 - dir*16.0, red_c, 2)

	# Triebwerks-Nachbrenner
	var eng_glow = Color(1.0, 0.55, 0.1, 0.85)
	draw_circle(tail - dir * 2.0, 5, eng_glow)
	draw_circle(tail - dir * 8.0, 3, Color(1.0, 0.85, 0.4, 0.6))

func _draw_luegens() -> void:
	for l in _luegens:
		var lp   = to_local(l["pos"])
		var wobx = sin(l["wobble"]) * 3.0
		var woby = cos(l["wobble"] * 1.3) * 3.0
		# Sprechblase (orangefarbene Kugel)
		draw_circle(lp + Vector2(wobx, woby), 10, Color(1.0, 0.62, 0.12))
		draw_circle(lp + Vector2(wobx, woby), 10, Color(1.0, 0.80, 0.20, 0.5))
		# Schwanz der Sprechblase
		draw_colored_polygon(PackedVector2Array([
			lp + Vector2(wobx-4, woby+8),
			lp + Vector2(wobx+4, woby+8),
			lp + Vector2(wobx+8, woby+16),
		]), Color(1.0, 0.62, 0.12))
		# Wellenlinien im Inneren (= Lügen / Blabla)
		for wi in range(3):
			var wy = -4.0 + float(wi) * 4.0
			draw_line(
				lp + Vector2(-5 + wobx, wy + woby),
				lp + Vector2(5  + wobx, wy + woby),
				Color(0.20, 0.10, 0.04, 0.85), 1.5
			)

# ── Todesanimation ────────────────────────────────────────────────────────────
func _draw_death() -> void:
	var t     = _death_anim_time
	var suit  = Color(0.08, 0.10, 0.24).darkened(0.3)
	var orange = Color(0.82, 0.44, 0.12)
	var charr  = Color(0.12, 0.08, 0.06)
	var blood  = Color(0.70, 0.04, 0.04)
	var red_c  = Color(0.70, 0.04, 0.04)

	var fall = min(t * 48.0, 36.0)
	var lean = min(t * 2.0,  1.0)

	if t > 0.3:
		draw_circle(Vector2(0, 34), min((t-0.3)*38.0, 30.0), Color(blood.r,blood.g,blood.b,0.68))

	# Körper kippt
	draw_rect(Rect2(-14+fall*0.25, 14+fall*0.45, 11, 14), suit)
	draw_rect(Rect2(3+fall*0.25,   14+fall*0.45, 11, 14), suit)
	draw_rect(Rect2(-16+fall*0.3*lean, -12+fall*lean, 32, 26), suit)
	# Krawatte weht
	draw_line(Vector2(fall*0.4, -8+fall*0.5), Vector2(fall*0.4+6, 18+fall*0.6), red_c, 5)
	# Kopf rollt weg
	draw_circle(Vector2(fall*0.55, -28+fall*0.88), 20, orange)
	if _charred:
		draw_circle(Vector2(fall*0.55-6, -26+fall*0.88), 6, Color(charr.r,charr.g,charr.b,0.75))
	# MAGA-Haare fliegen weg
	var hx = -fall * 0.8;  var hy = -44.0 - t * 50.0
	for i in range(5):
		draw_line(
			Vector2(hx + float(i)*6, hy),
			Vector2(hx + float(i)*6 - 8, hy - 12),
			Color(0.88, 0.78, 0.22), 3
		)

	modulate.a = 1.0 - max(0.0, (t - 1.2) / 0.4)
