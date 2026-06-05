class_name RewardScreen
extends Control

signal reward_chosen(card: RewardCard)

func _process(delta):
    $Hand/Beam.modulate.a = 0.8 + sin(Time.get_ticks_msec() * 0.002) * 0.2

@onready var hand: TextureRect = $OmnitrixHand
@onready var projection_icon: TextureRect = $ProjectionIcon
@onready var cards_container: HBoxContainer = $CardsContainer
@onready var lightning: LightningCanvas = $LightningCanvas
@onready var card_label: Label = $CardTypeLabel

@export var card_ui_scene: PackedScene

var _card_uis: Array[RewardCardUI] = []
var _selected_index: int = 0
var _confirmed: bool = false

func populate(cards: Array[RewardCard]) -> void:
    for child in cards_container.get_children():
        child.queue_free()
    
    _cards_uis.clear()
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
