class_name Player
extends CharacterBody2D

@onready var sprite:              Sprite2D              = $Sprite2D
@onready var attack_pivot:        Node2D                = $AttackPivot
@onready var health_component:    HealthComponent       = $Components/HealthComponent
@onready var omnitrix:            OmnitrixComponent     = $Components/OmnitrixComponent
@onready var stats:               PlayerStats           = $Components/PlayerStats
@onready var hurtbox:             Area2D                = $Components/HurtboxComponent
@onready var skill_executor: SkillExecutor = $Components/SkillExecutor

# ─────────────────────────────────────────
# External references
@export var omnitrix_wheel: OmnitrixWheel

# ─────────────────────────────────────────
#  Internal state
# ─────────────────────────────────────────
var _attack_cooldown_remaining: float = 0.0
var _current_attack_instance:   Node  = null

func _ready() -> void:
	omnitrix.alien_transform.connect(_on_alien_changed)
	health_component.died.connect(_on_died)
	hurtbox.area_entered.connect(_on_hurtbox_entered)
	omnitrix_wheel.connect_to(omnitrix) 
	omnitrix.connect_to(omnitrix_wheel)
	_on_alien_changed(omnitrix.get_active())

func _process(delta: float) -> void:
	_handle_attack_cooldown(delta)
	_handle_attack_input()
	_flip_sprite()


func _physics_process(_delta: float) -> void:
	_handle_movement()


# ─────────────────────────────────────────
#  Movement
# ─────────────────────────────────────────
func _handle_movement() -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * stats.get_stat("move_speed")
	move_and_slide()


# ─────────────────────────────────────────
#  Attacking
# ─────────────────────────────────────────
func _handle_attack_cooldown(delta: float) -> void:
	if _attack_cooldown_remaining > 0:
		_attack_cooldown_remaining -= delta


func _handle_attack_input() -> void:
	var dir = _get_attack_direction()
	if _attack_cooldown_remaining > 0:
		return
	if omnitrix._wheel_open:
		return
	if is_instance_valid(_current_attack_instance):
		return
	
	if Input.is_action_just_pressed("attack"):
		_perform_attack()
	if Input.is_action_just_pressed("skill_primary"):
		skill_executor.try_use(0, dir)
	if Input.is_action_just_pressed("skill_secondary"):
		skill_executor.try_use(1, dir)


func _perform_attack() -> void:
	var alien: AlienData = omnitrix.get_active()
	if alien.attack_instance == null:
		return

	# Direction: face direction, or last move direction as fallback
	var attack_dir = _get_attack_direction()

	var hitbox = alien.attack_instance.instantiate()

	# Parent to the player so it moves with them — melee stays attached
	hitbox.position   = Vector2.ZERO     # offset handled inside the hitbox scene itself
	hitbox.direction  = attack_dir
	hitbox.damage     = stats.get_stat("damage")
	add_child(hitbox)

	_current_attack_instance   = hitbox
	_attack_cooldown_remaining = stats.get_stat("attack_cooldown")

	# Orient AttackPivot so visuals face the right way
	attack_pivot.rotation = attack_dir.angle()


func _get_attack_direction() -> Vector2:
	var mouse_world = get_global_mouse_position()
	var dir = (mouse_world - global_position)

	if dir.length() < 0.5:
		return Vector2.RIGHT
	
	return dir.normalized()
	


# ─────────────────────────────────────────
#  Visuals
# ─────────────────────────────────────────
func _flip_sprite() -> void:
	var mouse_world = get_global_mouse_position()
	sprite.flip_h = mouse_world.x < global_position.x


# ─────────────────────────────────────────
#  Damage reception
# ─────────────────────────────────────────
func _on_hurtbox_entered(area: Area2D) -> void:
	#if invincibility.is_invincible:
	#	return
	if area.is_in_group("enemy_hitbox"):
		var dmg = area.get_parent().contact_damage if area.get_parent().has_method("get") else 1
		take_damage(dmg, area.global_position)


func take_damage(amount: int, source_position: Vector2 = global_position) -> void:
	#if invincibility.is_invincible:
	#	return
	health_component.take_damage(amount)
	#invincibility.activate()
	_apply_knockback(source_position)


func _apply_knockback(source_position: Vector2) -> void:
	var dir = (global_position - source_position).normalized()
	velocity = dir * 300.0  # knockback impulse; decays naturally next physics frame


# ─────────────────────────────────────────
#  Alien switching callbacks
# ─────────────────────────────────────────
func _on_alien_changed(alien: AlienData) -> void:
	sprite.texture    = alien.texture
	sprite.scale      = alien.scale_modifier
	stats.active_alien = alien   # PlayerStats factors in alien modifiers
	skill_executor.load_alien(alien)

	# Swap attack scene
	if _current_attack_instance:
		_current_attack_instance.queue_free()
	if alien.attack_instance:
		_current_attack_instance = alien.attack_instance.instantiate()
		attack_pivot.add_child(_current_attack_instance)

func _on_died() -> void:
	# Tell RunManager the player is dead
	#RunManager.on_player_died()
	#queue_free()
	pass
