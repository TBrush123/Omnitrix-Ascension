class_name HeatblastMelee
extends MeleeHitboxBase

const BURN_TICKS:    int   = 5
const BURN_INTERVAL: float = 0.5
const BURN_DAMAGE:   float = 0.4


func _on_spawned() -> void:
	_start_lifetime()

	print("Heatblast spawned at: ", global_position)

	var tween = create_tween().set_loops(3)
	tween.tween_property($Sprite2D, "modulate",
		Color(1.0, 0.6, 0.1, 0.9), 0.04)
	tween.tween_property($Sprite2D, "modulate",
		Color(1.0, 0.9, 0.3, 0.7), 0.04)

	create_tween().tween_property($Sprite2D, "modulate:a",
		0.0, lifetime).set_delay(lifetime * 0.4)

func _on_hit(enemy: Node) -> void:
	print("Heatblast melee hit: ", enemy.name)
	if enemy.has_method("apply_dot"):
		enemy.apply_dot(BURN_DAMAGE, BURN_TICKS, BURN_INTERVAL)
	else:
		if enemy.has_node("HealthComponent"):
			enemy.get_node("HealthComponent").take_damage(BURN_DAMAGE * BURN_TICKS * 0.5)
	
	if enemy.has_method("apply_knockback"):
		var direction = (enemy.global_position - global_position).normalized()
		enemy.apply_knockback(direction, knockback_force)