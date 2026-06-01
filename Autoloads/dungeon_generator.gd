class_name DungeonGenerator
extends RefCounted

const ROOM_SIZE: Vector2 = Vector2(320, 240) # Assuming all rooms are the same size for simplicity
const PLACE_RADIUS: float = 400.0 # Minimum distance between room centers
const PLACE_JITTER: float = 60.0 # Random offset applied to room positions
const BONUS_CONNECTION_CHANCE: float = 0.35 # Chance to add extra connections between rooms
const BONUS_CONNECTION_RADIUS: float = 500.0 # Max distance for bonus connections
const ROOM_COUNT_MIN: int = 7
const ROOM_COUNT_MAX: int = 10
const MAX_PLACE_ATTEMPTS: int = 20

var rooms: Array[RoomNode] = []
var corridors: Array[CorridorData] = []

func generate() -> void:
	rooms.clear()
	corridors.clear()

	_place_rooms()
	_assign_content()
	_build_corridors()

func _place_rooms() -> void:
	var count = randi_range(ROOM_COUNT_MIN, ROOM_COUNT_MAX)
	var queue: Array[RoomNode] = []

	var start = RoomNode.new()
	start.id = 0
	start.position = Vector2.ZERO
	start.size = ROOM_SIZE
	rooms.append(start)
	queue.push_back(0)

	while queue.size() > 0 and rooms.size() < count:
		var parent_idx = queue.pop_front()
		var parent = rooms[parent_idx]

		var new_pos = _try_place_near(parent.position)
		if new_pos == Vector2.INF:
			continue

		var room = RoomNode.new()
		room.id = rooms.size()
		room.position = new_pos
		room.size = ROOM_SIZE
		rooms.append(room)
		queue.push_back(room.id)

		_add_connection(parent.id, room.id)

		for other in rooms:
			if other.id == parent.id or other.id == room.id:
				continue
			if other.position.distance_to(room.position) < BONUS_CONNECTION_RADIUS and randf() < BONUS_CONNECTION_CHANCE:
				_add_connection(room.id, other.id)
	var furthest = rooms.reduce(func(acc, room):
		if room.position.length() > acc.position.length():
			return room
		return acc, rooms[0])
	furthest.is_furthest = true

func _add_connection(from_id: int, to_id: int) -> void:
	if not rooms[from_id].connections.has(to_id):
		rooms[from_id].connections.append(to_id)
	if not rooms[to_id].connections.has(from_id):
		rooms[to_id].connections.append(from_id)

func _assign_content() -> void:
	for room in rooms:
		room.data = RoomTypeRegistry.get_random(RoomData.RoomType.COMBAT)

func _try_place_near(center: Vector2) -> Vector2:
	for i in range(MAX_PLACE_ATTEMPTS):
		var angle = randf() * TAU
		var radius = PLACE_RADIUS + randf_range(-PLACE_JITTER, PLACE_JITTER)
		var offset = Vector2(cos(angle), sin(angle)) * radius
		var candidate = center + offset

		if _is_position_valid(candidate):
			return candidate

	return Vector2.INF # Failed to find a valid position after max attempts

func _is_position_valid(pos: Vector2) -> bool:
	for room in rooms:
		var min_dist = (ROOM_SIZE.x + ROOM_SIZE.y) / 2 + 20.0
		if room.position.distance_to(pos) < min_dist:
			return false
	return true