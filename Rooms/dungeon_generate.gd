class_name DungeonGenerator
extends Node

func get_empty_neighbors(pos: Vector2i, grid: Dictionary) -> Array:
	var neighbors = []
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor_pos = pos + offset
		if not grid.has(neighbor_pos):
			neighbors.append(neighbor_pos)
	return neighbors

func generate(room_count: int) -> Dictionary:
	var grid = {}
	var pos = Vector2i(3, 3)
	grid[pos] = "normal"
	var prev = pos
	for i in range(room_count - 1):
		var neighbors = get_empty_neighbors(pos, grid)
		if neighbors.is_empty(): break
		pos = neighbors.pick_random()
		grid[pos] = "normal"
    # farthest cell becomes boss
	grid[pos] = "boss"
	return grid