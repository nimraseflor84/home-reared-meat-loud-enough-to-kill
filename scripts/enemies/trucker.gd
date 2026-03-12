extends EnemyBase

# Thunder-Trucker Heinz
# Angriff:   Bowie-Messer-Stich (Nahkampf)
# Spezial:   Steigt in Truck → 10 s lang Überfahren-Modus

const KNIFE_CD      = 1.6
const KNIFE_RANGE   = 72.0
const TRUCK_CD      = 13.0
const TRUCK_DUR     = 10.0    # Sekunden im Truck
const TRUCK_SPD     = 440.0   # Truck-Geschwindigkeit
const TRUCK_DMG_MUL = 4.0     # Schaden beim Überfahren
const TRUCK_W       = 72.0    # Truck Breite (Kollisionsbreite)
const TRUCK_H       = 120.0   # Truck Länge

# Modi
const M_FOOT  = 0   # zu Fuß
const M_ENTER = 1   # Einsteige-Animation (0.8 s)
const M_TRUCK = 2   # Truck aktiv (10 s)
const M_EXIT  = 3   # Aussteige-Animation (0.5 s)

var _knife_timer: float   = 0.8
var _knife_anim: float    = -1.0   # 0..0.35
var _truck_timer: float   = 8.0    # erster Truck nach 8 s

var _mode: int            = M_FOOT
var _mode_t: float        = 0.0
var _truck_active_t: float = 0.0   # 0..TRUCK_DUR

var _truck_pos: Vector2   = Vector2.ZERO
var _truck_dir: Vector2   = Vector2.DOWN
var _truck_hit: bool      = false   # pro Überfahrt einmal Schaden

var _phase2: bool         = false
var _dust: Array          = []

func _ready() -> void:
	enemy_id             = "trucker"
	max_hp               = 750.0
	damage               = 32.0
	move_speed           = 52.0
	score_value          = 1900
	_death_anim_duration = 1.6
	add_to_group("bosses")
	super._ready()

# ── Update ────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not is_alive or _dying:
		super._process(delta)
		return

	_mode_t += delta

	match _mode:
		M_ENTER:
			if _mode_t >= 0.8:
				_mode           = M_TRUCK
				_mode_t         = 0.0
				_truck_active_t = 0.0
				_truck_pos      = global_position
				_truck_dir      = _dir_to_target()
				_truck_hit      = false

		M_TRUCK:
			_truck_active_t += delta
			# Staub
			for _i in range(2):
				_dust.append({
					"pos":  _truck_pos + Vector2(randf_range(-28,28), randf_range(-10,10)),
					"vel":  -_truck_dir * randf_range(40,90) + Vector2(randf_range(-40,40), randf_range(-40,40)),
					"life": randf_range(0.2, 0.55),
					"sz":   randf_range(10.0, 22.0),
				})
			if _truck_active_t >= TRUCK_DUR:
				_mode   = M_EXIT
				_mode_t = 0.0

		M_EXIT:
			if _mode_t >= 0.5:
				_mode         = M_FOOT
				_mode_t       = 0.0
				_truck_timer  = TRUCK_CD
				global_position = _truck_pos

	# Staub
	for i in range(_dust.size() - 1, -1, -1):
		var d = _dust[i]
		d["life"] -= delta
		d["pos"]  += d["vel"] * delta
		d["vel"]  *= 0.88
		if d["life"] <= 0.0:
			_dust.remove_at(i)

	super._process(delta)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	if not is_instance_valid(target):
		var pl = get_tree().get_nodes_in_group("players")
		if pl.size() > 0: target = pl[0]

	if not _phase2 and current_hp <= max_hp * 0.5:
		_phase2    = true
		move_speed = 88.0

	match _mode:
		M_FOOT:
			_truck_timer -= delta
			if _truck_timer <= 0.0:
				_start_truck()

			_knife_timer += delta
			if is_instance_valid(target) and _knife_timer >= KNIFE_CD:
				if global_position.distance_to(target.global_position) < KNIFE_RANGE:
					_knife_timer = 0.0
					_do_knife()
			super._physics_process(delta)

		M_ENTER, M_EXIT:
			velocity = Vector2.ZERO
			move_and_slide()

		M_TRUCK:
			# Truck verfolgt den Spieler — dreht kontinuierlich nach
			if is_instance_valid(target):
				var desired = (_truck_pos.direction_to(target.global_position))
				_truck_dir  = _truck_dir.lerp(desired, delta * 1.8).normalized()
			_truck_pos += _truck_dir * TRUCK_SPD * delta

			# Bildschirm-Clamp für den Truck
			var vp = get_viewport_rect()
			_truck_pos.x = clamp(_truck_pos.x, 60, vp.size.x - 60)
			_truck_pos.y = clamp(_truck_pos.y, 60, vp.size.y - 60)

			# Spieler-Kollision mit Truck (Rechteck-Näherung)
			if is_instance_valid(target):
				var diff     = target.global_position - _truck_pos
				var forward  = diff.dot(_truck_dir)
				var sideways = abs(diff.dot(_truck_dir.rotated(PI * 0.5)))
				if forward > -TRUCK_H * 0.5 and forward < TRUCK_H * 0.6 \
						and sideways < TRUCK_W * 0.5:
					if not _truck_hit:
						_truck_hit = true
						target.take_damage(damage * TRUCK_DMG_MUL)
						target.apply_knockback(_truck_dir * 700.0)
						AudioManager.play_hit_sfx()
				else:
					_truck_hit = false   # reset für nächste Überfahrt

			# Heinz-Node bleibt unsichtbar am Truck
			global_position = _truck_pos

# ── Aktionen ──────────────────────────────────────────────────────────────────
func _do_knife() -> void:
	_knife_anim = 0.0
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage * 1.8)
		target.apply_knockback(
			(target.global_position - global_position).normalized() * 360.0
		)
	AudioManager.play_hit_sfx()

func _start_truck() -> void:
	_mode   = M_ENTER
	_mode_t = 0.0
	AudioManager.play_boss_siren_sfx()

func _dir_to_target() -> Vector2:
	if is_instance_valid(target):
		return (target.global_position - global_position).normalized()
	return Vector2.DOWN

func _on_dying_process(_delta: float) -> void:
	_dust.clear()
	_mode = M_FOOT

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if _dying:
		_draw_death()
		return
	if not is_alive:
		return

	# Staub
	for d in _dust:
		var lp = to_local(d["pos"])
		var al = d["life"] / 0.55
		draw_circle(lp, d["sz"] * al, Color(0.72, 0.60, 0.42, al * 0.5))

	match _mode:
		M_FOOT, M_ENTER, M_EXIT:
			var _wc   = sin(_anim_time * 3.5)
			var bob   = _wc * 1.5
			var leg_r = _wc * 9.0
			var leg_l = -leg_r
			var arm_r = -leg_r * 0.7
			var arm_l = leg_r * 0.7
			var flash = _hit_flash > 0
			_draw_heinz(bob, leg_l, leg_r, arm_l, arm_r, flash)
			if _knife_anim >= 0.0:
				_knife_anim += get_process_delta_time()
				if _knife_anim >= 0.35: _knife_anim = -1.0
			# Einsteige-Animation: Heinz wird kleiner/verschwindet
			if _mode == M_ENTER:
				var fade = 1.0 - _mode_t / 0.8
				modulate.a = fade
			elif _mode == M_EXIT:
				modulate.a = _mode_t / 0.5
			else:
				modulate.a = 1.0

		M_TRUCK:
			modulate.a = 1.0
			var lp = to_local(_truck_pos)
			_draw_truck(lp, _truck_dir)
			# Heinz im Truck (kleines Gesicht hinter Windschutzscheibe)
			_draw_heinz_in_truck(lp, _truck_dir)

func _draw_heinz(bob: float, leg_l: float, leg_r: float, arm_l: float, arm_r: float, flash: bool) -> void:
	var skin  = Color(0.75, 0.52, 0.35) if not flash else Color.WHITE
	var jeans = Color(0.28, 0.35, 0.52)
	var shirt = Color(0.68, 0.22, 0.08)   # rotes Flanellhemd
	var vest  = Color(0.22, 0.16, 0.10)   # Lederweste
	var hair  = Color(0.28, 0.20, 0.10)
	var boot  = Color(0.18, 0.10, 0.04)
	var knife = Color(0.72, 0.72, 0.74)
	var kgrip = Color(0.38, 0.22, 0.08)

	# Stiefel (Cowboy-Stiefel mit Absatz)
	draw_rect(Rect2(-16, 28 + leg_l * 0.4 + bob, 13, 8), boot)
	draw_rect(Rect2(3,   28 + leg_r * 0.4 + bob, 13, 8), boot)
	draw_rect(Rect2(-14, 34 + leg_l * 0.4 + bob, 11, 4), boot.darkened(0.3))   # Absatz
	draw_rect(Rect2(5,   34 + leg_r * 0.4 + bob, 11, 4), boot.darkened(0.3))

	# Jeans
	draw_rect(Rect2(-14, 14 + leg_l * 0.3 + bob, 11, 16), jeans)
	draw_rect(Rect2(3,   14 + leg_r * 0.3 + bob, 11, 16), jeans)

	# Körper (Flanell-Shirt + Lederweste drüber)
	draw_rect(Rect2(-16, -12+bob, 32, 28), shirt)
	# Plaid-Linien auf Shirt
	for sy in [-8.0, -2.0, 4.0, 10.0]:
		draw_line(Vector2(-16, sy+bob), Vector2(16, sy+bob), shirt.darkened(0.35), 1.0)
	for sx in [-10.0, -3.0, 4.0, 11.0]:
		draw_line(Vector2(sx, -12+bob), Vector2(sx, 16+bob), shirt.darkened(0.35), 1.0)

	# Lederweste
	draw_rect(Rect2(-16, -12+bob, 8, 28), vest)
	draw_rect(Rect2(8,   -12+bob, 8, 28), vest)
	# Westen-Schnallen
	for wy in [-4.0, 4.0]:
		draw_rect(Rect2(-18, wy+bob, 4, 6), Color(0.55,0.45,0.10))
		draw_rect(Rect2(14,  wy+bob, 4, 6), Color(0.55,0.45,0.10))

	# Arme
	draw_rect(Rect2(-24, -6 + arm_l + bob, 8, 18), shirt)
	draw_rect(Rect2(16,  -6 + arm_r + bob, 8, 18), shirt)
	# Hände
	draw_circle(Vector2(-22, 11 + arm_l + bob), 7, skin)
	draw_circle(Vector2(22,  11 + arm_r + bob), 7, skin)

	# Bowie-Messer (rechte Hand)
	var ka = _knife_anim >= 0.0
	var kx = 22.0 + (10.0 if ka else 0.0)
	var ky = 11.0 - (8.0  if ka else 0.0)
	# Klinge (lang, breit)
	draw_colored_polygon(PackedVector2Array([
		Vector2(kx,    ky-5 + arm_r + bob),
		Vector2(kx+22, ky-3 + arm_r + bob),
		Vector2(kx+22, ky+3 + arm_r + bob),
		Vector2(kx,    ky+5 + arm_r + bob),
	]), knife)
	# Clip-Point Spitze
	draw_colored_polygon(PackedVector2Array([
		Vector2(kx+22, ky-3 + arm_r + bob),
		Vector2(kx+30, ky+0 + arm_r + bob),
		Vector2(kx+22, ky+3 + arm_r + bob),
	]), knife.lightened(0.1))
	# Guard
	draw_rect(Rect2(kx-2, ky-7 + arm_r + bob, 4, 14), Color(0.55,0.55,0.58))
	# Griff
	draw_rect(Rect2(kx-12, ky-4 + arm_r + bob, 12, 8), kgrip)
	# Griff-Wicklung
	for wi in range(4):
		draw_line(Vector2(kx-12+wi*3, ky-4 + arm_r + bob), Vector2(kx-12+wi*3, ky+4 + arm_r + bob), kgrip.darkened(0.3), 1.5)

	# Kopf
	var hb = bob * 0.4
	draw_circle(Vector2(0, -26+hb), 19, skin)

	# Trucker-Cap (flache Schirmkappe)
	draw_rect(Rect2(-18, -42+hb, 36, 12), Color(0.12,0.10,0.08))   # Kappe
	draw_rect(Rect2(-22, -32+hb, 44, 5),  Color(0.08,0.06,0.04))   # Schirm
	draw_rect(Rect2(-20, -32+hb, 40, 3),  Color(0.16,0.14,0.12))   # Schirmnaht
	# "HRM" Aufdruck auf Kappe (3 kleine Balken)
	for pi in range(3):
		draw_rect(Rect2(-4+pi*4, -40+hb, 3, 8), Color(0.85,0.06,0.06))

	# Koteletten / Bartschatten
	draw_rect(Rect2(-18, -30+hb, 6, 10), hair)
	draw_rect(Rect2(12,  -30+hb, 6, 10), hair)
	# Augen (schmal, misstrauisch)
	draw_rect(Rect2(-10, -28+hb, 7, 4), Color(0.92,0.88,0.82))
	draw_rect(Rect2(3,   -28+hb, 7, 4), Color(0.92,0.88,0.82))
	draw_circle(Vector2(-7,  -27+hb), 2, Color(0.25,0.15,0.05))
	draw_circle(Vector2(6,   -27+hb), 2, Color(0.25,0.15,0.05))
	draw_line(Vector2(-12,-30+hb), Vector2(-3,-28+hb), hair, 3)
	draw_line(Vector2(3,  -28+hb), Vector2(12,-30+hb), hair, 3)
	# Mund (grimmig)
	draw_line(Vector2(-6, -19+hb), Vector2(6, -19+hb), Color(0.22,0.12,0.06), 3)

	# Phase 2: Stirnader sichtbar
	if _phase2:
		draw_line(Vector2(-4, -34+hb), Vector2(0, -28+hb), Color(0.72,0.08,0.04), 2)

func _draw_truck(center: Vector2, dir: Vector2) -> void:
	var right   = dir.rotated(PI * 0.5)
	var rust    = Color(0.55, 0.28, 0.10)
	var chrome  = Color(0.72, 0.72, 0.76)
	var glass   = Color(0.38, 0.58, 0.75, 0.85)
	var tire_c  = Color(0.10, 0.10, 0.12)
	var rim_c   = Color(0.60, 0.60, 0.64)
	var exhaust = Color(0.30, 0.28, 0.25)
	var light_c = Color(1.0, 0.95, 0.6)
	var red_c   = Color(0.80, 0.06, 0.06)

	# Schatten
	draw_circle(center + dir * 5.0, 42, Color(0, 0, 0, 0.22))

	# ── Anhänger / Ladefläche (hinten) ──
	var cargo_c = center - dir * 65.0
	var cb = [
		cargo_c + right*30 - dir*50, cargo_c - right*30 - dir*50,
		cargo_c - right*30 + dir*50, cargo_c + right*30 + dir*50,
	]
	draw_colored_polygon(PackedVector2Array(cb), rust.darkened(0.2))
	# Querstreifen Ladefläche
	for si in range(4):
		var sp = cargo_c - dir*40 + dir*float(si)*22.0
		draw_line(sp + right*30, sp - right*30, rust.darkened(0.35), 3)
	# Seitliche Nieten
	for ni in range(5):
		var np = cargo_c - dir*40 + dir*float(ni)*18.0
		draw_circle(np + right*30, 3, chrome)
		draw_circle(np - right*30, 3, chrome)

	# ── Fahrerkabine (vorne) ──
	var cab_c = center + dir * 30.0
	var cab_pts = PackedVector2Array([
		cab_c + right*28  - dir*10,
		cab_c - right*28  - dir*10,
		cab_c - right*24  + dir*52,
		cab_c + right*24  + dir*52,
	])
	draw_colored_polygon(cab_pts, rust)

	# Seitliche Fenster-Streifen (Kabine)
	draw_line(cab_c + right*28 + dir*10, cab_c + right*28 + dir*35, chrome, 3)
	draw_line(cab_c - right*28 + dir*10, cab_c - right*28 + dir*35, chrome, 3)

	# Windschutzscheibe
	var wsz_pts = PackedVector2Array([
		cab_c + right*20  + dir*44,
		cab_c - right*20  + dir*44,
		cab_c - right*16  + dir*58,
		cab_c + right*16  + dir*58,
	])
	draw_colored_polygon(wsz_pts, glass)
	# Scheibenwischer
	draw_line(cab_c + dir*52, cab_c + right*14 + dir*46, chrome, 2)

	# Motorhaube / Schnauze
	var hood_pts = PackedVector2Array([
		cab_c + right*24 + dir*52,
		cab_c - right*24 + dir*52,
		cab_c - right*20 + dir*75,
		cab_c + right*20 + dir*75,
	])
	draw_colored_polygon(hood_pts, rust.darkened(0.1))

	# Stoßstange (Frontgrill)
	draw_rect_from_center(cab_c + dir*74, right*22, dir*5, chrome)
	# Grill-Stäbe
	for gi in range(5):
		var gx = cab_c + dir*70 + right*(-16 + float(gi)*8)
		draw_line(gx - dir*4, gx + dir*4, chrome.darkened(0.2), 2.5)

	# Scheinwerfer
	draw_circle(cab_c + right*16 + dir*74, 7, light_c)
	draw_circle(cab_c - right*16 + dir*74, 7, light_c)
	draw_circle(cab_c + right*16 + dir*74, 4, Color(1,1,0.8))
	draw_circle(cab_c - right*16 + dir*74, 4, Color(1,1,0.8))

	# Rücklichter
	draw_circle(cab_c + right*27 - dir*10, 5, red_c)
	draw_circle(cab_c - right*27 - dir*10, 5, red_c)

	# ── Räder (4 Stück) ──
	for side_m in [-1.0, 1.0]:
		for fwd in [-45.0, 25.0]:
			var wheel_c = center + right * side_m * 32.0 + dir * fwd
			draw_circle(wheel_c, 14, tire_c)
			draw_circle(wheel_c, 10, tire_c.lightened(0.08))
			draw_circle(wheel_c, 6,  rim_c)
			# Speichen
			for sp in range(5):
				var sp_ang = float(sp) * TAU / 5.0 + _anim_time * 5.0
				draw_line(wheel_c, wheel_c + Vector2(cos(sp_ang), sin(sp_ang)) * 8.0, chrome, 2)

	# Auspuff-Rauch (hinten links)
	var exhaust_pos = center - dir*100.0 + right*22.0
	for ei in range(3):
		var ep = exhaust_pos - dir*float(ei)*10.0
		var ea = 0.5 - float(ei)*0.15
		draw_circle(to_local(to_global(ep)), 5.0+float(ei)*4.0, Color(exhaust.r,exhaust.g,exhaust.b,ea))

func draw_rect_from_center(center: Vector2, half_right: Vector2, half_forward: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + half_right + half_forward,
		center - half_right + half_forward,
		center - half_right - half_forward,
		center + half_right - half_forward,
	]), color)

func _draw_heinz_in_truck(truck_local: Vector2, dir: Vector2) -> void:
	# Kleines Gesicht hinter der Windschutzscheibe sichtbar
	var skin = Color(0.75, 0.52, 0.35)
	var hair = Color(0.28, 0.20, 0.10)
	var face_pos = truck_local + dir * 50.0
	draw_circle(face_pos, 10, skin)
	draw_circle(face_pos + Vector2(-3,-1), 2.5, skin.darkened(0.3))  # Augen
	draw_circle(face_pos + Vector2(3, -1), 2.5, skin.darkened(0.3))
	draw_arc(face_pos + Vector2(0,3), 4, 0.2, PI-0.2, 5, Color(0.2,0.1,0.04), 2)
	draw_arc(face_pos - Vector2(0,8), 10, PI, TAU, 8, hair, 6)  # Kappe

# ── Todesanimation ────────────────────────────────────────────────────────────
func _draw_death() -> void:
	var t     = _death_anim_time
	var skin  = Color(0.68, 0.45, 0.28)
	var jeans = Color(0.24, 0.30, 0.48)
	var vest  = Color(0.18, 0.12, 0.06)
	var blood = Color(0.70, 0.04, 0.04)
	var knife = Color(0.70, 0.70, 0.72)

	var fall = min(t * 46.0, 34.0)
	var lean = min(t * 2.2, 1.0)

	if t > 0.3:
		draw_circle(Vector2(0, 34), min((t-0.3)*36.0, 28.0), Color(blood.r,blood.g,blood.b,0.70))

	# Beine
	draw_rect(Rect2(-14+fall*0.22, 14+fall*0.44, 11, 14), jeans)
	draw_rect(Rect2(3+fall*0.22,   14+fall*0.44, 11, 14), jeans)
	# Körper kippt
	draw_rect(Rect2(-16+fall*0.28*lean, -12+fall*lean, 32, 26), vest)
	# Kopf
	draw_circle(Vector2(fall*0.52, -26+fall*0.86), 19, skin)
	# Cap fliegt ab
	var hx = t*30.0;  var hy = -42.0 - t*48.0
	draw_rect(Rect2(-18+hx, hy, 36, 12), Color(0.12,0.10,0.08))
	draw_rect(Rect2(-22+hx, hy+10, 44, 5), Color(0.08,0.06,0.04))
	# Messer fliegt weg
	var kx = 20.0 + t*60.0;  var ky = 8.0 - t*40.0
	draw_line(Vector2(kx, ky), Vector2(kx+22, ky-4), knife, 4)
	draw_circle(Vector2(kx+22, ky-4), 3, knife)

	modulate.a = 1.0 - max(0.0, (t - 1.2) / 0.4)
