# alien_charge_component.gd
class_name AlienChargeComponent
extends Node2D

signal charge_updated(current: float, maximum: float)
signal charge_depleted     # triggers detransform
signal charge_recharged    # back to full, can transform again

@export var max_charge:      float = 10.0   # seconds of alien time
@export var drain_rate:      float = 1.0    # per second while transformed
@export var recharge_rate:   float = 2.0    # per second while human
@export var recharge_delay:  float = 1.5    # seconds before recharge starts

var current_charge: float  = 10.0
var is_transformed: bool   = false
var _recharge_timer: float = 0.0
var _depleted:       bool  = false


func _process(delta: float) -> void:
    if is_transformed:
        _drain(delta)
    else:
        _recharge(delta)


func _drain(delta: float) -> void:
    if _depleted:
        return
    current_charge = max(0.0, current_charge - drain_rate * delta)
    emit_signal("charge_updated", current_charge, max_charge)

    if current_charge <= 0.0:
        current_charge = 0.0
        _depleted = true
        emit_signal("charge_depleted")


func _recharge(delta: float) -> void:
    if current_charge >= max_charge:
        return

    # Wait for recharge_delay before starting to fill
    if _recharge_timer < recharge_delay:
        _recharge_timer += delta
        return

    var was_depleted = _depleted
    current_charge   = min(max_charge, current_charge + recharge_rate * delta)
    emit_signal("charge_updated", current_charge, max_charge)

    if was_depleted and current_charge >= max_charge:
        _depleted = false
        emit_signal("charge_recharged")


func set_transformed(value: bool) -> void:
    is_transformed   = value
    _recharge_timer  = 0.0   # reset delay whenever state changes


func can_transform() -> bool:
    return not _depleted and current_charge >= max_charge * 0.1