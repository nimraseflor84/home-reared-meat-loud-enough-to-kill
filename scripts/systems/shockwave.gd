extends Node2D
class_name Shockwave

@export var radius: float = 100.0
@export var damage: float = 50.0
@export var expand_time: float = 0.3
@export var slow_factor: float = 0.0  # 0 = no slow
@export var slow_duration: float = 0.0

var shooter = null
var _timer: float = 0.0
var _current_radius: float = 0.0
var _enemies_hit: Dictionary = {}

func _ready() -> void:
	_current_radius = 0.0

func _process(delta: float) -> void:
	_timer += delta
	var t = _timer / expand_time
	_current_radius = radius * t

	# Check enemies in radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not _enemies_hit.has(enemy) and is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= _current_radius:
				_enemies_hit[enemy] = true
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage, shooter)
				if slow_factor > 0 and enemy.has_method("apply_slow"):
					enemy.apply_slow(slow_factor, slow_duration)

	queue_redraw()

	if _timer >= expand_time + 0.1:
		queue_free()

func _draw() -> void:
	var alpha = max(0.0, 1.0 - (_timer / expand_time))
	var outer_color = Color(1.0, 0.5, 0.0, alpha * 0.6)
	var inner_color = Color(1.0, 0.8, 0.0, alpha * 0.3)
	draw_circle(Vector2.ZERO, _current_radius, inner_color)
	for i in range(3):
		var r = _current_radius - i * 4
		if r > 0:
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, outer_color, 2.0 - i * 0.5)
