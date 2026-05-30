# speed_vortex.gd
class_name SpeedVortex
extends Area2D

var direction:       Vector2 = Vector2.RIGHT
var damage:          float   = 1.0
var momentum_stacks: int     = 0

const SPIN_RADIUS:    float = 70.0
const SPIN_DURATION:  float = 1.5
const TICK_INTERVAL:  float = 0.15
const PULL_FORCE:     float = 180.0
const TRAVEL_SPEED:   float = 120.0

var _elapsed:       float = 0.0
var _tick_timer:    float = 0.0
var _hit_this_tick: Array = []
var orbit_tweens:   Array = []
var _traveling:     bool  = false
var _travel_target: Vector2

func _ready() -> void:
	var collision = get_node_or_null("CollisionShape2D")
	if collision and collision.shape is CircleShape2D:
		collision.shape.radius = SPIN_RADIUS

	_traveling = momentum_stacks >= MomentumComponent.MAX_STACKS
	_travel_target = get_global_mouse_position()

	_animate_vortex()
	get_tree().create_timer(SPIN_DURATION).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_elapsed    += delta
	_tick_timer += delta

	# Travel toward mouse at max momentum
	if _traveling:
		var move_dir = (_travel_target - global_position).normalized()
		global_position += move_dir * TRAVEL_SPEED * delta

	# Pull enemies inward each frame
	_pull_nearby_enemies(delta)

	# Damage tick
	if _tick_timer >= TICK_INTERVAL:
		_tick_timer = 0.0
		_hit_this_tick.clear()
		_damage_nearby_enemies()


func _pull_nearby_enemies(delta: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var diff = global_position - enemy.global_position
		if diff.length() > SPIN_RADIUS * 1.4:
			continue
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(diff.normalized(), PULL_FORCE * delta)


func _damage_nearby_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy in _hit_this_tick:
			continue
		if global_position.distance_to(enemy.global_position) > SPIN_RADIUS:
			continue
		_hit_this_tick.append(enemy)
		if enemy.has_node("HealthComponent"):
			enemy.get_node("HealthComponent").take_damage(damage * 0.4)


func _animate_vortex() -> void:
	# Spinning ring of ghost sprites orbiting the center
	for i in range(5):
		var ghost_angle = (TAU / 5.0) * i
		var orbit       = create_tween().set_loops(999)
		orbit_tweens.append(orbit)
		orbit.tween_method(
			func(angle: float):
				if not is_instance_valid(self): return
				var pos = global_position + \
					Vector2(cos(angle), sin(angle)) * SPIN_RADIUS * 0.6
				# Draw at pos — in practice use a Sprite2D child
				pass,
			ghost_angle,
			ghost_angle + TAU,
			SPIN_DURATION * 0.5
		)

func _exit_tree() -> void:
	for tween in orbit_tweens:
		if is_instance_valid(tween):
			tween.kill()
	orbit_tweens.clear()
