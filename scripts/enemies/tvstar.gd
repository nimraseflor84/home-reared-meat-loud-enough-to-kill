extends EnemyBase

# TV-Guru Bernd Goldmann
# Angriff:   Kleine gelbe Blitze (Zickzack-Projektile)
# Spezial:   BADFLIX – Monitor zeigt Intro-Animation → spawnt 5 zufällige TV-Figuren

const BLITZ_CD   = 2.0
const BLITZ_SPD  = 320.0
const BLITZ_RNG  = 580.0
const SPECIAL_CD = 15.0

const _FIGUR_SCENE = "res://scenes/entities/enemies/enemy_tv_figur.tscn"
const FIGUR_TYPES  = [
	"joffrey","umbridge","jarjar","percy","ratched",
	"bella","commodus","cal","scrappy","andrea"
]

# BADFLIX-Phasen
const BF_NONE    = 0
const BF_MONITOR = 1   # Monitor-Animation erscheint (1.8 s)
const BF_SPAWN   = 2   # Flash beim Spawn            (0.3 s)

var _phase2: bool          = false

var _blitz_timer: float    = 1.2
var _special_timer: float  = 8.0

var _bf_phase: int         = BF_NONE
var _bf_t: float           = 0.0
var _monitor_alpha: float  = 0.0
var _monitor_scan: float   = 0.0   # scrollende Scanlinie

# Blitz-Projektile – {pos, vel, seed, dmg}
var _blitze: Array         = []

func _ready() -> void:
	enemy_id             = "tvstar"
	max_hp               = 800.0
	damage               = 30.0
	move_speed           = 48.0
	score_value          = 2200
	_death_anim_duration = 1.6
	add_to_group("bosses")
	super._ready()

# ── Update ────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not is_alive or _dying:
		super._process(delta)
		return

	# Phase-2-Trigger bei 50 % HP
	if not _phase2 and current_hp <= max_hp * 0.5:
		_phase2    = true
		move_speed = move_speed * 1.65

	# Blitze bewegen + Treffer prüfen
	for i in range(_blitze.size() - 1, -1, -1):
		var b = _blitze[i]
		b["pos"] += b["vel"] * delta
		var too_far = b["pos"].distance_to(global_position) > BLITZ_RNG
		var hit     = false
		if is_instance_valid(target):
			if b["pos"].distance_to(target.global_position) < 20.0:
				if target.has_method("take_damage"):
					target.take_damage(b["dmg"])
				hit = true
		if hit or too_far:
			_blitze.remove_at(i)

	# BADFLIX-Phasen
	_bf_t += delta
	match _bf_phase:
		BF_MONITOR:
			_monitor_alpha = min(_bf_t / 0.3, 1.0)
			_monitor_scan  = fmod(_bf_t * 80.0, 80.0)
			if _bf_t >= 1.8:
				_do_spawn_figuren()
		BF_SPAWN:
			if _bf_t >= 0.3:
				_bf_phase      = BF_NONE
				_bf_t          = 0.0
				_monitor_alpha = 0.0

	super._process(delta)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if _bf_phase == BF_NONE:
		_blitz_timer   -= delta
		if is_instance_valid(target) and _blitz_timer <= 0.0:
			_blitz_timer = BLITZ_CD * (0.65 if _phase2 else 1.0)
			_shoot_blitz()
		_special_timer -= delta
		if _special_timer <= 0.0:
			_start_badflix()
		super._physics_process(delta)
	else:
		# Während BADFLIX: langsam schleichen
		velocity *= 0.88
		move_and_slide()

# ── Aktionen ──────────────────────────────────────────────────────────────────
func _shoot_blitz() -> void:
	if not is_instance_valid(target): return
	var base_dir = (target.global_position - global_position).normalized()
	# Phase1: 2 Blitze, Phase2: 3 Blitze im breiteren Fächer
	var angles = [-0.18, 0.18] if not _phase2 else [-0.28, 0.0, 0.28]
	for a in angles:
		var dir = base_dir.rotated(a)
		_blitze.append({
			"pos":  global_position + dir * 32.0,
			"vel":  dir * BLITZ_SPD,
			"seed": randi(),
			"dmg":  damage * 0.75,
		})
	AudioManager.play_projectile_sfx(0)

func _start_badflix() -> void:
	_special_timer = SPECIAL_CD
	_bf_phase      = BF_MONITOR
	_bf_t          = 0.0
	_monitor_alpha = 0.0
	_monitor_scan  = 0.0
	AudioManager.play_boss_siren_sfx()

func _do_spawn_figuren() -> void:
	_bf_phase = BF_SPAWN
	_bf_t     = 0.0
	var shuffled = FIGUR_TYPES.duplicate()
	shuffled.shuffle()
	var to_spawn = shuffled.slice(0, 5)
	var parent   = get_parent()
	if not parent: return
	var scene = load(_FIGUR_SCENE)
	if not scene: return
	for i in range(to_spawn.size()):
		var f = scene.instantiate()
		f.figur_type = to_spawn[i]
		var angle = float(i) / 5.0 * TAU + randf() * 0.4
		var dist  = randf_range(80.0, 145.0)
		parent.add_child(f)
		f.global_position = global_position + Vector2(cos(angle), sin(angle)) * dist
		if f.has_method("set_target"):
			f.set_target(target)

func _on_dying_process(_delta: float) -> void:
	_blitze.clear()

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if _dying:
		_draw_death()
		return
	if not is_alive:
		return

	var _wc   = sin(_anim_time * 3.2)
	var bob   = _wc * 1.4
	var leg_r = _wc * 9.0
	var leg_l = -leg_r
	var arm_r = -leg_r * 0.7
	var arm_l = leg_r * 0.7
	var flash = _hit_flash > 0
	_draw_body(bob, leg_l, leg_r, arm_l, arm_r, flash)
	_draw_blitze()
	if _bf_phase == BF_MONITOR or _bf_phase == BF_SPAWN:
		_draw_badflix_monitor(bob)

func _draw_body(bob: float, leg_l: float, leg_r: float, arm_l: float, arm_r: float, flash: bool) -> void:
	var gold  = Color(0.92, 0.78, 0.08) if not flash else Color.WHITE
	var lgold = Color(1.00, 0.92, 0.22)
	var skin  = Color(0.90, 0.76, 0.58) if not flash else Color.WHITE
	var black = Color(0.08, 0.06, 0.04)
	var white = Color(0.95, 0.93, 0.89)
	var purp  = Color(0.45, 0.05, 0.55)   # lila Krawatte

	# Schuhe
	draw_rect(Rect2(-15, 30 + leg_l * 0.4 + bob, 13, 6), black)
	draw_rect(Rect2(2,   30 + leg_r * 0.4 + bob, 13, 6), black)

	# Hosen (Gold)
	draw_rect(Rect2(-13, 14 + leg_l * 0.3 + bob, 10, 18), gold)
	draw_rect(Rect2(3,   14 + leg_r * 0.3 + bob, 10, 18), gold)

	# Goldener Anzug-Jacket
	draw_rect(Rect2(-16, -12+bob, 32, 28), gold)

	# Weißes Hemd
	draw_rect(Rect2(-5, -12+bob, 10, 14), white)

	# Goldene Revers
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5,-12+bob), Vector2(-16,-4+bob), Vector2(-5,4+bob)
	]), lgold)
	draw_colored_polygon(PackedVector2Array([
		Vector2(5,-12+bob), Vector2(16,-4+bob), Vector2(5,4+bob)
	]), lgold)

	# Lila Krawatte (Retro-TV-Moderator)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3,-10+bob), Vector2(3,-10+bob),
		Vector2(4, 10+bob),  Vector2(-4,10+bob)
	]), purp)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4,10+bob), Vector2(4,10+bob), Vector2(0,16+bob)
	]), purp.darkened(0.25))

	# Goldene Knöpfe
	for ky in [-4.0, 2.0]:
		draw_circle(Vector2(-7, ky+bob), 2.5, lgold)

	# Arme
	draw_rect(Rect2(-24, -8 + arm_l + bob, 8, 22), gold)
	draw_rect(Rect2(16,  -8 + arm_r + bob, 8, 22), gold)
	draw_circle(Vector2(-22, 13 + arm_l + bob), 7, skin)
	draw_circle(Vector2(22,  13 + arm_r + bob), 7, skin)

	# Blitz-Manschettenknöpfe
	_draw_small_bolt(Vector2(-22, 5 + arm_l + bob), 5.0, lgold)
	_draw_small_bolt(Vector2(22,  5 + arm_r + bob), 5.0, lgold)

	# Mikrofon linke Hand
	draw_rect(Rect2(-28, 2 + arm_l + bob, 4, 14), Color(0.55,0.55,0.58))
	draw_circle(Vector2(-26, 0 + arm_l + bob), 6, Color(0.62,0.62,0.65))
	draw_circle(Vector2(-26, 0 + arm_l + bob), 4, Color(0.25,0.25,0.28))

	# Kopf
	var hb = bob * 0.4
	draw_circle(Vector2(0, -28+hb), 20, skin)

	# Große Fönwelle
	_draw_pompadour(hb, lgold, gold)

	# Rundes Brillengestell
	draw_arc(Vector2(-7, -30+hb), 7, 0, TAU, 8, black, 2)
	draw_arc(Vector2(7,  -30+hb), 7, 0, TAU, 8, black, 2)
	draw_line(Vector2(-14,-30+hb), Vector2(-16,-28+hb), black, 2)  # linker Bügel
	draw_line(Vector2(14, -30+hb), Vector2(16, -28+hb), black, 2)  # rechter Bügel

	# Augen hinter Gläsern (blaue Iris)
	draw_circle(Vector2(-7, -30+hb), 4, white)
	draw_circle(Vector2(7,  -30+hb), 4, white)
	draw_circle(Vector2(-7, -30+hb), 2, Color(0.12,0.20,0.72))
	draw_circle(Vector2(7,  -30+hb), 2, Color(0.12,0.20,0.72))

	# Breites strahlendes Lächeln
	draw_arc(Vector2(0, -20+hb), 10, 0.2, PI-0.2, 8, Color(0.88,0.20,0.12), 4)
	for ti in range(5):
		draw_rect(Rect2(-7 + ti*3, -22+hb, 2, 5), white)

	# Phase2: Goldzacken-Strahlenkranz um Kopf
	if _phase2:
		for i in range(8):
			var ra = float(i) / 8.0 * TAU + _anim_time * 1.2
			var r1 = Vector2(cos(ra),              sin(ra))              * 22.0
			var r2 = Vector2(cos(ra + TAU/16.0),   sin(ra + TAU/16.0))  * 30.0
			var r3 = Vector2(cos(ra + TAU/8.0),    sin(ra + TAU/8.0))   * 22.0
			draw_colored_polygon(PackedVector2Array([
				r1 + Vector2(0,-28+hb),
				r2 + Vector2(0,-28+hb),
				r3 + Vector2(0,-28+hb),
			]), Color(lgold.r, lgold.g, lgold.b, 0.55))

func _draw_pompadour(bob: float, lgold: Color, gold: Color) -> void:
	var wave = sin(_anim_time * 2.0) * 1.5
	var pts  = PackedVector2Array()
	# Obere Wellenkontur (Quiff)
	for i in range(9):
		var t_val = float(i) / 8.0
		var x = -14.0 + t_val * 28.0
		var y = -42.0 - sin(t_val * PI) * 14.0 + wave + bob
		pts.append(Vector2(x, y))
	# Unterkante
	pts.append(Vector2(14.0, -36.0+bob))
	pts.append(Vector2(-14.0, -36.0+bob))
	draw_colored_polygon(pts, lgold)
	# Glanzlinie oben
	draw_arc(Vector2(0, -50+bob+wave), 10, PI*0.8, PI*0.2 + TAU*0.5, 6, gold.lightened(0.3), 3)

func _draw_small_bolt(center: Vector2, size: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(size*0.3,   -size),
		center + Vector2(-size*0.1,  -size*0.1),
		center + Vector2(size*0.4,   -size*0.1),
		center + Vector2(-size*0.3,   size),
		center + Vector2(size*0.1,    size*0.1),
		center + Vector2(-size*0.4,   size*0.1),
	]), col)

func _draw_blitze() -> void:
	for b in _blitze:
		var lp    = to_local(b["pos"])
		var vel   = b["vel"]
		var len_v = vel.length()
		if len_v < 1.0: continue
		var fwd  = vel / len_v
		var perp = fwd.rotated(PI * 0.5)
		var seg  = 14.0
		var rng  = RandomNumberGenerator.new()
		rng.seed = b["seed"]
		var pts  = PackedVector2Array()
		var origin = lp - fwd * seg * 3.0
		for i in range(7):
			var off = 0.0 if (i == 0 or i == 6) else rng.randf_range(-5.5, 5.5)
			pts.append(origin + fwd * float(i) * seg + perp * off)
		# Breiter gelber Schein
		draw_polyline(pts, Color(1.0, 0.95, 0.3, 0.35), 8.0)
		# Weißer Kern
		draw_polyline(pts, Color(1.0, 1.0, 0.85), 2.5)

func _draw_badflix_monitor(bob: float) -> void:
	var mx    = 0.0
	var my    = -82.0 + bob
	var alpha = _monitor_alpha
	var w     = 54.0
	var h     = 40.0

	# Monitor-Gehäuse (Röhren-Stil)
	draw_rect(Rect2(mx-w*0.5-5, my-h*0.5-5, w+10, h+10),
		Color(0.20, 0.20, 0.22, alpha))
	# Bildschirm
	draw_rect(Rect2(mx-w*0.5, my-h*0.5, w, h),
		Color(0.02, 0.02, 0.06, alpha))

	# Scanline
	var scan_y = my - h*0.5 + fmod(_monitor_scan, h)
	draw_line(
		Vector2(mx - w*0.5, scan_y), Vector2(mx + w*0.5, scan_y),
		Color(0.5, 1.0, 0.3, alpha * 0.35), 2.0)

	# BADFLIX-Logo erscheint nach 0.35 s
	if _bf_t > 0.35:
		var ta = min((_bf_t - 0.35) / 0.3, 1.0)
		# Roter Balken
		draw_rect(Rect2(mx-24, my-9, 48, 18), Color(0.85, 0.06, 0.06, alpha * ta))
		# Weiße Pixelschrift: "BADFLIX"
		# B
		draw_rect(Rect2(mx-22, my-7, 3, 14), Color(1,1,1, alpha*ta))
		draw_rect(Rect2(mx-19, my-7, 5, 6),  Color(1,1,1, alpha*ta))
		draw_rect(Rect2(mx-19, my+1, 5, 6),  Color(1,1,1, alpha*ta))
		# A
		draw_rect(Rect2(mx-13, my-7, 3, 14), Color(1,1,1, alpha*ta))
		draw_rect(Rect2(mx-10, my-7, 3, 14), Color(1,1,1, alpha*ta))
		draw_rect(Rect2(mx-13, my-1, 6, 2),  Color(1,1,1, alpha*ta))
		draw_line(Vector2(mx-13,my-7), Vector2(mx-7,my-7), Color(1,1,1,alpha*ta), 2)
		# D
		draw_rect(Rect2(mx-6, my-7, 3, 14), Color(1,1,1, alpha*ta))
		draw_arc(Vector2(mx-3, my), 7, -PI*0.5, PI*0.5, 6, Color(1,1,1,alpha*ta), 3)
		# F
		draw_rect(Rect2(mx+5, my-7, 3, 14), Color(1,1,1, alpha*ta))
		draw_rect(Rect2(mx+8, my-7, 5, 2),  Color(1,1,1, alpha*ta))
		draw_rect(Rect2(mx+8, my-1, 4, 2),  Color(1,1,1, alpha*ta))
		# L
		draw_rect(Rect2(mx+14, my-7, 3, 14), Color(1,1,1, alpha*ta))
		draw_rect(Rect2(mx+17, my+5, 5, 2),  Color(1,1,1, alpha*ta))
		# I
		draw_rect(Rect2(mx+20, my-7, 3, 14), Color(1,1,1, alpha*ta))
		# X
		draw_line(Vector2(mx+25,my-7), Vector2(mx+31,my+7), Color(1,1,1,alpha*ta), 2.5)
		draw_line(Vector2(mx+31,my-7), Vector2(mx+25,my+7), Color(1,1,1,alpha*ta), 2.5)

	# Blinkende Umrahmung beim Spawnen
	if _bf_phase == BF_SPAWN:
		var pulse = sin(_anim_time * 25.0) * 0.5 + 0.5
		draw_rect(
			Rect2(mx-w*0.5-7, my-h*0.5-7, w+14, h+14),
			Color(1.0, 0.92, 0.1, pulse * 0.85), false, 3.0)

	# Verbindungslinie Monitor → Boss-Kopf
	draw_line(
		Vector2(mx, my + h*0.5 + 4),
		Vector2(0, -52.0 + bob),
		Color(0.32, 0.28, 0.30, alpha * 0.65), 2.0)

# ── Todesanimation ────────────────────────────────────────────────────────────
func _draw_death() -> void:
	var t     = _death_anim_time
	var gold  = Color(0.85, 0.70, 0.06)
	var skin  = Color(0.88, 0.72, 0.52)
	var black = Color(0.08, 0.06, 0.04)
	var purp  = Color(0.45, 0.05, 0.55)

	var fall  = min(t * 52.0, 42.0)
	var lean  = min(t * 2.2, 1.0)

	# Goldener Schein am Boden
	if t > 0.25:
		draw_circle(Vector2(0, 36), min((t-0.25)*40.0, 32.0),
			Color(0.88, 0.72, 0.06, 0.62))

	# Körper kippt
	draw_rect(Rect2(-13+fall*0.28, 14+fall*0.50, 10, 16), gold.darkened(t*0.4))
	draw_rect(Rect2(3+fall*0.28,   14+fall*0.50, 10, 16), gold.darkened(t*0.4))
	draw_rect(Rect2(-16+fall*0.30*lean, -12+fall*lean, 32, 26), gold.darkened(t*0.4))

	# Krawatte weht
	draw_line(
		Vector2(fall*0.35, -10+fall*0.45),
		Vector2(fall*0.35+5, 14+fall*0.55),
		purp, 5.0)

	# Mikrofon fliegt weg
	draw_circle(Vector2(-20.0 + t*42.0, -8.0 - t*24.0), 5, Color(0.55,0.55,0.58))

	# Brille fliegt weg
	draw_arc(Vector2(-8.0 - t*16.0, -30.0 - t*20.0), 7, 0, TAU, 8, black, 2)

	# Kopf dreht sich / kippt
	draw_circle(Vector2(fall*0.50, -28+fall*0.90), 20, skin)

	# Haare fliegen weg
	for i in range(5):
		var hx = -8.0 + float(i)*4.0 - fall*0.6
		var hy = -50.0 - t*55.0
		draw_line(
			Vector2(hx, hy), Vector2(hx+3, hy-10),
			Color(0.92, 0.82, 0.18), 3.5)

	modulate.a = 1.0 - max(0.0, (t - 1.2) / 0.4)
