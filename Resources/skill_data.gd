class_name SkillData
extends Resource

@export var name: String
@export var description: String
@export var cooldown: float
@export var skill_scene: PackedScene
@export var icon: Texture2D
@export var upgrades: Array[SkillUpgrade] = []