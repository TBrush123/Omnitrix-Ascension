class_name PlayerStats
extends Node

# Base stats — never modified directly
const BASE_STATS: Dictionary = {
	"move_speed":       150.0,
	"damage":           1.0,
	"attack_cooldown":  0.5,
	"projectile_speed": 300.0,
}

# The currently active alien contributes its own modifiers
var active_alien: AlienData = null


func get_stat(stat_name: String) -> float:
	var base: float = BASE_STATS.get(stat_name, 0.0)

	# Apply alien's built-in modifier for this stat
	if active_alien and active_alien.stat_modifiers.has(stat_name):
		base += active_alien.stat_modifiers[stat_name]

	return base