class_name RoomNode
extends RefCounted

enum Door {
    NORTH,
    EAST,
    SOUTH,
    WEST
}

var id: int
var position: Vector2
var size: Vector2
var data: RoomData
var connections: Array[int]
var is_furthest: bool = false

func get_door_position(door: Door) -> Vector2:
    match door:
        Door.NORTH:
            return position + Vector2(size.x / 2, 0)
        Door.EAST:
            return position + Vector2(size.x, size.y / 2)
        Door.SOUTH:
            return position + Vector2(size.x / 2, size.y)
        Door.WEST:
            return position + Vector2(0, size.y / 2)
        _:
            return position

func get_nearest_door(target: Vector2) -> Door:
    var closest_door: Door = Door.NORTH
    var closest_distance: float = INF
    for door in Door.values():
        var door_pos = get_door_position(door)
        var distance = door_pos.distance_to(target)
        if distance < closest_distance:
            closest_distance = distance
            closest_door = door
    return closest_door