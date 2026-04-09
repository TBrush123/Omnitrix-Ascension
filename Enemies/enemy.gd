class_name Enemy
extends Node

@export var health_component: HealthComponent

func _ready():
	health_component.connect("health_changed", Callable(self, "_on_health_changed"))
	health_component.connect("died", Callable(self, "_on_died"))

func take_damage(amount: int):
	print("Enemy takes damage: ", amount)
	health_component.take_damage(amount)

func _on_health_changed(new_health: int):
	print("Enemy health changed: ", new_health)

func _on_died():
	print("Enemy died")
	queue_free()
