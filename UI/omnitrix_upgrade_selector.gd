extends Control

func _process(delta):
    $Hand/Beam.modulate.a = 0.8 + sin(Time.get_ticks_msec() * 0.002) * 0.2