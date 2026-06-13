extends Control

const BASE_CHARACTERS = ["manni", "shouter", "dreads", "riff_slicer", "distortion", "bassist"]
const CHAR_ROLES = {
	"manni": "DRUMMER", "shouter": "GROWLER", "dreads": "SCREAMER",
	"riff_slicer": "LEAD GUITAR", "distortion": "RHYTHM GUITAR", "bassist": "BASS",
	"pimmel": "MERCH", "theo": "STAGEHAND", "toxo": "MUTANT",
}
# Anzeigenamen der Signature-Waffen (freischaltbar durch Sieg auf Drink Fight Die!)
const SIGNATURE_NAMES = {
	"manni": "Blast Beat Barrage", "shouter": "Brown Note", "dreads": "Headbang Cyclone",
	"riff_slicer": "Sweep Picking", "distortion": "Feedback Drone", "bassist": "Standing Wave",
	"pimmel": "Bauchladen Blitz", "theo": "Backline Rig",
}
# Aktive Charakterliste: Band + freigeschaltete Geheimcharaktere (Eastereggs).
# Geheime Charaktere tauchen vor der Freischaltung NICHT auf (auch nicht als ???).
var CHARACTERS: Array = []

func _build_character_list() -> void:
	CHARACTERS = BASE_CHARACTERS.duplicate()
	for sid in GameManager.SECRET_CHARACTERS:
		if SaveManager.is_character_unlocked(sid):
			CHARACTERS.append(sid)
var selected_index: int = 0
var _anim_time: float = 0.0
var _preview_nodes: Array = []
var _char_buttons: Array = []
var _diff_buttons: Array = []
# Waffen-Auswahl: char_id -> bool (true = Signature). Plus Button-Referenz.
var _weapon_choice: Dictionary = {}
var _weapon_btn: Button = null

# Co-op
var _coop_mode: bool = false
var _p2_idx: int = 0  # 0 = Manni (immer freigeschaltet); 1 war der gesperrte Shouter
var _coop_btn = null
var _p2_panel = null

# Netzwerk Co-op
var _net_panel = null
var _net_ip_label = null
var _net_status_label = null
var _net_ip_field = null
var _peer_ready: bool = false

func _ready() -> void:
	_build_character_list()
	_build_ui()
	_update_selection(0)
	GameManager.add_volume_widget(self)

func _process(delta: float) -> void:
	_anim_time += delta
	# Animate preview
	for n in _preview_nodes:
		if is_instance_valid(n):
			n.queue_redraw()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.04, 0.12)
	add_child(bg)

	# Title
	var title = Label.new()
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.position = Vector2(-300, 20)
	title.size = Vector2(600, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = LocalizationManager.t("select_fighter")
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 1.0))
	title.add_theme_font_size_override("font_size", 42)
	add_child(title)

	# Character grid: 3x2 fuer die Band, 4 Spalten sobald Geheimcharaktere
	# freigeschaltet sind (dann werden die Karten etwas schmaler)
	var n_chars: int = CHARACTERS.size()
	var grid_cols: int = 3 if n_chars <= 6 else 4
	var spacing_x: float = 360.0 if grid_cols == 3 else 295.0
	var start_x: float = 100.0 if grid_cols == 3 else 40.0
	var card_w: float = 320.0 if grid_cols == 3 else 285.0
	for i in range(n_chars):
		var char_id = CHARACTERS[i]
		var info = GameManager.CHARACTER_INFO.get(char_id, {})
		var unlocked = SaveManager.is_character_unlocked(char_id)

		var col = i % grid_cols
		var row = i / grid_cols
		var x = start_x + col * spacing_x
		var y = 110.0 + row * 220.0

		# Card background
		var card = Control.new()
		card.position = Vector2(x, y)
		card.size = Vector2(card_w, 200)
		add_child(card)

		var card_bg = ColorRect.new()
		card_bg.set_anchors_preset(PRESET_FULL_RECT)
		card_bg.color = Color(0.1, 0.08, 0.18) if unlocked else Color(0.05, 0.04, 0.08)
		card.add_child(card_bg)

		# Character preview (drawn shape)
		var preview = Control.new()
		preview.name = "Preview_" + char_id
		preview.position = Vector2(20, 5)
		preview.size = Vector2(80, 100)
		var char_color = info.get("color", Color.WHITE)
		preview.draw.connect(_draw_char_preview.bind(preview, char_id, char_color, unlocked))
		card.add_child(preview)
		_preview_nodes.append(preview)

		# Character name
		var name_lbl = Label.new()
		name_lbl.position = Vector2(110, 14)
		name_lbl.size = Vector2(card_w - 120, 40)
		name_lbl.text = info.get("name", char_id) if unlocked else "???"
		name_lbl.add_theme_color_override("font_color", char_color if unlocked else Color(0.3, 0.3, 0.3))
		name_lbl.add_theme_font_size_override("font_size", 28)
		name_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		name_lbl.add_theme_constant_override("outline_size", 3)
		card.add_child(name_lbl)

		# Instrument role
		var role_lbl = Label.new()
		role_lbl.position = Vector2(110, 54)
		role_lbl.size = Vector2(card_w - 120, 22)
		role_lbl.text = CHAR_ROLES.get(char_id, "") if unlocked else ""
		role_lbl.add_theme_color_override("font_color", Color(char_color.r, char_color.g, char_color.b, 0.70))
		role_lbl.add_theme_font_size_override("font_size", 13)
		card.add_child(role_lbl)

		# Description
		var desc_lbl = Label.new()
		desc_lbl.position = Vector2(110, 76)
		desc_lbl.size = Vector2(card_w - 120, 68)
		desc_lbl.text = GameManager.char_desc(char_id) if unlocked else LocalizationManager.t("char_unlock_hint") % [_unlock_wave(char_id)]
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9) if unlocked else Color(0.4, 0.4, 0.4))
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		card.add_child(desc_lbl)

		# Select button
		var btn = Button.new()
		btn.position = Vector2(20, 155)
		btn.size = Vector2(card_w - 40, 35)
		btn.text = LocalizationManager.t("char_select") if unlocked else LocalizationManager.t("char_locked")
		btn.disabled = not unlocked
		var idx = i
		btn.pressed.connect(func(): _update_selection(idx))
		card.add_child(btn)
		_char_buttons.append(btn)

		# Selection indicator (border)
		var border = ColorRect.new()
		border.name = "Border_" + str(i)
		border.set_anchors_preset(PRESET_FULL_RECT)
		border.color = Color(0, 0, 0, 0)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(border)

	# ── Schwierigkeitsgrad-Auswahl ───────────────────────────────────────────
	var diff_title = Label.new()
	diff_title.position = Vector2(40, 548)
	diff_title.size = Vector2(300, 26)
	diff_title.text = LocalizationManager.t("difficulty_lbl")
	diff_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	diff_title.add_theme_font_size_override("font_size", 16)
	add_child(diff_title)

	for d in range(5):
		var col  = GameManager.DIFFICULTY_COLORS[d]
		var dbtn = Button.new()
		dbtn.position = Vector2(40.0 + d * 242.0, 574)
		dbtn.size = Vector2(232, 50)
		dbtn.text = GameManager.DIFFICULTY_NAMES[d]
		dbtn.add_theme_font_size_override("font_size", 14)
		var sty = StyleBoxFlat.new()
		sty.set_corner_radius_all(6)
		sty.bg_color = col.darkened(0.55)
		sty.border_color = col
		sty.set_border_width_all(2)
		dbtn.add_theme_stylebox_override("normal", sty)
		var sty_hover = StyleBoxFlat.new()
		sty_hover.set_corner_radius_all(6)
		sty_hover.bg_color = col.darkened(0.25)
		sty_hover.border_color = col.lightened(0.3)
		sty_hover.set_border_width_all(3)
		dbtn.add_theme_stylebox_override("hover", sty_hover)
		var idx = d
		dbtn.pressed.connect(func(): _select_difficulty(idx))
		add_child(dbtn)
		_diff_buttons.append(dbtn)

	_update_diff_visuals()

	# Play button
	var play_btn = Button.new()
	play_btn.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	play_btn.anchor_left = 1.0
	play_btn.anchor_right = 1.0
	play_btn.anchor_top = 1.0
	play_btn.anchor_bottom = 1.0
	play_btn.position = Vector2(-280, -70)
	play_btn.size = Vector2(260, 55)
	play_btn.text = LocalizationManager.t("lets_play")
	play_btn.add_theme_font_size_override("font_size", 26)
	var play_style = StyleBoxFlat.new()
	play_style.bg_color = Color(0.1, 0.6, 0.15)
	play_style.border_color = Color(0.3, 1.0, 0.4)
	play_style.set_border_width_all(2)
	play_style.set_corner_radius_all(8)
	play_btn.add_theme_stylebox_override("normal", play_style)
	play_btn.pressed.connect(_on_play_pressed)
	add_child(play_btn)
	play_btn.call_deferred("grab_focus")

	# ── Waffen-Auswahl (ueber dem Play-Button) ───────────────────────────────
	# Standard- vs Signature-Waffe fuer den gewaehlten Charakter. Gesperrt bis
	# der Charakter den Story-Mode auf Drink Fight Die! (oder hoeher) schafft.
	_weapon_btn = Button.new()
	_weapon_btn.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	_weapon_btn.anchor_left = 1.0
	_weapon_btn.anchor_right = 1.0
	_weapon_btn.anchor_top = 1.0
	_weapon_btn.anchor_bottom = 1.0
	_weapon_btn.position = Vector2(-280, -132)
	_weapon_btn.size = Vector2(260, 48)
	_weapon_btn.add_theme_font_size_override("font_size", 16)
	var wstyle = StyleBoxFlat.new()
	wstyle.bg_color = Color(0.22, 0.10, 0.34)
	wstyle.border_color = Color(0.70, 0.45, 1.0)
	wstyle.set_border_width_all(2)
	wstyle.set_corner_radius_all(8)
	_weapon_btn.add_theme_stylebox_override("normal", wstyle)
	_weapon_btn.pressed.connect(_toggle_weapon)
	add_child(_weapon_btn)

	# Back button
	var back_btn = Button.new()
	back_btn.set_anchors_preset(PRESET_BOTTOM_LEFT)
	back_btn.anchor_top = 1.0
	back_btn.anchor_bottom = 1.0
	back_btn.position = Vector2(20, -70)
	back_btn.size = Vector2(140, 55)
	back_btn.text = LocalizationManager.t("back")
	back_btn.add_theme_font_size_override("font_size", 22)
	back_btn.pressed.connect(GameManager.go_to_main_menu)
	add_child(back_btn)

	# ── 2-Spieler-Toggle (Mitte unten) ───────────────────────────────────────
	_coop_btn = Button.new()
	_coop_btn.set_anchors_preset(PRESET_BOTTOM_LEFT)
	_coop_btn.anchor_left  = 0.5
	_coop_btn.anchor_right = 0.5
	_coop_btn.anchor_top   = 1.0
	_coop_btn.anchor_bottom = 1.0
	_coop_btn.offset_left   = -110
	_coop_btn.offset_right  = 110
	_coop_btn.offset_top    = -70
	_coop_btn.offset_bottom = -15
	_coop_btn.text = "👤 SOLO"
	_coop_btn.add_theme_font_size_override("font_size", 16)
	_coop_btn.pressed.connect(_toggle_coop)
	add_child(_coop_btn)
	_update_coop_btn_style()

	# ── P2-Charakter-Auswahl (erscheint im Co-op-Modus) ──────────────────────
	_p2_panel = Control.new()
	_p2_panel.set_anchors_preset(PRESET_BOTTOM_LEFT)
	_p2_panel.anchor_left   = 0.5
	_p2_panel.anchor_right  = 0.5
	_p2_panel.anchor_top    = 1.0
	_p2_panel.anchor_bottom = 1.0
	_p2_panel.offset_left   = -260
	_p2_panel.offset_right  = 260
	_p2_panel.offset_top    = -130
	_p2_panel.offset_bottom = -80
	_p2_panel.visible = false
	add_child(_p2_panel)

	var p2_bg = ColorRect.new()
	p2_bg.set_anchors_preset(PRESET_FULL_RECT)
	p2_bg.color = Color(0.08, 0.06, 0.16, 0.95)
	_p2_panel.add_child(p2_bg)

	var p2_lbl = Label.new()
	p2_lbl.position = Vector2(8, 8)
	p2_lbl.size = Vector2(120, 34)
	p2_lbl.text = LocalizationManager.t("p2_label")
	p2_lbl.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0))
	p2_lbl.add_theme_font_size_override("font_size", 14)
	p2_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_p2_panel.add_child(p2_lbl)

	var prev_btn = Button.new()
	prev_btn.position = Vector2(128, 5)
	prev_btn.size = Vector2(36, 40)
	prev_btn.text = "<"
	prev_btn.add_theme_font_size_override("font_size", 18)
	prev_btn.pressed.connect(_p2_prev)
	_p2_panel.add_child(prev_btn)

	var p2_name_lbl = Label.new()
	p2_name_lbl.name = "P2NameLabel"
	p2_name_lbl.position = Vector2(170, 5)
	p2_name_lbl.size = Vector2(140, 40)
	p2_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p2_name_lbl.add_theme_font_size_override("font_size", 16)
	_p2_panel.add_child(p2_name_lbl)

	var next_btn = Button.new()
	next_btn.position = Vector2(316, 5)
	next_btn.size = Vector2(36, 40)
	next_btn.text = ">"
	next_btn.add_theme_font_size_override("font_size", 18)
	next_btn.pressed.connect(_p2_next)
	_p2_panel.add_child(next_btn)

	_update_p2_display()

func _draw_char_preview(canvas: Control, char_id: String, _color: Color, unlocked: bool) -> void:
	var c = canvas.size / 2.0
	var t = _anim_time
	var bob = sin(t * 5.0) * 1.2
	if not unlocked:
		canvas.draw_circle(c, 30, Color(0.15, 0.15, 0.15))
		canvas.draw_string(ThemeDB.fallback_font, c + Vector2(-8, 6), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(0.4,0.4,0.4))
		return
	match char_id:
		"manni":
			var skin  = Color(0.98, 0.82, 0.66)
			var ov    = Color(0.18, 0.28, 0.55)
			var beanie = Color(0.82, 0.72, 0.52)
			var beard = Color(0.30, 0.18, 0.08)
			var stick = Color(0.68, 0.48, 0.22)
			# Schuhe
			canvas.draw_rect(Rect2(c+Vector2(-12,24+bob), Vector2(11,4)), Color(0.12,0.08,0.04))
			canvas.draw_rect(Rect2(c+Vector2(-1,24+bob),  Vector2(11,4)), Color(0.12,0.08,0.04))
			# Beine
			canvas.draw_rect(Rect2(c+Vector2(-10,12+bob), Vector2(8,13)), ov)
			canvas.draw_rect(Rect2(c+Vector2(2,12+bob),   Vector2(8,13)), ov)
			# Torso (Latzhose)
			canvas.draw_rect(Rect2(c+Vector2(-11,-6+bob), Vector2(22,19)), ov)
			# Träger
			canvas.draw_line(c+Vector2(-7,-6+bob),  c+Vector2(-3,-19+bob), Color(0.38,0.50,0.80), 2.5)
			canvas.draw_line(c+Vector2(7,-6+bob),   c+Vector2(3,-19+bob),  Color(0.38,0.50,0.80), 2.5)
			# Arme
			canvas.draw_rect(Rect2(c+Vector2(-18,-1+bob), Vector2(7,11)), ov)
			canvas.draw_rect(Rect2(c+Vector2(11,-1+bob),  Vector2(7,11)), ov)
			# Hände
			canvas.draw_circle(c+Vector2(-17,9+bob), 5, skin)
			canvas.draw_circle(c+Vector2(17,9+bob),  5, skin)
			# Trommelstöcke
			canvas.draw_line(c+Vector2(-15,9+bob),  c+Vector2(-23,20+bob), stick, 2.5)
			canvas.draw_circle(c+Vector2(-23,20+bob), 3, stick)
			canvas.draw_line(c+Vector2(18,9+bob),   c+Vector2(26,20+bob),  stick, 2.5)
			canvas.draw_circle(c+Vector2(26,20+bob),  3, stick)
			# Kopf (groß, South Park)
			canvas.draw_circle(c+Vector2(0,-22+bob), 14, skin)
			# Beanie-Mütze
			var bp = PackedVector2Array([
				c+Vector2(-14,-24+bob), c+Vector2(-11,-32+bob),
				c+Vector2(-5,-38+bob),  c+Vector2(0,-40+bob),
				c+Vector2(5,-38+bob),   c+Vector2(11,-32+bob),
				c+Vector2(14,-24+bob)
			])
			canvas.draw_colored_polygon(bp, beanie)
			canvas.draw_line(c+Vector2(-14,-24+bob), c+Vector2(14,-24+bob), beanie.darkened(0.3), 2.5)
			# Vollbart
			var bpts = PackedVector2Array([
				c+Vector2(-12,-16+bob), c+Vector2(-14,-9+bob),
				c+Vector2(-9,-5+bob),   c+Vector2(0,-3+bob),
				c+Vector2(9,-5+bob),    c+Vector2(14,-9+bob),
				c+Vector2(12,-16+bob)
			])
			canvas.draw_colored_polygon(bpts, beard)
			# Augenbrauen (SP: dick, zusammenlaufend)
			canvas.draw_line(c+Vector2(-11,-28+bob), c+Vector2(-2,-26+bob), beard, 2.5)
			canvas.draw_line(c+Vector2(2,-26+bob),   c+Vector2(11,-28+bob), beard, 2.5)
			# Augen
			canvas.draw_circle(c+Vector2(-5,-24+bob), 3.5, Color(0.95,0.95,0.95))
			canvas.draw_circle(c+Vector2(5,-24+bob),  3.5, Color(0.95,0.95,0.95))
			canvas.draw_circle(c+Vector2(-5,-24+bob), 1.8, Color(0.05,0.05,0.05))
			canvas.draw_circle(c+Vector2(5,-24+bob),  1.8, Color(0.05,0.05,0.05))
		"shouter":
			var skin   = Color(0.98, 0.82, 0.66)
			var flannel = Color(0.58, 0.22, 0.12)
			var f_dark  = Color(0.08, 0.04, 0.04)
			var denim  = Color(0.28, 0.38, 0.58)
			var beard  = Color(0.32, 0.22, 0.10)
			var gold   = Color(0.92, 0.80, 0.22)
			# Schuhe
			canvas.draw_rect(Rect2(c+Vector2(-12,24+bob), Vector2(11,4)), Color(0.12,0.08,0.04))
			canvas.draw_rect(Rect2(c+Vector2(-1,24+bob),  Vector2(11,4)), Color(0.12,0.08,0.04))
			# Beine (Jeans)
			canvas.draw_rect(Rect2(c+Vector2(-10,12+bob), Vector2(8,13)), denim)
			canvas.draw_rect(Rect2(c+Vector2(2,12+bob),   Vector2(8,13)), denim)
			# Flanellhemd (rot-schwarz kariert)
			canvas.draw_rect(Rect2(c+Vector2(-11,-6+bob), Vector2(22,18)), flannel)
			for yo in [-4, 1, 6, 11]:
				canvas.draw_line(c+Vector2(-11,yo+bob), c+Vector2(11,yo+bob), f_dark, 1.0)
			for xo in [-7, -2, 3, 8]:
				canvas.draw_line(c+Vector2(xo,-6+bob), c+Vector2(xo,12+bob), f_dark, 1.0)
			# Arme
			canvas.draw_rect(Rect2(c+Vector2(-18,-1+bob), Vector2(7,11)), flannel)
			canvas.draw_rect(Rect2(c+Vector2(11,-1+bob),  Vector2(7,11)), flannel)
			canvas.draw_circle(c+Vector2(-17,9+bob), 5, skin)
			canvas.draw_circle(c+Vector2(17,9+bob),  5, skin)
			# Lange goldene Haare (animiert)
			for j in range(12):
				var hx = -13.0 + float(j) * 2.4
				var sw = sin(t * 1.6 + float(j) * 0.65) * 5.0
				var hpts = PackedVector2Array()
				for step in range(7):
					var s = float(step) / 6.0
					hpts.append(c+Vector2(hx + sw * s * s, -38.0 + bob + s * 80.0))
				canvas.draw_polyline(hpts, gold, 3.0)
			# Kopf
			canvas.draw_circle(c+Vector2(0,-22+bob), 14, skin)
			# Großer Vollbart
			var bpts = PackedVector2Array([
				c+Vector2(-12,-16+bob), c+Vector2(-14,-9+bob),
				c+Vector2(-9,-4+bob),   c+Vector2(0,-2+bob),
				c+Vector2(9,-4+bob),    c+Vector2(14,-9+bob),
				c+Vector2(12,-16+bob)
			])
			canvas.draw_colored_polygon(bpts, beard)
			# Schrei-Mund (weit offen)
			canvas.draw_arc(c+Vector2(0,-17+bob), 8, 0.08, PI-0.08, 8, Color(0.05,0.02,0.02), 13)
			# Augenbrauen
			canvas.draw_line(c+Vector2(-11,-28+bob), c+Vector2(-2,-26+bob), beard, 2.5)
			canvas.draw_line(c+Vector2(2,-26+bob),   c+Vector2(11,-28+bob), beard, 2.5)
			# Augen
			canvas.draw_circle(c+Vector2(-5,-24+bob), 3.5, Color(0.95,0.95,0.95))
			canvas.draw_circle(c+Vector2(5,-24+bob),  3.5, Color(0.95,0.95,0.95))
			canvas.draw_circle(c+Vector2(-5,-24+bob), 1.8, Color(0.05,0.05,0.05))
			canvas.draw_circle(c+Vector2(5,-24+bob),  1.8, Color(0.05,0.05,0.05))
		"dreads":
			var skin  = Color(0.72, 0.52, 0.36)
			var dread = Color(0.32, 0.20, 0.08)
			var tank  = Color(0.60, 0.52, 0.38)
			var suspender = Color(0.55, 0.38, 0.18)
			var denim = Color(0.28, 0.38, 0.58)
			# Schuhe
			canvas.draw_rect(Rect2(c+Vector2(-12,24+bob), Vector2(11,4)), Color(0.12,0.08,0.04))
			canvas.draw_rect(Rect2(c+Vector2(-1,24+bob),  Vector2(11,4)), Color(0.12,0.08,0.04))
			# Beine
			canvas.draw_rect(Rect2(c+Vector2(-10,12+bob), Vector2(8,13)), denim)
			canvas.draw_rect(Rect2(c+Vector2(2,12+bob),   Vector2(8,13)), denim)
			# Tank-Top
			canvas.draw_rect(Rect2(c+Vector2(-10,-6+bob), Vector2(20,18)), tank)
			# Hosenträger
			canvas.draw_line(c+Vector2(-6,12+bob), c+Vector2(-3,-6+bob), suspender, 2.5)
			canvas.draw_line(c+Vector2(6,12+bob),  c+Vector2(3,-6+bob),  suspender, 2.5)
			# Arme (Haut)
			canvas.draw_rect(Rect2(c+Vector2(-17,-1+bob), Vector2(7,11)), skin)
			canvas.draw_rect(Rect2(c+Vector2(10,-1+bob),  Vector2(7,11)), skin)
			canvas.draw_circle(c+Vector2(-16,9+bob), 5, skin)
			canvas.draw_circle(c+Vector2(16,9+bob),  5, skin)
			# Dreadlocks (braun, lang, animiert – HINTER Kopf zeichnen)
			for j in range(10):
				var sx = -13.0 + float(j) * 2.9
				var sw = sin(t * 1.5 + float(j) * 0.8) * 4.0
				var pts = PackedVector2Array()
				for step in range(7):
					var s = float(step) / 6.0
					pts.append(c+Vector2(sx + sw * s, -20.0 + bob + s * 55.0))
				if pts.size() > 1:
					canvas.draw_polyline(pts, dread, 4.0)
				canvas.draw_circle(pts[-1], 2.5, dread.darkened(0.2))
			# Kopf (nach Dreads, damit er drüber liegt)
			canvas.draw_circle(c+Vector2(0,-22+bob), 14, skin)
			# Kurzer Bart
			canvas.draw_arc(c+Vector2(0,-16+bob), 7, 0.15, PI-0.15, 8, dread, 2.5)
			# Augenbrauen
			canvas.draw_line(c+Vector2(-10,-27+bob), c+Vector2(-2,-25+bob), dread, 2.5)
			canvas.draw_line(c+Vector2(2,-25+bob),   c+Vector2(10,-27+bob), dread, 2.5)
			# Augen
			canvas.draw_circle(c+Vector2(-5,-23+bob), 3.2, Color(0.95,0.95,0.95))
			canvas.draw_circle(c+Vector2(5,-23+bob),  3.2, Color(0.95,0.95,0.95))
			canvas.draw_circle(c+Vector2(-5,-23+bob), 1.6, Color(0.05,0.05,0.05))
			canvas.draw_circle(c+Vector2(5,-23+bob),  1.6, Color(0.05,0.05,0.05))
		"riff_slicer":
			var skin  = Color(0.98, 0.82, 0.66)
			var tank  = Color(0.95, 0.92, 0.88)
			var pants = Color(0.22, 0.26, 0.40)
			var suspender = Color(0.32, 0.18, 0.06)
			var straw = Color(0.82, 0.72, 0.40)
			var beard = Color(0.32, 0.20, 0.10)
			# Schuhe
			canvas.draw_rect(Rect2(c+Vector2(-12,24+bob), Vector2(11,4)), Color(0.12,0.08,0.04))
			canvas.draw_rect(Rect2(c+Vector2(-1,24+bob),  Vector2(11,4)), Color(0.12,0.08,0.04))
			# Beine (Jeans)
			canvas.draw_rect(Rect2(c+Vector2(-10,12+bob), Vector2(8,13)), pants)
			canvas.draw_rect(Rect2(c+Vector2(2,12+bob),   Vector2(8,13)), pants)
			# Tank-Top
			canvas.draw_rect(Rect2(c+Vector2(-10,-6+bob), Vector2(20,18)), tank)
			# Hosenträger
			canvas.draw_line(c+Vector2(-6,12+bob), c+Vector2(-3,-6+bob), suspender, 2.5)
			canvas.draw_line(c+Vector2(6,12+bob),  c+Vector2(3,-6+bob),  suspender, 2.5)
			# Arme (Haut – Tank-Top)
			canvas.draw_rect(Rect2(c+Vector2(-17,-1+bob), Vector2(7,11)), skin)
			canvas.draw_rect(Rect2(c+Vector2(10,-1+bob),  Vector2(7,11)), skin)
			canvas.draw_circle(c+Vector2(-16,9+bob), 5, skin)
			canvas.draw_circle(c+Vector2(16,9+bob),  5, skin)
			# Kopf
			canvas.draw_circle(c+Vector2(0,-22+bob), 14, skin)
			# Strohhut (sehr breit)
			canvas.draw_rect(Rect2(c+Vector2(-20,-31+bob), Vector2(40,5)), straw)  # Krempe
			canvas.draw_rect(Rect2(c+Vector2(-9,-44+bob),  Vector2(18,14)), straw) # Krone
			canvas.draw_line(c+Vector2(-9,-31+bob), c+Vector2(9,-31+bob), straw.darkened(0.3), 2)
			# Vollbart
			var bpts = PackedVector2Array([
				c+Vector2(-11,-16+bob), c+Vector2(-13,-9+bob),
				c+Vector2(-8,-4+bob),   c+Vector2(0,-2+bob),
				c+Vector2(8,-4+bob),    c+Vector2(13,-9+bob),
				c+Vector2(11,-16+bob)
			])
			canvas.draw_colored_polygon(bpts, beard)
			# Augenbrauen
			canvas.draw_line(c+Vector2(-10,-27+bob), c+Vector2(-2,-25+bob), beard, 2.5)
			canvas.draw_line(c+Vector2(2,-25+bob),   c+Vector2(10,-27+bob), beard, 2.5)
			# Augen
			canvas.draw_circle(c+Vector2(-5,-23+bob), 3.2, Color(0.95,0.95,0.95))
			canvas.draw_circle(c+Vector2(5,-23+bob),  3.2, Color(0.95,0.95,0.95))
			canvas.draw_circle(c+Vector2(-5,-23+bob), 1.6, Color(0.05,0.05,0.05))
			canvas.draw_circle(c+Vector2(5,-23+bob),  1.6, Color(0.05,0.05,0.05))
		"distortion":
			var skin    = Color(0.96, 0.80, 0.64)
			var overall = Color(0.22, 0.38, 0.68)
			var ov_dark = Color(0.16, 0.28, 0.52)
			var green   = Color(0.22, 0.55, 0.22)
			var g_dark  = Color(0.14, 0.38, 0.14)
			var beard   = Color(0.28, 0.18, 0.10)
			var hair    = Color(0.22, 0.18, 0.12)
			# Schuhe
			canvas.draw_rect(Rect2(c+Vector2(-12,24+bob), Vector2(11,4)), Color(0.12,0.08,0.04))
			canvas.draw_rect(Rect2(c+Vector2(-1,24+bob),  Vector2(11,4)), Color(0.12,0.08,0.04))
			# Beine (Latzhose denim)
			canvas.draw_rect(Rect2(c+Vector2(-10,12+bob), Vector2(8,13)), overall)
			canvas.draw_rect(Rect2(c+Vector2(2,12+bob),   Vector2(8,13)), overall)
			# Arme (grünes Karohemd)
			canvas.draw_rect(Rect2(c+Vector2(-17,-1+bob), Vector2(7,11)), green)
			for yo in [-1, 4, 8]:
				canvas.draw_line(c+Vector2(-17,yo+bob), c+Vector2(-10,yo+bob), g_dark, 1.0)
			canvas.draw_rect(Rect2(c+Vector2(10,-1+bob),  Vector2(7,11)), green)
			for yo in [-1, 4, 8]:
				canvas.draw_line(c+Vector2(10,yo+bob), c+Vector2(17,yo+bob), g_dark, 1.0)
			# Latzhosen-Torso
			canvas.draw_rect(Rect2(c+Vector2(-11,-6+bob), Vector2(22,18)), overall)
			# Träger
			canvas.draw_line(c+Vector2(-7,-6+bob),  c+Vector2(-3,-19+bob), ov_dark, 2.5)
			canvas.draw_line(c+Vector2(7,-6+bob),   c+Vector2(3,-19+bob),  ov_dark, 2.5)
			# Hände
			canvas.draw_circle(c+Vector2(-16,9+bob), 5, skin)
			canvas.draw_circle(c+Vector2(16,9+bob),  5, skin)
			# Kopf
			canvas.draw_circle(c+Vector2(0,-22+bob), 14, skin)
			# Haare (nach oben gestylt)
			canvas.draw_arc(c+Vector2(0,-22+bob), 14, PI, 0, 12, hair, 4)
			for j in range(5):
				var hx = -7.0 + float(j) * 3.5
				canvas.draw_line(c+Vector2(hx,-35+bob), c+Vector2(hx+1,-22+bob), hair, 2.0)
			# Bart
			canvas.draw_arc(c+Vector2(0,-16+bob), 7, 0.1, PI-0.1, 8, beard, 2.5)
			# Augenbrauen
			canvas.draw_line(c+Vector2(-10,-27+bob), c+Vector2(-2,-25+bob), hair, 2.5)
			canvas.draw_line(c+Vector2(2,-25+bob),   c+Vector2(10,-27+bob), hair, 2.5)
			# Augen
			canvas.draw_circle(c+Vector2(-5,-23+bob), 3.2, Color(0.95,0.95,0.95))
			canvas.draw_circle(c+Vector2(5,-23+bob),  3.2, Color(0.95,0.95,0.95))
			canvas.draw_circle(c+Vector2(-5,-23+bob), 1.6, Color(0.05,0.05,0.05))
			canvas.draw_circle(c+Vector2(5,-23+bob),  1.6, Color(0.05,0.05,0.05))
		"bassist":
			var skin   = Color(0.98, 0.82, 0.66)
			var shirt  = Color(0.75, 0.12, 0.10)
			var p_line = Color(0.30, 0.04, 0.03)
			var denim  = Color(0.28, 0.38, 0.58)
			var beard  = Color(0.30, 0.20, 0.10)
			var hat    = Color(0.12, 0.10, 0.14)
			var glass  = Color(0.06, 0.06, 0.08)
			# Schuhe
			canvas.draw_rect(Rect2(c+Vector2(-12,24+bob), Vector2(11,4)), Color(0.12,0.08,0.04))
			canvas.draw_rect(Rect2(c+Vector2(-1,24+bob),  Vector2(11,4)), Color(0.12,0.08,0.04))
			# Beine
			canvas.draw_rect(Rect2(c+Vector2(-10,12+bob), Vector2(8,13)), denim)
			canvas.draw_rect(Rect2(c+Vector2(2,12+bob),   Vector2(8,13)), denim)
			# Rotes Flanellhemd
			canvas.draw_rect(Rect2(c+Vector2(-11,-6+bob), Vector2(22,18)), shirt)
			for yo in [-4, 1, 6, 11]:
				canvas.draw_line(c+Vector2(-11,yo+bob), c+Vector2(11,yo+bob), p_line, 1.0)
			for xo in [-7, -2, 3, 8]:
				canvas.draw_line(c+Vector2(xo,-6+bob), c+Vector2(xo,12+bob), p_line, 1.0)
			# Arme
			canvas.draw_rect(Rect2(c+Vector2(-18,-1+bob), Vector2(7,11)), shirt)
			canvas.draw_rect(Rect2(c+Vector2(11,-1+bob),  Vector2(7,11)), shirt)
			canvas.draw_circle(c+Vector2(-17,9+bob), 5, skin)
			canvas.draw_circle(c+Vector2(17,9+bob),  5, skin)
			# Kopf
			canvas.draw_circle(c+Vector2(0,-22+bob), 14, skin)
			# Breiter dunkler Hut (Wide-Brim)
			canvas.draw_rect(Rect2(c+Vector2(-19,-33+bob), Vector2(38,6)), hat)  # Krempe
			canvas.draw_rect(Rect2(c+Vector2(-9,-46+bob),  Vector2(18,14)), hat) # Krone
			# Kinn-Bart
			canvas.draw_arc(c+Vector2(0,-16+bob), 7, 0.15, PI-0.15, 8, beard, 3)
			# Mund
			canvas.draw_arc(c+Vector2(0,-20+bob), 4, 0.2, PI-0.2, 6, Color(0.12,0.04,0.04), 5)
			# Augenbrauen
			canvas.draw_line(c+Vector2(-10,-27+bob), c+Vector2(-2,-25+bob), beard, 2.0)
			canvas.draw_line(c+Vector2(2,-25+bob),   c+Vector2(10,-27+bob), beard, 2.0)
			# Sonnenbrille
			canvas.draw_circle(c+Vector2(-6,-26+bob), 5.5, glass)
			canvas.draw_circle(c+Vector2(6,-26+bob),  5.5, glass)
			canvas.draw_line(c+Vector2(-0.5,-26+bob), c+Vector2(0.5,-26+bob), glass, 1.5)
			canvas.draw_line(c+Vector2(-11.5,-26+bob), c+Vector2(-11.5,-23+bob), glass, 1.5)
			canvas.draw_line(c+Vector2(11.5,-26+bob),  c+Vector2(11.5,-23+bob),  glass, 1.5)
		"pimmel":
			# Geheimcharakter: Merch-Mann mit Sombrero, Sonnenbrille,
			# Schnauzer, gelbem Hawaiihemd und Becher
			var skin   = Color(0.95, 0.76, 0.58)
			var shirt  = Color(0.97, 0.80, 0.10)
			var hat    = Color(0.93, 0.72, 0.12)
			var tash   = Color(0.42, 0.26, 0.12)
			var glass  = Color(0.05, 0.05, 0.08)
			var cup    = Color(0.15, 0.35, 0.85)
			# Schuhe (Slip-Ons)
			canvas.draw_rect(Rect2(c+Vector2(-12,24+bob), Vector2(11,4)), Color(0.08,0.08,0.08))
			canvas.draw_rect(Rect2(c+Vector2(-1,24+bob),  Vector2(11,4)), Color(0.08,0.08,0.08))
			# Nackte Beine + Shorts
			canvas.draw_rect(Rect2(c+Vector2(-9,16+bob), Vector2(7,9)), skin)
			canvas.draw_rect(Rect2(c+Vector2(2,16+bob),  Vector2(7,9)), skin)
			canvas.draw_rect(Rect2(c+Vector2(-10,9+bob), Vector2(20,8)), Color(0.16,0.18,0.30))
			# Hawaiihemd mit Tupfern
			canvas.draw_rect(Rect2(c+Vector2(-11,-8+bob), Vector2(22,18)), shirt)
			canvas.draw_circle(c+Vector2(-6,-3+bob), 2.0, Color(0.85,0.25,0.15))
			canvas.draw_circle(c+Vector2(6,-5+bob),  1.8, Color(0.95,0.95,0.90))
			canvas.draw_circle(c+Vector2(5,4+bob),   2.0, Color(0.85,0.25,0.15))
			# Arme + Becher
			canvas.draw_rect(Rect2(c+Vector2(-18,-3+bob), Vector2(7,10)), shirt)
			canvas.draw_rect(Rect2(c+Vector2(11,-3+bob),  Vector2(7,10)), shirt)
			canvas.draw_circle(c+Vector2(-17,9+bob), 5, skin)
			canvas.draw_circle(c+Vector2(17,9+bob),  5, skin)
			canvas.draw_rect(Rect2(c+Vector2(14,1+bob), Vector2(8,10)), cup)
			# Kopf + Schnauzer
			canvas.draw_circle(c+Vector2(0,-22+bob), 14, skin)
			canvas.draw_rect(Rect2(c+Vector2(-7,-18+bob), Vector2(14,4)), tash)
			# Sonnenbrille
			canvas.draw_rect(Rect2(c+Vector2(-10,-28+bob), Vector2(8,6)), glass)
			canvas.draw_rect(Rect2(c+Vector2(2,-28+bob),   Vector2(8,6)), glass)
			canvas.draw_line(c+Vector2(-2,-25+bob), c+Vector2(2,-25+bob), glass, 1.5)
			# Sombrero: breite Krempe + Spitzkrone
			canvas.draw_rect(Rect2(c+Vector2(-24,-36+bob), Vector2(48,6)), hat)
			var crown = PackedVector2Array([
				c+Vector2(-9,-36+bob), c+Vector2(9,-36+bob), c+Vector2(0,-52+bob)])
			canvas.draw_colored_polygon(crown, hat)
			canvas.draw_line(c+Vector2(-8,-38+bob), c+Vector2(8,-38+bob), Color(0.65,0.18,0.10), 2.5)
		"theo":
			# Geheimcharakter: Stagehand mit Geheimratsecken, Kinnbart,
			# Flanellhemd und Gaffa-Rolle
			var skin   = Color(0.96, 0.78, 0.62)
			var plaid  = Color(0.60, 0.16, 0.14)
			var plaid2 = Color(0.30, 0.08, 0.10)
			var jeans  = Color(0.25, 0.32, 0.50)
			var hair   = Color(0.62, 0.48, 0.30)
			var beard  = Color(0.55, 0.42, 0.26)
			# Stiefel
			canvas.draw_rect(Rect2(c+Vector2(-12,24+bob), Vector2(11,5)), Color(0.30,0.20,0.10))
			canvas.draw_rect(Rect2(c+Vector2(-1,24+bob),  Vector2(11,5)), Color(0.30,0.20,0.10))
			# Jeans
			canvas.draw_rect(Rect2(c+Vector2(-10,12+bob), Vector2(8,13)), jeans)
			canvas.draw_rect(Rect2(c+Vector2(2,12+bob),   Vector2(8,13)), jeans)
			# Flanellhemd mit Karomuster
			canvas.draw_rect(Rect2(c+Vector2(-11,-7+bob), Vector2(22,19)), plaid)
			for xo in [-6, 0, 6]:
				canvas.draw_line(c+Vector2(xo,-7+bob), c+Vector2(xo,12+bob), plaid2, 1.2)
			for yo in [-3, 3, 9]:
				canvas.draw_line(c+Vector2(-11,yo+bob), c+Vector2(11,yo+bob), plaid2, 1.2)
			# Gaffa-Rolle am Guertel
			canvas.draw_circle(c+Vector2(8,11+bob), 4, Color(0.55,0.55,0.55))
			canvas.draw_circle(c+Vector2(8,11+bob), 1.8, Color(0.12,0.12,0.12))
			# Arme (hochgekrempelt)
			canvas.draw_rect(Rect2(c+Vector2(-18,-2+bob), Vector2(7,6)), plaid)
			canvas.draw_rect(Rect2(c+Vector2(11,-2+bob),  Vector2(7,6)), plaid)
			canvas.draw_rect(Rect2(c+Vector2(-18,4+bob), Vector2(7,5)), skin)
			canvas.draw_rect(Rect2(c+Vector2(11,4+bob),  Vector2(7,5)), skin)
			canvas.draw_circle(c+Vector2(-17,10+bob), 5, skin)
			canvas.draw_circle(c+Vector2(17,10+bob),  5, skin)
			# Kopf
			canvas.draw_circle(c+Vector2(0,-22+bob), 14, skin)
			# Haar mit Geheimratsecken (hohe Stirn frei)
			var hpts = PackedVector2Array([
				c+Vector2(-13,-25+bob), c+Vector2(-11,-32+bob), c+Vector2(-5,-34+bob),
				c+Vector2(0,-32+bob),  c+Vector2(5,-34+bob),  c+Vector2(11,-32+bob),
				c+Vector2(13,-25+bob), c+Vector2(10,-28+bob), c+Vector2(0,-28+bob),
				c+Vector2(-10,-28+bob)])
			canvas.draw_colored_polygon(hpts, hair)
			# Kinnbart + Oberlippenbart
			var gpts = PackedVector2Array([
				c+Vector2(-4,-13+bob), c+Vector2(4,-13+bob),
				c+Vector2(3,-7+bob), c+Vector2(0,-6+bob), c+Vector2(-3,-7+bob)])
			canvas.draw_colored_polygon(gpts, beard)
			canvas.draw_line(c+Vector2(-3,-16+bob), c+Vector2(3,-16+bob), beard, 1.8)
			# Grinsen + Augen
			canvas.draw_arc(c+Vector2(0,-18+bob), 5.0, 0.3, PI-0.3, 8, Color(0.45,0.25,0.15), 1.5)
			canvas.draw_line(c+Vector2(-8,-24+bob), c+Vector2(-3,-23+bob), Color(0.1,0.1,0.1), 2.0)
			canvas.draw_line(c+Vector2(3,-23+bob),  c+Vector2(8,-24+bob),  Color(0.1,0.1,0.1), 2.0)
		"toxo":
			# Bonus-Charakter: gruener Mutant mit leuchtenden Augen
			var skin   = Color(0.45, 0.78, 0.30)
			var skin_d = Color(0.30, 0.58, 0.20)
			var overall = Color(0.40, 0.30, 0.10)
			var glow   = Color(0.75, 1.0, 0.25)
			# Schuhe
			canvas.draw_rect(Rect2(c+Vector2(-12,24+bob), Vector2(11,4)), Color(0.12,0.10,0.06))
			canvas.draw_rect(Rect2(c+Vector2(-1,24+bob),  Vector2(11,4)), Color(0.12,0.10,0.06))
			# Beine
			canvas.draw_rect(Rect2(c+Vector2(-10,12+bob), Vector2(8,13)), skin)
			canvas.draw_rect(Rect2(c+Vector2(2,12+bob),   Vector2(8,13)), skin)
			# Latzhose
			canvas.draw_rect(Rect2(c+Vector2(-11,-6+bob), Vector2(22,18)), overall)
			# Arme
			canvas.draw_rect(Rect2(c+Vector2(-17,-1+bob), Vector2(7,11)), skin)
			canvas.draw_rect(Rect2(c+Vector2(10,-1+bob),  Vector2(7,11)), skin)
			canvas.draw_circle(c+Vector2(-16,9+bob), 5, skin)
			canvas.draw_circle(c+Vector2(16,9+bob),  5, skin)
			# Kopf
			canvas.draw_circle(c+Vector2(0,-22+bob), 14, skin)
			canvas.draw_circle(c+Vector2(-7,-26+bob), 4, skin_d)
			canvas.draw_circle(c+Vector2(7,-19+bob), 3, skin_d)
			# Leuchtende Augen
			canvas.draw_circle(c+Vector2(-5,-24+bob), 3.2, glow)
			canvas.draw_circle(c+Vector2(5,-24+bob),  3.2, glow)
			canvas.draw_circle(c+Vector2(-5,-24+bob), 1.4, Color(0.05,0.10,0.0))
			canvas.draw_circle(c+Vector2(5,-24+bob),  1.4, Color(0.05,0.10,0.0))
			# Maul
			canvas.draw_arc(c+Vector2(0,-16+bob), 5, 0.1, PI-0.1, 8, Color(0.10,0.20,0.05), 2.5)

func _unlock_wave(char_id: String) -> int:
	match char_id:
		"shouter": return 3
		"dreads": return 5
		"riff_slicer": return 7
		"distortion": return 10
		"bassist": return 12
		_: return 0

func _update_selection(index: int) -> void:
	selected_index = index
	GameManager.selected_character = CHARACTERS[index]
	_update_weapon_btn()
	# Visual feedback handled by draw

func _sig_name(char_id: String) -> String:
	return SIGNATURE_NAMES.get(char_id, "Signature")

func _update_weapon_btn() -> void:
	if not _weapon_btn:
		return
	var cid: String = CHARACTERS[selected_index]
	var de: bool = LocalizationManager.current_language == "de"
	if not SaveManager.is_weapon_unlocked(cid):
		_weapon_btn.disabled = true
		_weapon_btn.text = "Signature: Stufe 3 schaffen" if de else "Signature: beat difficulty 3"
		return
	_weapon_btn.disabled = false
	if bool(_weapon_choice.get(cid, false)):
		_weapon_btn.text = ("Waffe: " if de else "Weapon: ") + _sig_name(cid)
	else:
		_weapon_btn.text = "Waffe: Standard" if de else "Weapon: Standard"

func _toggle_weapon() -> void:
	var cid: String = CHARACTERS[selected_index]
	if not SaveManager.is_weapon_unlocked(cid):
		return
	_weapon_choice[cid] = not bool(_weapon_choice.get(cid, false))
	_update_weapon_btn()

func _select_difficulty(idx: int) -> void:
	GameManager.difficulty = idx
	_update_diff_visuals()

func _update_diff_visuals() -> void:
	for d in range(_diff_buttons.size()):
		var btn = _diff_buttons[d]
		var col = GameManager.DIFFICULTY_COLORS[d]
		var sty = StyleBoxFlat.new()
		sty.set_corner_radius_all(6)
		sty.set_border_width_all(2)
		if d == GameManager.difficulty:
			sty.bg_color = col.darkened(0.1)
			sty.border_color = Color.WHITE
			sty.set_border_width_all(3)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			sty.bg_color = col.darkened(0.55)
			sty.border_color = col
			btn.add_theme_color_override("font_color", col.lightened(0.2))
		btn.add_theme_stylebox_override("normal", sty)

func _is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

func _toggle_coop() -> void:
	var enabling = not _coop_mode
	if enabling and _is_mobile():
		var wifi_check = load("res://scripts/globals/wifi_check.gd")
		if not wifi_check.is_wifi_connected():
			wifi_check.show_no_wifi_dialog(self)
			return
	if not _coop_mode and _is_mobile():
		# Auf Mobilgeräten: Netzwerk-Panel statt lokalem P2-Panel
		_coop_mode = true
		_build_net_panel()
		_update_coop_btn_style()
		return
	if not enabling:
		GameManager.net_stop()
		_peer_ready = false
		if _net_panel:
			_net_panel.queue_free()
			_net_panel = null
	_coop_mode = enabling
	_p2_panel.visible = _coop_mode and not _is_mobile()
	_update_coop_btn_style()

func _build_net_panel() -> void:
	if _net_panel:
		_net_panel.queue_free()
	_net_panel = Control.new()
	_net_panel.set_anchors_preset(PRESET_FULL_RECT)
	_net_panel.anchor_top = 0.60
	add_child(_net_panel)

	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.02, 0.13, 0.98)
	_net_panel.add_child(bg)

	# Titel
	var title = Label.new()
	title.position = Vector2(0, 8)
	title.size = Vector2(1280, 40)
	title.text = LocalizationManager.t("net_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	title.add_theme_font_size_override("font_size", 26)
	_net_panel.add_child(title)

	# HOSTEN-Button (links)
	var host_btn = Button.new()
	host_btn.position = Vector2(80, 56)
	host_btn.size = Vector2(260, 60)
	host_btn.text = LocalizationManager.t("net_host")
	host_btn.add_theme_font_size_override("font_size", 22)
	host_btn.pressed.connect(_on_net_host_pressed)
	_net_panel.add_child(host_btn)

	# BEITRETEN-Button (rechts)
	var join_btn = Button.new()
	join_btn.position = Vector2(460, 56)
	join_btn.size = Vector2(260, 60)
	join_btn.text = LocalizationManager.t("net_join")
	join_btn.add_theme_font_size_override("font_size", 22)
	join_btn.pressed.connect(_on_net_join_pressed)
	_net_panel.add_child(join_btn)

	# IP-Eingabefeld (immer sichtbar, für Beitreten)
	_net_ip_field = LineEdit.new()
	_net_ip_field.position = Vector2(780, 56)
	_net_ip_field.size = Vector2(380, 60)
	_net_ip_field.placeholder_text = "Host-IP: 192.168.x.x"
	_net_ip_field.add_theme_font_size_override("font_size", 20)
	_net_panel.add_child(_net_ip_field)

	# Status-Label
	_net_ip_label = Label.new()
	_net_ip_label.position = Vector2(0, 128)
	_net_ip_label.size = Vector2(980, 50)
	_net_ip_label.text = "← Hosten oder IP eingeben und Beitreten"
	_net_ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_net_ip_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	_net_ip_label.add_theme_font_size_override("font_size", 18)
	_net_panel.add_child(_net_ip_label)

	# SPIELEN-Button im Panel (nur für Host, erscheint nach Verbindung)
	var net_play_btn = Button.new()
	net_play_btn.name = "NetPlayBtn"
	net_play_btn.position = Vector2(1000, 110)
	net_play_btn.size = Vector2(260, 65)
	net_play_btn.text = "▶ SPIELEN"
	net_play_btn.add_theme_font_size_override("font_size", 24)
	net_play_btn.visible = false
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.1, 0.6, 0.15)
	ps.border_color = Color(0.3, 1.0, 0.4)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(8)
	net_play_btn.add_theme_stylebox_override("normal", ps)
	net_play_btn.pressed.connect(_on_play_pressed)
	_net_panel.add_child(net_play_btn)

func _on_net_host_pressed() -> void:
	GameManager.net_stop()
	var ip = GameManager.net_start_host()
	_net_ip_label.text = LocalizationManager.t("net_waiting") % ip
	_net_ip_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	if not GameManager.net_peer_connected.is_connected(_on_net_partner_connected):
		GameManager.net_peer_connected.connect(_on_net_partner_connected, CONNECT_ONE_SHOT)

func _on_net_join_pressed() -> void:
	var ip = _net_ip_field.text.strip_edges()
	if ip.is_empty():
		_net_ip_label.text = LocalizationManager.t("net_enter_ip")
		_net_ip_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
		return
	GameManager.net_stop()
	_net_ip_label.text = LocalizationManager.t("net_connecting") % ip
	_net_ip_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	var err = GameManager.net_join(ip)
	if err != OK:
		_net_ip_label.text = LocalizationManager.t("net_conn_error") % err
		_net_ip_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		return
	# Auf Verbindung warten (mit Timeout-Feedback)
	if not GameManager.net_connected_to_host.is_connected(_on_net_partner_connected):
		GameManager.net_connected_to_host.connect(_on_net_partner_connected, CONNECT_ONE_SHOT)
	if not multiplayer.connection_failed.is_connected(_on_net_connection_failed):
		multiplayer.connection_failed.connect(_on_net_connection_failed, CONNECT_ONE_SHOT)

func _on_net_connection_failed() -> void:
	_net_ip_label.text = LocalizationManager.t("net_conn_failed")
	_net_ip_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	GameManager.net_stop()

func _on_net_partner_connected() -> void:
	_peer_ready = true
	if GameManager.network_mode == 1:
		_net_ip_label.text = LocalizationManager.t("net_p2_connected")
		_net_ip_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		var btn = _net_panel.get_node_or_null("NetPlayBtn")
		if btn:
			btn.visible = true
	else:
		_net_ip_label.text = LocalizationManager.t("net_connected_wait")
		_net_ip_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))

func _update_coop_btn_style() -> void:
	if not _coop_btn:
		return
	var sty = StyleBoxFlat.new()
	sty.set_corner_radius_all(6)
	sty.set_border_width_all(2)
	if _coop_mode:
		_coop_btn.text = "👥 2 SPIELER"
		sty.bg_color     = Color(0.2, 0.1, 0.4)
		sty.border_color = Color(0.7, 0.4, 1.0)
		_coop_btn.add_theme_color_override("font_color", Color(0.9, 0.7, 1.0))
	else:
		_coop_btn.text = "👤 SOLO"
		sty.bg_color     = Color(0.08, 0.08, 0.14)
		sty.border_color = Color(0.4, 0.4, 0.6)
		_coop_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	_coop_btn.add_theme_stylebox_override("normal", sty)

# P2-Zyklus ueberspringt gesperrte Charaktere (vorher konnte P2 gesperrte
# Basis-Charaktere waehlen, Default war sogar der gesperrte Shouter;
# Audit Run #11, P1)
func _p2_step(dir: int) -> void:
	for _i in range(CHARACTERS.size()):
		_p2_idx = (_p2_idx + dir + CHARACTERS.size()) % CHARACTERS.size()
		if SaveManager.is_character_unlocked(CHARACTERS[_p2_idx]):
			break
	_update_p2_display()

func _p2_prev() -> void:
	_p2_step(-1)

func _p2_next() -> void:
	_p2_step(1)

func _update_p2_display() -> void:
	if not _p2_panel:
		return
	var lbl = _p2_panel.get_node_or_null("P2NameLabel")
	if lbl:
		var char_id = CHARACTERS[_p2_idx]
		var info = GameManager.CHARACTER_INFO.get(char_id, {})
		var col = info.get("color", Color.WHITE)
		lbl.text = info.get("name", char_id)
		lbl.add_theme_color_override("font_color", col)

func _on_play_pressed() -> void:
	GameManager.selected_characters[0] = CHARACTERS[selected_index]
	GameManager.selected_characters[1] = CHARACTERS[_p2_idx]
	GameManager.selected_weapon = _weapon_choice.duplicate()
	if GameManager.network_mode == 1:
		# Netzwerk-Host: Client informieren, dann Spiel starten
		GameManager.net_start_game_as_host()
	elif GameManager.network_mode == 2:
		# Client wartet – Host startet das Spiel
		pass
	else:
		GameManager.player_count = 2 if _coop_mode else 1
		GameManager.start_game()
