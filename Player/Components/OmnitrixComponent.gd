class_name OmnitrixComponent
extends Node

signal alien_transform(alien: AlienData)
signal cooldown_updated(remaining: float, total: float)
signal toggle_wheel(should_show: bool)

@export var aliens: Array[AlienData] = []
@export var switch_cooldown: float = 3.0


var current_index: int         = 0
var _cooldown_remaining: float = 0.0
var _wheel_open: bool          = false
var omnitrix_wheel: OmnitrixWheel

func _process(delta: float):
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("omnitrix_toggle"):
		_wheel_open = not _wheel_open
		toggle_wheel.emit(_wheel_open)
	if event.is_action_pressed("omnitrix_slam") and _wheel_open:
		_switch_to(current_index)

func _switch_to(index: int) -> void:
	if _cooldown_remaining > 0:
		print(_cooldown_remaining)
		return
	var charge = get_parent().get_parent().get_node("Components/AlienChargeComponent")
	if not charge.can_transform():
		return

	_wheel_open = not _wheel_open
	current_index = omnitrix_wheel.get_active_alien_index()
	alien_transform.emit(aliens[current_index])

func connect_to(player_omnitrix_wheel: OmnitrixWheel):
	omnitrix_wheel = player_omnitrix_wheel

func get_active() -> AlienData:
	return aliens[omnitrix_wheel.get_active_alien_index()]

func force_detransform() -> void:
	current_index = -1
	_cooldown_remaining = switch_cooldown
	emit_signal("alien_transform", null)

func has_alien(alien: AlienData) -> bool:
	return alien in aliens
