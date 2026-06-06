class_name RewardCardUI
extends PanelContainer

signal card_selected(card: RewardCard)

@export_group("Card Settings")
@export var rarity_colors: Dictionary[RewardCard.Rarity, Color] 
@export var type_labels: Dictionary[RewardCard.CardType, String]

@onready var rarity_bar: ColorRect = $MarginContainer/VBoxContainer/RarityBar
@onready var type_badge: Label = $MarginContainer/VBoxContainer/TypeBadge
@onready var icon_rect: TextureRect = $MarginContainer/VBoxContainer/ItemContainer/IconRect
@onready var card_name: Label = $MarginContainer/VBoxContainer/CardName
@onready var description: Label = $MarginContainer/VBoxContainer/Description

var _card: RewardCard = null
var _is_selected: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(140, 190)
	pivot_offset = custom_minimum_size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	mouse_entered.connect(func(): if not _is_selected: _hover(true))
	mouse_exited.connect(func(): if not _is_selected: _hover(false))
	gui_input.connect(_on_gui_input)

func setup(card: RewardCard) -> void:
	_card = card
	icon_rect.texture = card.icon
	card_name.text = card.card_name
	description.text = card.description
	rarity_bar.color = rarity_colors[card.rarity]
	type_badge.text = type_labels[card.card_type]
	_apply_rarity_style(card.rarity)

func set_selected(value: bool) -> void:
	_is_selected = value
	if value:
		_select_anim()
	else:
		_deselect_anim()
	
func _apply_rarity_style(rarity: RewardCard.Rarity) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.bg_color = Color(0.06, 0.08, 0.06, 0.92)
	style.border_color = rarity_colors[rarity]
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	add_theme_stylebox_override("panel", style)

func _select_anim() -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.bg_color = Color(0.10, 0.18, 0.10, 0.95)
	style.border_color = rarity_colors[_card.rarity]
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	add_theme_stylebox_override("panel", style)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.12) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(1.1, 1.1, 1.1), 0.12)

func _deselect_anim() -> void:
	_apply_rarity_style(_card.rarity)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)
	tween.tween_property(self, "modulate", Color.WHITE, 0.10)

func _hover(hovered: bool) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale",
		Vector2(1.05, 1.05) if hovered else Vector2(1.0, 1.0), 0.08)
	tween.tween_property(self, "modulate",
		Color(1.15, 1.15, 1.15) if hovered else Color.WHITE, 0.08)

	# Brighten border on hover
	if _card == null:
		return
	var style       = StyleBoxFlat.new()
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.bg_color      = Color(0.06, 0.08, 0.06, 0.92)
	style.border_color  = rarity_colors[_card.rarity]
	style.border_width_top    = 2 if hovered else 1
	style.border_width_bottom = 2 if hovered else 1
	style.border_width_left   = 2 if hovered else 1
	style.border_width_right  = 2 if hovered else 1
	add_theme_stylebox_override("panel", style)

func play_confirm_flash() -> void:
	var tween = create_tween().set_loops(3)
	tween.tween_property(self, "modulate",
		Color( 
			rarity_colors[_card.rarity].r * 2,
			rarity_colors[_card.rarity].g * 2,
			rarity_colors[_card.rarity].b * 2), 0.06)
	tween.tween_property(self, "modulate", Color.WHITE, 0.06)

func get_card() -> RewardCard:
	return _card

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		emit_signal("card_selected", _card)
