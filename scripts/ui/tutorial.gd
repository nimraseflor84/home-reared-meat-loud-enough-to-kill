extends Control

# Tutorial overlay: 5 pages, NEXT/PREV/SKIP, controller-friendly.
# Goes to character_select when finished (or skipped).

# Seiten in allen 5 Sprachen (de/en/fr/es/uk). Aufloesung in _show_page().
# Hinweis Run #6: Tastenhinweise korrigiert. Ultimate liegt auf E (nicht Q),
# Dash auf SHIFT / rechter Maustaste / B-Button (nicht rechter Stick).
const PAGES: Array = [
	{
		"icon": "WASD",
		"title": {"de": "BEWEGUNG", "en": "MOVEMENT", "fr": "DÉPLACEMENT", "es": "MOVIMIENTO", "uk": "РУХ"},
		"lines": {
			"de": ["WASD oder Pfeiltasten", "Linker Stick am Controller", "Lauf, weich aus, bleib in Bewegung."],
			"en": ["WASD or arrow keys", "Left stick on a controller", "Run, dodge, never stop moving."],
			"fr": ["WASD ou flèches", "Stick gauche à la manette", "Cours, esquive, ne t'arrête jamais."],
			"es": ["WASD o flechas", "Stick izquierdo en el mando", "Corre, esquiva, nunca te detengas."],
			"uk": ["WASD або стрілки", "Лівий стік на ґеймпаді", "Біжи, ухиляйся, не зупиняйся."],
		},
	},
	{
		"icon": "SPACE / A",
		"title": {"de": "ATTACKE", "en": "ATTACK", "fr": "ATTAQUE", "es": "ATAQUE", "uk": "АТАКА"},
		"lines": {
			"de": ["Auto-Attack ist immer an.", "LEERTASTE oder A-Button für Timing-Bonus.", "Wer den Beat trifft, schlägt härter."],
			"en": ["Auto-attack is always on.", "SPACE or A button for a timing bonus.", "Hit the beat, hit harder."],
			"fr": ["L'attaque auto est toujours active.", "ESPACE ou bouton A pour le bonus de timing.", "Frappe sur le beat, frappe plus fort."],
			"es": ["El ataque automático siempre está activo.", "ESPACIO o botón A para el bono de ritmo.", "Acierta el beat, golpea más fuerte."],
			"uk": ["Автоатака завжди увімкнена.", "ПРОБІЛ або кнопка A для бонусу таймінгу.", "Влучай у біт — бий сильніше."],
		},
	},
	{
		"icon": "E / X",
		"title": {"de": "ULTIMATE", "en": "ULTIMATE", "fr": "ULTIME", "es": "ÚLTIMO", "uk": "УЛЬТА"},
		"lines": {
			"de": ["E oder X-Button feuert deine Ultimate.", "Lädt sich durch Kills und Schaden auf.", "Spar sie für dichte Wellen oder Bosse."],
			"en": ["E or X fires your ultimate.", "Charges through kills and damage taken.", "Save it for dense waves or bosses."],
			"fr": ["E ou X déclenche ton ultime.", "Se charge avec les kills et les dégâts subis.", "Garde-le pour les grosses vagues ou les boss."],
			"es": ["E o X dispara tu último.", "Se carga con bajas y daño recibido.", "Guárdalo para oleadas densas o jefes."],
			"uk": ["E або X запускає ульту.", "Заряджається від вбивств і отриманої шкоди.", "Бережи її для щільних хвиль або босів."],
		},
	},
	{
		"icon": "SHIFT / B",
		"title": {"de": "DASH", "en": "DASH", "fr": "DASH", "es": "DASH", "uk": "РИВОК"},
		"lines": {
			"de": ["SHIFT, rechte Maustaste oder B-Button für den Dash.", "Kurzer i-Frame, kurzer Cooldown.", "Durch Gegner durch, raus aus dem Mob."],
			"en": ["SHIFT, right mouse or B button dashes.", "Short i-frames, short cooldown.", "Punch through mobs, escape the swarm."],
			"fr": ["MAJ, clic droit ou bouton B pour le dash.", "Brève invincibilité, bref cooldown.", "Traverse les ennemis, fuis la horde."],
			"es": ["SHIFT, clic derecho o botón B para el dash.", "Breve invulnerabilidad, breve enfriamiento.", "Atraviesa enemigos, escapa de la horda."],
			"uk": ["SHIFT, права кнопка миші або B — ривок.", "Коротка невразливість, короткий кулдаун.", "Крізь ворогів, геть із натовпу."],
		},
	},
	{
		"icon": "!",
		"title": {"de": "ÜBERLEBE", "en": "SURVIVE", "fr": "SURVIS", "es": "SOBREVIVE", "uk": "ВИЖИВИ"},
		"lines": {
			"de": ["Wellen töten, Upgrades einsammeln.", "Im Shop zwischen Wellen aufrüsten.", "Höchste Welle = höchster Score.", "Viel Glück. Wirst du brauchen."],
			"en": ["Clear waves, grab upgrades.", "Power up in the shop between waves.", "Higher waves = higher score.", "Good luck. You'll need it."],
			"fr": ["Nettoie les vagues, ramasse les améliorations.", "Améliore-toi à la boutique entre les vagues.", "Plus de vagues = plus de points.", "Bonne chance. Tu en auras besoin."],
			"es": ["Supera oleadas, recoge mejoras.", "Mejora en la tienda entre oleadas.", "Más oleadas = más puntos.", "Buena suerte. La necesitarás."],
			"uk": ["Зачищай хвилі, збирай апгрейди.", "Прокачуйся в магазині між хвилями.", "Більше хвиль = більше очок.", "Щасти. Воно тобі знадобиться."],
		},
	},
]

var _page: int = 0
var _font_big: Font = null
var _font_md: Font = null
var _font_sm: Font = null

var _title_label: Label = null
var _icon_label: Label = null
var _body_label: Label = null
var _page_label: Label = null
var _prev_btn: Button = null
var _next_btn: Button = null
var _skip_btn: Button = null


func _ready() -> void:
	_build_fonts()
	_build_ui()
	_show_page(0)
	process_mode = Node.PROCESS_MODE_ALWAYS


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

	# Background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.02, 0.06, 1.0)
	add_child(bg)

	# Subtle red diagonal stripe
	var stripe := ColorRect.new()
	stripe.set_anchors_preset(Control.PRESET_FULL_RECT)
	stripe.color = Color(0.55, 0.05, 0.08, 0.15)
	stripe.size_flags_horizontal = SIZE_EXPAND_FILL
	stripe.size_flags_vertical = SIZE_EXPAND_FILL
	stripe.anchor_top = 0.40
	stripe.anchor_bottom = 0.60
	add_child(stripe)

	# Top header: "HOW TO PLAY"
	var header := Label.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_top = 24.0
	header.offset_left = 0.0
	header.offset_right = 0.0
	header.text = LocalizationManager.t("how_to_play")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_override("font", _font_sm)
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	add_child(header)

	# Title
	_title_label = Label.new()
	_title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title_label.offset_top = 90.0
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", _font_big)
	_title_label.add_theme_font_size_override("font_size", 86)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.10, 0.12))
	_title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_title_label.add_theme_constant_override("outline_size", 6)
	add_child(_title_label)

	# Big keybind/icon
	_icon_label = Label.new()
	_icon_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_icon_label.offset_top = 200.0
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_override("font", _font_md)
	_icon_label.add_theme_font_size_override("font_size", 54)
	_icon_label.add_theme_color_override("font_color", Color.WHITE)
	_icon_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_icon_label.add_theme_constant_override("outline_size", 4)
	add_child(_icon_label)

	# Body
	_body_label = Label.new()
	_body_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body_label.offset_top = 310.0
	_body_label.offset_bottom = -160.0
	_body_label.offset_left = 80.0
	_body_label.offset_right = -80.0
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_override("font", _font_sm)
	_body_label.add_theme_font_size_override("font_size", 30)
	_body_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	_body_label.add_theme_constant_override("line_spacing", 10)
	add_child(_body_label)

	# Page indicator
	_page_label = Label.new()
	_page_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_page_label.offset_bottom = -100.0
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.add_theme_font_override("font", _font_sm)
	_page_label.add_theme_font_size_override("font_size", 22)
	_page_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	add_child(_page_label)

	# Buttons
	_prev_btn = _make_button(LocalizationManager.t("btn_prev"), Color(0.20, 0.20, 0.24))
	_prev_btn.position = Vector2(40, 0)
	_prev_btn.anchor_left = 0.0
	_prev_btn.anchor_right = 0.0
	_prev_btn.anchor_top = 1.0
	_prev_btn.anchor_bottom = 1.0
	_prev_btn.offset_top = -90.0
	_prev_btn.offset_bottom = -30.0
	_prev_btn.offset_left = 40.0
	_prev_btn.offset_right = 240.0
	_prev_btn.pressed.connect(_on_prev_pressed)
	add_child(_prev_btn)

	_skip_btn = _make_button(LocalizationManager.t("skip"), Color(0.65, 0.10, 0.10))
	_skip_btn.anchor_left = 0.5
	_skip_btn.anchor_right = 0.5
	_skip_btn.anchor_top = 1.0
	_skip_btn.anchor_bottom = 1.0
	_skip_btn.offset_left = -100.0
	_skip_btn.offset_right = 100.0
	_skip_btn.offset_top = -90.0
	_skip_btn.offset_bottom = -30.0
	_skip_btn.pressed.connect(_on_skip_pressed)
	add_child(_skip_btn)

	_next_btn = _make_button(LocalizationManager.t("btn_next"), Color(0.15, 0.55, 0.25))
	_next_btn.anchor_left = 1.0
	_next_btn.anchor_right = 1.0
	_next_btn.anchor_top = 1.0
	_next_btn.anchor_bottom = 1.0
	_next_btn.offset_left = -240.0
	_next_btn.offset_right = -40.0
	_next_btn.offset_top = -90.0
	_next_btn.offset_bottom = -30.0
	_next_btn.pressed.connect(_on_next_pressed)
	add_child(_next_btn)

	_next_btn.call_deferred("grab_focus")


func _make_button(text: String, base: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _font_md)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", Color.WHITE)
	var sty := StyleBoxFlat.new()
	sty.bg_color = base.darkened(0.35)
	sty.border_color = base
	sty.set_border_width_all(2)
	sty.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", sty)
	var sty_h := StyleBoxFlat.new()
	sty_h.bg_color = base.lightened(0.15)
	sty_h.set_corner_radius_all(6)
	b.add_theme_stylebox_override("hover", sty_h)
	var sty_f := StyleBoxFlat.new()
	sty_f.bg_color = base
	sty_f.border_color = Color.WHITE
	sty_f.set_border_width_all(3)
	sty_f.set_corner_radius_all(6)
	b.add_theme_stylebox_override("focus", sty_f)
	return b


func _lang() -> String:
	# Alle 5 Sprachen werden direkt unterstuetzt, unbekannte fallen auf en zurueck
	var cur: String = LocalizationManager.current_language if LocalizationManager else "de"
	if cur in ["de", "en", "fr", "es", "uk"]:
		return cur
	return "en"


func _show_page(idx: int) -> void:
	_page = clamp(idx, 0, PAGES.size() - 1)
	var lang := _lang()
	var page: Dictionary = PAGES[_page]
	var titles: Dictionary = page.get("title", {})
	_title_label.text = titles.get(lang, titles.get("en", ""))
	var lines_map: Dictionary = page.get("lines", {})
	var lines: Array = lines_map.get(lang, lines_map.get("en", []))
	_body_label.text = "\n".join(lines)
	_icon_label.text = page["icon"]
	_page_label.text = "%d / %d" % [_page + 1, PAGES.size()]

	_prev_btn.disabled = _page == 0
	if _page == PAGES.size() - 1:
		_next_btn.text = LocalizationManager.t("btn_start")
	else:
		_next_btn.text = LocalizationManager.t("btn_next")


func _on_prev_pressed() -> void:
	if _page > 0:
		_show_page(_page - 1)
		_next_btn.call_deferred("grab_focus")


func _on_next_pressed() -> void:
	if _page < PAGES.size() - 1:
		_show_page(_page + 1)
		_next_btn.call_deferred("grab_focus")
	else:
		_finish()


func _on_skip_pressed() -> void:
	_finish()


func _finish() -> void:
	SaveManager.mark_tutorial_seen()
	GameManager.go_to_character_select()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_skip_pressed()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_left"):
		_on_prev_pressed()
		get_viewport().set_input_as_handled()
		return
