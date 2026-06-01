class_name RoomData
extends Resource

@export var room_id: int
@export var room_scene: PackedScene
@export var room_type: RoomType = RoomType.COMBAT
@export var weight: float = 1.0

enum RoomType {
	EMPTY,
	COMBAT,
	PUZZLE,
	SHOP,
	ELITE,
	REST,
	TREASURE,
	BOSS,
	EXIT
}
