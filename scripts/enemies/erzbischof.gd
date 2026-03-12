extends EnemyBase

# Erzbischof Viktor Stummbert
# Angriff:   Heiligenschriften werfen (Fächer aus 2-3 Büchern)
# Spezial:   Tornado-Gebet – alle Sektierer beten zusammen →
#            gewaltiger Tornado fliegt auf den Spieler zu

const BOOK_CD       = 2.2
const BOOK_SPEED    = 240.0
const BOOK_RANGE    = 600.0
const GEBET_CD      = 18.0
const PHASE2_HP     = 0.5

var _book_timer:   float = 1.5
var _gebet_timer:  float = 10.0   # erstes Gebet nach 10 s
var _phase2:       bool  = false
var _praying:      bool  = false
var _pray_time:    float = 0.0
var _pray_duration: float = 2.8   # Sekunden Aufwärmen

# Tornado: {pos, vel, radius, dmg}
var _tornado: Dictionary = {}
var _tornado_active: bool = false

# Bücher: {pos, vel, angle, angle_vel, dmg}
var _books: Array = []

func _ready() -> void:
	enemy_id             = "erzbischof"
	max_hp               = 820.0
	damage               = 30.0
	move_speed           = 36.0
	score_value          = 2200
	_death_anim_duration = 1.8
	add_to_group("bosses")
	super._ready()

func _process(delta: float) -> void:
	if not is_alive or _dying:
		super._process(delta)
		return

	# Bücher bewegen
	for i in range(_books.size() - 1, -1, -1):
		var bk = _books[i]
		bk["pos"]   += bk["vel"] * delta
		bk["angle"] += bk["angle_vel"] * delta
		var too_far = bk["pos"].distance_to(global_position) > BOOK_RANGE
		var hit     = false
		if is_instance_valid(target):
			if bk["pos"].distance_to(target.global_position) < 22.0:
				if target.has_method("take_damage"):
					target.take_damage(bk["dmg"])
				hit = true
		if hit or too_far:
			_books.remove_at(i)

	# Tornado bewegen
	if _tornado_active and _tornado.size() > 0:
		_tornado["pos"] += _tornado["vel"] * delta
		if is_instance_valid(target):
			if _tornado["pos"].distance_to(target.global_position) < _tornado["radius"] + 18.0:
				if target.has_method("take_damage"):
					target.take_damage(_tornado["dmg"] * delta)
				if target.has_method("apply_knockback"):
					var kdir = (target.global_position - _tornado["pos"]).normalized()
					target.apply_knockback(kdir * 350.0)
		# Tornado erlischt bei Bildschirmrand
		var vp = get_viewport().get_visible_rect()
		var tp = _tornado["pos"]
		if tp.x < -80 or tp.x > vp.size.x + 80 or tp.y < -80 or tp.y > vp.size.y + 80:
			_tornado_active = false
			_tornado.clear()

	super._process(delta)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if not _phase2 and current_hp <= max_hp * PHASE2_HP:
		_phase2    = true
		move_speed = 58.0
		_book_timer = 0.0

	if not _praying:
		_book_timer += delta
		if is_instance_valid(target) and _book_timer >= BOOK_CD:
			var dist = global_position.distance_to(target.global_position)
			if dist > 65.0:
				_book_timer = 0.0
				_throw_books()

		_gebet_timer -= delta
		if _gebet_timer <= 0.0:
			_gebet_timer = GEBET_CD
			_start_gebet()
	else:
		# Während des Gebets: Erzbischof bleibt stehen und betet
		_pray_time += delta
		# Sektierer zur Mitte locken
		_call_sektierer()
		if _pray_time >= _pray_duration:
			_fire_tornado()
			_praying   = false
			_pray_time = 0.0

	super._physics_process(delta)

func _move_toward_target(delta: float) -> void:
	if _praying:
		velocity = Vector2.ZERO
		return
	super._move_toward_target(delta)

func _throw_books() -> void:
	if not is_instance_valid(target):
		return
	var dir  = (target.global_position - global_position).normalized()
	var fan  = [-0.22, 0.0, 0.22] if _phase2 else [-0.15, 0.15]
	for a in fan:
		_books.append({
			"pos":       global_position + dir.rotated(a) * 35.0,
			"vel":       dir.rotated(a) * BOOK_SPEED,
			"angle":     0.0,
			"angle_vel": randf_range(4.0, 7.0) * (1.0 if a >= 0.0 else -1.0),
			"dmg":       damage * 0.80,
		})
	AudioManager.play_projectile_sfx(0)

func _start_gebet() -> void:
	_praying   = true
	_pray_time = 0.0
	AudioManager.play_boss_siren_sfx()

func _call_sektierer() -> void:
	# Sektierer auf dem Bildschirm bewegen sich für kurze Zeit zum Erzbischof
	var sects = get_tree().get_nodes_in_group("enemies")
	for s in sects:
		if s.has_method("_move_toward_target") and s.enemy_id == "sektierer":
			s.target = self   # kurzzeitig zum Erzbischof navigieren

func _fire_tornado() -> void:
	if not is_instance_valid(target):
		_praying = false
		return
	var dir = (target.global_position - global_position).normalized()
	_tornado = {
		"pos":    global_position + dir * 50.0,
		"vel":    dir * 260.0,
		"radius": 38.0,
		"dmg":    damage * 1.4,
	}
	_tornado_active = true
	# Sektierer bekommen ihren echten Target zurück
	var sects = get_tree().get_nodes_in_group("enemies")
	for s in sects:
		if s.has_method("_move_toward_target") and s.enemy_id == "sektierer":
			var players = get_tree().get_nodes_in_group("players")
			if players.size() > 0:
				s.target = players[0]

func _draw() -> void:
	if _dying: _draw_death(); return
	if not is_alive: return

	var bob   = sin(_anim_time * 2.2) * 2.0
	var flash = _hit_flash > 0

	var robe   = Color(0.12, 0.10, 0.28) if not flash else Color.WHITE
	var dark   = Color(0.06, 0.05, 0.14)
	var gold   = Color(0.88, 0.72, 0.12)
	var white  = Color(0.94, 0.92, 0.88)
	var beard  = Color(0.88, 0.86, 0.84)

	# Stab (rechts)
	draw_line(Vector2(28, 40 + bob), Vector2(28, -60 + bob), gold, 5)
	draw_circle(Vector2(28, -58 + bob), 8, gold)
	draw_line(Vector2(22, -64 + bob), Vector2(34, -64 + bob), gold, 4)
	draw_line(Vector2(28, -64 + bob), Vector2(28, -72 + bob), gold, 4)

	# Schuhe (groß)
	draw_rect(Rect2(-16, 36 + bob, 14, 6), dark)
	draw_rect(Rect2(2,   36 + bob, 14, 6), dark)

	# Robe (breite Soutane)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -12 + bob), Vector2(18, -12 + bob),
		Vector2(24,  42 + bob),  Vector2(-24, 42 + bob),
	]), robe)
	# Goldene Borte an der Robe
	draw_line(Vector2(-18, -12 + bob), Vector2(-24, 42 + bob), gold, 2)
	draw_line(Vector2(18,  -12 + bob), Vector2(24,  42 + bob), gold, 2)
	# Großes Kreuz auf der Brust
	draw_line(Vector2(0, -6 + bob), Vector2(0, 18 + bob),  gold, 4)
	draw_line(Vector2(-9, 4 + bob), Vector2(9,  4 + bob),  gold, 4)

	# Schulterumhang (Epitrachilion)
	draw_rect(Rect2(-22, -14 + bob, 44, 8), white)
	draw_rect(Rect2(-5,  -14 + bob, 10, 58), white)

	# Arme
	draw_rect(Rect2(-28, -10 + bob, 10, 18), robe)
	draw_rect(Rect2(18,  -10 + bob, 10, 18), robe)
	# Hände
	draw_circle(Vector2(-25, 8 + bob), 7, Color(0.78, 0.66, 0.56))
	draw_circle(Vector2(25,  8 + bob), 7, Color(0.78, 0.66, 0.56))

	# Langer weißer Bart
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -18 + bob), Vector2(10, -18 + bob),
		Vector2(8,   8 + bob),   Vector2(-8,  8 + bob),
	]), beard)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, 4 + bob), Vector2(8, 4 + bob),
		Vector2(4,  22 + bob), Vector2(-4, 22 + bob),
	]), beard)

	# Kopf
	draw_circle(Vector2(0, -30 + bob), 18, Color(0.80, 0.68, 0.58))

	# Orthodoxe Mitra (hohe Krone)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -44 + bob), Vector2(16, -44 + bob),
		Vector2(12,  -70 + bob), Vector2(-12, -70 + bob),
	]), dark)
	draw_rect(Rect2(-18, -46 + bob, 36, 5), dark)
	draw_line(Vector2(-18, -41 + bob), Vector2(18, -41 + bob), gold, 3)
	# Kreuz auf der Mitra
	draw_line(Vector2(0, -68 + bob), Vector2(0, -50 + bob), gold, 3)
	draw_line(Vector2(-6, -61 + bob), Vector2(6, -61 + bob), gold, 3)
	# Edelsteine auf der Mitra
	for mi in range(5):
		var mx = -10.0 + mi * 5.0
		draw_circle(Vector2(mx, -47 + bob), 2.5, Color(0.6, 0.1, 0.8))

	# Augen (stechend)
	draw_rect(Rect2(-9, -33 + bob, 7, 4), white)
	draw_rect(Rect2(2,  -33 + bob, 7, 4), white)
	draw_circle(Vector2(-6, -32 + bob), 2, dark)
	draw_circle(Vector2(5,  -32 + bob), 2, dark)

	# Phase 2: Aureole (Heiligenschein)
	if _phase2:
		draw_arc(Vector2(0, -30 + bob), 30, 0, TAU, 18,
			Color(0.92, 0.78, 0.14, 0.55 + sin(_anim_time * 5.0) * 0.20), 4)

	# Bet-Animation
	if _praying:
		var pt      = _pray_time / _pray_duration
		var glow_a  = sin(pt * TAU * 3.0) * 0.25 + 0.30
		draw_circle(Vector2(0, -20 + bob), 55 * pt, Color(0.8, 0.75, 0.2, glow_a))
		# Energiestrahlen
		for ri in range(8):
			var ra = float(ri) / 8.0 * TAU + _anim_time * 2.5
			var rl = 20.0 + pt * 60.0
			draw_line(Vector2(0, -20 + bob),
				Vector2(cos(ra) * rl, -20 + bob + sin(ra) * rl),
				Color(0.9, 0.8, 0.2, (1.0 - pt) * 0.7), 2.0)

	_draw_books()
	_draw_tornado_local()

func _draw_books() -> void:
	var page  = Color(0.92, 0.90, 0.82)
	var cover = Color(0.22, 0.10, 0.48)
	var gold2 = Color(0.82, 0.68, 0.14)
	for bk in _books:
		var lp  = to_local(bk["pos"])
		var ang = bk["angle"]
		var hw = 12.0; var hh = 8.0
		var pts = PackedVector2Array([
			lp + Vector2(-hw, -hh).rotated(ang),
			lp + Vector2( hw, -hh).rotated(ang),
			lp + Vector2( hw,  hh).rotated(ang),
			lp + Vector2(-hw,  hh).rotated(ang),
		])
		draw_colored_polygon(pts, cover)
		var ipts = PackedVector2Array([
			lp + Vector2(-hw + 2, -hh + 1).rotated(ang),
			lp + Vector2( hw - 1, -hh + 1).rotated(ang),
			lp + Vector2( hw - 1,  hh - 1).rotated(ang),
			lp + Vector2(-hw + 2,  hh - 1).rotated(ang),
		])
		draw_colored_polygon(ipts, page)
		draw_line(lp + Vector2(0,-3).rotated(ang), lp + Vector2(0,3).rotated(ang), gold2, 2)
		draw_line(lp + Vector2(-3,0).rotated(ang), lp + Vector2(3,0).rotated(ang), gold2, 2)

func _draw_tornado_local() -> void:
	if not _tornado_active or _tornado.is_empty():
		return
	var lp = to_local(_tornado["pos"])
	var r  = _tornado["radius"]
	var at = _anim_time * 6.0
	# Spirale
	for li in range(12):
		var a   = float(li) / 12.0 * TAU + at
		var r1  = r * 0.3
		var r2  = r
		var off = float(li) / 12.0 * r * 0.6
		draw_line(
			lp + Vector2(cos(a) * r1, sin(a) * r1 + off),
			lp + Vector2(cos(a + 0.5) * r2, sin(a + 0.5) * r2 + off),
			Color(0.7, 0.6, 0.2, 0.65), 3.0)
	# Kern (goldenes Auge)
	draw_circle(lp, r * 0.25, Color(0.92, 0.80, 0.20, 0.85))
	# Äußerer Kreis
	draw_arc(lp, r, 0, TAU, 20, Color(0.5, 0.4, 0.1, 0.5), 5)

func _draw_death() -> void:
	var t     = _death_anim_time
	var robe  = Color(0.12, 0.10, 0.28)
	var gold  = Color(0.88, 0.72, 0.12)
	var blood = Color(0.70, 0.04, 0.04)

	var fall = min(t * 45.0, 42.0)
	var lean = min(t * 1.6, 1.0)

	if t > 0.4:
		draw_circle(Vector2(0, 42), min((t - 0.4) * 38.0, 30.0), Color(blood.r, blood.g, blood.b, 0.65))

	draw_colored_polygon(PackedVector2Array([
		Vector2(-18 + fall * 0.2 * lean, -12 + fall * lean),
		Vector2(18  + fall * 0.2 * lean, -12 + fall * lean),
		Vector2(24  + fall * 0.2 * lean, 42  + fall * lean),
		Vector2(-24 + fall * 0.2 * lean, 42  + fall * lean),
	]), robe)

	# Mitra fliegt hoch
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16 + t*18, -44 - t*60), Vector2(16 + t*18, -44 - t*60),
		Vector2(12  + t*18, -70 - t*60), Vector2(-12 + t*18, -70 - t*60),
	]), Color(robe.r, robe.g, robe.b, 1.0 - min(t * 0.8, 1.0)))

	# Stab fällt
	draw_line(Vector2(28 + t*30, 40 - t*20), Vector2(28 + t*60, -60 + t*80), gold, 5)

	# Bücher aus dem Umhang
	for i in range(8):
		var a = float(i) * TAU / 8.0
		var d = 6.0 + t * 80.0
		var bc = Color(0.22, 0.10, 0.48, 1.0 - min(t * 0.7, 1.0))
		draw_rect(Rect2(cos(a)*d - 9, sin(a)*d - 6, 18, 12), bc)

	modulate.a = 1.0 - max(0.0, (t - 1.5) / 0.3)
