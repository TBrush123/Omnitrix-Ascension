class_name EMPGrenade
extends Node2D

var direction:     Vector2 = Vector2.RIGHT
var damage:        float   = 1.0
var stun_duration: float   = 2.5
var blast_range:   float   = 150.0

const ARC_HEIGHT:  float   = 60.0    
const FLY_DURATION: float  = 0.55

@onready var sprite:  Sprite2D = $Sprite2D
@onready var shadow:  Sprite2D = $Shadow

@export var emp_burst_vfx: PackedScene 

var _target:       Vector2 = Vector2.ZERO
var _start:        Vector2 = Vector2.ZERO
var _elapsed:      float   = 0.0
var _flying:       bool    = false


func _ready() -> void:
	_start  = global_position
	_target = get_global_mouse_position()

	# Clamp throw distance so it can't go infinitely far
	var max_throw = blast_range * 1.8
	var diff      = _target - _start
	if diff.length() > max_throw:
		_target = _start + diff.normalized() * max_throw

	# Place shadow at landing spot immediately
	shadow.global_position = _target
	shadow.scale           = Vector2(0.4, 0.4)

	_flying = true


func _process(delta: float) -> void:
	if not _flying:
		return

	_elapsed += delta
	var t = clampf(_elapsed / FLY_DURATION, 0.0, 1.0)

	# Horizontal position: lerp from start to target
	var flat_pos = _start.lerp(_target, t)

	# Vertical arc: sine curve peaks at t=0.5
	var arc_offset = -ARC_HEIGHT * sin(t * PI)

	# Apply: move the whole node horizontally,
	# offset only the sprite vertically to fake the arc
	global_position  = flat_pos
	sprite.position  = Vector2(0.0, arc_offset)

	# Shadow scales up as grenade approaches ground
	var shadow_scale = lerp(0.3, 0.9, t)
	shadow.scale     = Vector2(shadow_scale, shadow_scale * 0.5)
	shadow.modulate.a = lerp(0.2, 0.5, t)

	# Spin the sprite while flying
	sprite.rotation += delta * 5.0

	if t >= 1.0:
		_land()


func _land() -> void:
	_flying = false
	shadow.queue_free()

	# Small squash on landing before detonation
	var tween = create_tween()
	tween.tween_property(sprite, "scale",
		Vector2(1.6, 0.5), 0.06)
	tween.tween_property(sprite, "scale",
		Vector2.ZERO, 0.08)
	tween.tween_callback(_detonate)


func _detonate() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) > blast_range:
			continue
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(stun_duration)

	_spawn_burst()
	queue_free()


func _spawn_burst() -> void:
	var burst = emp_burst_vfx.instantiate()
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position
	burst.blast_range     = blast_range
