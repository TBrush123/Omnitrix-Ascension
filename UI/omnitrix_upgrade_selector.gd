class_name RewardScreen
extends Control

signal reward_chosen(card: RewardCard)

func _process(delta):
	$OmnitrixHand/Beam.modulate.a = 0.8 + sin(Time.get_ticks_msec() * 0.002) * 0.2

@onready var hand: TextureRect = $OmnitrixHand
@onready var projection_icon: TextureRect = $ProjectionIcon
@onready var cards_container: HBoxContainer = $CardsContainer
@onready var lightning: LightningCanvas = $LightningCanvas
@onready var card_label: Label = $CardTypeLabel
@onready var omnitrix_placement: Marker2D = $OmnitrixPlacement

@export var card_ui_scene: PackedScene

var _card_uis: Array[RewardCardUI] = []
var _selected_index: int = 0
var _confirmed: bool = false


func populate(cards: Array[RewardCard]) -> void:
	for child in cards_container.get_children():
		child.queue_free()
	
	_card_uis.clear()
	_confirmed = false
	_selected_index = 0

	for card in cards:
		var ui = card_ui_scene.instantiate()
		cards_container.add_child(ui)
		ui.setup(card)
		ui.card_selected.connect(_on_card_clicked)
		_card_uis.append(ui)
	
	if _card_uis.size() > 0:
		_update_selection(0)

func _input(event: InputEvent) -> void:
	if _confirmed:
		return

	if event.is_action_pressed("ui_accept"):
		_confirm_selection()

func _on_card_clicked(card: RewardCard) -> void:
	var idx = _get_card_index(card)
	if idx == -1:
		return
	
	if idx != _selected_index:
		_update_selection(idx)
	
	else:
		_confirm_selection()

func _get_card_index(card: RewardCard) -> int:
	for i in range(_card_uis.size()):
		if _card_uis[i].get_card() == card:
			return i
	
	return -1

func _update_selection(index: int) -> void:
	if _selected_index < _card_uis.size():
		_card_uis[_selected_index].set_selected(false)
	_selected_index = index
	_card_uis[_selected_index].set_selected(true)
	_update_projection(_card_uis[index].get_card())

func _update_projection(card: RewardCard) -> void:
	projection_icon.texture = card.icon

	var type_colors = {
		RewardCard.CardType.ALIEN_UNLOCK:  Color(0.5, 1.0, 0.6),
		RewardCard.CardType.STAT_UPGRADE:  Color(0.5, 0.7, 1.0),
		RewardCard.CardType.SKILL_UPGRADE: Color(1.0, 0.5, 0.5),
		RewardCard.CardType.ITEM:          Color(1.0, 0.85, 0.4),
	}

	var tween = create_tween().set_parallel(true)
	tween.tween_property(projection_icon, "modulate", 
	Color(type_colors[card.card_type].r,
		type_colors[card.card_type].g,
		type_colors[card.card_type].b, 0.9), 0.15)
	
	tween.tween_property(projection_icon, "scale", Vector2(1.0, 1.0), 0.1).from(Vector2(0.8, 0.8))
	tween.tween_property(projection_icon, "position:y", hand.position.y - 600, 0.18) \
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _confirm_selection() -> void:
	_confirmed = true
	var chosen_ui = _card_uis[_selected_index]
	var chosen_card = chosen_ui.get_card()

	chosen_ui.play_confirm_flash()

	var card_pos = chosen_ui.global_position + chosen_ui.size / 2.0
	var omnitrix_pos = omnitrix_placement.global_position
	
	var rarity_colors = {
		RewardCard.Rarity.COMMON:    Color(0.434, 0.434, 0.434),
		RewardCard.Rarity.UNCOMMON:    Color(0.235, 1.0, 0.178),
		RewardCard.Rarity.RARE:      Color(0.098, 0.262, 1.0),
		RewardCard.Rarity.EPIC:      Color(0.445, 0.159, 0.847),
		RewardCard.Rarity.LEGENDARY: Color(0.753, 0.539, 0.0),
		RewardCard.Rarity.X:    Color(0.0, 0.0, 0.0),
	}

	lightning.bolt_color = rarity_colors[chosen_card.rarity]
	lightning.shoot(card_pos, omnitrix_pos, func(): emit_signal("reward_chosen", chosen_card))

func hide_screen() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func show_screen() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS
