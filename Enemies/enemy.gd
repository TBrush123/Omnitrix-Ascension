class_name EnemyBase
extends CharacterBody2D

signal died

@export var max_health: float = 20.0
@export var move_speed: float = 70.0
@export var contact_damage: float = 5.0
@export var is_robot: bool = false

var current_health: float
var _player: CharacterBody2D
var _stunned: bool = false
var _confused: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("enemy")

	if has_meta("player_ref"):
		_player = get_meta("player_ref")
	else:
		_player = get_tree().get_first_node_in_group("player")

	if has_node("Hurtbox"):
		$Hurtbox.area_entered.connect(_on_hurtbox_entered)

	if has_node("ContactArea"):
		$ContactArea.area_entered.connect(_on_contact_area_entered)

func _physics_process(delta: float) -> void:
	if _stunned:
		return
	_move(delta)

func _move(_delta: float) -> void:
	pass

func get_direction_to_player() -> Vector2:
	if not is_instance_valid(_player):
		return Vector2.ZERO
	return (_player.global_position - global_position).normalized()

func _on_hurtbox_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack"):
		var damage = area.get_meta("damage", 1.0)
		take_damage(damage)

func take_damage(amount: float) -> void:
	current_health -= amount
	_flash_damage()
	if current_health <= 0:
		_die()

func _die() -> void:
	emit_signal("died")

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.15)
	tween.chain().tween_callback(queue_free)

func _flash_damage() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 0.3, 0.3), 0.06)
	tween.tween_property(self, "modulate", Color.WHITE, 0.06)

func _on_contact_area_entered(area: Area2D) -> void:
	if area.is_in_group("hurtbox"):
		var player = area.owner
		if player and player.has_method("take_damage"):
			player.take_damage(contact_damage)

func apply_knockback(direction: Vector2, force: float = 200.0) -> void:
	velocity = direction.normalized() * force

func apply_stun(duration: float) -> void:
	_stunned = true
	modulate = Color(0.6, 0.9, 1.0)
	get_tree().create_timer(duration).timeout.connect(func():
		_stunned = false
		modulate = Color.WHITE
	)

func apply_confusion(duration: float) -> void:
	_confused = true
	modulate = Color(1.0, 0.5, 1.0)
	get_tree().create_timer(duration).timeout.connect(func():
		_confused = false
		modulate = Color.WHITE
	)

func apply_hack(duration: float) -> void:
	if not is_robot:
		return
	remove_from_group("enemy")
	add_to_group("ally")

	modulate = Color(0.5, 0.8, 1.0)
	get_tree().create_timer(duration).timeout.connect(func():
		remove_from_group("ally")
		_die()
	)
