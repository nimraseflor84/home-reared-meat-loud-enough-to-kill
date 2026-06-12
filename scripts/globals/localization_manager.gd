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
	"stat_damage_dealt": {
		"de": "Schaden ausgeteilt", "en": "Damage Dealt",
		"fr": "Dégâts infligés", "es": "Daño causado", "uk": "Завдано шкоди",
	},
	"stat_time_played": {
		"de": "Spielzeit", "en": "Time Played",
		"fr": "Temps de jeu", "es": "Tiempo jugado", "uk": "Час гри",
	},
	"new_high_score": {
		"de": "★ NEUER HIGHSCORE ★", "en": "* NEW HIGH SCORE *",
		"fr": "* NOUVEAU RECORD *", "es": "* NUEVO RÉCORD *", "uk": "* НОВИЙ РЕКОРД *",
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
	"options_btn": {
		"de": "OPTIONEN", "en": "OPTIONS",
		"fr": "OPTIONS", "es": "OPCIONES", "uk": "НАЛАШТУВАННЯ",
	},
	"restart_run": {
		"de": "RUN NEUSTARTEN", "en": "RESTART RUN",
		"fr": "REDÉMARRER", "es": "REINICIAR PARTIDA", "uk": "ПЕРЕЗАПУСТИТИ",
	},
	"next_wave_enemies": {
		"de": "GEGNER IN DER NÄCHSTEN WELLE: %d",
		"en": "ENEMIES IN NEXT WAVE: %d",
		"fr": "ENNEMIS DANS LA PROCHAINE VAGUE : %d",
		"es": "ENEMIGOS EN LA PRÓXIMA OLEADA: %d",
		"uk": "ВОРОГІВ У НАСТУПНІЙ ХВИЛІ: %d",
	},
	"shop_incoming": {
		"de": "★ BACKSTAGE-SHOP ÖFFNET ★",
		"en": "* BACKSTAGE SHOP OPENS *",
		"fr": "* LA BOUTIQUE BACKSTAGE OUVRE *",
		"es": "* LA TIENDA BACKSTAGE ABRE *",
		"uk": "* БЕКСТЕЙДЖ-МАГАЗИН ВІДКРИВАЄТЬСЯ *",
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

	# ── Endless Map Select ────────────────────────────────────────────────────
	"endless_map_select": {
		"de": "ENDLESS MODE – MAP WÄHLEN",
		"en": "ENDLESS MODE – SELECT MAP",
		"fr": "MODE INFINI – CHOISIR LA MAP",
		"es": "MODO INFINITO – ELEGIR MAPA",
		"uk": "НЕСКІНЧЕННО – ОБЕРІТЬ КАРТУ",
	},
	"charakter_lbl": {
		"de": "CHARAKTER:", "en": "CHARACTER:", "fr": "PERSONNAGE:", "es": "PERSONAJE:", "uk": "ПЕРСОНАЖ:",
	},
	"schwierigkeit_lbl": {
		"de": "SCHWIERIGKEIT:", "en": "DIFFICULTY:", "fr": "DIFFICULTÉ:", "es": "DIFICULTAD:", "uk": "СКЛАДНІСТЬ:",
	},
	"start_endless": {
		"de": "START ENDLESS!", "en": "START ENDLESS!", "fr": "COMMENCER!", "es": "¡EMPEZAR!", "uk": "СТАРТ!",
	},

	# ── Options – Sound ───────────────────────────────────────────────────────
	"sound_tip": {
		"de": "Tipp: Lautstärke auch mit F1/F2 im Spiel änderbar.",
		"en": "Tip: Volume can also be changed with F1/F2 in-game.",
		"fr": "Conseil: le volume peut être changé avec F1/F2 en jeu.",
		"es": "Consejo: el volumen también se puede cambiar con F1/F2.",
		"uk": "Підказка: гучність також можна змінити F1/F2 у грі.",
	},

	# ── Options – Controls ────────────────────────────────────────────────────
	"press_button": {
		"de": "Knopf drücken", "en": "Press button", "fr": "Appuyer bouton",
		"es": "Pulsar botón", "uk": "Натисніть кнопку",
	},
	"reset_controller": {
		"de": "Controller zurücksetzen", "en": "Reset Controller",
		"fr": "Réinitialiser manette", "es": "Restablecer mando", "uk": "Скинути ґеймпад",
	},

	# ── Options – Gameplay / Highscore ────────────────────────────────────────
	"hs_display": {
		"de": "Highscore: %d  |  Beste Wave: %d",
		"en": "High Score: %d  |  Best Wave: %d",
		"fr": "Meilleur score: %d  |  Meilleure vague: %d",
		"es": "Mejor puntuación: %d  |  Mejor oleada: %d",
		"uk": "Рекорд: %d  |  Краща хвиля: %d",
	},
	"hs_reset_btn": {
		"de": "Highscore zurücksetzen", "en": "Reset High Score",
		"fr": "Réinitialiser le score", "es": "Restablecer puntuación", "uk": "Скинути рекорд",
	},
	"hs_confirm": {
		"de": "Sicher? Nochmal klicken!", "en": "Sure? Click again!",
		"fr": "Sûr? Cliquez encore!", "es": "¿Seguro? ¡Clic de nuevo!", "uk": "Впевнений? Клікни ще!",
	},
	"hs_done": {
		"de": "✓ Zurückgesetzt", "en": "✓ Reset",
		"fr": "✓ Réinitialisé", "es": "✓ Restablecido", "uk": "✓ Скинуто",
	},

	# ── Main Menu ─────────────────────────────────────────────────────────────
	"hs_prefix": {
		"de": "Highscore: ", "en": "High Score: ",
		"fr": "Meilleur score: ", "es": "Mejor puntuación: ", "uk": "Рекорд: ",
	},

	# ── HUD: Dash & Ultimate ──────────────────────────────────────────────────
	"dash_hint": {
		"de": "DASH: SHIFT / RECHTE MAUSTASTE", "en": "DASH: SHIFT / RIGHT MOUSE",
		"fr": "DASH: MAJ / CLIC DROIT", "es": "DASH: SHIFT / CLIC DERECHO", "uk": "РИВОК: SHIFT / ПРАВА КНОПКА",
	},
	"hud_ult_cd": {
		"de": "E: Ultimate [%.1fs]", "en": "E: Ultimate [%.1fs]",
		"fr": "E: Ultime [%.1fs]", "es": "E: Último [%.1fs]", "uk": "E: Ульт [%.1fs]",
	},

	# ── Co-op / Netzwerk ──────────────────────────────────────────────────────
	"p2_label": {
		"de": "SPIELER 2:", "en": "PLAYER 2:", "fr": "JOUEUR 2:", "es": "JUGADOR 2:", "uk": "ГРАВЕЦЬ 2:",
	},
	"net_title": {
		"de": "WiFi CO-OP", "en": "WiFi CO-OP", "fr": "CO-OP WiFi", "es": "CO-OP WiFi", "uk": "WiFi КООП",
	},
	"net_host": {
		"de": "HOSTEN", "en": "HOST", "fr": "HÉBERGER", "es": "CREAR", "uk": "СТВОРИТИ",
	},
	"net_join": {
		"de": "BEITRETEN", "en": "JOIN", "fr": "REJOINDRE", "es": "UNIRSE", "uk": "ПРИЄДНАТИСЯ",
	},
	"net_waiting": {
		"de": "Deine IP: %s   Port: 7777   –   Warte auf Spieler …",
		"en": "Your IP: %s   Port: 7777   –   Waiting for player …",
		"fr": "Ton IP: %s   Port: 7777   –   En attente d'un joueur …",
		"es": "Tu IP: %s   Puerto: 7777   –   Esperando jugador …",
		"uk": "Твоя IP: %s   Порт: 7777   –   Очікування гравця …",
	},
	"net_enter_ip": {
		"de": "Bitte Host-IP eingeben!", "en": "Please enter the host IP!",
		"fr": "Entre l'IP de l'hôte!", "es": "¡Introduce la IP del host!", "uk": "Введіть IP хоста!",
	},
	"net_connecting": {
		"de": "Verbinde mit %s …", "en": "Connecting to %s …",
		"fr": "Connexion à %s …", "es": "Conectando con %s …", "uk": "З'єднання з %s …",
	},
	"net_conn_error": {
		"de": "Verbindungsfehler %d – IP korrekt?", "en": "Connection error %d – IP correct?",
		"fr": "Erreur de connexion %d – IP correcte?", "es": "Error de conexión %d – ¿IP correcta?", "uk": "Помилка з'єднання %d – IP вірна?",
	},
	"net_conn_failed": {
		"de": "Verbindung fehlgeschlagen – Host erreichbar?", "en": "Connection failed – host reachable?",
		"fr": "Connexion échouée – hôte joignable?", "es": "Conexión fallida – ¿host accesible?", "uk": "З'єднання не вдалося – хост доступний?",
	},
	"net_p2_connected": {
		"de": "Spieler 2 verbunden!", "en": "Player 2 connected!",
		"fr": "Joueur 2 connecté!", "es": "¡Jugador 2 conectado!", "uk": "Гравець 2 підключився!",
	},
	"net_connected_wait": {
		"de": "Verbunden! Warte auf Host …", "en": "Connected! Waiting for host …",
		"fr": "Connecté! En attente de l'hôte …", "es": "¡Conectado! Esperando al host …", "uk": "Підключено! Очікування хоста …",
	},

	# ── Upgrade Shop ──────────────────────────────────────────────────────────
	"take_it": {
		"de": "NIMM ES!", "en": "TAKE IT!", "fr": "PRENDS-LE!", "es": "¡TÓMALO!", "uk": "БЕРИ!",
	},

	# ── Tutorial ──────────────────────────────────────────────────────────────
	"how_to_play": {
		"de": "SO WIRD GESPIELT", "en": "HOW TO PLAY",
		"fr": "COMMENT JOUER", "es": "CÓMO JUGAR", "uk": "ЯК ГРАТИ",
	},
	"btn_prev": {
		"de": "< ZURÜCK", "en": "< PREV", "fr": "< PRÉC.", "es": "< ANTERIOR", "uk": "< НАЗАД",
	},
	"btn_next": {
		"de": "WEITER >", "en": "NEXT >", "fr": "SUIVANT >", "es": "SIGUIENTE >", "uk": "ДАЛІ >",
	},
	"btn_start": {
		"de": "START", "en": "START", "fr": "GO!", "es": "EMPEZAR", "uk": "СТАРТ",
	},
	"lore_new": {
		"de": "NEU: ", "en": "NEW: ", "fr": "NOUVEAU: ", "es": "NUEVO: ", "uk": "НОВЕ: ",
	},
	"no_song": {
		"de": "-- kein Song --", "en": "-- no song --", "fr": "-- aucun titre --",
		"es": "-- sin canción --", "uk": "-- немає пісні --",
	},
	"next_song": {
		"de": ">> Nächster Song", "en": ">> Next song", "fr": ">> Titre suivant",
		"es": ">> Siguiente canción", "uk": ">> Наступна пісня",
	},

	# ── Maps (Titel + Untertitel) ─────────────────────────────────────────────
	"map_farm_title": {
		"de": "Die Farm", "en": "The Farm", "fr": "La Ferme", "es": "La Granja", "uk": "Ферма",
	},
	"map_farm_sub": {
		"de": "Irgendwo in Niedersachsen...", "en": "Somewhere in Lower Saxony...",
		"fr": "Quelque part en Basse-Saxe...", "es": "En algún lugar de Baja Sajonia...", "uk": "Десь у Нижній Саксонії...",
	},
	"map_prison_title": {
		"de": "Das Gefängnis", "en": "The Prison", "fr": "La Prison", "es": "La Prisión", "uk": "В'язниця",
	},
	"map_prison_sub": {
		"de": "3 Jahre wegen Lärmbelästigung", "en": "3 years for noise violations",
		"fr": "3 ans pour tapage nocturne", "es": "3 años por ruido excesivo", "uk": "3 роки за порушення тиші",
	},
	"map_proberaum_title": {
		"de": "Der Proberaum", "en": "The Rehearsal Room", "fr": "Le Local de Répèt", "es": "La Sala de Ensayo", "uk": "Репетиційна",
	},
	"map_proberaum_sub": {
		"de": "Nachbarn wieder sauer...", "en": "Neighbors angry again...",
		"fr": "Les voisins sont fâchés...", "es": "Los vecinos enfadados otra vez...", "uk": "Сусіди знову злі...",
	},
	"map_schweinestall_title": {
		"de": "Der Schweinestall", "en": "The Pigsty", "fr": "La Porcherie", "es": "La Pocilga", "uk": "Свинарник",
	},
	"map_schweinestall_sub": {
		"de": "Riecht nach Musik", "en": "Smells like music",
		"fr": "Ça sent la musique", "es": "Huele a música", "uk": "Пахне музикою",
	},
	"map_amerika_title": {
		"de": "Amerika", "en": "America", "fr": "L'Amérique", "es": "América", "uk": "Америка",
	},
	"map_amerika_sub": {
		"de": "Road Trip from Hell", "en": "Road Trip from Hell",
		"fr": "Road trip infernal", "es": "Viaje infernal", "uk": "Пекельна подорож",
	},
	"map_truck_title": {
		"de": "Fahrender Truck", "en": "Moving Truck", "fr": "Camion en Route", "es": "Camión en Marcha", "uk": "Вантажівка на ходу",
	},
	"map_truck_sub": {
		"de": "270 km/h auf der A31", "en": "270 km/h on the A31",
		"fr": "270 km/h sur l'A31", "es": "270 km/h por la A31", "uk": "270 км/год по A31",
	},
	"map_tonstudio_title": {
		"de": "Tonstudio Soundlodge", "en": "Soundlodge Studio", "fr": "Studio Soundlodge", "es": "Estudio Soundlodge", "uk": "Студія Soundlodge",
	},
	"map_tonstudio_sub": {
		"de": "Rhauderfehn, Ostfriesland...", "en": "Rhauderfehn, East Frisia...",
		"fr": "Rhauderfehn, Frise orientale...", "es": "Rhauderfehn, Frisia Oriental...", "uk": "Раудерфен, Східна Фризія...",
	},
	"map_tv_studio_title": {
		"de": "TV Studio", "en": "TV Studio", "fr": "Studio TV", "es": "Estudio de TV", "uk": "Телестудія",
	},
	"map_tv_studio_sub": {
		"de": "Live auf Sendung", "en": "Live on Air",
		"fr": "En direct", "es": "En directo", "uk": "У прямому ефірі",
	},
	"map_meppen_title": {
		"de": "Meppen", "en": "Meppen", "fr": "Meppen", "es": "Meppen", "uk": "Меппен",
	},
	"map_meppen_sub": {
		"de": "Stadt der Verdammten", "en": "City of the Damned",
		"fr": "Ville des damnés", "es": "Ciudad de los condenados", "uk": "Місто проклятих",
	},
	"map_death_feast_title": {
		"de": "Death Feast", "en": "Death Feast", "fr": "Death Feast", "es": "Death Feast", "uk": "Death Feast",
	},
	"map_death_feast_sub": {
		"de": "Bühne Andernach – letzte Chance!", "en": "Andernach stage – last chance!",
		"fr": "Scène d'Andernach – dernière chance!", "es": "Escenario Andernach – ¡última oportunidad!", "uk": "Сцена Андернах – останній шанс!",
	},
}

# Liefert Map-Titel und -Untertitel in der aktiven Sprache
func map_title(map_id: String) -> String:
	return t("map_%s_title" % map_id)

func map_subtitle(map_id: String) -> String:
	return t("map_%s_sub" % map_id)

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
