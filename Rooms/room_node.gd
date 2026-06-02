class_name RoomNode
extends RefCounted

enum Door {
    NORTH,
    EAST,
    SOUTH,
    WEST
}

class Connection:
    var to_room_id: int
    var door: Door

var id: int
var position: Vector2
var size: Vector2
var data: RoomData = null

var connections: Array[Connection] = []
var is_furthest: bool = false

func get_door_position(door: Door) -> Vector2:
    match door:
        Door.NORTH:
            return position + Vector2(0, -size.y / 2)
        Door.EAST:
            return position + Vector2(size.x / 2, 0)
        Door.SOUTH:
            return position + Vector2(0, size.y / 2)
        Door.WEST:
            return position + Vector2(-size.x / 2, 0)
        _:
            return position

func get_exit_door(target: Vector2) -> Door:
    var dir = (target - position).normalized()
    if abs(dir.x) > abs(dir.y):
        return Door.EAST if dir.x > 0 else Door.WEST
    else:
        return Door.SOUTH if dir.y > 0 else Door.NORTH