extends Node

@onready var dungeon_world: DungeonWorld = $"../../World/DungeonWorld"

var current_floor:   int  = 1
var current_room: int = 0
var _current_room: RoomController = null
var _taken_upgrades: Array = []
var _dungeon: DungeonGenerator = null
var _current_room_node: RoomNode = null

var _player:         CharacterBody2D
var _reward_screen:  RewardScreen
var _omnitrix:       OmnitrixComponent



func start_run() -> void:
	current_floor = 1
	current_room = 0
	_taken_upgrades.clear()

	_generate_floor()


func load_room_from_node(room_node: RoomNode) -> void:
	var room = preload("res://Rooms/room_template.tscn").instantiate()
	var world = get_tree().current_scene.get_node_or_null("World")

	room.global_position = room_node.position
	world.add_child(room)

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("Player not found in group 'player'!")
		return
	
	var spawn_points = room.get_node_or_null("SpawnPoints")
	if spawn_points and spawn_points.get_child_count() > 0:
		player.global_position = spawn_points.get_child(0).global_position
	else:
		player.global_position = room.global_position
	
	_current_room = room.get_node_or_null("RoomController")
	if _current_room == null:
		push_error("RoomController not found in room!")
		return
	
	_current_room.active_doors = _get_door_flags(room_node)
	_current_room.difficulty = current_floor
	_current_room.room_cleared.connect(_on_room_cleared, CONNECT_ONE_SHOT)
	_current_room.activate(player)

func _get_door_flags(room_node: RoomNode) -> Dictionary:
	var flags: Dictionary = {}
	for conn in room_node.connections:
		match conn.door:
			RoomNode.Door.NORTH: flags["north"] = true
			RoomNode.Door.SOUTH: flags["south"] = true
			RoomNode.Door.EAST:  flags["east"]  = true
			RoomNode.Door.WEST:  flags["west"]  = true
	return flags

func setup(player: CharacterBody2D, reward_screen: RewardScreen) -> void:
	_player        = player
	_reward_screen = reward_screen
	_omnitrix      = player.get_node("Components/OmnitrixComponent")

func build_reward_pool() -> Array[RewardCard]:
	var pool: Array[RewardCard] = []
	var active_alien = _omnitrix.get_active()

	# Always offer at least one stat upgrade
	pool.append_array(_get_stat_upgrades(1))

	# Offer skill upgrades for current alien if available
	if active_alien:
		pool.append_array(_get_skill_upgrades(active_alien, 1))

	# Chance of new alien or item
	if randf() < 1:
		print("skibidi")
		pool.append_array(_get_alien_unlocks(1))
	else:
		pool.append_array(_get_items(1))

	pool.shuffle()
	return pool.slice(0, 3)


func _get_stat_upgrades(count: int) -> Array[RewardCard]:
	var all: Array[RewardCard] = GameData.stat_upgrade_pool.duplicate()
	all.shuffle()
	return all.slice(0, count)


func _get_skill_upgrades(alien: AlienData, count: int) -> Array[RewardCard]:
	var pool: Array[RewardCard] = []
	for skill in [alien.primary_skill, alien.secondary_skill]:
		if skill == null:
			continue
		for upgrade in skill.upgrades:
			if not _already_taken(upgrade):
				var card        = RewardCard.new()
				card.card_name  = upgrade.upgrade_name
				card.description = upgrade.description
				card.card_type  = RewardCard.CardType.SKILL_UPGRADE
				card.skill_upgrade = upgrade
				card.icon       = alien.texture
				card.rarity     = RewardCard.Rarity.RARE
				pool.append(card)
	pool.shuffle()
	return pool.slice(0, count)


func _get_alien_unlocks(count: int) -> Array[RewardCard]:
	var locked = GameData.alien_roster.filter(func(a):
		return not _omnitrix.has_alien(a)
	)
	locked.shuffle()
	var result: Array[RewardCard] = []
	for alien in locked.slice(0, count):
		var card        = RewardCard.new()
		card.card_name  = alien.alien_name
		card.description = "Add %s to your Omnitrix." % alien.alien_name
		card.card_type  = RewardCard.CardType.ALIEN_UNLOCK
		card.alien_data = alien
		card.icon       = alien.texture
		card.rarity     = RewardCard.Rarity.EPIC
		result.append(card)
	return result

func _get_locked_aliens() -> Array[AlienData]:
	return GameData.alien_roster.filter(
		func(a): return not _omnitrix.has_alien(a)
	)

func _get_items(count: int) -> Array[RewardCard]:
	var all: Array[RewardCard] = GameData.item_pool.duplicate()
	all.shuffle()
	return all.slice(0, count)

func _already_taken(item) -> bool:
	return _taken_upgrades.has(item)

func _load_next_room() -> void:
	pass

func load_room(room_scene: PackedScene) -> void:
	var world = get_tree().current_scene.get_node_or_null("World")
	if world == null:
		push_error("World node not found!")
		return

	var old_room = world.get_node_or_null("CurrentRoom")
	if old_room:
		old_room.queue_free()
		await get_tree().process_frame

	var room = room_scene.instantiate()
	room.name = "CurrentRoom"
	world.add_child(room)

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("Player not found in group 'player'!")
		return

	# Move player to room spawn
	var spawn_points = room.get_node_or_null("SpawnPoints")
	if spawn_points == null or spawn_points.get_child_count() == 0:
		push_error("No SpawnPoints found in room!")
		return

	player.global_position = spawn_points.get_child(0).global_position

	# Wire room controller
	_current_room = room.get_node_or_null("RoomController")
	if _current_room == null:
		push_error("RoomController not found in room!")
		return

	_current_room.difficulty   = current_floor
	_current_room.room_cleared.connect(_on_room_cleared, CONNECT_ONE_SHOT)
	_current_room.activate(player)


func _go_to_next_room() -> void:
	var candidates: Array[RoomNode] = []
	for conn in _current_room_node.connections:
		var neighbor = _dungeon.rooms[conn.to_room_id]
		if not neighbor.cleared:
			candidates.append(neighbor)

	if candidates.is_empty():
		_on_floor_complete()
		return
	
	var exit_rooms = candidates.filter(func(r):
		return r.data != null \
			and r.data.room_type == RoomNode.RoomType.EXIT)

	_current_room_node = exit_rooms[0] \
		if not exit_rooms.is_empty() \
		else candidates.pick_random()

	load_room_from_node(_current_room_node)

func _generate_floor() -> void:
	_dungeon = DungeonGenerator.new()

	var registry = get_tree().current_scene.get_node_or_null("Managers/RoomRegistry")
	_print_tree(get_tree().current_scene, 0)
	if registry == null:
		push_error("RoomTypeRegistry node not found in scene!")
		return

	_dungeon.generate(registry)
	_print_tree(get_tree().current_scene, 0)

	var dungeon_world = get_tree().current_scene.get_node_or_null("World/DungeonWorld")
	if dungeon_world == null:
		push_error("DungeonWorld not found! Check path: World/DungeonWorld")
		return
	# Clear old tilemap
	dungeon_world.tilemap.clear()

	# Stamp rooms and open doors
	dungeon_world.initialize(_dungeon)

	await get_tree().process_frame

	for grid_pos in _dungeon.rooms.keys():
		var cell = _dungeon.rooms[grid_pos]
		if cell.instance == null:
			continue

		var controller = cell.instance.get_node_or_null("RoomController")
		if controller == null:
			continue

		controller.active_doors = cell.doors
		controller.room_type    = cell.type
		controller.difficulty   = current_floor
		controller.grid_pos     = cell.grid_pos
		controller.room_cleared.connect(
			func(): _on_room_cleared(cell.grid_pos),
			CONNECT_ONE_SHOT
		)

	# Move player to start room center
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("Player not found!")
		return

	var start_cell = _dungeon.rooms[_dungeon.start_pos]
	player.global_position = start_cell.world_pos \
		+ Vector2(DungeonGenerator.ROOM_SIZE) / 2.0

func _print_tree(node: Node, depth: int) -> void:
	print("  ".repeat(depth) + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_tree(child, depth + 1)
		
func _spawn_room(cell: DungeonGenerator.RoomCell, world: Node) -> void:
	var instance      = cell.data.scene.instantiate()
	instance.name     = "Room_%d_%d" % [cell.grid_pos.x, cell.grid_pos.y]
	instance.position = cell.world_pos
	world.add_child(instance)

	var controller = instance.get_node_or_null("RoomController")
	if controller == null:
		return

	controller.active_doors  = cell.doors
	controller.room_type     = cell.type
	controller.difficulty    = current_floor
	controller.grid_pos      = cell.grid_pos
	controller.room_cleared.connect(
		func(): _on_room_cleared(cell.grid_pos),
		CONNECT_ONE_SHOT
	)


func _spawn_corridors(world: Node) -> void:
	# Draw corridors as TileMap or StaticBody paths
	# For now just spawn a simple walkable connector
	for corridor in _dungeon.corridors:
		_spawn_corridor(corridor, world)


func _spawn_corridor(corridor: CorridorData, world: Node) -> void:
	# Each corridor is a series of line segments
	# We spawn a walkable path along those points
	for i in range(corridor.points.size() - 1):
		var from = corridor.points[i]
		var to   = corridor.points[i + 1]
		_spawn_corridor_segment(from, to, world)


func _spawn_corridor_segment(from: Vector2, to: Vector2, world: Node) -> void:
	var segment        = StaticBody2D.new()
	var shape_node     = CollisionShape2D.new()
	var shape          = RectangleShape2D.new()

	var diff           = to - from
	var length         = diff.length()
	var is_horizontal  = abs(diff.x) > abs(diff.y)

	shape.size         = Vector2(length, 96) if is_horizontal \
						else Vector2(96, length)
	shape_node.shape   = shape
	segment.add_child(shape_node)

	segment.global_position = (from + to) / 2.0
	segment.rotation        = diff.angle() if is_horizontal else 0.0
	world.add_child(segment)


func _on_room_cleared(room_id: Vector2i) -> void:
	# Mark this room as cleared in the dungeon data
	_dungeon.rooms[room_id].cleared = true

	# Check if all non-exit rooms are cleared
	var all_cleared := true
	for r in _dungeon.rooms.values():
		var is_exit = r.data and r.data.room_type == RoomData.RoomType.EXIT
		if not (r.cleared or is_exit):
			all_cleared = false
			break

	if all_cleared:
		_on_floor_complete()
		return

	await get_tree().create_timer(0.8).timeout
	var cards = build_reward_pool()
	if cards.is_empty():
		return
	_reward_screen.populate(cards)
	_reward_screen.show_screen()


func on_reward_taken() -> void:
	_reward_screen.hide_screen()
	_omnitrix.reset()
	current_room += 1


func _on_floor_complete() -> void:
	current_floor += 1
	_generate_floor()
