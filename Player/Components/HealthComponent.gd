class_name HealthComponent
extends Node

@export var max_health: int = 100
var current_health: int = max_health

signal health_changed(new_health: int)
signal died()

func take_damage(amount: int) -> void:
	current_health = max(current_health - amount, 0)
	emit_signal("health_changed", current_health)
	if current_health == 0:
		emit_signal("died")
