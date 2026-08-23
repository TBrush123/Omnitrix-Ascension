class_name Chaser
extends EnemyBase

func _move(_delta: float) -> void:
    var dir: Vector2

    if _confused:
        dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
    else:
        dir = get_direction_to_player()
    

    velocity = dir * move_speed
    move_and_slide()
