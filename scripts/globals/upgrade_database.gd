extends Node

# All upgrades organized by category. Character-specific upgrades carry
# a "character" key and are only offered when that hero is selected.
#
# Lokalisierung: "name" bleibt in allen Sprachen englisch (Flavor-Namen wie
# Songtitel). "desc" ist Englisch, desc_de/fr/es/uk sind Uebersetzungen.
# Aufloesung ueber get_desc() unten.
const UPGRADES = {
	# Weapon upgrades
	"heavy_strings": {
		"id": "heavy_strings", "name": "Heavy Strings",
		"desc": "Drop-tune to C. +25% damage on every hit.",
		"desc_de": "Auf C runtergestimmt. +25% Schaden bei jedem Treffer.",
		"desc_fr": "Accordé en do grave. +25% de dégâts à chaque coup.",
		"desc_es": "Afinado en do grave. +25% de daño en cada golpe.",
		"desc_uk": "Стрій знижено до до. +25% шкоди за кожен удар.",
		"category": "weapon", "rarity": "common",
		"effect": {"damage_bonus": 0.25}
	},
	"faster_picks": {
		"id": "faster_picks", "name": "Faster Picks",
		"desc": "Tremolo fingers. +18% attack speed.",
		"desc_de": "Tremolo-Finger. +18% Angriffstempo.",
		"desc_fr": "Doigts tremolo. +18% de vitesse d'attaque.",
		"desc_es": "Dedos trémolo. +18% de velocidad de ataque.",
		"desc_uk": "Тремоло-пальці. +18% швидкості атаки.",
		"category": "weapon", "rarity": "common",
		"effect": {"attack_speed_bonus": 0.18}
	},
	"reverb_echo": {
		"id": "reverb_echo", "name": "Reverb Echo",
		"desc": "Cathedral hall. Projectiles bounce once extra.",
		"desc_de": "Kathedralen-Hall. Projektile prallen einmal extra ab.",
		"desc_fr": "Réverb de cathédrale. Les projectiles rebondissent une fois de plus.",
		"desc_es": "Reverb de catedral. Los proyectiles rebotan una vez más.",
		"desc_uk": "Соборна реверберація. Снаряди відбиваються ще раз.",
		"category": "weapon", "rarity": "rare",
		"effect": {"extra_bounce": 1}
	},
	"bass_boost": {
		"id": "bass_boost", "name": "Bass Boost",
		"desc": "Sub-frequencies kill faster. All shockwaves +35% radius.",
		"desc_de": "Sub-Frequenzen töten schneller. Alle Schockwellen +35% Radius.",
		"desc_fr": "Les sub-fréquences tuent plus vite. Ondes de choc +35% de rayon.",
		"desc_es": "Las subfrecuencias matan más rápido. Ondas de choque +35% de radio.",
		"desc_uk": "Суб-частоти вбивають швидше. Усі ударні хвилі +35% радіуса.",
		"category": "weapon", "rarity": "rare",
		"effect": {"aoe_radius_bonus": 0.35}
	},
	"piercing_riff": {
		"id": "piercing_riff", "name": "Piercing Riff",
		"desc": "Through-and-through. Projectiles pierce 1 extra enemy.",
		"desc_de": "Glatter Durchschuss. Projektile durchbohren 1 Gegner mehr.",
		"desc_fr": "De part en part. Les projectiles transpercent 1 ennemi de plus.",
		"desc_es": "De lado a lado. Los proyectiles atraviesan 1 enemigo más.",
		"desc_uk": "Наскрізь. Снаряди пронизують на 1 ворога більше.",
		"category": "weapon", "rarity": "rare",
		"effect": {"pierce": 1}
	},
	"double_strike": {
		"id": "double_strike", "name": "Double Strike",
		"desc": "Hammer-on madness. 25% chance to attack twice.",
		"desc_de": "Hammer-On-Wahnsinn. 25% Chance auf Doppelangriff.",
		"desc_fr": "Folie hammer-on. 25% de chance d'attaquer deux fois.",
		"desc_es": "Locura de hammer-on. 25% de probabilidad de atacar dos veces.",
		"desc_uk": "Хаммер-он божевілля. 25% шансу атакувати двічі.",
		"category": "weapon", "rarity": "rare",
		"effect": {"double_strike_chance": 0.25}
	},
	# Stats upgrades
	"steel_toes": {
		"id": "steel_toes", "name": "Steel Toes",
		"desc": "Combat boots. +35 max HP.",
		"desc_de": "Springerstiefel. +35 maximale LP.",
		"desc_fr": "Bottes coquées. +35 PV max.",
		"desc_es": "Botas de combate. +35 PS máximos.",
		"desc_uk": "Берці. +35 макс. ЖК.",
		"category": "stats", "rarity": "common",
		"effect": {"max_hp_bonus": 35}
	},
	"roadie_endurance": {
		"id": "roadie_endurance", "name": "Roadie Endurance",
		"desc": "Twelve-hour load-ins. +30 max HP, +10% move speed.",
		"desc_de": "Zwölf Stunden Aufbau. +30 max. LP, +10% Tempo.",
		"desc_fr": "Douze heures de montage. +30 PV max, +10% de vitesse.",
		"desc_es": "Doce horas de montaje. +30 PS máx, +10% de velocidad.",
		"desc_uk": "Дванадцять годин завантаження. +30 макс. ЖК, +10% швидкості.",
		"category": "stats", "rarity": "common",
		"effect": {"max_hp_bonus": 30, "speed_bonus": 0.10}
	},
	"adrenaline_rush": {
		"id": "adrenaline_rush", "name": "Adrenaline Rush",
		"desc": "Pre-show jitters. +12% move speed.",
		"desc_de": "Lampenfieber. +12% Bewegungstempo.",
		"desc_fr": "Trac d'avant-concert. +12% de vitesse.",
		"desc_es": "Nervios preconcierto. +12% de velocidad.",
		"desc_uk": "Передконцертний мандраж. +12% швидкості руху.",
		"category": "stats", "rarity": "common",
		"effect": {"speed_bonus": 0.12}
	},
	"mosh_pit_armor": {
		"id": "mosh_pit_armor", "name": "Mosh Pit Armor",
		"desc": "Battle-vest of patches. -18% damage taken.",
		"desc_de": "Kutte voller Patches. -18% erlittener Schaden.",
		"desc_fr": "Veste à patchs. -18% de dégâts subis.",
		"desc_es": "Chaleco de parches. -18% de daño recibido.",
		"desc_uk": "Жилет із нашивками. -18% отриманої шкоди.",
		"category": "stats", "rarity": "rare",
		"effect": {"damage_reduction": 0.18}
	},
	"stage_presence": {
		"id": "stage_presence", "name": "Stage Presence",
		"desc": "Pure intimidation. +55 max HP, heal 30 HP now.",
		"desc_de": "Pure Einschüchterung. +55 max. LP, sofort 30 LP Heilung.",
		"desc_fr": "Intimidation pure. +55 PV max, soigne 30 PV maintenant.",
		"desc_es": "Pura intimidación. +55 PS máx, cura 30 PS ahora.",
		"desc_uk": "Чисте залякування. +55 макс. ЖК, миттєво лікує 30 ЖК.",
		"category": "stats", "rarity": "rare",
		"effect": {"max_hp_bonus": 55, "heal_now": 30}
	},
	# Ability upgrades
	"amp_overdrive": {
		"id": "amp_overdrive", "name": "Amp Overdrive",
		"desc": "Tubes glow red. Ultimate cooldown -3.5s.",
		"desc_de": "Röhren glühen rot. Ultimate-Cooldown -3,5s.",
		"desc_fr": "Les lampes rougeoient. Recharge de l'ultime -3,5s.",
		"desc_es": "Las válvulas brillan en rojo. Enfriamiento del último -3,5s.",
		"desc_uk": "Лампи розжарені. Перезарядка ульти -3,5с.",
		"category": "ability", "rarity": "rare",
		"effect": {"ultimate_cooldown_reduction": 3.5}
	},
	"distortion_pedal": {
		"id": "distortion_pedal", "name": "Distortion Pedal",
		"desc": "Wall of fuzz. Ultimate slows everything in its AOE.",
		"desc_de": "Wand aus Fuzz. Ultimate verlangsamt alles im Wirkungsbereich.",
		"desc_fr": "Mur de fuzz. L'ultime ralentit tout dans sa zone.",
		"desc_es": "Muro de fuzz. El último ralentiza todo en su área.",
		"desc_uk": "Стіна фузу. Ульта сповільнює все в зоні дії.",
		"category": "ability", "rarity": "epic",
		"effect": {"ultimate_slow_aoe": true}
	},
	"power_chord": {
		"id": "power_chord", "name": "Power Chord",
		"desc": "All fingers on the same fret. Ultimate damage +50%.",
		"desc_de": "Alle Finger auf einem Bund. Ultimate-Schaden +50%.",
		"desc_fr": "Tous les doigts sur la même frette. Dégâts de l'ultime +50%.",
		"desc_es": "Todos los dedos en el mismo traste. Daño del último +50%.",
		"desc_uk": "Усі пальці на одному ладу. Шкода ульти +50%.",
		"category": "ability", "rarity": "epic",
		"effect": {"ultimate_damage_bonus": 0.50}
	},
	"encore": {
		"id": "encore", "name": "Encore",
		"desc": "The crowd demands more. +1 ultimate charge per wave.",
		"desc_de": "Das Publikum will mehr. +1 Ultimate-Ladung pro Welle.",
		"desc_fr": "Le public en redemande. +1 charge d'ultime par vague.",
		"desc_es": "El público pide más. +1 carga de último por oleada.",
		"desc_uk": "Натовп вимагає ще. +1 заряд ульти за хвилю.",
		"category": "ability", "rarity": "epic",
		"effect": {"ultimate_extra_charge": 1}
	},
	# Rhythm upgrades
	"crowd_surfer": {
		"id": "crowd_surfer", "name": "Crowd Surfer",
		"desc": "Hands keep you up. Crowd meter fills 25% faster.",
		"desc_de": "Hände tragen dich. Crowd-Meter füllt sich 25% schneller.",
		"desc_fr": "Porté par la foule. La jauge de foule se remplit 25% plus vite.",
		"desc_es": "Las manos te sostienen. El medidor de público se llena 25% más rápido.",
		"desc_uk": "Руки тримають тебе. Шкала натовпу заповнюється на 25% швидше.",
		"category": "rhythm", "rarity": "common",
		"effect": {"crowd_fill_bonus": 0.25}
	},
	"on_the_beat": {
		"id": "on_the_beat", "name": "On The Beat",
		"desc": "Internal click track. Rhythm hit window +0.06s.",
		"desc_de": "Innerer Klick-Track. Rhythmus-Fenster +0,06s.",
		"desc_fr": "Métronome intérieur. Fenêtre de rythme +0,06s.",
		"desc_es": "Claqueta interna. Ventana de ritmo +0,06s.",
		"desc_uk": "Внутрішній клік-трек. Вікно ритму +0,06с.",
		"category": "rhythm", "rarity": "common",
		"effect": {"rhythm_window_bonus": 0.06}
	},
	"groove_machine": {
		"id": "groove_machine", "name": "Groove Machine",
		"desc": "Pocket secured. Rhythm combo cap +2 (max x6).",
		"desc_de": "Groove sitzt. Rhythmus-Combo-Limit +2 (max. x6).",
		"desc_fr": "Groove verrouillé. Plafond de combo rythmique +2 (max x6).",
		"desc_es": "Groove asegurado. Límite de combo rítmico +2 (máx x6).",
		"desc_uk": "Грув упіймано. Ліміт ритм-комбо +2 (макс. x6).",
		"category": "rhythm", "rarity": "rare",
		"effect": {"combo_cap_bonus": 2}
	},
	"metronome": {
		"id": "metronome", "name": "Metronome",
		"desc": "Tick. Tick. Tick. Visual beat indicator appears.",
		"desc_de": "Tick. Tick. Tick. Visueller Beat-Indikator erscheint.",
		"desc_fr": "Tic. Tic. Tic. Un indicateur de beat visuel apparaît.",
		"desc_es": "Tic. Tic. Tic. Aparece un indicador visual del beat.",
		"desc_uk": "Тік. Тік. Тік. З'являється візуальний індикатор біта.",
		"category": "rhythm", "rarity": "common",
		"effect": {"show_beat_indicator": true}
	},
	"crowd_ignition": {
		"id": "crowd_ignition", "name": "Crowd Ignition",
		"desc": "Lighter aloft. Crowd meter bonus +12% per level.",
		"desc_de": "Feuerzeuge hoch. Crowd-Meter-Bonus +12% pro Stufe.",
		"desc_fr": "Briquets levés. Bonus de jauge de foule +12% par niveau.",
		"desc_es": "Mecheros en alto. Bono del medidor de público +12% por nivel.",
		"desc_uk": "Запальнички вгору. Бонус шкали натовпу +12% за рівень.",
		"category": "rhythm", "rarity": "epic",
		"effect": {"crowd_bonus_multiplier": 0.12}
	},
	# Special / Passive upgrades
	"kill_streak": {
		"id": "kill_streak", "name": "Kill Streak",
		"desc": "Body-count momentum. Every 5 kills: +6% damage this wave.",
		"desc_de": "Kill-Momentum. Alle 5 Kills: +6% Schaden in dieser Welle.",
		"desc_fr": "Élan meurtrier. Tous les 5 kills: +6% de dégâts cette vague.",
		"desc_es": "Impulso letal. Cada 5 bajas: +6% de daño esta oleada.",
		"desc_uk": "Інерція вбивств. Кожні 5 вбивств: +6% шкоди цієї хвилі.",
		"category": "special", "rarity": "rare",
		"effect": {"kill_streak_bonus": 0.06, "kill_streak_threshold": 5}
	},
	"vampire_riff": {
		"id": "vampire_riff", "name": "Vampire Riff",
		"desc": "Drink the kill. Heal 5 HP per enemy slain.",
		"desc_de": "Trink den Kill. 5 LP Heilung pro besiegtem Gegner.",
		"desc_fr": "Bois le kill. Soigne 5 PV par ennemi tué.",
		"desc_es": "Bebe la baja. Cura 5 PS por enemigo eliminado.",
		"desc_uk": "Випий вбивство. 5 ЖК зцілення за кожного ворога.",
		"category": "special", "rarity": "epic",
		"effect": {"lifesteal_per_kill": 5}
	},
	"feedback_loop": {
		"id": "feedback_loop", "name": "Feedback Loop",
		"desc": "Pain feeds the noise. Taking damage fills crowd meter.",
		"desc_de": "Schmerz füttert den Lärm. Erlittener Schaden füllt das Crowd-Meter.",
		"desc_fr": "La douleur nourrit le bruit. Subir des dégâts remplit la jauge de foule.",
		"desc_es": "El dolor alimenta el ruido. Recibir daño llena el medidor de público.",
		"desc_uk": "Біль живить шум. Отримана шкода заповнює шкалу натовпу.",
		"category": "special", "rarity": "rare",
		"effect": {"crowd_fill_on_hit": 0.04}
	},
	"wall_of_sound": {
		"id": "wall_of_sound", "name": "Wall of Sound",
		"desc": "Sonic mud. Projectiles leave a small slow zone on impact.",
		"desc_de": "Klangschlamm. Projektile hinterlassen beim Einschlag eine kleine Slow-Zone.",
		"desc_fr": "Boue sonore. Les projectiles laissent une zone de ralentissement à l'impact.",
		"desc_es": "Lodo sónico. Los proyectiles dejan una zona ralentizante al impactar.",
		"desc_uk": "Звукова багнюка. Снаряди лишають малу зону сповільнення при влучанні.",
		"category": "special", "rarity": "epic",
		"effect": {"projectile_slow_zone": true}
	},
	"roadie_rage": {
		"id": "roadie_rage", "name": "Roadie Rage",
		"desc": "Final stand mode. Below 25% HP: +35% damage, +25% speed.",
		"desc_de": "Letztes Gefecht. Unter 25% LP: +35% Schaden, +25% Tempo.",
		"desc_fr": "Dernier rempart. Sous 25% PV: +35% de dégâts, +25% de vitesse.",
		"desc_es": "Última resistencia. Bajo 25% PS: +35% de daño, +25% de velocidad.",
		"desc_uk": "Останній рубіж. Нижче 25% ЖК: +35% шкоди, +25% швидкості.",
		"category": "special", "rarity": "epic",
		"effect": {"rage_damage_bonus": 0.35, "rage_speed_bonus": 0.25, "rage_threshold": 0.25}
	},

	# --------------------------------------------------------------------------
	# CHARACTER-SPECIFIC UPGRADES (only offered when matching hero is selected)
	# --------------------------------------------------------------------------
	# Manni (drummer) - stacks on his kill-passive attack speed
	"manni_blast_beats": {
		"id": "manni_blast_beats", "name": "Blast Beats",
		"desc": "Manni: passive kill stacks cap at 15 (was 10).",
		"desc_de": "Manni: Kill-Stacks-Limit steigt auf 15 (vorher 10).",
		"desc_fr": "Manni: le plafond de stacks passe à 15 (au lieu de 10).",
		"desc_es": "Manni: el límite de acumulaciones sube a 15 (antes 10).",
		"desc_uk": "Манні: ліміт стаків зростає до 15 (було 10).",
		"category": "weapon", "rarity": "rare", "character": "manni",
		"effect": {"manni_extra_stacks": 5}
	},
	"manni_double_kick": {
		"id": "manni_double_kick", "name": "Double Kick",
		"desc": "Manni: ultimate fires a fourth shockwave ring.",
		"desc_de": "Manni: Ultimate feuert einen vierten Schockwellen-Ring.",
		"desc_fr": "Manni: l'ultime tire un quatrième anneau d'ondes de choc.",
		"desc_es": "Manni: el último dispara un cuarto anillo de ondas de choque.",
		"desc_uk": "Манні: ульта випускає четверте кільце ударних хвиль.",
		"category": "ability", "rarity": "epic", "character": "manni",
		"effect": {"manni_extra_ring": true}
	},
	# Shouter (chicken vocalist) - precision beams
	"shouter_brown_note": {
		"id": "shouter_brown_note", "name": "The Brown Note",
		"desc": "Shouter: every 3rd shout is a guaranteed crit (x2).",
		"desc_de": "Shouter: jeder 3. Schrei ist ein garantierter Krit (x2).",
		"desc_fr": "Shouter: un cri sur trois est un critique garanti (x2).",
		"desc_es": "Shouter: cada 3er grito es un crítico garantizado (x2).",
		"desc_uk": "Шаутер: кожен 3-й крик — гарантований крит (x2).",
		"category": "weapon", "rarity": "rare", "character": "shouter",
		"effect": {"shouter_third_crit": true}
	},
	"shouter_pyroclastic": {
		"id": "shouter_pyroclastic", "name": "Pyroclastic Howl",
		"desc": "Shouter: scream pierces 2 extra enemies.",
		"desc_de": "Shouter: Schrei durchbohrt 2 Gegner mehr.",
		"desc_fr": "Shouter: le cri transperce 2 ennemis de plus.",
		"desc_es": "Shouter: el grito atraviesa 2 enemigos más.",
		"desc_uk": "Шаутер: крик пронизує ще 2 ворогів.",
		"category": "weapon", "rarity": "rare", "character": "shouter",
		"effect": {"pierce": 2}
	},
	# Dreads - grappler with kill speed-boost
	"dreads_locked_in": {
		"id": "dreads_locked_in", "name": "Locked In",
		"desc": "Dreads: kill speed boost lasts +1.5s longer.",
		"desc_de": "Dreads: Kill-Tempo-Boost hält +1,5s länger.",
		"desc_fr": "Dreads: le boost de vitesse dure +1,5s de plus.",
		"desc_es": "Dreads: el impulso de velocidad dura +1,5s más.",
		"desc_uk": "Дредс: прискорення від вбивств триває на +1,5с довше.",
		"category": "stats", "rarity": "rare", "character": "dreads",
		"effect": {"dreads_boost_duration": 1.5}
	},
	"dreads_whip_chain": {
		"id": "dreads_whip_chain", "name": "Whip Chain",
		"desc": "Dreads: whip arcs to one extra enemy.",
		"desc_de": "Dreads: Peitsche springt auf einen weiteren Gegner über.",
		"desc_fr": "Dreads: le fouet atteint un ennemi de plus.",
		"desc_es": "Dreads: el látigo alcanza a un enemigo más.",
		"desc_uk": "Дредс: батіг перескакує на ще одного ворога.",
		"category": "weapon", "rarity": "epic", "character": "dreads",
		"effect": {"dreads_whip_chain": 1}
	},
	# Riff Slicer - string blades
	"riff_slicer_drop_d": {
		"id": "riff_slicer_drop_d", "name": "Drop D",
		"desc": "Riff Slicer: blades pierce 2 more enemies and stay sharp longer.",
		"desc_de": "Riff Slicer: Klingen durchbohren 2 Gegner mehr und bleiben länger scharf.",
		"desc_fr": "Riff Slicer: les lames transpercent 2 ennemis de plus et restent affûtées plus longtemps.",
		"desc_es": "Riff Slicer: las cuchillas atraviesan 2 enemigos más y siguen afiladas más tiempo.",
		"desc_uk": "Рифф Слайсер: леза пронизують ще 2 ворогів і довше лишаються гострими.",
		"category": "weapon", "rarity": "rare", "character": "riff_slicer",
		"effect": {"pierce": 2}
	},
	"riff_slicer_serrated": {
		"id": "riff_slicer_serrated", "name": "Serrated Strings",
		"desc": "Riff Slicer: blades apply bleed (extra damage over time).",
		"desc_de": "Riff Slicer: Klingen verursachen Blutung (Schaden über Zeit).",
		"desc_fr": "Riff Slicer: les lames infligent un saignement (dégâts sur la durée).",
		"desc_es": "Riff Slicer: las cuchillas causan sangrado (daño continuo).",
		"desc_uk": "Рифф Слайсер: леза спричиняють кровотечу (шкода з часом).",
		"category": "special", "rarity": "epic", "character": "riff_slicer",
		"effect": {"riff_slicer_bleed": true}
	},
	# Distortion - slow fields
	"distortion_feedback_field": {
		"id": "distortion_feedback_field", "name": "Feedback Field",
		"desc": "Distortion: slow field radius +30%, slows enemies harder.",
		"desc_de": "Distortion: Slow-Feld-Radius +30%, verlangsamt stärker.",
		"desc_fr": "Distortion: rayon du champ +30%, ralentit plus fort.",
		"desc_es": "Distortion: radio del campo +30%, ralentiza más.",
		"desc_uk": "Дисторшн: радіус поля +30%, сповільнює сильніше.",
		"category": "ability", "rarity": "rare", "character": "distortion",
		"effect": {"distortion_field_bonus": 0.30}
	},
	"distortion_overdrive_amp": {
		"id": "distortion_overdrive_amp", "name": "Overdrive Amp",
		"desc": "Distortion: slowed enemies take +25% damage from any source.",
		"desc_de": "Distortion: verlangsamte Gegner erleiden +25% Schaden aus allen Quellen.",
		"desc_fr": "Distortion: les ennemis ralentis subissent +25% de dégâts de toute source.",
		"desc_es": "Distortion: los enemigos ralentizados reciben +25% de daño de cualquier fuente.",
		"desc_uk": "Дисторшн: сповільнені вороги отримують +25% шкоди з будь-якого джерела.",
		"category": "special", "rarity": "epic", "character": "distortion",
		"effect": {"distortion_slow_damage_bonus": 0.25}
	},
	# Bassist - shockwaves on kill
	"bassist_sub_frequency": {
		"id": "bassist_sub_frequency", "name": "Sub Frequency",
		"desc": "Bassist: kill shockwaves +40% radius and deal +25% damage.",
		"desc_de": "Bassist: Kill-Schockwellen +40% Radius und +25% Schaden.",
		"desc_fr": "Bassist: ondes de choc +40% de rayon et +25% de dégâts.",
		"desc_es": "Bassist: ondas de choque +40% de radio y +25% de daño.",
		"desc_uk": "Басист: ударні хвилі +40% радіуса і +25% шкоди.",
		"category": "weapon", "rarity": "rare", "character": "bassist",
		"effect": {"bassist_shockwave_bonus": 0.25, "aoe_radius_bonus": 0.40}
	},
	"bassist_low_end_theory": {
		"id": "bassist_low_end_theory", "name": "Low End Theory",
		"desc": "Bassist: every 4th hit emits a mini shockwave.",
		"desc_de": "Bassist: jeder 4. Treffer löst eine Mini-Schockwelle aus.",
		"desc_fr": "Bassist: un coup sur quatre émet une mini onde de choc.",
		"desc_es": "Bassist: cada 4º golpe emite una mini onda de choque.",
		"desc_uk": "Басист: кожен 4-й удар випускає міні ударну хвилю.",
		"category": "weapon", "rarity": "epic", "character": "bassist",
		"effect": {"bassist_periodic_wave": true}
	},
}

# Liefert die Upgrade-Beschreibung in der aktiven Sprache.
# "desc" ist die englische Basis, desc_de/fr/es/uk die Uebersetzungen.
func get_desc(upgrade: Dictionary) -> String:
	var lang: String = LocalizationManager.current_language
	if lang == "en":
		return upgrade.get("desc", "")
	return upgrade.get("desc_" + lang, upgrade.get("desc", ""))

func get_random_upgrades(count: int = 3, exclude: Array = []) -> Array:
	# Determine which character-specific upgrades are valid for this run.
	# Co-op runs include upgrades for any selected character.
	var allowed_chars: Dictionary = {}
	if "selected_characters" in GameManager and GameManager.player_count >= 2:
		for c in GameManager.selected_characters:
			allowed_chars[c] = true
	else:
		allowed_chars[GameManager.selected_character] = true

	var available: Array = []
	for id in UPGRADES:
		if id in exclude:
			continue
		var upg = UPGRADES[id]
		# Filter character-locked upgrades out if the hero isn't on the team
		var ch = upg.get("character", "")
		if ch != "" and not allowed_chars.has(ch):
			continue
		available.append(upg)

	# Weight by rarity (commons appear more, character upgrades get a small boost)
	var weighted: Array = []
	for upgrade in available:
		match upgrade["rarity"]:
			"common": weighted.append_array([upgrade, upgrade, upgrade])
			"rare": weighted.append_array([upgrade, upgrade])
			"epic": weighted.append(upgrade)
		# Character-specific upgrades get one extra slot to keep them visible
		if upgrade.get("character", "") != "":
			weighted.append(upgrade)

	weighted.shuffle()

	var result: Array = []
	var seen_ids: Array = []
	for upgrade in weighted:
		if upgrade["id"] not in seen_ids:
			result.append(upgrade)
			seen_ids.append(upgrade["id"])
			if result.size() >= count:
				break

	return result

func get_upgrade(id: String) -> Dictionary:
	return UPGRADES.get(id, {})
