class_name AlienData
extends Resource

@export var alien_name:    String       = "Unknown"
@export var texture:       Texture2D
@export var scale_modifier: Vector2    = Vector2.ONE
@export var attack_instance:  PackedScene  # the projectile or melee hitbox this alien fires
@export var passive_trait: String       = ""  # resolved by PassiveSystem later

@export var stat_modifiers: Dictionary = {}