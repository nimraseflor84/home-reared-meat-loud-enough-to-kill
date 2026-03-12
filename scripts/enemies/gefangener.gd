extends EnemyBase

# Gefangener – spawnt beim "Gefängnisausbruch" des Gefchefs
# Stürmt mit Stichwaffe auf Spieler zu, schneller Kontaktschaden

var _shiv_flash: float = -1.0   # kurze Stich-Animation

func _ready() -> void:
	enemy_id    = "gefangener"
	max_hp      = 45.0
	damage      = 22.0
	move_speed  = 330.0
	score_value = 120
	super._ready()

# Schnellerer Kontaktschaden als Basisklasse (0.32 statt 0.5 s)
func _check_contact_damage(delta: float) -> void:
	contact_damage_timer += delta
	if contact_damage_timer >= 0.32:
		contact_damage_timer = 0.0
		if is_instance_valid(target) and \
				global_position.distance_to(target.global_position) < 36:
			if target.has_method("take_damage"):
				target.take_damage(damage)
			_shiv_flash = 0.0
			AudioManager.play_hit_sfx()

func _process(delta: float) -> void:
	if _shiv_flash >= 0.0:
		_shiv_flash += delta
		if _shiv_flash >= 0.18:
			_shiv_flash = -1.0
	super._process(delta)

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if _dying:
		return
	if not is_alive:
		return

	var bob    = sin(_anim_time * 11.0) * 3.5   # schneller Laufrhythmus
	var leg_r  = sin(_anim_time * 11.0) * 13.0  # starke Beinbewegung
	var leg_l  = -leg_r
	var arm_r  = -leg_r * 0.85
	var arm_l  = leg_r * 0.85
	var flash  = _hit_flash > 0
	var skin  = Color(0.88, 0.70, 0.55) if not flash else Color.WHITE
	var suit  = Color(0.88, 0.48, 0.06)
	var dsuit = Color(0.62, 0.30, 0.02)
	var metal = Color(0.75, 0.75, 0.78)
	var chain = Color(0.55, 0.55, 0.58)

	# Stiefel (animiert)
	draw_rect(Rect2(-13, 26 + leg_l * 0.4 + bob, 11, 6), Color(0.18, 0.12, 0.04))
	draw_rect(Rect2(2,   26 + leg_r * 0.4 + bob, 11, 6), Color(0.18, 0.12, 0.04))
	# Beine (animiert)
	draw_rect(Rect2(-12, 12 + leg_l * 0.3 + bob, 10, 15), suit)
	draw_rect(Rect2(2,   12 + leg_r * 0.3 + bob, 10, 15), suit)
	# Torso
	draw_rect(Rect2(-14, -10+bob, 28, 24), suit)
	# Nummern-Streifen auf Brust
	draw_rect(Rect2(-6, -6+bob, 12, 4), dsuit)
	draw_rect(Rect2(-6,  0+bob, 12, 4), dsuit)
	# Arme (gegenläufig zu Beinen, vorwärts gestreckt beim Rennen)
	draw_rect(Rect2(-22, -4 + arm_l + bob, 8, 14), suit)
	draw_rect(Rect2(14,  -4 + arm_r + bob, 8, 14), suit)
	# Hände
	draw_circle(Vector2(-20, 9 + arm_l + bob), 6, skin)
	draw_circle(Vector2(20,  9 + arm_r + bob), 6, skin)
	# Zerbrochene Handfessel links (folgt linker Hand)
	draw_arc(Vector2(-20, 9 + arm_l + bob), 8, 0.0, PI * 1.4, 8, chain, 3)
	draw_line(
		Vector2(-20 + cos(PI*1.4)*8, 9 + arm_l + bob + sin(PI*1.4)*8),
		Vector2(-20 + cos(PI*1.4)*8 - 5, 9 + arm_l + bob + sin(PI*1.4)*8 + 4),
		chain, 3
	)

	# Shiv in rechter Hand (folgt rechter Hand)
	var stab = _shiv_flash >= 0.0
	var sx   = 20.0 + (8.0 if stab else 0.0)
	var sy   = 9.0 + arm_r - (6.0 if stab else 0.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(sx,    sy-4+bob),
		Vector2(sx+14, sy-10+bob),
		Vector2(sx,    sy+4+bob)
	]), metal)
	draw_rect(Rect2(sx-8, sy-3+bob, 8, 6), Color(0.28, 0.16, 0.06))

	# Kopf (geschoren, grimmig)
	draw_circle(Vector2(0, -22+bob), 14, skin)
	draw_circle(Vector2(-5, -24+bob), 4,   Color(0.96, 0.94, 0.88))
	draw_circle(Vector2(5,  -24+bob), 4,   Color(0.96, 0.94, 0.88))
	draw_circle(Vector2(-5, -24+bob), 2,   Color(0.08, 0.05, 0.03))
	draw_circle(Vector2(5,  -24+bob), 2,   Color(0.08, 0.05, 0.03))
	# Wütende Augenbrauen
	draw_line(Vector2(-9, -30+bob), Vector2(-1, -27+bob), Color(0.2,0.12,0.04), 3)
	draw_line(Vector2(1,  -27+bob), Vector2(9,  -30+bob), Color(0.2,0.12,0.04), 3)
	# Gefletscht – Zähne sichtbar
	draw_arc(Vector2(0, -18+bob), 5, 0.15, PI-0.15, 5, Color(0.1,0.05,0.02), 4)
	for tx in [-4.0, 0.0, 4.0]:
		draw_line(Vector2(tx, -17+bob), Vector2(tx, -13+bob), Color(0.92,0.90,0.85), 2)
