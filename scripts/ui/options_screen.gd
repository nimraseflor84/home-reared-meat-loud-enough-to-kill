extends Control

var _current_tab: int = 0
var _tab_panels: Array = []
var _tab_btns: Array = []
var _rebinding_action: String = ""
var _rebinding_btn: Button = null
var _rebinding_is_joy: bool = false
var _anim_time: float = 0.0
var _kb_btn_map: Dictionary = {}   # action_name -> Keyboard-Button
var _joy_btn_map: Dictionary = {}  # action_name -> Controller-Button
var _fps_lbl: Label = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	call_deferred("_build_ui")
	LocalizationManager.language_changed.connect(_on_language_changed)

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()
	if _fps_lbl and is_instance_valid(_fps_lbl) and SaveManager.get_setting("show_fps"):
		_fps_lbl.text = "FPS: %d" % Engine.get_frames_per_second()

func _draw() -> void:
	var s = size
	# Dark background
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.04, 0.02, 0.08))
	# Subtle scanlines every 3px
	var y_pos: float = 0.0
	while y_pos < s.y:
		draw_line(Vector2(0, y_pos), Vector2(s.x, y_pos), Color(0.0, 0.0, 0.0, 0.08), 1.0)
		y_pos += 3.0
	# Animated orange border pulse
	var alpha = 0.4 + 0.2 * sin(_anim_time * 2.0)
	var border_color = Color(1.0, 0.5, 0.0, alpha * 0.1 + 0.05)
	draw_rect(Rect2(Vector2.ZERO, s), border_color, false, 3.0)

func _build_ui() -> void:
	# Title
	var title = Label.new()
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_bottom = 64.0
	title.text = LocalizationManager.t("options_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.add_theme_font_size_override("font_size", 34)
	add_child(title)

	# Tab buttons - 4 tabs, centered in 1280px
	var tab_configs = [
		{"key": "tab_graphics", "color": Color(0.2, 0.4, 0.8)},
		{"key": "tab_sound",    "color": Color(0.55, 0.1, 0.75)},
		{"key": "tab_gameplay", "color": Color(0.15, 0.55, 0.15)},
		{"key": "tab_language", "color": Color(0.75, 0.4, 0.05)},
	]
	var tab_w: float = 256.0
	var tab_h: float = 44.0
	var tab_gap: float = 8.0
	var total_tabs_w: float = tab_configs.size() * tab_w + (tab_configs.size() - 1) * tab_gap
	var tab_start_x: float = (1280.0 - total_tabs_w) / 2.0

	_tab_btns.clear()
	for i in range(tab_configs.size()):
		var cfg = tab_configs[i]
		var btn = Button.new()
		btn.text = LocalizationManager.t(cfg["key"])
		btn.anchor_left = 0.0
		btn.anchor_top = 0.0
		btn.anchor_right = 0.0
		btn.anchor_bottom = 0.0
		btn.position = Vector2(tab_start_x + i * (tab_w + tab_gap), 70.0)
		btn.size = Vector2(tab_w, tab_h)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_font_size_override("font_size", 17)
		var idx = i
		btn.pressed.connect(func(): _select_tab(idx))
		_tab_btns.append(btn)
		add_child(btn)

	# Content panel background
	var panel_bg = ColorRect.new()
	panel_bg.position = Vector2(30, 122)
	panel_bg.size = Vector2(1220, 506)
	panel_bg.color = Color(0.06, 0.04, 0.10)
	add_child(panel_bg)

	# Gold top border line for content panel
	var border_line = ColorRect.new()
	border_line.position = Vector2(30, 122)
	border_line.size = Vector2(1220, 2)
	border_line.color = Color(1.0, 0.85, 0.2)
	add_child(border_line)

	# 4 content panels
	_tab_panels.clear()
	var panel_builders = [
		_build_graphics_panel,
		_build_sound_panel,
		_build_gameplay_panel,
		_build_language_panel,
	]
	for i in range(4):
		var panel = Control.new()
		panel.position = Vector2(30, 128)
		panel.size = Vector2(1220, 500)
		panel.visible = (i == _current_tab)
		add_child(panel)
		_tab_panels.append(panel)
		panel_builders[i].call(panel)

	# Back button
	var back_btn = Button.new()
	back_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back_btn.offset_top = -68.0
	back_btn.offset_right = 190.0
	back_btn.offset_bottom = 0.0
	back_btn.offset_left = 14.0
	back_btn.text = LocalizationManager.t("back")
	back_btn.add_theme_color_override("font_color", Color.WHITE)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(func(): GameManager.go_to_main_menu())
	var back_sty = StyleBoxFlat.new()
	back_sty.bg_color = Color(0.2, 0.2, 0.25)
	back_sty.border_color = Color(0.5, 0.5, 0.55)
	back_sty.set_border_width_all(2)
	back_sty.set_corner_radius_all(5)
	back_btn.add_theme_stylebox_override("normal", back_sty)
	var back_sty_h = StyleBoxFlat.new()
	back_sty_h.bg_color = Color(0.3, 0.3, 0.35)
	back_sty_h.set_corner_radius_all(5)
	back_btn.add_theme_stylebox_override("hover", back_sty_h)
	add_child(back_btn)

	# Apply initial tab styling
	_select_tab(_current_tab)

func _select_tab(idx: int) -> void:
	_current_tab = idx
	var tab_colors = [
		Color(0.2, 0.4, 0.8),
		Color(0.55, 0.1, 0.75),
		Color(0.15, 0.55, 0.15),
		Color(0.75, 0.4, 0.05),
	]
	for i in range(_tab_btns.size()):
		if not is_instance_valid(_tab_btns[i]):
			continue
		var btn = _tab_btns[i]
		var col = tab_colors[i]
		if i == _current_tab:
			var sty = StyleBoxFlat.new()
			sty.bg_color = col.lightened(0.25)
			sty.border_color = col.lightened(0.5)
			sty.set_border_width_all(3)
			sty.set_corner_radius_all(5)
			btn.add_theme_stylebox_override("normal", sty)
			btn.add_theme_stylebox_override("hover", sty)
		else:
			var sty = StyleBoxFlat.new()
			sty.bg_color = col.darkened(0.55)
			sty.border_color = col.darkened(0.2)
			sty.set_border_width_all(2)
			sty.set_corner_radius_all(5)
			btn.add_theme_stylebox_override("normal", sty)
			var sty_h = StyleBoxFlat.new()
			sty_h.bg_color = col.darkened(0.3)
			sty_h.set_corner_radius_all(5)
			btn.add_theme_stylebox_override("hover", sty_h)

	for i in range(_tab_panels.size()):
		if is_instance_valid(_tab_panels[i]):
			_tab_panels[i].visible = (i == _current_tab)

func _on_language_changed(_lang: String) -> void:
	for c in get_children():
		c.queue_free()
	_tab_panels = []
	_tab_btns = []
	_kb_btn_map = {}
	_joy_btn_map = {}
	_rebinding_action = ""
	_rebinding_btn = null
	_rebinding_is_joy = false
	_fps_lbl = null
	call_deferred("_build_ui")

# ─── Helper: make a toggle row with ON/OFF buttons ───────────────────────────

func _make_toggle_row(parent: Control, row_y: float, label_text: String, current_on: bool, on_cb: Callable, off_cb: Callable) -> void:
	var lbl = Label.new()
	lbl.position = Vector2(20, row_y + 8)
	lbl.size = Vector2(450, 36)
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	lbl.add_theme_font_size_override("font_size", 20)
	parent.add_child(lbl)

	var on_text = LocalizationManager.t("on_label")
	var off_text = LocalizationManager.t("off_label")

	var on_btn = Button.new()
	on_btn.text = on_text
	on_btn.position = Vector2(480, row_y + 4)
	on_btn.size = Vector2(80, 36)
	on_btn.add_theme_font_size_override("font_size", 16)
	parent.add_child(on_btn)

	var off_btn = Button.new()
	off_btn.text = off_text
	off_btn.position = Vector2(566, row_y + 4)
	off_btn.size = Vector2(80, 36)
	off_btn.add_theme_font_size_override("font_size", 16)
	parent.add_child(off_btn)

	var _apply_toggle_style = func(is_on: bool) -> void:
		var on_sty = StyleBoxFlat.new()
		if is_on:
			on_sty.bg_color = Color(0.1, 0.7, 0.2)
			on_sty.border_color = Color(0.3, 1.0, 0.4)
			on_sty.set_border_width_all(2)
		else:
			on_sty.bg_color = Color(0.08, 0.15, 0.08)
			on_sty.border_color = Color(0.2, 0.3, 0.2)
			on_sty.set_border_width_all(1)
		on_sty.set_corner_radius_all(4)
		on_btn.add_theme_stylebox_override("normal", on_sty)
		on_btn.add_theme_stylebox_override("hover", on_sty)
		on_btn.add_theme_color_override("font_color", Color.WHITE if is_on else Color(0.4, 0.4, 0.4))

		var off_sty = StyleBoxFlat.new()
		if not is_on:
			off_sty.bg_color = Color(0.6, 0.1, 0.1)
			off_sty.border_color = Color(1.0, 0.3, 0.3)
			off_sty.set_border_width_all(2)
		else:
			off_sty.bg_color = Color(0.15, 0.05, 0.05)
			off_sty.border_color = Color(0.3, 0.15, 0.15)
			off_sty.set_border_width_all(1)
		off_sty.set_corner_radius_all(4)
		off_btn.add_theme_stylebox_override("normal", off_sty)
		off_btn.add_theme_stylebox_override("hover", off_sty)
		off_btn.add_theme_color_override("font_color", Color.WHITE if not is_on else Color(0.4, 0.4, 0.4))

	_apply_toggle_style.call(current_on)

	on_btn.pressed.connect(func():
		on_cb.call()
		_apply_toggle_style.call(true)
	)
	off_btn.pressed.connect(func():
		off_cb.call()
		_apply_toggle_style.call(false)
	)

	# Separator
	var sep = ColorRect.new()
	sep.position = Vector2(0, row_y + 58)
	sep.size = Vector2(1220, 2)
	sep.color = Color(1.0, 0.85, 0.2, 0.3)
	parent.add_child(sep)

# ─── Helper: make a styled button ────────────────────────────────────────────

func _make_styled_btn(text: String, col: Color, active: bool) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 15)
	var sty = StyleBoxFlat.new()
	if active:
		sty.bg_color = col.lightened(0.2)
		sty.border_color = col.lightened(0.5)
		sty.set_border_width_all(2)
	else:
		sty.bg_color = col.darkened(0.6)
		sty.border_color = col.darkened(0.2)
		sty.set_border_width_all(1)
	sty.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sty)
	btn.add_theme_color_override("font_color", Color.WHITE if active else Color(0.55, 0.55, 0.55))
	return btn

# ─── GRAPHICS PANEL ──────────────────────────────────────────────────────────

func _build_graphics_panel(p: Control) -> void:
	var row_ys = [20.0, 90.0, 160.0, 230.0, 310.0]

	# Row 0: Fullscreen
	var is_fs = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_make_toggle_row(p, row_ys[0], LocalizationManager.t("fullscreen"), is_fs,
		func():
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			SaveManager.set_setting("fullscreen", true),
		func():
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			SaveManager.set_setting("fullscreen", false)
	)

	# Row 1: VSync
	var is_vsync = DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED
	_make_toggle_row(p, row_ys[1], LocalizationManager.t("vsync"), is_vsync,
		func():
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			SaveManager.set_setting("vsync", true),
		func():
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			SaveManager.set_setting("vsync", false)
	)

	# Row 2: Screen Shake
	var shake_on = SaveManager.get_setting("screen_shake")
	if shake_on == null:
		shake_on = true
	_make_toggle_row(p, row_ys[2], LocalizationManager.t("screen_shake"), bool(shake_on),
		func(): SaveManager.set_setting("screen_shake", true),
		func(): SaveManager.set_setting("screen_shake", false)
	)

	# Row 3: Show FPS
	var fps_on = SaveManager.get_setting("show_fps")
	if fps_on == null:
		fps_on = false
	_make_toggle_row(p, row_ys[3], LocalizationManager.t("show_fps"), bool(fps_on),
		func(): SaveManager.set_setting("show_fps", true),
		func(): SaveManager.set_setting("show_fps", false)
	)

	# FPS label (top-right corner of the screen)
	if _fps_lbl == null or not is_instance_valid(_fps_lbl):
		_fps_lbl = Label.new()
		_fps_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_fps_lbl.offset_left = -120.0
		_fps_lbl.offset_bottom = 30.0
		_fps_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.5))
		_fps_lbl.add_theme_font_size_override("font_size", 16)
		_fps_lbl.text = ""
		add_child(_fps_lbl)

	# Row 4: Particle quality - multi-option selector
	var particles_lbl = Label.new()
	particles_lbl.position = Vector2(20, row_ys[4] + 8)
	particles_lbl.size = Vector2(450, 36)
	particles_lbl.text = LocalizationManager.t("particles")
	particles_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	particles_lbl.add_theme_font_size_override("font_size", 20)
	p.add_child(particles_lbl)

	var particle_options = [
		{"key": "q_high",   "value": "high"},
		{"key": "q_medium", "value": "medium"},
		{"key": "q_low",    "value": "low"},
		{"key": "q_off",    "value": "off"},
	]
	var current_particles = SaveManager.get_setting("particles")
	if current_particles == null:
		current_particles = "high"

	var q_btns: Array = []
	var btn_x: float = 480.0
	var q_btn_w: float = 120.0
	var q_gap: float = 4.0
	var base_col = Color(0.3, 0.3, 0.5)

	for i in range(particle_options.size()):
		var opt = particle_options[i]
		var is_active = (current_particles == opt["value"])
		var q_btn = _make_styled_btn(LocalizationManager.t(opt["key"]), base_col, is_active)
		q_btn.position = Vector2(btn_x + i * (q_btn_w + q_gap), row_ys[4] + 4)
		q_btn.size = Vector2(q_btn_w, 36)
		p.add_child(q_btn)
		q_btns.append(q_btn)

	for i in range(q_btns.size()):
		var opt = particle_options[i]
		var btn_ref = q_btns[i]
		btn_ref.pressed.connect(func():
			SaveManager.set_setting("particles", opt["value"])
			for j in range(q_btns.size()):
				var qb = q_btns[j]
				var active_j = (particle_options[j]["value"] == opt["value"])
				var sty = StyleBoxFlat.new()
				if active_j:
					sty.bg_color = base_col.lightened(0.2)
					sty.border_color = base_col.lightened(0.5)
					sty.set_border_width_all(2)
				else:
					sty.bg_color = base_col.darkened(0.6)
					sty.border_color = base_col.darkened(0.2)
					sty.set_border_width_all(1)
				sty.set_corner_radius_all(4)
				qb.add_theme_stylebox_override("normal", sty)
				qb.add_theme_color_override("font_color", Color.WHITE if active_j else Color(0.55, 0.55, 0.55))
		)

# ─── SOUND PANEL ─────────────────────────────────────────────────────────────

func _build_sound_panel(p: Control) -> void:
	var channels = [
		{"label_key": "master_vol", "bus": "Master", "setting": "master_vol"},
		{"label_key": "music_vol",  "bus": "Music",  "setting": "music_vol"},
		{"label_key": "sfx_vol",    "bus": "SFX",    "setting": "sfx_vol"},
	]
	var row_ys = [40.0, 140.0, 240.0]

	for i in range(channels.size()):
		var ch = channels[i]
		var row_y = row_ys[i]
		var bus_idx = AudioServer.get_bus_index(ch["bus"])
		var cur_linear: float
		if bus_idx >= 0:
			cur_linear = clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_idx)), 0.0, 1.0)
		else:
			cur_linear = SaveManager.save_data["settings"].get(ch["setting"], 1.0)

		# Label
		var lbl = Label.new()
		lbl.position = Vector2(20, row_y)
		lbl.size = Vector2(350, 30)
		lbl.text = LocalizationManager.t(ch["label_key"])
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		lbl.add_theme_font_size_override("font_size", 20)
		p.add_child(lbl)

		# Percentage label
		var pct_lbl = Label.new()
		pct_lbl.position = Vector2(1010, row_y)
		pct_lbl.size = Vector2(60, 30)
		pct_lbl.text = str(int(cur_linear * 100)) + "%"
		pct_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		pct_lbl.add_theme_font_size_override("font_size", 18)
		p.add_child(pct_lbl)

		# Mute indicator circle (drawn via ColorRect approximation)
		var mute_indicator = ColorRect.new()
		mute_indicator.position = Vector2(1082, row_y + 4)
		mute_indicator.size = Vector2(28, 28)
		var is_muted = AudioServer.is_bus_mute(bus_idx) if bus_idx >= 0 else false
		mute_indicator.color = Color(0.2, 0.2, 0.2) if is_muted else Color(0.1, 0.8, 0.3)
		p.add_child(mute_indicator)

		# Slider
		var slider = HSlider.new()
		slider.position = Vector2(380, row_y + 4)
		slider.size = Vector2(620, 28)
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.02
		slider.value = cur_linear
		p.add_child(slider)

		# Capture closure vars
		var bus_name = ch["bus"]
		var setting_key = ch["setting"]
		var pct_ref = pct_lbl
		var mute_ref = mute_indicator

		slider.value_changed.connect(func(val: float):
			var b_idx = AudioServer.get_bus_index(bus_name)
			AudioServer.set_bus_volume_db(b_idx, linear_to_db(val))
			SaveManager.set_setting(setting_key, val)
			pct_ref.text = str(int(val * 100)) + "%"
			mute_ref.color = Color(0.2, 0.2, 0.2) if val <= 0.0 else Color(0.1, 0.8, 0.3)
		)

	# Tip label
	var tip = Label.new()
	tip.position = Vector2(20, 360)
	tip.size = Vector2(1180, 30)
	tip.text = "Tipp: Lautstärke auch mit F1/F2 im Spiel änderbar."
	tip.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	tip.add_theme_font_size_override("font_size", 14)
	p.add_child(tip)

# ─── GAMEPLAY PANEL ───────────────────────────────────────────────────────────

func _build_gameplay_panel(p: Control) -> void:
	# Left column container
	var left_col = Control.new()
	left_col.position = Vector2(20, 0)
	left_col.size = Vector2(600, 500)
	p.add_child(left_col)

	# Right column container
	var right_col = Control.new()
	right_col.position = Vector2(640, 0)
	right_col.size = Vector2(560, 500)
	p.add_child(right_col)

	# ── Left: Keyboard bindings ──
	var kb_header = Label.new()
	kb_header.position = Vector2(0, 10)
	kb_header.size = Vector2(580, 30)
	kb_header.text = LocalizationManager.t("kb_controls")
	kb_header.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
	kb_header.add_theme_font_size_override("font_size", 18)
	left_col.add_child(kb_header)

	var action_rows = [
		{"action": "move_up",    "label_key": "act_move_up"},
		{"action": "move_down",  "label_key": "act_move_down"},
		{"action": "move_left",  "label_key": "act_move_left"},
		{"action": "move_right", "label_key": "act_move_right"},
		{"action": "attack",     "label_key": "act_attack"},
		{"action": "ultimate",   "label_key": "act_special"},
		{"action": "ui_cancel",  "label_key": "act_pause"},
	]

	for i in range(action_rows.size()):
		var row_data = action_rows[i]
		var row_y = 42.0 + i * 58.0
		var action = row_data["action"]

		# Action label
		var act_lbl = Label.new()
		act_lbl.position = Vector2(0, row_y)
		act_lbl.size = Vector2(200, 30)
		act_lbl.text = LocalizationManager.t(row_data["label_key"])
		act_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		act_lbl.add_theme_font_size_override("font_size", 16)
		left_col.add_child(act_lbl)

		# Key display button
		var key_btn = Button.new()
		key_btn.position = Vector2(210, row_y)
		key_btn.size = Vector2(160, 40)
		key_btn.text = _get_key_display(action)
		key_btn.add_theme_font_size_override("font_size", 15)
		var key_sty = StyleBoxFlat.new()
		key_sty.bg_color = Color(0.1, 0.08, 0.15)
		key_sty.border_color = Color(1.0, 0.85, 0.2)
		key_sty.set_border_width_all(2)
		key_sty.set_corner_radius_all(4)
		key_btn.add_theme_stylebox_override("normal", key_sty)
		key_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		left_col.add_child(key_btn)
		_kb_btn_map[action] = key_btn

		# Rebind hint
		var hint_lbl = Label.new()
		hint_lbl.position = Vector2(380, row_y + 8)
		hint_lbl.size = Vector2(120, 24)
		hint_lbl.text = LocalizationManager.t("click_rebind")
		hint_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		hint_lbl.add_theme_font_size_override("font_size", 11)
		left_col.add_child(hint_lbl)

		var act_capture = action
		var btn_capture = key_btn
		key_btn.pressed.connect(func(): _start_rebind(act_capture, btn_capture))

	# ── Right: Controller Belegung ──
	var ctrl_header = Label.new()
	ctrl_header.position = Vector2(0, 10)
	ctrl_header.size = Vector2(540, 26)
	ctrl_header.text = LocalizationManager.t("ctrl_controls")
	ctrl_header.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
	ctrl_header.add_theme_font_size_override("font_size", 18)
	right_col.add_child(ctrl_header)

	# Deadzone
	var dz_lbl = Label.new()
	dz_lbl.position = Vector2(0, 40)
	dz_lbl.size = Vector2(140, 26)
	dz_lbl.text = LocalizationManager.t("deadzone")
	dz_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	dz_lbl.add_theme_font_size_override("font_size", 14)
	right_col.add_child(dz_lbl)

	var dz_val = SaveManager.get_setting("controller_deadzone")
	if dz_val == null:
		dz_val = 0.15

	var dz_pct_lbl = Label.new()
	dz_pct_lbl.position = Vector2(440, 40)
	dz_pct_lbl.size = Vector2(60, 26)
	dz_pct_lbl.text = str(int(float(dz_val) * 100)) + "%"
	dz_pct_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	dz_pct_lbl.add_theme_font_size_override("font_size", 14)
	right_col.add_child(dz_pct_lbl)

	var dz_slider = HSlider.new()
	dz_slider.position = Vector2(148, 42)
	dz_slider.size = Vector2(285, 26)
	dz_slider.min_value = 0.05
	dz_slider.max_value = 0.5
	dz_slider.step = 0.01
	dz_slider.value = float(dz_val)
	right_col.add_child(dz_slider)
	var dz_pct_ref = dz_pct_lbl
	dz_slider.value_changed.connect(func(val: float):
		SaveManager.set_setting("controller_deadzone", val)
		dz_pct_ref.text = str(int(val * 100)) + "%"
	)

	# Controller Rebind-Zeilen
	var ctrl_actions = [
		{"action": "move_up",    "label_key": "act_move_up"},
		{"action": "move_down",  "label_key": "act_move_down"},
		{"action": "move_left",  "label_key": "act_move_left"},
		{"action": "move_right", "label_key": "act_move_right"},
		{"action": "attack",     "label_key": "act_attack"},
		{"action": "ultimate",   "label_key": "act_special"},
		{"action": "ui_cancel",  "label_key": "act_pause"},
	]

	for i in range(ctrl_actions.size()):
		var row_data = ctrl_actions[i]
		var row_y = 74.0 + i * 48.0
		var action = row_data["action"]

		var act_lbl = Label.new()
		act_lbl.position = Vector2(0, row_y + 6)
		act_lbl.size = Vector2(175, 26)
		act_lbl.text = LocalizationManager.t(row_data["label_key"])
		act_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		act_lbl.add_theme_font_size_override("font_size", 15)
		right_col.add_child(act_lbl)

		var joy_btn = Button.new()
		joy_btn.position = Vector2(182, row_y)
		joy_btn.size = Vector2(200, 36)
		joy_btn.text = _get_joy_display(action)
		joy_btn.add_theme_font_size_override("font_size", 13)
		var joy_sty = StyleBoxFlat.new()
		joy_sty.bg_color = Color(0.08, 0.12, 0.20)
		joy_sty.border_color = Color(0.3, 0.6, 1.0)
		joy_sty.set_border_width_all(2)
		joy_sty.set_corner_radius_all(4)
		joy_btn.add_theme_stylebox_override("normal", joy_sty)
		joy_btn.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		right_col.add_child(joy_btn)
		_joy_btn_map[action] = joy_btn

		var hint_lbl = Label.new()
		hint_lbl.position = Vector2(390, row_y + 9)
		hint_lbl.size = Vector2(160, 20)
		hint_lbl.text = "Knopf drücken"
		hint_lbl.add_theme_color_override("font_color", Color(0.38, 0.38, 0.38))
		hint_lbl.add_theme_font_size_override("font_size", 11)
		right_col.add_child(hint_lbl)

		var act_capture = action
		var btn_capture = joy_btn
		joy_btn.pressed.connect(func(): _start_rebind(act_capture, btn_capture, true))

	# Reset-Buttons Zeile
	var reset_row_y = 74.0 + ctrl_actions.size() * 48.0 + 6.0

	var reset_kb_btn = Button.new()
	reset_kb_btn.position = Vector2(0, reset_row_y)
	reset_kb_btn.size = Vector2(220, 36)
	reset_kb_btn.text = LocalizationManager.t("reset_keys")
	reset_kb_btn.add_theme_font_size_override("font_size", 13)
	reset_kb_btn.add_theme_color_override("font_color", Color.WHITE)
	var rkb_sty = StyleBoxFlat.new()
	rkb_sty.bg_color = Color(0.45, 0.28, 0.0)
	rkb_sty.border_color = Color(1.0, 0.7, 0.1)
	rkb_sty.set_border_width_all(2)
	rkb_sty.set_corner_radius_all(5)
	reset_kb_btn.add_theme_stylebox_override("normal", rkb_sty)
	reset_kb_btn.pressed.connect(_reset_keybindings)
	right_col.add_child(reset_kb_btn)

	var reset_joy_btn = Button.new()
	reset_joy_btn.position = Vector2(228, reset_row_y)
	reset_joy_btn.size = Vector2(220, 36)
	reset_joy_btn.text = "Controller zurücksetzen"
	reset_joy_btn.add_theme_font_size_override("font_size", 13)
	reset_joy_btn.add_theme_color_override("font_color", Color.WHITE)
	var rjoy_sty = StyleBoxFlat.new()
	rjoy_sty.bg_color = Color(0.10, 0.22, 0.45)
	rjoy_sty.border_color = Color(0.3, 0.6, 1.0)
	rjoy_sty.set_border_width_all(2)
	rjoy_sty.set_corner_radius_all(5)
	reset_joy_btn.add_theme_stylebox_override("normal", rjoy_sty)
	reset_joy_btn.pressed.connect(_reset_joy_bindings)
	right_col.add_child(reset_joy_btn)

	# Highscore-Reset (linke Spalte, unterhalb Keyboard-Bindings)
	var hs_lbl = Label.new()
	hs_lbl.position = Vector2(0, 434)
	hs_lbl.size = Vector2(580, 22)
	hs_lbl.text = "Highscore: %d  |  Beste Wave: %d" % [SaveManager.get_high_score(), SaveManager.save_data.get("best_wave", 0)]
	hs_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hs_lbl.add_theme_font_size_override("font_size", 13)
	left_col.add_child(hs_lbl)

	var hs_btn = Button.new()
	hs_btn.position = Vector2(0, 458)
	hs_btn.size = Vector2(280, 36)
	hs_btn.text = "Highscore zurücksetzen"
	hs_btn.add_theme_font_size_override("font_size", 14)
	hs_btn.add_theme_color_override("font_color", Color.WHITE)
	var hs_sty = StyleBoxFlat.new()
	hs_sty.bg_color = Color(0.45, 0.05, 0.05)
	hs_sty.border_color = Color(0.9, 0.2, 0.2)
	hs_sty.set_border_width_all(2)
	hs_sty.set_corner_radius_all(5)
	hs_btn.add_theme_stylebox_override("normal", hs_sty)
	var hs_sty_h = StyleBoxFlat.new()
	hs_sty_h.bg_color = Color(0.6, 0.08, 0.08)
	hs_sty_h.set_corner_radius_all(5)
	hs_btn.add_theme_stylebox_override("hover", hs_sty_h)
	left_col.add_child(hs_btn)

	hs_btn.set_meta("confirm_pending", false)
	var hs_lbl_ref = hs_lbl
	hs_btn.pressed.connect(func():
		if not hs_btn.get_meta("confirm_pending"):
			hs_btn.set_meta("confirm_pending", true)
			hs_btn.text = "Sicher? Nochmal klicken!"
			var confirm_sty = StyleBoxFlat.new()
			confirm_sty.bg_color = Color(0.7, 0.1, 0.1)
			confirm_sty.border_color = Color(1.0, 0.3, 0.3)
			confirm_sty.set_border_width_all(3)
			confirm_sty.set_corner_radius_all(5)
			hs_btn.add_theme_stylebox_override("normal", confirm_sty)
		else:
			SaveManager.reset_highscore()
			hs_btn.set_meta("confirm_pending", false)
			hs_btn.text = "✓ Zurückgesetzt"
			hs_lbl_ref.text = "Highscore: 0  |  Beste Wave: 0"
			var done_sty = StyleBoxFlat.new()
			done_sty.bg_color = Color(0.45, 0.05, 0.05)
			done_sty.border_color = Color(0.9, 0.2, 0.2)
			done_sty.set_border_width_all(2)
			done_sty.set_corner_radius_all(5)
			hs_btn.add_theme_stylebox_override("normal", done_sty)
	)

func _joy_button_name(idx: int) -> String:
	match idx:
		JOY_BUTTON_A:             return "A / Kreuz"
		JOY_BUTTON_B:             return "B / Kreis"
		JOY_BUTTON_X:             return "X / Quadrat"
		JOY_BUTTON_Y:             return "Y / Dreieck"
		JOY_BUTTON_LEFT_SHOULDER: return "LB / L1"
		JOY_BUTTON_RIGHT_SHOULDER:return "RB / R1"
		JOY_BUTTON_LEFT_STICK:    return "LS-Klick"
		JOY_BUTTON_RIGHT_STICK:   return "RS-Klick"
		JOY_BUTTON_START:         return "Start"
		JOY_BUTTON_BACK:          return "Select"
		JOY_BUTTON_DPAD_UP:       return "D-Pad ↑"
		JOY_BUTTON_DPAD_DOWN:     return "D-Pad ↓"
		JOY_BUTTON_DPAD_LEFT:     return "D-Pad ←"
		JOY_BUTTON_DPAD_RIGHT:    return "D-Pad →"
		_:                        return "Btn %d" % idx

func _get_joy_display(action: String) -> String:
	if not InputMap.has_action(action):
		return "—"
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton:
			return _joy_button_name(ev.button_index)
		if ev is InputEventJoypadMotion:
			var axis_names = ["LStick X", "LStick Y", "RStick X", "RStick Y", "LT", "RT"]
			var aname = axis_names[ev.axis] if ev.axis < axis_names.size() else "Axis%d" % ev.axis
			return aname + ("+" if ev.axis_value > 0 else "−")
	return "—"

func _start_rebind(action: String, btn: Button, is_joy: bool = false) -> void:
	# Alten ausstehenden Rebind abbrechen
	if _rebinding_btn != null and is_instance_valid(_rebinding_btn):
		if _rebinding_is_joy:
			var old_sty = StyleBoxFlat.new()
			old_sty.bg_color = Color(0.08, 0.12, 0.20)
			old_sty.border_color = Color(0.3, 0.6, 1.0)
			old_sty.set_border_width_all(2)
			old_sty.set_corner_radius_all(4)
			_rebinding_btn.add_theme_stylebox_override("normal", old_sty)
			_rebinding_btn.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
			_rebinding_btn.text = _get_joy_display(_rebinding_action)
		else:
			var old_sty = StyleBoxFlat.new()
			old_sty.bg_color = Color(0.1, 0.08, 0.15)
			old_sty.border_color = Color(1.0, 0.85, 0.2)
			old_sty.set_border_width_all(2)
			old_sty.set_corner_radius_all(4)
			_rebinding_btn.add_theme_stylebox_override("normal", old_sty)
			_rebinding_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
			_rebinding_btn.text = _get_key_display(_rebinding_action)

	_rebinding_action = action
	_rebinding_btn = btn
	_rebinding_is_joy = is_joy
	btn.text = "< drücken... >"

	var wait_sty = StyleBoxFlat.new()
	if is_joy:
		wait_sty.bg_color = Color(0.05, 0.18, 0.35)
		wait_sty.border_color = Color(0.4, 0.8, 1.0)
		wait_sty.set_border_width_all(3)
		wait_sty.set_corner_radius_all(4)
		btn.add_theme_color_override("font_color", Color(0.6, 1.0, 1.0))
	else:
		wait_sty.bg_color = Color(0.2, 0.15, 0.0)
		wait_sty.border_color = Color(1.0, 0.9, 0.0)
		wait_sty.set_border_width_all(3)
		wait_sty.set_corner_radius_all(4)
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	btn.add_theme_stylebox_override("normal", wait_sty)

func _get_key_display(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	var events = InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			return ev.as_text_key_label()
	return "?"

func _reset_keybindings() -> void:
	InputMap.load_from_project_settings()
	for action in _kb_btn_map:
		var btn = _kb_btn_map[action]
		if is_instance_valid(btn):
			btn.text = _get_key_display(action)

func _reset_joy_bindings() -> void:
	InputMap.load_from_project_settings()
	for action in _joy_btn_map:
		var btn = _joy_btn_map[action]
		if is_instance_valid(btn):
			btn.text = _get_joy_display(action)

func _input(event: InputEvent) -> void:
	if _rebinding_action == "":
		return

	if _rebinding_is_joy:
		# Controller-Rebind: wartet auf Joypad-Button oder Escape
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			if _rebinding_btn != null and is_instance_valid(_rebinding_btn):
				_rebinding_btn.text = _get_joy_display(_rebinding_action)
				var cancel_sty = StyleBoxFlat.new()
				cancel_sty.bg_color = Color(0.08, 0.12, 0.20)
				cancel_sty.border_color = Color(0.3, 0.6, 1.0)
				cancel_sty.set_border_width_all(2)
				cancel_sty.set_corner_radius_all(4)
				_rebinding_btn.add_theme_stylebox_override("normal", cancel_sty)
				_rebinding_btn.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
			_rebinding_action = ""
			_rebinding_btn = null
			get_viewport().set_input_as_handled()
		elif event is InputEventJoypadButton and event.pressed:
			# Alte Joypad-Bindings für diese Action entfernen, Keyboard behalten
			var existing = InputMap.action_get_events(_rebinding_action)
			for ev in existing:
				if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
					InputMap.action_erase_event(_rebinding_action, ev)
			InputMap.action_add_event(_rebinding_action, event)
			if _rebinding_btn != null and is_instance_valid(_rebinding_btn):
				_rebinding_btn.text = _joy_button_name(event.button_index)
				var done_sty = StyleBoxFlat.new()
				done_sty.bg_color = Color(0.08, 0.12, 0.20)
				done_sty.border_color = Color(0.3, 0.6, 1.0)
				done_sty.set_border_width_all(2)
				done_sty.set_corner_radius_all(4)
				_rebinding_btn.add_theme_stylebox_override("normal", done_sty)
				_rebinding_btn.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
			_rebinding_action = ""
			_rebinding_btn = null
			get_viewport().set_input_as_handled()
	else:
		# Keyboard-Rebind: wartet auf Taste oder Escape
		if event is InputEventKey and event.pressed and not event.is_echo():
			if event.keycode == KEY_ESCAPE:
				if _rebinding_btn != null and is_instance_valid(_rebinding_btn):
					_rebinding_btn.text = _get_key_display(_rebinding_action)
					var cancel_sty = StyleBoxFlat.new()
					cancel_sty.bg_color = Color(0.1, 0.08, 0.15)
					cancel_sty.border_color = Color(1.0, 0.85, 0.2)
					cancel_sty.set_border_width_all(2)
					cancel_sty.set_corner_radius_all(4)
					_rebinding_btn.add_theme_stylebox_override("normal", cancel_sty)
					_rebinding_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
			else:
				# Alte Keyboard-Bindings entfernen, Joypad behalten
				var existing = InputMap.action_get_events(_rebinding_action)
				for ev in existing:
					if ev is InputEventKey:
						InputMap.action_erase_event(_rebinding_action, ev)
				InputMap.action_add_event(_rebinding_action, event)
				if _rebinding_btn != null and is_instance_valid(_rebinding_btn):
					_rebinding_btn.text = _get_key_display(_rebinding_action)
					var done_sty = StyleBoxFlat.new()
					done_sty.bg_color = Color(0.1, 0.08, 0.15)
					done_sty.border_color = Color(1.0, 0.85, 0.2)
					done_sty.set_border_width_all(2)
					done_sty.set_corner_radius_all(4)
					_rebinding_btn.add_theme_stylebox_override("normal", done_sty)
					_rebinding_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
			_rebinding_action = ""
			_rebinding_btn = null
			get_viewport().set_input_as_handled()

# ─── LANGUAGE PANEL ───────────────────────────────────────────────────────────

func _build_language_panel(p: Control) -> void:
	# Title
	var title = Label.new()
	title.position = Vector2(0, 30)
	title.size = Vector2(1220, 40)
	title.text = LocalizationManager.t("lang_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.add_theme_font_size_override("font_size", 28)
	p.add_child(title)

	var lang_keys = ["de", "en", "fr", "es", "uk"]
	var lang_colors = {
		"de": Color(0.0, 0.2, 0.6),
		"en": Color(0.6, 0.0, 0.1),
		"fr": Color(0.0, 0.4, 0.1),
		"es": Color(0.7, 0.5, 0.0),
		"uk": Color(0.0, 0.35, 0.55),
	}

	var btn_w: float = 190.0
	var btn_h: float = 70.0
	var btn_gap: float = 16.0
	var total_w: float = lang_keys.size() * btn_w + (lang_keys.size() - 1) * btn_gap
	var start_x: float = (1220.0 - total_w) / 2.0
	var btn_y: float = 110.0
	var flag_y: float = btn_y + btn_h + 14.0

	var cur_lang = LocalizationManager.current_language

	for i in range(lang_keys.size()):
		var lang = lang_keys[i]
		var col = lang_colors[lang]
		var bx = start_x + i * (btn_w + btn_gap)
		var is_active = (lang == cur_lang)

		# Flag node above the button
		var flag_node = _make_flag_node(lang)
		flag_node.position = Vector2(bx + (btn_w - 50.0) / 2.0, btn_y - 46.0)
		flag_node.size = Vector2(50.0, 34.0)
		p.add_child(flag_node)

		# Language button
		var lang_btn = Button.new()
		lang_btn.position = Vector2(bx, btn_y)
		lang_btn.size = Vector2(btn_w, btn_h)
		lang_btn.add_theme_font_size_override("font_size", 18)
		p.add_child(lang_btn)

		var lang_name = LocalizationManager.LANGUAGES[lang]
		if is_active:
			lang_btn.text = lang_name + "\n" + LocalizationManager.t("lang_active")
			lang_btn.add_theme_color_override("font_color", Color.WHITE)
			var sty = StyleBoxFlat.new()
			sty.bg_color = col.lightened(0.3)
			sty.border_color = Color(1.0, 0.85, 0.2)
			sty.set_border_width_all(3)
			sty.set_corner_radius_all(6)
			lang_btn.add_theme_stylebox_override("normal", sty)
			lang_btn.add_theme_stylebox_override("hover", sty)
		else:
			lang_btn.text = lang_name
			lang_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			var sty = StyleBoxFlat.new()
			sty.bg_color = col.darkened(0.65)
			sty.border_color = col
			sty.set_border_width_all(2)
			sty.set_corner_radius_all(6)
			lang_btn.add_theme_stylebox_override("normal", sty)
			var sty_h = StyleBoxFlat.new()
			sty_h.bg_color = col.darkened(0.4)
			sty_h.set_corner_radius_all(6)
			lang_btn.add_theme_stylebox_override("hover", sty_h)

		var lang_capture = lang
		lang_btn.pressed.connect(func(): LocalizationManager.set_language(lang_capture))

	# Hint label
	var hint = Label.new()
	hint.position = Vector2(0, 220)
	hint.size = Vector2(1220, 30)
	hint.text = LocalizationManager.t("lang_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.add_theme_font_size_override("font_size", 15)
	p.add_child(hint)

func _make_flag_node(lang: String) -> Control:
	var flag = Control.new()
	flag.size = Vector2(50.0, 34.0)

	match lang:
		"de":
			# Black / Red / Gold horizontal stripes
			var s1 = ColorRect.new()
			s1.position = Vector2(0, 0)
			s1.size = Vector2(50, 11)
			s1.color = Color(0.05, 0.05, 0.05)
			flag.add_child(s1)
			var s2 = ColorRect.new()
			s2.position = Vector2(0, 11)
			s2.size = Vector2(50, 12)
			s2.color = Color(0.8, 0.1, 0.1)
			flag.add_child(s2)
			var s3 = ColorRect.new()
			s3.position = Vector2(0, 23)
			s3.size = Vector2(50, 11)
			s3.color = Color(1.0, 0.8, 0.0)
			flag.add_child(s3)
		"en":
			# Blue background with white/red cross (simplified Union Jack)
			var bg = ColorRect.new()
			bg.position = Vector2(0, 0)
			bg.size = Vector2(50, 34)
			bg.color = Color(0.0, 0.12, 0.5)
			flag.add_child(bg)
			# White horizontal bar
			var wh = ColorRect.new()
			wh.position = Vector2(0, 14)
			wh.size = Vector2(50, 6)
			wh.color = Color(1.0, 1.0, 1.0)
			flag.add_child(wh)
			# White vertical bar
			var wv = ColorRect.new()
			wv.position = Vector2(21, 0)
			wv.size = Vector2(8, 34)
			wv.color = Color(1.0, 1.0, 1.0)
			flag.add_child(wv)
			# Red horizontal bar
			var rh = ColorRect.new()
			rh.position = Vector2(0, 15)
			rh.size = Vector2(50, 4)
			rh.color = Color(0.8, 0.0, 0.0)
			flag.add_child(rh)
			# Red vertical bar
			var rv = ColorRect.new()
			rv.position = Vector2(23, 0)
			rv.size = Vector2(4, 34)
			rv.color = Color(0.8, 0.0, 0.0)
			flag.add_child(rv)
		"fr":
			# Blue / White / Red vertical stripes
			var c1 = ColorRect.new()
			c1.position = Vector2(0, 0)
			c1.size = Vector2(17, 34)
			c1.color = Color(0.0, 0.15, 0.6)
			flag.add_child(c1)
			var c2 = ColorRect.new()
			c2.position = Vector2(17, 0)
			c2.size = Vector2(16, 34)
			c2.color = Color(1.0, 1.0, 1.0)
			flag.add_child(c2)
			var c3 = ColorRect.new()
			c3.position = Vector2(33, 0)
			c3.size = Vector2(17, 34)
			c3.color = Color(0.8, 0.0, 0.0)
			flag.add_child(c3)
		"es":
			# Red / Yellow / Red horizontal stripes
			var e1 = ColorRect.new()
			e1.position = Vector2(0, 0)
			e1.size = Vector2(50, 9)
			e1.color = Color(0.75, 0.0, 0.1)
			flag.add_child(e1)
			var e2 = ColorRect.new()
			e2.position = Vector2(0, 9)
			e2.size = Vector2(50, 16)
			e2.color = Color(1.0, 0.75, 0.0)
			flag.add_child(e2)
			var e3 = ColorRect.new()
			e3.position = Vector2(0, 25)
			e3.size = Vector2(50, 9)
			e3.color = Color(0.75, 0.0, 0.1)
			flag.add_child(e3)
		"uk":
			# Blue / Yellow horizontal stripes
			var u1 = ColorRect.new()
			u1.position = Vector2(0, 0)
			u1.size = Vector2(50, 17)
			u1.color = Color(0.0, 0.3, 0.8)
			flag.add_child(u1)
			var u2 = ColorRect.new()
			u2.position = Vector2(0, 17)
			u2.size = Vector2(50, 17)
			u2.color = Color(1.0, 0.8, 0.0)
			flag.add_child(u2)

	return flag
