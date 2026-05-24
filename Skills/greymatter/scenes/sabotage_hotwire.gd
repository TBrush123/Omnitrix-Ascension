class_name GreymatterHack
extends Node2D

@export var emp: PackedScene

var direction:  Vector2 = Vector2.RIGHT
var damage:     float   = 1.0

const HACK_DURATION:  float = 5.0
const LEAP_SPEED:     float = 400.0
const DETECT_RANGE:   float = 180.0
const EMP_RANGE: float = 150.0
const STUN_DURATION: float = 2.5


func _ready() -> void:
	var target = _find_nearest_enemy()
	if target == null:
		_throw_emp()
	else:
		_leap_to(target)


func _find_nearest_enemy() -> Node:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Node   = null
	var nearest_dist    = DETECT_RANGE
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if not e.is_in_group("robot"):
			continue
		var dist = get_parent().global_position.distance_to(e.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest      = e
	return nearest


func _leap_to(target: Node) -> void:
	# Move player to target position then apply hack
	var player = get_parent().get_parent()
	var tween  = create_tween()
	tween.tween_property(player, "global_position",
		target.global_position, 0.15) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _apply_hack(target))
	tween.tween_callback(queue_free)


func _apply_hack(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	if enemy.has_method("apply_hack"):
		enemy.apply_hack(HACK_DURATION)

func _throw_emp() -> void:
	var emp_instance = emp.instantiate()
	emp_instance.global_position = get_parent().global_position
	emp_instance.direction = direction
	emp_instance.stun_duration = STUN_DURATION
	emp_instance.blast_range = EMP_RANGE
	get_tree().current_scene.add_child(emp_instance)
	queue_free()
