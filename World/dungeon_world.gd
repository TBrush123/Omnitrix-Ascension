class_name DungeonWorld
extends Node2D

const SOURCE_ID = 0
const FLOOR_TILE = Vector2i(0, 0)
const WALL_TILE  = Vector2i(1, 0)

const CORRIDOR_HALF_WIDTH = 5

@onready var tilemap: TileMapLayer = $TileMapLayer

var generator: DungeonGenerator


func initialize(gen: DungeonGenerator) -> void:
	generator = gen
	_stamp_rooms()


func _stamp_rooms() -> void:
	for grid_pos in generator.rooms.keys():
		var cell: DungeonGenerator.RoomCell = generator.rooms[grid_pos]

		if cell.data != null and cell.data.scene != null:
			var room_instance = cell.data.scene.instantiate()
			room_instance.position = cell.world_pos
			add_child(room_instance)
			cell.instance = room_instance
		else:
			push_error("No scene for room at " + str(grid_pos))


func _copy_room_to_tilemap(room_instance: RoomTemplate) -> void:
	var used = room_instance.tilemap.get_used_cells()
	for local_cell in used:
		var world_pos   = room_instance.tilemap.map_to_local(local_cell) \
						+ room_instance.position
		var shared_cell = tilemap.local_to_map(world_pos)
		var source      = room_instance.tilemap.get_cell_source_id(local_cell)
		var atlas       = room_instance.tilemap.get_cell_atlas_coords(local_cell)
		tilemap.set_cell(shared_cell, source, atlas)


func _stamp_empty_room(cell: DungeonGenerator.RoomCell) -> void:
	var tile_size = tilemap.tile_set.tile_size
	var room_size = Vector2(DungeonGenerator.ROOM_SIZE)
	var top_left  = cell.world_pos    # world_pos is already top-left corner
	var cols      = int(room_size.x / tile_size.x)
	var rows      = int(room_size.y / tile_size.y)

	for x in cols:
		for y in rows:
			var world_pos = top_left + Vector2(x * tile_size.x, y * tile_size.y)
			var map_cell  = tilemap.local_to_map(world_pos)
			var is_wall   = x == 0 or y == 0 or x == cols - 1 or y == rows - 1
			tilemap.set_cell(map_cell, SOURCE_ID,
				WALL_TILE if is_wall else FLOOR_TILE)


func _carve_corridors() -> void:
	# In the grid approach, corridors are just the doorway openings
	# between adjacent rooms — no separate corridor paths needed.
	# We punch open the walls wherever two rooms share a door.
	for grid_pos in generator.rooms.keys():
		var cell: DungeonGenerator.RoomCell = generator.rooms[grid_pos]
		_open_room_doors(cell)


func _open_room_doors(cell: DungeonGenerator.RoomCell) -> void:
	var tile_size = tilemap.tile_set.tile_size
	var room_size = Vector2(DungeonGenerator.ROOM_SIZE)
	var cols      = int(room_size.x / tile_size.x)
	var rows      = int(room_size.y / tile_size.y)

	# Calculate door positions in world space for each open direction
	for dir_name in cell.doors.keys():
		if not cell.doors[dir_name]:
			continue   # wall here — don't punch

		var door_world_pos: Vector2

		match dir_name:
			"north":
				# Center of the north wall
				door_world_pos = cell.world_pos \
					+ Vector2(room_size.x / 2.0, 0)
			"south":
				door_world_pos = cell.world_pos \
					+ Vector2(room_size.x / 2.0, room_size.y)
			"east":
				door_world_pos = cell.world_pos \
					+ Vector2(room_size.x, room_size.y / 2.0)
			"west":
				door_world_pos = cell.world_pos \
					+ Vector2(0, room_size.y / 2.0)

		_punch_door(door_world_pos, dir_name)


func _punch_door(world_pos: Vector2, dir_name: String) -> void:
	var center_cell = tilemap.local_to_map(world_pos)

	# Punch perpendicular to the wall direction
	# North/South doors are wide horizontally, narrow vertically
	# East/West doors are wide vertically, narrow horizontally
	var is_horizontal_wall = dir_name == "north" or dir_name == "south"

	for a in range(-CORRIDOR_HALF_WIDTH, CORRIDOR_HALF_WIDTH + 1):
		for b in range(-2, 3):   # narrow depth through the wall
			var offset: Vector2i
			if is_horizontal_wall:
				offset = Vector2i(a, b)
			else:
				offset = Vector2i(b, a)
			tilemap.set_cell(
				center_cell + offset,
				SOURCE_ID,
				FLOOR_TILE
			)
