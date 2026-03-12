extends EnemyBase

# Gehasste TV/Film-Figuren – spawnen beim BADFLIX-Special des TV-Gurus
# figur_type vor add_child() setzen!

var figur_type: String = "scrappy"

const FIGUR_STATS = {
	"joffrey":  {"hp": 30,  "dmg": 10, "spd": 90,  "score": 80},
	"umbridge": {"hp": 45,  "dmg": 14, "spd": 75,  "score": 95},
	"jarjar":   {"hp": 15,  "dmg": 6,  "spd": 155, "score": 60},
	"percy":    {"hp": 35,  "dmg": 18, "spd": 85,  "score": 90},
	"ratched":  {"hp": 50,  "dmg": 12, "spd": 65,  "score": 100},
	"bella":    {"hp": 20,  "dmg": 8,  "spd": 110, "score": 70},
	"commodus": {"hp": 55,  "dmg": 16, "spd": 78,  "score": 105},
	"cal":      {"hp": 25,  "dmg": 9,  "spd": 100, "score": 75},
	"scrappy":  {"hp": 12,  "dmg": 8,  "spd": 185, "score": 65},
	"andrea":   {"hp": 38,  "dmg": 20, "spd": 95,  "score": 95},
}

func _ready() -> void:
	var s = FIGUR_STATS.get(figur_type, FIGUR_STATS["scrappy"])
	max_hp     = float(s["hp"])
	damage     = float(s["dmg"])
	move_speed = float(s["spd"])
	score_value = s["score"]
	enemy_id   = "tv_" + figur_type
	super._ready()

func _draw() -> void:
	if _dying: return
	if not is_alive: return
	var _wc   = sin(_anim_time * 5.5)
	var bob   = _wc * 1.4
	var leg_r = _wc * 9.0
	var leg_l = -leg_r
	var arm_r = -_wc * 0.65
	var arm_l = _wc * 0.65
	var flash = _hit_flash > 0
	match figur_type:
		"joffrey":  _draw_joffrey(bob, leg_l, leg_r, arm_l, arm_r, flash)
		"umbridge": _draw_umbridge(bob, leg_l, leg_r, arm_l, arm_r, flash)
		"jarjar":   _draw_jarjar(bob, leg_l, leg_r, arm_l, arm_r, flash)
		"percy":    _draw_percy(bob, leg_l, leg_r, arm_l, arm_r, flash)
		"ratched":  _draw_ratched(bob, leg_l, leg_r, arm_l, arm_r, flash)
		"bella":    _draw_bella(bob, leg_l, leg_r, arm_l, arm_r, flash)
		"commodus": _draw_commodus(bob, leg_l, leg_r, arm_l, arm_r, flash)
		"cal":      _draw_cal(bob, leg_l, leg_r, arm_l, arm_r, flash)
		"scrappy":  _draw_scrappy(bob, leg_l, leg_r, arm_l, arm_r, flash)
		"andrea":   _draw_andrea(bob, leg_l, leg_r, arm_l, arm_r, flash)

# ── Joffrey Baratheon ─────────────────────────────────────────────────────────
func _draw_joffrey(b: float, ll: float, lr: float, al: float, ar: float, f: bool) -> void:
	var skin = Color(0.92, 0.82, 0.72) if not f else Color.WHITE
	var red  = Color(0.75, 0.08, 0.06)
	var gold = Color(0.88, 0.72, 0.10)
	# Stiefel
	draw_rect(Rect2(-12, 26 + ll*0.4 + b, 10, 6), Color(0.15,0.10,0.04))
	draw_rect(Rect2(2,   26 + lr*0.4 + b, 10, 6), Color(0.15,0.10,0.04))
	# Beine / Hose
	draw_rect(Rect2(-11, 12 + ll*0.3 + b, 9, 15), Color(0.60,0.08,0.06))
	draw_rect(Rect2(2,   12 + lr*0.3 + b, 9, 15), Color(0.60,0.08,0.06))
	# Tunika (Lannister-Rot mit Goldrand)
	draw_rect(Rect2(-13, -10+b, 26, 24), red)
	draw_line(Vector2(-13,-10+b), Vector2(13,-10+b), gold, 3)
	draw_line(Vector2(-13, 14+b), Vector2(13, 14+b), gold, 2)
	# Arme
	draw_rect(Rect2(-21, -6 + al + b, 8, 14), red)
	draw_rect(Rect2(13,  -6 + ar + b, 8, 14), red)
	draw_circle(Vector2(-19, 7 + al + b), 6, skin)
	draw_circle(Vector2(19,  7 + ar + b), 6, skin)
	# Goldenes Löwen-Abzeichen
	draw_circle(Vector2(0, 0+b), 5, gold)
	# Kopf
	draw_circle(Vector2(0, -22+b), 13, skin)
	# Goldene Krone
	var crown_pts = PackedVector2Array([
		Vector2(-12,-32+b), Vector2(-12,-40+b), Vector2(-6,-36+b),
		Vector2(0,-42+b),   Vector2(6,-36+b),   Vector2(12,-40+b),
		Vector2(12,-32+b)
	])
	draw_colored_polygon(crown_pts, gold)
	# Blonde Locken
	for i in range(6):
		var cx = -10.0 + float(i)*4.0
		draw_arc(Vector2(cx, -28+b), 4, PI, TAU, 6, Color(0.88,0.78,0.38), 4)
	# Arroganter Schmollmund
	draw_arc(Vector2(0,-18+b), 4, PI*0.2, PI*0.8, 5, Color(0.18,0.08,0.04), 3)
	draw_circle(Vector2(-4,-21+b), 2.5, Color(0.18,0.12,0.06))
	draw_circle(Vector2(4, -21+b), 2.5, Color(0.18,0.12,0.06))

# ── Dolores Umbridge ──────────────────────────────────────────────────────────
func _draw_umbridge(b: float, ll: float, lr: float, al: float, ar: float, f: bool) -> void:
	var pink = Color(0.92, 0.58, 0.72) if not f else Color.WHITE
	var dpk  = Color(0.78, 0.35, 0.55)
	var skin = Color(0.88, 0.75, 0.65)
	# Runder Körper (breit)
	draw_rect(Rect2(-16, 26 + ll*0.4 + b, 14, 6), Color(0.32,0.20,0.10))
	draw_rect(Rect2(2,   26 + lr*0.4 + b, 14, 6), Color(0.32,0.20,0.10))
	draw_rect(Rect2(-14, 10 + ll*0.3 + b, 11, 17), pink)
	draw_rect(Rect2(3,   10 + lr*0.3 + b, 11, 17), pink)
	draw_circle(Vector2(0, 0+b), 18, pink)   # runder Torso
	# Strickjacken-Knöpfe
	for ky in [-6.0, 0.0, 6.0]:
		draw_circle(Vector2(0, ky+b), 2.5, dpk)
	# Kragen (weiß mit Schleife)
	draw_circle(Vector2(0, -14+b), 5, Color(0.94,0.92,0.88))
	draw_circle(Vector2(-4,-13+b), 4, pink); draw_circle(Vector2(4,-13+b), 4, pink)  # Schleife
	# Arme (kurz und rund)
	draw_circle(Vector2(-24, 2 + al + b), 9, pink)
	draw_circle(Vector2(24,  2 + ar + b), 9, pink)
	draw_circle(Vector2(-24, 2 + al + b), 6, skin)
	draw_circle(Vector2(24,  2 + ar + b), 6, skin)
	# Krötengesicht
	draw_circle(Vector2(0, -26+b), 15, skin)
	# Breiter Froschmund
	draw_arc(Vector2(0,-20+b), 8, 0.08, PI-0.08, 6, Color(0.60,0.22,0.18), 5)
	draw_circle(Vector2(-5,-25+b), 3, Color(0.25,0.18,0.12))
	draw_circle(Vector2(5, -25+b), 3, Color(0.25,0.18,0.12))
	# Haarschleife (rosa)
	draw_circle(Vector2(-5,-38+b), 6, pink); draw_circle(Vector2(5,-38+b), 6, pink)
	draw_circle(Vector2(0, -38+b), 4, dpk)
	# Graues Haar
	for i in range(8):
		var hx = -12.0 + float(i)*3.5
		draw_line(Vector2(hx,-32+b), Vector2(hx,-38+b), Color(0.75,0.70,0.72), 3)

# ── Jar Jar Binks ─────────────────────────────────────────────────────────────
func _draw_jarjar(b: float, ll: float, lr: float, al: float, ar: float, f: bool) -> void:
	var tan  = Color(0.72, 0.58, 0.38) if not f else Color.WHITE
	var dtan = Color(0.50, 0.38, 0.22)
	var yel  = Color(0.88, 0.80, 0.42)
	# Lange dünne Beine
	draw_rect(Rect2(-10, 10 + ll*0.3 + b, 7, 22), dtan)
	draw_rect(Rect2(3,   10 + lr*0.3 + b, 7, 22), dtan)
	draw_rect(Rect2(-13, 30 + ll*0.4 + b, 11, 5), dtan)  # breite Füße
	draw_rect(Rect2(2,   30 + lr*0.4 + b, 11, 5), dtan)
	# Schlanker Torso
	draw_rect(Rect2(-11, -8+b, 22, 20), tan)
	draw_circle(Vector2(-18, 4 + al + b), 6, tan)   # Arme
	draw_circle(Vector2(18,  4 + ar + b), 6, tan)
	# Langer Hals
	draw_rect(Rect2(-5, -18+b, 10, 12), tan)
	# Langer Schädel (Gungan)
	draw_circle(Vector2(0, -30+b), 12, tan)
	draw_rect(Rect2(-8, -42+b, 16, 20), tan)  # langer Kopf nach hinten
	# Lange hängende Ohren
	draw_rect(Rect2(-18, -36+b, 8, 28), dtan)
	draw_rect(Rect2(10,  -36+b, 8, 28), dtan)
	draw_line(Vector2(-18,-36+b), Vector2(-10,-36+b), tan, 2)
	draw_line(Vector2(10, -36+b), Vector2(18, -36+b), tan, 2)
	# Quatschen-Mund (weit offen)
	draw_arc(Vector2(0,-24+b), 8, 0.1, PI-0.1, 6, Color(0.18,0.08,0.02), 6)
	# Stielaugen
	draw_circle(Vector2(-7,-34+b), 5, yel)
	draw_circle(Vector2(7, -34+b), 5, yel)
	draw_circle(Vector2(-7,-34+b), 2.5, Color(0.05,0.05,0.05))
	draw_circle(Vector2(7, -34+b), 2.5, Color(0.05,0.05,0.05))

# ── Percy Wetmore ─────────────────────────────────────────────────────────────
func _draw_percy(b: float, ll: float, lr: float, al: float, ar: float, f: bool) -> void:
	var skin = Color(0.88, 0.72, 0.58) if not f else Color.WHITE
	var blue = Color(0.22, 0.30, 0.55)
	var kh   = Color(0.55, 0.38, 0.10)   # Knüppel
	draw_rect(Rect2(-12, 26 + ll*0.4 + b, 10, 6), Color(0.15,0.10,0.04))
	draw_rect(Rect2(2,   26 + lr*0.4 + b, 10, 6), Color(0.15,0.10,0.04))
	draw_rect(Rect2(-11, 12 + ll*0.3 + b, 9, 15), blue)
	draw_rect(Rect2(2,   12 + lr*0.3 + b, 9, 15), blue)
	draw_rect(Rect2(-13, -10+b, 26, 24), blue)
	# Uniformknöpfe und Abzeichen
	for ky in [-4.0, 2.0]: draw_circle(Vector2(0, ky+b), 2, Color(0.78,0.72,0.12))
	draw_circle(Vector2(-8, -2+b), 4, Color(0.78,0.72,0.12))  # Abzeichen
	draw_rect(Rect2(-21, -6 + al + b, 8, 14), blue)
	draw_rect(Rect2(13,  -6 + ar + b, 8, 14), blue)
	draw_circle(Vector2(-19, 7 + al + b), 6, skin)
	draw_circle(Vector2(19,  7 + ar + b), 6, skin)
	# Knüppel rechte Hand – erhoben (folgt rechtem Arm)
	draw_line(Vector2(19, 7 + ar + b), Vector2(32, -8 + ar + b), kh, 5)
	draw_circle(Vector2(32, -8 + ar + b), 5, kh.darkened(0.2))
	# Kopf
	draw_circle(Vector2(0, -22+b), 13, skin)
	# Schirmmütze
	draw_rect(Rect2(-13, -32+b, 26, 9), blue)
	draw_rect(Rect2(-16, -24+b, 32, 4), blue.darkened(0.2))
	# Schmales Schnäuzbärtchen
	draw_line(Vector2(-5,-18+b), Vector2(5,-18+b), Color(0.18,0.12,0.06), 3)
	# Sadistische schmale Augen
	draw_rect(Rect2(-9,-24+b, 6, 3), Color(0.90,0.85,0.78))
	draw_rect(Rect2(3, -24+b, 6, 3), Color(0.90,0.85,0.78))
	draw_circle(Vector2(-6,-23+b), 1.5, Color(0.1,0.06,0.02))
	draw_circle(Vector2(6, -23+b), 1.5, Color(0.1,0.06,0.02))
	draw_arc(Vector2(0,-14+b), 4, 0, PI, 5, Color(0.62,0.22,0.14), 3) # Grinsen

# ── Nurse Ratched ─────────────────────────────────────────────────────────────
func _draw_ratched(b: float, ll: float, lr: float, al: float, ar: float, f: bool) -> void:
	var skin  = Color(0.88, 0.80, 0.74) if not f else Color.WHITE
	var white = Color(0.94, 0.92, 0.90)
	var blue  = Color(0.58, 0.72, 0.82)  # kalte blaue Augen
	draw_rect(Rect2(-12, 26 + ll*0.4 + b, 10, 6), Color(0.85,0.82,0.78))
	draw_rect(Rect2(2,   26 + lr*0.4 + b, 10, 6), Color(0.85,0.82,0.78))
	draw_rect(Rect2(-11, 12 + ll*0.3 + b, 9, 15), white)
	draw_rect(Rect2(2,   12 + lr*0.3 + b, 9, 15), white)
	draw_rect(Rect2(-13, -10+b, 26, 24), white)
	# Kragen (blauer Streifen)
	draw_line(Vector2(-13,-10+b), Vector2(13,-10+b), Color(0.52,0.62,0.75), 4)
	draw_rect(Rect2(-20, -6 + al + b, 7, 14), white)
	draw_rect(Rect2(13,  -6 + ar + b, 7, 14), white)
	draw_circle(Vector2(-18, 7 + al + b), 6, skin)
	draw_circle(Vector2(18,  7 + ar + b), 6, skin)
	# Klemmbrett rechte Hand (folgt rechtem Arm)
	draw_rect(Rect2(16, -8 + ar + b, 14, 18), Color(0.75,0.65,0.45))
	draw_rect(Rect2(17, -6 + ar + b, 12, 15), white)
	draw_line(Vector2(18,-5 + ar + b), Vector2(27,-5 + ar + b), Color(0.7,0.7,0.7), 1.5)
	draw_line(Vector2(18,-1 + ar + b), Vector2(27,-1 + ar + b), Color(0.7,0.7,0.7), 1.5)
	draw_line(Vector2(18, 3 + ar + b), Vector2(27, 3 + ar + b), Color(0.7,0.7,0.7), 1.5)
	# Kopf
	draw_circle(Vector2(0, -22+b), 13, skin)
	# Schwesternhaube
	var cap_pts = PackedVector2Array([
		Vector2(-14,-30+b), Vector2(0,-44+b), Vector2(14,-30+b)
	])
	draw_colored_polygon(cap_pts, white)
	draw_line(Vector2(-14,-30+b), Vector2(14,-30+b), white.darkened(0.2), 2)
	draw_rect(Rect2(-8,-32+b, 16, 4), Color(0.52,0.62,0.75))  # blaues Kreuz
	draw_rect(Rect2(-2,-38+b, 4, 12), Color(0.52,0.62,0.75))
	# Kalter Ausdruck
	draw_rect(Rect2(-8,-25+b, 6, 4), Color(0.92,0.90,0.88))
	draw_rect(Rect2(2, -25+b, 6, 4), Color(0.92,0.90,0.88))
	draw_circle(Vector2(-5,-24+b), 2, blue)
	draw_circle(Vector2(5, -24+b), 2, blue)
	draw_line(Vector2(-7,-18+b), Vector2(7,-18+b), Color(0.55,0.40,0.35), 2)  # dünner Strich-Mund

# ── Bella Swan ────────────────────────────────────────────────────────────────
func _draw_bella(b: float, ll: float, lr: float, al: float, ar: float, f: bool) -> void:
	var skin  = Color(0.95, 0.90, 0.86) if not f else Color.WHITE  # sehr blass
	var brown = Color(0.35, 0.20, 0.08)
	var shirt = Color(0.48, 0.36, 0.24)  # Flanellhemd braun/grau
	draw_rect(Rect2(-11, 26 + ll*0.4 + b, 9, 6), Color(0.20,0.14,0.06))
	draw_rect(Rect2(2,   26 + lr*0.4 + b, 9, 6), Color(0.20,0.14,0.06))
	draw_rect(Rect2(-10, 12 + ll*0.3 + b, 8, 15), Color(0.32,0.28,0.45))  # Jeans
	draw_rect(Rect2(2,   12 + lr*0.3 + b, 8, 15), Color(0.32,0.28,0.45))
	draw_rect(Rect2(-12, -10+b, 24, 24), shirt)
	for sx in [-8.0, -2.0, 4.0]:
		draw_line(Vector2(sx,-10+b), Vector2(sx,14+b), shirt.darkened(0.3), 1)
	draw_rect(Rect2(-20, -6 + al + b, 8, 14), shirt)
	draw_rect(Rect2(12,  -6 + ar + b, 8, 14), shirt)
	draw_circle(Vector2(-18, 7 + al + b), 5, skin)
	draw_circle(Vector2(18,  7 + ar + b), 5, skin)
	# Blasser Kopf
	draw_circle(Vector2(0, -22+b), 13, skin)
	# Braune Haare (lang, zerzaust)
	for i in range(10):
		var hx = -14.0 + float(i)*3.0
		var swing = sin(float(i)*0.9 + _anim_time) * 3.0
		draw_line(Vector2(hx,-30+b), Vector2(hx+swing,14+b), brown, 3.5)
	# Leerer Ausdruck (Twilight-typisch)
	draw_circle(Vector2(-4,-23+b), 3, Color(0.55,0.38,0.22))
	draw_circle(Vector2(4, -23+b), 3, Color(0.55,0.38,0.22))
	draw_circle(Vector2(-4,-23+b), 1.5, Color(0.05,0.05,0.05))
	draw_circle(Vector2(4, -23+b), 1.5, Color(0.05,0.05,0.05))
	draw_line(Vector2(-4,-16+b), Vector2(4,-16+b), Color(0.65,0.45,0.38), 2)  # gerader Mund

# ── Commodus ──────────────────────────────────────────────────────────────────
func _draw_commodus(b: float, ll: float, lr: float, al: float, ar: float, f: bool) -> void:
	var skin  = Color(0.88, 0.75, 0.60) if not f else Color.WHITE
	var armor = Color(0.72, 0.68, 0.52)  # Rüstung
	var purp  = Color(0.45, 0.10, 0.55)  # Purpur-Toga
	var gold  = Color(0.88, 0.72, 0.10)
	draw_rect(Rect2(-12, 26 + ll*0.4 + b, 10, 6), Color(0.25,0.20,0.10))
	draw_rect(Rect2(2,   26 + lr*0.4 + b, 10, 6), Color(0.25,0.20,0.10))
	draw_rect(Rect2(-11, 12 + ll*0.3 + b, 9, 15), purp)
	draw_rect(Rect2(2,   12 + lr*0.3 + b, 9, 15), purp)
	# Rüstung (Lorica)
	draw_rect(Rect2(-14, -10+b, 28, 24), armor)
	for ay in [-6.0, -1.0, 4.0]:
		draw_line(Vector2(-14,ay+b), Vector2(14,ay+b), armor.darkened(0.25), 2)
	# Goldene Verzierung
	draw_line(Vector2(-14,-10+b), Vector2(14,-10+b), gold, 3)
	draw_circle(Vector2(0, -2+b), 6, gold)   # Brust-Medaillon
	# Schulterpanzer
	draw_rect(Rect2(-22, -12 + al + b, 10, 8), armor.darkened(0.1))
	draw_rect(Rect2(12,  -12 + ar + b, 10, 8), armor.darkened(0.1))
	draw_circle(Vector2(-19, 7 + al + b), 6, skin)
	draw_circle(Vector2(19,  7 + ar + b), 6, skin)
	# Kopf
	draw_circle(Vector2(0, -24+b), 14, skin)
	# Lorbeerkranz
	for i in range(10):
		var la = float(i) * TAU/10.0 - PI*0.5
		draw_circle(Vector2(cos(la)*14, -24+b+sin(la)*14), 4, Color(0.22,0.55,0.12))
	# Kleines Ziegenbärtchen
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3,-14+b), Vector2(3,-14+b), Vector2(1,-8+b), Vector2(-1,-8+b)
	]), Color(0.28,0.18,0.08))
	# Böser Blick
	draw_circle(Vector2(-5,-26+b), 3, Color(0.62,0.38,0.10))
	draw_circle(Vector2(5, -26+b), 3, Color(0.62,0.38,0.10))
	draw_line(Vector2(-9,-29+b), Vector2(-1,-27+b), Color(0.18,0.10,0.04), 2.5)
	draw_line(Vector2(1,-27+b),  Vector2(9,-29+b),  Color(0.18,0.10,0.04), 2.5)
	draw_arc(Vector2(0,-19+b), 4, 0, PI, 5, Color(0.62,0.22,0.12), 3)

# ── Cal Hockley ───────────────────────────────────────────────────────────────
func _draw_cal(b: float, ll: float, lr: float, al: float, ar: float, f: bool) -> void:
	var skin  = Color(0.90, 0.78, 0.65) if not f else Color.WHITE
	var suit  = Color(0.20, 0.20, 0.25)
	var white = Color(0.94, 0.92, 0.88)
	var glas  = Color(0.88, 0.82, 0.38)  # Champagnerglas
	draw_rect(Rect2(-12, 26 + ll*0.4 + b, 10, 6), Color(0.10,0.08,0.06))
	draw_rect(Rect2(2,   26 + lr*0.4 + b, 10, 6), Color(0.10,0.08,0.06))
	draw_rect(Rect2(-11, 12 + ll*0.3 + b, 9, 15), suit)
	draw_rect(Rect2(2,   12 + lr*0.3 + b, 9, 15), suit)
	draw_rect(Rect2(-13, -10+b, 26, 24), suit)
	draw_rect(Rect2(-4, -10+b, 8, 12), white)  # weißes Hemd
	# Fliege
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5,-6+b), Vector2(0,-3+b), Vector2(-5,0+b)
	]), Color(0.60,0.05,0.05))
	draw_colored_polygon(PackedVector2Array([
		Vector2(5,-6+b), Vector2(0,-3+b), Vector2(5,0+b)
	]), Color(0.60,0.05,0.05))
	# Revers
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4,-10+b), Vector2(-13,-2+b), Vector2(-5,4+b)
	]), white)
	draw_colored_polygon(PackedVector2Array([
		Vector2(4,-10+b), Vector2(13,-2+b), Vector2(5,4+b)
	]), white)
	draw_rect(Rect2(-20, -6 + al + b, 7, 14), suit)
	draw_rect(Rect2(13,  -6 + ar + b, 7, 14), suit)
	draw_circle(Vector2(-18, 7 + al + b), 5, skin)
	draw_circle(Vector2(18,  7 + ar + b), 5, skin)
	# Champagnerglas rechts (folgt rechtem Arm)
	draw_line(Vector2(22,-2 + ar + b), Vector2(22,14 + ar + b), glas, 2)   # Stiel
	draw_arc(Vector2(22,-8 + ar + b), 6, PI*0.1, PI*0.9, 6, glas, 3)  # Kelch
	draw_circle(Vector2(22,-6 + ar + b), 3, Color(0.92,0.88,0.30,0.7))  # Sekt
	# Kopf mit zurückgekämmten dunklen Haaren
	draw_circle(Vector2(0, -22+b), 13, skin)
	for i in range(8):
		var hx = -10.0 + float(i)*2.8
		draw_line(Vector2(hx,-34+b), Vector2(hx+4,-28+b), Color(0.18,0.12,0.06), 3)
	# Arrogantes Grinsen
	draw_arc(Vector2(2,-17+b), 5, PI*0.15, PI*0.7, 5, Color(0.62,0.22,0.12), 3)
	draw_circle(Vector2(-4,-21+b), 2.5, Color(0.25,0.16,0.08))
	draw_circle(Vector2(4, -21+b), 2.5, Color(0.25,0.16,0.08))
	draw_line(Vector2(-8,-24+b), Vector2(-2,-22+b), Color(0.18,0.10,0.04), 2)
	draw_line(Vector2(2,-22+b),  Vector2(8,-24+b),  Color(0.18,0.10,0.04), 2)

# ── Scrappy-Doo ───────────────────────────────────────────────────────────────
func _draw_scrappy(b: float, ll: float, lr: float, al: float, ar: float, f: bool) -> void:
	var tan  = Color(0.82, 0.65, 0.35) if not f else Color.WHITE
	var dtan = Color(0.55, 0.40, 0.18)
	var red  = Color(0.80, 0.08, 0.06)
	# Kleiner aggressiver Hund (Boxpose)
	# Beine
	draw_rect(Rect2(-9, 18 + ll*0.3 + b, 7, 12), tan)
	draw_rect(Rect2(2,  18 + lr*0.3 + b, 7, 12), tan)
	draw_rect(Rect2(-10,28 + ll*0.4 + b, 8, 5), dtan)  # Pfoten
	draw_rect(Rect2(2,  28 + lr*0.4 + b, 8, 5), dtan)
	# Kleiner Körper
	draw_circle(Vector2(0, 6+b), 13, tan)
	# Schwanz (hoch erhoben – aggressiv)
	draw_arc(Vector2(-14, 0+b), 8, -PI*0.8, -PI*0.1, 8, tan, 5)
	# Halsbandkragen
	draw_circle(Vector2(0, -8+b), 8, Color(0.70,0.08,0.06))
	draw_rect(Rect2(-7,-10+b, 14, 5), red)
	draw_circle(Vector2(0,-8+b), 3, Color(0.88,0.72,0.10))   # Marke
	# Kleine Fäuste erhoben (Boxpose, schwingen mit Armen)
	draw_circle(Vector2(-20, -4 + al + b), 7, tan)
	draw_circle(Vector2(20,  -4 + ar + b), 7, tan)
	draw_circle(Vector2(-20, -4 + al + b), 5, dtan)
	draw_circle(Vector2(20,  -4 + ar + b), 5, dtan)
	# Großer aggressiver Kopf
	draw_circle(Vector2(0, -20+b), 14, tan)
	# Große abstehende Ohren
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8,-28+b), Vector2(-18,-42+b), Vector2(-4,-30+b)
	]), tan)
	draw_colored_polygon(PackedVector2Array([
		Vector2(8,-28+b), Vector2(18,-42+b), Vector2(4,-30+b)
	]), tan)
	# Wütende Augen
	draw_circle(Vector2(-5,-21+b), 4, Color(0.95,0.92,0.88))
	draw_circle(Vector2(5, -21+b), 4, Color(0.95,0.92,0.88))
	draw_circle(Vector2(-5,-21+b), 2, Color(0.08,0.05,0.02))
	draw_circle(Vector2(5, -21+b), 2, Color(0.08,0.05,0.02))
	draw_line(Vector2(-10,-26+b), Vector2(-2,-23+b), dtan, 3)
	draw_line(Vector2(2,  -23+b), Vector2(10,-26+b), dtan, 3)
	# Geblecktes Maul
	draw_arc(Vector2(0,-14+b), 5, 0.1, PI-0.1, 5, Color(0.10,0.05,0.02), 4)
	for ti in [-3.0, 0.0, 3.0]:
		draw_line(Vector2(ti,-14+b), Vector2(ti,-10+b), Color(0.94,0.92,0.88), 2)

# ── Andrea (Walking Dead) ─────────────────────────────────────────────────────
func _draw_andrea(b: float, ll: float, lr: float, al: float, ar: float, f: bool) -> void:
	var skin  = Color(0.88, 0.74, 0.60) if not f else Color.WHITE
	var brn   = Color(0.35, 0.28, 0.18)   # braune Überlebenden-Klamotten
	var dbrn  = Color(0.22, 0.16, 0.08)
	var gun   = Color(0.28, 0.28, 0.30)
	draw_rect(Rect2(-11, 26 + ll*0.4 + b, 9, 6), Color(0.18,0.12,0.04))
	draw_rect(Rect2(2,   26 + lr*0.4 + b, 9, 6), Color(0.18,0.12,0.04))
	draw_rect(Rect2(-10, 12 + ll*0.3 + b, 8, 15), dbrn)
	draw_rect(Rect2(2,   12 + lr*0.3 + b, 8, 15), dbrn)
	draw_rect(Rect2(-12, -10+b, 24, 24), brn)
	# Riemenzeug (Überlebendes)
	draw_line(Vector2(-12,-10+b), Vector2(6,14+b),  Color(0.18,0.14,0.06), 3)
	draw_line(Vector2(12,-10+b),  Vector2(-6,14+b), Color(0.18,0.14,0.06), 3)
	draw_rect(Rect2(-20, -6 + al + b, 8, 14), brn)
	draw_rect(Rect2(12,  -6 + ar + b, 8, 14), brn)
	draw_circle(Vector2(-18, 7 + al + b), 5, skin)
	draw_circle(Vector2(18,  7 + ar + b), 5, skin)
	# Pistole rechte Hand – erhoben (folgt rechtem Arm)
	draw_rect(Rect2(18, -6 + ar + b, 12, 7), gun)
	draw_rect(Rect2(22, -6 + ar + b, 4, 10), gun.darkened(0.2))  # Griff
	draw_circle(Vector2(30,-3 + ar + b), 3, gun.lightened(0.1))   # Lauf-Ende
	# Kopf
	draw_circle(Vector2(0, -22+b), 13, skin)
	# Blonde zerzauste Haare (Post-Apokalypse)
	for i in range(8):
		var hx = -11.0 + float(i)*3.0
		var swing = sin(float(i)*1.1) * 4.0
		draw_line(Vector2(hx,-30+b), Vector2(hx+swing,-18+b), Color(0.82,0.70,0.30), 3)
	# Müder/gestresster Ausdruck
	draw_circle(Vector2(-4,-23+b), 2.5, Color(0.42,0.28,0.14))
	draw_circle(Vector2(4, -23+b), 2.5, Color(0.42,0.28,0.14))
	draw_line(Vector2(-6,-20+b), Vector2(6,-20+b), Color(0.55,0.35,0.25), 2)
	# Augenringe (Erschöpfung)
	draw_arc(Vector2(-4,-22+b), 4, PI*0.1, PI*0.9, 4, Color(0.38,0.22,0.14,0.5), 2)
	draw_arc(Vector2(4, -22+b), 4, PI*0.1, PI*0.9, 4, Color(0.38,0.22,0.14,0.5), 2)
