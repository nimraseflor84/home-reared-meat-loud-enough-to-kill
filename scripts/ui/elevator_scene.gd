extends Node2D

# Strand-Fahrstuhl-Szene als eigenständiger Node2D.
# Node2D hat ein eigenes CanvasItem – _draw() läuft zuverlässig auch
# wenn der SceneTree pausiert ist (process_mode = ALWAYS).

var _time: float = 0.0
var _font: Font = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var f = SystemFont.new()
	f.font_names  = PackedStringArray(["Impact", "Arial Black", "Arial"])
	f.font_weight = 700
	_font = f

func reset() -> void:
	_time = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var vp = get_viewport_rect()
	var w = vp.size.x
	var h = vp.size.y
	if w < 2.0 or h < 2.0:
		return
	var t = _time
	_draw_sky(w, h, t)
	_draw_ocean(w, h, t)
	_draw_beach(w, h, t)
	_draw_crabs(w, h, t)
	_draw_dolphins(w, h, t)
	_draw_palms(w, h, t)
	_draw_elevator(w, h, t)
	# Dunkler Streifen oben für den Titel
	draw_rect(Rect2(0, 0, w, 72), Color(0, 0, 0, 0.48))

# ── Himmel ────────────────────────────────────────────────────────────────────
func _draw_sky(w: float, h: float, t: float) -> void:
	var horizon = h * 0.50
	var sun_angle = fmod(t * 0.055, TAU)
	var sun_s = sin(sun_angle)

	var sky_top: Color
	var sky_bot: Color
	if sun_s > 0.25:
		sky_top = Color(0.22, 0.52, 0.92)
		sky_bot = Color(0.55, 0.78, 0.98)
	elif sun_s > -0.10:
		var d = (sun_s + 0.10) / 0.35
		sky_top = Color(0.22, 0.52, 0.92).lerp(Color(0.06, 0.05, 0.18), 1.0 - d)
		sky_bot = Color(0.55, 0.78, 0.98).lerp(Color(0.90, 0.44, 0.14), d * 0.72)
	else:
		sky_top = Color(0.03, 0.04, 0.14)
		sky_bot = Color(0.07, 0.08, 0.20)

	draw_rect(Rect2(0, 0, w, horizon), sky_top)
	for i in range(9):
		var y = horizon * (0.66 + float(i) * 0.038)
		var a = float(i) / 9.0
		draw_rect(Rect2(0, y, w, horizon * 0.042 + 1), sky_bot * Color(1, 1, 1, a * 0.52))

	# Sterne (nachts)
	var star_v = clamp(1.0 - sun_s * 4.0, 0.0, 1.0)
	if star_v > 0.05:
		for i in range(58):
			var sx = fmod(float(i) * 317.7, w)
			var sy = fmod(float(i) * 173.3, horizon * 0.90)
			var tw = 0.5 + 0.5 * sin(t * (1.2 + float(i) * 0.08) + float(i) * 1.9)
			draw_circle(Vector2(sx, sy), 1.3, Color(1, 1, 0.95, star_v * tw * 0.88))

	# Sonne
	var sun_cx = w * 0.5 - cos(sun_angle) * w * 0.44
	var sun_cy = horizon - sun_s * horizon * 0.84
	if sun_s > -0.12:
		var sa = clamp((sun_s + 0.12) / 0.26, 0.0, 1.0)
		var sc = Color(1.0, 0.95, 0.50) if sun_s > 0.15 else Color(1.0, 0.58, 0.18)
		for r in range(4):
			draw_circle(Vector2(sun_cx, sun_cy), 36 + r * 10, Color(sc.r, sc.g, sc.b, 0.055 * sa))
		draw_circle(Vector2(sun_cx, sun_cy), 32, Color(sc.r, sc.g * 0.92, sc.b * 0.65, sa))
		draw_circle(Vector2(sun_cx, sun_cy), 24, Color(1.0, 1.0, 0.92, sa))

	# Mond
	var mn_angle = sun_angle + PI
	var mn_s = sin(mn_angle)
	var mn_cx = w * 0.5 - cos(mn_angle) * w * 0.44
	var mn_cy = horizon - mn_s * horizon * 0.84
	if mn_s > -0.12:
		var ma = clamp((mn_s + 0.12) / 0.26, 0.0, 1.0) * clamp(1.0 - sun_s * 4.0, 0.0, 1.0)
		if ma > 0.02:
			draw_circle(Vector2(mn_cx, mn_cy), 23, Color(0.85, 0.88, 0.97, ma * 0.88))
			draw_circle(Vector2(mn_cx, mn_cy), 19, Color(0.97, 0.97, 1.0, ma))
			draw_circle(Vector2(mn_cx - 6, mn_cy - 5), 4.5, Color(0.82, 0.82, 0.90, ma))
			draw_circle(Vector2(mn_cx + 7, mn_cy + 4), 3.2, Color(0.82, 0.82, 0.90, ma))
			draw_circle(Vector2(mn_cx - 1, mn_cy + 8), 2.5, Color(0.82, 0.82, 0.90, ma))

# ── Ozean ─────────────────────────────────────────────────────────────────────
func _draw_ocean(w: float, h: float, t: float) -> void:
	var horizon = h * 0.50
	var sun_angle = fmod(t * 0.055, TAU)
	var sun_s = sin(sun_angle)
	var wd = clamp(sun_s, 0.0, 1.0)

	draw_rect(Rect2(0, horizon, w, h * 0.76 - horizon),
		Color(0.06 + wd * 0.10, 0.22 + wd * 0.18, 0.52 + wd * 0.18))

	if sun_s > 0.05:
		var sun_cx = w * 0.5 - cos(sun_angle) * w * 0.44
		var rc = Color(1.0, 0.88, 0.42) if sun_s > 0.20 else Color(1.0, 0.58, 0.20)
		for i in range(9):
			var rw = 5.5 - float(i) * 0.40
			var ry = horizon + 6 + float(i) * 24
			var rx_off = sin(t * 2.8 + float(i) * 0.65) * 9.0
			draw_rect(Rect2(sun_cx - rw * 0.5 + rx_off, ry, rw, 13),
				Color(rc.r, rc.g, rc.b, (0.55 - float(i) * 0.055) * clamp(sun_s * 2.5, 0, 1)))

	for row in range(5):
		var wy = horizon + 18 + float(row) * 36
		var spd = 1.20 + float(row) * 0.28
		var amp = 2.5 + float(row) * 1.6
		var pts = PackedVector2Array()
		var steps = int(w / 5) + 2
		for s in range(steps):
			var xv = float(s) * 5.0
			var yv = wy + sin(xv * 0.022 + t * spd + float(row) * 1.05) * amp \
					 + cos(xv * 0.014 + t * spd * 0.68) * amp * 0.45
			pts.append(Vector2(xv, yv))
		if pts.size() > 1:
			draw_polyline(pts, Color(0.58, 0.83, 0.98, 0.28 - float(row) * 0.03), 1.8)

# ── Strand ────────────────────────────────────────────────────────────────────
func _draw_beach(w: float, h: float, t: float) -> void:
	var beach_top = h * 0.76
	draw_rect(Rect2(0, beach_top, w, h - beach_top), Color(0.86, 0.80, 0.58))
	draw_rect(Rect2(0, beach_top, w, 10), Color(0.70, 0.63, 0.42))
	for i in range(4):
		draw_line(Vector2(0, beach_top + 22 + float(i) * 26),
			Vector2(w, beach_top + 22 + float(i) * 26), Color(0.76, 0.70, 0.50, 0.32), 1.5)
	for i in range(7):
		var fx = fmod(float(i) * 185.0 + t * 18.0, w + 40.0) - 40.0
		draw_circle(Vector2(fx, beach_top + 3), 20, Color(1, 1, 1, 0.38))
		draw_circle(Vector2(fx + 18, beach_top + 2), 13, Color(1, 1, 1, 0.28))

# ── Palmen ────────────────────────────────────────────────────────────────────
func _draw_palms(w: float, h: float, t: float) -> void:
	var gy = h * 0.76
	_draw_one_palm(w * 0.06, gy, t)
	_draw_one_palm(w * 0.88, gy, t + 1.3)
	_draw_one_palm(w * 0.14, gy + 5, t + 0.5)

func _draw_one_palm(x: float, gy: float, t: float) -> void:
	var sw = sin(t * 1.1 + x * 0.008) * 7.0
	var top = Vector2(x + sw, gy - 92)
	var tp = PackedVector2Array([
		Vector2(x - 7, gy), Vector2(x - 4 + sw * 0.28, gy - 46),
		Vector2(top.x - 3, top.y), Vector2(top.x + 5, top.y),
		Vector2(x + 5 + sw * 0.28, gy - 46), Vector2(x + 9, gy),
	])
	draw_colored_polygon(tp, Color(0.52, 0.35, 0.15))
	for i in range(5):
		draw_line(Vector2(x - 7 + sw * float(i) * 0.06, gy - float(i) * 18),
			Vector2(x + 9 + sw * float(i) * 0.06, gy - float(i) * 18),
			Color(0.40, 0.26, 0.10, 0.42), 1.5)
	for i in range(2):
		draw_circle(top + Vector2(float(i) * 9 - 4, 8), 5.5, Color(0.48, 0.28, 0.10))
	for i in range(6):
		var ba = -PI * 0.5 + float(i) * TAU / 6.0
		var fsw = sin(t * 1.1 + float(i) * 0.75 + x * 0.008) * 0.13
		var ang = ba + fsw
		var tip = top + Vector2(cos(ang) * 58, sin(ang) * 58 + 14)
		var mid = top + Vector2(cos(ang) * 29, sin(ang) * 29 + 7)
		var perp = Vector2(-sin(ang), cos(ang))
		draw_colored_polygon(PackedVector2Array([top, mid + perp * 7.5, tip, mid - perp * 7.5]),
			Color(0.17, 0.50, 0.13))

# ── Delfine ───────────────────────────────────────────────────────────────────
func _draw_dolphins(w: float, h: float, t: float) -> void:
	var surf = h * 0.50 + 10
	for i in range(3):
		var spd = 0.52 + float(i) * 0.17
		var off = float(i) * TAU / 3.0 + 0.9
		var phase = fmod(t * spd + off, TAU)
		var jump = sin(phase)
		var hx = w * (0.18 + float(i) * 0.28) + cos(phase * 0.38 + float(i)) * 60.0
		if jump <= -0.35:
			continue
		var by = surf - jump * 72.0 if jump >= 0 else surf + abs(jump) * 14.0
		var tilt = -cos(phase) * 0.52
		var ct = cos(tilt); var st = sin(tilt)

		var bpts = PackedVector2Array()
		for a in range(12):
			var ang = float(a) * TAU / 12.0
			bpts.append(Vector2(hx + cos(ang) * 30 * ct - sin(ang) * 11 * st,
								by  + cos(ang) * 30 * st + sin(ang) * 11 * ct))
		draw_colored_polygon(bpts, Color(0.18, 0.32, 0.52))

		var belpts = PackedVector2Array()
		for a in range(8):
			var ang = float(a) * TAU / 8.0
			belpts.append(Vector2(hx + cos(ang) * 20 * ct - max(sin(ang), 0.0) * 7 * st,
								   by  + cos(ang) * 20 * st + max(sin(ang), 0.0) * 7 * ct))
		draw_colored_polygon(belpts, Color(0.62, 0.76, 0.84, 0.55))

		draw_colored_polygon(PackedVector2Array([
			Vector2(hx - 2*ct,          by - 2*st),
			Vector2(hx + 4*ct + st*22,  by + 4*st - ct*22),
			Vector2(hx + 12*ct,         by + 12*st),
		]), Color(0.12, 0.24, 0.42))

		var tb = Vector2(hx - 28*ct, by - 28*st)
		var perp = Vector2(st, -ct)
		draw_colored_polygon(PackedVector2Array([
			tb,
			tb + perp * 16 - Vector2(ct, st) * 14,
			tb - Vector2(ct, st) * 7,
			tb - perp * 16 - Vector2(ct, st) * 14,
		]), Color(0.12, 0.24, 0.42))

		var ep = Vector2(hx + 22*ct - st*3, by + 22*st + ct*3)
		draw_circle(ep, 2.5, Color(1, 1, 1, 0.88))
		draw_circle(ep + Vector2(0.4, 0.4), 1.5, Color(0.05, 0.05, 0.1))

		if abs(jump) < 0.22 and jump > -0.08:
			for s in range(6):
				var sx = hx + (float(s) - 2.5) * 10
				var syt = surf - 22.0 * (1.0 - abs(jump) * 4.5)
				draw_line(Vector2(sx, surf), Vector2(sx + (float(s) - 2.5) * 4, syt),
					Color(0.85, 0.95, 1.0, 0.72), 2.0)

# ── Glasfahrstuhl ─────────────────────────────────────────────────────────────
func _draw_elevator(w: float, h: float, t: float) -> void:
	var cx  = w * 0.5
	var ew  = 320.0
	var eh  = 370.0
	var elx = cx - ew * 0.5

	draw_line(Vector2(elx - 12, 0),      Vector2(elx - 12, h),      Color(0.55, 0.58, 0.68, 0.45), 6.0)
	draw_line(Vector2(elx + ew + 12, 0), Vector2(elx + ew + 12, h), Color(0.55, 0.58, 0.68, 0.45), 6.0)

	for j in range(14):
		var dy = fmod(float(j) * (h / 14.0) - t * 38.0, h)
		if dy < 0: dy += h
		draw_circle(Vector2(cx, dy), 2.5, Color(0.50, 0.52, 0.62, 0.50))

	var cyc  = 11.0
	var prog = fmod(t / cyc, 1.0)
	var sm   = prog * prog * (3.0 - 2.0 * prog)
	var ety  = h + 20.0 - sm * (h + eh + 30.0)

	if ety + eh < h:
		for s in range(5):
			draw_rect(Rect2(elx + float(s) * 2.5, ety + eh, ew - float(s) * 5.0, 5),
				Color(0, 0, 0, 0.035 * float(5 - s)))

	draw_rect(Rect2(elx + 8, ety + 8, ew - 16, eh - 16), Color(0.68, 0.86, 0.95, 0.26))
	_draw_chars_in_lift(elx, ety, ew, eh, t)

	var fr = Color(0.65, 0.70, 0.82)
	draw_rect(Rect2(elx,           ety,           ew, 12), fr)
	draw_rect(Rect2(elx,           ety + eh - 12, ew, 12), fr)
	draw_rect(Rect2(elx,           ety,           12, eh), fr)
	draw_rect(Rect2(elx + ew - 12, ety,           12, eh), fr)
	draw_rect(Rect2(elx,           ety + eh * 0.47, ew, 6), fr)
	for bx2 in [elx + 2, elx + ew - 10]:
		for by2 in [ety + 2, ety + eh - 11]:
			draw_circle(Vector2(bx2 + 4, by2 + 4), 3.5, Color(0.48, 0.50, 0.60))

	draw_line(Vector2(elx + 16, ety + 16), Vector2(elx + 16, ety + eh - 16), Color(1, 1, 1, 0.38), 3.0)
	draw_line(Vector2(elx + 26, ety + 18), Vector2(elx + 26, ety + eh * 0.58), Color(1, 1, 1, 0.18), 2.0)

	var blink = int(t * 2.5) % 2
	draw_circle(Vector2(cx, ety + 6), 6, Color(0.0, 0.75 + float(blink) * 0.25, 0.0, 0.85))

	draw_rect(Rect2(elx + 12, ety + eh - 22, ew - 24, 10), Color(0.50, 0.40, 0.30))
	draw_rect(Rect2(elx + 12, ety + eh - 22, ew - 24, 2),  Color(0.65, 0.55, 0.42))

func _draw_chars_in_lift(elx: float, ety: float, ew: float, eh: float, t: float) -> void:
	# Versetzt-alternierende Positionen damit alle 6 Chars sichtbar sind:
	# x-Ordnung: 48(F1) 88(B1) 128(F2) 168(B2) 208(F3) 248(B3)
	var back_y  = ety + eh - 22.0
	var front_y = ety + eh - 14.0
	# Hinterreihe: Manni(0) Shouter(1) Dreads(2) – Scale 0.88, versetzt nach rechts
	_draw_lift_person(0, elx + 88.0,  back_y,  0.88, t)
	_draw_lift_person(1, elx + 168.0, back_y,  0.88, t + 0.55)
	_draw_lift_person(2, elx + 248.0, back_y,  0.88, t + 1.10)
	# Vorderreihe: RiffSlicer(3) Distortion(4) Bassist(5) – Scale 1.15, versetzt nach links
	_draw_lift_person(3, elx + 48.0,  front_y, 1.15, t + 1.65)
	_draw_lift_person(4, elx + 128.0, front_y, 1.15, t + 2.20)
	_draw_lift_person(5, elx + 208.0, front_y, 1.15, t + 2.75)

	# Namens-Labels
	if _font:
		var names      = ["Manny", "Chicken", "Nik", "Andz", "Grindhouse", "Armin"]
		var name_color = Color(0.95, 0.92, 0.72, 0.90)
		var back_xs  = [elx + 88.0,  elx + 168.0, elx + 248.0]
		var front_xs = [elx + 48.0,  elx + 128.0, elx + 208.0]
		for i in range(3):
			draw_string(_font, Vector2(back_xs[i]  - 28, back_y  + 8),
				names[i],     HORIZONTAL_ALIGNMENT_CENTER, 56, 11, name_color)
			draw_string(_font, Vector2(front_xs[i] - 34, front_y + 12),
				names[i + 3], HORIZONTAL_ALIGNMENT_CENTER, 68, 11, name_color)

# ── Charakter-Zeichner ─────────────────────────────────────────────────────────
func _draw_lift_person(char_id: int, cx: float, feet_y: float, sc: float, t: float) -> void:
	var bob = sin(t * 1.8) * 2.0 * sc
	var fy  = feet_y + bob
	var body_colors = [
		Color(0.18, 0.38, 0.88),  # 0 Manni     – blau
		Color(0.85, 0.18, 0.18),  # 1 Shouter   – rot
		Color(0.18, 0.75, 0.28),  # 2 Dreads    – grün
		Color(0.92, 0.48, 0.08),  # 3 RiffSlicer– orange
		Color(0.55, 0.18, 0.88),  # 4 Distortion– lila
		Color(0.10, 0.25, 0.68),  # 5 Bassist   – dunkelblau
	]
	var col = body_colors[char_id]

	# Beine + Schuhe
	draw_line(Vector2(cx - 5*sc, fy - 22*sc), Vector2(cx - 4*sc, fy), Color(0.18, 0.12, 0.08), 3.0 * sc)
	draw_line(Vector2(cx + 5*sc, fy - 22*sc), Vector2(cx + 4*sc, fy), Color(0.18, 0.12, 0.08), 3.0 * sc)
	draw_rect(Rect2(cx - 9*sc, fy - 2.5*sc, 5.5*sc, 4.5*sc), Color(0.1, 0.08, 0.06))
	draw_rect(Rect2(cx + 3.5*sc, fy - 2.5*sc, 5.5*sc, 4.5*sc), Color(0.1, 0.08, 0.06))

	# Körper (charakterspezifisch)
	var leg_len = 22.0 * sc
	var body_h  = 28.0 * sc
	var body_w  = 11.0 * sc
	var by = fy - leg_len - body_h
	_draw_char_body(char_id, cx, by, body_w, body_h, col, sc, t)

	# Arme + Instrument
	_draw_char_arms(char_id, cx, by + body_h * 0.38, sc, col, t)

	# Kopf
	var head_r = 10.0 * sc
	var hy = by - head_r * 0.55
	draw_circle(Vector2(cx, hy), head_r, col.lightened(0.22))
	# Augenweißes
	draw_circle(Vector2(cx - 3.2*sc, hy - 1.0*sc), 2.0*sc, Color(1, 1, 1, 0.92))
	draw_circle(Vector2(cx + 3.2*sc, hy - 1.0*sc), 2.0*sc, Color(1, 1, 1, 0.92))
	# Pupillen
	draw_circle(Vector2(cx - 2.8*sc, hy - 0.8*sc), 1.2*sc, Color(0.05, 0.04, 0.1))
	draw_circle(Vector2(cx + 2.8*sc, hy - 0.8*sc), 1.2*sc, Color(0.05, 0.04, 0.1))
	# Mund (animiert – singt)
	var mouth_open = (sin(t * 3.5 + float(char_id)) * 0.5 + 0.5) * 2.0 * sc
	draw_arc(Vector2(cx, hy + 3.5*sc), 3.0*sc, 0.1, PI - 0.1, 7, Color(0.2, 0.08, 0.06), max(1.2, sc * 1.8))
	if mouth_open > 0.5:
		draw_circle(Vector2(cx, hy + 4.5*sc), mouth_open, Color(0.15, 0.06, 0.06))

	# Frisur / Accessoires
	_draw_char_hair(char_id, cx, hy, head_r, sc, t, col)

func _draw_char_body(cid: int, cx: float, by: float, bw: float, bh: float, col: Color, sc: float, t: float) -> void:
	match cid:
		0:  # Manni – Sechseck (Drummer)
			var pts = PackedVector2Array()
			for i in range(6):
				var a = float(i) * TAU / 6.0 - PI / 6.0
				pts.append(Vector2(cx + cos(a) * bw, by + bh * 0.5 + sin(a) * bh * 0.52))
			draw_colored_polygon(pts, col)
		1:  # Shouter – Dreieck (Kegelform, Mikrofon-Silhouette)
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, by + 3*sc),
				Vector2(cx - bw * 1.35, by + bh),
				Vector2(cx + bw * 1.35, by + bh),
			]), col)
		2:  # Dreads – Kreis
			draw_circle(Vector2(cx, by + bh * 0.5), bw * 1.05, col)
		3:  # Riff Slicer – Raute
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, by),
				Vector2(cx - bw * 1.3, by + bh * 0.5),
				Vector2(cx, by + bh),
				Vector2(cx + bw * 1.3, by + bh * 0.5),
			]), col)
		4:  # Distortion – Quadrat + animierte Wellenlinien
			draw_rect(Rect2(cx - bw, by, bw * 2.0, bh), col)
			for i in range(3):
				var wy = by + bh * (0.22 + float(i) * 0.26)
				var wpts = PackedVector2Array()
				for xi in range(6):
					wpts.append(Vector2(
						cx - bw * 0.85 + float(xi) * bw * 0.35,
						wy + sin(t * 3.5 + float(xi) * 1.1 + float(i) * 1.4) * 2.5 * sc))
				if wpts.size() > 1:
					draw_polyline(wpts, Color(1, 1, 1, 0.35), 1.2)
		5:  # Bassist – Oktagon
			var pts = PackedVector2Array()
			for i in range(8):
				var a = float(i) * TAU / 8.0
				pts.append(Vector2(cx + cos(a) * bw, by + bh * 0.5 + sin(a) * bh * 0.5))
			draw_colored_polygon(pts, col)

func _draw_char_arms(cid: int, cx: float, arm_y: float, sc: float, col: Color, t: float) -> void:
	var swing = sin(t * 1.85) * 0.25
	var la = Vector2(cx - 13*sc - swing * 4*sc, arm_y + 9*sc)
	var ra = Vector2(cx + 13*sc + swing * 4*sc, arm_y + 9*sc)
	draw_line(Vector2(cx - 7*sc, arm_y), la, col.darkened(0.18), 3.2 * sc)
	draw_line(Vector2(cx + 7*sc, arm_y), ra, col.darkened(0.18), 3.2 * sc)
	match cid:
		0:  # Manni – zwei Drumsticks
			draw_line(la, la + Vector2(-7*sc, -15*sc), Color(0.72, 0.55, 0.28), 2.2 * sc)
			draw_line(ra, ra + Vector2( 7*sc, -15*sc), Color(0.72, 0.55, 0.28), 2.2 * sc)
			draw_circle(la + Vector2(-7*sc, -15*sc), 2.8*sc, Color(0.50, 0.35, 0.12))
			draw_circle(ra + Vector2( 7*sc, -15*sc), 2.8*sc, Color(0.50, 0.35, 0.12))
		1:  # Shouter – Mikrofon (rechte Hand)
			draw_rect(Rect2(ra.x - 2*sc, ra.y - 15*sc, 4*sc, 13*sc), Color(0.35, 0.34, 0.42))
			draw_circle(ra + Vector2(0, -15*sc), 5*sc, Color(0.55, 0.54, 0.62))
			draw_circle(ra + Vector2(0, -15*sc), 3*sc, Color(0.30, 0.29, 0.36))
			var mpts = PackedVector2Array()
			for i in range(5):
				mpts.append(Vector2(
					ra.x + float(i) * 2.2*sc + sin(float(i) * 1.1 + t) * 2.5*sc,
					ra.y + float(i) * 3.5*sc))
			draw_polyline(mpts, Color(0.18, 0.18, 0.22, 0.75), 1.8)
		2:  # Dreads – Gitarre (linke Hand)
			var gx = la.x + 3*sc
			var gy = la.y - 4*sc
			draw_circle(Vector2(gx, gy), 8*sc, Color(0.62, 0.28, 0.08))
			draw_circle(Vector2(gx, gy - 6*sc), 5.5*sc, Color(0.62, 0.28, 0.08))
			draw_rect(Rect2(gx - 2*sc, gy - 24*sc, 4*sc, 19*sc), Color(0.45, 0.24, 0.08))
			for s in range(3):
				draw_line(
					Vector2(gx - 1.5*sc + float(s) * 1.5*sc, gy - 23*sc),
					Vector2(gx - 1.5*sc + float(s) * 1.5*sc, gy - 2*sc),
					Color(0.75, 0.75, 0.78, 0.65), 0.9)
		3:  # Riff Slicer – Flying-V-Gitarre (rechte Hand)
			var gx = ra.x + 1*sc
			var gy = ra.y - 9*sc
			draw_colored_polygon(PackedVector2Array([
				Vector2(gx, gy),
				Vector2(gx - 15*sc, gy + 12*sc),
				Vector2(gx - 11*sc, gy + 12*sc),
				Vector2(gx, gy + 5*sc),
			]), Color(0.88, 0.15, 0.10))
			draw_colored_polygon(PackedVector2Array([
				Vector2(gx, gy),
				Vector2(gx + 15*sc, gy + 12*sc),
				Vector2(gx + 11*sc, gy + 12*sc),
				Vector2(gx, gy + 5*sc),
			]), Color(0.88, 0.15, 0.10))
			draw_rect(Rect2(gx - 1.5*sc, gy - 18*sc, 3*sc, 18*sc), Color(0.50, 0.22, 0.06))
			for s in range(4):
				draw_line(
					Vector2(gx - 1*sc + float(s) * 0.9*sc, gy - 17*sc),
					Vector2(gx - 1*sc + float(s) * 0.9*sc, gy - 1*sc),
					Color(0.8, 0.8, 0.8, 0.6), 0.7)
		4:  # Distortion – Keyboard horizontal
			var kx = cx - 16*sc
			var ky = arm_y + 5*sc
			draw_rect(Rect2(kx, ky, 32*sc, 9*sc), Color(0.12, 0.10, 0.18))
			for k in range(6):
				draw_rect(Rect2(kx + 2*sc + float(k) * 5*sc, ky + 1*sc, 4.2*sc, 5.5*sc), Color(0.92, 0.92, 0.96))
			for k in range(5):
				draw_rect(Rect2(kx + 5*sc + float(k) * 5*sc, ky + 1*sc, 2.5*sc, 3.5*sc), Color(0.12, 0.12, 0.15))
		5:  # Bassist – E-Bass (linke Hand)
			var gx = la.x + 2*sc
			var gy = la.y - 5*sc
			var bpts = PackedVector2Array()
			for i in range(6):
				var a = float(i) * TAU / 6.0
				bpts.append(Vector2(gx + cos(a) * 8*sc, gy + sin(a) * 7*sc))
			draw_colored_polygon(bpts, Color(0.12, 0.16, 0.58))
			draw_circle(Vector2(gx, gy - 5.5*sc), 5*sc, Color(0.12, 0.16, 0.58))
			draw_rect(Rect2(gx - 2*sc, gy - 24*sc, 4*sc, 18*sc), Color(0.28, 0.20, 0.06))
			for s in range(4):
				draw_line(
					Vector2(gx - 1.5*sc + float(s) * 1.1*sc, gy - 23*sc),
					Vector2(gx - 1.5*sc + float(s) * 1.1*sc, gy - 5*sc),
					Color(0.72, 0.72, 0.74, 0.6), 0.8)

# ── Krebse am Strand ───────────────────────────────────────────────────────────
func _draw_crabs(w: float, h: float, t: float) -> void:
	var beach_top = h * 0.76
	# [start_frac, speed_px_s, size, y_offset, phase]
	var crabs = [
		[0.08,  30.0,  9.0, 22.0, 0.0],
		[0.50, -22.0,  7.0, 44.0, 1.4],
		[0.72,  26.0, 11.0, 18.0, 2.8],
		[0.28, -36.0,  6.5, 58.0, 0.7],
		[0.88,  18.0,  8.0, 36.0, 3.5],
	]
	for cr in crabs:
		var cx = fmod(cr[0] * w + t * cr[1] + w * 60.0, w)
		var cy = beach_top + cr[3]
		var sz = cr[2]
		var dir = sign(cr[1])
		var walk = sin(t * 7.5 + cr[4])
		_draw_one_crab(cx, cy, sz, dir, walk)

func _draw_one_crab(cx: float, cy: float, sz: float, dir: float, walk: float) -> void:
	var shell = Color(0.90, 0.38, 0.10)
	var dark  = Color(0.62, 0.20, 0.06)
	# Beine (4 Paare, hinter Körper)
	for i in range(4):
		var lx = cx - sz * 0.9 + float(i) * sz * 0.62
		var phase = walk * (1.0 if i % 2 == 0 else -1.0)
		draw_line(
			Vector2(lx, cy + sz * 0.4),
			Vector2(lx + phase * sz * 0.55, cy + sz * 1.55),
			dark, max(1.0, sz * 0.22))
	# Körper (abgeplattete Ellipse)
	var body_pts = PackedVector2Array()
	for i in range(12):
		var a = float(i) * TAU / 12.0
		body_pts.append(Vector2(cx + cos(a) * sz * 1.35, cy + sin(a) * sz * 0.82))
	draw_colored_polygon(body_pts, shell)
	# Muster auf Schale
	draw_arc(Vector2(cx, cy), sz * 0.6, 0, TAU, 8, dark.lightened(0.1), max(0.8, sz * 0.15))
	draw_arc(Vector2(cx, cy), sz * 1.0, 0, TAU, 10, dark.lightened(0.05), max(0.6, sz * 0.12))
	# Große Schere (Laufrichtung)
	var scx = cx + dir * sz * 1.6
	var scy = cy - sz * 0.15
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + dir * sz * 0.85, cy - sz * 0.1),
		Vector2(scx,                  scy - sz * 0.65),
		Vector2(scx + dir * sz * 0.7, scy - sz * 0.30),
		Vector2(scx + dir * sz * 0.15,scy + sz * 0.28),
	]), dark)
	# Scherenöffnung (animiert)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + dir * sz * 0.85, cy - sz * 0.1),
		Vector2(scx + dir * sz * 0.12, scy - sz * 0.50 + walk * sz * 0.22),
		Vector2(scx + dir * sz * 0.62, scy - sz * 0.28),
		Vector2(scx + dir * sz * 0.10, scy + sz * 0.22),
	]), shell.lightened(0.12))
	# Augenstiele + Augen
	for ei in range(2):
		var ex = cx + dir * sz * (0.60 - float(ei) * 0.38)
		draw_line(Vector2(ex, cy - sz * 0.55), Vector2(ex, cy - sz * 0.98), dark, max(0.8, sz * 0.17))
		draw_circle(Vector2(ex, cy - sz * 1.0), sz * 0.26, dark)
		draw_circle(Vector2(ex, cy - sz * 1.0), sz * 0.13, Color(0.02, 0.02, 0.02))

func _draw_char_hair(cid: int, cx: float, hy: float, hr: float, sc: float, t: float, col: Color) -> void:
	match cid:
		0:  # Manni – rotes Schweißband + kurze Haare
			draw_rect(Rect2(cx - hr * 0.95, hy - hr * 0.15, hr * 1.9, 3.5*sc), Color(0.88, 0.18, 0.18))
			for i in range(5):
				var a = -PI * 0.9 + float(i) * PI * 0.45
				draw_line(
					Vector2(cx + cos(a) * hr * 0.85, hy + sin(a) * hr * 0.85),
					Vector2(cx + cos(a) * (hr + 4*sc), hy + sin(a) * (hr + 4*sc)),
					Color(0.15, 0.10, 0.06), 1.8 * sc)
		1:  # Shouter – rote Stachelhaare (animiert)
			for i in range(8):
				var a = -PI * 0.88 + float(i) * PI * 0.25
				var flair = sin(t * 2.5 + float(i) * 0.7) * 1.5 * sc
				draw_line(
					Vector2(cx + cos(a) * hr * 0.88, hy + sin(a) * hr * 0.88),
					Vector2(cx + cos(a) * (hr + 9*sc) + flair, hy + sin(a) * (hr + 9*sc)),
					Color(0.88, 0.08, 0.08), 2.2 * sc)
		2:  # Dreads – schwingende Dreadlocks
			for i in range(9):
				var a = -PI + float(i) * PI / 8.0
				var sway = sin(t * 0.9 + float(i) * 0.65) * 3.5 * sc
				var root = Vector2(cx + cos(a) * hr * 0.80, hy + sin(a) * hr * 0.80)
				var tip  = Vector2(cx + cos(a) * (hr + 17*sc) + sway, hy + sin(a) * (hr + 14*sc) + 6*sc)
				draw_line(root, tip, Color(0.40, 0.28, 0.12), 2.8 * sc)
				draw_circle(tip, 2.2 * sc, Color(0.48, 0.32, 0.14))
		3:  # Riff Slicer – wilde orangefarbene Haare
			for i in range(7):
				var a = -PI * 0.92 + float(i) * PI * 0.31
				var flair = sin(t * 2.4 + float(i) * 0.85) * 3.5 * sc
				draw_line(
					Vector2(cx + cos(a) * hr, hy + sin(a) * hr),
					Vector2(cx + cos(a) * (hr + 11*sc) + flair, hy + sin(a) * (hr + 11*sc) - 2*sc),
					Color(0.95, 0.58, 0.06), 2.5 * sc)
		4:  # Distortion – lila Haare + Schutzbrille
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - hr * 0.95, hy - hr * 0.22),
				Vector2(cx - hr * 0.80, hy - hr * 1.05),
				Vector2(cx + hr * 0.80, hy - hr * 1.05),
				Vector2(cx + hr * 0.95, hy - hr * 0.22),
			]), Color(0.52, 0.15, 0.85))
			draw_rect(Rect2(cx - 7.5*sc, hy - 2.5*sc, 6.0*sc, 4.5*sc), Color(0.48, 0.82, 0.92, 0.82))
			draw_rect(Rect2(cx + 1.5*sc,  hy - 2.5*sc, 6.0*sc, 4.5*sc), Color(0.48, 0.82, 0.92, 0.82))
			draw_line(Vector2(cx - 1.5*sc, hy - 1.5*sc), Vector2(cx + 1.5*sc, hy - 1.5*sc), Color(0.35, 0.35, 0.45), 1.5)
		5:  # Bassist – gelbes Stirnband + dunkles langes Haar
			for i in range(6):
				var a = -PI + float(i) * PI / 5.0
				var root = Vector2(cx + cos(a) * hr * 0.82, hy + sin(a) * hr * 0.82)
				var tip  = Vector2(cx + cos(a) * (hr + 13*sc), hy + sin(a) * (hr + 13*sc) + 5*sc)
				draw_line(root, tip, Color(0.15, 0.10, 0.06), 2.8 * sc)
			draw_rect(Rect2(cx - hr * 0.92, hy - hr * 0.12, hr * 1.84, 4.0*sc), Color(0.85, 0.62, 0.08))
