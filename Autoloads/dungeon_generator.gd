class_name DungeonGenerator
extends RefCounted

const ROOM_SIZE: Vector2 = Vector2(1280, 960) # Assuming all rooms are the same size for simplicity
const PLACE_RADIUS: float = 2000.0 # Minimum distance between room centers
const PLACE_JITTER: float = 320.0 # Random offset applied to room positions
const BONUS_CONNECTION_CHANCE: float = 0.35 # Chance to add extra connections between rooms
const BONUS_CONNECTION_RADIUS: float = 1800.0 # Max distance for bonus connections
const ROOM_COUNT_MIN: int = 4
const ROOM_COUNT_MAX: int = 5
const MAX_PLACE_ATTEMPTS: int = 50

var rooms: Array[RoomNode] = []
var corridors: Array[CorridorData] = []

func generate() -> void:
	rooms.clear()
	corridors.clear()

	_place_rooms()
	_assign_content()
	_build_corridors()
	_merge_shared_corridors()

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

func _add_connection(a: int, b: int) -> void:
	var room_a = rooms[a]
	var room_b = rooms[b]

	# Check not already connected
	for conn in room_a.connections:
		if conn.to_room_id == b:
			return

	var conn_a = RoomNode.Connection.new()
	conn_a.to_room_id = b
	conn_a.door = room_a.get_exit_door(room_b.position)
	room_a.connections.append(conn_a)

	var conn_b = RoomNode.Connection.new()
	conn_b.to_room_id = a
	conn_b.door = room_b.get_exit_door(room_a.position)
	room_b.connections.append(conn_b)

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
		for connection in room.connections:

			var other_id = connection.to_room_id
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
	var door_a: RoomNode.Door
	var door_b: RoomNode.Door

	# Get doors from connection structs
	for conn in a.connections:
		if conn.to_room_id == b.id:
			door_a = conn.door
			break

	for conn in b.connections:
		if conn.to_room_id == a.id:
			door_b = conn.door
			break

	var start = a.get_door_position(door_a)
	var end_  = b.get_door_position(door_b)

	# Same side → U-shape
	if door_a == door_b:
		var offset = 80.0
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
	var is_opposite = (door_a == RoomNode.Door.EAST  and door_b == RoomNode.Door.WEST)  or \
					  (door_a == RoomNode.Door.WEST  and door_b == RoomNode.Door.EAST)  or \
					  (door_a == RoomNode.Door.NORTH and door_b == RoomNode.Door.SOUTH) or \
					  (door_a == RoomNode.Door.SOUTH and door_b == RoomNode.Door.NORTH)

	if is_opposite:
		if door_a == RoomNode.Door.EAST or door_a == RoomNode.Door.WEST:
			var mid_x = (start.x + end_.x) / 2
			return [start, Vector2(mid_x, start.y), Vector2(mid_x, end_.y), end_]
		else:
			var mid_y = (start.y + end_.y) / 2
			return [start, Vector2(start.x, mid_y), Vector2(end_.x, mid_y), end_]

	# Adjacent sides → L-shape
	if door_a == RoomNode.Door.EAST or door_a == RoomNode.Door.WEST:
		return [start, Vector2(end_.x, start.y), end_]
	else:
		return [start, Vector2(start.x, end_.y), end_]

func _check_minimal_distance(point1: Vector2, point2: Vector2, other: Vector2) -> Array[Vector2]:
	var dist1 = point1.distance_to(other)
	var dist2 = point2.distance_to(other)
	var new_points: Array[Vector2]
	if dist1 < dist2:
		new_points = [other, point2]
	else:
		new_points = [point1, other]
	
	return new_points

func _merge_shared_corridors() -> void:
	for room in rooms:
		# Group corridors by which door they exit from this room
		var by_door: Dictionary = {}
		
		for corridor in corridors:
			if corridor.from_room_id == room.id:
				var door = _get_corridor_door(corridor, room, true)
				if not by_door.has(door):
					by_door[door] = []
				by_door[door].append(corridor)
			elif corridor.to_room_id == room.id:
				var door = _get_corridor_door(corridor, room, false)
				if not by_door.has(door):
					by_door[door] = []
				by_door[door].append(corridor)
		
		# For each door that has more than one corridor, merge them
		for door in by_door:
			var group: Array = by_door[door]
			if group.size() < 2:
				continue
			_merge_corridor_group(group, room, door)

func _get_corridor_door(corridor: CorridorData, room: RoomNode, is_from: bool) -> RoomNode.Door:
	if is_from:
		return rooms[corridor.from_room_id].get_exit_door(rooms[corridor.to_room_id].position)
	else:
		return rooms[corridor.to_room_id].get_exit_door(rooms[corridor.from_room_id].position)

func _merge_corridor_group(group: Array, room: RoomNode, door: RoomNode.Door) -> void:
	var door_pos = room.get_door_position(door)
	
	# Find the shared exit point — all corridors in this group start at the same door
	# so we insert a shared first segment up to a junction point
	# The junction is just slightly outside the door
	var junction_offset = 40.0
	var junction: Vector2
	match door:
		RoomNode.Door.EAST:  junction = door_pos + Vector2(junction_offset, 0)
		RoomNode.Door.WEST:  junction = door_pos + Vector2(-junction_offset, 0)
		RoomNode.Door.SOUTH: junction = door_pos + Vector2(0, junction_offset)
		RoomNode.Door.NORTH: junction = door_pos + Vector2(0, -junction_offset)
	
	# Rewrite each corridor in the group so it starts at the junction instead of the door
	# Then they all share the door→junction segment visually (drawn once)
	for corridor in group:
		# Replace the first point (door_pos) with junction
		# so the corridor renderer draws from junction onward
		if corridor.points[0].is_equal_approx(door_pos):
			corridor.points[0] = junction
		elif corridor.points[-1].is_equal_approx(door_pos):
			corridor.points[-1] = junction
	
	# Add a shared stub corridor from door to junction
	var stub = CorridorData.new()
	stub.from_room_id = room.id
	stub.to_room_id = room.id  # stub, doesn't go anywhere
	var points: Array[Vector2] = [door_pos, junction]
	stub.points = points
	stub.width = corridors[0].width
	corridors.append(stub)