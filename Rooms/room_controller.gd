class_name RoomController
extends Node

# ─────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────
signal room_cleared          # doors open, reward triggers
signal room_entered          # enemies spawned, doors locked

# ─────────────────────────────────────────
#  Exports — set these per-room in the editor
# ─────────────────────────────────────────
@export var enemy_table: Array[PackedScene] = []   # which enemies can spawn here
@export var min_enemies: int = 2
@export var max_enemies: int = 4
@export var difficulty: int = 1                    # passed in by RunManager

# ─────────────────────────────────────────
#  Node references
# ─────────────────────────────────────────
@onready var spawn_points: Node2D     = $SpawnPoints
@onready var doors: Node2D            = $Doors
@onready var enemy_container: Node2D  = $EnemyContainer

# ─────────────────────────────────────────
#  Internal state
# ─────────────────────────────────────────
var _enemies_alive: int = 0
var _room_active: bool  = false
var _room_cleared: bool = false   # prevent double-clear if two enemies die same frame

# ─────────────────────────────────────────
#  Entry point — called by RunManager when
#  the player physically enters this room
# ─────────────────────────────────────────
func activate(active_doors: Array[String]) -> void:
	if _room_cleared:
		return  # already beaten this room (player backtracked)

	_setup_doors(active_doors)
	_spawn_enemies()
	_lock_doors()
	_room_active = true
	emit_signal("room_entered")


# ─────────────────────────────────────────
#  Door setup
#  active_doors is an Array of directions:
#  e.g. ["North", "South"] means those two
#  doors lead somewhere; others are walled.
# ─────────────────────────────────────────
func _setup_doors(active_doors: Array[String]) -> void:
	for door in doors.get_children():
		# door.name is "DoorNorth", "DoorSouth", etc.
		var direction = door.name.replace("Door", "")
		if direction in active_doors:
			door.set_exists(true)
		else:
			door.set_exists(false)   # hides it / replaces with wall tile


func _lock_doors() -> void:
	for door in doors.get_children():
		if door.exists:
			door.lock()


func _unlock_doors() -> void:
	for door in doors.get_children():
		if door.exists:
			door.unlock()


# ─────────────────────────────────────────
#  Enemy spawning
# ─────────────────────────────────────────
func _spawn_enemies() -> void:
	if enemy_table.is_empty():
		# No enemies defined → room is already clear (treasure room, etc.)
		_on_room_cleared()
		return

	var points = spawn_points.get_children()
	points.shuffle()   # randomize which points get used

	var count = clampi(
		min_enemies + difficulty - 1,   # difficulty nudges the count up
		min_enemies,
		min(max_enemies, points.size())  # never spawn more than we have points for
	)

	for i in range(count):
		var enemy_scene: PackedScene = enemy_table.pick_random()
		var enemy: Node2D = enemy_scene.instantiate()

		enemy_container.add_child(enemy)
		enemy.global_position = points[i].global_position

		# Scale stats by difficulty before the enemy is ready
		_apply_difficulty(enemy)

		# Connect death signal — every enemy MUST have a `died` signal
		enemy.died.connect(_on_enemy_died)

		_enemies_alive += 1


func _apply_difficulty(enemy: Node2D) -> void:
	# Enemies expose these properties in their base class
	if enemy.has_method("scale_stats"):
		enemy.scale_stats(difficulty)


# ─────────────────────────────────────────
#  Enemy death tracking
# ─────────────────────────────────────────
func _on_enemy_died() -> void:
	_enemies_alive -= 1
	if _enemies_alive <= 0 and _room_active and not _room_cleared:
		_on_room_cleared()


func _on_room_cleared() -> void:
	_room_cleared = true
	_room_active  = false
	_unlock_doors()
	emit_signal("room_cleared")
	# RunManager listens to this signal and spawns the reward pickup