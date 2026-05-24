class_name CalculateEvade
extends Node2D

var direction: Vector2 = Vector2.RIGHT
var damage: float = 1.0

const DASH_SPEED: float = 520.0
const DASH_DURATION: float = 0.14
const DODGE_WINDOW: float = 2.0

signal dodge_triggered

func _ready() -> void:
    var player = get_parent().get_parent()
    _perform_dash(player)

func _perform_dash(player: Node) -> void:
    player.get_node("Components/InvincibilityComponent").activate(DASH_DURATION)

    var start_pos  = player.global_position
    var target_pos = start_pos + direction * DASH_SPEED * DASH_DURATION

    # Check for walls — don't dash through solid geometry
    var space  = player.get_world_2d().direct_space_state
    var query  = PhysicsRayQueryParameters2D.create(
        start_pos, target_pos, player.collision_mask
    )
    query.exclude = [player.get_rid()]
    var result    = space.intersect_ray(query)
    if result:
        # Stop just before the wall
        target_pos = result.position - direction * 8.0

    # Move the player directly via tween on global_position
    var tween = create_tween()
    tween.tween_property(player, "global_position",
        target_pos, DASH_DURATION) \
        .set_trans(Tween.TRANS_QUAD) \
        .set_ease(Tween.EASE_OUT)

    _spawn_trail(player)

    tween.tween_callback(func(): _open_dodge_window(player))
    tween.tween_callback(queue_free)

func _open_dodge_window(player: Node) -> void:
    var invincibility = player.get_node("Components/InvincibilityComponent")
    var hurtbox       = player.get_node("Components/HurtboxComponent")

    # Switch hurtbox into dodge-detection mode
    # Instead of dealing damage, any hit during this window
    # triggers the dodge payoff
    player.set_meta("dodge_window_active", true)

    # Visual: subtle green shimmer on the player
    var shimmer = create_tween().set_loops(999)
    shimmer.tween_property(player.get_node("Sprite2D"), "modulate",
        Color(0.6, 1.0, 0.7, 1.0), 0.2)
    shimmer.tween_property(player.get_node("Sprite2D"), "modulate",
        Color.WHITE, 0.2)

    # Window timer
    var timer = get_tree().create_timer(DODGE_WINDOW)
    timer.timeout.connect(func():
        player.set_meta("dodge_window_active", false)
        shimmer.kill()
        player.get_node("Sprite2D").modulate = Color.WHITE
    )


func _spawn_trail(player: Node) -> void:
    # Spawn 4 ghost copies of the player sprite that fade out
    for i in range(4):
        var ghost_delay = i * (DASH_DURATION / 4.0)
        get_tree().create_timer(ghost_delay).timeout.connect(
            func(): _spawn_single_ghost(player)
        )


func _spawn_single_ghost(player: Node) -> void:
    if not is_instance_valid(player):
        return
    var ghost      = Sprite2D.new()
    ghost.texture  = player.get_node("Sprite2D").texture
    ghost.scale    = player.get_node("Sprite2D").scale
    ghost.flip_h   = player.get_node("Sprite2D").flip_h
    ghost.modulate = Color(0.4, 1.0, 0.55, 0.55)
    get_tree().current_scene.add_child(ghost)
    ghost.global_position = player.global_position

    var tween = ghost.create_tween().set_parallel(true)
    tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
    tween.tween_property(ghost, "scale", ghost.scale * 0.8, 0.3)
    tween.chain().tween_callback(ghost.queue_free)
