class_name AlienChargeHUD
extends Control

@onready var progress_bar: TextureProgressBar = $MarginContainer/TextureProgressBar
@onready var beep_sound:   AudioStreamPlayer  = $BeepSound
@onready var recharge_sound:   AudioStreamPlayer  = $RechargeSound
var _tween: Tween = null
var _is_blinking: bool  = false
var _blink_tween: Tween = null

var _last_blink_period: float = -1.0    

const LOW_THRESHOLD: float = 0.20
const CRITICAL_THRESHOLD: float = 0.10


func _ready():
	# Initialize values
	progress_bar.value = 100
	progress_bar.modulate = Color.GREEN

func connect_to(alien_charge: AlienChargeComponent) -> void:
	alien_charge.charge_updated.connect(_change_value)
	alien_charge.charge_depleted.connect(_on_depleted)
	alien_charge.charge_recharged.connect(_on_recharged)

func _change_value(current_charge: float, max_charge: float) -> void:
	var pct = current_charge / max_charge
	var target = pct * 100.0

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(progress_bar, "value", target, 0.15) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_IN_OUT)
	
	if pct <= LOW_THRESHOLD and not _is_blinking:
		_start_blinking(pct)
	elif pct > LOW_THRESHOLD and _is_blinking:
		_stop_blinking()
	elif _is_blinking:
		_update_blink_speed(pct)

	
func _on_depleted() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(progress_bar, "value", 0.0, 0.1) \
		.set_trans(Tween.TRANS_LINEAR)
	progress_bar.modulate = Color.RED
	beep_sound.stop()

func _on_recharged() -> void:
	_blink_tween = create_tween()
	# Flash to red
	_blink_tween.tween_property(progress_bar, "modulate",
		Color.GREEN, 0.2) \
		.set_trans(Tween.TRANS_SINE)
	beep_sound.stop()
	recharge_sound.play()

func _start_blinking(pct: float) -> void:
	_is_blinking = true
	_update_blink_speed(pct)

func _stop_blinking() -> void:
	_is_blinking       = false
	_last_blink_period = -1.0   # ← reset so next time it starts fresh
	if _blink_tween:
		_blink_tween.kill()

func _update_blink_speed(pct: float) -> void:
	# Blink period: 0.8s at 20%, speeds up to 0.25s at 0%
	var blink_period = lerp(0.25, 0.80, pct / LOW_THRESHOLD)

	if abs(blink_period - _last_blink_period) < 0.05:
		return
	
	_last_blink_period = blink_period
	if _blink_tween:
		_blink_tween.kill()

	_blink_tween = create_tween().set_loops()
	# Flash to red
	_blink_tween.tween_property(progress_bar, "modulate",
		Color.RED, blink_period * 0.3) \
		.set_trans(Tween.TRANS_SINE)
	# Back to normal
	_blink_tween.tween_property(progress_bar, "modulate",
		Color.WHITE, blink_period * 0.7) \
		.set_trans(Tween.TRANS_SINE)

	# Play beep in sync with the blink
	_schedule_beep(blink_period)
	
func _schedule_beep(period: float) -> void:
	# Stop previous beep loop first
	if beep_sound.playing:
		beep_sound.stop()
	beep_sound.play()

	# Re-trigger the beep every blink cycle
	# Using a timer so it stays in sync with the blink tween
	var timer = get_tree().create_timer(period)
	timer.timeout.connect(func():
		if _is_blinking:
			_schedule_beep(period)
	)
	
