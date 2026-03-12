extends EnemyBase

# Farmtier – spawnt wenn Großbauer pfeift
# Typ wird vor add_child() gesetzt: animal.animal_type = "kuh"

var animal_type: String = "huhn"

const ANIMAL_STATS = {
	"kuh":       {"hp": 55,  "dmg": 12, "spd": 68,  "score": 80},
	"huhn":      {"hp": 12,  "dmg": 4,  "spd": 185, "score": 30},
	"schwein":   {"hp": 40,  "dmg": 10, "spd": 88,  "score": 60},
	"katze":     {"hp": 22,  "dmg": 8,  "spd": 155, "score": 50},
	"hund":      {"hp": 28,  "dmg": 10, "spd": 140, "score": 55},
	"ente":      {"hp": 14,  "dmg": 5,  "spd": 115, "score": 35},
	"kueken":    {"hp": 8,   "dmg": 3,  "spd": 200, "score": 25},
	"schaf":     {"hp": 32,  "dmg": 7,  "spd": 78,  "score": 55},
	"ziege":     {"hp": 26,  "dmg": 9,  "spd": 95,  "score": 60},
	"pferd":     {"hp": 70,  "dmg": 16, "spd": 112, "score": 120},
	"esel":      {"hp": 50,  "dmg": 12, "spd": 68,  "score": 90},
	"kaninchen": {"hp": 14,  "dmg": 4,  "spd": 172, "score": 40},
}

func _ready() -> void:
	var s = ANIMAL_STATS.get(animal_type, ANIMAL_STATS["huhn"])
	max_hp     = float(s["hp"])
	damage     = float(s["dmg"])
	move_speed = float(s["spd"])
	score_value = s["score"]
	enemy_id   = "farm_" + animal_type
	super._ready()

func _draw() -> void:
	if _dying:
		return
	if not is_alive:
		return
	var _wc   = sin(_anim_time * 6.0)
	var bob   = _wc * 1.2
	var la    = _wc * 4.5    # Diagonalpaar A (hinten-links + vorne-rechts)
	var lb    = -la          # Diagonalpaar B (vorne-links + hinten-rechts)
	var flash = _hit_flash > 0
	match animal_type:
		"kuh":       _draw_kuh(bob, la, lb, flash)
		"huhn":      _draw_huhn(bob, flash)
		"schwein":   _draw_schwein(bob, la, lb, flash)
		"katze":     _draw_katze(bob, flash)
		"hund":      _draw_hund(bob, la, lb, flash)
		"ente":      _draw_ente(bob, flash)
		"kueken":    _draw_kueken(bob, flash)
		"schaf":     _draw_schaf(bob, la, lb, flash)
		"ziege":     _draw_ziege(bob, la, lb, flash)
		"pferd":     _draw_pferd(bob, la, lb, flash)
		"esel":      _draw_esel(bob, la, lb, flash)
		"kaninchen": _draw_kaninchen(bob, flash)

# ── Kuh ──────────────────────────────────────────────────────────────────────
func _draw_kuh(b: float, la: float, lb: float, f: bool) -> void:
	var wh  = Color.WHITE if not f else Color(1,1,1,1)
	var blk = Color(0.05, 0.05, 0.05)
	var brn = Color(0.55, 0.35, 0.10)
	# 4-Bein Diagonalgang: hinten-links(0) & vorne-rechts(3) = la; vorne-links(1) & hinten-rechts(2) = lb
	draw_rect(Rect2(-12-3, 10 + la + b, 5, 12), blk)
	draw_rect(Rect2( -4-3, 10 + lb + b, 5, 12), blk)
	draw_rect(Rect2(  4-3, 10 + lb + b, 5, 12), blk)
	draw_rect(Rect2( 12-3, 10 + la + b, 5, 12), blk)
	draw_rect(Rect2(-20, -8+b, 40, 18), wh)
	draw_circle(Vector2(-7, -2+b), 6, blk)
	draw_circle(Vector2(5, 5+b), 4.5, blk)
	draw_circle(Vector2(-1, -6+b), 3.5, blk)
	draw_circle(Vector2(24, -8+b), 11, wh)
	draw_line(Vector2(18, -16+b), Vector2(14, -24+b), brn, 2.5)
	draw_line(Vector2(24, -16+b), Vector2(28, -24+b), brn, 2.5)
	draw_circle(Vector2(28, -6+b), 7, Color(0.95, 0.75, 0.75))
	draw_circle(Vector2(25, -5+b), 2, blk)
	draw_circle(Vector2(30, -5+b), 2, blk)
	draw_circle(Vector2(20, -10+b), 2.5, blk)

# ── Huhn ─────────────────────────────────────────────────────────────────────
func _draw_huhn(b: float, f: bool) -> void:
	var wh  = Color(0.95, 0.92, 0.88) if not f else Color.WHITE
	var red = Color(0.85, 0.15, 0.1)
	var yel = Color(0.95, 0.7, 0.1)
	draw_circle(Vector2(0, 2+b), 13, wh)
	draw_circle(Vector2(0, -12+b), 8, wh)
	for cx in [-3.0, 0.0, 3.0]:
		draw_circle(Vector2(cx, -20+b), 3.5, red)
	draw_colored_polygon(PackedVector2Array([
		Vector2(7,-13+b), Vector2(15,-11+b), Vector2(7,-9+b)
	]), yel)
	draw_circle(Vector2(4, -14+b), 2, Color(0.1,0.1,0.1))
	draw_line(Vector2(-3, 15+b), Vector2(-5, 22+b), yel, 3)
	draw_line(Vector2(3, 15+b), Vector2(5, 22+b), yel, 3)

# ── Schwein ───────────────────────────────────────────────────────────────────
func _draw_schwein(b: float, la: float, lb: float, f: bool) -> void:
	var pk  = Color(0.98, 0.75, 0.78) if not f else Color.WHITE
	var dpk = Color(0.88, 0.55, 0.60)
	draw_rect(Rect2(-12-3, 17 + la + b, 5, 9), dpk)
	draw_rect(Rect2( -4-3, 17 + lb + b, 5, 9), dpk)
	draw_rect(Rect2(  4-3, 17 + lb + b, 5, 9), dpk)
	draw_rect(Rect2( 12-3, 17 + la + b, 5, 9), dpk)
	draw_circle(Vector2(0, 2+b), 18, pk)
	draw_circle(Vector2(20, -5+b), 12, pk)
	draw_colored_polygon(PackedVector2Array([Vector2(12,-14+b),Vector2(8,-24+b),Vector2(18,-20+b)]), dpk)
	draw_colored_polygon(PackedVector2Array([Vector2(22,-14+b),Vector2(24,-24+b),Vector2(28,-18+b)]), dpk)
	draw_circle(Vector2(26, -3+b), 7, dpk)
	draw_circle(Vector2(23, -2+b), 2, Color(0.3,0.1,0.1))
	draw_circle(Vector2(28, -2+b), 2, Color(0.3,0.1,0.1))
	draw_arc(Vector2(-20, 2+b), 6, -PI*0.5, PI*0.5, 8, dpk, 3)
	draw_circle(Vector2(17, -8+b), 2, Color(0.1,0.05,0.05))

# ── Katze ─────────────────────────────────────────────────────────────────────
func _draw_katze(b: float, f: bool) -> void:
	var gy  = Color(0.65, 0.65, 0.68) if not f else Color.WHITE
	var dgy = Color(0.40, 0.40, 0.44)
	draw_rect(Rect2(-14, -8+b, 28, 20), gy)
	draw_arc(Vector2(-20, 8+b), 10, -PI*0.8, PI*0.2, 10, gy, 5)
	draw_circle(Vector2(0, -20+b), 13, gy)
	draw_colored_polygon(PackedVector2Array([Vector2(-14,-26+b),Vector2(-8,-36+b),Vector2(-2,-26+b)]), gy)
	draw_colored_polygon(PackedVector2Array([Vector2(2,-26+b),Vector2(8,-36+b),Vector2(14,-26+b)]), gy)
	draw_colored_polygon(PackedVector2Array([Vector2(-11,-26+b),Vector2(-8,-32+b),Vector2(-5,-26+b)]), Color(0.9,0.5,0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(5,-26+b),Vector2(8,-32+b),Vector2(11,-26+b)]), Color(0.9,0.5,0.55))
	draw_circle(Vector2(-5, -21+b), 3, Color(0.1,0.7,0.2))
	draw_circle(Vector2(5, -21+b), 3, Color(0.1,0.7,0.2))
	draw_rect(Rect2(-6, -22.5+b, 2, 5), Color(0.05,0.05,0.05))
	draw_rect(Rect2(4, -22.5+b, 2, 5), Color(0.05,0.05,0.05))
	for wy in [-22.0, -18.0]:
		draw_line(Vector2(-4, wy+b), Vector2(-18, wy-2+b), dgy, 1)
		draw_line(Vector2(4, wy+b), Vector2(18, wy-2+b), dgy, 1)
	for sy in [-4.0, 2.0, 8.0]:
		draw_line(Vector2(-14, sy+b), Vector2(14, sy+b), dgy, 2)

# ── Hund ──────────────────────────────────────────────────────────────────────
func _draw_hund(b: float, la: float, lb: float, f: bool) -> void:
	var brn = Color(0.72, 0.48, 0.22) if not f else Color.WHITE
	var dbn = Color(0.48, 0.30, 0.10)
	draw_rect(Rect2(-10-3, 12 + la + b, 5, 10), brn)
	draw_rect(Rect2( -2-3, 12 + lb + b, 5, 10), brn)
	draw_rect(Rect2(  6-3, 12 + lb + b, 5, 10), brn)
	draw_rect(Rect2( 14-3, 12 + la + b, 5, 10), brn)
	draw_rect(Rect2(-15, -6+b, 30, 18), brn)
	draw_circle(Vector2(18, -10+b), 14, brn)
	draw_rect(Rect2(8, -12+b, 7, 18), dbn)
	draw_rect(Rect2(22, -12+b, 7, 18), dbn)
	draw_circle(Vector2(24, -6+b), 7, Color(0.85,0.62,0.38))
	draw_circle(Vector2(24, -8+b), 4, Color(0.2,0.1,0.08))
	draw_circle(Vector2(12, -12+b), 2.5, Color(0.1,0.08,0.05))
	draw_circle(Vector2(20, -12+b), 2.5, Color(0.1,0.08,0.05))
	var wag = sin(_anim_time * 12.0) * 0.4
	draw_arc(Vector2(-18, -2+b), 8, -PI*0.8+wag, -PI*0.2+wag, 8, brn, 5)

# ── Ente ──────────────────────────────────────────────────────────────────────
func _draw_ente(b: float, f: bool) -> void:
	var wh  = Color(0.95, 0.92, 0.88) if not f else Color.WHITE
	var org = Color(0.95, 0.55, 0.1)
	draw_circle(Vector2(0, 2+b), 16, wh)
	draw_circle(Vector2(14, -12+b), 10, wh)
	draw_rect(Rect2(22, -14+b, 12, 5), org)
	draw_circle(Vector2(18, -14+b), 2, Color(0.1,0.1,0.1))
	draw_arc(Vector2(-4, 0+b), 12, PI*0.2, PI*0.9, 8, Color(0.75,0.72,0.68), 6)
	draw_rect(Rect2(-6, 17+b, 8, 4), org)
	draw_rect(Rect2(2, 17+b, 8, 4), org)

# ── Küken ─────────────────────────────────────────────────────────────────────
func _draw_kueken(b: float, f: bool) -> void:
	var yel = Color(0.98, 0.9, 0.2) if not f else Color.WHITE
	var org = Color(0.95, 0.55, 0.1)
	draw_circle(Vector2(0, 2+b), 10, yel)
	draw_circle(Vector2(0, -10+b), 8, yel)
	draw_colored_polygon(PackedVector2Array([
		Vector2(7,-10+b), Vector2(12,-9+b), Vector2(7,-8+b)
	]), org)
	draw_circle(Vector2(3, -11+b), 1.5, Color(0.1,0.1,0.1))
	draw_arc(Vector2(-8, 2+b), 6, PI*0.3, PI*0.9, 6, Color(0.85,0.78,0.1), 4)
	draw_arc(Vector2(8, 2+b), 6, PI*0.1, PI*0.7, 6, Color(0.85,0.78,0.1), 4)
	draw_line(Vector2(-3, 11+b), Vector2(-5, 17+b), org, 2)
	draw_line(Vector2(3, 11+b), Vector2(5, 17+b), org, 2)

# ── Schaf ─────────────────────────────────────────────────────────────────────
func _draw_schaf(b: float, la: float, lb: float, f: bool) -> void:
	var wh  = Color(0.94, 0.92, 0.88) if not f else Color.WHITE
	var blk = Color(0.1, 0.08, 0.08)
	draw_rect(Rect2(-8-2, 12 + la + b, 3, 10), blk)
	draw_rect(Rect2(-2-2, 12 + lb + b, 3, 10), blk)
	draw_rect(Rect2( 4-2, 12 + lb + b, 3, 10), blk)
	draw_rect(Rect2(10-2, 12 + la + b, 3, 10), blk)
	for cv in [Vector2(-10,0), Vector2(-4,0), Vector2(4,0), Vector2(10,0),
			   Vector2(0,-6), Vector2(-6,4), Vector2(6,4)]:
		draw_circle(cv + Vector2(0,b), 11, wh)
	draw_circle(Vector2(18, -8+b), 9, blk)
	draw_circle(Vector2(21, -10+b), 2, Color(0.85,0.85,0.85))

# ── Ziege ─────────────────────────────────────────────────────────────────────
func _draw_ziege(b: float, la: float, lb: float, f: bool) -> void:
	var lg  = Color(0.80, 0.78, 0.75) if not f else Color.WHITE
	var dg  = Color(0.52, 0.50, 0.48)
	draw_rect(Rect2(-10-2, 12 + la + b, 4, 10), dg)
	draw_rect(Rect2( -2-2, 12 + lb + b, 4, 10), dg)
	draw_rect(Rect2(  6-2, 12 + lb + b, 4, 10), dg)
	draw_rect(Rect2( 14-2, 12 + la + b, 4, 10), dg)
	draw_rect(Rect2(-16, -6+b, 32, 18), lg)
	draw_circle(Vector2(20, -10+b), 12, lg)
	draw_line(Vector2(14, -18+b), Vector2(10, -26+b), dg, 3)
	draw_line(Vector2(20, -18+b), Vector2(22, -26+b), dg, 3)
	draw_line(Vector2(22, -2+b), Vector2(20, 6+b), dg, 3)
	draw_arc(Vector2(20, 6+b), 4, 0, PI, 8, dg, 3)
	draw_circle(Vector2(15, -12+b), 2.5, Color(0.6,0.4,0.05))
	draw_circle(Vector2(26, -8+b), 6, Color(0.88,0.78,0.72))
	draw_circle(Vector2(23, -6+b), 2, dg)
	draw_circle(Vector2(28, -6+b), 2, dg)

# ── Pferd ─────────────────────────────────────────────────────────────────────
func _draw_pferd(b: float, la: float, lb: float, f: bool) -> void:
	var brn = Color(0.65, 0.38, 0.15) if not f else Color.WHITE
	var dbn = Color(0.38, 0.20, 0.06)
	# 4 Beine mit Diagonalgang
	var _loffs = [la, lb, lb, la]
	var _lxs   = [-16.0, -6.0, 8.0, 18.0]
	for i in range(4):
		draw_rect(Rect2(_lxs[i]-4, 12 + _loffs[i] + b, 7, 14), dbn)
		draw_rect(Rect2(_lxs[i]-4, 24 + _loffs[i] + b, 7, 4), Color(0.15,0.1,0.05))
	draw_rect(Rect2(-22, -10+b, 44, 22), brn)
	draw_rect(Rect2(16, -22+b, 12, 14), brn)
	draw_circle(Vector2(26, -28+b), 14, brn)
	for mx in range(-18, 20, 5):
		draw_line(Vector2(float(mx), -10+b), Vector2(float(mx), -20+b), dbn, 4)
	draw_circle(Vector2(34, -26+b), 3, dbn)
	draw_circle(Vector2(18, -30+b), 3, dbn)
	for i in range(5):
		var angle = -PI*0.3 + float(i)*0.15
		draw_line(Vector2(-22, 0+b), Vector2(-22+cos(angle)*16, sin(angle)*16+b), dbn, 3)

# ── Esel ──────────────────────────────────────────────────────────────────────
func _draw_esel(b: float, la: float, lb: float, f: bool) -> void:
	var gy  = Color(0.62, 0.60, 0.60) if not f else Color.WHITE
	var dgy = Color(0.35, 0.33, 0.32)
	draw_rect(Rect2(-12-3, 12 + la + b, 5, 12), dgy)
	draw_rect(Rect2( -4-3, 12 + lb + b, 5, 12), dgy)
	draw_rect(Rect2(  4-3, 12 + lb + b, 5, 12), dgy)
	draw_rect(Rect2( 12-3, 12 + la + b, 5, 12), dgy)
	draw_rect(Rect2(-18, -8+b, 36, 20), gy)
	draw_rect(Rect2(14, -20+b, 10, 14), gy)
	draw_circle(Vector2(20, -26+b), 13, gy)
	# Lange Ohren – sehr markant
	draw_rect(Rect2(9, -52+b, 6, 30), gy)
	draw_rect(Rect2(24, -52+b, 6, 30), gy)
	draw_rect(Rect2(10.5, -50+b, 3, 26), Color(0.88,0.70,0.70))
	draw_rect(Rect2(25.5, -50+b, 3, 26), Color(0.88,0.70,0.70))
	draw_circle(Vector2(26, -22+b), 8, Color(0.82,0.78,0.72))
	draw_circle(Vector2(23, -20+b), 2, dgy)
	draw_circle(Vector2(28, -20+b), 2, dgy)
	draw_circle(Vector2(16, -28+b), 3, dgy)
	draw_line(Vector2(13, -31+b), Vector2(19, -29+b), dgy, 2)  # trauriger Blick
	draw_line(Vector2(-18, -4+b), Vector2(-26, 4+b), dgy, 3)
	draw_line(Vector2(-26, 4+b), Vector2(-24, 10+b), dgy, 4)

# ── Kaninchen ─────────────────────────────────────────────────────────────────
func _draw_kaninchen(b: float, f: bool) -> void:
	var wh = Color(0.96, 0.94, 0.92) if not f else Color.WHITE
	var pk = Color(0.92, 0.65, 0.68)
	draw_rect(Rect2(-8, 16+b, 6, 8), wh)
	draw_rect(Rect2(2, 16+b, 6, 8), wh)
	draw_circle(Vector2(0, 4+b), 14, wh)
	draw_circle(Vector2(-16, 6+b), 5, wh)  # Schwanz
	draw_circle(Vector2(0, -12+b), 11, wh)
	# Lange Ohren
	draw_rect(Rect2(-10, -50+b, 7, 32), wh)
	draw_rect(Rect2(3, -50+b, 7, 32), wh)
	draw_rect(Rect2(-8.5, -48+b, 4, 28), pk)
	draw_rect(Rect2(4.5, -48+b, 4, 28), pk)
	draw_circle(Vector2(-4, -14+b), 3.5, Color(0.85,0.1,0.1))
	draw_circle(Vector2(4, -14+b), 3.5, Color(0.85,0.1,0.1))
	draw_circle(Vector2(-4, -14+b), 1.5, Color(0.05,0.05,0.05))
	draw_circle(Vector2(4, -14+b), 1.5, Color(0.05,0.05,0.05))
	draw_circle(Vector2(0, -10+b), 2, pk)
