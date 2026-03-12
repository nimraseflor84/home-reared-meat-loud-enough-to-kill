extends Node
# AUTOLOAD: Add this script as autoload in Project Settings → Autoload
# Name: LocalizationManager
# Path: res://scripts/globals/localization_manager.gd

signal language_changed(lang: String)

var current_language: String = "de"

const LANGUAGES: Dictionary = {
	"de": "Deutsch",
	"en": "English",
	"fr": "Français",
	"es": "Español",
	"uk": "Українська",
}

const TRANSLATIONS: Dictionary = {
	"play": {
		"de": "SPIELEN",
		"en": "PLAY",
		"fr": "JOUER",
		"es": "JUGAR",
		"uk": "ГРАТИ",
	},
	"endless_mode": {
		"de": "ENDLOSMODUS",
		"en": "ENDLESS MODE",
		"fr": "MODE INFINI",
		"es": "MODO INFINITO",
		"uk": "НЕСКІНЧЕННО",
	},
	"leaderboard": {
		"de": "BESTENLISTE",
		"en": "LEADERBOARD",
		"fr": "CLASSEMENT",
		"es": "CLASIFICACIÓN",
		"uk": "РЕКОРДИ",
	},
	"options": {
		"de": "OPTIONEN",
		"en": "OPTIONS",
		"fr": "OPTIONS",
		"es": "OPCIONES",
		"uk": "НАЛАШТ.",
	},
	"quit": {
		"de": "BEENDEN",
		"en": "QUIT",
		"fr": "QUITTER",
		"es": "SALIR",
		"uk": "ВИЙТИ",
	},
	"options_title": {
		"de": "OPTIONEN",
		"en": "OPTIONS",
		"fr": "OPTIONS",
		"es": "OPCIONES",
		"uk": "НАЛАШТУВАННЯ",
	},
	"tab_graphics": {
		"de": "GRAFIK",
		"en": "GRAPHICS",
		"fr": "GRAPHISMES",
		"es": "GRÁFICOS",
		"uk": "ГРАФІКА",
	},
	"tab_sound": {
		"de": "SOUND",
		"en": "SOUND",
		"fr": "SON",
		"es": "SONIDO",
		"uk": "ЗВУК",
	},
	"tab_gameplay": {
		"de": "GAMEPLAY",
		"en": "GAMEPLAY",
		"fr": "GAMEPLAY",
		"es": "JUGABILIDAD",
		"uk": "ГЕЙМПЛЕЙ",
	},
	"tab_language": {
		"de": "SPRACHE",
		"en": "LANGUAGE",
		"fr": "LANGUE",
		"es": "IDIOMA",
		"uk": "МОВА",
	},
	"back": {
		"de": "← ZURÜCK",
		"en": "← BACK",
		"fr": "← RETOUR",
		"es": "← ATRÁS",
		"uk": "← НАЗАД",
	},
	"fullscreen": {
		"de": "Vollbild",
		"en": "Fullscreen",
		"fr": "Plein écran",
		"es": "Pantalla completa",
		"uk": "Повний екран",
	},
	"vsync": {
		"de": "VSync",
		"en": "VSync",
		"fr": "VSync",
		"es": "VSync",
		"uk": "VSync",
	},
	"screen_shake": {
		"de": "Bildschirmschütteln",
		"en": "Screen Shake",
		"fr": "Tremblement d'écran",
		"es": "Vibración pantalla",
		"uk": "Тремтіння екрану",
	},
	"particles": {
		"de": "Partikeleffekte",
		"en": "Particle Effects",
		"fr": "Effets particules",
		"es": "Efectos partículas",
		"uk": "Ефекти частинок",
	},
	"show_fps": {
		"de": "FPS anzeigen",
		"en": "Show FPS",
		"fr": "Afficher FPS",
		"es": "Mostrar FPS",
		"uk": "Показати FPS",
	},
	"q_high": {
		"de": "Hoch",
		"en": "High",
		"fr": "Élevé",
		"es": "Alto",
		"uk": "Високий",
	},
	"q_medium": {
		"de": "Mittel",
		"en": "Medium",
		"fr": "Moyen",
		"es": "Medio",
		"uk": "Середній",
	},
	"q_low": {
		"de": "Niedrig",
		"en": "Low",
		"fr": "Bas",
		"es": "Bajo",
		"uk": "Низький",
	},
	"q_off": {
		"de": "Aus",
		"en": "Off",
		"fr": "Désactivé",
		"es": "Desactivado",
		"uk": "Вимкнено",
	},
	"on_label": {
		"de": "AN",
		"en": "ON",
		"fr": "ACT.",
		"es": "ACT.",
		"uk": "УВІМК",
	},
	"off_label": {
		"de": "AUS",
		"en": "OFF",
		"fr": "DÉSACT.",
		"es": "DESACT.",
		"uk": "ВИМК",
	},
	"master_vol": {
		"de": "Master-Lautstärke",
		"en": "Master Volume",
		"fr": "Volume principal",
		"es": "Volumen maestro",
		"uk": "Загальна гучність",
	},
	"music_vol": {
		"de": "Musik",
		"en": "Music",
		"fr": "Musique",
		"es": "Música",
		"uk": "Музика",
	},
	"sfx_vol": {
		"de": "Soundeffekte",
		"en": "Sound Effects",
		"fr": "Effets sonores",
		"es": "Efectos sonido",
		"uk": "Звукові ефекти",
	},
	"kb_controls": {
		"de": "TASTATUR",
		"en": "KEYBOARD",
		"fr": "CLAVIER",
		"es": "TECLADO",
		"uk": "КЛАВІАТУРА",
	},
	"ctrl_controls": {
		"de": "CONTROLLER",
		"en": "CONTROLLER",
		"fr": "MANETTE",
		"es": "MANDO",
		"uk": "ҐЕЙМПАД",
	},
	"act_move_up": {
		"de": "Hoch",
		"en": "Move Up",
		"fr": "Monter",
		"es": "Arriba",
		"uk": "Вгору",
	},
	"act_move_down": {
		"de": "Runter",
		"en": "Move Down",
		"fr": "Descendre",
		"es": "Abajo",
		"uk": "Вниз",
	},
	"act_move_left": {
		"de": "Links",
		"en": "Move Left",
		"fr": "Gauche",
		"es": "Izquierda",
		"uk": "Вліво",
	},
	"act_move_right": {
		"de": "Rechts",
		"en": "Move Right",
		"fr": "Droite",
		"es": "Derecha",
		"uk": "Вправо",
	},
	"act_attack": {
		"de": "Angriff",
		"en": "Attack",
		"fr": "Attaque",
		"es": "Atacar",
		"uk": "Атака",
	},
	"act_special": {
		"de": "Spezial",
		"en": "Special",
		"fr": "Spécial",
		"es": "Especial",
		"uk": "Спеціальний",
	},
	"act_pause": {
		"de": "Pause",
		"en": "Pause",
		"fr": "Pause",
		"es": "Pausa",
		"uk": "Пауза",
	},
	"deadzone": {
		"de": "Totzone",
		"en": "Deadzone",
		"fr": "Zone morte",
		"es": "Zona muerta",
		"uk": "Мертва зона",
	},
	"reset_keys": {
		"de": "Standard wiederherstellen",
		"en": "Reset to Default",
		"fr": "Rétablir défauts",
		"es": "Restablecer",
		"uk": "Скинути",
	},
	"press_key": {
		"de": "[Taste drücken...]",
		"en": "[Press key...]",
		"fr": "[Appuyez...]",
		"es": "[Pulse tecla...]",
		"uk": "[Натисніть...]",
	},
	"click_rebind": {
		"de": "Klick → ändern",
		"en": "Click → rebind",
		"fr": "Clic → modifier",
		"es": "Clic → cambiar",
		"uk": "Клік → змінити",
	},
	"lang_title": {
		"de": "SPRACHE WÄHLEN",
		"en": "SELECT LANGUAGE",
		"fr": "CHOISIR LA LANGUE",
		"es": "SELECCIONAR IDIOMA",
		"uk": "ОБЕРІТЬ МОВУ",
	},
	"lang_hint": {
		"de": "Sprache wird sofort übernommen.",
		"en": "Language applied immediately.",
		"fr": "Langue appliquée immédiatement.",
		"es": "Idioma aplicado inmediatamente.",
		"uk": "Мову застосовано негайно.",
	},
	"lang_active": {
		"de": "✓ AKTIV",
		"en": "✓ ACTIVE",
		"fr": "✓ ACTIVE",
		"es": "✓ ACTIVO",
		"uk": "✓ АКТИВНА",
	},

	# ── Ingame HUD ────────────────────────────────────────────────────────────
	"hud_hp": {
		"de": "LP", "en": "HP", "fr": "PV", "es": "PS", "uk": "ЖК",
	},
	"hud_crowd": {
		"de": "CROWD", "en": "CROWD", "fr": "FOULE", "es": "MASA", "uk": "НАТОВП",
	},
	"hud_score_prefix": {
		"de": "Score: ", "en": "Score: ", "fr": "Score: ", "es": "Ptos: ", "uk": "Рахунок: ",
	},
	"hud_wave_prefix": {
		"de": "Welle ", "en": "Wave ", "fr": "Vague ", "es": "Oleada ", "uk": "Хвиля ",
	},
	"hud_ult_ready": {
		"de": "E: Ultimate [BEREIT]", "en": "E: Ultimate [READY]",
		"fr": "E: Ultime [PRÊT]", "es": "E: Último [LISTO]", "uk": "E: Ульт [ГОТОВО]",
	},
	"hud_enemies_left": {
		"de": " Gegner übrig", "en": " enemies left",
		"fr": " ennemis restants", "es": " enemigos", "uk": " ворогів",
	},
	"hud_enemies_spawn": {
		"de": " Gegner spawnen noch...", "en": " more incoming...",
		"fr": " ennemis en route...", "es": " más vienen...", "uk": " ще ворогів...",
	},
	"wave_banner": {
		"de": "WELLE %d", "en": "WAVE %d", "fr": "VAGUE %d", "es": "OLEADA %d", "uk": "ХВИЛЯ %d",
	},
	"boss_wave_banner": {
		"de": "BOSS WELLE %d!", "en": "BOSS WAVE %d!", "fr": "VAGUE BOSS %d!",
		"es": "¡OLEADA JEFA %d!", "uk": "БОSS ХВИЛЯ %d!",
	},
	"naht": {
		"de": "NAHT!  KEIN ENTKOMMEN!", "en": "IT APPROACHES!  NO ESCAPE!",
		"fr": "ÇA ARRIVE!  PAS D'ISSUE!", "es": "¡SE ACERCA!  ¡SIN ESCAPE!", "uk": "НАБЛИЖАЄТЬСЯ!  ВИХОДУ НЕМА!",
	},

	# ── Game Over ─────────────────────────────────────────────────────────────
	"show_complete": {
		"de": "SHOW ABGESCHLOSSEN!", "en": "SHOW COMPLETE!",
		"fr": "SHOW TERMINÉ!", "es": "¡SHOW COMPLETO!", "uk": "ШОУ ЗАВЕРШЕНО!",
	},
	"crowd_silent": {
		"de": "DIE WELT VERSINKT IN ABSOLUTER STILLE!", "en": "THE WORLD SINKS INTO ABSOLUTE SILENCE!",
		"fr": "LE MONDE SOMBRE DANS UN SILENCE ABSOLU!", "es": "¡EL MUNDO SE HUNDE EN SILENCIO ABSOLUTO!", "uk": "СВІТ ЗАНУРЮЄТЬСЯ В АБСОЛЮТНУ ТИШУ!",
	},
	"play_again": {
		"de": "NOCHMAL SPIELEN", "en": "PLAY AGAIN",
		"fr": "REJOUER", "es": "VOLVER A JUGAR", "uk": "ГРАТИ ЗНОВУ",
	},
	"main_menu": {
		"de": "HAUPTMENÜ", "en": "MAIN MENU",
		"fr": "MENU PRINCIPAL", "es": "MENÚ PRINCIPAL", "uk": "ГОЛОВНЕ МЕНЮ",
	},
	"main_menu_back": {
		"de": "← HAUPTMENÜ", "en": "← MAIN MENU",
		"fr": "← MENU PRINCIPAL", "es": "← MENÚ PRINCIPAL", "uk": "← ГОЛОВНЕ МЕНЮ",
	},
	"stat_final_score": {
		"de": "Endpunktzahl", "en": "Final Score",
		"fr": "Score final", "es": "Puntuación final", "uk": "Фінальний рахунок",
	},
	"stat_waves": {
		"de": "Wellen geschafft", "en": "Waves Cleared",
		"fr": "Vagues franchies", "es": "Oleadas superadas", "uk": "Хвиль пройдено",
	},
	"stat_kills": {
		"de": "Gegner besiegt", "en": "Enemies Killed",
		"fr": "Ennemis éliminés", "es": "Enemigos eliminados", "uk": "Ворогів вбито",
	},
	"stat_rhythm": {
		"de": "Rhythmus-Treffer", "en": "Rhythm Hits",
		"fr": "Coups rythmés", "es": "Golpes rítmicos", "uk": "Ритмічних влучань",
	},
	"stat_highscore": {
		"de": "Highscore", "en": "High Score",
		"fr": "Meilleur score", "es": "Mejor puntuación", "uk": "Рекорд",
	},
	"upgrades_lbl": {
		"de": "Upgrades:", "en": "Upgrades:", "fr": "Améliorations:", "es": "Mejoras:", "uk": "Апгрейди:",
	},

	# ── Pause ─────────────────────────────────────────────────────────────────
	"pause_title": {
		"de": "~ PAUSE ~", "en": "~ PAUSE ~", "fr": "~ PAUSE ~", "es": "~ PAUSA ~", "uk": "~ ПАУЗА ~",
	},
	"continue_btn": {
		"de": "▶   WEITER SPIELEN", "en": "▶   CONTINUE",
		"fr": "▶   CONTINUER", "es": "▶   CONTINUAR", "uk": "▶   ПРОДОВЖИТИ",
	},
	"esc_hint": {
		"de": "oder  ESC  drücken", "en": "or press ESC",
		"fr": "ou appuyer sur ESC", "es": "o pulsar ESC", "uk": "або натиснути ESC",
	},

	# ── Upgrade Shop ──────────────────────────────────────────────────────────
	"backstage_upgrades": {
		"de": "BACKSTAGE UPGRADES", "en": "BACKSTAGE UPGRADES",
		"fr": "AMÉLIORATIONS BACKSTAGE", "es": "MEJORAS BACKSTAGE", "uk": "БЕКСТЕЙДЖ АПГРЕЙДИ",
	},
	"wave_cleared_sub": {
		"de": "Welle %d abgeschlossen! Wähle dein Upgrade:",
		"en": "Wave %d cleared! Choose your upgrade:",
		"fr": "Vague %d franchie! Choisissez une amélioration:",
		"es": "¡Oleada %d superada! Elige tu mejora:",
		"uk": "Хвиля %d пройдена! Обери апгрейд:",
	},
	"skip": {
		"de": "ÜBERSPRINGEN", "en": "SKIP", "fr": "PASSER", "es": "SALTAR", "uk": "ПРОПУСТИТИ",
	},

	# ── Leaderboard ───────────────────────────────────────────────────────────
	"lb_title": {
		"de": "BESTENLISTE – ENDLESS MODE", "en": "LEADERBOARD – ENDLESS MODE",
		"fr": "CLASSEMENT – MODE INFINI", "es": "CLASIFICACIÓN – MODO INFINITO", "uk": "РЕКОРДИ – НЕСКІНЧЕННИЙ",
	},
	"game_over": {
		"de": "GAME OVER", "en": "GAME OVER", "fr": "GAME OVER", "es": "GAME OVER", "uk": "GAME OVER",
	},
	"enter_name": {
		"de": "NAME EINGEBEN (3 Buchstaben):", "en": "ENTER NAME (3 letters):",
		"fr": "ENTRER LE NOM (3 lettres):", "es": "INTRODUCIR NOMBRE (3 letras):", "uk": "ВВЕДІТЬ ІМ'Я (3 літери):",
	},
	"confirm_entry": {
		"de": "EINTRAGEN ✓", "en": "CONFIRM ✓", "fr": "CONFIRMER ✓", "es": "CONFIRMAR ✓", "uk": "ПІДТВЕРДИТИ ✓",
	},
	"kb_hint_lb": {
		"de": "Tastaturtipp: Buchstaben tippen  |  ← Backspace",
		"en": "Keyboard: type letters  |  ← Backspace",
		"fr": "Clavier: tapez des lettres  |  ← Retour",
		"es": "Teclado: escriba letras  |  ← Retroceso",
		"uk": "Клавіш: введіть літери  |  ← Backspace",
	},
	"top10": {
		"de": "TOP 10 – BESTENLISTE", "en": "TOP 10 – LEADERBOARD",
		"fr": "TOP 10 – CLASSEMENT", "es": "TOP 10 – CLASIFICACIÓN", "uk": "ТОП 10 – РЕКОРДИ",
	},
	"lb_empty": {
		"de": "Noch kein Eintrag – sei der Erste!", "en": "No entries yet – be the first!",
		"fr": "Pas encore d'entrée – soyez le premier!", "es": "Sin entradas aún – ¡sé el primero!",
		"uk": "Ще немає записів – будь першим!",
	},
	"lb_wave_col": {
		"de": "Welle", "en": "Wave", "fr": "Vague", "es": "Oleada", "uk": "Хвиля",
	},
	"lb_col_header": {
		"de": "#    NAME    WELLE    PUNKTE           MAP",
		"en": "#    NAME    WAVE     POINTS           MAP",
		"fr": "#    NOM     VAGUE    POINTS           MAP",
		"es": "#    NOMBRE  OLEADA   PUNTOS           MAP",
		"uk": "#    ІМ'Я    ХВИЛЯ    ОЧКИ             MAP",
	},
	"lb_stats_line": {
		"de": "Welle %d   •   Score: %d   •   Map: %s",
		"en": "Wave %d   •   Score: %d   •   Map: %s",
		"fr": "Vague %d   •   Score: %d   •   Map: %s",
		"es": "Oleada %d   •   Score: %d   •   Map: %s",
		"uk": "Хвиля %d   •   Score: %d   •   Map: %s",
	},

	# ── Character Select ──────────────────────────────────────────────────────
	"select_fighter": {
		"de": "WÄHLE DEINEN KÄMPFER", "en": "SELECT YOUR FIGHTER",
		"fr": "CHOISISSEZ VOTRE COMBATTANT", "es": "SELECCIONA TU LUCHADOR", "uk": "ОБЕРИ СВОГО БІЙЦЯ",
	},
	"difficulty_lbl": {
		"de": "SCHWIERIGKEITSGRAD:", "en": "DIFFICULTY:",
		"fr": "DIFFICULTÉ:", "es": "DIFICULTAD:", "uk": "СКЛАДНІСТЬ:",
	},
	"char_select": {
		"de": "AUSWÄHLEN", "en": "SELECT", "fr": "SÉLECTIONNER", "es": "SELECCIONAR", "uk": "ОБРАТИ",
	},
	"char_locked": {
		"de": "GESPERRT", "en": "LOCKED", "fr": "VERROUILLÉ", "es": "BLOQUEADO", "uk": "ЗАБЛОКОВАНО",
	},
	"char_unlock_hint": {
		"de": "Welle %d schaffen zum Freischalten",
		"en": "Beat wave %d to unlock",
		"fr": "Franchir la vague %d pour débloquer",
		"es": "Supera la oleada %d para desbloquear",
		"uk": "Пройди хвилю %d щоб відкрити",
	},
	"lets_play": {
		"de": "LOS GEHT'S!", "en": "LET'S PLAY!", "fr": "C'EST PARTI!", "es": "¡A JUGAR!", "uk": "ВПЕРЕД!",
	},
}

func _ready() -> void:
	var saved_lang = SaveManager.get_setting("language")
	if saved_lang and LANGUAGES.has(saved_lang):
		current_language = saved_lang
	else:
		current_language = "de"

func t(key: String) -> String:
	if TRANSLATIONS.has(key):
		var lang_map: Dictionary = TRANSLATIONS[key]
		if lang_map.has(current_language):
			return lang_map[current_language]
		elif lang_map.has("de"):
			return lang_map["de"]
	return key

func set_language(lang: String) -> void:
	if LANGUAGES.has(lang):
		current_language = lang
		SaveManager.set_setting("language", lang)
		emit_signal("language_changed", lang)
