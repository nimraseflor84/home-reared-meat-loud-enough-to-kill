extends CharacterBody2D

const _PROJ_SCENE = preload("res://scenes/entities/projectiles/projectile.tscn")
const _SW_SCENE   = preload("res://scenes/entities/projectiles/shockwave.tscn")

# Stats
@export var max_hp: int = 100
@export var move_speed: float = 200.0
@export var base_damage: float = 20.0
@export var attack_speed: float = 1.0  # attacks per second
@export var character_id: String = "base"
@export var ultimate_cooldown: float = 15.0

var current_hp: int
var attack_timer: float = 0.0
var ultimate_timer: float = 0.0
var is_alive: bool = true

# Signature-Waffe (freigeschaltet durch Sieg auf Drink Fight Die!). Wenn true,
# nutzt der Charakter _auto_attack_signature() statt _auto_attack().
var signature_active: bool = false

# Co-op: Spieler-Index und Controller-Geraet
var player_index: int = 0    # 0=P1, 1=P2
var _joy_device: int = -1    # -1=InputMap (P1), >=0=direkter Joypad (P2)
var _ult_was_pressed: bool = false

# Upgrade bonuses
var damage_bonus: float = 0.0
var speed_bonus: float = 0.0
var attack_speed_bonus: float = 0.0
var max_hp_bonus: int = 0
var damage_reduction: float = 0.0
var aoe_radius_bonus: float = 0.0
var pierce: int = 0
var extra_bounce: int = 0
var double_strike_chance: float = 0.0
var ultimate_cooldown_reduction: float = 0.0
var lifesteal_per_kill: int = 0
var kill_count_this_wave: int = 0
var kills_total: int = 0

# Encore upgrade - extra ultimate charge per wave
var _encore_charges: int = 0       # total extras from upgrades (stacks)
var _encore_used_this_wave: int = 0  # resets each wave

# -- XP / Level system --------------------------------------------------------
# Cumulative XP thresholds for levels 2..10. Reaching threshold = ding.
const _XP_THRESHOLDS: Array = [50, 120, 220, 360, 550, 800, 1100, 1450, 1850, 2300]
const MAX_LEVEL: int = 10
var xp: int = 0
var level: int = 1
var _levelup_flash: float = 0.0       # visual flash timer
var _levelup_text_timer: float = 0.0  # floating text duration
var _levelup_text_offset: float = 0.0 # floating text rises over time

signal leveled_up(new_level)

# Death animation
var _death_anim: float = -1.0
var _death_ptcls: Array = []

# Rhythm bonuses
var rhythm_damage_bonus: float = 0.0  # set by rhythm system
var crowd_damage_bonus: float = 0.0   # set by crowd meter

# Netzwerk
var _use_network_input: bool = false   # P2 auf Host: Input kommt per RPC
var _net_input_dir: Vector2 = Vector2.ZERO
var _net_input_buttons: int = 0        # bit0=dash, bit1=ult

var _is_remote: bool = false           # Dieser Spieler laeuft auf dem anderen Geraet
var _remote_target_pos: Vector2 = Vector2.ZERO

func _apply_net_input(dir: Vector2, buttons: int) -> void:
	_net_input_dir     = dir
	_net_input_buttons = buttons

# Dash
const _DASH_SPEED_MULT    := 4.5
const _DASH_DURATION      := 0.18
const _DASH_COOLDOWN      := 1.5
var _dash_timer:     float = 0.0   # > 0 = gerade am Dashen
var _dash_cooldown_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _dash_was_pressed: bool = false
var _dash_flash: float = 0.0

# Visual
var _anim_time: float = 0.0
var _hit_flash: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0

signal died()
signal hp_changed(current, maximum)
signal attacked()
signal ultimate_used()
signal took_damage(amount)  # fuer Screen Shake und HUD-Feedback

func _ready() -> void:
	current_hp = max_hp
	emit_signal("hp_changed", current_hp, max_hp)

func _process(delta: float) -> void:
	if _death_anim >= 0.0:
		_death_anim += delta
		for p in _death_ptcls:
			p["pos"] += p["vel"] * delta
			p["vel"].y += 380.0 * delta
			p["vel"]   *= 0.965
		queue_redraw()
		return
	if not is_alive:
		return
	_anim_time += delta
	if _hit_flash > 0:
		_hit_flash -= delta
	# Level-up flash overrides dash flash for a brief moment
	if _levelup_flash > 0.0:
		_levelup_flash -= delta
		var f: float = clamp(_levelup_flash / 0.45, 0.0, 1.0)
		modulate = Color(1.0, 0.9, 0.3, 1.0).lerp(Color.WHITE, 1.0 - f)
	elif _dash_flash > 0:
		_dash_flash -= delta
		modulate = Color(0.55, 0.85, 1.0, 0.75)
	else:
		modulate = Color.WHITE
	if _levelup_text_timer > 0.0:
		_levelup_text_timer -= delta
		_levelup_text_offset += delta * 32.0  # rises ~45 px over its lifetime
	queue_redraw()

func _draw_levelup_text() -> void:
	# Subclasses call this from their own _draw to render the floating text.
	if _levelup_text_timer <= 0.0:
		return
	var t: float = clamp(_levelup_text_timer / 1.4, 0.0, 1.0)
	var alpha: float = t
	var y: float = -54.0 - _levelup_text_offset
	var col := Color(1.0, 0.85, 0.15, alpha)
	var shadow := Color(0.10, 0.05, 0.0, alpha)
	var font := GameManager.game_font if GameManager.game_font != null else ThemeDB.fallback_font
	if font == null:
		return
	var msg: String = "+1 LEVEL UP"
	var sz: int = 18
	var width: float = font.get_string_size(msg, HORIZONTAL_ALIGNMENT_CENTER, -1, sz).x
	var pos: Vector2 = Vector2(-width * 0.5, y)
	draw_string(font, pos + Vector2(2, 2), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, shadow)
	draw_string(font, pos, msg, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Remote-Spieler: nur zur empfangenen Position interpolieren
	if _is_remote:
		global_position = global_position.lerp(_remote_target_pos, 0.25)
		return

	# Movement
	var direction = Vector2.ZERO
	if _use_network_input:
		direction = _net_input_dir
	elif _joy_device >= 0:
		# P2: Joypad direkt auslesen (device-spezifisch)
		var jx = Input.get_joy_axis(_joy_device, JOY_AXIS_LEFT_X)
		var jy = Input.get_joy_axis(_joy_device, JOY_AXIS_LEFT_Y)
		if abs(jx) < 0.2: jx = 0.0
		if abs(jy) < 0.2: jy = 0.0
		if Input.is_joy_button_pressed(_joy_device, JOY_BUTTON_DPAD_LEFT):  jx -= 1.0
		if Input.is_joy_button_pressed(_joy_device, JOY_BUTTON_DPAD_RIGHT): jx += 1.0
		if Input.is_joy_button_pressed(_joy_device, JOY_BUTTON_DPAD_UP):    jy -= 1.0
		if Input.is_joy_button_pressed(_joy_device, JOY_BUTTON_DPAD_DOWN):  jy += 1.0
		direction = Vector2(jx, jy)
	else:
		# P1: InputMap-Aktionen (Tastatur + Joypad 0)
		if Input.is_action_pressed("move_up"):    direction.y -= 1
		if Input.is_action_pressed("move_down"):  direction.y += 1
		if Input.is_action_pressed("move_left"):  direction.x -= 1
		if Input.is_action_pressed("move_right"): direction.x += 1

	if direction.length() > 0:
		direction = direction.normalized()
		_dash_dir = direction

	# Dash cooldown
	if _dash_cooldown_timer > 0:
		_dash_cooldown_timer -= delta

	# Dash-Input (steigende Flanke)
	var _dash_now: bool
	if _use_network_input:
		_dash_now = (_net_input_buttons & 1) != 0
	elif _joy_device >= 0:
		_dash_now = Input.is_joy_button_pressed(_joy_device, JOY_BUTTON_B)
	else:
		_dash_now = Input.is_action_pressed("dash")
	if _dash_now and not _dash_was_pressed and _dash_cooldown_timer <= 0 and _dash_timer <= 0:
		_dash_timer = _DASH_DURATION
		_dash_cooldown_timer = _DASH_COOLDOWN
		_dash_flash = _DASH_DURATION + 0.05
		_on_dash_start()
	_dash_was_pressed = _dash_now

	var rage_speed: float = 0.0
	if has_upgrade("roadie_rage"):
		var pct = float(current_hp) / float(max_hp + max_hp_bonus)
		if pct <= 0.25:
			rage_speed = 0.25  # +25% Speed unter 25% HP (Wert aus Upgrade-DB)
	var effective_speed = move_speed * (1.0 + speed_bonus + rage_speed)
	if _dash_timer > 0:
		_dash_timer -= delta
		velocity = _dash_dir * effective_speed * _DASH_SPEED_MULT
		_on_dash_tick(delta)
	elif _knockback_timer > 0:
		_knockback_timer -= delta
		velocity = _knockback_vel * (_knockback_timer / 0.3) + direction * effective_speed * 0.3
	else:
		velocity = direction * effective_speed
	move_and_slide()

	# Clamp to screen
	var viewport_size = get_viewport_rect().size
	global_position.x = clamp(global_position.x, 32, viewport_size.x - 32)
	global_position.y = clamp(global_position.y, 32, viewport_size.y - 32)

	# Attack timer
	attack_timer += delta
	var effective_attack_rate = 1.0 / (attack_speed * (1.0 + attack_speed_bonus))
	if attack_timer >= effective_attack_rate:
		attack_timer = 0.0
		if signature_active:
			_auto_attack_signature()
		else:
			_auto_attack()

	# Ultimate timer
	if ultimate_timer > 0:
		ultimate_timer -= delta

	var _ult_now: bool
	if _use_network_input:
		_ult_now = (_net_input_buttons & 2) != 0
	elif _joy_device >= 0:
		_ult_now = Input.is_joy_button_pressed(_joy_device, JOY_BUTTON_X)
	else:
		_ult_now = Input.is_action_pressed("ultimate")
	var _encore_available := has_upgrade("encore") and _encore_used_this_wave < _encore_charges
	if _ult_now and not _ult_was_pressed and (ultimate_timer <= 0 or _encore_available):
		if ultimate_timer > 0 and _encore_available:
			_encore_used_this_wave += 1  # Encore-Charge verbrauchen
		_use_ultimate()
		ultimate_timer = ultimate_cooldown - ultimate_cooldown_reduction
	_ult_was_pressed = _ult_now

func get_total_damage() -> float:
	var base = base_damage * (1.0 + damage_bonus)
	# Rage bonus - Damage und Speed (beide laut Upgrade-DB)
	if has_upgrade("roadie_rage"):
		var pct = float(current_hp) / float(max_hp + max_hp_bonus)
		if pct <= 0.25:
			base *= 1.35  # +35% Schaden unter 25% HP (Wert aus Upgrade-DB)
	# Kill streak
	if has_upgrade("kill_streak"):
		var streaks = int(kill_count_this_wave / 5)
		base *= (1.0 + streaks * 0.06)  # Wert aus Upgrade-DB (kill_streak_bonus)
	base *= (1.0 + rhythm_damage_bonus)
	base *= (1.0 + crowd_damage_bonus)
	return base

func take_damage(amount: float) -> void:
	if not is_alive:
		return
	var reduced = amount * (1.0 - damage_reduction)
	current_hp -= int(reduced)
	_hit_flash = 0.15
	emit_signal("took_damage", reduced)

	# Feedback loop upgrade
	if has_upgrade("feedback_loop"):
		var crowd = get_tree().get_first_node_in_group("crowd_meter")
		if crowd:
			crowd.add_fill(0.04)  # Wert aus Upgrade-DB (crowd_fill_on_hit)

	emit_signal("hp_changed", current_hp, max_hp + max_hp_bonus)
	if current_hp <= 0:
		_die()

func apply_knockback(force: Vector2) -> void:
	_knockback_vel = force
	_knockback_timer = 0.3

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp + max_hp_bonus)
	emit_signal("hp_changed", current_hp, max_hp + max_hp_bonus)

func _die() -> void:
	is_alive = false
	_death_anim = 0.0
	_spawn_death_particles()
	AudioManager.play_player_death_sfx()
	emit_signal("died")

func _spawn_death_particles() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = get_instance_id() + Time.get_ticks_msec()
	for i in range(32):
		var angle = rng.randf() * TAU
		var speed = rng.randf_range(55.0, 225.0)
		_death_ptcls.append({
			"pos": Vector2(rng.randf_range(-6.0, 6.0), rng.randf_range(-22.0, 0.0)),
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed - 110.0),
			"size": rng.randf_range(2.5, 5.8),
			"col": Color(rng.randf_range(0.52, 0.78), rng.randf_range(0.0, 0.07), rng.randf_range(0.0, 0.05)),
		})

func _auto_attack() -> void:
	# Override in subclass
	pass

func _auto_attack_signature() -> void:
	# Override in subclass fuer die freigeschaltete Signature-Waffe.
	# Fallback: normaler Angriff, falls ein Charakter (noch) keine Signature hat.
	_auto_attack()

func _use_ultimate() -> void:
	# Override in subclass
	emit_signal("ultimate_used")

# -- Dash hooks fuer Charakter-spezifische Effekte ------------------------------
func _on_dash_start() -> void:
	# Wird beim Start eines Dashs aufgerufen (steigende Flanke). Override fuer
	# Spezialeffekte wie Teleport-Flash, Linien-Hits, Afterimage-Reset etc.
	pass

func _on_dash_tick(_delta: float) -> void:
	# Wird waehrend des Dashs jeden Physics-Frame aufgerufen. Override fuer
	# fortlaufende Effekte wie Trail-Spawn, Line-Hit-Collision oder Afterimages.
	pass

# Hilfs-Funktion: Screen-Shake triggern (wenn die current_scene das unterstuetzt)
func _request_screen_shake(intensity: float, duration: float) -> void:
	var scene = get_tree().current_scene
	if scene and scene.has_method("trigger_screen_shake"):
		scene.trigger_screen_shake(intensity, duration)

func on_kill(enemy) -> void:
	kill_count_this_wave += 1
	kills_total += 1
	GameManager.add_kill()
	# Crowd-Meter fuellt sich pro Kill (vorher faelschlich pro Attacke)
	var crowd_sys = get_tree().get_first_node_in_group("crowd_meter")
	if crowd_sys != null and crowd_sys.has_method("add_kill"):
		crowd_sys.add_kill()
	if lifesteal_per_kill > 0:
		heal(lifesteal_per_kill)
	# Award XP (defaults to 10 if missing)
	var xp_gain: int = 10
	if enemy != null and is_instance_valid(enemy):
		var v = enemy.get("xp_value")
		if v != null:
			xp_gain = int(v)
	add_xp(xp_gain)
	_on_kill_passive(enemy)

func add_xp(amount: int) -> void:
	if amount <= 0 or level >= MAX_LEVEL:
		return
	xp += amount
	# Loop in case the player crosses multiple level thresholds at once
	while level < MAX_LEVEL and xp >= int(_XP_THRESHOLDS[level - 1]):
		_level_up()

func _level_up() -> void:
	level += 1
	# +8% max HP, +5% damage at each level
	var hp_gain: int = int(round(float(max_hp) * 0.08))
	max_hp_bonus += hp_gain
	heal(hp_gain)
	damage_bonus += 0.05
	# Visual feedback
	_levelup_flash = 0.45
	_levelup_text_timer = 1.4
	_levelup_text_offset = 0.0
	AudioManager.play_wave_complete_sfx()  # uses an existing SFX as a stand-in
	emit_signal("leveled_up", level)

func _on_kill_passive(enemy) -> void:
	# Override for character-specific kill passives
	pass

func reset_for_new_wave() -> void:
	kill_count_this_wave = 0
	_encore_used_this_wave = 0

func apply_upgrade(upgrade: Dictionary) -> void:
	var effect = upgrade.get("effect", {})
	if effect.has("damage_bonus"): damage_bonus += effect["damage_bonus"]
	if effect.has("attack_speed_bonus"): attack_speed_bonus += effect["attack_speed_bonus"]
	if effect.has("speed_bonus"): speed_bonus += effect["speed_bonus"]
	if effect.has("max_hp_bonus"):
		max_hp_bonus += effect["max_hp_bonus"]
		heal(effect["max_hp_bonus"])
	if effect.has("heal_now"): heal(effect["heal_now"])
	if effect.has("damage_reduction"): damage_reduction += effect["damage_reduction"]
	if effect.has("aoe_radius_bonus"): aoe_radius_bonus += effect["aoe_radius_bonus"]
	if effect.has("pierce"): pierce += effect["pierce"]
	if effect.has("extra_bounce"): extra_bounce += effect["extra_bounce"]
	if effect.has("double_strike_chance"): double_strike_chance += effect["double_strike_chance"]
	if effect.has("ultimate_cooldown_reduction"): ultimate_cooldown_reduction += effect["ultimate_cooldown_reduction"]
	if effect.has("lifesteal_per_kill"): lifesteal_per_kill += effect["lifesteal_per_kill"]
	if effect.has("ultimate_extra_charge"): _encore_charges += effect["ultimate_extra_charge"]

var _applied_upgrades: Array = []

func has_upgrade(id: String) -> bool:
	return id in _applied_upgrades

func apply_upgrade_by_id(id: String) -> void:
	_applied_upgrades.append(id)
	var upgrade = UpgradeDB.get_upgrade(id)
	if not upgrade.is_empty():
		apply_upgrade(upgrade)

const _PROJ_VARIETY = {
	"manni": 0, "shouter": 1, "dreads": 2,
	"riff_slicer": 3, "distortion": 4, "bassist": 5,
	"pimmel": 6, "theo": 7, "toxo": 8,
}

func spawn_projectile(direction: Vector2, damage: float = -1, speed: float = 400.0, pierce: int = 0) -> void:
	var proj = _PROJ_SCENE.instantiate()
	if proj:
		proj.global_position = global_position
		proj.direction = direction
		proj.damage = damage if damage >= 0 else get_total_damage()
		proj.speed = speed
		proj.pierce_count = self.pierce + pierce
		proj.bounce_count = extra_bounce
		proj.shooter = self
		proj.proj_type = _PROJ_VARIETY.get(character_id, 0)
		get_tree().current_scene.add_child(proj)
	AudioManager.play_projectile_sfx(_PROJ_VARIETY.get(character_id, 0))

func spawn_shockwave(radius: float = 100.0, damage: float = -1) -> void:
	var sw = _SW_SCENE.instantiate()
	if sw:
		sw.global_position = global_position
		sw.radius = radius * (1.0 + aoe_radius_bonus)
		sw.damage = damage if damage >= 0 else get_total_damage() * 2.0
		sw.shooter = self
		get_tree().current_scene.add_child(sw)

func get_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist = INF
	for e in enemies:
		var enemy := e as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.get("is_alive") == false:
			continue
		var d = global_position.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy
	return nearest

func get_direction_to_nearest_enemy() -> Vector2:
	var target = get_nearest_enemy()
	if target:
		return (target.global_position - global_position).normalized()
	return Vector2.RIGHT
