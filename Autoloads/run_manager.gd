extends Node


var current_floor:   int  = 1
var current_room:    int  = 0
var _taken_upgrades: Array = []

var _player:         CharacterBody2D
var _reward_screen:  RewardScreen
var _omnitrix:       OmnitrixComponent

func setup(player: CharacterBody2D, reward_screen: RewardScreen) -> void:
	print("diih")
	_player        = player
	_reward_screen = reward_screen
	_omnitrix      = player.get_node("Components/OmnitrixComponent")

func build_reward_pool() -> Array[RewardCard]:
	var pool: Array[RewardCard] = []
	var active_alien = _omnitrix.get_active()

	# Always offer at least one stat upgrade
	pool.append_array(_get_stat_upgrades(1))

	# Offer skill upgrades for current alien if available
	if active_alien:
		pool.append_array(_get_skill_upgrades(active_alien, 1))

	# Chance of new alien or item
	if randf() < 1:
		print("skibidi")
		pool.append_array(_get_alien_unlocks(1))
	else:
		pool.append_array(_get_items(1))

	pool.shuffle()
	return pool.slice(0, 3)


func _get_stat_upgrades(count: int) -> Array[RewardCard]:
	var all: Array[RewardCard] = GameData.stat_upgrade_pool.duplicate()
	all.shuffle()
	return all.slice(0, count)


func _get_skill_upgrades(alien: AlienData, count: int) -> Array[RewardCard]:
	var pool: Array[RewardCard] = []
	for skill in [alien.primary_skill, alien.secondary_skill]:
		if skill == null:
			continue
		for upgrade in skill.upgrades:
			if not _already_taken(upgrade):
				var card        = RewardCard.new()
				card.card_name  = upgrade.upgrade_name
				card.description = upgrade.description
				card.card_type  = RewardCard.CardType.SKILL_UPGRADE
				card.skill_upgrade = upgrade
				card.icon       = alien.texture
				card.rarity     = RewardCard.Rarity.RARE
				pool.append(card)
	pool.shuffle()
	return pool.slice(0, count)


func _get_alien_unlocks(count: int) -> Array[RewardCard]:
	var locked = GameData.alien_roster.filter(func(a):
		return not _omnitrix.has_alien(a)
	)
	locked.shuffle()
	var result: Array[RewardCard] = []
	for alien in locked.slice(0, count):
		var card        = RewardCard.new()
		card.card_name  = alien.alien_name
		card.description = "Add %s to your Omnitrix." % alien.alien_name
		card.card_type  = RewardCard.CardType.ALIEN_UNLOCK
		card.alien_data = alien
		card.icon       = alien.texture
		card.rarity     = RewardCard.Rarity.EPIC
		result.append(card)
	return result

func _get_locked_aliens() -> Array[AlienData]:
	return GameData.alien_roster.filter(
		func(a): return not _omnitrix.has_alien(a)
	)

func _get_items(count: int) -> Array[RewardCard]:
	var all: Array[RewardCard] = GameData.item_pool.duplicate()
	all.shuffle()
	return all.slice(0, count)

func _already_taken(item) -> bool:
	return _taken_upgrades.has(item)

func _load_next_room() -> void:
	pass
