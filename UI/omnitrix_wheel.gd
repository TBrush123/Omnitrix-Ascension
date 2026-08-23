class_name OmnitrixWheel
extends Control

@export_group("Sound Settings")
@export var switchingSFX: AudioStreamPlayer
@export var activatingSFX: AudioStreamPlayer
@export var transformSFX: AudioStreamPlayer

@export_group("Wheel Settings")
@export var radius: float = 365.0
@export var rotation_speed: float = 12.0
@export var scale_active: float = 0.18
@export var scale_inactive: float = 0.15
@export var alien_icons: Node2D
@export var error_icon: Texture2D
@export var switch_cooldown: float = 0.25
@export var hand_texture: Sprite2D
@export var wheel_texture: TextureRect

var switch_timer: float = 0.0
var is_active: bool = false
var dir: int = 0

var aliens: Array[AlienData]
var omnitrix_component: OmnitrixComponent

const VISIBLE_SLOTS: int = 7
const HALF: int = VISIBLE_SLOTS / 2 
const STEP: float = (2 * PI) / 10.0 # 36 degrees
const INITIAL_DELAY:  float = 0.4 
const REPEAT_INTERVAL: float = 0.25

var icons = []
var selected_index: int = 0
var target_angle: float = 0.0
var current_angle: float = 0.0
var _hold_timer:    float = 0.0
var _has_repeated:  bool  = false
var _prev_dir:      int   = 0

func _ready():
	if aliens.is_empty():
		push_error("Add some alien textures to the array!")
		return
	selected_index = aliens.size() / 2
	_setup_wheel()
	hide()

func connect_to(player_omnitrix_component: OmnitrixComponent):
	omnitrix_component = player_omnitrix_component
	omnitrix_component.toggle_wheel.connect(toggle_wheel)
	omnitrix_component.alien_transform.connect(transform)
	aliens = omnitrix_component.aliens 


func find_alien_at_index(index: int) -> Texture2D:
	var texture = aliens[((index % aliens.size()) + aliens.size()) % aliens.size()].texture 
	if texture:
		return texture
	return error_icon 

func _setup_wheel():
	for i in range(VISIBLE_SLOTS):
		var icon = Sprite2D.new()
		icon.scale = Vector2.ONE * scale_inactive
		icon.texture = find_alien_at_index(selected_index - HALF + i)
		alien_icons.add_child(icon)
		icons.append(icon)


func _process(delta):
	current_angle = lerp_angle(current_angle, target_angle, delta * rotation_speed)
	_draw_wheel()

	if Input.is_action_pressed("ui_right"):
		dir = 1
		
	elif Input.is_action_pressed("ui_left"):
		dir = -1
	else:
		dir = 0
		

	if dir != 0 and is_active:
		# Reset hold state if direction changed
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		tween.tween_property(hand_texture, "offset", Vector2(-8, 0) if dir == -1 else Vector2(8, 0), 0.2)
		tween.tween_property(hand_texture, "rotation", deg_to_rad(-15) if dir == -1 else deg_to_rad(10), 0.2)
		if dir != _prev_dir:
			_hold_timer = 0.0
			_has_repeated = false

		_hold_timer += delta

		# First press — fire immediately
		if switch_timer <= 0.0 and _hold_timer <= delta + 0.01:
			_do_switch()

		# After initial delay — fire on repeat interval
		elif _hold_timer >= INITIAL_DELAY and switch_timer <= 0.0:
			_has_repeated = true
			_do_switch()

		_prev_dir = dir

	else:
		_hold_timer   = 0.0
		_has_repeated = false
		_prev_dir = 0

	if dir == 0 and is_active:
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(hand_texture, "offset", Vector2(0, 0), 0.2)
		tween.tween_property(hand_texture, "rotation", 0, 0.2)

	if switch_timer > 0.0:
		switch_timer -= delta

func _do_switch() -> void:
	switchingSFX.pitch_scale = randf_range(0.9, 1.1)
	switchingSFX.play()
	selected_index = ((selected_index + dir) % aliens.size() + aliens.size()) % aliens.size()
	if dir == 1:
		var icon = icons.pop_front()
		icon.texture = find_alien_at_index(selected_index + HALF)
		icons.append(icon)
	else:
		var icon = icons.pop_back()
		icon.texture = find_alien_at_index(selected_index - HALF)
		icons.push_front(icon)
	current_angle += dir * STEP

	# Use faster cooldown once repeat has kicked in
	switch_timer = REPEAT_INTERVAL if _has_repeated else switch_cooldown

func _draw_wheel():
	for i in range(VISIBLE_SLOTS):
		var angle = ((i - HALF) * STEP) + current_angle - (PI / 2) # Start from the top
		icons[i].position = Vector2(cos(angle), sin(angle)) * radius
		icons[i].rotation = angle + (PI / 2)

		var angle_diff = abs(angle_difference(angle, -PI / 2))
		if angle_diff < 0.2:
			icons[i].scale = icons[i].scale.lerp(Vector2.ONE * scale_active, 0.2)
		else:
			icons[i].scale = icons[i].scale.lerp(Vector2.ONE * scale_inactive, 0.2)

func get_active_alien_index():
	return selected_index

func can_transform() -> bool:
	return omnitrix_component.can_transform()

func toggle_wheel(should_show: bool):
	is_active = should_show
	if is_active:
		activatingSFX.play()
	
	# Create a tween for smooth movement
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if is_active:
		self.show()
		# Pop scale from 0 to 1 with a "Back" ease (slight overshoot for "pop" effect)
		tween.tween_property(self, "modulate:a", 1.0, 0.2)
	else:
		# Shrink and fade away
		var shrink_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(hand_texture, "offset", Vector2(0, 15), 0.2)
		shrink_tween.tween_property(self, "modulate:a", 0.0, 0.2)
		shrink_tween.chain().tween_callback(hide)

func transform(alien: AlienData):
	transformSFX.play()
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	self.show()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(hide)
	is_active = false

func reset():
	for icon in range(alien_icons.get_child_count()):
		alien_icons.get_child(icon).texture = find_alien_at_index(selected_index - HALF + icon)
