extends EnemyBase

var _push_timer: float = 0.0
const PUSH_INTERVAL = 1.8

func _ready() -> void:
	max_hp = 200.0
	damage = 28.0
	move_speed = 48.0
	score_value = 350
	enemy_id = "security"
	_death_anim_duration = 0.72
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	if not is_alive:
		return
	_push_timer += delta
	if _push_timer >= PUSH_INTERVAL:
		_push_timer = 0.0
		_push_player()

func _push_player() -> void:
	if not is_instance_valid(target):
		return
	if global_position.distance_to(target.global_position) < 60:
		var push_dir = (target.global_position - global_position).normalized()
		if target.has_method("take_damage"):
			target.take_damage(damage)
		if target.has_method("apply_knockback"):
			target.apply_knockback(push_dir * 400.0)

func _on_dying_process(_delta: float) -> void:
	var t = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	# Kippt wie ein Baum vorwärts
	rotation = t * PI * 0.50

func _draw() -> void:
	if _dying: _draw_death(); return
	var flash    = _hit_flash > 0
	# ── South Park Stil (Security Guard) ──
	var body_col = Color(0.08, 0.08, 0.10) if not flash else Color.WHITE
	var skin_col = Color(0.95, 0.78, 0.62) if not flash else Color.WHITE

	# Schwerer, langsamer Laufzyklus
	var _wc    = sin(_anim_time * 4.0)
	var bob    = _wc * 2.0
	var leg_r  = _wc * 8.0
	var leg_l  = -leg_r
	var arm_r  = -leg_r * 0.7
	var arm_l  = leg_r * 0.7

	# Schuhe (breit, flach)
	draw_rect(Rect2(-15, 31 + leg_l * 0.4 + bob, 14, 5), Color(0.06, 0.05, 0.05))
	draw_rect(Rect2(-1,  31 + leg_r * 0.4 + bob, 14, 5), Color(0.06, 0.05, 0.05))

	# Beine (massiv, flache Farbe)
	draw_rect(Rect2(-12, 18 + leg_l * 0.3 + bob, 10, 14), Color(0.10, 0.10, 0.12))
	draw_rect(Rect2(2,   18 + leg_r * 0.3 + bob, 10, 14), Color(0.10, 0.10, 0.12))

	# Breiter schwarzer Körper (South Park: Klotz)
	draw_rect(Rect2(-16, -10 + bob, 32, 28), body_col)

	# High-Vis Westen-Streifen (gelb)
	draw_rect(Rect2(-16, -2 + bob, 6, 20), Color(0.90, 0.60, 0.0, 0.7))
	draw_rect(Rect2(10,  -2 + bob, 6, 20), Color(0.90, 0.60, 0.0, 0.7))

	# SECURITY Linien-Andeutung
	for i in range(3):
		draw_line(Vector2(-8, -3 + i * 5 + bob), Vector2(8, -3 + i * 5 + bob), Color(0.9, 0.9, 0.9, 0.5), 1.5)

	# Arme (massiv, breite Stubs)
	draw_rect(Rect2(-28, -8 + arm_l + bob, 12, 22), body_col)
	draw_rect(Rect2(16,  -8 + arm_r + bob, 12, 22), body_col)

	# Mitten-Hände (SP: runde Klumpen)
	draw_circle(Vector2(-24, 13 + arm_l + bob), 7, Color(0.88, 0.72, 0.56))
	draw_circle(Vector2(24,  13 + arm_r + bob), 7, Color(0.88, 0.72, 0.56))

	# Kopf (geschorener Schädel)
	draw_circle(Vector2(0, -24 + bob * 0.4), 16, skin_col)

	# Glanz auf Glatze
	draw_arc(Vector2(-4, -32 + bob * 0.4), 7, -PI, 0, 6, Color(1.0, 1.0, 1.0, 0.15), 3.0)

	# Ohrhörer (Erkennungsmerkmal)
	draw_circle(Vector2(16, -22 + bob * 0.4), 4, Color(0.2, 0.2, 0.2))
	draw_line(Vector2(16, -18 + bob * 0.4), Vector2(18, -8 + bob * 0.4), Color(0.3, 0.3, 0.3), 1.5)

	# Sonnenbrille (2 schwarze Rechtecke)
	draw_rect(Rect2(-12, -28 + bob * 0.4, 10, 6), Color(0.04, 0.04, 0.06))
	draw_rect(Rect2(2,   -28 + bob * 0.4, 10, 6), Color(0.04, 0.04, 0.06))
	draw_line(Vector2(-2, -26 + bob * 0.4), Vector2(2, -26 + bob * 0.4), Color(0.15, 0.15, 0.18), 2.0)

	# Grimmiger Mund
	draw_arc(Vector2(0, -16 + bob * 0.4), 5, 0.3, PI - 0.3, 5, Color(0.30, 0.15, 0.10), 2.0)

func _draw_death() -> void:
	var t        = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	var body_col = Color(0.08, 0.08, 0.10)
	var skin_col = Color(0.95, 0.78, 0.62)
	var blood    = Color(0.72, 0.0,  0.02)

	# Massiver Körper (Rotation durch _on_dying_process – kippt wie ein Turm)
	draw_rect(Rect2(-16, -10, 32, 28), body_col)
	draw_rect(Rect2(-12,  18, 10, 14), Color(0.10,0.10,0.12))
	draw_rect(Rect2(  2,  18, 10, 14), Color(0.10,0.10,0.12))
	draw_rect(Rect2(-16,  -2,  6, 20), Color(0.90,0.60,0.0,0.7))
	draw_rect(Rect2( 10,  -2,  6, 20), Color(0.90,0.60,0.0,0.7))
	draw_rect(Rect2(-28,  -8, 12, 22), body_col)
	draw_rect(Rect2( 16,  -8, 12, 22), body_col)
	draw_circle(Vector2(-24, 13), 7, Color(0.88,0.72,0.56))
	draw_circle(Vector2( 24, 13), 7, Color(0.88,0.72,0.56))
	# Kopf (Glatze)
	draw_circle(Vector2(0, -24), 16, skin_col)
	# Sonnenbrille – ZERSPLITTERT (Fragmente fliegen)
	for i in range(4):
		var fx = (-12.0 + float(i)*6.0) + (float(i)-1.5)*t*22.0
		var fy = -28.0 - t*(8.0 + float(i)*6.0)
		draw_rect(Rect2(fx, fy, 5, 4), Color(0.04,0.04,0.06))
	# Ohrhörer fliegt weg
	draw_circle(Vector2(16+t*35, -22-t*28), 4*(1.0-t*0.6), Color(0.2,0.2,0.2))
	draw_line(Vector2(16+t*35, -18-t*28), Vector2(18+t*38, -8-t*20), Color(0.3,0.3,0.3), 1.5)
	# Aufprall-Impulsring (erscheint wenn er trifft)
	if t > 0.55:
		var it = (t-0.55)/0.45
		draw_arc(Vector2.ZERO, it*55.0, 0, TAU, 18, Color(0.65,0.65,0.65,(1.0-it)*0.50), 4.0)
		draw_arc(Vector2.ZERO, it*35.0, 0, TAU, 14, Color(0.50,0.50,0.50,(1.0-it)*0.35), 2.5)
	# RIESIGE Blutlache (massiver Körper = viel Blut)
	draw_circle(Vector2(0, 20), t*38.0, Color(0.52,0.0,0.01,0.82))
	# Blut spritzt radial bei Aufprall
	if t > 0.50:
		var bt = (t-0.50)/0.50
		for k in range(10):
			var ba  = float(k)*TAU/10.0
			var bl  = bt*(18.0 + float(k)*4.5)
			draw_circle(Vector2(cos(ba),sin(ba))*bl + Vector2(0,12), 4.0-bt*3.0, blood)
