extends EnemyBase

# CEO der Stille – Herr Böse (Dirigent) – FINALBOSS Welle 15
# Während des Kampfes: Chaos-Wellen mit ALLEN Bossen und Gegnern der vorherigen Maps
# Wenn er stirbt → Spiel gewonnen

var _spawn_timer: float  = 0.0
var _chaos_timer: float  = 18.0   # erste Chaos-Welle nach 18 s
const CHAOS_INTERVAL     = 22.0   # danach alle 22 s

var _minion_count: int   = 0
const MAX_MINIONS        = 6
const MINION_INTERVAL    = 4.0

var _phase: int          = 1
var _aura_pulse: float   = 0.0

# Alle Bonus-Spawns – werden beim Tod des Dirigenten entfernt
var _chaos_spawns: Array = []

# ── Szenen-Pfade ──────────────────────────────────────────────────────────────
const _SCENES = {
	# Reguläre Gegner
	"stille":        "res://scenes/entities/enemies/enemy_stille.tscn",
	"verstimmte":    "res://scenes/entities/enemies/enemy_verstimmte.tscn",
	"headbanger":    "res://scenes/entities/enemies/enemy_headbanger.tscn",
	"waerter":       "res://scenes/entities/enemies/enemy_waerter.tscn",
	"wildschwein":   "res://scenes/entities/enemies/enemy_wildschwein.tscn",
	"huhn":          "res://scenes/entities/enemies/enemy_huhn.tscn",
	"cowboy":        "res://scenes/entities/enemies/enemy_cowboy.tscn",
	"security":      "res://scenes/entities/enemies/enemy_security.tscn",
	# Alle Bosse der vorherigen Maps
	"grossbauer":    "res://scenes/entities/enemies/enemy_grossbauer.tscn",
	"gefchef":       "res://scenes/entities/enemies/enemy_gefchef.tscn",
	"mega_schwein":  "res://scenes/entities/enemies/enemy_mega_schwein.tscn",
	"trump":         "res://scenes/entities/enemies/enemy_trump.tscn",
	"trucker":       "res://scenes/entities/enemies/enemy_trucker.tscn",
	"tvstar":        "res://scenes/entities/enemies/enemy_tvstar.tscn",
	"buergermeister":"res://scenes/entities/enemies/enemy_buergermeister.tscn",
}

const _REGULAR_ENEMIES = [
	"stille","verstimmte","headbanger","waerter",
	"wildschwein","huhn","cowboy","security"
]
const _ALL_BOSSES = [
	"grossbauer","gefchef","mega_schwein","trump",
	"trucker","tvstar","buergermeister"
]

func _ready() -> void:
	enemy_id             = "dirigent"
	max_hp               = 2000.0
	damage               = 40.0
	move_speed           = 55.0
	score_value          = 5000
	_death_anim_duration = 2.0
	add_to_group("enemies")
	add_to_group("bosses")
	super._ready()

# ── Update ────────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	super._physics_process(delta)
	_aura_pulse += delta * 3.0

	# Phase-2-Trigger
	if current_hp <= max_hp * 0.5 and _phase == 1:
		_phase     = 2
		move_speed = 88.0

	# Reguläre Stille-Minions (wie bisher)
	_spawn_timer += delta
	if _spawn_timer >= MINION_INTERVAL:
		_spawn_timer = 0.0
		_spawn_minion()

	# Chaos-Wellen: alle Bosse und Gegner aus allen Maps
	_chaos_timer -= delta
	if _chaos_timer <= 0.0:
		_chaos_timer = CHAOS_INTERVAL * (0.75 if _phase == 2 else 1.0)
		_spawn_chaos_wave()

# ── Spawn: reguläre Stille-Minions ────────────────────────────────────────────
func _spawn_minion() -> void:
	if _minion_count >= MAX_MINIONS:
		return
	var e = _make_enemy("stille")
	if not e: return
	e.global_position = global_position + Vector2(
		cos(randf() * TAU), sin(randf() * TAU)) * 65.0
	_add_bonus(e)
	_minion_count += 1

# ── Spawn: Chaos-Welle ────────────────────────────────────────────────────────
func _spawn_chaos_wave() -> void:
	var parent = get_parent()
	if not parent: return

	# 1–2 zufällige frühere Bosse
	var boss_list = _ALL_BOSSES.duplicate()
	boss_list.shuffle()
	var boss_count = 2 if _phase == 2 else 1
	for i in range(min(boss_count, boss_list.size())):
		var e = _make_enemy(boss_list[i])
		if not e: continue
		e.global_position = _spawn_edge_pos()
		_add_bonus(e)

	# 4–6 zufällige reguläre Gegner
	var enemy_count = 6 if _phase == 2 else 4
	for i in range(enemy_count):
		var t = _REGULAR_ENEMIES[randi() % _REGULAR_ENEMIES.size()]
		var e = _make_enemy(t)
		if not e: continue
		e.global_position = _spawn_edge_pos()
		_add_bonus(e)

	AudioManager.play_boss_siren_sfx()

# ── Hilfsfunktionen ───────────────────────────────────────────────────────────
func _make_enemy(type: String) -> Node:
	var path = _SCENES.get(type, "")
	if path == "": return null
	var scene = load(path)
	if not scene: return null
	return scene.instantiate()

func _add_bonus(e: Node) -> void:
	var parent = get_parent()
	if not parent: return
	# WICHTIG: KEIN connect("died", wave_manager) → zählt nicht für Wellenende
	parent.add_child(e)
	if is_instance_valid(target) and e.has_method("set_target"):
		e.set_target(target)
	_chaos_spawns.append(e)

func _spawn_edge_pos() -> Vector2:
	var vp  = get_viewport().get_visible_rect()
	var mgn = 60.0
	match randi() % 4:
		0: return Vector2(randf_range(0, vp.size.x), -mgn)
		1: return Vector2(randf_range(0, vp.size.x), vp.size.y + mgn)
		2: return Vector2(-mgn, randf_range(0, vp.size.y))
		_: return Vector2(vp.size.x + mgn, randf_range(0, vp.size.y))

# ── Tod – alle Chaos-Spawns entfernen → Wellenabschluss → Spiel gewonnen ─────
func _die(attacker = null) -> void:
	is_alive   = false
	_bullets.clear()
	remove_from_group("enemies")

	# Alle Bonus-Spawns sofort entfernen damit wave_complete sauber feuert
	for e in _chaos_spawns:
		if is_instance_valid(e):
			e.queue_free()
	_chaos_spawns.clear()

	if is_instance_valid(attacker) and attacker.has_method("on_kill"):
		attacker.on_kill(self)
	AudioManager.play_boss_death_sfx()
	emit_signal("died", self)
	_dying = true

func _on_dying_process(delta: float) -> void:
	var t = _death_anim_time / _death_anim_duration
	modulate.a  = 1.0 - t
	rotation   += delta * TAU * (0.2 + t * 0.6)
	var s       = max(0.01, 1.0 - t * 0.9)
	scale       = Vector2(s, s)

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if _dying:
		_draw_dirigent_death()
		return

	var flash      = _hit_flash > 0
	var ap         = _aura_pulse
	var cloak_col  = Color(0.05, 0.02, 0.08) if not flash else Color.WHITE
	if _phase == 2:
		cloak_col  = Color(0.35, 0.05, 0.0) if not flash else Color.WHITE
	var sk_col     = Color(0.80, 0.80, 0.76) if not flash else Color.WHITE
	var hat_col    = Color(0.04, 0.02, 0.06) if not flash else Color.WHITE

	# Lauf-Animation (langsam, bedrohlich)
	var _wc  = sin(_anim_time * 3.5)
	var bob  = _wc * 1.8

	# Anti-Musik-Aura (pulsierend, tiefes Rot) – statisch, keine bob
	for i in range(5):
		var r = 38 + i * 15 + sin(ap + i * 1.4) * 7
		draw_arc(Vector2.ZERO, r, 0, TAU, 24,
			Color(0.45 - i * 0.06, 0.0, 0.0, 0.30 - i * 0.05), 4.0 - i * 0.5)

	# Phase 2: zweite Chaos-Aura (größer, schneller pulsierend)
	if _phase == 2:
		for i in range(4):
			var r = 70 + i * 22 + sin(ap * 2.0 + i * 1.8) * 10
			draw_arc(Vector2.ZERO, r, 0, TAU, 20,
				Color(0.65, 0.08 + i * 0.04, 0.0, 0.20 - i * 0.04), 3.0)

	# Schwebende Anti-Noten (durchgestrichen) – eigene Orbit-Animation
	for n in range(6):
		var na   = n * TAU / 6.0 + ap * 0.7
		var nr   = 48 + sin(ap * 1.5 + n) * 8
		var npos = Vector2(cos(na), sin(na)) * nr
		draw_circle(npos, 5, Color(0.0, 0.0, 0.0, 0.80))
		draw_line(npos + Vector2(5, 0), npos + Vector2(5, -16),
			Color(0.0, 0.0, 0.0, 0.80), 2.0)
		draw_line(npos + Vector2(-8, -8), npos + Vector2(8, 8),
			Color(0.75, 0.0, 0.0, 0.80), 1.5)

	# Umhang (bobbt mit dem Körper)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -14 + bob), Vector2(18, -14 + bob),
		Vector2(54, 44 + bob), Vector2(-54, 44 + bob)]), cloak_col)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -10 + bob), Vector2(12, -10 + bob),
		Vector2(44, 40 + bob), Vector2(-44, 40 + bob)]),
		Color(cloak_col.r * 2.5, cloak_col.g * 2.0, cloak_col.b * 2.5, 0.35))
	for fold in range(5):
		var fx = -42.0 + fold * 21.0
		draw_line(Vector2(fx, 42 + bob), Vector2(fx * 0.22, -10 + bob),
			Color(0.0, 0.0, 0.0, 0.25), 2.0)

	# Weißer Kragen
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -18 + bob), Vector2(18, -18 + bob),
		Vector2(13, -8 + bob), Vector2(-13, -8 + bob)]),
		Color(0.82, 0.80, 0.76) if not flash else Color.WHITE)

	# Skelett-Hände (mit Umhang-bob)
	draw_circle(Vector2(-52, 44 + bob), 8, sk_col)
	draw_circle(Vector2(52,  44 + bob), 8, sk_col)
	for fi in range(4):
		var fa_l = PI * 0.35 + fi * PI * 0.12
		draw_line(Vector2(-52, 44 + bob),
			Vector2(-52 + cos(fa_l + PI) * 14, 44 + bob + sin(fa_l + PI) * 14), sk_col, 2.5)
		var fa_r = PI * 0.65 - fi * PI * 0.12
		draw_line(Vector2(52, 44 + bob),
			Vector2(52 + cos(fa_r) * 14, 44 + bob + sin(fa_r) * 14), sk_col, 2.5)

	# Taktstock (folgt der rechten Hand mit bob; eigene Glow-Animation bleibt)
	var baton_glow = 0.85 + sin(ap * 4) * 0.15
	draw_line(Vector2(50, 42 + bob), Vector2(86, -16 + bob), Color(0.95, 0.92, 0.80), 4.0)
	draw_circle(Vector2(87, -18 + bob), 4, Color(1.0, 0.98, 0.85, baton_glow))
	draw_circle(Vector2(87, -18 + bob), 7, Color(0.72, 0.12, 0.12, baton_glow * 0.5))

	# Kopf (bobbt weniger)
	draw_circle(Vector2(0, -38 + bob * 0.4), 22, sk_col)

	# Augen
	var tilt = 0.25; var ew = 7.0; var eh = 5.0
	var lepts = PackedVector2Array(); var repts = PackedVector2Array()
	for i in range(10):
		var a = i * TAU / 10.0
		var ox = cos(a) * ew; var oy = sin(a) * eh
		lepts.append(Vector2(-8 + ox*cos(tilt) - oy*sin(tilt), -42 + bob * 0.4 + ox*sin(tilt) + oy*cos(tilt)))
		repts.append(Vector2(8 + ox*cos(-tilt) - oy*sin(-tilt), -42 + bob * 0.4 + ox*sin(-tilt) + oy*cos(-tilt)))
	draw_colored_polygon(lepts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_colored_polygon(repts, Color(0.95, 0.95, 0.95) if not flash else Color.WHITE)
	draw_circle(Vector2(-8, -42 + bob * 0.4), 3.0, Color(0.80, 0.0, 0.0))
	draw_circle(Vector2(8,  -42 + bob * 0.4), 3.0, Color(0.80, 0.0, 0.0))

	# Nase
	draw_circle(Vector2(-3, -33 + bob * 0.4), 2, Color(0.35, 0.25, 0.22))
	draw_circle(Vector2(3,  -33 + bob * 0.4), 2, Color(0.35, 0.25, 0.22))

	# Totenkopf-Grinsen
	draw_arc(Vector2(0, -27 + bob * 0.4), 9, 0.2, PI - 0.2, 8, Color(0.08, 0.04, 0.08), 3.0)
	for ti in range(5):
		var tx = -7.0 + ti * 3.5
		draw_line(Vector2(tx, -27 + bob * 0.4), Vector2(tx, -21 + bob * 0.4), Color(0.95, 0.92, 0.85), 2.5)

	# Hut
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22, -60 + bob * 0.4), Vector2(-4, -92 + bob * 0.4),
		Vector2(4, -92 + bob * 0.4),   Vector2(22, -60 + bob * 0.4)]), hat_col)
	draw_rect(Rect2(-24, -63 + bob * 0.4, 48, 7), hat_col)
	draw_line(Vector2(-24, -64 + bob * 0.4), Vector2(24, -64 + bob * 0.4), Color(0.72, 0.04, 0.04), 4.0)

	# Phase 2: Flammen + leuchtende Augen
	if _phase == 2:
		for fi in range(8):
			var fa   = fi * TAU / 8.0 + ap * 2.5
			var fpr  = 52 + sin(ap * 5 + fi) * 10
			var fpos = Vector2(cos(fa), sin(fa)) * fpr
			draw_circle(fpos, 8 + sin(ap * 4 + fi) * 3,
				Color(1.0, 0.32 + sin(ap * 4 + fi) * 0.15, 0.0,
					  0.65 + sin(ap * 3 + fi) * 0.20))
		draw_circle(Vector2(-8, -42 + bob * 0.4), 4, Color(1.0, 0.35, 0.0))
		draw_circle(Vector2(8,  -42 + bob * 0.4), 4, Color(1.0, 0.35, 0.0))

	# HP-Balken
	var hp_pct = current_hp / max_hp
	draw_rect(Rect2(-48, 58, 96, 10),          Color(0.12, 0.0, 0.0))
	draw_rect(Rect2(-48, 58, 96 * hp_pct, 10), Color(0.85, 0.08, 0.08))
	draw_rect(Rect2(-48, 58, 96, 10),          Color(0.6, 0.0, 0.0), false, 1.5)

func _draw_dirigent_death() -> void:
	var t      = clamp(_death_anim_time / _death_anim_duration, 0.0, 1.0)
	var alpha  = 1.0 - t
	var bt     = t * t   # beschleunigt

	# Noten fliegen heraus
	for n in range(10):
		var angle = float(n) * TAU / 10.0 + t * TAU * 0.5
		var dist  = (50 + float(n) * 12) * (0.5 + t * 5.5)
		var npos  = Vector2(cos(angle), sin(angle)) * dist
		draw_circle(npos, 11.0 * alpha, Color(0.0, 0.0, 0.0, alpha))
		draw_circle(npos, 7.0 * alpha,  Color(0.72, 0.0, 0.0, alpha * 0.75))
		draw_line(npos + Vector2(11, 0), npos + Vector2(11, -34.0 * alpha),
			Color(0.0, 0.0, 0.0, alpha), 3.5)
		draw_line(npos + Vector2(-16, -10), npos + Vector2(16, 10),
			Color(0.78, 0.0, 0.0, alpha), 3.0)

	# Taktstock schießt weg
	var b1 = Vector2(50 + bt * 120, 44 - bt * 130)
	var b2 = Vector2(88 + bt * 220, -18 - bt * 200)
	draw_line(b1, b2, Color(0.95, 0.92, 0.80, alpha), 7.0)
	draw_circle(b2, 10.0 * alpha, Color(1.0, 0.95, 0.80, alpha))
	draw_circle(b2, 18.0 * alpha, Color(0.72, 0.12, 0.12, alpha * 0.5))

	# Roter Nebel
	for i in range(5):
		var r = (45 + float(i) * 32) * (0.5 + t * 3.5)
		draw_arc(Vector2.ZERO, r, 0, TAU, 14, Color(0.62, 0.0, 0.0, (1.0 - t) * 0.35), 9.0)

	# Umhang-Splitter
	for i in range(8):
		var angle = float(i) * TAU / 8.0 + t * 0.4
		var dist  = 55.0 * (0.3 + t * 5.0)
		var pos   = Vector2(cos(angle), sin(angle)) * dist
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(-12, -20) * alpha,
			pos + Vector2(12,  -20) * alpha,
			pos + Vector2(16,   20) * alpha,
			pos + Vector2(-16,  20) * alpha,
		]), Color(0.04, 0.02, 0.08, alpha))

	# Blut
	var b_alpha = 1.0 - clamp(t * 1.4, 0.0, 1.0)
	for i in range(16):
		var angle = float(i) * TAU / 16.0 + float(i) * 0.31
		var dist  = 15.0 + bt * 320.0
		var sz    = 14.0 - bt * 10.0
		if sz > 0.1:
			draw_circle(Vector2(cos(angle), sin(angle)) * dist, sz,
				Color(0.70, 0.0, 0.02, b_alpha * 0.90))
	for i in range(8):
		var angle = float(i) * TAU / 8.0 + 0.22
		var dist  = 25.0 + bt * 200.0
		var pos   = Vector2(cos(angle), sin(angle)) * dist
		draw_circle(pos,        10.0 * b_alpha, Color(0.48, 0.0, 0.01, b_alpha * 0.85))
		draw_circle(pos * 0.55,  7.0 * b_alpha, Color(0.55, 0.0, 0.02, b_alpha * 0.70))
	draw_circle(Vector2(0, 28), 18.0 + t * 90.0, Color(0.52, 0.0, 0.01, (1.0 - t) * 0.55))
