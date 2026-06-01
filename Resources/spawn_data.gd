extends Resource
class_name SpawnData

@export var enemy_pool: Array[PackedScene] = []
@export var min_enemies: int = 3
@export var max_enemies: int = 6
@export var spawn_points: Array[NodePath] = []