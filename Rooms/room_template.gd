class_name RoomTemplate
extends Node2D

@export var room_size_tiles: Vector2i = Vector2i(80, 60) # Size of the room in tiles

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var door_north: Marker2D = $Markers/DoorNorth
@onready var door_east: Marker2D = $Markers/DoorEast
@onready var door_south: Marker2D = $Markers/DoorSouth
@onready var door_west: Marker2D = $Markers/DoorWest

const SOURCE_ID = 0
const FLOOR_TILE = Vector2i(0, 0)
const WALL_TILE = Vector2i(1, 0)

func build() -> void:
    tilemap.clear()
    _paint_floor()
    _paint_walls()
    _place_door_markers()

func _paint_floor() -> void:
    for x in range(room_size_tiles.x):
        for y in range(room_size_tiles.y):
            tilemap.set_cellv(Vector2i(x, y), SOURCE_ID, FLOOR_TILE)

func _paint_walls() -> void:
    for x in room_size_tiles.x:
        tilemap.set_cellv(Vector2i(x, -1), SOURCE_ID, WALL_TILE)
        tilemap.set_cellv(Vector2i(x, room_size_tiles.y - 1), SOURCE_ID, WALL_TILE)
    for y in room_size_tiles.y:
        tilemap.set_cellv(Vector2i(-1, y), SOURCE_ID, WALL_TILE)
        tilemap.set_cellv(Vector2i(room_size_tiles.x - 1, y), SOURCE_ID, WALL_TILE)
    
func _place_door_markers() -> void:
    var tile_size = tilemap.tile_set.tile_size
    var half = Vector2(room_size_tiles) * Vector2(tile_size) / 2

    door_north.position = Vector2(half.x, 0)
    door_east.position = Vector2(room_size_tiles.x * tile_size.x, half.y)
    door_south.position = Vector2(half.x, room_size_tiles.y * tile_size.y)
    door_west.position = Vector2(0, half.y)

func get_door_position(door: RoomNode.Door) -> Vector2:
    match door:
        RoomNode.Door.NORTH:
            return door_north.global_position
        RoomNode.Door.EAST:
            return door_east.global_position
        RoomNode.Door.SOUTH:
            return door_south.global_position
        RoomNode.Door.WEST:
            return door_west.global_position
        _:
            return global_position