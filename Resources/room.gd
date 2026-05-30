class_name RoomData
extends Resource

@export var room_id: String = ""
@export var room_scene: PackedScene
@export var room_type: RoomType = RoomType.COMBAT
@export var weight: float = 1.0

enum RoomType {
	COMBAT,
	PUZZLE,
	SHOP,
	ELITE,
	REST,
	TREASURE,
	BOSS
}