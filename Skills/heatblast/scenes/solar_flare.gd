class_name SolarFlare
extends Node2D

var direction:  Vector2 = Vector2.RIGHT   # unused for flare but kept for interface
var damage:     float   = 3.0

# Upgrade flags
var blast_radius_multiplier: float = 1.0
var does_pull:        bool  = false   # Backdraft upgrade
var leaves_zone:      bool  = false   # Meltdown upgrade
var ray_count:        int   = 0       # Solar Prominence (0 = no rays)
var doubles_patches:  bool  = true    # base behaviour — always true

const BASE_RADIUS:   float = 240.0
const LIFETIME:      float = 0.25    # how long the hitbox stays active


func _ready() -> void:
	var radius = BASE_RADIUS * blast_radius_multiplier
	($BlastArea/CollisionShape2D.shape as CircleShape2D).radius = radius

	if does_pull:
		_pull_enemies_inward(radius)
	else:
		_apply_knockback_to_enemies(radius)

	$BlastArea.area_entered.connect(_on_area_entered)
	$BlastArea.monitoring = true

	_animate_flash(radius)
	_double_all_patches()

	if leaves_zone:
		pass
		#_spawn_large_burn_zone(radius)
	if ray_count > 0:
		_spawn_rays()

	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)


func apply_upgrades(skill: SkillData) -> void:
	var effects = skill.get_meta("effects", [])

	if "flare_wider" in effects:
		blast_radius_multiplier = 1.4

	if "flare_pull" in effects:
		does_pull = true

	if "flare_meltdown" in effects:
		leaves_zone = true

	if "flare_prominence" in effects:
		ray_count = 8


# ─────────────────────────────────────────
#  Damage
# ─────────────────────────────────────────
var _hit_enemies: Array = []

func _on_area_entered(area: Area2D) -> void:
	print("Area entered: ", area)
	if not area.is_in_group("hitbox"):
		return
	var enemy = area.owner
	if enemy in _hit_enemies:
		return
	_hit_enemies.append(enemy)
	if enemy.has_node("HealthComponent"):
		enemy.get_node("HealthComponent").take_damage(damage)
	if enemy.has_method("apply_burn"):
		enemy.apply_burn(0.5, 4)


# ─────────────────────────────────────────
#  Base behaviour — double all burn patches
# ─────────────────────────────────────────
func _double_all_patches() -> void:
	# Find every active burn patch in the scene and extend its duration
	var patches = get_tree().get_nodes_in_group("burn_patch")
	for patch in patches:
		if patch.has_method("extend_duration"):
			patch.extend_duration(2.0)   # multiply remaining ticks by 2


# ─────────────────────────────────────────
#  Backdraft — pull enemies inward first
# ─────────────────────────────────────────
func _pull_enemies_inward(radius: float) -> void:
	var bodies = get_tree().get_nodes_in_group("enemy")
	for enemy in bodies:
		if not is_instance_valid(enemy):
			continue
		var dist = (global_position - enemy.global_position).length()
		if dist > radius * 1.5:
			continue
		var pull_dir = (global_position - enemy.global_position).normalized()
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(pull_dir, 300.0)


# ─────────────────────────────────────────
#  Meltdown — large persistent burn zone
# ─────────────────────────────────────────
#func _spawn_large_burn_zone(radius: float) -> void:
#    var patch = preload("res://Skills/heatblast/scenes/burn_patch.tscn").instantiate()
#    get_tree().current_scene.add_child(patch)
#   patch.global_position  = global_position
#   patch.radius           = radius * 0.9
#   patch.damage_per_tick  = 0.8
#   patch.ticks_remaining  = 20     # long duration


# ─────────────────────────────────────────
#  Solar Prominence — 8 outward rays
# ─────────────────────────────────────────
func _spawn_rays() -> void:
	for i in range(ray_count):
		var angle = (TAU / ray_count) * i
		var ray = preload("res://Skills/heatblast/scenes/fireball.tscn").instantiate()
		get_tree().current_scene.add_child(ray)
		ray.global_position = global_position
		ray.direction       = Vector2.RIGHT.rotated(angle)
		ray.damage          = damage * 0.6
		ray.can_bounce      = false
		ray.does_split      = false
		ray.burn_ticks      = 4


# ─────────────────────────────────────────
#  Visual flash
# ─────────────────────────────────────────
func _animate_flash(radius: float) -> void:
	$Sprite2D.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale",
		Vector2.ONE * (radius / 40.0), 0.12).from(Vector2.ZERO)
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.13)

func _apply_knockback_to_enemies(radius: float) -> void:
	var bodies = get_tree().get_nodes_in_group("enemy")
	for enemy in bodies:
		if not is_instance_valid(enemy):
			continue
		var dist = (global_position - enemy.global_position).length()
		if dist > radius:
			continue
		var pull_dir = (enemy.global_position - global_position).normalized()
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(pull_dir, 600.0)
