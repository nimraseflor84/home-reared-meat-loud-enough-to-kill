extends EnemyBase

# Sektierer – wirft Heiligenschriften als Projektile
# Teil der Orthodoxen Sekte im Proberaum

const THROW_CD    = 2.8
const THROW_SPEED = 210.0
const THROW_RANGE = 480.0

var _throw_timer: float = 1.2
# {pos, vel, angle, angle_vel, dmg}
var _books: Array = []

func _ready() -> void:
	enemy_id             = "sektierer"
	max_hp               = 35.0
	damage               = 12.0
	move_speed           = 68.0
	score_value          = 120
	_death_anim_duration = 0.75
	add_to_group("enemies")
	super._ready()

func _process(delta: float) -> void:
	if not is_alive or _dying:
		super._process(delta)
		return

	for i in range(_books.size() - 1, -1, -1):
		var bk = _books[i]
		bk["pos"]   += bk["vel"] * delta
		bk["angle"] += bk["angle_vel"] * delta
		var too_far = bk["pos"].distance_to(global_position) > THROW_RANGE
		var hit     = false
		if is_instance_valid(target):
			if bk["pos"].distance_to(target.global_position) < 20.0:
				if target.has_method("take_damage"):
					target.take_damage(bk["dmg"])
				hit = true
		if hit or too_far:
			_books.remove_at(i)

	super._process(delta)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_throw_timer += delta
	if is_instance_valid(target) and _throw_timer >= THROW_CD:
		var dist = global_position.distance_to(target.global_position)
		if dist > 55.0 and dist < THROW_RANGE:
			_throw_timer = 0.0
			_throw_book()

	super._physics_process(delta)

func _throw_book() -> void:
	if not is_instance_valid(target):
		return
	var dir = (target.global_position - global_position).normalized()
	_books.append({
		"pos":       global_position + dir * 22.0,
		"vel":       dir * THROW_SPEED,
		"angle":     0.0,
		"angle_vel": randf_range(3.5, 6.0) * (1.0 if randf() > 0.5 else -1.0),
		"dmg":       damage * 0.7,
	})
	AudioManager.play_projectile_sfx(0)

func _draw() -> void:
	if _dying: _draw_death(); return
	var flash  = _hit_flash > 0
	var _wc    = sin(_anim_time * 5.0)   # langsamer Sektierer
	var bob    = _wc * 1.2
	var leg_r  = _wc * 7.0
	var leg_l  = -leg_r
	var arm_r  = -leg_r * 0.7
	var arm_l  = leg_r * 0.7

	var robe  = Color(0.14, 0.12, 0.30) if not flash else Color.WHITE
	var dark  = Color(0.08, 0.06, 0.18)
	var gold  = Color(0.82, 0.68, 0.14)
	var beard = Color(0.82, 0.80, 0.78)

	# Schuhe
	draw_rect(Rect2(-11, 28 + leg_l * 0.4 + bob, 10, 5), dark)
	draw_rect(Rect2(1,   28 + leg_r * 0.4 + bob, 10, 5), dark)

	# Robe (lang, breit) – folgt Torso-Bob
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, -8 + bob), Vector2(14, -8 + bob),
		Vector2(18, 32 + bob),  Vector2(-18, 32 + bob),
	]), robe)

	# Kreuz auf der Robe
	draw_line(Vector2(0, -2 + bob), Vector2(0, 14 + bob), gold, 3)
	draw_line(Vector2(-6, 4 + bob), Vector2(6, 4 + bob), gold, 3)

	# Arme (Ärmel)
	draw_rect(Rect2(-22, -4 + arm_l + bob, 8, 14), robe)
	draw_rect(Rect2(14,  -4 + arm_r + bob, 8, 14), robe)
	# Hände
	draw_circle(Vector2(-20, 10 + arm_l + bob), 5, Color(0.78, 0.66, 0.56))
	draw_circle(Vector2(20,  10 + arm_r + bob), 5, Color(0.78, 0.66, 0.56))

	# Bart
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -14 + bob * 0.4), Vector2(8, -14 + bob * 0.4),
		Vector2(6,  0 + bob * 0.4),   Vector2(-6, 0 + bob * 0.4),
	]), beard)

	# Kopf
	draw_circle(Vector2(0, -24 + bob * 0.4), 14, Color(0.80, 0.68, 0.58))

	# Orthodoxe Mütze (Kalimavkion – flacher Zylinder)
	draw_rect(Rect2(-12, -40 + bob * 0.4, 24, 18), dark)
	draw_rect(Rect2(-14, -40 + bob * 0.4, 28, 5),  dark)
	# Goldener Rand
	draw_line(Vector2(-14, -35 + bob * 0.4), Vector2(14, -35 + bob * 0.4), gold, 2)

	# Augen (fromm geschlossen oder stechend)
	draw_line(Vector2(-6, -27 + bob * 0.4), Vector2(-2, -25 + bob * 0.4), dark, 2)
	draw_line(Vector2(2,  -25 + bob * 0.4), Vector2(6,  -27 + bob * 0.4), dark, 2)

	# Fliegende Heiligenschriften
	_draw_books()

func _draw_books() -> void:
	var page  = Color(0.92, 0.90, 0.82)
	var cover = Color(0.22, 0.10, 0.48)
	var text  = Color(0.08, 0.04, 0.20)
	for bk in _books:
		var lp  = to_local(bk["pos"])
		var ang = bk["angle"]
		var hw = 10.0; var hh = 7.0
		var pts = PackedVector2Array([
			lp + Vector2(-hw, -hh).rotated(ang),
			lp + Vector2( hw, -hh).rotated(ang),
			lp + Vector2( hw,  hh).rotated(ang),
			lp + Vector2(-hw,  hh).rotated(ang),
		])
		draw_colored_polygon(pts, cover)
		# Seiten (weiß, leicht geöffnet)
		var ipts = PackedVector2Array([
			lp + Vector2(-hw + 2, -hh + 1).rotated(ang),
			lp + Vector2( hw - 1, -hh + 1).rotated(ang),
			lp + Vector2( hw - 1,  hh - 1).rotated(ang),
			lp + Vector2(-hw + 2,  hh - 1).rotated(ang),
		])
		draw_colored_polygon(ipts, page)
		# Textzeilen
		for li in range(3):
			var loff = Vector2(0, -2.5 + li * 2.5).rotated(ang)
			draw_line(lp + loff - Vector2(5, 0).rotated(ang),
				lp + loff + Vector2(5, 0).rotated(ang), text, 0.8)
		# Goldenes Kreuz auf Cover
		draw_line(lp + Vector2(0, -3).rotated(ang), lp + Vector2(0, 3).rotated(ang),
			Color(0.82, 0.68, 0.14), 1.5)
		draw_line(lp + Vector2(-3, 0).rotated(ang), lp + Vector2(3, 0).rotated(ang),
			Color(0.82, 0.68, 0.14), 1.5)

func _draw_death() -> void:
	var t     = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	var robe  = Color(0.14, 0.12, 0.30)
	var beard = Color(0.82, 0.80, 0.78)
	var blood = Color(0.70, 0.04, 0.04)

	# Robe auseinanderfallend
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14 - t*10, -8 - t*5), Vector2(14 + t*10, -8 - t*5),
		Vector2(18 + t*15, 32 + t*20), Vector2(-18 - t*15, 32 + t*20),
	]), Color(robe.r, robe.g, robe.b, 1.0 - t))
	# Bart fliegt weg
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8 - t*20, -14 - t*30), Vector2(8 - t*20, -14 - t*30),
		Vector2(6 - t*20, 0 - t*30), Vector2(-6 - t*20, 0 - t*30),
	]), Color(beard.r, beard.g, beard.b, 1.0 - t * 0.8))
	# Kopf
	draw_circle(Vector2(t * 18, -24 - t * 20), 14 * (1.0 - t * 0.5), Color(0.80, 0.68, 0.58))
	# Bücher fliegen aus dem Umhang
	for i in range(5):
		var a = float(i) * TAU / 5.0
		var d = 5.0 + t * 60.0
		draw_rect(Rect2(cos(a)*d - 7, sin(a)*d - 5, 14, 10), Color(0.22, 0.10, 0.48, 1.0 - t))
	# Blutlache
	draw_circle(Vector2(0, 25), t * 18.0, Color(0.52, 0.0, 0.01, 0.65))
	modulate.a = 1.0 - max(0.0, (t - 0.75) / 0.25)
