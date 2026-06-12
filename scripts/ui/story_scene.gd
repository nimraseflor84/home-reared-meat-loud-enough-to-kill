extends Control

# Story-Szene: erkennt aus dem Szenen-Pfad welcher Akt gespielt wird.
# Alle Texte liegen in 5 Sprachen vor (de/en/fr/es/uk), unbekannte
# Sprachen fallen auf Englisch zurueck.
#
# Roter Faden der Story (Run #6):
# Akt I fuehrt SoundCorp und die Radio-Werbung bereits ein, damit die
# Aufloesung in Akt III keine neue Figur mehr braucht.

var act_title: Dictionary = {}
var act_progress: Dictionary = {}
var slides: Array = []
var next_scene: String = "res://scenes/game.tscn"

var _current_slide: int = 0
var _anim_time: float = 0.0
var _text_reveal: float = 0.0
var _advance_ready: bool = false
var _auto_timer: float = 0.0
const AUTO_ADVANCE_SEC: float = 12.0

const CONTINUE_HINT: Dictionary = {
	"de": "[ Klick / SPACE – weiter | automatisch in 12s ]",
	"en": "[ Click / SPACE – continue | auto in 12s ]",
	"fr": "[ Clic / ESPACE – continuer | auto dans 12s ]",
	"es": "[ Clic / ESPACIO – continuar | auto en 12s ]",
	"uk": "[ Клік / ПРОБІЛ – далі | авто через 12с ]",
}

# Liefert den Sprachschluessel fuer Story-Texte (en als Fallback)
func _lang() -> String:
	var cur: String = LocalizationManager.current_language
	if cur in ["de", "en", "fr", "es", "uk"]:
		return cur
	return "en"

func _ready() -> void:
	_load_act_data()
	_build_ui()

func _load_act_data() -> void:
	var path = scene_file_path
	if "act1" in path:
		act_title = {
			"de": "ACT I — DIE ERSTE PROBE", "en": "ACT I — THE FIRST REHEARSAL",
			"fr": "ACTE I — LA PREMIÈRE RÉPÉTITION", "es": "ACTO I — EL PRIMER ENSAYO",
			"uk": "АКТ I — ПЕРША РЕПЕТИЦІЯ"}
		act_progress = {
			"de": "Kapitel 1 von 4  ·  Wellen 1–5", "en": "Chapter 1 of 4  ·  Waves 1–5",
			"fr": "Chapitre 1 sur 4  ·  Vagues 1–5", "es": "Capítulo 1 de 4  ·  Oleadas 1–5",
			"uk": "Розділ 1 з 4  ·  Хвилі 1–5"}
		next_scene = "res://scenes/game.tscn"
		slides = [
			{"de": "Meppen. Ein Proberaum-Keller.\n\nSechs Musiker. Zu viel Energie.\n\nIm Radio läuft zum hundertsten Mal dieselbe Werbung:\n\"SoundCorp präsentiert: DIE NEUE STILLE.\nBald in Ihrer Stadt.\"",
			 "en": "Meppen, Germany. A basement rehearsal room.\n\nSix musicians. Too much energy.\n\nOn the radio, the same ad for the hundredth time:\n\"SoundCorp presents: THE NEW SILENCE.\nComing to your town soon.\"",
			 "fr": "Meppen, Allemagne. Une cave de répétition.\n\nSix musiciens. Trop d'énergie.\n\nÀ la radio, la même pub pour la centième fois:\n«SoundCorp présente: LE NOUVEAU SILENCE.\nBientôt dans votre ville.»",
			 "es": "Meppen, Alemania. Un sótano de ensayo.\n\nSeis músicos. Demasiada energía.\n\nEn la radio, el mismo anuncio por centésima vez:\n«SoundCorp presenta: EL NUEVO SILENCIO.\nPronto en tu ciudad.»",
			 "uk": "Меппен, Німеччина. Підвал для репетицій.\n\nШестеро музикантів. Забагато енергії.\n\nПо радіо всоте та сама реклама:\n«SoundCorp представляє: НОВА ТИША.\nСкоро у вашому місті.»",
			 "bg_color": Color(0.05, 0.03, 0.12)},
			{"de": "Niemand hörte hin.\n\nDann spielten sie den Akkord.\nDen einen Akkord, der alles veränderte.\n\nDie Schallwellen mutierten. Wurden lebendig.",
			 "en": "Nobody was listening.\n\nThen they played the chord.\nThe one chord that changed everything.\n\nThe sound waves mutated. Came alive.",
			 "fr": "Personne n'écoutait.\n\nPuis ils ont joué l'accord.\nLe seul accord qui a tout changé.\n\nLes ondes sonores ont muté. Ont pris vie.",
			 "es": "Nadie escuchaba.\n\nEntonces tocaron el acorde.\nEl único acorde que lo cambió todo.\n\nLas ondas de sonido mutaron. Cobraron vida.",
			 "uk": "Ніхто не слухав.\n\nА потім вони зіграли акорд.\nТой самий акорд, що змінив усе.\n\nЗвукові хвилі мутували. Ожили.",
			 "bg_color": Color(0.1, 0.02, 0.05)},
			{"de": "Stille-Wesen – einst Konzertbesucher –\nkrochen aus den Lautsprechern.\n\nHungernd nach Musik. Hungernd nach Blut.\n\nUnd auf jedem Lautsprecher: ein SoundCorp-Logo.",
			 "en": "Silence creatures – once concertgoers –\ncrawled out of the speakers.\n\nHungry for music. Hungry for blood.\n\nAnd on every speaker: a SoundCorp logo.",
			 "fr": "Des créatures du silence – d'anciens spectateurs –\nont rampé hors des enceintes.\n\nAffamées de musique. Affamées de sang.\n\nEt sur chaque enceinte: un logo SoundCorp.",
			 "es": "Criaturas del silencio – antiguos espectadores –\nsalieron arrastrándose de los altavoces.\n\nHambrientas de música. Hambrientas de sangre.\n\nY en cada altavoz: un logo de SoundCorp.",
			 "uk": "Істоти тиші – колишні відвідувачі концертів –\nвиповзли з динаміків.\n\nГолодні до музики. Голодні до крові.\n\nІ на кожному динаміку: логотип SoundCorp.",
			 "bg_color": Color(0.07, 0.04, 0.1)},
			{"de": "Es gibt nur einen Weg zu überleben:\n\nSpiele lauter als die Apokalypse.",
			 "en": "There is only one way to survive:\n\nPlay louder than the apocalypse.",
			 "fr": "Il n'y a qu'un seul moyen de survivre:\n\nJoue plus fort que l'apocalypse.",
			 "es": "Solo hay una forma de sobrevivir:\n\nToca más fuerte que el apocalipsis.",
			 "uk": "Вижити можна лише одним способом:\n\nГрай гучніше за апокаліпсис.",
			 "bg_color": Color(0.02, 0.08, 0.02)},
		]
	elif "act2" in path:
		act_title = {
			"de": "ACT II — TOUR DURCH DIE APOKALYPSE", "en": "ACT II — TOUR THROUGH THE APOCALYPSE",
			"fr": "ACTE II — TOURNÉE DANS L'APOCALYPSE", "es": "ACTO II — GIRA POR EL APOCALIPSIS",
			"uk": "АКТ II — ТУР АПОКАЛІПСИСОМ"}
		act_progress = {
			"de": "Kapitel 2 von 4  ·  Wellen 6–10", "en": "Chapter 2 of 4  ·  Waves 6–10",
			"fr": "Chapitre 2 sur 4  ·  Vagues 6–10", "es": "Capítulo 2 de 4  ·  Oleadas 6–10",
			"uk": "Розділ 2 з 4  ·  Хвилі 6–10"}
		next_scene = "res://scenes/game.tscn"
		slides = [
			{"de": "Fünf Wellen überlebt. Die Stadt liegt in Trümmern.\n\nAber die Band spielt weiter.",
			 "en": "Five waves survived. The town lies in ruins.\n\nBut the band plays on.",
			 "fr": "Cinq vagues survécues. La ville est en ruines.\n\nMais le groupe continue de jouer.",
			 "es": "Cinco oleadas superadas. La ciudad está en ruinas.\n\nPero la banda sigue tocando.",
			 "uk": "П'ять хвиль позаду. Місто в руїнах.\n\nАле гурт грає далі.",
			 "bg_color": Color(0.08, 0.05, 0.02)},
			{"de": "Überall dasselbe Logo: SoundCorp.\n\nAuf den Lautsprechern, aus denen die Monster krochen.\nAuf den Ohrstöpseln der Verstimmten.\n\nDas ist kein Zufall.",
			 "en": "The same logo everywhere: SoundCorp.\n\nOn the speakers the monsters crawled from.\nOn the earplugs of the Detuned.\n\nThat is no coincidence.",
			 "fr": "Le même logo partout: SoundCorp.\n\nSur les enceintes d'où sortaient les monstres.\nSur les bouchons d'oreilles des Désaccordés.\n\nCe n'est pas un hasard.",
			 "es": "El mismo logo en todas partes: SoundCorp.\n\nEn los altavoces de los que salían los monstruos.\nEn los tapones de los Desafinados.\n\nNo es casualidad.",
			 "uk": "Той самий логотип всюди: SoundCorp.\n\nНа динаміках, з яких лізли монстри.\nНа берушах Розстроєних.\n\nЦе не випадковість.",
			 "bg_color": Color(0.1, 0.03, 0.03)},
			{"de": "Gerüchte sprechen von einem DIRIGENTEN –\neinem Wesen, das die Chaos-Musiker anführt.\n\nEr will die letzte Musik auslöschen.",
			 "en": "Rumors speak of a CONDUCTOR –\na being that commands the chaos musicians.\n\nHe wants to extinguish the last music.",
			 "fr": "Des rumeurs parlent d'un CHEF D'ORCHESTRE –\nun être qui commande les musiciens du chaos.\n\nIl veut éteindre la dernière musique.",
			 "es": "Los rumores hablan de un DIRECTOR –\nun ser que comanda a los músicos del caos.\n\nQuiere extinguir la última música.",
			 "uk": "Ходять чутки про ДИРИГЕНТА –\nістоту, що командує музиками хаосу.\n\nВін хоче знищити останню музику.",
			 "bg_color": Color(0.03, 0.02, 0.1)},
		]
	elif "act3" in path:
		act_title = {
			"de": "ACT III — DER URSPRUNG", "en": "ACT III — THE ORIGIN",
			"fr": "ACTE III — L'ORIGINE", "es": "ACTO III — EL ORIGEN",
			"uk": "АКТ III — ПОХОДЖЕННЯ"}
		act_progress = {
			"de": "Kapitel 3 von 4  ·  Wellen 11–14", "en": "Chapter 3 of 4  ·  Waves 11–14",
			"fr": "Chapitre 3 sur 4  ·  Vagues 11–14", "es": "Capítulo 3 de 4  ·  Oleadas 11–14",
			"uk": "Розділ 3 з 4  ·  Хвилі 11–14"}
		next_scene = "res://scenes/game.tscn"
		slides = [
			{"de": "Die Wahrheit kommt ans Licht.\n\nSoundCorp hat den Mutationsakkord bewusst verbreitet.\nDie Radio-Werbung war eine Trägerfrequenz.\n\nJeder, der sie hörte, wurde empfänglich.",
			 "en": "The truth comes to light.\n\nSoundCorp spread the mutation chord deliberately.\nThe radio ad was a carrier frequency.\n\nEveryone who heard it became susceptible.",
			 "fr": "La vérité éclate.\n\nSoundCorp a délibérément répandu l'accord mutant.\nLa pub radio était une fréquence porteuse.\n\nQuiconque l'a entendue est devenu réceptif.",
			 "es": "La verdad sale a la luz.\n\nSoundCorp difundió el acorde mutante a propósito.\nEl anuncio de radio era una frecuencia portadora.\n\nQuien lo oyó se volvió receptivo.",
			 "uk": "Правда виходить назовні.\n\nSoundCorp навмисно поширила мутаційний акорд.\nРадіореклама була несучою частотою.\n\nКожен, хто її чув, став сприйнятливим.",
			 "bg_color": Color(0.03, 0.06, 0.08)},
			{"de": "Der CEO: Dr. Victor Stille.\n\nEr glaubte, die Welt braucht absolute Stille.\n\nKeine Musik. Kein Lärm. Keine Menschheit.",
			 "en": "The CEO: Dr. Victor Stille.\n\nHe believed the world needs absolute silence.\n\nNo music. No noise. No humanity.",
			 "fr": "Le PDG: Dr Victor Stille.\n\nIl croyait que le monde a besoin d'un silence absolu.\n\nPas de musique. Pas de bruit. Pas d'humanité.",
			 "es": "El CEO: Dr. Victor Stille.\n\nCreía que el mundo necesita silencio absoluto.\n\nSin música. Sin ruido. Sin humanidad.",
			 "uk": "CEO: д-р Віктор Штілле.\n\nВін вірив, що світу потрібна абсолютна тиша.\n\nБез музики. Без шуму. Без людства.",
			 "bg_color": Color(0.06, 0.02, 0.02)},
			{"de": "Er hat sich selbst mit dem Akkord infiziert.\n\nEr IST der Dirigent.\n\nDie finale Konfrontation wartet.",
			 "en": "He infected himself with the chord.\n\nHe IS the Conductor.\n\nThe final confrontation awaits.",
			 "fr": "Il s'est infecté lui-même avec l'accord.\n\nIl EST le Chef d'orchestre.\n\nLa confrontation finale attend.",
			 "es": "Se infectó a sí mismo con el acorde.\n\nÉL ES el Director.\n\nLa confrontación final espera.",
			 "uk": "Він заразив себе акордом.\n\nВін І Є Диригент.\n\nФінальне протистояння чекає.",
			 "bg_color": Color(0.05, 0.0, 0.08)},
		]
	elif "finale" in path:
		act_title = {
			"de": "FINALE — DAS LETZTE KONZERT", "en": "FINALE — THE LAST CONCERT",
			"fr": "FINAL — LE DERNIER CONCERT", "es": "FINAL — EL ÚLTIMO CONCIERTO",
			"uk": "ФІНАЛ — ОСТАННІЙ КОНЦЕРТ"}
		act_progress = {
			"de": "Kapitel 4 von 4  ·  Welle 15", "en": "Chapter 4 of 4  ·  Wave 15",
			"fr": "Chapitre 4 sur 4  ·  Vague 15", "es": "Capítulo 4 de 4  ·  Oleada 15",
			"uk": "Розділ 4 з 4  ·  Хвиля 15"}
		next_scene = "res://scenes/game.tscn"
		slides = [
			{"de": "Die Band steht vor dem größten\nKonzert ihres Lebens.\n\nDas Publikum? Eine Armee aus Monstern.",
			 "en": "The band faces the biggest\nconcert of their lives.\n\nThe audience? An army of monsters.",
			 "fr": "Le groupe est face au plus grand\nconcert de sa vie.\n\nLe public? Une armée de monstres.",
			 "es": "La banda afronta el mayor\nconcierto de su vida.\n\n¿El público? Un ejército de monstruos.",
			 "uk": "Попереду в гурту найбільший\nконцерт у житті.\n\nПубліка? Армія монстрів.",
			 "bg_color": Color(0.1, 0.0, 0.0)},
			{"de": "Dr. Victor Stille erhebt seinen Taktstock.\n\nDie Welt hält den Atem an.\n\nDann... setzt die Musik ein.",
			 "en": "Dr. Victor Stille raises his baton.\n\nThe world holds its breath.\n\nThen... the music begins.",
			 "fr": "Le Dr Victor Stille lève sa baguette.\n\nLe monde retient son souffle.\n\nPuis... la musique commence.",
			 "es": "El Dr. Victor Stille alza su batuta.\n\nEl mundo contiene la respiración.\n\nEntonces... empieza la música.",
			 "uk": "Д-р Віктор Штілле здіймає паличку.\n\nСвіт затамовує подих.\n\nА потім... починається музика.",
			 "bg_color": Color(0.05, 0.0, 0.1)},
			{"de": "WELLE 15.\n\nDer finale Showdown.\n\nSpiele das lauteste Konzert der Geschichte.",
			 "en": "WAVE 15.\n\nThe final showdown.\n\nPlay the loudest concert in history.",
			 "fr": "VAGUE 15.\n\nL'affrontement final.\n\nJoue le concert le plus bruyant de l'histoire.",
			 "es": "OLEADA 15.\n\nEl enfrentamiento final.\n\nToca el concierto más ruidoso de la historia.",
			 "uk": "ХВИЛЯ 15.\n\nФінальна битва.\n\nЗіграй найгучніший концерт в історії.",
			 "bg_color": Color(0.0, 0.0, 0.0)},
		]
	else:
		act_title = {"de": "", "en": ""}
		act_progress = {"de": "", "en": ""}
		slides = [{"de": "...", "en": "...", "bg_color": Color(0.05, 0.03, 0.1)}]

# Liefert einen Text aus einem Sprach-Dictionary in der aktiven Sprache
func _pick(map: Dictionary) -> String:
	return map.get(_lang(), map.get("en", map.get("de", "")))

func _slide_text(slide: Dictionary) -> String:
	return _pick(slide)

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
	act_lbl.text = _pick(act_title)
	act_lbl.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0))
	act_lbl.add_theme_font_size_override("font_size", 30)
	add_child(act_lbl)

	# Fortschrittszeile: zeigt Kapitel und Wellen-Bereich, damit der Spieler
	# jederzeit weiss, wo er in der Story steht
	var progress_lbl = Label.new()
	progress_lbl.name = "ProgressLabel"
	progress_lbl.set_anchors_preset(PRESET_CENTER_TOP)
	progress_lbl.anchor_left = 0.5
	progress_lbl.anchor_right = 0.5
	progress_lbl.position = Vector2(-300, 92)
	progress_lbl.size = Vector2(600, 30)
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_lbl.text = _pick(act_progress)
	progress_lbl.add_theme_color_override("font_color", Color(0.55, 0.45, 0.75))
	progress_lbl.add_theme_font_size_override("font_size", 17)
	add_child(progress_lbl)

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
	continue_lbl.text = _pick(CONTINUE_HINT)
	continue_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.85))
	continue_lbl.add_theme_font_size_override("font_size", 15)
	add_child(continue_lbl)

	var skip_btn = Button.new()
	skip_btn.position = Vector2(20, 670)
	skip_btn.size = Vector2(160, 40)
	skip_btn.text = LocalizationManager.t("skip")
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(_go_to_next)
	add_child(skip_btn)

func _update_slide_text() -> void:
	var label = get_node_or_null("StoryText")
	if label == null or _current_slide >= slides.size():
		return
	var full_text = _slide_text(slides[_current_slide])
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
