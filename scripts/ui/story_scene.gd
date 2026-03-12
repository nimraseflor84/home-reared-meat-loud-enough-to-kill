extends Control

# Story scene detects which act it is from its file path
# No complex data needed in .tscn files

var act_title: String = ""
var slides: Array = []
var next_scene: String = "res://scenes/game.tscn"

var _current_slide: int = 0
var _anim_time: float = 0.0
var _text_reveal: float = 0.0
var _advance_ready: bool = false
var _auto_timer: float = 0.0
const AUTO_ADVANCE_SEC = 12.0

func _ready() -> void:
	_load_act_data()
	_build_ui()

func _load_act_data() -> void:
	var path = scene_file_path
	if "act1" in path:
		act_title = "ACT I — DIE ERSTE PROBE"
		next_scene = "res://scenes/game.tscn"
		slides = [
			{"text": "Es begann wie jede andere Band-Probe.\n\nSechs Musiker. Ein Keller. Zu viel Energie.", "bg_color": Color(0.05, 0.03, 0.12)},
			{"text": "Dann spielten sie den Akkord.\n\nDen einen Akkord, der alles veränderte.\n\nDie Schallwellen mutierten. Wurden lebendig.", "bg_color": Color(0.1, 0.02, 0.05)},
			{"text": "Stille-Wesen – einst Konzertbesucher –\nkrochen aus den Lautsprechern.\n\nHungernd nach Musik. Hungernd nach Blut.", "bg_color": Color(0.07, 0.04, 0.1)},
			{"text": "Es gibt nur einen Weg zu überleben:\n\nSpiele lauter als die Apokalypse.", "bg_color": Color(0.02, 0.08, 0.02)},
		]
	elif "act2" in path:
		act_title = "ACT II — TOUR DURCH DIE APOKALYPSE"
		next_scene = "res://scenes/game.tscn"
		slides = [
			{"text": "Fünf Wellen überlebt. Die Stadt liegt in Trümmern.\n\nAber die Band spielt weiter.", "bg_color": Color(0.08, 0.05, 0.02)},
			{"text": "Die Verstimmten-Horden tanzen durch ausgebrannte Konzerthallen.\nDie Headbanger rotten sich zusammen.\n\nEtwas Großes kommt.", "bg_color": Color(0.1, 0.03, 0.03)},
			{"text": "Gerüchte sprechen von einem DIRIGENTEN –\neinem Wesen, das die Chaos-Musiker anführt.\n\nEr will die letzte Musik auslöschen.", "bg_color": Color(0.03, 0.02, 0.1)},
		]
	elif "act3" in path:
		act_title = "ACT III — DER URSPRUNG"
		next_scene = "res://scenes/game.tscn"
		slides = [
			{"text": "Die Wahrheit kommt ans Licht.\n\nEin Konzern – SoundCorp – hat bewusst\nden Mutationsakkord verbreitet.", "bg_color": Color(0.03, 0.06, 0.08)},
			{"text": "Der CEO: Dr. Victor Stille.\n\nEr glaubte, die Welt braucht absolute Stille.\n\nKeine Musik. Kein Lärm. Keine Menschheit.", "bg_color": Color(0.06, 0.02, 0.02)},
			{"text": "Er hat sich selbst mit dem Akkord infiziert.\n\nEr IST der Dirigent.\n\nDie finale Konfrontation wartet.", "bg_color": Color(0.05, 0.0, 0.08)},
		]
	elif "finale" in path:
		act_title = "FINALE — DAS LETZTE KONZERT"
		next_scene = "res://scenes/game.tscn"
		slides = [
			{"text": "Die Band steht vor dem größten\nKonzert ihrer Leben.\n\nDas Publikum? Eine Armee aus Monstern.", "bg_color": Color(0.1, 0.0, 0.0)},
			{"text": "Dr. Stille erhebt seinen Taktstock.\n\nDie Welt hält den Atem an.\n\nDann... setzt die Musik ein.", "bg_color": Color(0.05, 0.0, 0.1)},
			{"text": "WELLE 15.\n\nDer finale Showdown.\n\nSpiele das lauteste Konzert der Geschichte.", "bg_color": Color(0.0, 0.0, 0.0)},
		]
	else:
		slides = [{"text": "...", "bg_color": Color(0.05, 0.03, 0.1)}]

func _process(delta: float) -> void:
	_anim_time += delta
	_text_reveal = min(_text_reveal + delta * 25.0, 1.0)
	if _text_reveal >= 1.0:
		_advance_ready = true
		_auto_timer += delta
		if _auto_timer >= AUTO_ADVANCE_SEC:
			_auto_timer = 0.0
			_advance_slide()
	queue_redraw()
	_update_slide_text()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = slides[0].get("bg_color", Color(0.05, 0.03, 0.1))
	add_child(bg)

	var act_lbl = Label.new()
	act_lbl.name = "ActLabel"
	act_lbl.set_anchors_preset(PRESET_CENTER_TOP)
	act_lbl.anchor_left = 0.5
	act_lbl.anchor_right = 0.5
	act_lbl.position = Vector2(-300, 40)
	act_lbl.size = Vector2(600, 50)
	act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	act_lbl.text = act_title
	act_lbl.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0))
	act_lbl.add_theme_font_size_override("font_size", 30)
	add_child(act_lbl)

	var text_label = Label.new()
	text_label.name = "StoryText"
	text_label.set_anchors_preset(PRESET_CENTER)
	text_label.anchor_left = 0.5
	text_label.anchor_right = 0.5
	text_label.anchor_top = 0.5
	text_label.anchor_bottom = 0.5
	text_label.position = Vector2(-400, -150)
	text_label.size = Vector2(800, 300)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	text_label.add_theme_font_size_override("font_size", 28)
	add_child(text_label)

	var continue_lbl = Label.new()
	continue_lbl.name = "ContinueHint"
	continue_lbl.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	continue_lbl.anchor_left = 1.0
	continue_lbl.anchor_right = 1.0
	continue_lbl.anchor_top = 1.0
	continue_lbl.anchor_bottom = 1.0
	continue_lbl.position = Vector2(-370, -55)
	continue_lbl.size = Vector2(350, 40)
	continue_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_lbl.text = "[ Klick / SPACE – weiter | automatisch in 12s ]"
	continue_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.85))
	continue_lbl.add_theme_font_size_override("font_size", 15)
	add_child(continue_lbl)

	var skip_btn = Button.new()
	skip_btn.position = Vector2(20, 670)
	skip_btn.size = Vector2(160, 40)
	skip_btn.text = "SKIP"
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(_go_to_next)
	add_child(skip_btn)

func _update_slide_text() -> void:
	var label = get_node_or_null("StoryText")
	if label == null or _current_slide >= slides.size():
		return
	var full_text = slides[_current_slide].get("text", "")
	var chars = int(_text_reveal * full_text.length())
	label.text = full_text.substr(0, chars)
	var bg = get_node_or_null("Background")
	if bg:
		bg.color = slides[_current_slide].get("bg_color", Color(0.05, 0.03, 0.1))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action_pressed("attack") and not event.is_echo():
		_handle_advance()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_advance()

func _handle_advance() -> void:
	if not _advance_ready:
		_text_reveal = 1.0
	else:
		_advance_slide()

func _advance_slide() -> void:
	_current_slide += 1
	_text_reveal = 0.0
	_advance_ready = false
	if _current_slide >= slides.size():
		_go_to_next()

func _go_to_next() -> void:
	GameManager.change_scene(next_scene)

func _draw() -> void:
	var vp = get_viewport_rect()
	for i in range(5):
		var y = vp.size.y * 0.3 + i * 90.0
		var pts = PackedVector2Array()
		for x in range(0, int(vp.size.x), 10):
			var wave_y = y + sin(_anim_time * 1.5 + x * 0.015 + i * 1.2) * 25.0
			pts.append(Vector2(x, wave_y))
		if pts.size() > 1:
			draw_polyline(pts, Color(0.3, 0.1, 0.5, 0.07), 1.5)
