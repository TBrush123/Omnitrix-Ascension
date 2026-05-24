class_name InvincibilityComponent
extends Node

signal invincibility_started
signal invincibility_ended

@export var iframe_duration: float = 0.8

var is_invincible: bool = false

var _timer:        float = 0.0
var _blink_tween:  Tween = null
var _sprite:       Sprite2D = null


func _ready() -> void:
    # Grab the sprite from the parent automatically
    # so the component is self-contained
    if get_parent().has_node("Sprite2D"):
        _sprite = get_parent().get_node("Sprite2D")


func _process(delta: float) -> void:
    if not is_invincible:
        return
    _timer -= delta
    if _timer <= 0.0:
        _end()


# ─────────────────────────────────────────
#  Public API
# ─────────────────────────────────────────

func activate(duration: float = -1.0) -> void:
    # duration = -1 means use the exported default
    if is_invincible:
        # Extend rather than restart if already active
        _timer = max(_timer, _get_duration(duration))
        return

    is_invincible = true
    _timer        = _get_duration(duration)
    emit_signal("invincibility_started")
    _start_blink()


func deactivate() -> void:
    # Force-end iframes early — useful for skills that
    # explicitly end their own invincibility
    if not is_invincible:
        return
    _end()


func get_remaining() -> float:
    return max(_timer, 0.0)


func get_percent() -> float:
    return clampf(_timer / iframe_duration, 0.0, 1.0)


# ─────────────────────────────────────────
#  Internal
# ─────────────────────────────────────────

func _get_duration(override: float) -> float:
    return iframe_duration if override < 0.0 else override


func _end() -> void:
    is_invincible = false
    _timer        = 0.0
    _stop_blink()
    emit_signal("invincibility_ended")


func _start_blink() -> void:
    if _sprite == null:
        return
    if _blink_tween:
        _blink_tween.kill()

    # Blink faster as iframes run out
    _blink_tween = create_tween().set_loops(999)
    _blink_tween.tween_method(_set_sprite_alpha, 1.0, 0.15, 0.07)
    _blink_tween.tween_method(_set_sprite_alpha, 0.15, 1.0, 0.07)


func _stop_blink() -> void:
    if _blink_tween:
        _blink_tween.kill()
        _blink_tween = null
    if _sprite:
        _sprite.modulate.a = 1.0


func _set_sprite_alpha(value: float) -> void:
    if _sprite and is_instance_valid(_sprite):
        _sprite.modulate.a = value