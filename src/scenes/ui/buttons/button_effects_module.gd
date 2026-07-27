extends Node
class_name ButtonEffectsModule

# README: Script needs to be child of button
@export_category("General Tween Settings")
@export var ease_type: Tween.EaseType
@export var trans_type: Tween.TransitionType
@export var anim_duration: float = 0.07
@export_category("Scale Settings")
@export var allow_scale: bool = true
@export var scale_amount: Vector2 = Vector2(1.1 , 1.1)
@export_category("Rotation Settings")
@export var allow_rotation: bool = true
@export var rotation_amount: float = 3.0

@onready var button: Button = get_parent()
var tween: Tween

# Initial values
var init_button_scale: Vector2
var init_button_rotation: float

func _ready() -> void:
	button.mouse_entered.connect(_on_mouse_hovered.bind(true))
	button.mouse_exited.connect(_on_mouse_hovered.bind(false))
	button.pressed.connect(_on_button_pressed)
	
	# Set pivot offset
	button.pivot_offset_ratio = Vector2(0.5, 0.5)
	
	# Get initial values
	init_button_scale = button.scale
	init_button_rotation = button.rotation

func _on_button_pressed() -> void:
	reset_tween()
	if allow_scale:
		tween.tween_property(button,"scale", 
		init_button_scale * scale_amount, anim_duration).from(init_button_scale * Vector2(0.8, 0.8))
	if allow_rotation:
		tween.tween_property(button,"rotation", 
		init_button_rotation + rotation_amount * [-1, 1].pick_random(), anim_duration).from(0)
	

func _on_mouse_hovered(hovered: bool) -> void:
	reset_tween()
	if allow_scale:
		tween.tween_property(button,"scale", 
		init_button_scale * scale_amount if hovered else init_button_scale, anim_duration)
	if allow_rotation:
		tween.tween_property(button,"rotation", 
		init_button_rotation + rotation_amount * [-1, 1].pick_random() if hovered else button.rotation, anim_duration)

func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(ease_type).set_trans(trans_type).set_parallel(true)

# TODO: add a way to remember Scale/Rotation
