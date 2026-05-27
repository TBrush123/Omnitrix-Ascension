# tornado_dash.gd
class_name TornadoDash
extends Node2D

var direction:        Vector2 = Vector2.RIGHT
var damage:           float   = 1.0
var momentum_stacks:  int     = 0

const DASH_DAMAGE_RADIUS: float = 28.0
const LAP_DURATION:       float = 0.3
const DASH_DURATION:       float = 0.2
const DASH_DISTANCE:       float = 200.0


func _ready() -> void:
	var player = get_parent().get_parent() as Player
	if not player:
		push_error("TornadoDash: Could not find Player in parent hierarchy")
		queue_free()
		return

	if momentum_stacks >= MomentumComponent.MAX_STACKS:
		print("Performing room lap!")
		print("Current stacks: %d" % momentum_stacks)
		_perform_room_lap(player)
	else:
		print("Current stacks: %d" % momentum_stacks)
		print("Performing straight dash!")
		_perform_dash(player)


# ── Low momentum: straight dash ──
func _perform_dash(player: Node) -> void:
	var invincibility = player.get_node_or_null("Components/InvincibilityComponent")
	if invincibility:
		invincibility.activate(DASH_DURATION)

	var target = player.global_position + direction * DASH_DISTANCE
	var tween  = create_tween()
	tween.tween_property(player, "global_position",
		target, DASH_DURATION) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)

	_hit_enemies_along_path(player.global_position, target)
	_spawn_dash_trail(player)


# ── Max momentum: full room lap ──
func _perform_room_lap(player: Node) -> void:
	var invincibility = player.get_node_or_null("Components/InvincibilityComponent")
	if invincibility:
		invincibility.activate(LAP_DURATION)

	# Build a circular path around the room center
	# We approximate this with 8 points around the player
	var center     = player.global_position
	var lap_radius = 160.0
	var points: Array[Vector2] = []

	for i in range(16):   # 16 steps + return to start
		var angle = (TAU / 16.0) * i
		points.append(center + Vector2(cos(angle), sin(angle)) * lap_radius)

	var tween = create_tween()
	for pt in points:
		tween.tween_property(player, "global_position",
			pt, LAP_DURATION / 8.0) \
			.set_trans(Tween.TRANS_LINEAR)
		# Hit enemies near each waypoint
		tween.tween_callback(func():
			_hit_enemies_at_position(player.global_position)
			_spawn_single_ghost(player)
		)

	tween.tween_property(player, "global_position",
		center, 0.08)   # snap back to start
	tween.tween_callback(queue_free)


func _hit_enemies_along_path(from: Vector2, to: Vector2) -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		# Check if enemy is close to the dash line
		var closest = Geometry2D.get_closest_point_to_segment(
			enemy.global_position, from, to
		)
		
		if enemy.global_position.distance_to(closest) < DASH_DAMAGE_RADIUS:
			#_damage_enemy(enemy)
			pass


func _hit_enemies_at_position(pos: Vector2) -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if pos.distance_to(enemy.global_position) < DASH_DAMAGE_RADIUS:
			#_damage_enemy(enemy)
			if enemy.has_node("HealthComponent"):
				enemy.get_node("HealthComponent").take_damage(damage)
			if enemy.has_method("apply_knockback"):
				var dir = (enemy.global_position - get_parent().global_position).normalized()
				enemy.apply_knockback(dir * 200.0)

func _spawn_dash_trail(player: Node) -> void:
	for i in range(3):
		get_tree().create_timer(i * 0.05).timeout.connect(
			func(): _spawn_single_ghost(player)
		)

func _spawn_single_ghost(player: Node) -> void:
	if not is_instance_valid(player):
		return
	var sprite = player.get_node_or_null("Sprite2D")
	if not sprite:
		return

	var ghost             = Sprite2D.new()
	ghost.texture         = sprite.texture
	ghost.scale           = sprite.scale
	ghost.flip_h          = sprite.flip_h
	ghost.modulate        = Color(0.3, 0.8, 1.0, 0.6)
	ghost.global_position = player.global_position
	get_tree().current_scene.add_child(ghost)

	var tween = ghost.create_tween().set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_property(ghost, "scale", ghost.scale * 0.7, 0.25)
	tween.chain().tween_callback(ghost.queue_free)
