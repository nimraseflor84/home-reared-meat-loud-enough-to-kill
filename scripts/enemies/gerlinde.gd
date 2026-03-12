extends EnemyBase

# Gerlinde Schrei-Stopp
# Angriff:  Rollator-Ramme
# Spezial:  "HILFE RUFEN!" – 3 zufällige Verstärkung spawnen

const ROLLER_CD  = 2.4
const ROLLER_RNG = 78.0
const RUFEN_CD   = 14.0

const _HELPER_PATHS = [
	"res://scenes/entities/enemies/enemy_headbanger.tscn",
	"res://scenes/entities/enemies/enemy_waerter.tscn",
	"res://scenes/entities/enemies/enemy_security.tscn",
]

var _phase2: bool       = false
var _base_speed: float  = 32.0

var _roller_timer: float = 1.6
var _rufen_timer: float  = 10.0
var _roller_anim: float  = 0.0
var _rufen_anim: float   = 0.0   # 1→0: Sprechblase sichtbar

func _ready() -> void:
	enemy_id             = "gerlinde"
	max_hp               = 500.0
	damage               = 24.0
	move_speed           = 32.0
	score_value          = 1200
	_death_anim_duration = 1.6
	_base_speed          = move_speed
	add_to_group("bosses")
	super._ready()

# ── Update ────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not is_alive or _dying:
		super._process(delta)
		return

	if not _phase2 and current_hp <= max_hp * 0.5:
		_phase2    = true
		move_speed = _base_speed * 1.75

	if _roller_anim > 0.0: _roller_anim = max(0.0, _roller_anim - delta * 3.0)
	if _rufen_anim  > 0.0: _rufen_anim  = max(0.0, _rufen_anim  - delta * 1.2)

	super._process(delta)

func _physics_process(delta: float) -> void:
	if not is_alive: return

	_roller_timer -= delta
	_rufen_timer  -= delta

	if is_instance_valid(target):
		if _roller_timer <= 0.0 and global_position.distance_to(target.global_position) < ROLLER_RNG:
			_roller_timer = ROLLER_CD
			_do_roller_hit()

	if _rufen_timer <= 0.0:
		_rufen_timer = RUFEN_CD
		_start_rufen()

	super._physics_process(delta)

# ── Aktionen ──────────────────────────────────────────────────────────────────
func _do_roller_hit() -> void:
	if not is_instance_valid(target): return
	if global_position.distance_to(target.global_position) > ROLLER_RNG: return
	target.take_damage(damage * 1.6)
	if target.has_method("apply_knockback"):
		target.apply_knockback(
			(target.global_position - global_position).normalized() * 300.0)
	_roller_anim = 1.0
	AudioManager.play_projectile_sfx(0)

func _start_rufen() -> void:
	_rufen_anim = 1.0
	AudioManager.play_boss_siren_sfx()
	var parent = get_parent()
	if not parent: return
	for i in range(3):
		var path  = _HELPER_PATHS[randi() % _HELPER_PATHS.size()]
		var scene = load(path)
		if not scene: continue
		var e     = scene.instantiate()
		var angle = float(i) / 3.0 * TAU + randf() * 0.4
		parent.add_child(e)
		e.global_position = global_position + Vector2(cos(angle), sin(angle)) * randf_range(80.0, 130.0)
		if e.has_method("set_target"):
			e.set_target(target)

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if _dying:
		_draw_death()
		return
	if not is_alive: return

	var _wc   = sin(_anim_time * 3.5)
	var bob   = _wc * 1.2
	var leg_r = _wc * 7.0
	var leg_l = -leg_r
	var flash = _hit_flash > 0
	_draw_body(bob, flash, leg_l, leg_r)
	if _rufen_anim > 0.0:
		_draw_rufen_bubble(bob)

func _draw_body(bob: float, flash: bool, leg_l: float = 0.0, leg_r: float = 0.0) -> void:
	var skin   = Color(0.90, 0.78, 0.68) if not flash else Color.WHITE
	var dress  = Color(0.88, 0.56, 0.64) if not flash else Color.WHITE
	var white  = Color(0.94, 0.92, 0.90)
	var metal  = Color(0.62, 0.64, 0.68)
	var gold_e = Color(0.85, 0.70, 0.08)

	# Rollator – stößt nach vorne (nach oben im Sprite) bei Ramme
	var ram_y = -_roller_anim * 11.0
	var ry    = -4.0 + bob + ram_y
	draw_line(Vector2(-14, ry),    Vector2(14, ry),    metal, 4)  # Griffstange
	draw_line(Vector2(-14, ry),    Vector2(-14, ry+20), metal, 3)  # linkes Bein
	draw_line(Vector2(14,  ry),    Vector2(14,  ry+20), metal, 3)  # rechtes Bein
	draw_line(Vector2(-14, ry+18), Vector2(14,  ry+18), metal, 3)  # untere Stange
	draw_circle(Vector2(-14, ry+22), 4, Color(0.22,0.22,0.25))     # Rad links
	draw_circle(Vector2(14,  ry+22), 4, Color(0.22,0.22,0.25))     # Rad rechts
	draw_circle(Vector2(-14, ry+2),  4, skin)   # Hand links
	draw_circle(Vector2(14,  ry+2),  4, skin)   # Hand rechts
	# Handtasche am Rollator
	draw_rect(Rect2(-24, ry+4, 10, 9), Color(0.55,0.28,0.50))
	draw_line(Vector2(-14, ry+2), Vector2(-22, ry+6), Color(0.45,0.22,0.40), 2)
	# Ramm-Flash
	if _roller_anim > 0.65:
		draw_circle(Vector2(0, ry-2), 12, Color(0.9, 0.5, 0.8, (_roller_anim-0.65)*2.8))

	# Schuhe (animiert mit Beinen)
	draw_rect(Rect2(-11, 28 + leg_l * 0.4 + bob, 9, 5), Color(0.62,0.38,0.62))
	draw_rect(Rect2(2,   28 + leg_r * 0.4 + bob, 9, 5), Color(0.62,0.38,0.62))
	# Midi-Kleid mit Blumenmuster
	draw_rect(Rect2(-14, 6+bob, 28, 24), dress)
	for fx in [-6.0, 0.0, 6.0]:
		for fy in [10.0, 18.0]:
			draw_circle(Vector2(fx, fy+bob), 2.5, Color(1.0,0.90,0.25))
			draw_circle(Vector2(fx, fy+bob), 1.2, Color(0.95,0.30,0.30))
	draw_rect(Rect2(-11, -8+bob, 22, 16), dress)  # Oberteil
	draw_circle(Vector2(0, -8+bob), 5, white)      # Kragen
	# Arme (halten Rollator – nur bob, kein Arm-Swing)
	draw_rect(Rect2(-19, -2+bob, 6, 16), dress)
	draw_rect(Rect2(13,  -2+bob, 6, 16), dress)

	# Kopf
	draw_circle(Vector2(0, -22 + bob * 0.4), 13, skin)
	# Weißer Dutt mit Haarnetz
	draw_circle(Vector2(0, -30 + bob * 0.4), 10, white)
	draw_circle(Vector2(0, -32 + bob * 0.4), 7, white.darkened(0.12))
	for ni in range(5):
		var na = float(ni) / 5.0 * TAU
		draw_circle(Vector2(cos(na)*6, -31 + bob * 0.4 + sin(na)*3.5), 1.5, white.darkened(0.3))
	# Goldene Ohrringe
	draw_circle(Vector2(-14, -22 + bob * 0.4), 3.5, gold_e)
	draw_circle(Vector2(14,  -22 + bob * 0.4), 3.5, gold_e)
	# Augen
	draw_circle(Vector2(-4, -22 + bob * 0.4), 3, white)
	draw_circle(Vector2(4,  -22 + bob * 0.4), 3, white)
	draw_circle(Vector2(-4, -22 + bob * 0.4), 1.8, Color(0.30,0.18,0.08))
	draw_circle(Vector2(4,  -22 + bob * 0.4), 1.8, Color(0.30,0.18,0.08))
	# Zusammengepresste Lippen
	draw_line(Vector2(-5, -14 + bob * 0.4), Vector2(5, -14 + bob * 0.4), Color(0.72,0.38,0.38), 3)
	# Phase2: Zornesfalten
	if _phase2:
		draw_line(Vector2(-8,-26 + bob * 0.4), Vector2(-2,-24 + bob * 0.4), Color(0.55,0.28,0.18), 2.5)
		draw_line(Vector2(2, -24 + bob * 0.4), Vector2(8, -26 + bob * 0.4), Color(0.55,0.28,0.18), 2.5)

func _draw_rufen_bubble(bob: float) -> void:
	var alpha = _rufen_anim
	var bx = 14.0; var by = -52.0 + bob
	var w  = 44.0; var h  = 22.0
	# Sprechblase
	draw_rect(Rect2(bx-w*0.5, by-h*0.5, w, h), Color(1.0,1.0,1.0, alpha * 0.92))
	draw_rect(Rect2(bx-w*0.5, by-h*0.5, w, h), Color(0.72,0.38,0.38, alpha), false, 2.0)
	# Schwanz der Blase
	draw_colored_polygon(PackedVector2Array([
		Vector2(bx-6, by+h*0.5), Vector2(bx+4, by+h*0.5), Vector2(bx-4, by+h*0.5+10)
	]), Color(1.0,1.0,1.0, alpha))
	draw_line(Vector2(bx-6, by+h*0.5), Vector2(bx-4, by+h*0.5+10), Color(0.72,0.38,0.38,alpha), 2)
	draw_line(Vector2(bx+4, by+h*0.5), Vector2(bx-4, by+h*0.5+10), Color(0.72,0.38,0.38,alpha), 2)
	# "HILFE!" – Pixel-Text
	var r = Color(0.72, 0.08, 0.08, alpha)
	# H
	draw_line(Vector2(bx-19, by-7), Vector2(bx-19, by+7), r, 2)
	draw_line(Vector2(bx-19, by),   Vector2(bx-15, by),   r, 2)
	draw_line(Vector2(bx-15, by-7), Vector2(bx-15, by+7), r, 2)
	# I
	draw_line(Vector2(bx-12, by-7), Vector2(bx-12, by+7), r, 2)
	# L
	draw_line(Vector2(bx-9,  by-7), Vector2(bx-9,  by+7), r, 2)
	draw_line(Vector2(bx-9,  by+7), Vector2(bx-5,  by+7), r, 2)
	# F
	draw_line(Vector2(bx-2,  by-7), Vector2(bx-2,  by+7), r, 2)
	draw_line(Vector2(bx-2,  by-7), Vector2(bx+2,  by-7), r, 2)
	draw_line(Vector2(bx-2,  by),   Vector2(bx+1,  by),   r, 2)
	# E
	draw_line(Vector2(bx+5,  by-7), Vector2(bx+5,  by+7), r, 2)
	draw_line(Vector2(bx+5,  by-7), Vector2(bx+9,  by-7), r, 2)
	draw_line(Vector2(bx+5,  by),   Vector2(bx+8,  by),   r, 2)
	draw_line(Vector2(bx+5,  by+7), Vector2(bx+9,  by+7), r, 2)
	# !
	draw_line(Vector2(bx+13, by-7), Vector2(bx+13, by+2), r, 2)
	draw_circle(Vector2(bx+13, by+6), 1.5, r)

# ── Todesanimation ────────────────────────────────────────────────────────────
func _draw_death() -> void:
	var t     = _death_anim_time
	var dress = Color(0.85, 0.52, 0.60).darkened(t * 0.35)
	var skin  = Color(0.88, 0.74, 0.60)
	var metal = Color(0.55, 0.57, 0.62)
	var white = Color(0.94, 0.92, 0.90)
	var fall  = min(t * 50.0, 40.0)

	if t > 0.3:
		draw_circle(Vector2(0, 34), min((t-0.3)*38.0, 28.0), Color(0.78, 0.62, 0.08, 0.55))

	# Gerlinde kippt vorwärts in den Rollator
	draw_rect(Rect2(-14+fall*0.20, 6+fall*0.46, 28, 22), dress)
	draw_circle(Vector2(fall*0.28, -22+fall*0.90), 13, skin)
	# Dutt fliegt weg
	draw_circle(Vector2(fall*0.45, -32.0 - t*22.0), 9, white)
	# Rollator kippt mit ihr
	var rx = t * 14.0
	draw_line(Vector2(-14+rx, 14-t*8),  Vector2(14+rx, 14-t*8),  metal, 3)
	draw_line(Vector2(-14+rx, 14-t*8),  Vector2(-16+rx, 32+t*6), metal, 2)
	draw_line(Vector2(14+rx,  14-t*8),  Vector2(16+rx,  32+t*6), metal, 2)
	draw_line(Vector2(-14+rx, 32+t*6),  Vector2(14+rx,  32+t*6), metal, 2)

	modulate.a = 1.0 - max(0.0, (t - 1.2) / 0.4)
