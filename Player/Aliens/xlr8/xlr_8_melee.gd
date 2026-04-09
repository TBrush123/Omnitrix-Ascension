class_name XLR8Melee
extends MeleeHitboxBase

const COMBO_DELAY: float = 0.10
var _is_combo_hit: bool = false

func _on_spawned() -> void:
	if not _is_combo_hit:
		direction = direction.rotated(deg_to_rad(-15))
	else:
		direction = direction.rotated(deg_to_rad(30))

	lifetime = 0.12
	knockback_force = 120.0
	_start_lifetime()

	var tween = create_tween()
	tween.tween_property($Sprite2D, 'scale',
			Vector2(1.0, 1.0), 0.05).from(Vector2(0.3, 1.0))
	tween.tween_property($Sprite2D, 'modulate:a', 0.0, 0.05)

	if _is_combo_hit:
		return


	await get_tree().create_timer(COMBO_DELAY).timeout
	if not is_instance_valid(self):
		return
	_spawn_second_hit()

func _spawn_second_hit() -> void:
	var second = duplicate()
	second._is_combo_hit = true
	second.position = position
	second.direction = direction
	second.damage = damage * 0.7
	get_parent().add_child(second)