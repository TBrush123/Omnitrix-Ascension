extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Hitbox ready, monitoring: ", monitoring)
	print("Hitbox collision layer: ", collision_layer)
	print("Hitbox collision mask: ", collision_mask)
	area_entered.connect(_on_area_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	print("HIT: ", area.name, " | groups: ", area.get_groups())