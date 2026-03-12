extends EnemyBase

func _ready() -> void:
	max_hp = 120.0
	damage = 20.0
	move_speed = 84.0
	score_value = 250
	enemy_id = "waerter"
	_death_anim_duration = 0.68
	super._ready()

func _on_dying_process(_delta: float) -> void:
	var t = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	# Fällt steif rückwärts um
	rotation = -t * PI * 0.48

func _draw() -> void:
	if _dying: _draw_death(); return
	var flash     = _hit_flash > 0
	# ── South Park Stil (Gefängniswärter) ──
	var body_col  = Color(0.10, 0.14, 0.42) if not flash else Color.WHITE
	var badge_col = Color(0.90, 0.76, 0.10)
	var skin_col  = Color(0.98, 0.82, 0.66)

	# Lauf-Animation
	var bob      = sin(_anim_time * 6.5) * 2.2
	var leg_r    = sin(_anim_time * 6.5) * 9.0   # rechtes Bein vor/zurück
	var leg_l    = -leg_r                          # linkes Bein entgegengesetzt
	var arm_r    = -leg_r * 0.7                    # Arme gegenläufig
	var arm_l    = leg_r * 0.7

	# Schuhe (animiert mit Beinen)
	draw_rect(Rect2(-14, 27 + leg_l * 0.4 + bob, 13, 5), Color(0.08, 0.06, 0.04))
	draw_rect(Rect2(-1,  27 + leg_r * 0.4 + bob, 13, 5), Color(0.08, 0.06, 0.04))

	# Beine (animiert)
	draw_rect(Rect2(-11, 14 + leg_l * 0.3 + bob, 9, 14), Color(0.06, 0.09, 0.30))
	draw_rect(Rect2(2,   14 + leg_r * 0.3 + bob, 9, 14), Color(0.06, 0.09, 0.30))

	# Uniform-Körper
	draw_rect(Rect2(-12, -8 + bob, 24, 22), body_col)

	# Gürtel
	draw_rect(Rect2(-12, 10 + bob, 24, 5), Color(0.14, 0.10, 0.04))
	draw_rect(Rect2(-4,   9 + bob,  8, 7), Color(0.60, 0.50, 0.10))

	# Abzeichen (Kreis-in-Kreis)
	draw_circle(Vector2(-5, 1 + bob), 6, badge_col)
	draw_circle(Vector2(-5, 1 + bob), 4, body_col)
	draw_circle(Vector2(-5, 1 + bob), 2, badge_col)

	# Arme (animiert, schwingen beim Laufen)
	draw_rect(Rect2(-20, -3 + arm_l + bob, 8, 15), body_col)
	draw_rect(Rect2(12,  -3 + arm_r + bob, 8, 15), body_col)

	# Hände
	draw_circle(Vector2(-19, 11 + arm_l + bob), 6, Color(0.88, 0.72, 0.56))
	draw_circle(Vector2(19,  11 + arm_r + bob), 6, Color(0.88, 0.72, 0.56))

	# Knüppel rechts (schwingt mit Arm)
	draw_line(Vector2(20, 6 + arm_r + bob), Vector2(28, 20 + arm_r + bob), Color(0.35, 0.20, 0.05), 5)
	draw_circle(Vector2(28, 20 + arm_r + bob), 4, Color(0.35, 0.20, 0.05))

	# Kopf (groß, South Park) – bleibt relativ stabil
	draw_circle(Vector2(0, -22 + bob * 0.4), 15, skin_col)

	# Dienstmütze
	draw_rect(Rect2(-16, -36 + bob * 0.4, 32, 12), body_col)
	draw_rect(Rect2(-18, -26 + bob * 0.4, 36,  4), body_col)
	draw_circle(Vector2(0, -30 + bob * 0.4), 4, badge_col)

	# Strenge Augenbrauen
	draw_line(Vector2(-9, -28 + bob * 0.4), Vector2(-2, -26 + bob * 0.4), Color(0.10, 0.08, 0.04), 2.5)
	draw_line(Vector2(2,  -26 + bob * 0.4), Vector2(9,  -28 + bob * 0.4), Color(0.10, 0.08, 0.04), 2.5)

	# Augen
	var tilt = 0.25; var ew = 5.5; var eh = 3.5
	var lepts = PackedVector2Array(); var repts = PackedVector2Array()
	for i in range(10):
		var a = i * TAU / 10.0; var ox = cos(a) * ew; var oy = sin(a) * eh
		lepts.append(Vector2(-6 + ox*cos(tilt) - oy*sin(tilt), -24 + bob * 0.4 + ox*sin(tilt) + oy*cos(tilt)))
		repts.append(Vector2(6 + ox*cos(-tilt) - oy*sin(-tilt), -24 + bob * 0.4 + ox*sin(-tilt) + oy*cos(-tilt)))
	draw_colored_polygon(lepts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_colored_polygon(repts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_circle(Vector2(-6, -24 + bob * 0.4), 2.0, Color(0.08, 0.08, 0.08))
	draw_circle(Vector2(6,  -24 + bob * 0.4), 2.0, Color(0.08, 0.08, 0.08))

	# Dünner, strenger Mund
	draw_line(Vector2(-5, -16 + bob * 0.4), Vector2(5, -16 + bob * 0.4), Color(0.20, 0.10, 0.08), 2.0)

func _draw_death() -> void:
	var t        = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	var body_col = Color(0.10, 0.14, 0.42)
	var badge_col = Color(0.90, 0.76, 0.10)
	var skin_col  = Color(0.98, 0.82, 0.66)
	var blood     = Color(0.72, 0.0,  0.02)

	# Körper (Rotation durch _on_dying_process)
	draw_rect(Rect2(-12, -8,  24, 22), body_col)
	draw_rect(Rect2(-11, 14,   9, 14), Color(0.06,0.09,0.30))
	draw_rect(Rect2(  2, 14,   9, 14), Color(0.06,0.09,0.30))
	draw_rect(Rect2(-12, 10,  24,  5), Color(0.14,0.10,0.04))
	# Arme (steif ausgestreckt)
	draw_rect(Rect2(-20, -3, 8, 15), body_col)
	draw_rect(Rect2( 12, -3, 8, 15), body_col)
	draw_circle(Vector2(-19, 11), 6, Color(0.88,0.72,0.56))
	draw_circle(Vector2( 19, 11), 6, Color(0.88,0.72,0.56))
	# Kopf (rückwärts fallend)
	draw_circle(Vector2(0, -22), 15, skin_col)
	# Mütze
	draw_rect(Rect2(-16, -36, 32, 12), body_col)
	draw_rect(Rect2(-18, -26, 36,  4), body_col)
	# Abzeichen FLIEGT ab (nimmt an Rotation nicht teil – bewegt sich in lokalem Raum)
	var bx = -5.0 + t*28.0
	var by =  1.0 - t*32.0
	draw_circle(Vector2(bx, by), 6*(1.0-t*0.7), badge_col)
	draw_circle(Vector2(bx, by), 4*(1.0-t*0.7), body_col)
	draw_circle(Vector2(bx, by), 2*(1.0-t*0.7), badge_col)
	# Knüppel fliegt weg
	var kx = 20.0 + t*40.0
	var ky =  6.0 + t*25.0
	draw_line(Vector2(kx, ky), Vector2(kx+7, ky+12*(1.0-t)), Color(0.35,0.20,0.05), 5)
	draw_circle(Vector2(kx+7, ky+12*(1.0-t)), 4, Color(0.35,0.20,0.05))
	# BLUT – Kopfwunde (platzt beim Aufprall)
	for k in range(6):
		var ba  = -PI*0.6 + float(k)*PI*0.24
		var bl  = t*(10.0 + float(k)*4.0)
		draw_line(Vector2(0,-22), Vector2(cos(ba)*bl, -22+sin(ba)*bl), blood, 2.8)
	draw_circle(Vector2(0, -22), t*12.0, Color(0.52,0.0,0.01,0.72))
