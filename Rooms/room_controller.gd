class_name RoomController
extends Node

signal room_cleared

@export var enemy_scenes: Array[PackedScene]
@export var min_enemies: int = 2
@export var max_enemies: int = 4
@export var difficulty: int = 1

@onready var spawn_points: Node2D = $"../SpawnPoints"
@onready var enemy_container: Node2D = $"../EnemyContainer"
@onready var doors: Node2D = $"../Doors"



var _enemies_alive: int = 0
var _room_active: bool = false
var _room_cleared: bool = false
var _player: Node2D
var active_doors: Dictionary = {}
var room_type: int = 0
var room_node_id: int = 0
var grid_pos: Vector2i = Vector2i.ZERO

func _ready() -> void:
	var entry = get_node_or_null("../EntryArea")
	if entry:
		entry.body_entered.connect(_on_player_entered)

	# Connect each door for transition
	if doors:
		for door in doors.get_children():
			door.body_entered.connect(_on_door_body_entered.bind(door))

	# Hide doors that don't have connections
	_setup_doors()

	for door in doors.get_children():
		door.body_entered.connect(_on_door_entered)
	
func _setup_doors() -> void:
	if doors == null:
		return
	for door in doors.get_children():
		var dir = door.name.to_lower().replace("door", "")
		if active_doors.has(dir):
			door.visible = true
		else:
			door.visible = false
			door.get_node("CollisionShape2D").disabled = true
func _on_player_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if _room_active or _room_cleared:
		return
	activate(body)
	
func _on_door_body_entered(body: Node, door: Node2D) -> void:
	pass

func _on_door_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if _room_active or _room_cleared:
		return
	print("Player entered room trigger, activating room...")
	activate(body)

func activate(player: Node2D) -> void:
	if _room_cleared:
		_unlock_doors()
		return
	_player = player
	_lock_doors()
	_spawn_enemies()
	_room_active = true

func _lock_doors() -> void:
	for door in doors.get_children():
		door.get_node("CollisionShape2D").disabled = false
		door.monitoring = false

		if door.has_node("Sprite2D"):
			door.get_node("Sprite2D").modulate = Color(0.4, 0.1, 0.1)

func _unlock_doors() -> void:
	for door in doors.get_children():
		door.get_node("CollisionShape2D").disabled = true
		door.monitoring = true
		if door.has_node("Sprite2D"):
			door.get_node("Sprite2D").modulate = Color.WHITE

func _spawn_enemies() -> void:
	if enemy_scenes.is_empty():
		_on_room_cleared()
		return
	
	var points = spawn_points.get_children().duplicate()
	points.shuffle()

	var count = clampi(min_enemies + (difficulty - 1), min_enemies, min(max_enemies, points.size()))

	for i in range(count):
		var scene: PackedScene = enemy_scenes.pick_random()
		var enemy: Node2D = scene.instantiate()

		enemy.set_meta("player_ref", _player)

		enemy_container.add_child(enemy)
		enemy.global_position = points[i].global_position
		enemy.died.connect(_on_enemy_died)
		_enemies_alive += 1

		await get_tree().create_timer(0.1).timeout
	
func _on_enemy_died() -> void:
	_enemies_alive -= 1
	if _enemies_alive <= 0 and _room_active and not _room_cleared:
		_on_room_cleared()

func _on_room_cleared() -> void:
	_room_cleared = true
	_room_active = false
	_unlock_doors()
	emit_signal("room_cleared")
