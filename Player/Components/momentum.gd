class_name MomentumComponent
extends Node2D

signal stacks_changed(current: int, maximum: int)
signal reached_max_stacks
signal left_max_stacks

const MAX_STACKS:      int   = 8
const BUILD_TIME:      float = 0.3    # seconds of movement to gain one stack
const DRAIN_DELAY:     float = 0.15   # seconds of stillness before draining
const SPEED_PER_STACK: float = 18.0   # flat move speed per stack
const DAMAGE_PER_STACK:float = 0.12   # 12% damage bonus per stack

var current_stacks: int   = 0
var _build_timer:   float = 0.0
var _drain_timer:   float = 0.0
var _moving:        bool  = false
var was_max: bool = false

@onready var _stats: PlayerStats = get_parent().get_node("PlayerStats")
@onready var _player = get_parent().get_parent() as Player


func _process(delta: float) -> void:
	_moving = _player.velocity.length() > 10.0
	if _moving:
		_drain_timer = 0.0
		_build_timer += delta
		if _build_timer >= BUILD_TIME:
			_build_timer = 0.0
			_add_stack()
	else:
		_build_timer = 0.0
		_drain_timer += delta
		if _drain_timer >= DRAIN_DELAY:
			_drain_timer = 0.0
			_remove_stack()


func _add_stack() -> void:
	if current_stacks >= MAX_STACKS:
		return
	current_stacks += 1
	_apply_to_stats()
	emit_signal("stacks_changed", current_stacks, MAX_STACKS)

	if current_stacks == MAX_STACKS and not was_max:
		emit_signal("reached_max_stacks")


func _remove_stack() -> void:
	if current_stacks <= 0:
		return
	current_stacks -= 1
	_apply_to_stats()
	emit_signal("stacks_changed", current_stacks, MAX_STACKS)

	if was_max and current_stacks < MAX_STACKS:
		emit_signal("left_max_stacks")


func clear_stacks() -> void:
	current_stacks = 0
	_apply_to_stats()
	emit_signal("stacks_changed", 0, MAX_STACKS)

	if was_max:
		emit_signal("left_max_stacks")


func _apply_to_stats() -> void:
	_stats.remove_modifiers_by_source("momentum")

	if current_stacks == 0:
		return

	var speed_mod = StatModifier.new()
	speed_mod.stat = "move_speed"
	speed_mod.type = StatModifier.Type.FLAT
	speed_mod.value = SPEED_PER_STACK * current_stacks
	speed_mod.source = "momentum"

	var damage_mod = StatModifier.new()
	damage_mod.stat = "damage"
	damage_mod.type = StatModifier.Type.PERCENT
	damage_mod.value = DAMAGE_PER_STACK * current_stacks
	damage_mod.source = "momentum"

	_stats.add_modifier(speed_mod)
	_stats.add_modifier(damage_mod)


func get_stack_percent() -> float:
	return float(current_stacks) / float(MAX_STACKS)


func is_at_max() -> bool:
	return current_stacks >= MAX_STACKS
