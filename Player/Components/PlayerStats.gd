class_name PlayerStats
extends Node

const BASE_STATS: Dictionary = {
	"move_speed":       150.0,
	"damage":           1.0,
	"attack_cooldown":  0.5,
	"projectile_speed": 300.0,
	"drain_rate": 10.0,
	"charge_recharge": 15.0,
	"max_charge": 100.0,
}

var active_alien: AlienData = null
var collected_modifiers: Array[StatModifier] = []

func _process(_delta: float) -> void:
	print(get_stat("move_speed"))

func get_stat(stat_name: String) -> float:
	var base: float = BASE_STATS.get(stat_name, 0.0)
	var flat_bonus: float = 0.0
	var percent_bonus: float = 0.0

	if active_alien:
		print("Active alien: %s" % active_alien.alien_name)
	if active_alien and active_alien.stat_modifiers.has(stat_name):
		base += active_alien.stat_modifiers[stat_name]
	

	for mod in collected_modifiers:
		if mod.stat == stat_name:
			match mod.type:
				StatModifier.Type.FLAT:
					flat_bonus += mod.value
				StatModifier.Type.PERCENT:
					percent_bonus += mod.value
	return (base + flat_bonus) * (1 + percent_bonus)


func add_modifier(modifier: StatModifier) -> void:
	collected_modifiers.append(modifier)

func remove_modifiers_by_source(source: String) -> void:
	collected_modifiers = collected_modifiers.filter(
		func(m): return m.source != source
	)
