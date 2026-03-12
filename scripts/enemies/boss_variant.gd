extends EnemyBase
# Konfigurierbarer Boss – jeder Boss hat einzigartiges Aussehen per enemy_id

@export var body_color: Color = Color(0.7, 0.1, 0.1)
@export var accent_color: Color = Color(1.0, 0.4, 0.4)
@export var body_size: float = 30.0
@export var minion_path: String = "res://scenes/entities/enemies/enemy_stille.tscn"
@export var hat_style: int = 7
@export var speed_phase2: float = 90.0

var _spawn_timer: float = 0.0
const SPAWN_INTERVAL = 6.0
var _phase: int = 1
var _aura_pulse: float = 0.0
var _minion_scene_cache: PackedScene = null

func _ready() -> void:
	add_to_group("bosses")
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = body_size
	col.shape = shape
	add_child(col)
	collision_layer = 2
	collision_mask = 1
	_death_anim_duration = 1.8
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	_aura_pulse += delta * 2.2

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_do_spawn_minion()
	if current_hp <= max_hp * 0.5 and _phase == 1:
		_phase = 2
		move_speed = speed_phase2

func _do_spawn_minion() -> void:
	if _minion_scene_cache == null:
		_minion_scene_cache = load(minion_path)
	if not _minion_scene_cache:
		return
	for i in range(2):
		var m = _minion_scene_cache.instantiate()
		var angle = randf() * TAU
		m.global_position = global_position + Vector2(cos(angle), sin(angle)) * (body_size * 2.5)
		get_tree().current_scene.add_child(m)

func _die(attacker = null) -> void:
	is_alive = false
	_bullets.clear()
	remove_from_group("enemies")
	if is_instance_valid(attacker) and attacker.has_method("on_kill"):
		attacker.on_kill(self)
	AudioManager.play_boss_death_sfx()
	emit_signal("died", self)
	_dying = true

# ─────────────────────────────────────────────────────────────
func _on_dying_process(delta: float) -> void:
	var t = _death_anim_time / _death_anim_duration
	modulate.a = 1.0 - t
	match enemy_id:
		"grossbauer":
			rotation += delta * TAU * (1.5 + t * 5.0)
			var s = max(0.01, 1.0 - t * 0.92)
			scale = Vector2(s, s)
		"gefchef":
			var s = max(0.01, 1.0 - t * 0.88)
			scale = Vector2(s, s)
		"mega_schwein":
			if t < 0.38:
				var s = 1.0 + t * 3.2
				scale = Vector2(s, s)
			else:
				var s = max(0.01, (1.0 - t) * 1.6)
				scale = Vector2(s, s)
		"trump":
			rotation += delta * TAU * (0.5 + t * 1.5)
			var s = max(0.01, 1.0 - t * 0.80)
			scale = Vector2(s, s)
		"trucker":
			rotation += delta * TAU * (2.0 + t * 4.0)
			var s = max(0.01, 1.0 - t * 0.88)
			scale = Vector2(s, s)
		"tvstar":
			# CRT-off: horizontal line collapses
			var sx = 1.0 + t * 0.4
			var sy = max(0.01, 1.0 - t * 1.15)
			scale = Vector2(sx, sy)
		"buergermeister":
			var s = max(0.01, 1.0 - t * 0.82)
			scale = Vector2(s, s)
		_:
			var s = max(0.01, 1.0 - t)
			scale = Vector2(s, s)

func _draw_boss_death_particles() -> void:
	var t = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	var bs = body_size
	var alpha = 1.0 - t
	match enemy_id:
		"grossbauer":
			# Große Heu-Brocken fliegen weit heraus
			for i in range(12):
				var angle = i * TAU / 12.0
				var dist = bs * (1.2 + t * 7.5)
				var pos = Vector2(cos(angle), sin(angle)) * dist
				draw_circle(pos, bs * (0.50 - t * 0.22), Color(0.78, 0.60, 0.16, alpha))
				draw_circle(pos + Vector2(bs * 0.25, -bs * 0.12), bs * (0.30 - t * 0.12), Color(0.55, 0.42, 0.10, alpha))
			# Riesige Staubringe
			for i in range(3):
				var r = bs * (2.5 + i * 3.0 + t * 6.0)
				draw_arc(Vector2.ZERO, r, 0, TAU, 20, Color(0.50, 0.36, 0.20, (1.0 - t) * 0.40), bs * 0.55)
			# Erdklumpen nach unten
			for i in range(6):
				var angle = PI + (float(i) - 2.5) * 0.35
				var dist = bs * (1.0 + t * 5.0)
				draw_circle(Vector2(cos(angle), sin(angle)) * dist, bs * 0.35 * alpha, Color(0.38, 0.24, 0.08, alpha))
		"gefchef":
			# Dicke Elektroentladungsbalken
			for i in range(10):
				var angle = i * TAU / 10.0
				var dist1 = bs * (0.8 + t * 5.0)
				var dist2 = bs * (1.8 + t * 8.0)
				var bend = sin(float(i) * 1.7 + t * 7.0) * 0.55
				var p1 = Vector2(cos(angle), sin(angle)) * dist1
				var p2 = Vector2(cos(angle + bend), sin(angle + bend)) * dist2
				draw_line(p1, p2, Color(0.25, 0.55, 1.0, alpha), bs * 0.18)
			# Großes Abzeichen dreht sich weit heraus
			var badge_a = t * TAU * 3.5
			var badge_d = bs * (0.5 + t * 6.0)
			_draw_star(Vector2(cos(badge_a), sin(badge_a)) * badge_d,
				bs * 0.65 * alpha, Color(0.92, 0.78, 0.08, alpha))
			# Blaue Schockringe
			for i in range(4):
				var r = bs * (2.0 + float(i) * 2.5 + t * 4.5)
				draw_arc(Vector2.ZERO, r, 0, TAU, 16, Color(0.18, 0.45, 1.0, (1.0 - t) * 0.45), bs * 0.42)
		"mega_schwein":
			if t < 0.38:
				# Druckringe beim Aufblasen
				var pt = t / 0.38
				for i in range(4):
					var r = bs * (1.5 + float(i) * 1.2) * (1.0 + pt * 1.0)
					draw_arc(Vector2.ZERO, r, 0, TAU, 16, Color(0.78, 0.40, 0.30, pt * 0.35), bs * 0.35)
			else:
				# RIESIGE SCHLAMMEXPLOSION nach dem POP
				var pt = (t - 0.38) / 0.62
				for i in range(14):
					var angle = float(i) * TAU / 14.0 + float(i) * 0.22
					var dist = bs * (0.8 + pt * 9.0)
					var sz = bs * (0.72 - pt * 0.40)
					draw_circle(Vector2(cos(angle), sin(angle)) * dist, sz,
						Color(0.22, 0.12, 0.03, 1.0 - pt))
				var ring_r = bs * (1.5 + pt * 7.5)
				draw_arc(Vector2.ZERO, ring_r, 0, TAU, 24, Color(0.30, 0.16, 0.04, (1.0 - pt) * 0.65), bs * 0.85)
				for i in range(6):
					var angle = float(i) * TAU / 6.0 + 0.3
					var dist = bs * (1.0 + pt * 6.0)
					draw_circle(Vector2(cos(angle), sin(angle)) * dist,
						bs * 0.55 * (1.0 - pt), Color(0.78, 0.40, 0.30, 1.0 - pt))
		"trump":
			# Dollar-Bills fliegen heraus
			for i in range(10):
				var angle = float(i) * TAU / 10.0 + t * 0.5
				var dist = bs * (0.8 + t * 7.0)
				var pos = Vector2(cos(angle), sin(angle)) * dist
				var rot = t * 4.0 + float(i) * 0.9
				var cr = cos(rot)
				var sr_r = sin(rot)
				var bw = bs * 0.55 * alpha
				var bh = bs * 0.30 * alpha
				draw_colored_polygon(PackedVector2Array([
					pos + Vector2(cr * bw - sr_r * bh, sr_r * bw + cr * bh),
					pos + Vector2(-cr * bw - sr_r * bh, -sr_r * bw + cr * bh),
					pos + Vector2(-cr * bw + sr_r * bh, -sr_r * bw - cr * bh),
					pos + Vector2(cr * bw + sr_r * bh, sr_r * bw - cr * bh),
				]), Color(0.12, 0.52, 0.18, alpha))
			# Riesige orange Schockwelle
			draw_arc(Vector2.ZERO, bs * (2.0 + t * 6.0), 0, TAU, 24,
				Color(0.92, 0.48, 0.08, (1.0 - t) * 0.55), bs * 0.65)
			# Krawatte fliegt nach oben
			var ty = -bs * (0.20 + t * t * 7.5)
			var tx = sin(t * TAU * 2.2) * bs * 3.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(tx - bs * 0.20, ty), Vector2(tx + bs * 0.20, ty),
				Vector2(tx + bs * 0.24, ty + bs * 1.6),
				Vector2(tx, ty + bs * 2.2),
				Vector2(tx - bs * 0.24, ty + bs * 1.6)
			]), Color(0.88, 0.06, 0.06, alpha))
		"trucker":
			# Massive Feuerball
			var fb_r = bs * (1.5 + t * 5.5)
			draw_circle(Vector2.ZERO, fb_r, Color(1.0, 0.35, 0.0, (1.0 - t) * 0.40))
			draw_arc(Vector2.ZERO, fb_r, 0, TAU, 20, Color(1.0, 0.65, 0.0, (1.0 - t) * 0.55), bs * 0.60)
			draw_arc(Vector2.ZERO, bs * (2.5 + t * 4.0), 0, TAU, 16,
				Color(0.9, 0.15, 0.0, (1.0 - t) * 0.35), bs * 0.40)
			# Kettenringe fliegen heraus
			for i in range(8):
				var angle = float(i) * TAU / 8.0 + t * TAU * 1.5
				var dist = bs * (1.5 + t * 8.0)
				var cpos = Vector2(cos(angle), sin(angle)) * dist
				draw_circle(cpos, bs * 0.32 * alpha, Color(0.65, 0.54, 0.18, alpha))
				var prev_a = angle - TAU / 8.0
				var prev_d = bs * (1.5 + max(0.0, t - 0.05) * 8.0)
				draw_line(cpos, Vector2(cos(prev_a), sin(prev_a)) * prev_d,
					Color(0.55, 0.44, 0.12, alpha * 0.85), bs * 0.14)
			# Kappe schießt nach oben
			draw_rect(Rect2(-bs * 0.65, -(bs * 1.65 + t * t * bs * 10.0), bs * 1.30, bs * 0.72 * alpha),
				Color(0.12, 0.08, 0.06, alpha))
		"tvstar":
			if t < 0.32:
				# Weißer Statik-Burst
				var nt = t / 0.32
				for i in range(18):
					var angle = float(i) * TAU / 18.0
					var dist = bs * (1.0 + nt * 5.5)
					var lw = 0.15 + abs(sin(float(i) * 2.3 + nt * 18.0)) * 0.7
					draw_line(Vector2(cos(angle), sin(angle)) * (dist - bs),
						Vector2(cos(angle), sin(angle)) * dist,
						Color(1.0, 1.0, 1.0, lw * (1.0 - nt) * 0.90), bs * 0.22)
				draw_circle(Vector2.ZERO, bs * 2.0 * (1.0 - nt), Color(1.0, 1.0, 1.0, (1.0 - nt) * 0.90))
			else:
				# Scanline-Kollaps
				var nt = (t - 0.32) / 0.68
				var line_h = bs * 2.5 * (1.0 - nt)
				for line in range(10):
					var ly = -line_h + float(line) * (line_h * 2.0 / 10.0)
					var gw = abs(sin(nt * 22.0 + float(line) * 1.6)) * 0.65 + 0.15
					draw_line(Vector2(-bs * 3.5 * (1.0 - nt * 0.9), ly),
						Vector2(bs * 3.5 * (1.0 - nt * 0.9), ly),
						Color(1.0, 1.0, 1.0, gw * alpha), bs * 0.20)
		"buergermeister":
			# Zylinder schießt senkrecht nach oben mit Schweif
			var hat_y = -(bs * 1.62 + t * t * bs * 12.0)
			draw_rect(Rect2(-bs * 0.78, hat_y, bs * 1.56, bs * 0.22), Color(0.04, 0.02, 0.06, alpha))
			draw_rect(Rect2(-bs * 0.56, hat_y - bs * 1.0, bs * 1.12, bs * 1.0), Color(0.04, 0.02, 0.06, alpha))
			draw_rect(Rect2(-bs * 0.54, hat_y - bs * 0.98, bs * 1.08, bs * 0.12), Color(0.88, 0.72, 0.08, alpha))
			for i in range(6):
				var trail_y = hat_y + bs * (0.6 + float(i) * 1.0)
				draw_circle(Vector2(0, trail_y), bs * (0.28 - float(i) * 0.04) * alpha,
					Color(0.38, 0.10, 0.60, (1.0 - float(i) / 6.0) * alpha))
			# Konfetti-Fontäne
			for i in range(20):
				var angle = float(i) * TAU / 20.0 + t * TAU * 0.6
				var dist = bs * (0.5 + t * 8.0)
				var col_i = [Color(0.72, 0.38, 0.96), Color(0.94, 0.78, 0.08), Color(0.14, 0.86, 0.32), Color(0.94, 0.14, 0.14)][i % 4]
				draw_circle(Vector2(cos(angle), sin(angle)) * dist,
					bs * 0.28 * alpha, Color(col_i.r, col_i.g, col_i.b, alpha))
			# Lila Rauchringe
			for i in range(3):
				var r = bs * (2.0 + float(i) * 3.0 + t * 5.0)
				draw_arc(Vector2.ZERO, r, 0, TAU, 16, Color(0.45, 0.10, 0.72, (1.0 - t) * 0.35), bs * 0.50)
		_:
			for i in range(3):
				var r = bs * (2.0 + float(i) * 2.5 + t * 6.0)
				draw_arc(Vector2.ZERO, r, 0, TAU, 20, Color(1.0, 0.5, 0.0, alpha * 0.65), bs * 0.45)

	# ── Blut – gilt für alle Bosse ──────────────────────────────
	var bt = clamp(t * 1.4, 0.0, 1.0)
	var b_alpha = 1.0 - bt
	# 16 Bluttropfen fliegen weit heraus
	for i in range(16):
		var angle = float(i) * TAU / 16.0 + float(i) * 0.31
		var dist = bs * (0.3 + bt * 7.0)
		var sz = bs * (0.42 - bt * 0.28)
		if sz > 0.01:
			draw_circle(Vector2(cos(angle), sin(angle)) * dist, sz,
				Color(0.70, 0.0, 0.02, b_alpha * 0.92))
	# 8 dunkle Blutklumpen mit Schleifspur
	for i in range(8):
		var angle = float(i) * TAU / 8.0 + 0.22
		var dist = bs * (0.6 + bt * 5.0)
		var pos = Vector2(cos(angle), sin(angle)) * dist
		draw_circle(pos, bs * 0.26 * b_alpha, Color(0.48, 0.0, 0.01, b_alpha * 0.85))
		draw_circle(pos * 0.55, bs * 0.18 * b_alpha, Color(0.55, 0.0, 0.02, b_alpha * 0.70))
	# Blutlache am Boden
	draw_circle(Vector2(0.0, bs * 0.6), bs * (0.6 + t * 2.5), Color(0.52, 0.0, 0.01, (1.0 - t) * 0.55))

# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	var flash = _hit_flash > 0
	var bs    = body_size
	var ap    = _aura_pulse

	match enemy_id:
		"grossbauer":     _draw_grossbauer(flash, bs, ap)
		"gefchef":        _draw_gefchef(flash, bs, ap)
		"mega_schwein":   _draw_mega_schwein(flash, bs, ap)
		"sheriff":        _draw_sheriff(flash, bs, ap)
		"trucker":        _draw_trucker(flash, bs, ap)
		"tvstar":         _draw_tvstar(flash, bs, ap)
		"buergermeister": _draw_buergermeister(flash, bs, ap)
		"trump":          _draw_trump(flash, bs, ap)
		_:                _draw_default(flash, bs, ap)

	# HP-Balken (nur wenn lebendig)
	if not _dying:
		var hp_pct = float(current_hp) / float(max_hp)
		var bw     = bs * 3.2
		draw_rect(Rect2(-bw * 0.5, bs + 14, bw, 11), Color(0.08, 0, 0))
		draw_rect(Rect2(-bw * 0.5, bs + 14, bw * hp_pct, 11), accent_color)
		draw_rect(Rect2(-bw * 0.5, bs + 14, bw, 11), Color(0, 0, 0), false, 1.5)
	else:
		_draw_boss_death_particles()

# ─────────────────────────────────────────────────────────────
# GROSSBAUER – South Park Stil: fetter Bauer mit Strohhut
# ─────────────────────────────────────────────────────────────
func _draw_grossbauer(flash: bool, bs: float, ap: float) -> void:
	var sk = Color(0.92, 0.72, 0.52) if not flash else Color.WHITE
	var ov = Color(0.12, 0.14, 0.40) if not flash else Color.WHITE  # dunkelblaue Latzhose
	var sh = Color(0.82, 0.78, 0.60) if not flash else Color.WHITE  # helles Hemd
	var _wc   = sin(_anim_time * 3.5)   # schwerer Bauer, langsam
	var bob   = _wc * bs * 0.06
	var leg_r = _wc * bs * 0.22
	var leg_l = -leg_r
	var arm_r = -leg_r * 0.7
	var arm_l = leg_r * 0.7
	# Erdaura
	for i in range(3):
		var r = bs + 8 + i * 12 + sin(ap + i) * 5
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(0.45, 0.28, 0.04, 0.20 - i * 0.05), 3.0)
	# Stiefel
	draw_rect(Rect2(-bs * 0.88, bs * 1.70 + leg_l * 0.4 + bob, bs * 0.72, bs * 0.22), Color(0.22, 0.12, 0.04))
	draw_rect(Rect2(bs * 0.16, bs * 1.70 + leg_r * 0.4 + bob, bs * 0.72, bs * 0.22), Color(0.22, 0.12, 0.04))
	# Beine (Latzhose)
	draw_rect(Rect2(-bs * 0.85, bs * 0.92 + leg_l * 0.3 + bob, bs * 0.70, bs * 0.80), ov.darkened(0.2))
	draw_rect(Rect2(bs * 0.15, bs * 0.92 + leg_r * 0.3 + bob, bs * 0.70, bs * 0.80), ov.darkened(0.2))
	# Latzhosen-Torso (SP: breites Rechteck)
	draw_rect(Rect2(-bs * 0.95, -bs * 0.20 + bob, bs * 1.90, bs * 1.14), ov)
	# Hemd (oberer Teil sichtbar)
	draw_rect(Rect2(-bs * 0.85, -bs * 0.90 + bob, bs * 1.70, bs * 0.72), sh)
	# Träger (Y-Form)
	draw_rect(Rect2(-bs * 0.32, -bs * 0.90 + bob, bs * 0.22, bs * 0.72), ov)
	draw_rect(Rect2(bs * 0.10, -bs * 0.90 + bob, bs * 0.22, bs * 0.72), ov)
	# Arme (kurze SP-Stubs)
	draw_rect(Rect2(-bs * 1.55, -bs * 0.80 + arm_l + bob, bs * 0.62, bs * 1.05), sh)
	draw_rect(Rect2(bs * 0.93, -bs * 0.80 + arm_r + bob, bs * 0.62, bs * 1.05), sh)
	# Fäuste
	draw_circle(Vector2(-bs * 1.20, bs * 0.30 + arm_l + bob), bs * 0.30, sk)
	draw_circle(Vector2(bs * 1.20, bs * 0.30 + arm_r + bob), bs * 0.30, sk)
	# Heugabel (halten, folgt rechtem Arm)
	var fx = bs * 1.12
	draw_line(Vector2(fx, bs * 0.25 + arm_r + bob), Vector2(fx, -bs * 2.10 + arm_r + bob), Color(0.52, 0.35, 0.10), 5.0)
	for td in [-1, 0, 1]:
		draw_line(Vector2(fx + td * bs * 0.26, -bs * 2.10 + arm_r + bob),
				  Vector2(fx + td * bs * 0.24, -bs * 1.55 + arm_r + bob), Color(0.52, 0.35, 0.10), 4.0)
	# Großer runder Kopf (South Park)
	draw_circle(Vector2(0, -bs * 1.05 + bob * 0.4), bs * 0.62, sk)
	# Böse Augenbrauen (V-Form)
	draw_line(Vector2(-bs * 0.50, -bs * 1.36 + bob * 0.4), Vector2(-bs * 0.12, -bs * 1.20 + bob * 0.4), Color(0.10, 0.05, 0.0), 5.0)
	draw_line(Vector2(bs * 0.12, -bs * 1.20 + bob * 0.4), Vector2(bs * 0.50, -bs * 1.36 + bob * 0.4), Color(0.10, 0.05, 0.0), 5.0)
	# Augen (South Park: weiß + Pupille, rot glühend)
	draw_circle(Vector2(-bs * 0.26, -bs * 1.06 + bob * 0.4), bs * 0.14, Color.WHITE)
	draw_circle(Vector2(bs * 0.26, -bs * 1.06 + bob * 0.4), bs * 0.14, Color.WHITE)
	draw_circle(Vector2(-bs * 0.26, -bs * 1.06 + bob * 0.4), bs * 0.08, Color(0.9, 0.05, 0.05))
	draw_circle(Vector2(bs * 0.26, -bs * 1.06 + bob * 0.4), bs * 0.08, Color(0.9, 0.05, 0.05))
	# Grimmiger Mund (umgekehrter Bogen)
	draw_arc(Vector2(0, -bs * 0.82 + bob * 0.4), bs * 0.22, PI * 1.1, PI * 1.9, 8, Color(0.10, 0.05, 0.02), 3.5)
	# Strohhut (breit, ikonisch)
	draw_rect(Rect2(-bs * 0.98, -bs * 1.76 + bob * 0.4, bs * 1.96, bs * 0.24), Color(0.70, 0.54, 0.20))
	draw_rect(Rect2(-bs * 0.56, -bs * 2.40 + bob * 0.4, bs * 1.12, bs * 0.66), Color(0.74, 0.58, 0.22))
	# Hutstreifen
	draw_line(Vector2(-bs * 0.56, -bs * 1.77 + bob * 0.4), Vector2(bs * 0.56, -bs * 1.77 + bob * 0.4), Color(0.42, 0.28, 0.08), 3.0)
	if _phase == 2:
		var p = abs(sin(ap * 5))
		draw_arc(Vector2.ZERO, bs * 1.18, 0, TAU, 32, Color(1.0, 0.42, 0.0, p * 0.85), 5.0)

# ─────────────────────────────────────────────────────────────
# GEFÄNGNISCHEF – Kalter Wärter-Boss mit Knüppel und Abzeichen
# ─────────────────────────────────────────────────────────────
# GEFÄNGNISCHEF – South Park Stil: Knastwächter Boss
# ─────────────────────────────────────────────────────────────
func _draw_gefchef(flash: bool, bs: float, ap: float) -> void:
	var uc = Color(0.08, 0.12, 0.42) if not flash else Color.WHITE
	var gc = Color(0.88, 0.74, 0.10) if not flash else Color.WHITE
	var sk = Color(0.98, 0.82, 0.66) if not flash else Color.WHITE
	var _wc   = sin(_anim_time * 3.5)   # schwerer Wächter-Boss
	var bob   = _wc * bs * 0.06
	var leg_r = _wc * bs * 0.22
	var leg_l = -leg_r
	var arm_r = -leg_r * 0.7
	var arm_l = leg_r * 0.7
	# Blau-Aura
	for i in range(3):
		var r = bs + 8 + i * 12 + sin(ap + i) * 4
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(0.05, 0.10, 0.55, 0.22 - i * 0.06), 3.0)
	# Stiefel
	draw_rect(Rect2(-bs * 0.88, bs * 1.72 + leg_l * 0.4 + bob, bs * 0.72, bs * 0.22), Color(0.18, 0.12, 0.06))
	draw_rect(Rect2(bs * 0.16, bs * 1.72 + leg_r * 0.4 + bob, bs * 0.72, bs * 0.22), Color(0.18, 0.12, 0.06))
	# Beine
	draw_rect(Rect2(-bs * 0.85, bs * 0.92 + leg_l * 0.3 + bob, bs * 0.70, bs * 0.82), uc.darkened(0.2))
	draw_rect(Rect2(bs * 0.15, bs * 0.92 + leg_r * 0.3 + bob, bs * 0.70, bs * 0.82), uc.darkened(0.2))
	# Uniform-Körper (South Park: breites Rechteck)
	draw_rect(Rect2(-bs * 0.95, -bs * 0.22 + bob, bs * 1.90, bs * 1.16), uc)
	# Gürtel + Schlüsselbund
	draw_rect(Rect2(-bs * 0.95, bs * 0.78 + bob, bs * 1.90, bs * 0.20), Color(0.14, 0.10, 0.04))
	draw_rect(Rect2(-bs * 0.14, bs * 0.76 + bob, bs * 0.28, bs * 0.26), gc)
	for k in range(4):
		draw_circle(Vector2(-bs * 0.62 + float(k) * bs * 0.18, bs * 1.02 + bob), bs * 0.09, gc)
	# Gold-Stern-Abzeichen (Erkennungsmerkmal)
	_draw_star(Vector2(-bs * 0.44, bs * 0.18 + bob), bs * 0.30, gc)
	# Schulterabzeichen
	draw_rect(Rect2(-bs * 1.00, -bs * 0.28 + bob, bs * 0.28, bs * 0.16), gc)
	draw_rect(Rect2(bs * 0.72,  -bs * 0.28 + bob, bs * 0.28, bs * 0.16), gc)
	# Arme (SP-Stubs)
	draw_rect(Rect2(-bs * 1.60, -bs * 0.20 + arm_l + bob, bs * 0.68, bs * 1.08), uc)
	draw_rect(Rect2(bs * 0.92,  -bs * 0.20 + arm_r + bob, bs * 0.68, bs * 1.08), uc)
	# Schlagstock rechts (folgt rechtem Arm)
	draw_line(Vector2(bs * 1.60, bs * 0.30 + arm_r + bob), Vector2(bs * 1.58, bs * 1.40 + arm_r + bob), Color(0.18, 0.10, 0.04), bs * 0.22)
	draw_circle(Vector2(bs * 1.59, bs * 0.35 + arm_r + bob), bs * 0.18, Color(0.24, 0.14, 0.06))
	# Großer runder Kopf (South Park)
	draw_circle(Vector2(0, -bs * 0.95 + bob * 0.4), bs * 0.60, sk)
	# Eiskalte blaue Augen + Brauen
	draw_line(Vector2(-bs * 0.46, -bs * 1.20 + bob * 0.4), Vector2(-bs * 0.10, -bs * 1.07 + bob * 0.4), Color(0.06, 0.04, 0.01), 5.0)
	draw_line(Vector2(bs * 0.10,  -bs * 1.07 + bob * 0.4), Vector2(bs * 0.46,  -bs * 1.20 + bob * 0.4), Color(0.06, 0.04, 0.01), 5.0)
	draw_circle(Vector2(-bs * 0.26, -bs * 0.96 + bob * 0.4), bs * 0.14, Color.WHITE)
	draw_circle(Vector2(bs * 0.26,  -bs * 0.96 + bob * 0.4), bs * 0.14, Color.WHITE)
	draw_circle(Vector2(-bs * 0.26, -bs * 0.96 + bob * 0.4), bs * 0.08, Color(0.12, 0.38, 0.90))
	draw_circle(Vector2(bs * 0.26,  -bs * 0.96 + bob * 0.4), bs * 0.08, Color(0.12, 0.38, 0.90))
	draw_circle(Vector2(-bs * 0.26, -bs * 0.96 + bob * 0.4), bs * 0.04, Color(0.0, 0.0, 0.0))
	draw_circle(Vector2(bs * 0.26,  -bs * 0.96 + bob * 0.4), bs * 0.04, Color(0.0, 0.0, 0.0))
	# Dünner Mund (streng)
	draw_line(Vector2(-bs * 0.22, -bs * 0.76 + bob * 0.4), Vector2(bs * 0.22, -bs * 0.76 + bob * 0.4), Color(0.15, 0.08, 0.04), 3.5)
	# Polizeimütze (South Park: großes Rechteck auf Kopf)
	draw_rect(Rect2(-bs * 0.82, -bs * 1.60 + bob * 0.4, bs * 1.64, bs * 0.26), uc)
	draw_rect(Rect2(-bs * 0.98, -bs * 1.38 + bob * 0.4, bs * 1.96, bs * 0.16), uc)
	draw_rect(Rect2(-bs * 0.58, -bs * 2.12 + bob * 0.4, bs * 1.16, bs * 0.58), uc)
	draw_circle(Vector2(0, -bs * 1.84 + bob * 0.4), bs * 0.22, gc)  # Abzeichen auf Mütze
	if _phase == 2:
		var p = abs(sin(ap * 6))
		draw_arc(Vector2.ZERO, bs * 1.15, 0, TAU, 32, Color(0.2, 0.4, 1.0, p * 0.90), 5.0)

# ─────────────────────────────────────────────────────────────
# MEGA-SCHWEIN – Monster-Wildschwein mit Hauern und Schlammradius
# ─────────────────────────────────────────────────────────────
func _draw_mega_schwein(flash: bool, bs: float, ap: float) -> void:
	# ── South Park Stil: Riesiges Monster-Schwein ──
	var pc  = Color(0.78, 0.40, 0.32) if not flash else Color.WHITE
	var pnk = Color(0.95, 0.62, 0.55) if not flash else Color.WHITE
	var dk  = Color(0.40, 0.20, 0.12) if not flash else Color.WHITE
	# 4-Bein Laufzyklus für das riesige Schwein
	var _wc  = sin(_anim_time * 4.0)   # schweres Boss-Tier, mittellangsam
	var bob  = _wc * bs * 0.05
	var huf0 = _wc * bs * 0.15         # hinten-links
	var huf1 = -_wc * bs * 0.15        # vorne-links
	var huf2 = -_wc * bs * 0.15        # hinten-rechts
	var huf3 = _wc * bs * 0.15         # vorne-rechts
	# Schlammringe
	for i in range(3):
		var r = bs + 10 + i * 14 + sin(ap + float(i) * 1.2) * 6
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(0.30, 0.18, 0.04, 0.24 - float(i) * 0.06), 5.0)
	# Schlamm-Tropfen
	for i in range(6):
		var mx = sin(float(i) * 2.1 + ap * 0.5) * bs * 0.90
		var my = bs * 0.85 + abs(sin(float(i) * 1.7 + ap * 1.2)) * bs * 0.20
		draw_circle(Vector2(mx, my), bs * 0.11 + sin(float(i) + ap) * bs * 0.04, Color(0.22, 0.12, 0.03, 0.80))
	# 4 Hufe (kurze Stubs) – abwechselnd animiert
	var huf_offsets = [huf0, huf1, huf2, huf3]
	var huf_xs = [-bs * 0.62, -bs * 0.20, bs * 0.20, bs * 0.62]
	for hi in range(4):
		var hx = huf_xs[hi]
		var hy = huf_offsets[hi]
		draw_rect(Rect2(hx - bs * 0.18, bs * 0.90 + hy, bs * 0.36, bs * 0.50), dk)
		draw_rect(Rect2(hx - bs * 0.16, bs * 1.36 + hy, bs * 0.32, bs * 0.12), Color(0.10, 0.05, 0.02))
	# Riesiger runder Körper (South Park)
	draw_circle(Vector2(0, bs * 0.12 + bob), bs * 1.05, pc)
	# Rückenborsten (kurze Stacheln)
	for brs in range(7):
		var ba = -PI * 0.88 + float(brs) * PI * 0.30
		draw_line(Vector2(cos(ba) * bs * 0.80, bs * 0.12 + bob + sin(ba) * bs * 0.80),
				  Vector2(cos(ba) * (bs * 1.02), bs * 0.12 + bob + sin(ba) * (bs * 1.02)), dk.lightened(0.2), 3.5)
	# Ohren (Dreiecke)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.88, -bs * 0.86 + bob * 0.4), Vector2(-bs * 0.54, -bs * 1.62 + bob * 0.4), Vector2(-bs * 0.20, -bs * 0.86 + bob * 0.4)]), pc)
	draw_colored_polygon(PackedVector2Array([
		Vector2(bs * 0.20, -bs * 0.86 + bob * 0.4), Vector2(bs * 0.54, -bs * 1.62 + bob * 0.4), Vector2(bs * 0.88, -bs * 0.86 + bob * 0.4)]), pc)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.78, -bs * 0.92 + bob * 0.4), Vector2(-bs * 0.54, -bs * 1.42 + bob * 0.4), Vector2(-bs * 0.28, -bs * 0.92 + bob * 0.4)]),
		Color(0.88, 0.52, 0.50))
	draw_colored_polygon(PackedVector2Array([
		Vector2(bs * 0.28, -bs * 0.92 + bob * 0.4), Vector2(bs * 0.54, -bs * 1.42 + bob * 0.4), Vector2(bs * 0.78, -bs * 0.92 + bob * 0.4)]),
		Color(0.88, 0.52, 0.50))
	# Großer runder Kopf (SP)
	draw_circle(Vector2(0, -bs * 0.60 + bob * 0.4), bs * 0.80, pc)
	# Riesige Schnauze
	draw_circle(Vector2(0, -bs * 0.25 + bob * 0.4), bs * 0.50, pnk)
	draw_circle(Vector2(-bs * 0.21, -bs * 0.24 + bob * 0.4), bs * 0.14, Color(0.28, 0.12, 0.10))
	draw_circle(Vector2(bs * 0.21,  -bs * 0.24 + bob * 0.4), bs * 0.14, Color(0.28, 0.12, 0.10))
	# Riesige Hauer
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.50, bs * 0.10 + bob * 0.4), Vector2(-bs * 0.20, bs * 0.10 + bob * 0.4), Vector2(-bs * 0.35, bs * 0.72 + bob * 0.4)]),
		Color(0.96, 0.92, 0.82))
	draw_colored_polygon(PackedVector2Array([
		Vector2(bs * 0.20, bs * 0.10 + bob * 0.4), Vector2(bs * 0.50, bs * 0.10 + bob * 0.4), Vector2(bs * 0.35, bs * 0.72 + bob * 0.4)]),
		Color(0.96, 0.92, 0.82))
	# Böse Augen (South Park: weiß + rot)
	draw_circle(Vector2(-bs * 0.46, -bs * 0.62 + bob * 0.4), bs * 0.18, Color.WHITE)
	draw_circle(Vector2(bs * 0.46,  -bs * 0.62 + bob * 0.4), bs * 0.18, Color.WHITE)
	draw_circle(Vector2(-bs * 0.46, -bs * 0.62 + bob * 0.4), bs * 0.10, Color(0.90, 0.05, 0.05))
	draw_circle(Vector2(bs * 0.46,  -bs * 0.62 + bob * 0.4), bs * 0.10, Color(0.90, 0.05, 0.05))
	draw_circle(Vector2(-bs * 0.46, -bs * 0.62 + bob * 0.4), bs * 0.05, Color(0.0, 0.0, 0.0))
	draw_circle(Vector2(bs * 0.46,  -bs * 0.62 + bob * 0.4), bs * 0.05, Color(0.0, 0.0, 0.0))
	if _phase == 2:
		var p = abs(sin(ap * 4))
		draw_arc(Vector2.ZERO, bs * 1.22, 0, TAU, 32, Color(0.65, 0.38, 0.05, p), 6.0)

# ─────────────────────────────────────────────────────────────
# SHERIFF – Wild-West-Killer mit Revolvern und Stern
# ─────────────────────────────────────────────────────────────
func _draw_sheriff(flash: bool, bs: float, ap: float) -> void:
	var bc = Color(0.68, 0.50, 0.20) if not flash else Color.WHITE
	var sk = Color(0.88, 0.70, 0.52) if not flash else Color.WHITE
	var gc = Color(0.92, 0.78, 0.18) if not flash else Color.WHITE
	var dc = Color(0.22, 0.14, 0.06) if not flash else Color.WHITE
	var _wc   = sin(_anim_time * 3.8)   # Cowboy-Boss, gemächliches Schreiten
	var bob   = _wc * bs * 0.06
	var leg_r = _wc * bs * 0.20
	var leg_l = -leg_r
	var arm_r = -leg_r * 0.7
	var arm_l = leg_r * 0.7
	for i in range(3):
		var r = bs + 8 + i * 12 + sin(ap + i) * 5
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(0.78, 0.60, 0.22, 0.18 - i * 0.05), 3.0)
	# Stiefel mit Sporen
	draw_rect(Rect2(-bs * 0.82, bs * 1.58 + leg_l * 0.4 + bob, bs * 0.66, bs * 0.22), dc)
	draw_rect(Rect2(bs * 0.16, bs * 1.58 + leg_r * 0.4 + bob, bs * 0.66, bs * 0.22), dc)
	draw_circle(Vector2(-bs * 0.18, bs * 1.82 + leg_l * 0.4 + bob), bs * 0.10, gc)
	draw_circle(Vector2(bs * 0.82, bs * 1.82 + leg_r * 0.4 + bob), bs * 0.10, gc)
	# Beine (Jeans)
	draw_rect(Rect2(-bs * 0.78, bs * 0.72 + leg_l * 0.3 + bob, bs * 0.62, bs * 0.88), Color(0.18, 0.25, 0.48))
	draw_rect(Rect2(bs * 0.16, bs * 0.72 + leg_r * 0.3 + bob, bs * 0.62, bs * 0.88), Color(0.18, 0.25, 0.48))
	# Körper (Weste)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.88, -bs * 0.18 + bob), Vector2(bs * 0.88, -bs * 0.18 + bob),
		Vector2(bs * 0.92, bs * 0.80 + bob), Vector2(-bs * 0.92, bs * 0.80 + bob)]), bc)
	# Hemd-Mitte
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.28, -bs * 0.18 + bob), Vector2(bs * 0.28, -bs * 0.18 + bob),
		Vector2(bs * 0.22, bs * 0.80 + bob), Vector2(-bs * 0.22, bs * 0.80 + bob)]),
		Color(0.92, 0.88, 0.75))
	# Bandelier diagonal
	draw_line(Vector2(-bs * 0.88, -bs * 0.18 + bob), Vector2(bs * 0.72, bs * 0.80 + bob), dc, 6.0)
	for k in range(7):
		var t = k / 6.0
		draw_circle(Vector2(-bs * 0.88 + t * bs * 1.60, -bs * 0.18 + t * bs * 0.98 + bob),
				   bs * 0.07, Color(0.55, 0.42, 0.10))
	# GOLD-SHERIFF-STERN (Hauptmerkmal!)
	_draw_star(Vector2(bs * 0.42, bs * 0.22 + bob), bs * 0.35, gc)
	# Gürtel
	draw_rect(Rect2(-bs * 0.92, bs * 0.65 + bob, bs * 1.84, bs * 0.18), dc)
	draw_rect(Rect2(-bs * 0.16, bs * 0.62 + bob, bs * 0.32, bs * 0.24), gc)
	# Arme breit ausgestreckt
	draw_rect(Rect2(-bs * 1.68, -bs * 0.14 + arm_l + bob, bs * 0.82, bs * 0.68), bc)
	draw_rect(Rect2(bs * 0.88, -bs * 0.14 + arm_r + bob, bs * 0.82, bs * 0.68), bc)
	# Revolver links (folgt linkem Arm)
	draw_rect(Rect2(-bs * 1.88, bs * 0.28 + arm_l + bob, bs * 0.58, bs * 0.24), Color(0.14, 0.10, 0.06))
	draw_rect(Rect2(-bs * 1.52, bs * 0.12 + arm_l + bob, bs * 0.16, bs * 0.42), Color(0.14, 0.10, 0.06))
	draw_circle(Vector2(-bs * 1.65, bs * 0.30 + arm_l + bob), bs * 0.14, Color(0.20, 0.14, 0.08))
	# Revolver rechts (folgt rechtem Arm)
	draw_rect(Rect2(bs * 1.32, bs * 0.28 + arm_r + bob, bs * 0.58, bs * 0.24), Color(0.14, 0.10, 0.06))
	draw_rect(Rect2(bs * 1.38, bs * 0.12 + arm_r + bob, bs * 0.16, bs * 0.42), Color(0.14, 0.10, 0.06))
	draw_circle(Vector2(bs * 1.49, bs * 0.30 + arm_r + bob), bs * 0.14, Color(0.20, 0.14, 0.08))
	# Kopf
	draw_circle(Vector2(0, -bs * 0.90 + bob * 0.4), bs * 0.54, sk)
	# Squint-Augen
	draw_line(Vector2(-bs * 0.40, -bs * 0.98 + bob * 0.4), Vector2(-bs * 0.12, -bs * 0.98 + bob * 0.4), dc, 4.0)
	draw_line(Vector2(bs * 0.12, -bs * 0.98 + bob * 0.4), Vector2(bs * 0.40, -bs * 0.98 + bob * 0.4), dc, 4.0)
	draw_circle(Vector2(-bs * 0.26, -bs * 0.94 + bob * 0.4), bs * 0.10, Color(0.40, 0.28, 0.08))
	draw_circle(Vector2(bs * 0.26, -bs * 0.94 + bob * 0.4), bs * 0.10, Color(0.40, 0.28, 0.08))
	# Schnauzbart
	draw_arc(Vector2(-bs * 0.22, -bs * 0.74 + bob * 0.4), bs * 0.22, PI * 0.75, PI * 1.75, 8, dc, 3.5)
	draw_arc(Vector2(bs * 0.22, -bs * 0.74 + bob * 0.4), bs * 0.22, PI * 1.25, PI * 2.25, 8, dc, 3.5)
	# Cowboyhut
	draw_rect(Rect2(-bs * 0.96, -bs * 1.52 + bob * 0.4, bs * 1.92, bs * 0.24), Color(0.45, 0.28, 0.10))
	draw_rect(Rect2(-bs * 0.58, -bs * 2.18 + bob * 0.4, bs * 1.16, bs * 0.68), Color(0.48, 0.30, 0.11))
	draw_line(Vector2(-bs * 0.54, -bs * 1.65 + bob * 0.4), Vector2(bs * 0.54, -bs * 1.65 + bob * 0.4), dc, 3.0)
	draw_rect(Rect2(-bs * 0.56, -bs * 2.16 + bob * 0.4, bs * 1.12, bs * 0.12), gc)
	if _phase == 2:
		var p = abs(sin(ap * 5))
		draw_arc(Vector2.ZERO, bs * 1.18, 0, TAU, 32, Color(1.0, 0.65, 0.0, p * 0.90), 5.0)

# ─────────────────────────────────────────────────────────────
# TRUCKER – Muskelkoloss mit Kette, Vollbart und Tattoos
# ─────────────────────────────────────────────────────────────
func _draw_trucker(flash: bool, bs: float, ap: float) -> void:
	var bc = Color(0.40, 0.20, 0.12) if not flash else Color.WHITE
	var sk = Color(0.82, 0.62, 0.46) if not flash else Color.WHITE
	var ac = Color(0.85, 0.40, 0.12) if not flash else Color.WHITE
	var jc = Color(0.15, 0.10, 0.06) if not flash else Color.WHITE
	var _wc   = sin(_anim_time * 3.5)   # massiver Trucker, schwere Schritte
	var bob   = _wc * bs * 0.07
	var leg_r = _wc * bs * 0.24
	var leg_l = -leg_r
	var arm_r = -leg_r * 0.7
	var arm_l = leg_r * 0.7
	for i in range(3):
		var r = bs + 8 + i * 12 + sin(ap + i) * 5
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(0.60, 0.28, 0.06, 0.22 - i * 0.06), 4.0)
	# Stiefel
	draw_rect(Rect2(-bs * 0.84, bs * 1.72 + leg_l * 0.4 + bob, bs * 0.72, bs * 0.24), Color(0.10, 0.06, 0.02))
	draw_rect(Rect2(bs * 0.12, bs * 1.72 + leg_r * 0.4 + bob, bs * 0.72, bs * 0.24), Color(0.10, 0.06, 0.02))
	# Beine
	draw_rect(Rect2(-bs * 0.80, bs * 0.78 + leg_l * 0.3 + bob, bs * 0.68, bs * 0.96), jc)
	draw_rect(Rect2(bs * 0.12, bs * 0.78 + leg_r * 0.3 + bob, bs * 0.68, bs * 0.96), jc)
	# Barrel-Chest (massiver Keil)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 1.12, -bs * 0.28 + bob), Vector2(bs * 1.12, -bs * 0.28 + bob),
		Vector2(bs * 1.00, bs * 0.82 + bob), Vector2(-bs * 1.00, bs * 0.82 + bob)]), bc)
	# Leder-Weste Mitte
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.42, -bs * 0.28 + bob), Vector2(bs * 0.42, -bs * 0.28 + bob),
		Vector2(bs * 0.32, bs * 0.82 + bob), Vector2(-bs * 0.32, bs * 0.82 + bob)]),
		Color(0.14, 0.08, 0.04))
	# Nieten-Streifen
	for row in range(3):
		draw_line(Vector2(-bs * 0.95, bs * 0.05 + row * bs * 0.25 + bob),
				  Vector2(bs * 0.95, bs * 0.05 + row * bs * 0.25 + bob), ac, 2.0)
	# Massive Arme
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 1.12, -bs * 0.26 + arm_l + bob), Vector2(-bs * 0.88, -bs * 0.26 + arm_l + bob),
		Vector2(-bs * 0.70, bs * 0.80 + arm_l + bob), Vector2(-bs * 1.65, bs * 0.80 + arm_l + bob)]), sk)
	draw_colored_polygon(PackedVector2Array([
		Vector2(bs * 0.88, -bs * 0.26 + arm_r + bob), Vector2(bs * 1.12, -bs * 0.26 + arm_r + bob),
		Vector2(bs * 1.65, bs * 0.80 + arm_r + bob), Vector2(bs * 0.70, bs * 0.80 + arm_r + bob)]), sk)
	# Tattoos (folgen Armen)
	draw_line(Vector2(-bs * 1.55, bs * 0.05 + arm_l + bob), Vector2(-bs * 1.05, bs * 0.35 + arm_l + bob), ac, 2.5)
	draw_line(Vector2(-bs * 1.52, bs * 0.28 + arm_l + bob), Vector2(-bs * 1.05, bs * 0.50 + arm_l + bob), ac, 1.8)
	draw_line(Vector2(bs * 1.05, bs * 0.05 + arm_r + bob), Vector2(bs * 1.58, bs * 0.35 + arm_r + bob), ac, 2.5)
	draw_line(Vector2(bs * 1.05, bs * 0.28 + arm_r + bob), Vector2(bs * 1.55, bs * 0.50 + arm_r + bob), ac, 1.8)
	# Fäuste mit Knöcheln
	draw_circle(Vector2(-bs * 1.42, bs * 0.82 + arm_l + bob), bs * 0.32, sk)
	draw_circle(Vector2(bs * 1.42, bs * 0.82 + arm_r + bob), bs * 0.32, sk)
	for kn in range(4):
		draw_arc(Vector2(-bs * 1.42 + (-1.5 + kn) * bs * 0.14, bs * 0.76 + arm_l + bob),
				 bs * 0.06, PI, TAU, 6, Color(0.55, 0.40, 0.28), 2.5)
		draw_arc(Vector2(bs * 1.42 + (-1.5 + kn) * bs * 0.14, bs * 0.76 + arm_r + bob),
				 bs * 0.06, PI, TAU, 6, Color(0.55, 0.40, 0.28), 2.5)
	# Animierte Kette (links, folgt linkem Arm)
	for k in range(6):
		var ka   = ap * 2.5 + k * 0.55
		var kpos = Vector2(-bs * 1.38 + sin(ka) * bs * 0.20,
						   bs * 0.82 + arm_l + bob + k * bs * 0.22 + cos(ka) * bs * 0.10)
		draw_circle(kpos, bs * 0.12, Color(0.58, 0.48, 0.15))
		if k > 0:
			var ka_p = ap * 2.5 + (k - 1) * 0.55
			draw_line(kpos, Vector2(-bs * 1.38 + sin(ka_p) * bs * 0.20,
				bs * 0.82 + arm_l + bob + (k-1) * bs * 0.22 + cos(ka_p) * bs * 0.10),
				Color(0.55, 0.45, 0.12), 2.0)
	# Kopf
	draw_circle(Vector2(0, -bs * 0.90 + bob * 0.4), bs * 0.60, sk)
	draw_rect(Rect2(-bs * 0.45, -bs * 0.32 + bob * 0.4, bs * 0.90, bs * 0.18), sk)
	# Vollbart
	var beard_pts = PackedVector2Array()
	for bi in range(18):
		var ba = PI * bi / 17.0
		beard_pts.append(Vector2(cos(ba) * bs * 0.55, -bs * 0.90 + bob * 0.4 + sin(ba) * bs * 0.45))
	draw_colored_polygon(beard_pts, Color(0.12, 0.07, 0.03))
	for bl in range(5):
		draw_line(Vector2(-bs * 0.42 + bl * bs * 0.21, -bs * 0.55 + bob * 0.4),
				  Vector2(-bs * 0.38 + bl * bs * 0.21, -bs * 0.46 + bob * 0.4),
				  Color(0.06, 0.04, 0.01), 1.5)
	# Tiefe wütende Augen
	draw_line(Vector2(-bs * 0.50, -bs * 1.10 + bob * 0.4), Vector2(-bs * 0.12, -bs * 1.18 + bob * 0.4),
			  Color(0.10, 0.05, 0.02), 5.0)
	draw_line(Vector2(bs * 0.12, -bs * 1.18 + bob * 0.4), Vector2(bs * 0.50, -bs * 1.10 + bob * 0.4),
			  Color(0.10, 0.05, 0.02), 5.0)
	draw_circle(Vector2(-bs * 0.30, -bs * 1.08 + bob * 0.4), bs * 0.13, Color(0.72, 0.12, 0.08))
	draw_circle(Vector2(bs * 0.30, -bs * 1.08 + bob * 0.4), bs * 0.13, Color(0.72, 0.12, 0.08))
	# Trucker-Cap
	draw_rect(Rect2(-bs * 0.65, -bs * 1.65 + bob * 0.4, bs * 1.30, bs * 0.70), Color(0.12, 0.08, 0.06))
	draw_rect(Rect2(-bs * 0.65, -bs * 0.98 + bob * 0.4, bs * 0.95, bs * 0.24), Color(0.10, 0.07, 0.04))
	draw_rect(Rect2(-bs * 0.63, -bs * 1.63 + bob * 0.4, bs * 1.26, bs * 0.14), ac)
	for nc in range(4):
		draw_line(Vector2(bs * 0.05 + nc * bs * 0.18, -bs * 1.58 + bob * 0.4),
				  Vector2(bs * 0.05 + nc * bs * 0.18, -bs * 0.98 + bob * 0.4),
				  Color(ac.r, ac.g, ac.b, 0.25), 1.5)
	if _phase == 2:
		var p = abs(sin(ap * 5))
		draw_arc(Vector2.ZERO, bs * 1.25, 0, TAU, 32, Color(1.0, 0.32, 0.0, p), 6.0)

# ─────────────────────────────────────────────────────────────
# TV-STAR – Fernsehkopf-Monster mit Halo und Glitch-Effekten
# ─────────────────────────────────────────────────────────────
func _draw_tvstar(flash: bool, bs: float, ap: float) -> void:
	var bc  = Color(0.82, 0.62, 0.04) if not flash else Color.WHITE
	var sc  = Color(0.04, 0.05, 0.15) if not flash else Color.WHITE
	var _wc   = sin(_anim_time * 4.0)   # TV-Star, schwebend-groovend
	var bob   = _wc * bs * 0.06
	var leg_r = _wc * bs * 0.20
	var leg_l = -leg_r
	var arm_r = -leg_r * 0.7
	var arm_l = leg_r * 0.7
	for i in range(4):
		var r = bs + 6 + i * 10 + sin(ap * 2 + i) * 6
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(0.95, 0.85, 0.10, 0.22 - i * 0.04), 3.0)
	# Glitzer-Sterne
	for st in range(8):
		var sa = st * TAU / 8.0 + ap * 0.6
		var sr = bs * (1.15 + sin(ap * 3 + st) * 0.25)
		_draw_sparkle(Vector2(cos(sa), sin(sa)) * sr, bs * 0.14, Color(1.0, 0.92, 0.22, 0.85))
	# Beine (Smoking)
	draw_rect(Rect2(-bs * 0.60, bs * 0.90 + leg_l * 0.3 + bob, bs * 0.48, bs * 0.90), bc.darkened(0.35))
	draw_rect(Rect2(bs * 0.12, bs * 0.90 + leg_r * 0.3 + bob, bs * 0.48, bs * 0.90), bc.darkened(0.35))
	draw_rect(Rect2(-bs * 0.62, bs * 1.72 + leg_l * 0.4 + bob, bs * 0.50, bs * 0.20), Color(0.10, 0.08, 0.04))
	draw_rect(Rect2(bs * 0.12, bs * 1.72 + leg_r * 0.4 + bob, bs * 0.50, bs * 0.20), Color(0.10, 0.08, 0.04))
	# Smoking-Jacke
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.72, -bs * 0.18 + bob), Vector2(bs * 0.72, -bs * 0.18 + bob),
		Vector2(bs * 0.78, bs * 0.98 + bob), Vector2(-bs * 0.78, bs * 0.98 + bob)]), bc)
	# Smoking-Revers
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.25, -bs * 0.18 + bob), Vector2(0, bs * 0.40 + bob),
		Vector2(-bs * 0.62, bs * 0.40 + bob), Vector2(-bs * 0.72, -bs * 0.18 + bob)]),
		Color(bc.r * 0.72, bc.g * 0.72, bc.b * 0.72))
	draw_colored_polygon(PackedVector2Array([
		Vector2(bs * 0.25, -bs * 0.18 + bob), Vector2(bs * 0.72, -bs * 0.18 + bob),
		Vector2(bs * 0.62, bs * 0.40 + bob), Vector2(0, bs * 0.40 + bob)]),
		Color(bc.r * 0.72, bc.g * 0.72, bc.b * 0.72))
	# Fliege
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.24, -bs * 0.14 + bob), Vector2(0, bs * 0.02 + bob),
		Vector2(-bs * 0.24, bs * 0.18 + bob)]), Color(0.75, 0.04, 0.04))
	draw_colored_polygon(PackedVector2Array([
		Vector2(bs * 0.24, -bs * 0.14 + bob), Vector2(0, bs * 0.02 + bob),
		Vector2(bs * 0.24, bs * 0.18 + bob)]), Color(0.75, 0.04, 0.04))
	# Arme
	draw_rect(Rect2(-bs * 1.35, -bs * 0.15 + arm_l + bob, bs * 0.65, bs * 0.82), bc)
	draw_rect(Rect2(bs * 0.72, -bs * 0.15 + arm_r + bob, bs * 0.65, bs * 0.82), bc)
	# Mikrofon links (folgt linkem Arm)
	draw_line(Vector2(-bs * 0.75, bs * 0.65 + arm_l + bob), Vector2(-bs * 1.22, bs * 1.55 + arm_l + bob),
			  Color(0.25, 0.25, 0.25), 3.5)
	draw_circle(Vector2(-bs * 1.22, bs * 1.55 + arm_l + bob), bs * 0.24, Color(0.20, 0.20, 0.20))
	draw_circle(Vector2(-bs * 1.22, bs * 1.55 + arm_l + bob), bs * 0.16, Color(0.35, 0.35, 0.35))
	# TV-KOPF Gehäuse (folgt Bob)
	draw_rect(Rect2(-bs * 0.96, -bs * 2.08 + bob * 0.4, bs * 1.92, bs * 1.52), Color(0.22, 0.18, 0.12))
	# Bildschirm
	draw_rect(Rect2(-bs * 0.88, -bs * 2.00 + bob * 0.4, bs * 1.76, bs * 1.36), sc)
	# Glitch-Linien animiert
	for gl in range(5):
		var gy  = -bs * 1.92 + bob * 0.4 + gl * bs * 0.24 + sin(ap * 8 + gl * 1.4) * bs * 0.05
		var glw = 0.30 + sin(ap * 12 + gl) * 0.25
		draw_line(Vector2(-bs * 0.78, gy), Vector2(bs * 0.78, gy),
				  Color(0.08, 0.42, 0.90, glw), 2.0)
	# Böses Lächeln
	draw_arc(Vector2(0, -bs * 1.12 + bob * 0.4), bs * 0.44, 0.12, PI - 0.12, 12,
			 Color(0.90, 0.90, 0.12), 4.0)
	# Augen als X-Kreuze
	_draw_sparkle(Vector2(-bs * 0.42, -bs * 1.52 + bob * 0.4), bs * 0.22, Color(0.90, 0.18, 0.18))
	_draw_sparkle(Vector2(bs * 0.42, -bs * 1.52 + bob * 0.4), bs * 0.22, Color(0.90, 0.18, 0.18))
	# Antennen
	draw_line(Vector2(-bs * 0.38, -bs * 2.08 + bob * 0.4), Vector2(-bs * 0.70, -bs * 2.88 + bob * 0.4),
			  Color(0.52, 0.48, 0.32), 3.5)
	draw_line(Vector2(bs * 0.38, -bs * 2.08 + bob * 0.4), Vector2(bs * 0.70, -bs * 2.88 + bob * 0.4),
			  Color(0.52, 0.48, 0.32), 3.5)
	draw_circle(Vector2(-bs * 0.72, -bs * 2.92 + bob * 0.4), bs * 0.12, Color(0.95, 0.85, 0.12))
	draw_circle(Vector2(bs * 0.72, -bs * 2.92 + bob * 0.4), bs * 0.12, Color(0.95, 0.85, 0.12))
	# Heiligenschein
	var halo_a = 0.85 + sin(ap * 3) * 0.15
	draw_arc(Vector2(0, -bs * 2.20 + bob * 0.4), bs * 0.72, 0, TAU, 32,
			 Color(0.95, 0.85, 0.12, halo_a), 5.0)
	for hi in range(8):
		var ha = hi * TAU / 8.0 + ap * 0.4
		draw_circle(Vector2(0, -bs * 2.20 + bob * 0.4) + Vector2(cos(ha), sin(ha)) * bs * 0.72,
				   bs * 0.09, Color(1.0, 0.92, 0.32))
	if _phase == 2:
		var p = abs(sin(ap * 6))
		draw_arc(Vector2(0, -bs * 1.32 + bob * 0.4), bs * 1.10, 0, TAU, 32,
				Color(1.0, 0.22, 0.88, p * 0.85), 5.0)

# ─────────────────────────────────────────────────────────────
# BÜRGERMEISTER – Aufgeblasener Korruptions-Despot mit Zylinder
# ─────────────────────────────────────────────────────────────
func _draw_buergermeister(flash: bool, bs: float, ap: float) -> void:
	var pc  = Color(0.24, 0.14, 0.44) if not flash else Color.WHITE
	var ac2 = Color(0.65, 0.40, 0.90) if not flash else Color.WHITE
	var sk  = Color(0.88, 0.70, 0.55) if not flash else Color.WHITE
	var gc  = Color(0.88, 0.72, 0.08) if not flash else Color.WHITE
	var _wc   = sin(_anim_time * 3.0)   # pompöser Despot, würdevoll langsam
	var bob   = _wc * bs * 0.06
	var leg_r = _wc * bs * 0.18
	var leg_l = -leg_r
	var arm_r = -leg_r * 0.5   # Arme auf Hüfte, weniger Schwung
	var arm_l = leg_r * 0.5
	for i in range(3):
		var r = bs + 8 + i * 12 + sin(ap + i) * 5
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(0.45, 0.10, 0.72, 0.22 - i * 0.05), 3.0)
	# Kurze dicke Beine
	draw_rect(Rect2(-bs * 0.82, bs * 1.70 + leg_l * 0.4 + bob, bs * 0.68, bs * 0.22), Color(0.10, 0.06, 0.04))
	draw_rect(Rect2(bs * 0.14, bs * 1.70 + leg_r * 0.4 + bob, bs * 0.68, bs * 0.22), Color(0.10, 0.06, 0.04))
	draw_rect(Rect2(-bs * 0.78, bs * 0.92 + leg_l * 0.3 + bob, bs * 0.65, bs * 0.80), pc.darkened(0.22))
	draw_rect(Rect2(bs * 0.13, bs * 0.92 + leg_r * 0.3 + bob, bs * 0.65, bs * 0.80), pc.darkened(0.22))
	# RIESIGER BAUCH (Hauptmerkmal!)
	draw_circle(Vector2(0, bs * 0.40 + bob), bs * 1.08, pc)
	draw_circle(Vector2(0, bs * 0.55 + bob), bs * 0.85, Color(pc.r * 1.30, pc.g * 1.30, pc.b * 1.30, 0.40))
	# Sakko
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 1.05, -bs * 0.25 + bob), Vector2(bs * 1.05, -bs * 0.25 + bob),
		Vector2(bs * 1.08, bs * 0.42 + bob), Vector2(-bs * 1.08, bs * 0.42 + bob)]), pc)
	# Grüne Schärpe diagonal
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 1.05, -bs * 0.25 + bob), Vector2(-bs * 0.62, -bs * 0.25 + bob),
		Vector2(bs * 0.85, bs * 0.88 + bob), Vector2(bs * 0.42, bs * 0.88 + bob)]),
		Color(0.06, 0.45, 0.12))
	draw_line(Vector2(-bs * 1.05, -bs * 0.25 + bob), Vector2(bs * 0.85, bs * 0.88 + bob), gc, 2.5)
	draw_line(Vector2(-bs * 0.62, -bs * 0.25 + bob), Vector2(bs * 0.42, bs * 0.88 + bob), gc, 2.5)
	# Orden auf Schärpe
	for med in range(4):
		var mt = med / 3.0
		var mp = Vector2(-bs * 0.95 + mt * bs * 1.82, -bs * 0.25 + mt * bs * 1.15 + bob)
		draw_circle(mp, bs * 0.15, gc)
		draw_circle(mp, bs * 0.08, Color(0.65, 0.06, 0.06))
	# Arme auf Hüfte (pompöse Pose)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 1.05, -bs * 0.22 + arm_l + bob), Vector2(-bs * 0.88, -bs * 0.22 + arm_l + bob),
		Vector2(-bs * 0.62, bs * 0.65 + arm_l + bob), Vector2(-bs * 1.62, bs * 0.65 + arm_l + bob)]), pc)
	draw_colored_polygon(PackedVector2Array([
		Vector2(bs * 0.88, -bs * 0.22 + arm_r + bob), Vector2(bs * 1.05, -bs * 0.22 + arm_r + bob),
		Vector2(bs * 1.62, bs * 0.65 + arm_r + bob), Vector2(bs * 0.62, bs * 0.65 + arm_r + bob)]), pc)
	draw_circle(Vector2(-bs * 1.05, bs * 0.68 + arm_l + bob), bs * 0.30, sk)
	draw_circle(Vector2(bs * 1.05, bs * 0.68 + arm_r + bob), bs * 0.30, sk)
	# Kopf mit dicken Backen
	draw_circle(Vector2(0, -bs * 0.90 + bob * 0.4), bs * 0.62, sk)
	draw_circle(Vector2(-bs * 0.52, -bs * 0.80 + bob * 0.4), bs * 0.34,
			   Color(sk.r * 1.04, sk.g * 0.92, sk.b * 0.88))
	draw_circle(Vector2(bs * 0.52, -bs * 0.80 + bob * 0.4), bs * 0.34,
			   Color(sk.r * 1.04, sk.g * 0.92, sk.b * 0.88))
	# Herablassende Augen
	draw_line(Vector2(-bs * 0.44, -bs * 1.04 + bob * 0.4), Vector2(-bs * 0.12, -bs * 0.98 + bob * 0.4),
			  Color(0.10, 0.05, 0.05), 4.0)
	draw_line(Vector2(bs * 0.12, -bs * 0.98 + bob * 0.4), Vector2(bs * 0.44, -bs * 1.04 + bob * 0.4),
			  Color(0.10, 0.05, 0.05), 4.0)
	draw_circle(Vector2(-bs * 0.30, -bs * 0.99 + bob * 0.4), bs * 0.13, Color(0.35, 0.12, 0.52))
	draw_circle(Vector2(bs * 0.30, -bs * 0.99 + bob * 0.4), bs * 0.13, Color(0.35, 0.12, 0.52))
	# Gezwirbelter Schnurrbart
	draw_arc(Vector2(-bs * 0.24, -bs * 0.76 + bob * 0.4), bs * 0.24, PI * 0.80, PI * 1.80, 10,
			 Color(0.45, 0.28, 0.10), 3.5)
	draw_arc(Vector2(bs * 0.24, -bs * 0.76 + bob * 0.4), bs * 0.24, PI * 1.20, PI * 2.20, 10,
			 Color(0.45, 0.28, 0.10), 3.5)
	draw_circle(Vector2(0, -bs * 0.88 + bob * 0.4), bs * 0.14,
			   Color(sk.r * 0.90, sk.g * 0.82, sk.b * 0.80))
	# Zylinder
	draw_rect(Rect2(-bs * 0.78, -bs * 1.60 + bob * 0.4, bs * 1.56, bs * 0.22), Color(0.04, 0.02, 0.06))
	draw_rect(Rect2(-bs * 0.56, -bs * 2.58 + bob * 0.4, bs * 1.12, bs * 1.00), Color(0.04, 0.02, 0.06))
	draw_rect(Rect2(-bs * 0.54, -bs * 2.56 + bob * 0.4, bs * 1.08, bs * 0.11), gc)
	draw_line(Vector2(-bs * 0.40, -bs * 2.52 + bob * 0.4), Vector2(-bs * 0.34, -bs * 1.62 + bob * 0.4),
			  Color(0.28, 0.16, 0.44, 0.50), 3.5)
	if _phase == 2:
		var p = abs(sin(ap * 5))
		draw_arc(Vector2.ZERO, bs * 1.30, 0, TAU, 32, Color(0.65, 0.0, 0.95, p * 0.90), 6.0)

# ─────────────────────────────────────────────────────────────
# DONALD TRUMP – Oranger Präsident mit Combover und langer Krawatte
# ─────────────────────────────────────────────────────────────
func _draw_trump(flash: bool, bs: float, ap: float) -> void:
	var sk  = Color(0.88, 0.54, 0.22) if not flash else Color.WHITE   # orange Haut
	var su  = Color(0.10, 0.12, 0.38) if not flash else Color.WHITE   # dunkelblauer Anzug
	var tie = Color(0.85, 0.06, 0.06) if not flash else Color.WHITE   # rote lange Krawatte
	var hr  = Color(0.88, 0.78, 0.32) if not flash else Color.WHITE   # goldblondes Haar
	var wh  = Color(0.96, 0.95, 0.92) if not flash else Color.WHITE   # Hemd (weiß)
	# Patriotische Aura (Rot-Weiß-Blau)
	for i in range(3):
		var r = bs + 8 + i * 12 + sin(ap + i) * 5
		var ac3 = [Color(0.85, 0.10, 0.10, 0.20 - i * 0.05),
				   Color(0.90, 0.90, 0.90, 0.12 - i * 0.03),
				   Color(0.15, 0.20, 0.75, 0.18 - i * 0.05)][i]
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, ac3, 3.0)
	# Schuhe
	draw_rect(Rect2(-bs * 0.88, bs * 1.78, bs * 0.72, bs * 0.20), Color(0.08, 0.06, 0.04))
	draw_rect(Rect2(bs * 0.16, bs * 1.78, bs * 0.72, bs * 0.20), Color(0.08, 0.06, 0.04))
	# Beine (Anzughose)
	draw_rect(Rect2(-bs * 0.84, bs * 0.90, bs * 0.70, bs * 0.90), su.darkened(0.18))
	draw_rect(Rect2(bs * 0.14, bs * 0.90, bs * 0.70, bs * 0.90), su.darkened(0.18))
	# Körper – dicker Anzugbauch
	draw_circle(Vector2(0, bs * 0.30), bs * 1.08, su)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 1.05, -bs * 0.22), Vector2(bs * 1.05, -bs * 0.22),
		Vector2(bs * 1.10, bs * 0.44), Vector2(-bs * 1.10, bs * 0.44)]), su)
	# Weißes Hemd Mitte
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.26, -bs * 0.22), Vector2(bs * 0.26, -bs * 0.22),
		Vector2(bs * 0.20, bs * 0.90), Vector2(-bs * 0.20, bs * 0.90)]), wh)
	# Anzug-Revers
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 1.05, -bs * 0.22), Vector2(-bs * 0.26, -bs * 0.22),
		Vector2(-bs * 0.05, bs * 0.28), Vector2(-bs * 0.65, bs * 0.28)]), su.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([
		Vector2(bs * 0.26, -bs * 0.22), Vector2(bs * 1.05, -bs * 0.22),
		Vector2(bs * 0.65, bs * 0.28), Vector2(bs * 0.05, bs * 0.28)]), su.lightened(0.08))
	# Amerikanische Flaggen-Anstecknadel (links)
	draw_rect(Rect2(-bs * 0.76, bs * 0.02, bs * 0.24, bs * 0.16), Color(0.85, 0.10, 0.10))
	for fi in range(3):
		draw_rect(Rect2(-bs * 0.76, bs * 0.02 + fi * bs * 0.055, bs * 0.24, bs * 0.053),
				  Color(1.0, 1.0, 1.0, 0.8) if fi % 2 == 0 else Color(0.85, 0.10, 0.10))
	draw_rect(Rect2(-bs * 0.76, bs * 0.02, bs * 0.10, bs * 0.10), Color(0.12, 0.18, 0.65))
	# LANGE ROTE KRAWATTE (Trump-Markenzeichen – zu lang!)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.14, -bs * 0.20), Vector2(bs * 0.14, -bs * 0.20),
		Vector2(bs * 0.18, bs * 0.50), Vector2(bs * 0.22, bs * 1.80),
		Vector2(0, bs * 2.08), Vector2(-bs * 0.22, bs * 1.80),
		Vector2(-bs * 0.18, bs * 0.50)]), tie)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.05, -bs * 0.20), Vector2(bs * 0.05, -bs * 0.20),
		Vector2(bs * 0.08, bs * 0.80), Vector2(0, bs * 0.95),
		Vector2(-bs * 0.08, bs * 0.80)]), Color(tie.r * 0.72, tie.g * 0.06, tie.b * 0.06))
	# Krawatten-Knoten
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.18, -bs * 0.22), Vector2(bs * 0.18, -bs * 0.22),
		Vector2(bs * 0.14, bs * 0.02), Vector2(0, bs * 0.12),
		Vector2(-bs * 0.14, bs * 0.02)]), tie.lightened(0.12))
	# Arme
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 1.05, -bs * 0.20), Vector2(-bs * 0.85, -bs * 0.20),
		Vector2(-bs * 0.60, bs * 0.80), Vector2(-bs * 1.50, bs * 0.80)]), su)
	draw_colored_polygon(PackedVector2Array([
		Vector2(bs * 0.85, -bs * 0.20), Vector2(bs * 1.05, -bs * 0.20),
		Vector2(bs * 1.50, bs * 0.80), Vector2(bs * 0.60, bs * 0.80)]), su)
	# Kleine Hände (Trump-Merkmal!)
	draw_circle(Vector2(-bs * 0.95, bs * 0.82), bs * 0.22, sk)
	draw_circle(Vector2(bs * 0.95, bs * 0.82), bs * 0.22, sk)
	for fn in range(3):
		var fa = PI * 0.35 + fn * PI * 0.15
		draw_line(Vector2(-bs * 0.95, bs * 0.82),
				  Vector2(-bs * 0.95 + cos(fa + PI) * bs * 0.18, bs * 0.82 + sin(fa + PI) * bs * 0.18), sk, 3.0)
		draw_line(Vector2(bs * 0.95, bs * 0.82),
				  Vector2(bs * 0.95 + cos(-fa) * bs * 0.18, bs * 0.82 + sin(-fa) * bs * 0.18), sk, 3.0)
	# Orangefetter Hals
	draw_rect(Rect2(-bs * 0.28, -bs * 0.28, bs * 0.56, bs * 0.28), sk)
	# Kopf (rund, orange)
	draw_circle(Vector2(0, -bs * 0.95), bs * 0.68, sk)
	# Weiße Augen-Bereiche (Sonnenbrille-Tan-Linie um Augen)
	draw_circle(Vector2(-bs * 0.28, -bs * 1.05), bs * 0.22, Color(0.95, 0.82, 0.65))
	draw_circle(Vector2(bs * 0.28, -bs * 1.05), bs * 0.22, Color(0.95, 0.82, 0.65))
	# Kleine blaue Augen
	draw_circle(Vector2(-bs * 0.28, -bs * 1.05), bs * 0.12, Color(0.30, 0.48, 0.78))
	draw_circle(Vector2(bs * 0.28, -bs * 1.05), bs * 0.12, Color(0.30, 0.48, 0.78))
	draw_circle(Vector2(-bs * 0.28, -bs * 1.05), bs * 0.05, Color(0.05, 0.05, 0.08))
	draw_circle(Vector2(bs * 0.28, -bs * 1.05), bs * 0.05, Color(0.05, 0.05, 0.08))
	# Kleine mürrische Lippen
	draw_arc(Vector2(0, -bs * 0.74), bs * 0.20, 0.20, PI - 0.20, 8, Color(0.65, 0.32, 0.28), 4.5)
	draw_line(Vector2(-bs * 0.18, -bs * 0.74), Vector2(bs * 0.18, -bs * 0.74),
			  Color(0.55, 0.24, 0.20), 3.0)
	# TRUMP-COMBOVER – Goldblondes übergeschwungenes Haar
	# Seiten (kahl, wenig Haar)
	draw_arc(Vector2(0, -bs * 0.95), bs * 0.68, PI * 1.0, PI * 0.0, 16, hr, 6.0)
	# Combover-Strähnen (charakteristisch: von rechts nach links geschwungen)
	for st in range(6):
		var t_st = float(st) / 5.0
		var sx   = bs * (0.58 - t_st * 1.10)
		var sy   = -bs * 1.62 + t_st * bs * 0.10
		var ex   = bs * (-0.55 + t_st * 0.10)
		var ey   = -bs * 1.58 + t_st * bs * 0.05
		draw_line(Vector2(sx, sy), Vector2(ex, ey), hr, 5.0 - t_st * 1.5)
	# Haarbüschel oben (Volumen-Illusion)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-bs * 0.60, -bs * 1.55), Vector2(-bs * 0.20, -bs * 1.72),
		Vector2(bs * 0.45, -bs * 1.68), Vector2(bs * 0.65, -bs * 1.52),
		Vector2(bs * 0.55, -bs * 1.42), Vector2(-bs * 0.60, -bs * 1.42)]), hr)
	# Phase 2: MAGA-Cap erscheint
	if _phase == 2:
		var p = abs(sin(ap * 5))
		draw_arc(Vector2.ZERO, bs * 1.20, 0, TAU, 32, Color(0.85, 0.08, 0.08, p * 0.90), 5.0)
		# MAGA-Cap
		draw_rect(Rect2(-bs * 0.72, -bs * 1.72, bs * 1.44, bs * 0.72), Color(0.72, 0.05, 0.05))
		draw_rect(Rect2(-bs * 0.72, -bs * 1.06, bs * 1.05, bs * 0.22), Color(0.60, 0.04, 0.04))
		draw_rect(Rect2(-bs * 0.70, -bs * 1.70, bs * 1.40, bs * 0.12), Color(0.92, 0.78, 0.10))

# ─────────────────────────────────────────────────────────────
# DEFAULT (Fallback)
# ─────────────────────────────────────────────────────────────
func _draw_default(flash: bool, bs: float, ap: float) -> void:
	var bc = body_color if not flash else Color.WHITE
	for i in range(3):
		var r = bs + 5.0 + i * 10.0 + sin(ap + i * 1.5) * 4.0
		draw_arc(Vector2.ZERO, r, 0, TAU, 24,
			Color(body_color.r, body_color.g, body_color.b, 0.22 - i * 0.06), 2.5)
	draw_circle(Vector2.ZERO, bs, bc)
	draw_arc(Vector2.ZERO, bs, 0, TAU, 32, accent_color, 3.0)
	draw_circle(Vector2(-bs * 0.33, -bs * 0.25), bs * 0.14, Color(0, 0, 0))
	draw_circle(Vector2( bs * 0.33, -bs * 0.25), bs * 0.14, Color(0, 0, 0))
	if _phase == 2:
		var p = abs(sin(ap * 4.0))
		draw_arc(Vector2.ZERO, bs + 3, 0, TAU, 32, Color(1.0, 0.4, 0.0, p), 3.0)

# ─────────────────────────────────────────────────────────────
# Hilfsfunktionen
# ─────────────────────────────────────────────────────────────
func _draw_star(center: Vector2, radius: float, col: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(12):
		var a = i * TAU / 12.0 - PI * 0.5
		var r = radius if i % 2 == 0 else radius * 0.44
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col)

func _draw_sparkle(center: Vector2, size: float, col: Color) -> void:
	for i in range(4):
		var a = i * PI * 0.5
		draw_line(center + Vector2(cos(a), sin(a)) * size * 0.5,
				  center + Vector2(cos(a + PI), sin(a + PI)) * size * 0.5,
				  col, 2.5)
