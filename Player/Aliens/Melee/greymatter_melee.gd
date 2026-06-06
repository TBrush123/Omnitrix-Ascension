class_name GreymatterMelee
extends MeleeHitboxBase

var flinch_chance: float = 0.25
var flinch_time: float = 1.0
var punch_damage: float = 1.0

func _on_spawned() -> void:
    _start_lifetime()
    
    var tween = create_tween()
    tween.tween_property($Sprite2D, "modulate:a",
    0.0, lifetime).set_delay(lifetime * 0.3)

func _on_hit(enemy: Node) -> void:
    if enemy.has_method("flinch"):
        var rolled_number = randf()
        if rolled_number <= flinch_chance:
            enemy.flinch(flinch_time)
    if enemy.has_no_de("HealthComponent"):
        enemy.get_node("HelthComponent").take_damage(damage)
    if enemy.has_method("apply_knockback"):
        var direction = (enemy.global_position - global_position).normalized()
        enemy.apply_knockback(direction, knockback_force)

