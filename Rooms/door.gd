class_name Door
extends Node2D

signal player_entered(door: Door)

@export var direction: String = "North"   # set in editor per door instance

var exists: bool  = false
var locked: bool  = false

@onready var collision  = $StaticBody2D/CollisionShape2D
@onready var trigger    = $Area2D          # player walks into this to change room
@onready var sprite     = $Sprite2D

func set_exists(value: bool) -> void:
	exists = value
	visible = value
	# If it doesn't exist, ensure its Area2D can't fire
	$Area2D/CollisionShape2D.disabled = not value


func lock() -> void:
	locked = true
	collision.disabled = false   # physical wall is solid
	sprite.frame = 1             # closed door frame
	$Area2D/CollisionShape2D.disabled = true  # can't walk through


func unlock() -> void:
	locked = false
	collision.disabled = true    # player can walk through
	sprite.frame = 0             # open door frame
	$Area2D/CollisionShape2D.disabled = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not locked:
		emit_signal("player_entered", self)