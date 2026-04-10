class_name SkillUpgrade
extends Resource

enum UpgradeType {
    REPLACE_SCENE,
    STAT_MODIFIER,
    ADD_EFFECT,
    OTHER
}

@export var name: String
@export var description: String
@export var type: UpgradeType
@export var new_scene: PackedScene
@export var modifier: StatModifier
@export var effect_tag: String
