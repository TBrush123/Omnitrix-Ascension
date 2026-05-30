class_name AlienChargeComponent
extends Node2D

signal charge_updated(current: float, maximum: float)
signal charge_depleted     # triggers detransform
signal charge_recharged    # back to full, can transform again

@export var max_charge:      float = 10.0   # seconds of alien time
@export var drain_rate:      float = 1.0    # per second while transformed
@export var recharge_rate:   float = 2.0    # per second while human
@export var recharge_delay:  float = 1.5

var current_charge: float  = 100.0
var is_transformed: bool   = false
var _recharge_timer: float = 0.0
var _depleted:       bool  = false
var _depleting: bool = false
var _stats: PlayerStats = null

func _ready() -> void:
	_stats = get_parent().get_node("PlayerStats")
	current_charge = _get_max()

func _process(delta: float) -> void:
	if is_transformed:
		_drain(delta)
	else:
		_recharge(delta)


func _drain(delta: float) -> void:
	if _depleted:
		return
	current_charge = max(0.0, current_charge - _get_drain()  * delta)
	emit_signal("charge_updated", current_charge, _get_max())

	if current_charge <= 0.0:
		current_charge = 0.0
		_depleted = true
		emit_signal("charge_depleted")


func _recharge(delta: float) -> void:
	if current_charge >= _get_max():
		return

	if _recharge_timer < recharge_delay:
		_recharge_timer += delta
		return
	var was_depleted = _depleted
	current_charge   = min(_get_max(), current_charge + _get_recharge() * delta)
	emit_signal("charge_updated", current_charge, _get_max())
	if was_depleted and current_charge >= _get_max():
		_depleted = false
		emit_signal("charge_recharged")

func set_transformed(value: bool) -> void:
	is_transformed   = value
	_recharge_timer  = 0.0


func can_transform() -> bool:
	return not _depleted and current_charge >= _get_max() * 0.1

func _get_max() -> float:
	return _stats.get_stat("max_charge") if _stats else 0.0

func _get_drain() -> float:
	return _stats.get_stat("drain_rate") if _stats else 10.0

func _get_recharge() -> float:
	return _stats.get_stat("charge_recharge") if _stats else 12.0
