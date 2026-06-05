extends Camera2D

@export var deadzone_size: Vector2 = Vector2(120, 80)

@export var follow_speed: float = 10.0

func _ready() -> void:
    top_level = true

func _process(delta: float) -> void:
    var player_pos = get_parent().global_position
    var cam_pos = global_position

    var offset = player_pos - cam_pos

    var target_offset = Vector2(
        _push(offset.x, deadzone_size.x / 2),
        _push(offset.y, deadzone_size.y / 2)
    ) 
    global_position = cam_pos.lerp(cam_pos + target_offset, follow_speed * delta)

func _push(value: float, boundary: float) -> float:
    if value > boundary:
        return value - boundary
    elif value < -boundary:
        return value + boundary
    return 0.0


