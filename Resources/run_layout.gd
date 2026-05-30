class_name RunLayout
extends Resource

@export var floor_number: int = 1
@export var total_floors: int = 10
@export var rooms: Array[RoomData.RoomType] = [
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.BOSS,
]