class_name DungeonGenerator
extends RefCounted

const ROOM_SIZE:  Vector2i = Vector2i(1280, 960)  # pixels per cell
const GRID_SIZE:  Vector2i = Vector2i(7, 7)        # max grid dimensions
const ROOM_COUNT: int      = 6                     # rooms per floor

var registry: RoomRegistry = null

class RoomCell:
	var grid_pos:  Vector2i
	var world_pos: Vector2
	var type:      RoomData.RoomType = RoomData.RoomType.COMBAT
	var data:      RoomData = null
	var cleared:   bool     = false
	var instance: Node2D = null
	var doors: Dictionary = {
		"north": false,
		"south": false,
		"east":  false,
		"west":  false,
	}

	func _init(gpos: Vector2i) -> void:
		grid_pos  = gpos
		world_pos = Vector2(gpos.x * ROOM_SIZE.x, gpos.y * ROOM_SIZE.y)

const DIRECTIONS = {
	"north": Vector2i( 0, -1),
	"south": Vector2i( 0,  1),
	"east":  Vector2i( 1,  0),
	"west":  Vector2i(-1,  0),
}
const OPPOSITE = {
	"north": "south",
	"south": "north",
	"east":  "west",
	"west":  "east",
}

var rooms: Dictionary = {}   # Vector2i → RoomCell
var start_pos: Vector2i
var boss_pos:  Vector2i


func generate(new_registry: RoomRegistry) -> void:
	rooms.clear()
	registry = new_registry
	_random_walk()
	_assign_types()
	_open_doors()


func _random_walk() -> void:
	# Start in the center of the grid
	var center = Vector2i(GRID_SIZE.x / 2, GRID_SIZE.y / 2)
	start_pos  = center

	var current = center
	var path: Array[Vector2i] = [current]
	rooms[current] = RoomCell.new(current)

	while rooms.size() < ROOM_COUNT:
		# Pick a random direction
		var dirs   = DIRECTIONS.keys()
		dirs.shuffle()
		var moved  = false

		for dir_name in dirs:
			var next = current + DIRECTIONS[dir_name]

			# Stay within grid bounds
			if next.x < 0 or next.x >= GRID_SIZE.x:
				continue
			if next.y < 0 or next.y >= GRID_SIZE.y:
				continue

			# Skip already placed rooms sometimes
			# to encourage branching
			if rooms.has(next) and randf() < 0.6:
				continue

			if not rooms.has(next):
				rooms[next] = RoomCell.new(next)

			current = next
			path.append(current)
			moved = true
			break

		# If stuck, backtrack
		if not moved:
			if path.size() > 1:
				path.pop_back()
				current = path.back()


func _assign_types() -> void:
	
	print("RoomRegistry exists: ", registry != null)
	print("REST pool size: ",     registry.rest_rooms.size())
	print("COMBAT pool size: ",   registry.combat_rooms.size())
	var farthest_pos  = start_pos
	var farthest_dist = 0

	for pos in rooms.keys():
		var dist = (pos - start_pos).length()
		if dist > farthest_dist:
			farthest_dist = dist
			farthest_pos  = pos

	boss_pos = farthest_pos

	# Assign types
	for pos in rooms.keys():
		var room = rooms[pos]
		if pos == start_pos:
			room.type = RoomData.RoomType.REST
			room.data = registry.get_random(RoomData.RoomType.REST)
		elif pos == boss_pos:
			room.type = RoomData.RoomType.EXIT
			room.data = registry.get_random(RoomData.RoomType.EXIT)
		else:
			var roll = randf()
			if roll < 0.55:
				room.type = RoomData.RoomType.COMBAT
				room.data = registry.get_random(RoomData.RoomType.COMBAT)
			elif roll < 0.75:
				room.type = RoomData.RoomType.TREASURE
				room.data = registry.get_random(RoomData.RoomType.TREASURE)
			else:
				room.type = RoomData.RoomType.ELITE
				room.data = registry.get_random(RoomData.RoomType.ELITE)


func _open_doors() -> void:
	# For each room, open doors toward adjacent rooms
	for pos in rooms.keys():
		var room = rooms[pos]
		for dir_name in DIRECTIONS.keys():
			var neighbor_pos = pos + DIRECTIONS[dir_name]
			if rooms.has(neighbor_pos):
				room.doors[dir_name] = true
