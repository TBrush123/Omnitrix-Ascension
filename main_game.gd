extends Node2D

@onready var player: CharacterBody2D = $World/Player
@onready var reward_screen: RewardScreen = $GameUI/RewardScreen
@onready var hud: Control = $GameUI/HUD


func _ready() -> void:
	print(player)
	RunManager.setup(player, reward_screen)
	reward_screen.hide_screen()
	reward_screen.reward_chosen.connect(_on_reward_chosen)


func _on_reward_chosen(card: RewardCard) -> void:
	card.apply(player)
	reward_screen.hide_screen()
	get_tree().paused     = false
	RunManager.on_reward_taken()

func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("debug_reward"):
		_open_debug_reward_screen()


func _open_debug_reward_screen() -> void:
	var cards = RunManager.build_reward_pool()
	get_tree().paused      = true
	reward_screen.visible  = true
	reward_screen.process_mode = Node.PROCESS_MODE_INHERIT
	reward_screen.populate(cards)
