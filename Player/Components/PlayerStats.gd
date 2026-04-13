class_name PlayerStats
extends Node

const BASE_STATS: Dictionary = {
	"move_speed":       150.0,
	"damage":           1.0,
	"attack_cooldown":  0.5,
	"projectile_speed": 300.0,
	"drain_rate": 10.0,
	"charge_rate": 15.0,
	"max_charge": 100.0,
}

var active_alien: AlienData = null
var collected_modifiers: Array[StatModifier] = []

func get_stat(stat_name: String) -> float:
	var base: float = BASE_STATS.get(stat_name, 0.0)
	var flat_bonus: float = 0.0
	var percent_bonus: float = 0.0

	for mod in collected_modifiers:
		if mod.stat == stat_name:
			match mod.type:
				StatModifier.ModifierType.FLAT:
					flat_bonus += mod.value
				StatModifier.ModifierType.PERCENT:
					percent_bonus += mod.value
	return (base + flat_bonus) * (1 + percent_bonus)

	# Apply alien's built-in modifier for this stat
	if active_alien and active_alien.stat_modifiers.has(stat_name):
		base += active_alien.stat_modifiers[stat_name]

	return base

func add_modifier(modifier: StatModifier) -> void:
	collected_modifiers.append(modifier)