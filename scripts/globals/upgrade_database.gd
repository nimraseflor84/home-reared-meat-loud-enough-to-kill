extends Node

# All 25 upgrades organized by category
const UPGRADES = {
	# Weapon upgrades
	"heavy_strings": {
		"id": "heavy_strings", "name": "Heavy Strings",
		"desc": "+20% damage to all attacks",
		"category": "weapon", "rarity": "common",
		"effect": {"damage_bonus": 0.20}
	},
	"faster_picks": {
		"id": "faster_picks", "name": "Faster Picks",
		"desc": "+15% attack speed",
		"category": "weapon", "rarity": "common",
		"effect": {"attack_speed_bonus": 0.15}
	},
	"reverb_echo": {
		"id": "reverb_echo", "name": "Reverb Echo",
		"desc": "Projectiles bounce once extra",
		"category": "weapon", "rarity": "rare",
		"effect": {"extra_bounce": 1}
	},
	"bass_boost": {
		"id": "bass_boost", "name": "Bass Boost",
		"desc": "All sound waves +30% radius",
		"category": "weapon", "rarity": "rare",
		"effect": {"aoe_radius_bonus": 0.30}
	},
	"piercing_riff": {
		"id": "piercing_riff", "name": "Piercing Riff",
		"desc": "Projectiles pierce 1 extra enemy",
		"category": "weapon", "rarity": "rare",
		"effect": {"pierce": 1}
	},
	"double_strike": {
		"id": "double_strike", "name": "Double Strike",
		"desc": "20% chance to attack twice",
		"category": "weapon", "rarity": "rare",
		"effect": {"double_strike_chance": 0.20}
	},
	# Stats upgrades
	"steel_toes": {
		"id": "steel_toes", "name": "Steel Toes",
		"desc": "+30 max HP",
		"category": "stats", "rarity": "common",
		"effect": {"max_hp_bonus": 30}
	},
	"roadie_endurance": {
		"id": "roadie_endurance", "name": "Roadie Endurance",
		"desc": "+25 max HP, +8% movement speed",
		"category": "stats", "rarity": "common",
		"effect": {"max_hp_bonus": 25, "speed_bonus": 0.08}
	},
	"adrenaline_rush": {
		"id": "adrenaline_rush", "name": "Adrenaline Rush",
		"desc": "+10% movement speed",
		"category": "stats", "rarity": "common",
		"effect": {"speed_bonus": 0.10}
	},
	"mosh_pit_armor": {
		"id": "mosh_pit_armor", "name": "Mosh Pit Armor",
		"desc": "-15% damage taken",
		"category": "stats", "rarity": "rare",
		"effect": {"damage_reduction": 0.15}
	},
	"stage_presence": {
		"id": "stage_presence", "name": "Stage Presence",
		"desc": "+50 max HP, heal 20 HP now",
		"category": "stats", "rarity": "rare",
		"effect": {"max_hp_bonus": 50, "heal_now": 20}
	},
	# Ability upgrades
	"amp_overdrive": {
		"id": "amp_overdrive", "name": "Amp Overdrive",
		"desc": "Ultimate cooldown -3 seconds",
		"category": "ability", "rarity": "rare",
		"effect": {"ultimate_cooldown_reduction": 3.0}
	},
	"distortion_pedal": {
		"id": "distortion_pedal", "name": "Distortion Pedal",
		"desc": "Slow AOE on ultimate",
		"category": "ability", "rarity": "epic",
		"effect": {"ultimate_slow_aoe": true}
	},
	"power_chord": {
		"id": "power_chord", "name": "Power Chord",
		"desc": "Ultimate damage +40%",
		"category": "ability", "rarity": "epic",
		"effect": {"ultimate_damage_bonus": 0.40}
	},
	"encore": {
		"id": "encore", "name": "Encore",
		"desc": "Ultimate can be used one extra time per wave",
		"category": "ability", "rarity": "epic",
		"effect": {"ultimate_extra_charge": 1}
	},
	# Rhythm upgrades
	"crowd_surfer": {
		"id": "crowd_surfer", "name": "Crowd Surfer",
		"desc": "Crowd meter fills 20% faster",
		"category": "rhythm", "rarity": "common",
		"effect": {"crowd_fill_bonus": 0.20}
	},
	"on_the_beat": {
		"id": "on_the_beat", "name": "On The Beat",
		"desc": "Rhythm hit window +0.05s",
		"category": "rhythm", "rarity": "common",
		"effect": {"rhythm_window_bonus": 0.05}
	},
	"groove_machine": {
		"id": "groove_machine", "name": "Groove Machine",
		"desc": "Rhythm combo cap +2 (max x6)",
		"category": "rhythm", "rarity": "rare",
		"effect": {"combo_cap_bonus": 2}
	},
	"metronome": {
		"id": "metronome", "name": "Metronome",
		"desc": "Visual beat indicator appears",
		"category": "rhythm", "rarity": "common",
		"effect": {"show_beat_indicator": true}
	},
	"crowd_ignition": {
		"id": "crowd_ignition", "name": "Crowd Ignition",
		"desc": "Crowd meter gives +10% more bonus per level",
		"category": "rhythm", "rarity": "epic",
		"effect": {"crowd_bonus_multiplier": 0.10}
	},
	# Special/Passive upgrades
	"kill_streak": {
		"id": "kill_streak", "name": "Kill Streak",
		"desc": "Every 5 kills: +5% damage this wave",
		"category": "special", "rarity": "rare",
		"effect": {"kill_streak_bonus": 0.05, "kill_streak_threshold": 5}
	},
	"vampire_riff": {
		"id": "vampire_riff", "name": "Vampire Riff",
		"desc": "Heal 4 HP per kill",
		"category": "special", "rarity": "epic",
		"effect": {"lifesteal_per_kill": 4}
	},
	"feedback_loop": {
		"id": "feedback_loop", "name": "Feedback Loop",
		"desc": "Taking damage fills crowd meter slightly",
		"category": "special", "rarity": "rare",
		"effect": {"crowd_fill_on_hit": 0.03}
	},
	"wall_of_sound": {
		"id": "wall_of_sound", "name": "Wall of Sound",
		"desc": "Projectiles create a small slow zone on impact",
		"category": "special", "rarity": "epic",
		"effect": {"projectile_slow_zone": true}
	},
	"roadie_rage": {
		"id": "roadie_rage", "name": "Roadie Rage",
		"desc": "Below 25% HP: +30% damage, +20% speed",
		"category": "special", "rarity": "epic",
		"effect": {"rage_damage_bonus": 0.30, "rage_speed_bonus": 0.20, "rage_threshold": 0.25}
	},
}

func get_random_upgrades(count: int = 3, exclude: Array = []) -> Array:
	var available = []
	for id in UPGRADES:
		if id not in exclude:
			available.append(UPGRADES[id])

	# Weight by rarity (commons appear more)
	var weighted = []
	for upgrade in available:
		match upgrade["rarity"]:
			"common": weighted.append_array([upgrade, upgrade, upgrade])
			"rare": weighted.append_array([upgrade, upgrade])
			"epic": weighted.append(upgrade)

	weighted.shuffle()

	var result = []
	var seen_ids = []
	for upgrade in weighted:
		if upgrade["id"] not in seen_ids:
			result.append(upgrade)
			seen_ids.append(upgrade["id"])
			if result.size() >= count:
				break

	return result

func get_upgrade(id: String) -> Dictionary:
	return UPGRADES.get(id, {})
