class_name AlienChargeHUD
extends Control

@onready var progress_bar: TextureProgressBar = $MarginContainer/TextureProgressBar

func _ready():
	# Initialize values
    progress_bar.value = 100

func connect_to(alien_charge: AlienChargeComponent) -> void:
    alien_charge.charge_updated.connect(_change_value)

func _change_value(current_charge: float, max_charge: float) -> void:
    progress_bar.value = (current_charge / max_charge) * 100.0
    
