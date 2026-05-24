extends Node2D

var blast_range: float = 150.0

func _ready() -> void:
	var sprite_base_size = 32.0
	var target_scale = (blast_range * 2.0) / sprite_base_size
	var tween = create_tween().set_parallel(true)
	tween.tween_property($Ring, "scale",
		Vector2(target_scale, target_scale), 0.35) \
		.from(Vector2(0.1, 0.1)) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property($Ring, "modulate:a",
		0.0, 0.35)
	tween.tween_callback(queue_free).set_delay(0.35)
