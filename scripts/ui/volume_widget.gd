extends Control
# Kleines Lautstärke-Panel – kann in jede Szene eingebettet werden
# Wird als CanvasLayer-Child gespawnt, damit es immer im Vordergrund bleibt

var _slider: HSlider
var _mute_btn: Button
var _proj_sfx_btn: Button
var _song_label: Label
var _panel: PanelContainer
var _visible_panel: bool = false

func _ready() -> void:
	_build()
	AudioManager.connect("song_changed", _on_song_changed)

func _build() -> void:
	# Root-Control darf keine Mausklicks blockieren – nur Kinder fangen ein
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Toggle-Button (immer sichtbar, oben rechts)
	var toggle = Button.new()
	toggle.name = "ToggleBtn"
	toggle.text = "M"
	toggle.set_anchors_preset(PRESET_TOP_RIGHT)
	toggle.anchor_left = 1.0
	toggle.anchor_right = 1.0
	toggle.position = Vector2(-54, 10)
	toggle.size = Vector2(44, 44)
	toggle.add_theme_font_size_override("font_size", 20)
	toggle.pressed.connect(_toggle_panel)
	var sty = StyleBoxFlat.new()
	sty.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	sty.border_color = Color(0.5, 0.5, 0.7)
	sty.set_border_width_all(1)
	sty.set_corner_radius_all(6)
	toggle.add_theme_stylebox_override("normal", sty)
	add_child(toggle)

	# Panel (ein-/ausklappbar)
	_panel = PanelContainer.new()
	_panel.name = "VolumePanel"
	_panel.set_anchors_preset(PRESET_TOP_RIGHT)
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.position = Vector2(-270, 60)
	_panel.size = Vector2(260, 165)
	_panel.visible = false

	var panel_sty = StyleBoxFlat.new()
	panel_sty.bg_color = Color(0.06, 0.05, 0.12, 0.93)
	panel_sty.border_color = Color(0.4, 0.3, 0.7)
	panel_sty.set_border_width_all(2)
	panel_sty.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", panel_sty)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	_panel.add_child(vbox)

	# Song-Titel
	_song_label = Label.new()
	_song_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var current = AudioManager.get_current_song_title()
	_song_label.text = current if current != "" else "-- kein Song --"
	_song_label.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
	_song_label.add_theme_font_size_override("font_size", 13)
	_song_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_song_label)

	# Lautstärke-Zeile
	var vol_row = HBoxContainer.new()
	vol_row.set("theme_override_constants/separation", 6)
	vbox.add_child(vol_row)

	var vol_lbl = Label.new()
	vol_lbl.text = "Vol"
	vol_lbl.custom_minimum_size = Vector2(28, 0)
	vol_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	vol_lbl.add_theme_font_size_override("font_size", 14)
	vol_row.add_child(vol_lbl)

	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.01
	_slider.value = AudioManager.get_music_volume()
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.value_changed.connect(_on_volume_changed)
	vol_row.add_child(_slider)

	# Mute-Button
	_mute_btn = Button.new()
	_mute_btn.text = "AN" if AudioManager.get_music_enabled() else "AUS"
	_mute_btn.custom_minimum_size = Vector2(44, 0)
	_mute_btn.add_theme_font_size_override("font_size", 13)
	_mute_btn.pressed.connect(_on_mute_toggled)
	vol_row.add_child(_mute_btn)

	# Projektil-SFX Zeile
	var sfx_row = HBoxContainer.new()
	sfx_row.set("theme_override_constants/separation", 6)
	vbox.add_child(sfx_row)

	var sfx_lbl = Label.new()
	sfx_lbl.text = "Proj-SFX"
	sfx_lbl.custom_minimum_size = Vector2(68, 0)
	sfx_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	sfx_lbl.add_theme_font_size_override("font_size", 13)
	sfx_row.add_child(sfx_lbl)

	_proj_sfx_btn = Button.new()
	_proj_sfx_btn.text = "AN" if AudioManager.get_proj_sfx_enabled() else "AUS"
	_proj_sfx_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_proj_sfx_btn.add_theme_font_size_override("font_size", 13)
	_proj_sfx_btn.pressed.connect(_on_proj_sfx_toggled)
	sfx_row.add_child(_proj_sfx_btn)

	# Nächster Song-Button
	var next_row = HBoxContainer.new()
	next_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(next_row)

	var next_btn = Button.new()
	next_btn.text = ">> Naechster Song"
	next_btn.add_theme_font_size_override("font_size", 13)
	next_btn.pressed.connect(AudioManager.next_song)
	next_row.add_child(next_btn)

	add_child(_panel)

func _toggle_panel() -> void:
	_visible_panel = not _visible_panel
	_panel.visible = _visible_panel
	if _visible_panel:
		var current = AudioManager.get_current_song_title()
		_song_label.text = current if current != "" else "-- kein Song --"
		_slider.value = AudioManager.get_music_volume()
		_mute_btn.text = "AN" if AudioManager.get_music_enabled() else "AUS"
		_proj_sfx_btn.text = "AN" if AudioManager.get_proj_sfx_enabled() else "AUS"

func _on_volume_changed(val: float) -> void:
	AudioManager.set_music_volume(val)
	AudioManager.set_music_enabled(val > 0.0)
	_mute_btn.text = "AN" if val > 0.0 else "AUS"

func _on_mute_toggled() -> void:
	var enabled = not AudioManager.get_music_enabled()
	AudioManager.set_music_enabled(enabled)
	_mute_btn.text = "AN" if enabled else "AUS"
	if enabled:
		_slider.value = max(AudioManager.get_music_volume(), 0.1)

func _on_proj_sfx_toggled() -> void:
	var enabled = not AudioManager.get_proj_sfx_enabled()
	AudioManager.set_proj_sfx_enabled(enabled)
	_proj_sfx_btn.text = "AN" if enabled else "AUS"

func _on_song_changed(title: String) -> void:
	if is_instance_valid(_song_label):
		_song_label.text = title if title != "" else "-- kein Song --"
