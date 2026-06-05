class_name RewardCard 
extends Resource

enum CardType {
    ALIEN_UNLOCK,
    STAT_UPGRADE,
    SKILL_UPGRADE,
    ITEM
} 

enum Rarity {
    COMMON,
    UNCOMMON,
    RARE,
    EPIC,
    LEGENDARY,
    X,
}

@export var card_name: String
@export var description: String
@export var icon: Texture2D
@export var card_type: CardType
@export var rarity: Rarity = Rarity.COMMON

#Alien Unlock
@export var alien_data: AlienData = null

#Stat Upgrade
@export var stat_modifier: Array[StatModifier] = []

#Skill Upgrade
@export var target_alien: AlienData = null
@export var skill_slot: int = 0
@export var skill_upgrade: SkillUpgrade = null

#Item
@export var item_scene: PackedScene = null
@export var item_is_passive: bool = true

func apply(player: Node) -> void:
    match card_type:
        CardType.ALIEN_UNLOCK:
            player.get_node("Components/OmnitrixComponent") \
                .add_alien(alien_data)
        CardType.STAT_UPGRADE:
            player.get_node("Components/PlayerStats") \
                .add_modifier(stat_modifier)
        CardType.SKILL_UPGRADE:
            var executor = player.get_node("Components/SkillExecutor")
            executor.apply_upgrade(skill_slot, skill_upgrade)
        CardType.ITEM:
            _apply_item(player)

func _apply_item(player: Node) -> void:
    if item_scene == null:
        return
    var item = item_scene.instantiate()
    player.add_child(item)
    if item.has_method("activate"):
        item.activate(player)