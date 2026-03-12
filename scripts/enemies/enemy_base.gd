extends CharacterBody2D
class_name EnemyBase

# Zeichnet feindliche Projektile unabhängig vom Subklassen-_draw()
class _BulletRenderer extends Node2D:
	var owner_enemy: Node = null
	func _process(_delta: float) -> void:
		if is_instance_valid(owner_enemy):
			queue_redraw()
	func _draw() -> void:
		if not is_instance_valid(owner_enemy):
			return
		for b in owner_enemy._bullets:
			var lp = to_local(b["pos"])
			draw_circle(lp, 6.0, Color(1.0, 0.15, 0.0, 0.92))
			draw_circle(lp, 3.0, Color(1.0, 0.85, 0.3, 0.95))

@export var max_hp: float = 30.0
@export var damage: float = 10.0
@export var move_speed: float = 80.0
@export var score_value: int = 100
@export var enemy_id: String = "base"
@export var xp_value: int = 10

var current_hp: float
var is_alive: bool = true
var target: Node2D = null
var _hit_flash: float = 0.0
var _anim_time: float = 0.0
var _slow_factor: float = 1.0
var _slow_timer: float = 0.0
var contact_damage_timer: float = 0.0
const CONTACT_DAMAGE_INTERVAL = 0.5
var _knockback_vel: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0
var _dying: bool = false
var _death_anim_time: float = 0.0
var _death_anim_duration: float = 0.35

# ── Fernkampf (Hard / Very Hard) ─────────────────────────────────────────────
var _can_shoot: bool = false
var _shoot_timer: float = 0.0
var _shoot_interval: float = 2.5
var _bullets: Array = []   # [{pos:Vector2, vel:Vector2}]
const _BULLET_SPEED  = 190.0
const _BULLET_RADIUS = 6.0

signal died(enemy)

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	_scale_to_wave()

func _scale_to_wave() -> void:
	var wave_mult = GameManager.get_wave_difficulty_multiplier()
	var diff_hp   = GameManager.DIFFICULTY_HP[GameManager.difficulty]
	var diff_dmg  = GameManager.DIFFICULTY_DMG[GameManager.difficulty]
	current_hp = max_hp * wave_mult * diff_hp
	max_hp     = current_hp
	damage     = damage * GameManager.get_wave_damage_multiplier() * diff_dmg

	# Fernkampf nur ab Hard
	var shoot_chance = GameManager.DIFFICULTY_SHOOT[GameManager.difficulty]
	if shoot_chance > 0.0 and randf() < shoot_chance:
		_can_shoot = true
		_shoot_timer = randf_range(0.5, _shoot_interval)  # versetzter Start
		# Bullet-Renderer als Child hinzufügen (zeichnet unabhängig von Subklassen-_draw)
		var br = _BulletRenderer.new()
		br.name = "_BulletRenderer"
		br.owner_enemy = self
		add_child(br)

func _process(delta: float) -> void:
	if _dying:
		_death_anim_time += delta
		_on_dying_process(delta)
		queue_redraw()
		if _death_anim_time >= _death_anim_duration:
			queue_free()
		return
	if not is_alive:
		return
	_anim_time += delta
	if _hit_flash > 0:
		_hit_flash -= delta
	if _slow_timer > 0:
		_slow_timer -= delta
		if _slow_timer <= 0:
			_slow_factor = 1.0

	# ── Bullets bewegen & Treffer prüfen ──
	if _bullets.size() > 0:
		for i in range(_bullets.size() - 1, -1, -1):
			var b = _bullets[i]
			b["pos"] += b["vel"] * delta
			var too_far = b["pos"].distance_to(global_position) > 900.0
			var hit = false
			if is_instance_valid(target):
				if b["pos"].distance_to(target.global_position) < 22.0:
					if target.has_method("take_damage"):
						target.take_damage(b["dmg"])
					hit = true
			if hit or too_far:
				_bullets.remove_at(i)

	queue_redraw()

func _on_dying_process(_delta: float) -> void:
	modulate.a = 1.0 - _death_anim_time / _death_anim_duration

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Find player target
	if not is_instance_valid(target):
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			target = players[0]

	# ── Fernkampf-Schuss ──
	if _can_shoot and is_instance_valid(target):
		_shoot_timer += delta
		if _shoot_timer >= _shoot_interval:
			_shoot_timer = 0.0
			var dist = global_position.distance_to(target.global_position)
			if dist > 60.0:   # nur schießen wenn nicht direkt daneben
				var dir = (target.global_position - global_position).normalized()
				_bullets.append({
					"pos": global_position,
					"vel": dir * _BULLET_SPEED * _slow_factor,
					"dmg": damage * 0.55,
				})

	# Apply knockback (overrides normal movement for duration)
	if _knockback_timer > 0:
		_knockback_timer -= delta
		velocity = _knockback_vel * (_knockback_timer / 0.4)
		move_and_slide()
		if is_instance_valid(target):
			_check_contact_damage(delta)
		return

	if is_instance_valid(target):
		_move_toward_target(delta)
		_check_contact_damage(delta)

func _move_toward_target(delta: float) -> void:
	var dir = (target.global_position - global_position).normalized()
	velocity = dir * move_speed * _slow_factor
	move_and_slide()

func _check_contact_damage(delta: float) -> void:
	contact_damage_timer += delta
	if contact_damage_timer >= CONTACT_DAMAGE_INTERVAL:
		contact_damage_timer = 0.0
		if global_position.distance_to(target.global_position) < 40:
			if target.has_method("take_damage"):
				target.take_damage(damage)

func take_damage(amount: float, attacker = null) -> void:
	if not is_alive:
		return
	current_hp -= amount
	_hit_flash = 0.12

	if current_hp <= 0:
		_die(attacker)

func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = min(_slow_factor, factor)
	_slow_timer = max(_slow_timer, duration)

func apply_knockback(force: Vector2) -> void:
	_knockback_vel = force
	_knockback_timer = 0.4

func _die(attacker = null) -> void:
	is_alive = false
	_bullets.clear()
	remove_from_group("enemies")
	if is_instance_valid(attacker) and attacker.has_method("on_kill"):
		attacker.on_kill(self)
	AudioManager.play_enemy_death_sfx()
	emit_signal("died", self)
	_dying = true
