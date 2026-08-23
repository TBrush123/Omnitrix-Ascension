class_name RewardCardUI
extends Control

signal card_selected(card: RewardCard)

@export_group("Card Settings")
@export var rarity_colors: Dictionary[RewardCard.Rarity, Color] 
@export var type_labels: Dictionary[RewardCard.CardType, String]
@export var rarity_names: Dictionary[RewardCard.Rarity, String]

@onready var card_base: NinePatchRect = $CardBase
@onready var rarity_label: Label = $MarginContainer2/MarginContainer/RarityLabel
@onready var hex_frame: TextureRect = $MarginContainer/HexFrame
@onready var icon_rect: TextureRect = $MarginContainer/HexFrame/IconRect
@onready var card_name: Label = $NameContainer/MarginContainer/Label
@onready var description: Label = $MarginContainer3/Label
@onready var selection_glow: ColorRect = $SelectionGlow


var _card: RewardCard = null
var _is_selected: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	selection_glow.visible = false

	mouse_entered.connect(func(): if not _is_selected: _hover(true))
	mouse_exited.connect(func(): if not _is_selected: _hover(false))
	gui_input.connect(_on_gui_input)

func setup(card: RewardCard) -> void:
	_card = card
	icon_rect.texture = card.icon
	card_name.text = card.card_name
	description.text = card.description
	rarity_label.text = rarity_names[card.rarity]

	card_base.modulate = rarity_colors[card.rarity]

func set_selected(value: bool) -> void:
	_is_selected = value
	selection_glow.visible = value

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08) if value else Vector2(1.0, 1.0), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
func _hover(hovered: bool) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale",
		Vector2(1.05, 1.05) if hovered else Vector2(1.0, 1.0), 0.08)
	tween.tween_property(self, "modulate",
		Color(1.15, 1.15, 1.15) if hovered else Color.WHITE, 0.08)


func play_confirm_flash() -> void:
	var tween = create_tween().set_loops(3)
	tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0), 0.06)
	tween.tween_property(self, "modulate", Color.WHITE, 0.06)

func get_card() -> RewardCard:
	return _card

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		emit_signal("card_selected", _card)
