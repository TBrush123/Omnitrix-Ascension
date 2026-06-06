# xlr8_slash.gd
class_name XLR8Slash
extends MeleeHitboxBase

const COMBO_DELAY: float = 0.12
var _is_combo_hit: bool  = false
var _momentum_stacks: int = 0    # set by player before add_child


func _on_spawned() -> void:
    lifetime        = 0.10
    knockback_force = 80.0 + _momentum_stacks * 15.0   # more stacks = more knockback

    var tween = create_tween()
    tween.tween_property($Sprite2D, "modulate",
        Color(0.5, 0.9, 1.0, 0.0), 0.10) \
        .from(Color(0.5, 0.9, 1.0, 1.0))
    _start_lifetime()

    if _is_combo_hit:
        return

    await get_tree().create_timer(COMBO_DELAY).timeout
    if not is_instance_valid(self):
        return

    if _momentum_stacks >= MomentumComponent.MAX_STACKS:
        _spawn_triple_hit()   # max momentum: three slashes at once
    else:
        _spawn_second_hit()


func _spawn_second_hit() -> void:
    var second               = duplicate()
    second._is_combo_hit     = true
    second._momentum_stacks  = _momentum_stacks
    second.position          = position
    second.direction         = direction.rotated(deg_to_rad(25))
    second.damage            = damage * 0.7
    get_parent().add_child(second)


func _spawn_triple_hit() -> void:
    # Three simultaneous slashes at -30°, 0°, +30°
    for angle_deg in [-30.0, 0.0, 30.0]:
        var hit               = duplicate()
        hit._is_combo_hit     = true
        hit._momentum_stacks  = _momentum_stacks
        hit.position          = position
        hit.direction         = direction.rotated(deg_to_rad(angle_deg))
        hit.damage            = damage * 0.85
        get_parent().add_child(hit)