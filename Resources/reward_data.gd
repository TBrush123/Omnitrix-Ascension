class_name RewardData 
extends Resource

@export var reward_name: String
@export var reward_type: RewardType  # STAT / ALIEN / SKILL / ITEM
@export var description: String
@export var flavor_text: String = ""
@export var icon: Texture2D
@export var stats: Dictionary[String, float]   
@export var alien_resource: AlienData  # null if not an alien reward

enum RewardType {
    STAT,
    ALIEN,
    SKILL,
    ITEM,
} 