class_name Fireball
extends ProjectileBase

var can_bounce: bool = false
var does_split: bool = false
var burn_damage: float = 0.4
var burn_ticks: int = 5

var _bounce_count: int = 0
const MAX_BOUNCES: int = 1

func _setup() -> void:
    max_range = 260.0
    speed = 220.0
    knockback = 80.0

    scale = Vector2.ZERO
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2.ONE, 0.08)

func _on_hit_enemy(enemy: Node) -> void:
    if enemy.has_method("apply_dot"):
        enemy.apply_burn(burn_damage, burn_ticks)
    _on_destroyed()

func _on_hit_wall(_wall: Node) -> void:
    if can_bounce and _bounce_count < MAX_BOUNCES:
        _bounce_count += 1
        _distance_traveled = 0.0
        if abs(direction.x) > abs(direction.y):
            direction.x *= -1
        else:
            direction.y *= -1
    else:
        _on_destroyed()
    
func _on_max_range() -> void:
    _on_destroyed()
