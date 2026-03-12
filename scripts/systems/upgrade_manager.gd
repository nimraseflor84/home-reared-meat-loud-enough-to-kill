extends Node
class_name UpgradeManager

var applied_upgrades: Array = []
var player_ref: PlayerBase = null

func set_player(player: PlayerBase) -> void:
	player_ref = player

func apply_upgrade(upgrade_id: String) -> void:
	applied_upgrades.append(upgrade_id)
	GameManager.run_stats["upgrades_taken"].append(upgrade_id)

	if is_instance_valid(player_ref):
		player_ref.apply_upgrade_by_id(upgrade_id)

	# Apply to systems if needed
	var upgrade = UpgradeDB.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return

	# Apply to rhythm system
	var game = get_tree().current_scene
	if game:
		var rhythm = game.get_node_or_null("RhythmSystem")
		if rhythm:
			rhythm.apply_upgrade(upgrade)
		var crowd = game.get_node_or_null("CrowdMeter")
		if crowd:
			crowd.apply_upgrade(upgrade)

func get_random_choices(count: int = 3) -> Array:
	return UpgradeDB.get_random_upgrades(count, applied_upgrades)

func reset() -> void:
	applied_upgrades.clear()
	player_ref = null
