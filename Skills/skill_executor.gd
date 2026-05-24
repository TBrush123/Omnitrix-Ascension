class_name SkillExecutor
extends Node2D

signal skill_used(slot: int, cooldown: float)

var _skills: Array[SkillData] = [null, null]
var _cooldowns: Array[float] = [0.0, 0.0]

@onready var _stats: PlayerStats = get_parent().get_node("PlayerStats")


func _process(delta: float) -> void:
	for i in range(_cooldowns.size()):
		if _cooldowns[i] > 0:
			_cooldowns[i] -= delta
		
func load_alien(alien: AlienData) -> void:
	_skills[0] = alien.primary_skill
	_skills[1] = alien.secondary_skill

func try_use(slot: int, direction: Vector2):
	var skill = _skills[slot]
	if skill == null:
		return
	if _cooldowns[slot] > 0:
		return
	
	_execute(skill, direction)
	_cooldowns[slot] = skill.cooldown
	emit_signal("skill_used", slot, skill.cooldown)

func _execute(skill: SkillData, direction: Vector2) -> void:
	if skill.skill_scene == null:
		return
	var instance = skill.skill_scene.instantiate()
	instance.direction = direction
	instance.damage = _stats.get_stat("damage")

	if instance.has_method("apply_upgrade"):
		instance.apply_upgrade(skill)

	get_parent().add_child(instance)
	

func apply_upgrade(slot: int, upgrade: SkillUpgrade) -> void:
	var skill = _skills[slot]
	if skill == null:
		return
	
	match upgrade.type:
		SkillUpgrade.UpgradeType.REPLACE_SCENE:
			skill.skill_scene = upgrade.new_scene

		SkillUpgrade.UpgradeType.STAT_MODIFIER:
			_stats.add_modifier(upgrade.modifier)
			
		SkillUpgrade.UpgradeType.ADD_EFFECT:
			if not skill.get_meta("effects", []).has(upgrade.effect_tag):
				var effects = skill.get_meta("effects", [])
				effects.append(upgrade.effect_tag)
				skill.set_meta("effects", effects)

func get_skill(slot: int) -> SkillData:
	return _skills[slot]

func get_cooldown_percent(slot: int) -> float:
	if _skills[slot] == null:
		return 0.0
	return clampf(_cooldowns[slot] / _skills[slot].cooldown, 0.0, 1.0)
	
func reset_cooldown(slot: int) -> void:
	_cooldowns[slot] = 0.0
	emit_signal("skill_used", slot, 0.0)