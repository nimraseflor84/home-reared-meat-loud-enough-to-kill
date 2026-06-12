extends Control

# Scrolling credits scene.
# Slow upward scroll. ESC / ui_cancel returns to main menu.

const SCROLL_SPEED: float = 50.0  # pixels per second

const CREDITS: Array = [
	{"type": "title",    "text": "HOME REARED MEAT"},
	{"type": "subtitle", "text": "LOUD ENOUGH TO KILL"},
	{"type": "space"},
	{"type": "space"},

	{"type": "section", "text": "GAME DESIGN & PROGRAMMING"},
	{"type": "name",    "text": "Armin Rolfes"},
	{"type": "space"},

	{"type": "section", "text": "ART & ANIMATION"},
	{"type": "name",    "text": "Armin Rolfes"},
	{"type": "space"},

	{"type": "section", "text": "MUSIC & SOUND"},
	{"type": "name",    "text": "Armin Rolfes"},
	{"type": "name",    "text": "Royalty-free metal samples"},
	{"type": "space"},

	{"type": "section", "text": "CHARACTERS"},
	{"type": "name",    "text": "Manni"},
	{"type": "name",    "text": "The Shouter"},
	{"type": "name",    "text": "Dreads"},
	{"type": "name",    "text": "Riff Slicer"},
	{"type": "name",    "text": "Distortion"},
	{"type": "name",    "text": "The Bassist"},
	{"type": "space"},

	{"type": "section", "text": "ENGINE"},
	{"type": "name",    "text": "Godot 4.6"},
	{"type": "space"},

	{"type": "section", "text": "SPECIAL THANKS"},
	{"type": "name",    "text": "The metal community"},
	{"type": "name",    "text": "Every playtester who survived"},
	{"type": "name",    "text": "AUTODOC SE"},
	{"type": "name",    "text": "Claude, OpenAI, Gemini"},
	{"type": "space"},
	{"type": "space"},

	{"type": "subtitle", "text": "THANKS FOR PLAYING"},
	{"type": "space"},
	{"type": "name",    "text": "(C) 2026 Armin Rolfes"},
	{"type": "space"},
	{"type": "space"},
	{"type": "space"},
]

var _font_big: Font = null
var _font_md: Font = null
var _font_sm: Font = null
var _scroll_container: Control = null
var _content: VBoxContainer = null
var _back_btn: Button = null
var _scroll_offset: float = 0.0
var _content_height: float = 0.0


func _ready() -> void:
	_build_fonts()
	_build_ui()
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Start the scroll just below the viewport
	_scroll_offset = -get_viewport_rect().size.y
	_apply_scroll()


func _build_fonts() -> void:
	var f_big := SystemFont.new()
	f_big.font_names = PackedStringArray(["Impact", "Arial Black", "Arial"])
	f_big.font_weight = 900
	f_big.font_italic = true
	_font_big = f_big

	var f_md := SystemFont.new()
	f_md.font_names = PackedStringArray(["Impact", "Arial Black", "Arial"])
	f_md.font_weight = 900
	f_md.font_italic = true
	_font_md = f_md

	var f_sm := SystemFont.new()
	f_sm.font_names = PackedStringArray(["Impact", "Arial Black", "Arial"])
	f_sm.font_weight = 700
	f_sm.font_italic = false
	_font_sm = f_sm


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.04, 1.0)
	add_child(bg)

	# Red faint background gradient stripe in the middle
	var stripe := ColorRect.new()
	stripe.set_anchors_preset(Control.PRESET_FULL_RECT)
	stripe.color = Color(0.45, 0.05, 0.08, 0.10)
	stripe.anchor_top = 0.45
	stripe.anchor_bottom = 0.55
	add_child(stripe)

	# Scrolling content container
	_scroll_container = Control.new()
	_scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll_container.clip_contents = true
	add_child(_scroll_container)

	_content = VBoxContainer.new()
	_content.anchor_left = 0.0
	_content.anchor_right = 1.0
	_content.anchor_top = 0.0
	_content.anchor_bottom = 0.0
	_content.offset_left = 0.0
	_content.offset_right = 0.0
	_content.add_theme_constant_override("separation", 14)
	_scroll_container.add_child(_content)

	for entry in CREDITS:
		_content.add_child(_make_entry(entry))

	# After all children added, compute height once layout is done.
	_content.call_deferred("custom_minimum_size")
	_content.size_changed.connect(_recompute_height)

	# Skip / back button (always visible)
	_back_btn = Button.new()
	_back_btn.text = LocalizationManager.t("back")
	_back_btn.add_theme_font_override("font", _font_md)
	_back_btn.add_theme_font_size_override("font_size", 22)
	_back_btn.add_theme_color_override("font_color", Color.WHITE)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.65, 0.10, 0.10).darkened(0.35)
	sty.border_color = Color(0.65, 0.10, 0.10)
	sty.set_border_width_all(2)
	sty.set_corner_radius_all(6)
	_back_btn.add_theme_stylebox_override("normal", sty)
	var sty_h := StyleBoxFlat.new()
	sty_h.bg_color = Color(0.65, 0.10, 0.10).lightened(0.15)
	sty_h.set_corner_radius_all(6)
	_back_btn.add_theme_stylebox_override("hover", sty_h)
	_back_btn.anchor_left = 0.0
	_back_btn.anchor_right = 0.0
	_back_btn.anchor_top = 0.0
	_back_btn.anchor_bottom = 0.0
	_back_btn.offset_left = 24.0
	_back_btn.offset_top = 24.0
	_back_btn.offset_right = 160.0
	_back_btn.offset_bottom = 64.0
	_back_btn.pressed.connect(_on_back_pressed)
	add_child(_back_btn)

	# Hint label
	var hint := Label.new()
	hint.text = "ESC / B"
	hint.add_theme_font_override("font", _font_sm)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.anchor_left = 0.0
	hint.anchor_right = 0.0
	hint.anchor_top = 0.0
	hint.anchor_bottom = 0.0
	hint.offset_left = 24.0
	hint.offset_top = 70.0
	hint.offset_right = 200.0
	hint.offset_bottom = 96.0
	add_child(hint)


func _make_entry(entry: Dictionary) -> Control:
	var t: String = String(entry.get("type", "name"))
	if t == "space":
		var c := Control.new()
		c.custom_minimum_size = Vector2(0, 40)
		return c
	var label := Label.new()
	label.text = String(entry.get("text", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	match t:
		"title":
			label.add_theme_font_override("font", _font_big)
			label.add_theme_font_size_override("font_size", 96)
			label.add_theme_color_override("font_color", Color(0.95, 0.10, 0.12))
			label.add_theme_constant_override("outline_size", 6)
		"subtitle":
			label.add_theme_font_override("font", _font_md)
			label.add_theme_font_size_override("font_size", 48)
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_constant_override("outline_size", 5)
		"section":
			label.add_theme_font_override("font", _font_md)
			label.add_theme_font_size_override("font_size", 32)
			label.add_theme_color_override("font_color", Color(0.95, 0.10, 0.12))
		"name", _:
			label.add_theme_font_override("font", _font_sm)
			label.add_theme_font_size_override("font_size", 26)
			label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	return label


func _recompute_height() -> void:
	_content_height = _content.size.y


func _process(delta: float) -> void:
	_scroll_offset += SCROLL_SPEED * delta
	# When content has fully scrolled past the top, exit back to the menu.
	if _content_height <= 0.0 and _content.size.y > 0.0:
		_content_height = _content.size.y
	if _content_height > 0.0 and _scroll_offset > _content_height + 200.0:
		_on_back_pressed()
		return
	_apply_scroll()


func _apply_scroll() -> void:
	if _content:
		_content.position.y = -_scroll_offset


func _on_back_pressed() -> void:
	GameManager.go_to_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
		return
	# Speed up scroll while holding down
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
		_scroll_offset += 200.0
		get_viewport().set_input_as_handled()
