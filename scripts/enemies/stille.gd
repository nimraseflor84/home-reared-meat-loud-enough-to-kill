extends "res://scripts/enemies/enemy_base.gd"

# Stille: bewegen sich in lockerem Pulk - sucht die naechsten Stille-Geschwister
# und gleicht die eigene Bewegungsrichtung leicht an. Macht sie als Gruppe
# bedrohlicher und unterscheidet sie vom Solo-Verhalten des Headbangers.
const _FLOCK_RADIUS: float = 90.0
const _FLOCK_WEIGHT: float = 0.35

func _ready() -> void:
	enemy_id = "stille"
	max_hp = 30.0
	damage = 10.0
	move_speed = 80.0
	score_value = 100
	add_to_group("enemies")
	_death_anim_duration = 0.70
	super._ready()

func _move_toward_target(_delta: float) -> void:
	if not is_instance_valid(target):
		return
	var to_target: Vector2 = (target.global_position - global_position).normalized()
	# Mit anderen Stille-Geschwistern flocken: durchschnittliche Richtung der
	# nahen Stille im Radius. Spaert die Hard-Combat-Phasen ein wenig auf.
	var flock_sum: Vector2 = Vector2.ZERO
	var flock_count: int = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e):
			continue
		if e.get("enemy_id") != "stille":
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d > 0.0 and d < _FLOCK_RADIUS:
			flock_sum += (e.global_position - global_position).normalized()
			flock_count += 1
	var move_dir: Vector2 = to_target
	if flock_count > 0:
		var flock_dir: Vector2 = (flock_sum / float(flock_count))
		move_dir = (to_target + flock_dir * _FLOCK_WEIGHT).normalized()
	velocity = move_dir * move_speed * _slow_factor
	move_and_slide()

func _draw() -> void:
	if _dying: _draw_death(); return
	var flash    = _hit_flash > 0
	# -- South Park Stil --
	var body_col = Color(0.62, 0.62, 0.65) if not flash else Color.WHITE
	var dark     = Color(0.28, 0.28, 0.32)
	var _wc   = sin(_anim_time * 3.5)
	var bob   = _wc * 1.2
	var leg_r = _wc * 8.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.65
	var arm_l = _wc * 0.65

	# Schuhe (breit, flach)
	draw_rect(Rect2(-12, 21 + leg_l * 0.3 + bob, 11, 4), Color(0.20, 0.20, 0.24))
	draw_rect(Rect2(-1,  21 + leg_r * 0.3 + bob, 11, 4), Color(0.20, 0.20, 0.24))

	# Beine (grau)
	draw_rect(Rect2(-9, 12 + leg_l * 0.25 + bob, 7, 10), dark)
	draw_rect(Rect2(2,  12 + leg_r * 0.25 + bob, 7, 10), dark)

	# Koerper (grauer Umhang)
	draw_rect(Rect2(-10, -6 + bob, 20, 18), body_col)

	# Arme (Stubs)
	draw_rect(Rect2(-17, -3 + arm_l + bob, 7, 11), body_col)
	draw_rect(Rect2(10,  -3 + arm_r + bob, 7, 11), body_col)

	# Mitten-Haende (SP: runde Klumpen)
	draw_circle(Vector2(-16, 7 + arm_l + bob), 5, body_col)
	draw_circle(Vector2(16,  7 + arm_r + bob), 5, body_col)

	# Kopf (rund, grau)
	draw_circle(Vector2(0, -20 + bob * 0.4), 14, body_col)

	# X-Augen (Stille-Symbol, ikonisch)
	var eye_r = 3.5
	for ex in [-5.0, 5.0]:
		draw_line(Vector2(ex - eye_r, -22 + bob * 0.4 - eye_r), Vector2(ex + eye_r, -22 + bob * 0.4 + eye_r), dark, 2.0)
		draw_line(Vector2(ex + eye_r, -22 + bob * 0.4 - eye_r), Vector2(ex - eye_r, -22 + bob * 0.4 + eye_r), dark, 2.0)

	# Genaehter Mund (zugenaeht - Stille)
	draw_line(Vector2(-6, -13 + bob * 0.4), Vector2(6, -13 + bob * 0.4), dark, 1.5)
	for i in range(4):
		draw_line(Vector2(-4.5 + i * 3.0, -15 + bob * 0.4), Vector2(-4.0 + i * 3.0, -11 + bob * 0.4), dark, 1.5)

func _draw_death() -> void:
	var t   = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	var sc  = 1.0 - t * 0.50             # Koerper schrumpft (implodiert)
	var snk = t * 20.0                   # Koerper sinkt
	var body_col = Color(0.62, 0.62, 0.65)
	var dark     = Color(0.28, 0.28, 0.32)
	var blood    = Color(0.72, 0.0,  0.02)

	# Koerper (implodierend)
	draw_rect(Rect2(-10*sc, -6*sc + snk, 20*sc, 18*sc), body_col)
	draw_rect(Rect2(-17*sc, -3*sc + snk, 7*sc, 11*sc), body_col)
	draw_rect(Rect2( 10*sc, -3*sc + snk, 7*sc, 11*sc), body_col)
	# Kopf
	var hy = -20*sc + snk * 0.55
	draw_circle(Vector2(0, hy), 14*sc, body_col)
	# X-Augen (verzerrend)
	for ex in [-5.0*sc, 5.0*sc]:
		var er = (3.5 + t * 2.0) * sc
		draw_line(Vector2(ex-er, hy-2-er), Vector2(ex+er, hy-2+er), dark, 2.0)
		draw_line(Vector2(ex+er, hy-2-er), Vector2(ex-er, hy-2+er), dark, 2.0)
	# Naehte reissen auf - fliegen einzeln weg
	var my = hy - 13*sc
	for i in range(4):
		var fly_t = clamp(t * 5.5 - float(i) * 0.7, 0.0, 1.0)
		var sx = -4.5 + float(i) * 3.0
		if fly_t < 0.9:
			draw_line(Vector2(sx, my-2), Vector2(sx+0.5, my+2), dark, 1.5)
		else:
			var off_x = sx + (float(i)-1.5) * fly_t * 16.0
			var off_y = my - fly_t * 18.0
			draw_line(Vector2(off_x, off_y), Vector2(off_x+1, off_y+4), dark, 1.5)
	# Mund reisst auf - stummer Schrei mit Blut
	var open_r = t * 6.5
	draw_arc(Vector2(0, my+1), max(0.5, open_r), 0, PI, 8, Color(0.15,0.0,0.0), 4.5)
	draw_rect(Rect2(-open_r, my+1, open_r*2, open_r*0.9), Color(0.15,0.0,0.0))
	for j in range(5):
		var bx = -4.0 + float(j)*2.0
		draw_line(Vector2(bx, my+4), Vector2(bx+sin(float(j))*2, my+4+t*(9+float(j)*4)), blood, 2.0)
	# Graue Splitter fliegen heraus
	for i in range(9):
		var a = float(i)*TAU/9.0
		var d = 4.0 + t*44.0
		var sz = 4.0 - t*2.6
		if sz > 0.1:
			draw_circle(Vector2(cos(a),sin(a))*d, sz, body_col)
	# Blutlache
	draw_circle(Vector2(0, 20), t*18.0, Color(0.52,0.0,0.01,0.65))
