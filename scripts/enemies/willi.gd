extends EnemyBase

# Willi Schrei-Stopp
# Angriff:  Gehstock-Hieb
# Spezial:  Signalpistole – 3 zufällige Leuchtmunition mit Effekten

const STOCK_CD   = 1.8
const STOCK_RNG  = 70.0
const SIGNAL_CD  = 13.0
const SIGNAL_SPD = 280.0
const SIGNAL_RNG = 520.0

const SIGNAL_TYPES = ["rot","blau","gelb","gruen","schwarz","weiss","rosa"]
const SIGNAL_COL   = {
	"rot":    Color(1.00, 0.15, 0.05),
	"blau":   Color(0.18, 0.42, 1.00),
	"gelb":   Color(1.00, 0.95, 0.10),
	"gruen":  Color(0.12, 0.85, 0.14),
	"schwarz":Color(0.10, 0.08, 0.08),
	"weiss":  Color(0.97, 0.97, 0.96),
	"rosa":   Color(1.00, 0.48, 0.78),
}

var _phase2: bool        = false
var _base_speed: float   = 38.0

var _stock_timer: float  = 1.0
var _signal_timer: float = 9.0
var _stock_anim: float   = 0.0
var _pistol_out: float   = 0.0

var _signal_shots: Array = []
var _effects: Array      = []
var _speed_boost: float  = 0.0

func _ready() -> void:
	enemy_id             = "willi"
	max_hp               = 500.0
	damage               = 28.0
	move_speed           = 38.0
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

	if _stock_anim > 0.0: _stock_anim = max(0.0, _stock_anim - delta * 3.5)
	if _pistol_out > 0.0: _pistol_out = max(0.0, _pistol_out - delta * 1.6)

	if _speed_boost > 0.0:
		_speed_boost -= delta
		if _speed_boost <= 0.0:
			move_speed = _base_speed * (1.75 if _phase2 else 1.0)

	# Projektile bewegen
	for i in range(_signal_shots.size() - 1, -1, -1):
		var s = _signal_shots[i]
		s["pos"] += s["vel"] * delta
		var too_far = s["pos"].distance_to(global_position) > SIGNAL_RNG
		var hit     = false
		if is_instance_valid(target):
			if s["pos"].distance_to(target.global_position) < 22.0:
				_apply_signal_effect(s["type"], s["dmg"])
				hit = true
		if hit or too_far:
			_signal_shots.remove_at(i)

	# Aktive Effekte
	for i in range(_effects.size() - 1, -1, -1):
		var eff = _effects[i]
		eff["timer"] -= delta
		if eff["timer"] <= 0.0:
			if eff["type"] == "blau" and is_instance_valid(target) and "move_speed" in target:
				target.move_speed = eff.get("orig_speed", 100.0)
			_effects.remove_at(i)
			continue
		match eff["type"]:
			"rot":
				eff["itimer"] += delta
				if eff["itimer"] >= 0.5:
					eff["itimer"] = 0.0
					if is_instance_valid(target): target.take_damage(damage * 0.35)
			"gruen":
				eff["itimer"] += delta
				if eff["itimer"] >= 0.8:
					eff["itimer"] = 0.0
					if is_instance_valid(target): target.take_damage(damage * 0.22)
			"schwarz":
				if is_instance_valid(target): target.velocity = Vector2.ZERO

	super._process(delta)

func _physics_process(delta: float) -> void:
	if not is_alive: return

	_stock_timer  -= delta
	_signal_timer -= delta

	if is_instance_valid(target):
		if _stock_timer <= 0.0 and global_position.distance_to(target.global_position) < STOCK_RNG:
			_stock_timer = STOCK_CD
			_do_stock_hit()

	if _signal_timer <= 0.0:
		_signal_timer = SIGNAL_CD
		_fire_signal()

	super._physics_process(delta)

# ── Aktionen ──────────────────────────────────────────────────────────────────
func _do_stock_hit() -> void:
	if not is_instance_valid(target): return
	if global_position.distance_to(target.global_position) > STOCK_RNG: return
	target.take_damage(damage * 2.0)
	if target.has_method("apply_knockback"):
		target.apply_knockback(
			(target.global_position - global_position).normalized() * 420.0)
	_stock_anim = 1.0
	AudioManager.play_projectile_sfx(0)

func _fire_signal() -> void:
	if not is_instance_valid(target): return
	_pistol_out = 1.0
	var base_dir = (target.global_position - global_position).normalized()
	for a in [-0.28, 0.0, 0.28]:
		var t = SIGNAL_TYPES[randi() % SIGNAL_TYPES.size()]
		var dir = base_dir.rotated(a)
		_signal_shots.append({
			"pos":  global_position + dir * 30.0,
			"vel":  dir * SIGNAL_SPD,
			"type": t,
			"dmg":  damage * 1.0,
		})
	AudioManager.play_boss_siren_sfx()

func _apply_signal_effect(type: String, dmg: float) -> void:
	match type:
		"rot":
			if is_instance_valid(target): target.take_damage(dmg * 0.7)
			_effects.append({"type":"rot",    "timer":3.0, "itimer":0.0})
		"blau":
			if is_instance_valid(target): target.take_damage(dmg * 0.4)
			var orig = 100.0
			if is_instance_valid(target) and "move_speed" in target:
				orig = target.move_speed
				target.move_speed = max(orig * 0.38, 22.0)
			_effects.append({"type":"blau", "timer":3.5, "itimer":0.0, "orig_speed": orig})
		"gelb":
			if is_instance_valid(target):
				target.take_damage(dmg * 2.2)
				if target.has_method("apply_knockback"):
					target.apply_knockback(
						(target.global_position - global_position).normalized() * 510.0)
		"gruen":
			if is_instance_valid(target): target.take_damage(dmg * 0.3)
			_effects.append({"type":"gruen",  "timer":4.5, "itimer":0.0})
		"schwarz":
			if is_instance_valid(target): target.take_damage(dmg * 0.4)
			_effects.append({"type":"schwarz","timer":2.2, "itimer":0.0})
		"weiss":  # Spieler komplett heilen
			if is_instance_valid(target) and target.has_method("heal"):
				target.heal(target.max_hp)
			elif is_instance_valid(target) and "current_hp" in target and "max_hp" in target:
				target.current_hp = target.max_hp
		"rosa":
			_speed_boost = 5.5
			move_speed   = _base_speed * 3.2

func _on_dying_process(_delta: float) -> void:
	_signal_shots.clear()
	_effects.clear()

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	if _dying:
		_draw_death()
		return
	if not is_alive: return

	var _wc   = sin(_anim_time * 4.0)
	var bob   = _wc * 1.2
	var leg_r = _wc * 8.0
	var leg_l = -leg_r
	var arm_r = -leg_r * 0.7
	var arm_l = leg_r * 0.7
	var flash = _hit_flash > 0
	_draw_body(bob, leg_l, leg_r, arm_l, arm_r, flash)
	_draw_signal_shots()
	if _pistol_out > 0.0:
		_draw_signal_pistol(bob, arm_r)

func _draw_body(bob: float, leg_l: float, leg_r: float, arm_l: float, arm_r: float, flash: bool) -> void:
	var skin    = Color(0.88, 0.74, 0.60) if not flash else Color.WHITE
	var beige   = Color(0.80, 0.72, 0.55) if not flash else Color.WHITE
	var grey    = Color(0.55, 0.55, 0.58)
	var slipper = Color(0.42, 0.28, 0.18)
	var cane_c  = Color(0.45, 0.28, 0.10)

	# Hausschuhe
	draw_rect(Rect2(-11, 28 + leg_l * 0.4 + bob, 9, 5), slipper)
	draw_rect(Rect2(2,   28 + leg_r * 0.4 + bob, 9, 5), slipper)
	# Graue Hosen
	draw_rect(Rect2(-9, 12 + leg_l * 0.3 + bob, 7, 18), grey)
	draw_rect(Rect2(2,  12 + leg_r * 0.3 + bob, 7, 18), grey)
	# Beige Strickjacke
	draw_rect(Rect2(-12, -8+bob, 24, 22), beige)
	for ky in [-2.0, 4.0, 10.0]:
		draw_circle(Vector2(0, ky+bob), 2.0, Color(0.62,0.58,0.42))
	# Arme
	draw_rect(Rect2(-20, -4 + arm_l + bob, 8, 18), beige)
	draw_rect(Rect2(12,  -4 + arm_r + bob, 8, 18), beige)
	draw_circle(Vector2(-18, 13 + arm_l + bob), 5, skin)
	draw_circle(Vector2(18,  13 + arm_r + bob), 5, skin)

	# Gehstock (rechte Hand) mit Schwinganimation
	var swing  = _stock_anim * 22.0
	var c_base = Vector2(18, 13 + arm_r + bob)
	var c_dir  = Vector2(sin(deg_to_rad(30.0 + swing)), 0.85).normalized()
	var c_tip  = c_base + c_dir * 38.0
	draw_line(c_base, c_tip, cane_c, 5)
	draw_circle(c_tip, 5, cane_c.darkened(0.2))
	draw_arc(c_base, 5, -PI*0.3, PI*0.3, 5, cane_c.lightened(0.2), 3)
	if _stock_anim > 0.65:
		draw_circle(c_tip, 9, Color(1.0, 0.85, 0.3, (_stock_anim - 0.65) * 2.5))

	# Kopf
	var hb = bob * 0.4
	draw_circle(Vector2(0, -22+hb), 14, skin)
	# Wenige graue Haare (seitlich)
	for i in range(4):
		draw_arc(Vector2(-11+float(i)*5, -28+hb), 4, PI, 0, 5, Color(0.72,0.72,0.75), 3)
	# Schnauzbärtchen
	draw_line(Vector2(-5, -16+hb), Vector2(5, -16+hb), Color(0.62,0.62,0.64), 3)
	# Dicke Brille
	draw_arc(Vector2(-5, -22+hb), 5, 0, TAU, 6, Color(0.18,0.12,0.04), 2)
	draw_arc(Vector2(5,  -22+hb), 5, 0, TAU, 6, Color(0.18,0.12,0.04), 2)
	draw_circle(Vector2(-5, -22+hb), 3, Color(0.55,0.72,0.88))
	draw_circle(Vector2(5,  -22+hb), 3, Color(0.55,0.72,0.88))
	# Mürrischer Mund
	draw_arc(Vector2(0, -13+hb), 5, PI*0.15, PI*0.85, 5, Color(0.45,0.25,0.18), 3)
	# Phase2: Zornige Schläfenadern
	if _phase2:
		draw_line(Vector2(-13,-26+hb), Vector2(-9,-23+hb), Color(0.85,0.08,0.06), 2)
		draw_line(Vector2(13, -26+hb), Vector2(9, -23+hb), Color(0.85,0.08,0.06), 2)

func _draw_signal_pistol(bob: float, arm_r: float) -> void:
	var alpha = _pistol_out
	var px = 22.0; var py = 6.0 + arm_r + bob
	draw_rect(Rect2(px-2, py,    4,  10), Color(0.35,0.20,0.08, alpha))
	draw_rect(Rect2(px-4, py-10, 14,  7), Color(0.22,0.22,0.26, alpha))
	draw_line(Vector2(px+10, py-10), Vector2(px+10, py-3), Color(0.35,0.35,0.40, alpha), 3)
	if _pistol_out > 0.4:
		var fa = (_pistol_out - 0.4) * 1.67
		draw_circle(Vector2(px+12, py-7), 7*fa, Color(1.0, 0.88, 0.2, fa*0.85))
		draw_circle(Vector2(px+16, py-7), 4*fa, Color(1.0, 1.0, 0.5, fa*0.70))

func _draw_signal_shots() -> void:
	for s in _signal_shots:
		var lp    = to_local(s["pos"])
		var col   = SIGNAL_COL.get(s["type"], Color.WHITE)
		var vel_n = (s["vel"].normalized() if s["vel"].length() > 1.0 else Vector2.RIGHT)
		for i in range(4):
			draw_circle(lp - vel_n * float(i+1) * 7.0,
				(4-float(i))*1.8, Color(col.r, col.g, col.b, 0.22-float(i)*0.05))
		draw_circle(lp, 13, Color(col.r, col.g, col.b, 0.28))
		draw_circle(lp,  8, col)
		draw_circle(lp,  4, Color(1.0, 1.0, 1.0, 0.85))
		match s["type"]:
			"rot":
				for fi in range(5):
					var fa = float(fi)/5.0 * TAU
					draw_line(lp, lp + Vector2(cos(fa), sin(fa))*13, Color(1.0,0.5,0.1,0.7), 2)
			"gelb":
				draw_line(lp+Vector2(-3,-8), lp+Vector2(2,-2),  Color(1.0,1.0,0.4,0.9), 2)
				draw_line(lp+Vector2(2, -2), lp+Vector2(-3,2),  Color(1.0,1.0,0.4,0.9), 2)
				draw_line(lp+Vector2(-3,2),  lp+Vector2(3,8),   Color(1.0,1.0,0.4,0.9), 2)
			"gruen":
				draw_circle(lp+Vector2(0,-5), 3, Color(0.1,1.0,0.2,0.8))
				draw_line(lp+Vector2(-3,2), lp+Vector2(3,2), Color(0.1,1.0,0.2,0.7), 2)
			"schwarz":
				draw_line(lp+Vector2(-6,-6), lp+Vector2(6,6),  Color(0.9,0.9,0.9,0.8), 2.5)
				draw_line(lp+Vector2(6, -6), lp+Vector2(-6,6), Color(0.9,0.9,0.9,0.8), 2.5)
			"weiss":
				draw_line(lp+Vector2(-6,0), lp+Vector2(6,0), Color(0.1,0.85,0.1,0.9), 2.5)
				draw_line(lp+Vector2(0,-6), lp+Vector2(0,6), Color(0.1,0.85,0.1,0.9), 2.5)
			"rosa":
				draw_line(lp+Vector2(-5,0), lp+Vector2(5,0), Color(1.0,0.5,0.8,0.9), 3)
				draw_line(lp+Vector2(2,-4), lp+Vector2(6,0), Color(1.0,0.5,0.8,0.9), 2.5)
				draw_line(lp+Vector2(2, 4), lp+Vector2(6,0), Color(1.0,0.5,0.8,0.9), 2.5)

# ── Todesanimation ────────────────────────────────────────────────────────────
func _draw_death() -> void:
	var t      = _death_anim_time
	var beige  = Color(0.78, 0.70, 0.52).darkened(t * 0.35)
	var skin   = Color(0.88, 0.74, 0.60)
	var cane_c = Color(0.45, 0.28, 0.10)
	var fall   = min(t * 50.0, 40.0)

	if t > 0.3:
		draw_circle(Vector2(0, 34), min((t-0.3)*38.0, 28.0), Color(0.78, 0.62, 0.08, 0.55))

	draw_rect(Rect2(-9+fall*0.15,  12+fall*0.48, 7, 14), beige)
	draw_rect(Rect2(2+fall*0.15,   12+fall*0.48, 7, 14), beige)
	draw_rect(Rect2(-12+fall*0.25*min(t*2,1), -8+fall*0.85, 22, 20), beige)
	draw_circle(Vector2(fall*0.30, -22+fall*0.90), 14, skin)
	# Brille fliegt weg
	draw_arc(Vector2(-5 - t*14.0, -22 - t*18.0), 5, 0, TAU, 6, Color(0.18,0.12,0.04), 2)
	# Gehstock fliegt
	draw_line(
		Vector2(18 - t*10.0, 13 - t*18.0),
		Vector2(18 - t*10.0 + sin(t*7)*6, 13 - t*18.0 + 36),
		cane_c, 5)

	modulate.a = 1.0 - max(0.0, (t - 1.2) / 0.4)
