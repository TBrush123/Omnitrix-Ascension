@icon("res://Assets/Misc/projectile.svg")
class_name ProjectileBase
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var damage: float = 1.0
var speed: float = 200.0
var knockback: float = 100.0

var max_range: float = 500.0
var lifetime: float = -1.0
var pierce_count: int = 0
var homing_strength: float = 0.0
var homing_range: float = 150.0

var _distance_traveled: float = 0.0
var _hits_remaining: int = 0
var _hit_enemies: Array = []

func _ready():
	_hits_remaining = pierce_count + 1
	rotation = direction.angle()

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	if has_node("VisibleOnScreenNotifier2D "):
		$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	
	if lifetime > 0:
		get_tree().create_timer(lifetime).timeout.connect(queue_free)

	_setup()

func _setup() -> void:
	pass

func _physics_process(delta: float) -> void:
	if homing_strength > 0:
		_apply_homing(delta)
	
	var move = direction.normalized() * speed * delta
	position += move
	_distance_traveled += move.length()

	if max_range > 0 and _distance_traveled >= max_range:
		_on_max_range()

func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hitbox"):
		return
	var enemy = area.owner
	if enemy in _hit_enemies:
		return
	_hit_enemies.append(enemy)

	if enemy.has_node("HealthComponent"):
		enemy.get_node("HealthComponent").take_damage(damage)
	if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(direction, 	knockback)
	
	_on_hit_enemy(enemy)

	_hits_remaining -= 1
	if _hits_remaining <= 0:
		_on_destroyed()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("wall"):
		_on_hit_wall(body)
	
func _on_hit_enemy(_enemy: Node) -> void:
	pass

func _on_hit_wall(_wall: Node) -> void:
	_on_destroyed()

func _on_max_range() -> void:
	_on_destroyed()

func _on_destroyed():
	queue_free()

func _apply_homing(delta: float) -> void:
	var target = _find_nearest_enemy()
	if target == null:
		return
	var desired = (target.global_position - global_position).normalized()
	direction = direction.lerp(desired, homing_strength * delta).normalized()

func _find_nearest_enemy() -> Node:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Node = null
	var nearest_dist = homing_range

	for e in enemies:
		if not is_instance_valid(e):
			continue
		var dist = global_position.distance_to(e.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = e
	
	return nearest
