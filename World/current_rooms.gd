extends Node2D

func _ready() -> void:
	var gen: DungeonGenerator = DungeonGenerator.new()
	gen.generate()
	
	var world = preload("res://World/dungeon_world.tscn").instantiate()
	add_child(world)

	world.initialize(gen)

	var start_pos = gen.rooms[0].position
	get_parent().get_node("Player").global_position = start_pos
