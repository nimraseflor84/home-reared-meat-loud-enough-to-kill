extends EnemyBase

# Großbauer: Latzhose, Strohhut, Mistgabel
# Angriff 1: Mistgabel-Stich (Nahkampf, 2.2× Schaden + Knockback)
# Spezial:   Pfeifen → 5 zufällige Farmtiere erscheinen

const FARM_ANIMALS = [
	"kuh","huhn","schwein","katze","hund","ente",
	"kueken","schaf","ziege","pferd","esel","kaninchen"
]
const _FARM_SCENE   = preload("res://scenes/entities/enemies/enemy_farm_animal.tscn")
const WHISTLE_CD    = 12.0
const STAB_CD       = 1.8
const STAB_RANGE    = 80.0

var _whistle_timer: float  = 6.0
var _stab_timer: float     = 0.0
var _stab_anim: float      = -1.0   # 0 .. 0.5
var _whistle_anim: float   = -1.0   # 0 .. 1.2
var _phase2: bool          = false
var _note_x: Array         = []

func _ready() -> void:
	enemy_id            = "grossbauer"
	max_hp              = 450.0
	damage              = 22.0
	move_speed          = 48.0
	score_value         = 1200
	_death_anim_duration = 1.5
	add_to_group("bosses")
	super._ready()
	for i in range(4):
		_note_x.append(randf_range(-18.0, 18.0))

# ── Update ────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not is_alive or _dying:
		super._process(delta)
		return

	_whistle_timer -= delta
	if _whistle_timer <= 0.0:
		_whistle_timer = WHISTLE_CD
		_do_whistle()

	if _stab_anim >= 0.0:
		_stab_anim += delta
		if _stab_anim >= 0.5:
			_stab_anim = -1.0

	if _whistle_anim >= 0.0:
		_whistle_anim += delta
		if _whistle_anim >= 1.2:
			_whistle_anim = -1.0

	super._process(delta)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Phase 2 bei 50 % HP
	if not _phase2 and current_hp <= max_hp * 0.5:
		_phase2 = true
		move_speed = 80.0

	_stab_timer += delta
	if is_instance_valid(target) and _stab_timer >= STAB_CD:
		if global_position.distance_to(target.global_position) < STAB_RANGE:
			_stab_timer = 0.0
			_stab_attack()

	super._physics_process(delta)

# ── Aktionen ──────────────────────────────────────────────────────────────────
func _stab_attack() -> void:
	_stab_anim = 0.0
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage * 2.2)
		if target.has_method("apply_knockback"):
			target.apply_knockback(
				(target.global_position - global_position).normalized() * 460.0
			)
	AudioManager.play_hit_sfx()

func _do_whistle() -> void:
	_whistle_anim = 0.0
	AudioManager.play_whistle_sfx()
	for i in range(5):
		var animal = _FARM_SCENE.instantiate()
		animal.animal_type = FARM_ANIMALS[randi() % FARM_ANIMALS.size()]
		var angle = i * TAU / 5.0 + randf() * 0.8
		animal.global_position = global_position + \
			Vector2(cos(angle), sin(angle)) * randf_range(70.0, 130.0)
		get_tree().current_scene.add_child(animal)

func _on_dying_process(_delta: float) -> void:
	pass  # Eigene Todesanimation in _draw()

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if _dying:
		_draw_death()
		return
	if not is_alive:
		return
	var _wc   = sin(_anim_time * 3.5)
	var bob   = _wc * 1.5
	var leg_r = _wc * 10.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.7
	var arm_l = _wc * 0.7
	var flash = _hit_flash > 0
	_draw_body(bob, leg_l, leg_r, arm_l, arm_r, flash)
	_draw_pitchfork(bob, arm_r)
	if _whistle_anim >= 0.0:
		_draw_whistle(bob, arm_l)

func _draw_body(b: float, ll: float, lr: float, al: float, ar: float, flash: bool) -> void:
	var skin    = Color(0.80, 0.52, 0.36) if not flash else Color.WHITE
	var rdface  = Color(0.78, 0.40, 0.28) if not flash else Color.WHITE
	var overall = Color(0.18, 0.30, 0.58)
	var shirt   = Color(0.70, 0.12, 0.08)
	var straw   = Color(0.82, 0.72, 0.30)
	var sband   = Color(0.48, 0.35, 0.10)
	var musta   = Color(0.35, 0.20, 0.06)
	var boot_c  = Color(0.20, 0.12, 0.05)

	# Stiefel (alternierend)
	draw_rect(Rect2(-18, 28 + ll * 0.35 + b, 16, 8), boot_c)
	draw_rect(Rect2(2,   28 + lr * 0.35 + b, 16, 8), boot_c)
	# Beine
	draw_rect(Rect2(-15, 14 + ll * 0.3 + b, 12, 16), overall)
	draw_rect(Rect2(3,   14 + lr * 0.3 + b, 12, 16), overall)
	# Torso
	draw_rect(Rect2(-16, -12+b, 32, 28), overall)
	# Shirt an Seiten sichtbar (Arme schaukeln)
	draw_rect(Rect2(-24, -6 + al + b, 10, 18), shirt)
	draw_rect(Rect2(14,  -6 + ar + b, 10, 18), shirt)
	# Latzhosen-Träger
	draw_line(Vector2(-8, -12+b), Vector2(-4, -28 + b*0.4), Color(0.30, 0.46, 0.80), 3)
	draw_line(Vector2(8,  -12+b), Vector2(4,  -28 + b*0.4), Color(0.30, 0.46, 0.80), 3)
	# Hände
	draw_circle(Vector2(-24, 8 + al + b), 8, skin)
	draw_circle(Vector2(24,  8 + ar + b), 8, skin)
	# Kopf
	draw_circle(Vector2(0, -28 + b*0.4), 20, rdface)
	# Strohhut
	draw_rect(Rect2(-28, -46 + b*0.4, 56, 7), straw)
	draw_rect(Rect2(-12, -68 + b*0.4, 24, 24), straw)
	draw_rect(Rect2(-14, -46 + b*0.4, 28, 5), sband)
	draw_line(Vector2(-28, -46 + b*0.4), Vector2(28, -46 + b*0.4), straw.darkened(0.25), 2)
	# Großer Schnauzbart
	var mpts = PackedVector2Array([
		Vector2(-14,-22 + b*0.4), Vector2(-18,-16 + b*0.4), Vector2(-8,-14 + b*0.4), Vector2(0,-17 + b*0.4),
		Vector2(8,-14 + b*0.4),   Vector2(18,-16 + b*0.4),  Vector2(14,-22 + b*0.4),
	])
	draw_colored_polygon(mpts, musta)
	# Augen
	draw_circle(Vector2(-8, -32 + b*0.4), 3.5, Color(0.95,0.92,0.85))
	draw_circle(Vector2(8,  -32 + b*0.4), 3.5, Color(0.95,0.92,0.85))
	draw_circle(Vector2(-8, -32 + b*0.4), 1.8, Color(0.15,0.08,0.04))
	draw_circle(Vector2(8,  -32 + b*0.4), 1.8, Color(0.15,0.08,0.04))
	draw_line(Vector2(-14,-36 + b*0.4), Vector2(-4,-34 + b*0.4), musta, 3)
	draw_line(Vector2(4,  -34 + b*0.4), Vector2(14,-36 + b*0.4), musta, 3)
	# Rote Nase
	draw_circle(Vector2(0, -26 + b*0.4), 5, Color(0.80, 0.30, 0.26))
	# Phase-2: Gesicht rot, Dampf aus Ohren
	if _phase2:
		draw_circle(Vector2(0, -28 + b*0.4), 20, Color(0.70, 0.18, 0.12, 0.35))
		var st = fmod(_anim_time * 3.0, 1.0)
		draw_circle(Vector2(-22, -28 + b*0.4), 3+st*5, Color(0.9,0.9,0.9, 0.55-st*0.5))
		draw_circle(Vector2(22,  -28 + b*0.4), 3+st*5, Color(0.9,0.9,0.9, 0.55-st*0.5))

func _draw_pitchfork(b: float, ar: float) -> void:
	var fork_c = Color(0.55, 0.38, 0.10)
	var tine_c = Color(0.62, 0.62, 0.64)
	var off = 0.0
	if _stab_anim >= 0.0:
		off = sin(_stab_anim / 0.5 * PI) * 20.0  # Herausstechen und zurück
	var px = 30.0 + off
	var py = ar + b  # folgt dem rechten Arm
	# Stiel
	draw_line(Vector2(px, 10 + py), Vector2(px, 38 + py), fork_c, 5)
	# Querbalken
	draw_line(Vector2(px-8, -2 + py), Vector2(px+8, -2 + py), tine_c, 4)
	# Drei Zinken
	for tx in [px-6.0, px, px+6.0]:
		var len = -20.0 if tx == px else -16.0
		draw_line(Vector2(tx, -2 + py), Vector2(tx, -2 + len + py), tine_c, 3)
		draw_circle(Vector2(tx, -2 + len + py), 2.5, tine_c)

func _draw_whistle(b: float, al: float) -> void:
	var wt = _whistle_anim
	var skin = Color(0.80, 0.52, 0.36)
	# Linke Hand bewegt sich zum Mund (startet von Armposition)
	var move = min(wt / 0.3, 1.0)
	var hx = -24.0 + move * 14.0
	var hy = 8.0 + al * (1.0 - move) - move * 16.0
	draw_circle(Vector2(hx, hy + b), 9, skin)
	# Noten steigen auf
	if wt > 0.3:
		var nt = wt - 0.3
		for i in range(4):
			var nx = _note_x[i]
			var ny = -30.0 - nt * 45.0 - float(i) * 14.0
			var na = max(0.0, 1.0 - nt / 0.9)
			draw_circle(Vector2(nx, ny+b), 4, Color(1.0, 1.0, 0.2, na))
			draw_line(Vector2(nx+3, ny+b), Vector2(nx+3, ny-10+b), Color(1.0,1.0,0.2,na), 2)
			draw_line(Vector2(nx+3, ny-10+b), Vector2(nx+8, ny-8+b), Color(1.0,1.0,0.2,na), 2)

# ── Todesanimation ────────────────────────────────────────────────────────────
func _draw_death() -> void:
	var t       = _death_anim_time
	var overall = Color(0.18, 0.30, 0.58)
	var skin    = Color(0.75, 0.48, 0.32)
	var straw   = Color(0.82, 0.72, 0.30)
	var blood   = Color(0.70, 0.04, 0.04)
	var fork_c  = Color(0.55, 0.38, 0.10)
	var tine_c  = Color(0.62, 0.62, 0.64)

	var fall = min(t * 55.0, 42.0)
	var lean = min(t * 2.0, 1.0)

	# Blutlache
	if t > 0.3:
		draw_circle(Vector2(0, 34), min((t-0.3)*36.0, 32.0), Color(blood.r,blood.g,blood.b,0.70))

	# Beine
	draw_rect(Rect2(-18 + fall*0.25, 14+fall*0.5, 12, 16), overall)
	draw_rect(Rect2(2   + fall*0.25, 14+fall*0.5, 12, 16), overall)
	# Torso kippt zurück
	draw_rect(Rect2(-16 + fall*0.3*lean, -12+fall*lean, 32, 28), overall)
	# Kopf rollt weg
	draw_circle(Vector2(fall*0.6, -28+fall*0.9), 20, skin)
	# Hut fliegt ab
	var hx = t * 32.0;  var hy = -46.0 - t * 48.0
	draw_rect(Rect2(-28+hx, hy, 56, 7), straw)
	draw_rect(Rect2(-12+hx, hy-22, 24, 24), straw)
	# Mistgabel fällt
	var fp = fall * 0.9
	draw_line(Vector2(30+fp, 10+fp), Vector2(30+fp, 38+fp), fork_c, 5)
	draw_line(Vector2(22+fp, -2+fp), Vector2(38+fp, -2+fp), tine_c, 4)
	for tx in [-6.0, 0.0, 6.0]:
		var len = -18.0 if tx == 0.0 else -14.0
		draw_line(Vector2(30+fp+tx, -2+fp), Vector2(30+fp+tx, -2+len+fp), tine_c, 3)

	# Fade in den letzten 0.3s
	var alpha = 1.0 - max(0.0, (t - 1.2) / 0.3)
	modulate.a = alpha
