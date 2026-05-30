class_name Player
extends CharacterBody2D

@export var human_sprite: Texture2D

@onready var sprite:              Sprite2D              = $Sprite2D
@onready var attack_pivot:        Node2D                = $AttackPivot
@onready var health_component:    HealthComponent       = $Components/HealthComponent
@onready var omnitrix:            OmnitrixComponent     = $Components/OmnitrixComponent
@onready var stats:               PlayerStats           = $Components/PlayerStats
@onready var hurtbox:             Area2D                = $Components/HurtboxComponent
@onready var invincibility: 	  InvincibilityComponent = $Components/InvincibilityComponent
@onready var skill_executor: 	  SkillExecutor = $Components/SkillExecutor
@onready var alien_charge:        AlienChargeComponent = $Components/AlienChargeComponent
@onready var momentum: 		MomentumComponent = $Components/MomentumComponent

# ─────────────────────────────────────────
# External references
@export var omnitrix_wheel: OmnitrixWheel
@export var charge_hud: AlienChargeHUD

# ─────────────────────────────────────────
#  Internal state
# ─────────────────────────────────────────
var _attack_cooldown_remaining: float = 0.0
var _current_attack_instance:   Node  = null
var _transform_tween: Tween = null

func _ready() -> void:
	omnitrix.alien_transform.connect(_on_alien_changed)
	health_component.died.connect(_on_died)
	hurtbox.area_entered.connect(_on_hurtbox_entered)
	omnitrix_wheel.connect_to(omnitrix) 
	omnitrix.connect_to(omnitrix_wheel)
	alien_charge.charge_depleted.connect(_on_charge_depleted)
	alien_charge.charge_recharged.connect(_on_charge_recharged)
	charge_hud.connect_to(alien_charge)
	momentum.reached_max_stacks.connect(_on_max_momentum)
	momentum.left_max_stacks.connect(_on_lost_max_momentum)


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

	if hitbox.get("_momentum_stacks") != null:
		hitbox._momentum_stacks = momentum.current_stacks
		
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


func take_damage(amount: int, source_position: Vector2 = global_position, attacker: Node = null) -> void:
	#if invincibility.is_invincible:
	#	retur
	if get_meta("dodge_window_active", false):
		_trigger_dodge_payoff(attacker)
		return
	health_component.take_damage(amount)
	invincibility.activate()
	_apply_knockback(source_position)

func _trigger_dodge_payoff(attacker: Node) -> void:
	# Clear the window so it can only trigger once
	set_meta("dodge_window_active", false)

	# Reset Sabotage (skill slot 0) cooldown
	skill_executor.reset_cooldown(0)

	# Confuse the attacker
	if attacker != null and attacker.has_method("apply_confusion"):
		attacker.apply_confusion(3.0)

	# Satisfying feedback — brief freeze frame + flash
	_dodge_success_effect()


func _dodge_success_effect() -> void:
	# Freeze frame: slow time very briefly
	Engine.time_scale = 0.05
	get_tree().create_timer(0.08, true, false, true).timeout.connect(
		func(): Engine.time_scale = 1.0
	)

	# White flash on player
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate",
		Color(2.0, 2.0, 2.0, 1.0), 0.04)
	tween.tween_property($Sprite2D, "modulate",
		Color.WHITE, 0.12)

	_spawn_floating_text("DODGE!")


func _spawn_floating_text(text: String) -> void:
	var label       = Label.new()
	label.text      = text
	label.modulate  = Color(0.3, 1.0, 0.4)
	get_tree().current_scene.add_child(label)
	label.global_position = global_position + Vector2(-20, -40)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y",
		label.position.y - 30, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6) \
		.set_delay(0.2)
	tween.tween_callback(label.queue_free).set_delay(0.6)

func _apply_knockback(source_position: Vector2) -> void:
	var dir = (global_position - source_position).normalized()
	velocity = dir * 300.0  # knockback impulse; decays naturally next physics frame


# ─────────────────────────────────────────
#  Alien switching callbacks
# ─────────────────────────────────────────
func _on_alien_changed(alien: AlienData) -> void:
	if alien == null:
		sprite.texture = human_sprite
		sprite.scale = Vector2.ONE
		stats.active_alien = null
		alien_charge.set_transformed(false)
		_play_detransform_effect()
		return
	stats.active_alien = alien   # PlayerStats factors in alien modifiers
	skill_executor.load_alien(alien)
	_play_transform_effect(alien)   # ← replaces the old sprite swap
	alien_charge.set_transformed(true)


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

func _play_transform_effect(alien: AlienData) -> void:

	if _transform_tween:
		_transform_tween.kill()
	
	_transform_tween = create_tween().set_parallel(false)

	_transform_tween.tween_property(sprite, "modulate", Color(0.3, 1.0, 0.4, 1.0), 0.07)
	_transform_tween.tween_property(sprite, "scale", alien.scale_modifier * 1.35, 0.07)

	_transform_tween.tween_callback(func():
		if alien.sprite_texture:
			sprite.texture = alien.sprite_texture
		else:
			sprite.texture = alien.texture
		sprite.scale = alien.scale_modifier * 1.35
		_spawn_transform_ring()
	)

	_transform_tween.tween_property(sprite, "scale", alien.scale_modifier, 0.10)
	_transform_tween.tween_property(sprite, "modulate", Color.WHITE, 0.08)

	
func _spawn_transform_ring() -> void:
	var ring = Sprite2D.new()
	ring.texture  = sprite.texture
	ring.modulate = Color(0.3, 1.0, 0.4, 0.6)
	ring.scale    = sprite.scale
	add_child(ring)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(ring, "scale",    sprite.scale * 2.5, 0.25)
	tween.tween_property(ring, "modulate", Color(0.3, 1.0, 0.4, 0.0), 0.25)
	tween.tween_callback(ring.queue_free).set_delay(0.25)

func _on_charge_depleted() -> void:
	alien_charge.set_transformed(false)
	omnitrix.force_detransform()
	_play_detransform_effect()

func _on_charge_recharged() -> void:
	pass
	#TODO

func _on_max_momentum() -> void:
	pass
	#TODO

func _on_lost_max_momentum() -> void:
	pass
	#TODO

func _play_detransform_effect() -> void:
	pass
	#TODO
