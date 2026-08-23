class_name RoomTemplate
extends Node2D

@export var room_size_tiles: Vector2i = Vector2i(80, 60)

@onready var tilemap:     TileMapLayer = $TileMapLayer
@onready var door_north:  Node2D       = $Doors/DoorNorth
@onready var door_east:   Node2D       = $Doors/DoorEast
@onready var door_south:  Node2D       = $Doors/DoorSouth
@onready var door_west:   Node2D       = $Doors/DoorWest

const SOURCE_ID  = 0
const FLOOR_TILE = Vector2i(0, 0)
const WALL_TILE  = Vector2i(1, 0)



func build() -> void:
	tilemap.clear()
	_paint_floor()
	_paint_walls()
	_place_door_markers()


func _paint_floor() -> void:
	for x in range(room_size_tiles.x):
		for y in range(room_size_tiles.y):
			tilemap.set_cell(Vector2i(x, y), SOURCE_ID, FLOOR_TILE)


func _paint_walls() -> void:
	for x in range(room_size_tiles.x):
		tilemap.set_cell(Vector2i(x, -1),                    SOURCE_ID, WALL_TILE)
		tilemap.set_cell(Vector2i(x, room_size_tiles.y),     SOURCE_ID, WALL_TILE)
	for y in range(-1, room_size_tiles.y + 1):
		tilemap.set_cell(Vector2i(-1, y),                    SOURCE_ID, WALL_TILE)
		tilemap.set_cell(Vector2i(room_size_tiles.x, y),     SOURCE_ID, WALL_TILE)


func _place_door_markers() -> void:
	var tile_size = tilemap.tile_set.tile_size
	var half      = Vector2(room_size_tiles) * Vector2(tile_size) / 2.0

	door_north.position = Vector2(half.x, 0)
	door_east.position  = Vector2(room_size_tiles.x * tile_size.x, half.y)
	door_south.position = Vector2(half.x, room_size_tiles.y * tile_size.y)
	door_west.position  = Vector2(0, half.y)


func get_door_position(door: RoomNode.Door) -> Vector2:
	match door:
		RoomNode.Door.NORTH: return door_north.global_position
		RoomNode.Door.EAST:  return door_east.global_position
		RoomNode.Door.SOUTH: return door_south.global_position
		RoomNode.Door.WEST:  return door_west.global_position
		_:                   return global_position
