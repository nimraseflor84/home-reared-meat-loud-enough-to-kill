extends EnemyBase

# Mega-Eber Borste-Bernd
# Angriff:  Borsten-Fächer (5 / 8 in Phase 2)
# Spezial:  Quicken → 3× Highspeed-Ramme auf den Spieler

const BRISTLE_CD    = 2.8
const BRISTLE_SPD   = 310.0
const BRISTLE_RNG   = 530.0

const QUICKEN_CD    = 12.0
const QUIEKEN_DUR   = 0.85   # Windup-Zeit
const CHARGE_SPD    = 570.0
const CHARGE_SPD2   = 700.0
const CHARGE_DUR    = 0.65   # Sekunden pro Ramme
const PAUSE_DUR     = 0.38   # Pause zwischen Rammen

const C_IDLE    = 0
const C_QUIEKEN = 1
const C_RUNNING = 2
const C_PAUSE   = 3

var _bristle_timer: float  = 1.5
var _quicken_timer: float  = 7.0
var _phase2: bool          = false

var _cphase: int           = C_IDLE
var _ccount: int           = 0
var _ctimer: float         = 0.0
var _cdir: Vector2         = Vector2.RIGHT
var _chit: bool            = false

var _quieken_anim: float   = -1.0
var _bristles: Array       = []   # {pos, vel, dmg}
var _dust: Array           = []   # {pos, vel, life, size}

func _ready() -> void:
	enemy_id             = "mega_schwein"
	max_hp               = 900.0
	damage               = 35.0
	move_speed           = 55.0
	score_value          = 1800
	_death_anim_duration = 1.8
	add_to_group("bosses")
	super._ready()

# ── Update ────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not is_alive or _dying:
		super._process(delta)
		return

	if _quieken_anim >= 0.0:
		_quieken_anim += delta

	# Borsten bewegen
	for i in range(_bristles.size() - 1, -1, -1):
		var br = _bristles[i]
		br["pos"] += br["vel"] * delta
		var too_far = br["pos"].distance_to(global_position) > BRISTLE_RNG
		var hit = false
		if is_instance_valid(target):
			if br["pos"].distance_to(target.global_position) < 18.0:
				if target.has_method("take_damage"):
					target.take_damage(br["dmg"])
				hit = true
		if hit or too_far:
			_bristles.remove_at(i)

	# Staub aktualisieren
	for i in range(_dust.size() - 1, -1, -1):
		var d = _dust[i]
		d["life"] -= delta
		d["pos"]  += d["vel"] * delta
		d["vel"]  *= 0.90
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
		move_speed = 100.0

	if _cphase == C_IDLE:
		_bristle_timer += delta
		if is_instance_valid(target) and _bristle_timer >= BRISTLE_CD:
			_bristle_timer = 0.0
			_shoot_bristles()
		_quicken_timer -= delta
		if _quicken_timer <= 0.0:
			_start_quicken()
		super._physics_process(delta)
	else:
		_update_charge(delta)

func _update_charge(delta: float) -> void:
	_ctimer -= delta
	match _cphase:
		C_QUIEKEN:
			velocity = Vector2.ZERO
			if _ctimer <= 0.0:
				_begin_charge()

		C_RUNNING:
			var spd = CHARGE_SPD2 if _phase2 else CHARGE_SPD
			velocity = _cdir * spd
			move_and_slide()
			_spawn_dust()
			if not _chit and is_instance_valid(target):
				if global_position.distance_to(target.global_position) < 62.0:
					_chit = true
					if target.has_method("take_damage"):
						target.take_damage(damage * 3.2)
					if target.has_method("apply_knockback"):
						target.apply_knockback(_cdir * 640.0)
					AudioManager.play_hit_sfx()
			if _ctimer <= 0.0:
				_ccount += 1
				if _ccount >= 3:
					_end_quicken()
				else:
					_cphase = C_PAUSE
					_ctimer = PAUSE_DUR

		C_PAUSE:
			velocity = Vector2.ZERO
			if _ctimer <= 0.0:
				_begin_charge()

# ── Aktionen ──────────────────────────────────────────────────────────────────
func _shoot_bristles() -> void:
	if not is_instance_valid(target): return
	var base_dir = (target.global_position - global_position).normalized()
	var count    = 8 if _phase2 else 5
	var spread   = PI * 0.30
	for i in range(count):
		var t_val = float(i) / float(count - 1) if count > 1 else 0.5
		var dir   = base_dir.rotated(-spread + t_val * spread * 2.0)
		_bristles.append({
			"pos": global_position + dir * 38.0,
			"vel": dir * BRISTLE_SPD,
			"dmg": damage * 0.42,
		})
	AudioManager.play_projectile_sfx(5)

func _start_quicken() -> void:
	_quicken_timer = QUICKEN_CD
	_cphase        = C_QUIEKEN
	_ctimer        = QUIEKEN_DUR
	_ccount        = 0
	_quieken_anim  = 0.0
	velocity       = Vector2.ZERO
	AudioManager.play_squeal_sfx()

func _begin_charge() -> void:
	_cphase = C_RUNNING
	_ctimer = CHARGE_DUR
	_chit   = false
	if is_instance_valid(target):
		_cdir = (target.global_position - global_position).normalized()

func _end_quicken() -> void:
	_cphase       = C_IDLE
	_ccount       = 0
	_quieken_anim = -1.0
	velocity      = Vector2.ZERO

func _spawn_dust() -> void:
	for _i in range(3):
		_dust.append({
			"pos":  global_position + Vector2(randf_range(-28, 28), randf_range(-12, 12)),
			"vel":  -_cdir * randf_range(30, 80) + Vector2(randf_range(-40,40), randf_range(-40,40)),
			"life": randf_range(0.18, 0.45),
			"size": randf_range(8.0, 18.0),
		})

func _on_dying_process(_delta: float) -> void:
	_bristles.clear()
	_dust.clear()
	_cphase = C_IDLE

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if _dying:
		_draw_death()
		return
	if not is_alive:
		return

	# Staub (hinter Körper)
	for d in _dust:
		var lp = to_local(d["pos"])
		var al = d["life"] / 0.45
		draw_circle(lp, d["size"] * al, Color(0.80, 0.68, 0.48, al * 0.55))

	var _wc   = sin(_anim_time * 3.2)
	var bob   = 0.0 if _cphase == C_RUNNING else _wc * 2.5   # mehr Waddle-Hub
	var leg_r = 0.0 if _cphase == C_RUNNING else _wc * 6.0   # Beinpaare
	var leg_l = -leg_r
	var flash = _hit_flash > 0
	# Quieken-Vibration
	var jitter = 0.0
	if _quieken_anim >= 0.0 and _cphase == C_QUIEKEN:
		jitter = sin(_quieken_anim * 55.0) * 4.5

	_draw_body(bob, flash, jitter, leg_l, leg_r)
	_draw_bristles_proj()

func _draw_body(bob: float, flash: bool, jitter: float, leg_l: float = 0.0, leg_r: float = 0.0) -> void:
	var pink  = Color(0.82, 0.50, 0.45) if not flash else Color.WHITE
	var dpink = Color(0.62, 0.32, 0.28)
	var ivory = Color(0.95, 0.90, 0.72)
	var blk   = Color(0.08, 0.06, 0.06)
	var red_e = Color(0.92, 0.18, 0.08)   # Augen
	var brist = Color(0.42, 0.22, 0.18)   # Borsten-Farbe

	# Phase-2: leichter roter Schimmer
	var body_c = pink
	if _phase2:
		body_c = Color(pink.r + 0.08, pink.g - 0.06, pink.b - 0.04)

	# ── Körper ──
	# Hauptkörper (großes Oval aus mehreren Kreisen)
	draw_circle(Vector2(jitter, 2+bob), 32, body_c)
	draw_circle(Vector2(12+jitter, 0+bob), 28, body_c)
	# Hals
	draw_rect(Rect2(18+jitter, -14+bob, 20, 28), body_c)

	# ── Beine (4 kurze Stummel, paarweise animiert) ──
	# Paar A (Vorne-links & Hinten-rechts): leg_l; Paar B: leg_r
	var _leg_offsets = [leg_l, leg_r, leg_l, leg_r]
	for li in range(4):
		var lx  = [-18.0, -8.0, 4.0, 14.0][li]
		var lof = _leg_offsets[li]
		draw_rect(Rect2(lx+jitter-4, 28 + lof * 0.3 + bob, 10, 16), dpink)
		# Gespaltene Hufe
		draw_rect(Rect2(lx+jitter-4, 42 + lof * 0.4 + bob, 4, 5), blk)
		draw_rect(Rect2(lx+jitter+1, 42 + lof * 0.4 + bob, 4, 5), blk)

	# ── Kopf ──
	draw_circle(Vector2(38+jitter, -2+bob), 22, body_c)
	# Schnauze (flache Scheibe)
	draw_circle(Vector2(58+jitter, -1+bob), 13, dpink)
	draw_circle(Vector2(55+jitter, -1+bob), 10, Color(dpink.r-0.06, dpink.g-0.04, dpink.b-0.04))
	# Nasenlöcher
	draw_circle(Vector2(62+jitter,  2+bob), 3, blk)
	draw_circle(Vector2(62+jitter, -4+bob), 3, blk)

	# ── Stoßzähne (Elfenbein, nach unten geschwungen) ──
	var tusk_pts1 = PackedVector2Array([
		Vector2(52+jitter, 8+bob),
		Vector2(66+jitter, 8+bob),
		Vector2(70+jitter, 22+bob),
		Vector2(58+jitter, 20+bob),
	])
	draw_colored_polygon(tusk_pts1, ivory)
	var tusk_pts2 = PackedVector2Array([
		Vector2(50+jitter, 4+bob),
		Vector2(62+jitter, 4+bob),
		Vector2(64+jitter, 16+bob),
		Vector2(52+jitter, 16+bob),
	])
	draw_colored_polygon(tusk_pts2, ivory.darkened(0.08))

	# ── Ohren ──
	draw_colored_polygon(PackedVector2Array([
		Vector2(24+jitter, -20+bob), Vector2(32+jitter, -38+bob), Vector2(42+jitter, -22+bob)
	]), body_c)
	draw_colored_polygon(PackedVector2Array([
		Vector2(24+jitter, -20+bob), Vector2(32+jitter, -38+bob), Vector2(42+jitter, -22+bob)
	]), Color(dpink.r, dpink.g, dpink.b, 0.6))  # innere Füllung

	# ── Augen (klein, gemein) ──
	var eye_c = red_e if (_phase2 or _cphase == C_RUNNING) else Color(0.88, 0.12, 0.04)
	draw_circle(Vector2(32+jitter, -10+bob), 5, Color(0.95, 0.88, 0.80))
	draw_circle(Vector2(32+jitter, -10+bob), 3, eye_c)
	draw_circle(Vector2(32+jitter, -10+bob), 1.2, blk)
	# Wütende Augenbraue
	draw_line(Vector2(26+jitter, -16+bob), Vector2(38+jitter, -13+bob), blk, 3)

	# ── Ringelschwanz ──
	draw_arc(Vector2(-28+jitter, -2+bob), 7, -PI*0.3, PI*1.0, 10, dpink, 5)
	draw_circle(Vector2(-35+jitter, 4+bob), 4, dpink)

	# ── Borsten-Rücken (Reihe scharfer Dreiecke) ──
	for i in range(10):
		var bx = -24.0 + float(i) * 6.2 + jitter
		var by = -30.0 + sin(float(i) * 0.8) * 4.0 + bob
		var bh = 12.0 if i % 3 != 1 else 16.0  # abwechselnde Längen
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx-3, by),
			Vector2(bx,   by - bh),
			Vector2(bx+3, by),
		]), brist)

	# ── Quieken-Maul ──
	if _quieken_anim >= 0.0:
		var qo = min(_quieken_anim / 0.3, 1.0) * 10.0  # Maul öffnet sich
		# Weit aufgerissenes Maul
		draw_arc(Vector2(58+jitter, -1+bob), 10+qo, 0.3, PI-0.3, 8, blk, int(qo+4))
		# Zähne
		for ti in range(3):
			var tx = 50.0 + float(ti) * 6.0 + jitter
			draw_colored_polygon(PackedVector2Array([
				Vector2(tx,   -1+bob + qo*0.3),
				Vector2(tx+3, -1+bob - 5 - qo*0.3),
				Vector2(tx+5,  -1+bob + qo*0.3),
			]), Color(0.94, 0.92, 0.88))
		# Schallwellen aus dem Maul (Quicken-Sound)
		if _quieken_anim > 0.2:
			for wi in range(3):
				var wr  = 18.0 + float(wi)*12.0 + fmod(_quieken_anim * 40.0, 12.0)
				var wal = max(0.0, 1.0 - float(wi)*0.3 - _quieken_anim * 0.5)
				draw_arc(Vector2(62+jitter, -1+bob), wr, -PI*0.4, PI*0.4, 8,
					Color(1.0, 0.85, 0.2, wal), 3)

	# ── Charge-Effekt: Geschwindigkeitslinien ──
	if _cphase == C_RUNNING:
		for li in range(6):
			var llen  = randf_range(20, 55)
			var ly    = -20.0 + float(li) * 8.0
			var lx    = -40.0 - randf_range(0, 20)
			draw_line(Vector2(lx, ly), Vector2(lx-llen, ly), Color(1.0,1.0,1.0,0.35), 2)

func _draw_bristles_proj() -> void:
	var brist = Color(0.42, 0.22, 0.18)
	var tip_c = Color(0.72, 0.62, 0.50)
	for br in _bristles:
		var lp  = to_local(br["pos"])
		var dir = br["vel"].normalized()
		# Borste: dünnes Dreieck in Flugrichtung
		var right = dir.rotated(PI * 0.5)
		draw_colored_polygon(PackedVector2Array([
			lp + dir * 14.0,
			lp - dir * 4.0 + right * 3.5,
			lp - dir * 4.0 - right * 3.5,
		]), brist)
		draw_circle(lp + dir * 14.0, 2.5, tip_c)

# ── Todesanimation ────────────────────────────────────────────────────────────
func _draw_death() -> void:
	var t     = _death_anim_time
	var pink  = Color(0.70, 0.40, 0.36)
	var dpink = Color(0.52, 0.26, 0.22)
	var ivory = Color(0.90, 0.84, 0.66)
	var blood = Color(0.70, 0.04, 0.04)
	var brist = Color(0.38, 0.18, 0.14)

	# Körper kippt auf die Seite
	var fall   = min(t * 45.0, 35.0)
	var squish = 1.0 - min(t * 0.5, 0.4)  # Körper wird flacher beim Aufprall

	# Blutlache
	if t > 0.4:
		draw_circle(Vector2(0, 40), min((t-0.4)*42.0, 38.0), Color(blood.r,blood.g,blood.b,0.72))

	# Körper auf Seite
	draw_circle(Vector2(fall*0.3, 6+fall*0.9), 32*squish, pink)
	draw_circle(Vector2(16+fall*0.3, 4+fall*0.9), 26*squish, pink)
	# Beine starr in der Luft
	for lx in [-18.0, -8.0, 4.0, 14.0]:
		var leg_ang = float(lx) * 0.04
		draw_line(
			Vector2(lx+fall*0.1, 28+fall*0.5),
			Vector2(lx + cos(leg_ang+PI*0.5)*14, 28+fall*0.5 + sin(leg_ang+PI*0.5)*14),
			dpink, 9
		)
	# Kopf
	draw_circle(Vector2(38+fall*0.4, -2+fall), 22*squish, pink)
	draw_circle(Vector2(58+fall*0.4, -1+fall), 13, dpink)
	# Stoßzähne
	draw_line(Vector2(52+fall*0.4, 8+fall), Vector2(70+fall*0.4, 22+fall), ivory, 5)
	# Borsten-Rücken
	for i in range(8):
		var bx = -22.0 + float(i)*7.0 + fall*0.2
		var by = -28.0 + fall*0.8
		var bh = 14.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx-3, by), Vector2(bx, by-bh*squish), Vector2(bx+3, by)
		]), brist)
	# Staub-Wolke beim Aufprall
	if t < 0.6:
		var da = max(0.0, 0.6 - t) / 0.6
		draw_circle(Vector2(0, 32), t * 80.0, Color(0.82,0.70,0.48, da * 0.7))

	modulate.a = 1.0 - max(0.0, (t - 1.4) / 0.4)
