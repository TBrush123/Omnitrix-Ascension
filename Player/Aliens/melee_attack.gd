@icon("res://Assets/Misc/Melee.svg")
class_name MeleeHitboxBase
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var damage: float = 1.0

@export var lifetime: float = 0.15
@export var knockback_force: float = 200.0

var _hit_enemies: Array = []

func _ready() -> void:
	rotation = direction.angle()
	self.area_entered.connect(_on_area_entered)
	_on_spawned()

func _on_spawned() -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	print("HIT: ", area.name, " | groups: ", area.get_groups())
	if not area.is_in_group('hitbox'):
		return
	var enemy = area.owner
	if enemy in _hit_enemies:
		return
	
	_hit_enemies.append(enemy)

	if enemy.has_node('HealthComponent'):
		enemy.get_node('HealthComponent').take_damage(damage)
	
	if enemy.has_method('apply_knockback'):
		enemy.apply_knockback(direction * knockback_force)

	_on_hit(enemy)

func _start_lifetime() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _on_hit(_enemy: Node) -> void:
	pass
