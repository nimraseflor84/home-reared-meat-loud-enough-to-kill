extends Control

var _anim_time: float = 0.0
var _selected_map: String = "farm"
var _selected_diff: int = 2
var _selected_char: String = "manni"

const MAPS = [
	{"id": "proberaum",     "name": "Proberaum",         "color": Color(0.18, 0.12, 0.24)},
	{"id": "prison",        "name": "Gefängnis",         "color": Color(0.30, 0.29, 0.34)},
	{"id": "farm",          "name": "Die Farm",         "color": Color(0.22, 0.44, 0.12)},
	{"id": "schweinestall", "name": "Schweinestall",     "color": Color(0.42, 0.26, 0.08)},
	{"id": "amerika",       "name": "Amerika",           "color": Color(0.10, 0.20, 0.55)},
	{"id": "truck",         "name": "Truck",             "color": Color(0.08, 0.12, 0.24)},
	{"id": "tonstudio",     "name": "Soundlodge",        "color": Color(0.10, 0.08, 0.16)},
	{"id": "tv_studio",     "name": "TV Studio",         "color": Color(0.12, 0.10, 0.20)},
	{"id": "meppen",        "name": "Meppen",            "color": Color(0.46, 0.44, 0.42)},
	{"id": "death_feast",   "name": "Death Feast",       "color": Color(0.06, 0.02, 0.08)},
]

var _map_buttons: Array = []
var _diff_buttons: Array = []
var _char_buttons: Array = []

func _ready() -> void:
	_selected_char = GameManager.selected_character
	call_deferred("_build_ui")

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

func _draw() -> void:
	var w = size.x; var h = size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.02, 0.08))
	# Animated diagonal stripes
	for i in range(12):
		var sx = fmod(float(i) * 110.0 - _anim_time * 18.0, w + 200.0) - 100.0
		draw_line(Vector2(sx, 0), Vector2(sx + 160, h), Color(1.0, 0.4, 0.0, 0.022), 28)
	# Top title bar
	draw_rect(Rect2(0, 0, w, 64), Color(0.0, 0.0, 0.0, 0.7))
	draw_line(Vector2(0, 64), Vector2(w, 64), Color(0.8, 0.35, 0.0), 2)

func _build_ui() -> void:
	# Title
	var title = Label.new()
	title.set_anchors_preset(PRESET_TOP_WIDE)
	title.anchor_bottom = 0.0
	title.offset_bottom = 64
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text = "ENDLESS MODE – MAP WÄHLEN"
	title.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)

	# ── Map grid (2 rows × 5) ──────────────────────────────────────────────
	var grid_x = 40.0
	var grid_y = 80.0
	var tile_w = 230.0
	var tile_h = 90.0
	var gap    = 10.0

	for i in range(MAPS.size()):
		var m    = MAPS[i]
		var col  = i % 5
		var row  = i / 5
		var bx   = grid_x + col * (tile_w + gap)
		var by   = grid_y + row * (tile_h + gap)

		var btn  = Button.new()
		btn.text = m["name"]
		btn.position = Vector2(bx, by)
		btn.size     = Vector2(tile_w, tile_h)
		btn.add_theme_font_size_override("font_size", 17)
		btn.add_theme_color_override("font_color", Color.WHITE)
		_apply_map_btn_style(btn, m["color"], m["id"] == _selected_map)
		btn.pressed.connect(_on_map_selected.bind(m["id"]))
		add_child(btn)
		_map_buttons.append({"btn": btn, "id": m["id"], "color": m["color"]})
		if i == 0:
			btn.call_deferred("grab_focus")

	# ── Character row ──────────────────────────────────────────────────────
	var char_lbl = Label.new()
	char_lbl.position = Vector2(40, 298)
	char_lbl.size     = Vector2(300, 26)
	char_lbl.text     = "CHARAKTER:"
	char_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	char_lbl.add_theme_font_size_override("font_size", 16)
	add_child(char_lbl)

	var chars = ["manni", "shouter", "dreads", "riff_slicer", "distortion", "bassist"]
	var char_names = {"manni": "Manny", "shouter": "Chicken", "dreads": "Nik",
		"riff_slicer": "Andz", "distortion": "Grindhouse", "bassist": "Armin"}
	var char_colors = {"manni": Color(0.2, 0.4, 0.9), "shouter": Color(0.9, 0.2, 0.2),
		"dreads": Color(0.2, 0.8, 0.3), "riff_slicer": Color(0.9, 0.5, 0.1),
		"distortion": Color(0.6, 0.2, 0.9), "bassist": Color(0.1, 0.2, 0.6)}

	for i in range(chars.size()):
		var cid  = chars[i]
		var btn  = Button.new()
		btn.text = char_names[cid]
		btn.position = Vector2(40 + i * 195, 325)
		btn.size     = Vector2(185, 55)
		btn.add_theme_font_size_override("font_size", 15)
		var unlocked = SaveManager.is_character_unlocked(cid)
		if unlocked:
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.pressed.connect(_on_char_selected.bind(cid))
		else:
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			btn.disabled = true
		_apply_char_btn_style(btn, char_colors[cid], cid == _selected_char, unlocked)
		add_child(btn)
		_char_buttons.append({"btn": btn, "id": cid, "color": char_colors[cid]})

	# ── Difficulty row ─────────────────────────────────────────────────────
	var diff_lbl = Label.new()
	diff_lbl.position = Vector2(40, 405)
	diff_lbl.size     = Vector2(300, 26)
	diff_lbl.text     = "SCHWIERIGKEIT:"
	diff_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	diff_lbl.add_theme_font_size_override("font_size", 16)
	add_child(diff_lbl)

	var diff_colors = [Color(0.15, 0.75, 0.25), Color(0.65, 0.80, 0.10),
		Color(0.90, 0.50, 0.05), Color(0.85, 0.12, 0.08), Color(0.55, 0.0, 0.08)]

	for i in range(GameManager.DIFFICULTY_NAMES.size()):
		var btn  = Button.new()
		btn.text = GameManager.DIFFICULTY_NAMES[i]
		btn.position = Vector2(40 + i * 234, 432)
		btn.size     = Vector2(224, 50)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color.WHITE)
		_apply_diff_btn_style(btn, diff_colors[i], i == _selected_diff)
		btn.pressed.connect(_on_diff_selected.bind(i))
		add_child(btn)
		_diff_buttons.append({"btn": btn, "idx": i, "color": diff_colors[i]})

	# ── Bottom buttons ─────────────────────────────────────────────────────
	var start_btn = Button.new()
	start_btn.name = "StartBtn"
	start_btn.text = "START ENDLESS!"
	start_btn.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	start_btn.anchor_left   = 1.0
	start_btn.anchor_top    = 1.0
	start_btn.offset_left   = -310
	start_btn.offset_top    = -78
	start_btn.offset_right  = -30
	start_btn.offset_bottom = -20
	start_btn.add_theme_font_size_override("font_size", 24)
	start_btn.add_theme_color_override("font_color", Color.WHITE)
	var sty_start = StyleBoxFlat.new()
	sty_start.bg_color     = Color(0.55, 0.18, 0.0)
	sty_start.border_color = Color(1.0, 0.55, 0.0)
	sty_start.set_border_width_all(2)
	sty_start.set_corner_radius_all(8)
	start_btn.add_theme_stylebox_override("normal", sty_start)
	var sty_sh = StyleBoxFlat.new()
	sty_sh.bg_color = Color(0.8, 0.35, 0.0)
	sty_sh.set_corner_radius_all(8)
	start_btn.add_theme_stylebox_override("hover", sty_sh)
	start_btn.pressed.connect(_on_start_pressed)
	add_child(start_btn)

	var back_btn = Button.new()
	back_btn.text = "← ZURÜCK"
	back_btn.set_anchors_preset(PRESET_BOTTOM_LEFT)
	back_btn.anchor_top    = 1.0
	back_btn.offset_left   = 30
	back_btn.offset_top    = -78
	back_btn.offset_right  = 220
	back_btn.offset_bottom = -20
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	var sty_back = StyleBoxFlat.new()
	sty_back.bg_color     = Color(0.08, 0.08, 0.12)
	sty_back.border_color = Color(0.4, 0.4, 0.5)
	sty_back.set_border_width_all(2)
	sty_back.set_corner_radius_all(6)
	back_btn.add_theme_stylebox_override("normal", sty_back)
	back_btn.pressed.connect(GameManager.go_to_main_menu)
	add_child(back_btn)

# ── Style helpers ──────────────────────────────────────────────────────────────
func _make_btn_sty(col: Color, selected: bool, border_w: int = 2) -> StyleBoxFlat:
	var sty = StyleBoxFlat.new()
	sty.bg_color     = col.darkened(0.5) if not selected else col.darkened(0.15)
	sty.border_color = col if selected else col.darkened(0.2)
	sty.set_border_width_all(border_w if not selected else 3)
	sty.set_corner_radius_all(6)
	return sty

func _apply_map_btn_style(btn: Button, col: Color, selected: bool) -> void:
	btn.add_theme_stylebox_override("normal", _make_btn_sty(col, selected, 2))
	var sty_h = StyleBoxFlat.new()
	sty_h.bg_color = col.darkened(0.2)
	sty_h.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", sty_h)

func _apply_char_btn_style(btn: Button, col: Color, selected: bool, unlocked: bool) -> void:
	var sty = StyleBoxFlat.new()
	sty.bg_color     = col.darkened(0.55) if not selected else col.darkened(0.2)
	sty.border_color = col if selected else (col.darkened(0.3) if unlocked else Color(0.3, 0.3, 0.3))
	sty.set_border_width_all(3 if selected else 2)
	sty.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sty)

func _apply_diff_btn_style(btn: Button, col: Color, selected: bool) -> void:
	btn.add_theme_stylebox_override("normal", _make_btn_sty(col, selected, 2))

# ── Selection handlers ─────────────────────────────────────────────────────────
func _on_map_selected(map_id: String) -> void:
	_selected_map = map_id
	for d in _map_buttons:
		_apply_map_btn_style(d["btn"], d["color"], d["id"] == _selected_map)

func _on_char_selected(char_id: String) -> void:
	_selected_char = char_id
	var char_colors = {"manni": Color(0.2, 0.4, 0.9), "shouter": Color(0.9, 0.2, 0.2),
		"dreads": Color(0.2, 0.8, 0.3), "riff_slicer": Color(0.9, 0.5, 0.1),
		"distortion": Color(0.6, 0.2, 0.9), "bassist": Color(0.1, 0.2, 0.6)}
	for d in _char_buttons:
		_apply_char_btn_style(d["btn"], d["color"], d["id"] == _selected_char,
			SaveManager.is_character_unlocked(d["id"]))

func _on_diff_selected(idx: int) -> void:
	_selected_diff = idx
	var diff_colors = [Color(0.15, 0.75, 0.25), Color(0.65, 0.80, 0.10),
		Color(0.90, 0.50, 0.05), Color(0.85, 0.12, 0.08), Color(0.55, 0.0, 0.08)]
	for d in _diff_buttons:
		_apply_diff_btn_style(d["btn"], diff_colors[d["idx"]], d["idx"] == _selected_diff)

func _on_start_pressed() -> void:
	GameManager.selected_character = _selected_char
	GameManager.difficulty         = _selected_diff
	GameManager.endless_map        = _selected_map
	GameManager.player_count       = 1  # Endless Mode immer Solo
	GameManager.start_endless_game()
