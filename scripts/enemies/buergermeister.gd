extends EnemyBase

# Spießiges Rentnerpaar: Willi & Gerlinde Schrei-Stopp
# Willi  (links):    Gehstock-Hieb
# Gerlinde (rechts): Rollator-Ramme
# Spezial:           Signalpistole – 3 zufällige Leuchtmunition mit Effekten

const STOCK_CD    = 1.8
const STOCK_RNG   = 70.0
const ROLLER_CD   = 2.4
const ROLLER_RNG  = 78.0
const SIGNAL_CD   = 13.0
const SIGNAL_SPD  = 280.0
const SIGNAL_RNG  = 520.0

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

var _phase2: bool         = false
var _base_speed: float    = 38.0

var _stock_timer: float   = 1.0
var _roller_timer: float  = 1.6
var _signal_timer: float  = 9.0

var _stock_anim: float    = 0.0   # 1→0: Gehstock-Schwinganimation
var _roller_anim: float   = 0.0   # 1→0: Rollator-Stoßanimation
var _pistol_out: float    = 0.0   # 1→0: Signalpistole sichtbar

# Projektile: {pos, vel, type, dmg}
var _signal_shots: Array  = []

# Aktive Status-Effekte: {type, timer, itimer, orig_speed?}
var _effects: Array       = []
var _speed_boost: float   = 0.0   # Timer für rosa-Boost

func _ready() -> void:
	enemy_id             = "buergermeister"
	max_hp               = 1000.0
	damage               = 28.0
	move_speed           = 38.0
	score_value          = 2400
	_death_anim_duration = 1.8
	_base_speed          = move_speed
	add_to_group("bosses")
	super._ready()

# ── Update ────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not is_alive or _dying:
		super._process(delta)
		return

	# Phase-2 bei 50 % HP
	if not _phase2 and current_hp <= max_hp * 0.5:
		_phase2    = true
		move_speed = _base_speed * 1.75

	# Animationen abklingen
	if _stock_anim  > 0.0: _stock_anim  = max(0.0, _stock_anim  - delta * 3.5)
	if _roller_anim > 0.0: _roller_anim = max(0.0, _roller_anim - delta * 3.0)
	if _pistol_out  > 0.0: _pistol_out  = max(0.0, _pistol_out  - delta * 1.6)

	# Geschwindigkeitsboost ablaufen
	if _speed_boost > 0.0:
		_speed_boost -= delta
		if _speed_boost <= 0.0:
			move_speed = _base_speed * (1.75 if _phase2 else 1.0)

	# Signalprojektile bewegen
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

	# Aktive Effekte verarbeiten
	for i in range(_effects.size() - 1, -1, -1):
		var eff = _effects[i]
		eff["timer"] -= delta
		if eff["timer"] <= 0.0:
			# Effekt beenden – ggf. Originalwert wiederherstellen
			if eff["type"] == "blau" and is_instance_valid(target) and "move_speed" in target:
				target.move_speed = eff.get("orig_speed", 100.0)
			_effects.remove_at(i)
			continue
		match eff["type"]:
			"rot":     # Feuer-DoT alle 0.5 s
				eff["itimer"] += delta
				if eff["itimer"] >= 0.5:
					eff["itimer"] = 0.0
					if is_instance_valid(target):
						target.take_damage(damage * 0.35)
			"gruen":   # Gift-DoT alle 0.8 s
				eff["itimer"] += delta
				if eff["itimer"] >= 0.8:
					eff["itimer"] = 0.0
					if is_instance_valid(target):
						target.take_damage(damage * 0.22)
			"schwarz": # Bewegungsunfähig – Velocity jeden Frame auf null
				if is_instance_valid(target):
					target.velocity = Vector2.ZERO

	super._process(delta)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_stock_timer  -= delta
	_roller_timer -= delta
	_signal_timer -= delta

	if is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if _stock_timer <= 0.0 and dist < STOCK_RNG:
			_stock_timer = STOCK_CD
			_do_stock_hit()
		if _roller_timer <= 0.0 and dist < ROLLER_RNG:
			_roller_timer = ROLLER_CD
			_do_roller_hit()

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

func _do_roller_hit() -> void:
	if not is_instance_valid(target): return
	if global_position.distance_to(target.global_position) > ROLLER_RNG: return
	target.take_damage(damage * 1.6)
	if target.has_method("apply_knockback"):
		target.apply_knockback(
			(target.global_position - global_position).normalized() * 300.0)
	_roller_anim = 1.0
	AudioManager.play_projectile_sfx(0)

func _fire_signal() -> void:
	if not is_instance_valid(target): return
	_pistol_out = 1.0
	var base_dir = (target.global_position - global_position).normalized()
	# 3 Schüsse – zufällige Typen, leichter Fächer
	var angles = [-0.28, 0.0, 0.28]
	for a in angles:
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
		"rot":    # Feuer – Initialschaden + DoT
			if is_instance_valid(target): target.take_damage(dmg * 0.7)
			_effects.append({"type":"rot",    "timer":3.0, "itimer":0.0})

		"blau":   # Wasser – stark verlangsamt
			if is_instance_valid(target): target.take_damage(dmg * 0.4)
			var orig = 100.0
			if is_instance_valid(target) and "move_speed" in target:
				orig = target.move_speed
				target.move_speed = max(orig * 0.38, 22.0)
			_effects.append({"type":"blau", "timer":3.5, "itimer":0.0, "orig_speed": orig})

		"gelb":   # Blitz – hoher Sofortschaden + Knockback
			if is_instance_valid(target):
				target.take_damage(dmg * 2.2)
				if target.has_method("apply_knockback"):
					target.apply_knockback(
						(target.global_position - global_position).normalized() * 510.0)

		"gruen":  # Gift – langsame DoT
			if is_instance_valid(target): target.take_damage(dmg * 0.3)
			_effects.append({"type":"gruen",  "timer":4.5, "itimer":0.0})

		"schwarz":# Bewegungsunfähig
			if is_instance_valid(target): target.take_damage(dmg * 0.4)
			_effects.append({"type":"schwarz","timer":2.2, "itimer":0.0})

		"weiss":  # Komplette Heilung des Spielers!
			if is_instance_valid(target) and target.has_method("heal"):
				target.heal(target.max_hp)
			elif is_instance_valid(target) and "current_hp" in target and "max_hp" in target:
				target.current_hp = target.max_hp

		"rosa":   # Geschwindigkeitsboost
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
	if not is_alive:
		return

	var _wc   = sin(_anim_time * 3.5)
	var bob   = _wc * 1.2
	var leg_r = _wc * 7.0
	var leg_l = -leg_r
	var arm_r = -leg_r * 0.7
	var arm_l = leg_r * 0.7
	var flash = _hit_flash > 0
	_draw_willi(bob, flash, leg_l, leg_r, arm_l, arm_r)
	_draw_gerlinde(bob, flash, leg_l, leg_r)
	_draw_signal_shots()
	if _pistol_out > 0.0:
		_draw_signal_pistol(bob)

# ── Willi Schrei-Stopp (links, Gehstock) ──────────────────────────────────────
func _draw_willi(bob: float, flash: bool, leg_l: float = 0.0, leg_r: float = 0.0, arm_l: float = 0.0, arm_r: float = 0.0) -> void:
	var ox     = -24.0
	var skin   = Color(0.88, 0.74, 0.60) if not flash else Color.WHITE
	var beige  = Color(0.80, 0.72, 0.55) if not flash else Color.WHITE
	var grey   = Color(0.55, 0.55, 0.58)
	var slipper= Color(0.42, 0.28, 0.18)
	var cane_c = Color(0.45, 0.28, 0.10)

	# Hausschuhe (animiert mit Beinen)
	draw_rect(Rect2(ox-11, 28 + leg_l * 0.4 + bob, 9,  5), slipper)
	draw_rect(Rect2(ox+2,  28 + leg_r * 0.4 + bob, 9,  5), slipper)
	# Graue Hosen (animiert)
	draw_rect(Rect2(ox-9,  12 + leg_l * 0.3 + bob, 7,  18), grey)
	draw_rect(Rect2(ox+2,  12 + leg_r * 0.3 + bob, 7,  18), grey)
	# Beige Strickjacke
	draw_rect(Rect2(ox-12, -8+bob, 24, 22), beige)
	# Knöpfe
	for ky in [-2.0, 4.0, 10.0]:
		draw_circle(Vector2(ox, ky+bob), 2.0, Color(0.62,0.58,0.42))
	# Arme (animiert)
	draw_rect(Rect2(ox-20, -4 + arm_l + bob, 8, 18), beige)
	draw_rect(Rect2(ox+12, -4 + arm_r + bob, 8, 18), beige)
	draw_circle(Vector2(ox-18, 13 + arm_l + bob), 5, skin)
	draw_circle(Vector2(ox+18, 13 + arm_r + bob), 5, skin)

	# Gehstock (rechte Hand) – Ability-Schwinganimation; folgt Arm-Position
	var swing   = _stock_anim * 22.0
	var c_base  = Vector2(ox+18, 13 + arm_r + bob)
	var c_dir   = Vector2(sin(deg_to_rad(30.0 + swing)), 0.85).normalized()
	var c_tip   = c_base + c_dir * 38.0
	draw_line(c_base, c_tip, cane_c, 5)
	draw_circle(c_tip, 5, cane_c.darkened(0.2))   # Gummikappe
	draw_arc(c_base, 5, -PI*0.3, PI*0.3, 5, cane_c.lightened(0.2), 3)  # Griff
	# Aufprall-Flash beim Schlag
	if _stock_anim > 0.65:
		draw_circle(c_tip, 9, Color(1.0, 0.85, 0.3, (_stock_anim - 0.65) * 2.5))

	# Kopf
	draw_circle(Vector2(ox, -22 + bob * 0.4), 14, skin)
	# Wenige graue Haare (seitlich)
	for i in range(4):
		draw_arc(Vector2(ox-11+float(i)*5, -28 + bob * 0.4), 4, PI, 0, 5, Color(0.72,0.72,0.75), 3)
	# Kleines Schnauzbärtchen
	draw_line(Vector2(ox-5, -16 + bob * 0.4), Vector2(ox+5, -16 + bob * 0.4), Color(0.62,0.62,0.64), 3)
	# Dicke Brille
	draw_arc(Vector2(ox-5, -22 + bob * 0.4), 5, 0, TAU, 6, Color(0.18,0.12,0.04), 2)
	draw_arc(Vector2(ox+5, -22 + bob * 0.4), 5, 0, TAU, 6, Color(0.18,0.12,0.04), 2)
	draw_line(Vector2(ox, -22 + bob * 0.4), Vector2(ox, -22 + bob * 0.4), Color(0.18,0.12,0.04), 2)
	draw_circle(Vector2(ox-5, -22 + bob * 0.4), 3, Color(0.55,0.72,0.88))
	draw_circle(Vector2(ox+5, -22 + bob * 0.4), 3, Color(0.55,0.72,0.88))
	# Mürrisch heruntergezogener Mund
	draw_arc(Vector2(ox, -13 + bob * 0.4), 5, PI*0.15, PI*0.85, 5, Color(0.45,0.25,0.18), 3)
	# Phase2: Zornige Schläfenadern
	if _phase2:
		draw_line(Vector2(ox-13,-26 + bob * 0.4), Vector2(ox-9,-23 + bob * 0.4), Color(0.85,0.08,0.06), 2)
		draw_line(Vector2(ox+13,-26 + bob * 0.4), Vector2(ox+9,-23 + bob * 0.4), Color(0.85,0.08,0.06), 2)

# ── Gerlinde Schrei-Stopp (rechts, Rollator) ──────────────────────────────────
func _draw_gerlinde(bob: float, flash: bool, leg_l: float = 0.0, leg_r: float = 0.0) -> void:
	var ox     = 24.0
	var skin   = Color(0.90, 0.78, 0.68) if not flash else Color.WHITE
	var dress  = Color(0.88, 0.56, 0.64) if not flash else Color.WHITE
	var white  = Color(0.94, 0.92, 0.90)
	var metal  = Color(0.62, 0.64, 0.68)
	var gold_e = Color(0.85, 0.70, 0.08)

	# Rollator (in front of Gerlinde, stößt nach vorne bei Ramme)
	var ram_y = -_roller_anim * 11.0
	var ry    = -4.0 + bob + ram_y
	# Griff-Querstange
	draw_line(Vector2(ox-14, ry),    Vector2(ox+14, ry),    metal, 4)
	# Senkrechte Beine
	draw_line(Vector2(ox-14, ry),    Vector2(ox-14, ry+20), metal, 3)
	draw_line(Vector2(ox+14, ry),    Vector2(ox+14, ry+20), metal, 3)
	# Untere Querstange
	draw_line(Vector2(ox-14, ry+18), Vector2(ox+14, ry+18), metal, 3)
	# Räder (kleine Kreise)
	draw_circle(Vector2(ox-14, ry+22), 4, Color(0.22,0.22,0.25))
	draw_circle(Vector2(ox+14, ry+22), 4, Color(0.22,0.22,0.25))
	# Hände greifen Griffe
	draw_circle(Vector2(ox-14, ry+2), 4, skin)
	draw_circle(Vector2(ox+14, ry+2), 4, skin)
	# Aufprall-Flash
	if _roller_anim > 0.65:
		draw_circle(Vector2(ox, ry-2), 12, Color(0.9, 0.5, 0.8, (_roller_anim-0.65)*2.8))

	# Schuhe (lila Hausschuhe, animiert)
	draw_rect(Rect2(ox-11, 28 + leg_l * 0.4 + bob, 9, 5), Color(0.62,0.38,0.62))
	draw_rect(Rect2(ox+2,  28 + leg_r * 0.4 + bob, 9, 5), Color(0.62,0.38,0.62))
	# Midi-Kleid (rosa mit Blumenmuster)
	draw_rect(Rect2(ox-14, 6+bob,  28, 24), dress)
	# Blumenmuster-Tupfer
	for fx in [-6.0, 0.0, 6.0]:
		for fy in [10.0, 18.0]:
			draw_circle(Vector2(ox+fx, fy+bob), 2.5, Color(1.0,0.90,0.25))
			draw_circle(Vector2(ox+fx, fy+bob), 1.2, Color(0.95,0.30,0.30))
	# Oberteil
	draw_rect(Rect2(ox-11, -8+bob, 22, 16), dress)
	# Weißer Kragen
	draw_circle(Vector2(ox, -8+bob), 5, white)
	# Arme (halten Rollator – nur bob, kein Arm-Swing)
	draw_rect(Rect2(ox-19, -2+bob, 6, 16), dress)
	draw_rect(Rect2(ox+13, -2+bob, 6, 16), dress)
	# Handtasche (hängt am Rollator-Griff links)
	draw_rect(Rect2(ox-24, ry+4,  10, 9), Color(0.55,0.28,0.50))
	draw_line(Vector2(ox-14, ry+2), Vector2(ox-22, ry+6), Color(0.45,0.22,0.40), 2)

	# Kopf
	draw_circle(Vector2(ox, -22 + bob * 0.4), 13, skin)
	# Weißes Haar – Dutt
	draw_circle(Vector2(ox, -30 + bob * 0.4), 10, white)
	draw_circle(Vector2(ox, -32 + bob * 0.4), 7, white.darkened(0.12))
	# Haarnetz-Punkte
	for ni in range(5):
		var na = float(ni) / 5.0 * TAU
		draw_circle(Vector2(ox + cos(na)*6, -31 + bob * 0.4 + sin(na)*3.5), 1.5, white.darkened(0.3))
	# Goldene Ohrringe
	draw_circle(Vector2(ox-14, -22 + bob * 0.4), 3.5, gold_e)
	draw_circle(Vector2(ox+14, -22 + bob * 0.4), 3.5, gold_e)
	# Augen
	draw_circle(Vector2(ox-4, -22 + bob * 0.4), 3, white)
	draw_circle(Vector2(ox+4, -22 + bob * 0.4), 3, white)
	draw_circle(Vector2(ox-4, -22 + bob * 0.4), 1.8, Color(0.30,0.18,0.08))
	draw_circle(Vector2(ox+4, -22 + bob * 0.4), 1.8, Color(0.30,0.18,0.08))
	# Zusammengepresste Lippen
	draw_line(Vector2(ox-5, -14 + bob * 0.4), Vector2(ox+5, -14 + bob * 0.4), Color(0.72,0.38,0.38), 3)
	# Phase2: Zornesfalten
	if _phase2:
		draw_line(Vector2(ox-8,-26 + bob * 0.4), Vector2(ox-2,-24 + bob * 0.4), Color(0.55,0.28,0.18), 2.5)
		draw_line(Vector2(ox+2,-24 + bob * 0.4), Vector2(ox+8,-26 + bob * 0.4), Color(0.55,0.28,0.18), 2.5)

# ── Signalpistole (Willis rechte Hand) ───────────────────────────────────────
func _draw_signal_pistol(bob: float) -> void:
	var ox    = -24.0
	var alpha = _pistol_out
	var px    = ox + 22.0
	var py    = 6.0 + bob
	# Griff
	draw_rect(Rect2(px-2, py, 4, 10), Color(0.35,0.20,0.08, alpha))
	# Lauf (kurzer Leuchtpistolen-Lauf, nach oben/schräg)
	draw_rect(Rect2(px-4, py-10, 14, 7), Color(0.22,0.22,0.26, alpha))
	# Laufmündung
	draw_line(Vector2(px+10, py-10), Vector2(px+10, py-3), Color(0.35,0.35,0.40, alpha), 3)
	# Mündungsblitz
	if _pistol_out > 0.4:
		var fa = (_pistol_out - 0.4) * 1.67
		draw_circle(Vector2(px+12, py-7), 7*fa, Color(1.0, 0.88, 0.2, fa*0.85))
		draw_circle(Vector2(px+16, py-7), 4*fa, Color(1.0, 1.0, 0.5, fa*0.7))

# ── Signal-Projektile ─────────────────────────────────────────────────────────
func _draw_signal_shots() -> void:
	for s in _signal_shots:
		var lp  = to_local(s["pos"])
		var col = SIGNAL_COL.get(s["type"], Color.WHITE)
		var vel_n = (s["vel"].normalized() if s["vel"].length() > 1.0 else Vector2.RIGHT)
		# Schweif
		for i in range(4):
			var tp = lp - vel_n * float(i+1) * 7.0
			draw_circle(tp, (4-float(i))*1.8, Color(col.r, col.g, col.b, 0.22-float(i)*0.05))
		# Leuchtgeschoss – Schein, Kern, weißes Zentrum
		draw_circle(lp, 13, Color(col.r, col.g, col.b, 0.28))
		draw_circle(lp,  8, col)
		draw_circle(lp,  4, Color(1.0, 1.0, 1.0, 0.85))
		# Effekt-Indikator
		match s["type"]:
			"rot":     # Flammen-Zacken
				for fi in range(5):
					var fa = float(fi)/5.0 * TAU
					draw_line(lp, lp + Vector2(cos(fa), sin(fa))*13, Color(1.0,0.5,0.1,0.7), 2)
			"gelb":    # Blitz-Zickzack
				draw_line(lp+Vector2(-3,-8), lp+Vector2(2,-2),  Color(1.0,1.0,0.4,0.9), 2)
				draw_line(lp+Vector2(2,-2),  lp+Vector2(-3,2),  Color(1.0,1.0,0.4,0.9), 2)
				draw_line(lp+Vector2(-3,2),  lp+Vector2(3,8),   Color(1.0,1.0,0.4,0.9), 2)
			"gruen":   # Gift-Tropfen
				draw_circle(lp+Vector2(0,-5), 3, Color(0.1,1.0,0.2,0.8))
				draw_line(lp+Vector2(-3,2), lp+Vector2(3,2), Color(0.1,1.0,0.2,0.7), 2)
			"schwarz": # X (Stopp)
				draw_line(lp+Vector2(-6,-6), lp+Vector2(6,6),  Color(0.9,0.9,0.9,0.8), 2.5)
				draw_line(lp+Vector2(6,-6),  lp+Vector2(-6,6), Color(0.9,0.9,0.9,0.8), 2.5)
			"weiss":   # Grünes Kreuz (Heilung)
				draw_line(lp+Vector2(-6,0), lp+Vector2(6,0),  Color(0.1,0.85,0.1,0.9), 2.5)
				draw_line(lp+Vector2(0,-6), lp+Vector2(0,6),  Color(0.1,0.85,0.1,0.9), 2.5)
			"rosa":    # Pfeil-Blitz (Boost)
				draw_line(lp+Vector2(-5,0), lp+Vector2(5,0), Color(1.0,0.5,0.8,0.9), 3)
				draw_line(lp+Vector2(2,-4), lp+Vector2(6,0), Color(1.0,0.5,0.8,0.9), 2.5)
				draw_line(lp+Vector2(2, 4), lp+Vector2(6,0), Color(1.0,0.5,0.8,0.9), 2.5)

# ── Todesanimation ────────────────────────────────────────────────────────────
func _draw_death() -> void:
	var t      = _death_anim_time
	var beige  = Color(0.78, 0.70, 0.52).darkened(t * 0.35)
	var dress  = Color(0.85, 0.52, 0.60).darkened(t * 0.35)
	var skin   = Color(0.88, 0.74, 0.60)
	var metal  = Color(0.55, 0.57, 0.62)
	var cane_c = Color(0.45, 0.28, 0.10)

	var fall = min(t * 50.0, 40.0)

	# Goldschimmer am Boden
	if t > 0.3:
		draw_circle(Vector2(0, 34), min((t-0.3)*38.0, 28.0),
			Color(0.78, 0.62, 0.08, 0.55))

	# Willi kippt nach links
	var wox = -26.0 - fall * 0.4
	draw_rect(Rect2(wox-9, 14+fall*0.45, 7, 14), beige)
	draw_rect(Rect2(wox-10, -8+fall*0.85, 20, 20), beige)
	draw_circle(Vector2(wox, -22+fall*0.90), 14, skin)
	# Gehstock fliegt
	draw_line(
		Vector2(wox+18 - t*14.0, 13 - t*16.0),
		Vector2(wox+18 - t*14.0 + 8, 13 - t*16.0 + 36),
		cane_c, 5)

	# Gerlinde kippt nach rechts
	var gox = 26.0 + fall * 0.4
	draw_rect(Rect2(gox-14, 6+fall*0.44, 28, 18), dress)
	draw_circle(Vector2(gox, -22+fall*0.90), 13, skin)
	# Rollator fliegt/kippt
	var rx = gox + t * 20.0
	draw_line(Vector2(rx-14, 14-t*10.0), Vector2(rx+14, 14-t*10.0), metal, 3)
	draw_line(Vector2(rx-14, 14-t*10.0), Vector2(rx-16, 32+t*8.0),  metal, 2)
	draw_line(Vector2(rx+14, 14-t*10.0), Vector2(rx+16, 32+t*8.0),  metal, 2)

	modulate.a = 1.0 - max(0.0, (t - 1.4) / 0.4)
