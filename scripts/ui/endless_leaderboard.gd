extends Control

# ── State ─────────────────────────────────────────────────────────────────────
var _anim_time:   float  = 0.0
var _saved:       bool   = false
var _show_entry:  bool   = false   # false = view-only (called from main menu)
var _new_rank:    int    = -1      # index of the newly saved entry (highlight)

# Name entry: 3 letter slots cycling A–Z
const _LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
var _slots: Array = [0, 0, 0]   # indices into _LETTERS
var _cursor: int  = 0

var _slot_labels:  Array = []   # 3 Label nodes for the letters
var _confirm_btn:  Button = null
var _lb_container: VBoxContainer = null

# ── Ready ──────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Called after death in endless mode OR directly from main menu
	_show_entry = GameManager.endless_mode and GameManager.run_stats.get("waves_cleared", 0) > 0
	# Defer so the Control's size is resolved from anchors before building UI
	call_deferred("_build_ui")

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

# ── Background draw ────────────────────────────────────────────────────────────
func _draw() -> void:
	var w = size.x; var h = size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.03, 0.01, 0.06))
	# Scanline effect
	for i in range(0, int(h), 4):
		draw_line(Vector2(0, i), Vector2(w, i), Color(0.0, 0.0, 0.0, 0.18), 1)
	# Pulsing border
	var pulse = 0.5 + 0.5 * sin(_anim_time * 2.5)
	draw_rect(Rect2(0, 0, w, h), Color(0.7, 0.3, 0.0, pulse * 0.08), false, 3)

# ── UI Build ───────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Back button (top left) – always visible
	var back_btn = Button.new()
	back_btn.text = LocalizationManager.t("main_menu_back")
	back_btn.set_anchors_preset(PRESET_TOP_LEFT)
	back_btn.position = Vector2(20, 16)
	back_btn.size     = Vector2(200, 42)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	var sty_b = StyleBoxFlat.new()
	sty_b.bg_color     = Color(0.08, 0.08, 0.12)
	sty_b.border_color = Color(0.4, 0.4, 0.5)
	sty_b.set_border_width_all(2)
	sty_b.set_corner_radius_all(6)
	back_btn.add_theme_stylebox_override("normal", sty_b)
	back_btn.pressed.connect(_on_main_menu)
	add_child(back_btn)

	if _show_entry:
		_build_entry_section()
	else:
		_build_title_only()

	_build_leaderboard_section()

func _build_title_only() -> void:
	var lbl = Label.new()
	lbl.set_anchors_preset(PRESET_TOP_WIDE)
	lbl.anchor_bottom = 0.0
	lbl.offset_bottom = 72
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.text = LocalizationManager.t("lb_title")
	lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.0))
	lbl.add_theme_font_size_override("font_size", 32)
	add_child(lbl)

func _build_entry_section() -> void:
	var wave  = GameManager.current_wave
	var score = GameManager.score
	var map_id = GameManager.endless_map

	# Game over header
	var go_lbl = Label.new()
	go_lbl.set_anchors_preset(PRESET_TOP_WIDE)
	go_lbl.anchor_bottom = 0.0
	go_lbl.offset_bottom = 56
	go_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	go_lbl.text = LocalizationManager.t("game_over")
	go_lbl.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
	go_lbl.add_theme_font_size_override("font_size", 44)
	add_child(go_lbl)

	# Stats line
	var stats_lbl = Label.new()
	stats_lbl.position = Vector2(0, 58)
	stats_lbl.size     = Vector2(size.x, 32)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.text = LocalizationManager.t("lb_stats_line") % [wave, score, map_id.capitalize()]
	stats_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	stats_lbl.add_theme_font_size_override("font_size", 20)
	add_child(stats_lbl)

	# Name entry panel – breit genug damit Slots und Confirm-Button nebeneinander passen
	var slots_cx = size.x * 0.5
	var panel_bg = ColorRect.new()
	panel_bg.position = Vector2(slots_cx - 310, 100)
	panel_bg.size     = Vector2(620, 162)
	panel_bg.color    = Color(0.06, 0.04, 0.10)
	add_child(panel_bg)

	var entry_lbl = Label.new()
	entry_lbl.position = Vector2(slots_cx - 300, 108)
	entry_lbl.size     = Vector2(290, 22)
	entry_lbl.text     = LocalizationManager.t("enter_name")
	entry_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	entry_lbl.add_theme_font_size_override("font_size", 14)
	add_child(entry_lbl)

	# 3 Buchstaben-Slots – nach links verschoben, Confirm-Button rechts daneben ohne Überlapp
	# Slots x: slots_cx-198, slots_cx-123, slots_cx-48  →  Confirm ab slots_cx+37
	for si in range(3):
		var sx = slots_cx - 198 + si * 75
		# Background box
		var box = ColorRect.new()
		box.position = Vector2(sx, 156)
		box.size     = Vector2(65, 65)
		box.color    = Color(0.12, 0.08, 0.18)
		add_child(box)

		# Up button (über dem Box, kein Überlapp mit entry_lbl da ab y=132)
		var up_btn = Button.new()
		up_btn.text     = "▲"
		up_btn.position = Vector2(sx + 11, 132)
		up_btn.size     = Vector2(44, 22)
		up_btn.add_theme_font_size_override("font_size", 13)
		_style_arrow_btn(up_btn)
		up_btn.pressed.connect(_on_slot_up.bind(si))
		add_child(up_btn)

		# Letter label
		var lbl = Label.new()
		lbl.position = Vector2(sx, 156)
		lbl.size     = Vector2(65, 65)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.text = _LETTERS[_slots[si]]
		lbl.add_theme_font_size_override("font_size", 40)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1) if si == _cursor else Color.WHITE)
		add_child(lbl)
		_slot_labels.append(lbl)

		# Down button (unter dem Box)
		var dn_btn = Button.new()
		dn_btn.text     = "▼"
		dn_btn.position = Vector2(sx + 11, 224)
		dn_btn.size     = Vector2(44, 22)
		dn_btn.add_theme_font_size_override("font_size", 13)
		_style_arrow_btn(dn_btn)
		dn_btn.pressed.connect(_on_slot_down.bind(si))
		add_child(dn_btn)

	# Confirm button – rechts neben Slot 2 (Slot 2 endet bei slots_cx+17, Confirm ab slots_cx+37)
	_confirm_btn = Button.new()
	_confirm_btn.text     = LocalizationManager.t("confirm_entry")
	_confirm_btn.position = Vector2(slots_cx + 37, 156)
	_confirm_btn.size     = Vector2(168, 65)
	_confirm_btn.add_theme_font_size_override("font_size", 17)
	_confirm_btn.add_theme_color_override("font_color", Color.WHITE)
	var sty_c = StyleBoxFlat.new()
	sty_c.bg_color     = Color(0.1, 0.45, 0.1)
	sty_c.border_color = Color(0.3, 0.9, 0.3)
	sty_c.set_border_width_all(2)
	sty_c.set_corner_radius_all(8)
	_confirm_btn.add_theme_stylebox_override("normal", sty_c)
	var sty_ch = StyleBoxFlat.new()
	sty_ch.bg_color = Color(0.2, 0.65, 0.2)
	sty_ch.set_corner_radius_all(8)
	_confirm_btn.add_theme_stylebox_override("hover", sty_ch)
	_confirm_btn.pressed.connect(_on_confirm)
	add_child(_confirm_btn)

	# Keyboard hint
	var hint = Label.new()
	hint.position = Vector2(slots_cx - 300, 268)
	hint.size     = Vector2(600, 22)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = LocalizationManager.t("kb_hint_lb")
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	hint.add_theme_font_size_override("font_size", 14)
	add_child(hint)

	# Play again button
	var again_btn = Button.new()
	again_btn.text = LocalizationManager.t("play_again")
	again_btn.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	again_btn.anchor_left   = 1.0
	again_btn.anchor_top    = 1.0
	again_btn.offset_left   = -290
	again_btn.offset_top    = -68
	again_btn.offset_right  = -20
	again_btn.offset_bottom = -16
	again_btn.add_theme_font_size_override("font_size", 20)
	again_btn.add_theme_color_override("font_color", Color.WHITE)
	var sty_a = StyleBoxFlat.new()
	sty_a.bg_color     = Color(0.55, 0.18, 0.0)
	sty_a.border_color = Color(1.0, 0.55, 0.0)
	sty_a.set_border_width_all(2)
	sty_a.set_corner_radius_all(8)
	again_btn.add_theme_stylebox_override("normal", sty_a)
	again_btn.pressed.connect(GameManager.go_to_map_select)
	add_child(again_btn)

func _build_leaderboard_section() -> void:
	var lb_y = 298.0 if _show_entry else 80.0

	# Section header
	var hdr = Label.new()
	hdr.position = Vector2(40, lb_y)
	hdr.size     = Vector2(size.x - 80, 28)
	hdr.text     = LocalizationManager.t("top10")
	hdr.add_theme_color_override("font_color", Color(1.0, 0.75, 0.0))
	hdr.add_theme_font_size_override("font_size", 20)
	add_child(hdr)

	# Column headers
	var col_hdr = Label.new()
	col_hdr.position = Vector2(40, lb_y + 32)
	col_hdr.size     = Vector2(size.x - 80, 22)
	col_hdr.text     = LocalizationManager.t("lb_col_header")
	col_hdr.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	col_hdr.add_theme_font_size_override("font_size", 14)
	add_child(col_hdr)

	# Divider
	var div = ColorRect.new()
	div.position = Vector2(40, lb_y + 56)
	div.size     = Vector2(size.x - 80, 2)
	div.color    = Color(0.5, 0.3, 0.0, 0.8)
	add_child(div)

	# Rows container (VBox for easy refresh)
	_lb_container = VBoxContainer.new()
	_lb_container.position = Vector2(40, lb_y + 62)
	_lb_container.size     = Vector2(size.x - 80, 300)
	add_child(_lb_container)

	_refresh_leaderboard_rows()

func _refresh_leaderboard_rows() -> void:
	for child in _lb_container.get_children():
		child.queue_free()

	var entries = SaveManager.get_endless_leaderboard()
	if entries.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = LocalizationManager.t("lb_empty")
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_lbl.add_theme_font_size_override("font_size", 16)
		_lb_container.add_child(empty_lbl)
		return

	for i in range(entries.size()):
		var e   = entries[i]
		var row = Label.new()
		var rank_str  = str(i + 1).lpad(2)
		var name_str  = e.get("name",  "???").rpad(4)
		var wave_str  = str(e.get("wave",  0)).lpad(5)
		var score_str = str(e.get("score", 0)).lpad(10)
		var map_str   = e.get("map", "").capitalize()
		row.text = "%s    %s    %s%s    %s    %s" % [rank_str, name_str, LocalizationManager.t("lb_wave_col"), wave_str, score_str, map_str]
		row.add_theme_font_size_override("font_size", 17)
		if i == _new_rank:
			row.add_theme_color_override("font_color", Color(1.0, 0.88, 0.0))
		elif i == 0:
			row.add_theme_color_override("font_color", Color(1.0, 0.75, 0.1))
		elif i == 1:
			row.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		elif i == 2:
			row.add_theme_color_override("font_color", Color(0.85, 0.55, 0.2))
		else:
			row.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		_lb_container.add_child(row)

# ── Input: keyboard letter entry ───────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _saved or not _show_entry:
		return
	if event is InputEventKey and event.pressed:
		var kc = event.keycode
		if kc >= KEY_A and kc <= KEY_Z:
			var letter_idx = kc - KEY_A
			_slots[_cursor] = letter_idx
			_update_slot_display()
			_cursor = min(_cursor + 1, 2)
			_update_cursor_highlight()
		elif kc == KEY_BACKSPACE:
			if _cursor > 0:
				_cursor -= 1
			_slots[_cursor] = 0
			_update_slot_display()
			_update_cursor_highlight()
		elif kc == KEY_LEFT and _cursor > 0:
			_cursor -= 1
			_update_cursor_highlight()
		elif kc == KEY_RIGHT and _cursor < 2:
			_cursor += 1
			_update_cursor_highlight()
		elif kc == KEY_ENTER or kc == KEY_KP_ENTER:
			_on_confirm()

# ── Slot controls ──────────────────────────────────────────────────────────────
func _on_slot_up(slot_idx: int) -> void:
	_cursor = slot_idx
	_slots[slot_idx] = (_slots[slot_idx] - 1 + 26) % 26
	_update_slot_display()
	_update_cursor_highlight()

func _on_slot_down(slot_idx: int) -> void:
	_cursor = slot_idx
	_slots[slot_idx] = (_slots[slot_idx] + 1) % 26
	_update_slot_display()
	_update_cursor_highlight()

func _update_slot_display() -> void:
	for i in range(3):
		if i < _slot_labels.size():
			_slot_labels[i].text = _LETTERS[_slots[i]]

func _update_cursor_highlight() -> void:
	for i in range(3):
		if i < _slot_labels.size():
			_slot_labels[i].add_theme_color_override("font_color",
				Color(1.0, 0.88, 0.1) if i == _cursor else Color.WHITE)

# ── Confirm ────────────────────────────────────────────────────────────────────
func _on_confirm() -> void:
	if _saved:
		return
	_saved = true
	if is_instance_valid(_confirm_btn):
		_confirm_btn.disabled = true

	var name_str = ""
	for i in range(3):
		name_str += _LETTERS[_slots[i]]

	var wave  = GameManager.current_wave
	var score = GameManager.score
	var map   = GameManager.endless_map

	SaveManager.add_endless_score(name_str, score, wave, map)

	# Find rank of new entry
	var lb = SaveManager.get_endless_leaderboard()
	for i in range(lb.size()):
		if lb[i]["name"] == name_str and lb[i]["score"] == score and lb[i]["wave"] == wave:
			_new_rank = i
			break

	_refresh_leaderboard_rows()

# ── Navigation ─────────────────────────────────────────────────────────────────
func _on_main_menu() -> void:
	GameManager.endless_mode = false
	GameManager.go_to_main_menu()

# ── Arrow button style helper ──────────────────────────────────────────────────
func _style_arrow_btn(btn: Button) -> void:
	btn.add_theme_color_override("font_color", Color.WHITE)
	var sty = StyleBoxFlat.new()
	sty.bg_color     = Color(0.18, 0.12, 0.28)
	sty.border_color = Color(0.5, 0.3, 0.7)
	sty.set_border_width_all(1)
	sty.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sty)
