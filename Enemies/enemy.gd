class_name Enemy
extends CharacterBody2D

@export var health_component: HealthComponent
@export var contact_damage: float = 5.0

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

func apply_knockback(direction: Vector2, force: float):
	velocity += direction * force


func _physics_process(delta: float):
	# Apply knockback velocity
	if velocity.length() > 0:
		move_and_slide()

	velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)  # Dampen knockback over time

func _on_contact_with_player(player: Node) -> void:
	player.take_damage(contact_damage, global_position, self)
