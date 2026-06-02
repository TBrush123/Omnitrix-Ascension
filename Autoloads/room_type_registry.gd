extends Node

@export var combat_rooms: Array[RoomData] = []
@export var puzzle_rooms: Array[RoomData] = []
@export var shop_rooms: Array[RoomData] = []
@export var elite_rooms: Array[RoomData] = []
@export var rest_rooms: Array[RoomData] = []
@export var treasure_rooms: Array[RoomData] = []
@export var boss_rooms: Array[RoomData] = []
@export var exit_rooms: Array[RoomData] = []

func get_random(type: RoomData.RoomType) -> RoomData:
	var pool = _get_pool(type)
	if pool.size() == 0:
		return null
	return _weighted_pick(pool)
	
func _get_pool(type: RoomData.RoomType) -> Array[RoomData]:
	match type:
		RoomData.RoomType.COMBAT:
			return combat_rooms
		RoomData.RoomType.PUZZLE:
			return puzzle_rooms
		RoomData.RoomType.SHOP:
			return shop_rooms
		RoomData.RoomType.ELITE:
			return elite_rooms
		RoomData.RoomType.REST:
			return rest_rooms
		RoomData.RoomType.TREASURE:
			return treasure_rooms
		RoomData.RoomType.BOSS:
			return boss_rooms
		RoomData.RoomType.EXIT:
			return exit_rooms
		_:
			return []

func _weighted_pick(pool: Array[RoomData]) -> RoomData:
	var total_weight: float = pool.reduce(func(acc, room):
		return acc + room.weight, 0
	)
	var pick: float = randf() * total_weight
	var cumulative: float = 0.0
	for room in pool:
		cumulative += room.weight
		if pick < cumulative:
			return room
	return pool[-1] # Fallback in case of rounding errors
