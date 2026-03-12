extends Node2D
class_name CrowdMeterSystem

var fill: float = 0.0  # 0.0 to 1.0
var level: int = 0  # 0-4
var _fill_bonus: float = 0.0  # from upgrades
var _crowd_bonus_multiplier: float = 0.0  # from upgrades
var _ultimate_ready: bool = false

signal level_changed(new_level)
signal ultimate_ready()
signal fill_changed(fill_value)

const LEVEL_THRESHOLDS = [0.25, 0.50, 0.75, 1.0]
const DAMAGE_BONUSES = [0.0, 0.10, 0.25, 0.50, 1.00]

func _ready() -> void:
	pass

func add_fill(amount: float) -> void:
	var effective = amount * (1.0 + _fill_bonus)
	fill = min(fill + effective, 1.0)
	_update_level()
	emit_signal("fill_changed", fill)

func add_rhythm_hit(multiplier: float) -> void:
	add_fill(0.04 * multiplier)

func add_kill() -> void:
	add_fill(0.05)

func _update_level() -> void:
	var new_level = 0
	for i in range(LEVEL_THRESHOLDS.size()):
		if fill >= LEVEL_THRESHOLDS[i]:
			new_level = i + 1

	if new_level != level:
		level = new_level
		emit_signal("level_changed", level)
		if level >= 4 and not _ultimate_ready:
			_ultimate_ready = true
			emit_signal("ultimate_ready")

func get_damage_bonus() -> float:
	var base_bonus = DAMAGE_BONUSES[level]
	return base_bonus * (1.0 + _crowd_bonus_multiplier)

func consume_ultimate() -> void:
	fill = 0.0
	_ultimate_ready = false
	level = 0
	emit_signal("level_changed", 0)
	emit_signal("fill_changed", fill)

func apply_upgrade(upgrade: Dictionary) -> void:
	var effect = upgrade.get("effect", {})
	if effect.has("crowd_fill_bonus"):
		_fill_bonus += effect["crowd_fill_bonus"]
	if effect.has("crowd_bonus_multiplier"):
		_crowd_bonus_multiplier += effect["crowd_bonus_multiplier"]

func reset() -> void:
	fill = 0.0
	level = 0
	_ultimate_ready = false
