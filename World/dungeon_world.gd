class_name DungeonWorld
extends Node2D

const SOURCE_ID = 0
const FLOOR_TILE = Vector2i(0, 0)
const WALL_TILE = Vector2i(1, 0)

const CORRIDOR_HALF_WIDTH = 5

@onready var tilemap: TileMapLayer = $TileMapLayer

var generator: DungeonGenerator

func initialize(gen: DungeonGenerator) -> void:
	generator = gen
	_stamp_rooms()
	_carve_corridors()
	_open_doors()

func _stamp_rooms() -> void:
	for room in generator.rooms:
		var scene: PackedScene = room.data.scene if room.data else null
		if scene:
			var room_instance: RoomTemplate = scene.instantiate()
			room_instance.position = room.position
			add_child(room_instance)
			room_instance.build()
			_copy_room_to_tilemap(room_instance, room)
			room_instance.queue_free()
		else:
			_stamp_empty_room(room)

func _copy_room_to_tilemap(room_instance: RoomTemplate, room: RoomNode) -> void:
	var used = room_instance.tilemap.get_used_cells()
	for local_cell in used:
		var world_pos = room_instance.tilemap.map_to_local(local_cell) + room_instance.position
		var shared_cell = tilemap.local_to_map(world_pos)
		var source = room_instance.tilemap.get_cell_source_id(local_cell)
		var atlas = room_instance.tilemap.get_cell_atlas_coords(local_cell)
		tilemap.set_cell(shared_cell, source, atlas)

func _stamp_empty_room(room: RoomNode) -> void:
	var tile_size = tilemap.tile_set.tile_size
	var half = room.size / 2
	var top_left = room.position - half
	var cols = int(room.size.x / tile_size.x)
	var rows = int(room.size.y / tile_size.y)

	for x in cols:
		for y in rows:
			var world_pos = top_left + Vector2(x * tile_size.x, y * tile_size.y)
			var cell = tilemap.local_to_map(world_pos)
			var is_wall = x == 0 or y == 0 or x == cols - 1 or y == rows - 1
			tilemap.set_cell(cell, SOURCE_ID, WALL_TILE if is_wall else FLOOR_TILE)

func _carve_corridors() -> void:
	for corridor in generator.corridors:
		var pts = corridor.points
		for i in range(pts.size() - 1):
			_carve_line(pts[i], pts[i + 1])
		
func _carve_line(from: Vector2, to: Vector2) -> void:
	var from_cell = tilemap.local_to_map(from)
	var to_cell   = tilemap.local_to_map(to)
	var diff  = to_cell - from_cell
	var steps = maxi(abs(diff.x), abs(diff.y))
	if steps == 0:
		return

	for i in steps + 1:
		var t = float(i) / float(steps)
		var cell = Vector2i(
			from_cell.x + roundi(float(diff.x) * t),
			from_cell.y + roundi(float(diff.y) * t)
		)
		for dx in range(-CORRIDOR_HALF_WIDTH, CORRIDOR_HALF_WIDTH + 1):
			for dy in range(-CORRIDOR_HALF_WIDTH, CORRIDOR_HALF_WIDTH + 1):
				tilemap.set_cell(cell + Vector2i(dx, dy), SOURCE_ID, FLOOR_TILE)

func _open_doors() -> void:
	for corridor in generator.corridors:
		if corridor.points.size() < 2:
			continue
		var entry = corridor.points[0]
		var exit_ = corridor.points[-1]
		_punch_door(entry)
		_punch_door(exit_)

func _punch_door(world_pos: Vector2) -> void:
	var cell = tilemap.local_to_map(world_pos)
	for dx in range(-CORRIDOR_HALF_WIDTH, CORRIDOR_HALF_WIDTH + 1):
		for dy in range(-CORRIDOR_HALF_WIDTH, CORRIDOR_HALF_WIDTH + 1):
			tilemap.set_cell(cell + Vector2i(dx, dy), SOURCE_ID, FLOOR_TILE)
