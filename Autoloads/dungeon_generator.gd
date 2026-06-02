class_name DungeonGenerator
extends RefCounted

const ROOM_SIZE: Vector2 = Vector2(320, 240) # Assuming all rooms are the same size for simplicity
const PLACE_RADIUS: float = 500.0 # Minimum distance between room centers
const PLACE_JITTER: float = 80.0 # Random offset applied to room positions
const BONUS_CONNECTION_CHANCE: float = 0.35 # Chance to add extra connections between rooms
const BONUS_CONNECTION_RADIUS: float = 500.0 # Max distance for bonus connections
const ROOM_COUNT_MIN: int = 7
const ROOM_COUNT_MAX: int = 10
const MAX_PLACE_ATTEMPTS: int = 50

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
	var queue: Array = []

	var start = RoomNode.new()
	start.id = 0
	start.position = Vector2.ZERO
	start.size = ROOM_SIZE
	rooms.append(start)
	queue.push_back(0)

	var chance = 1.0

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

		if randf() < chance:
			queue.push_back(parent_idx)
			chance *= 0.75

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
	for i in rooms.size():
		var room = rooms[i]
		
		if i == 0:
			room.data = RoomRegistry.get_random(RoomData.RoomType.REST)
			continue
		
		if room.is_furthest:
			room.data = RoomRegistry.get_random(RoomData.RoomType.EXIT)
			continue
		
		var roll = randf()
		if roll < 0.55:
			room.data = RoomRegistry.get_random(RoomData.RoomType.COMBAT)
		elif roll < 0.75:
			room.data = RoomRegistry.get_random(RoomData.RoomType.TREASURE)
		else:
			room.data = RoomRegistry.get_random(RoomData.RoomType.ELITE)

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
		var min_dist_x = ROOM_SIZE.x
		var min_dist_y = ROOM_SIZE.y
		var diff = (pos - room.position).abs()
		if diff.x < min_dist_x and diff.y < min_dist_y:
			return false
	return true	

func _build_corridors() -> void:
	var seen: Array[String] = []

	for room in rooms:
		for other_id in room.connections:

			var key = "%d-%d" % [mini(room.id, other_id), maxi(room.id, other_id)]
			if key in seen:
				continue
			seen.append(key)

			var other = rooms[other_id]
			var corridor = CorridorData.new()
			corridor.from_room_id = room.id
			corridor.to_room_id = other.id
			corridor.points = _make_corridor_points(room, other)
			corridors.append(corridor)

func _make_corridor_points(a: RoomNode, b: RoomNode) -> Array[Vector2]:
	var door_a = a.get_exit_door(b.position)
	var door_b = b.get_exit_door(a.position)

	var start = a.get_door_position(door_a)
	var end_  = b.get_door_position(door_b)
	
	# Same side → U-shape
	if door_a == door_b:
		var offset = 60.0  # how far to loop out before turning
		match door_a:
			RoomNode.Door.EAST:
				var out_x = max(start.x, end_.x) + offset
				return [start, Vector2(out_x, start.y), Vector2(out_x, end_.y), end_]
			RoomNode.Door.WEST:
				var out_x = min(start.x, end_.x) - offset
				return [start, Vector2(out_x, start.y), Vector2(out_x, end_.y), end_]
			RoomNode.Door.SOUTH:
				var out_y = max(start.y, end_.y) + offset
				return [start, Vector2(start.x, out_y), Vector2(end_.x, out_y), end_]
			RoomNode.Door.NORTH:
				var out_y = min(start.y, end_.y) - offset
				return [start, Vector2(start.x, out_y), Vector2(end_.x, out_y), end_]
	
	# Opposite sides → Z-shape
	var opposite_pairs = [
		[RoomNode.Door.EAST,  RoomNode.Door.WEST],
		[RoomNode.Door.WEST,  RoomNode.Door.EAST],
		[RoomNode.Door.NORTH, RoomNode.Door.SOUTH],
		[RoomNode.Door.SOUTH, RoomNode.Door.NORTH],
	]
	
	for pair in opposite_pairs:
		if door_a == pair[0] and door_b == pair[1]:
			if door_a == RoomNode.Door.EAST or door_a == RoomNode.Door.WEST:
				var mid_x = (start.x + end_.x) / 2
				return [start, Vector2(mid_x, start.y), Vector2(mid_x, end_.y), end_]
			else:
				var mid_y = (start.y + end_.y) / 2
				return [start, Vector2(start.x, mid_y), Vector2(end_.x, mid_y), end_]
	
	# Adjacent sides → L-shape
	return [start, Vector2(end_.x, start.y), end_]