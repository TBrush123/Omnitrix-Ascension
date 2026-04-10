class_name FireballBarrage
extends Node2D

@export var fireball_scene: PackedScene

var direction: Vector2 = Vector2.RIGHT
var damage: float = 1.0

var fireball_count: int = 5
var spread_angle: float = 60.0
var can_bounce: bool = false
var does_split: bool = false

const SPAWN_INTERVAL: float = 0.06

func _ready() -> void:
    _spawn_fireballs()
    # Self-destruct after all fireballs are spawned
    var total_time = SPAWN_INTERVAL * fireball_count + 0.1
    get_tree().create_timer(total_time).timeout.connect(queue_free)

func apply_upgrades(skill: SkillData) -> void:
    var effects = skill.get_meta("effects", [])

    if "barrage_wide_spread" in effects:
        spread_angle = 90.0

    if "barrage_bounce" in effects:
        can_bounce = true

    if "barrage_split" in effects:
        does_split = true

    if "barrage_supernova" in effects:
        fireball_count = 10
        # Also double burn duration on each fireball — handled via damage multiplier
        damage *= 1.5


func _spawn_fireballs() -> void:
    print(global_position)
    for i in range(fireball_count):
        # Spread fireballs evenly across the arc
        var t = 0.5 if fireball_count == 1 \
            else float(i) / (fireball_count - 1)
        var angle_offset = deg_to_rad(
            lerp(-spread_angle * 0.5, spread_angle * 0.5, t)
        )

        # Stagger spawn timing so they don't all appear at once
        var delay = i * SPAWN_INTERVAL
        get_tree().create_timer(delay).timeout.connect(
            func(): _fire_single(angle_offset)
        )


func _fire_single(angle_offset: float) -> void:
    if not is_instance_valid(self):
        return
    var fb = fireball_scene.instantiate()

    # Spawn at world level from our current world position
    fb.global_position = global_position
    fb.direction       = direction.rotated(angle_offset)
    fb.damage          = damage
    fb.can_bounce      = can_bounce
    fb.does_split      = does_split
    get_tree().current_scene.add_child(fb)