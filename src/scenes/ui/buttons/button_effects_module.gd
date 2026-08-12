extends Node
class_name ButtonEffectsModule

# README: Script needs to be child of button
@export_category("General Tween Settings")
## The type of ease the animation will use (e.g. "EaseIn", "EaseOut")
@export var ease_type: Tween.EaseType
## The transition type the animation will use. (Math functions like linear, Sine, Cubic, Exponential and more).
@export var trans_type: Tween.TransitionType
## Duration of animation effect (in seconds)
@export var anim_duration: float = 0.1



@export_category("Scale Settings")
## Should button be allowed to scale?
@export var allow_scale: bool = false
## Scale multiplier on when the button is hovered (inital_scale * scale_amount_hover)
@export var scale_amount_hover: Vector2 = Vector2(1.1 , 1.1)
## Scale multiplier on when the button is pressed (inital_scale * scale_amount_pressed)
@export var scale_amount_pressed: Vector2 = Vector2(0.9, 0.9)



@export_category("Rotation Settings")
## Should button be allowed to rotate?
@export var allow_rotation: bool = false
## Rotation of button when hovering (in degrees). 
## (positive value = clockwise).
## (negative value = counterclockwise).
@export var rotation_amount_hover: float = 5.0
## Rotation of button when pressed (in degrees). 
## (positive value = clockwise).
## (negative value = counterclockwise).
@export var rotation_amount_pressed: float = - 10.0



@export_category("Outline Settings")
## Should button display an outline on hover?
@export var allow_outline: bool = false
## Outline thiccness of button on hover (int in pixel)
@export var outline_thickness: int = 16
## Outline color of button on hover
@export var outline_color: Color = Color.BLACK



@onready var button: Button = get_parent()
var tween: Tween

# Initial values
var init_button_scale: Vector2
var init_button_rotation: float

func _ready() -> void:
	# Hover enter
	button.mouse_entered.connect(_on_mouse_hovered.bind(true))
	# Hover exit
	button.mouse_exited.connect(_on_mouse_hovered.bind(false))
	# Press button down
	button.button_down.connect(_on_button_pressed.bind(true))
	# Lets button go 
	button.button_up.connect(_on_button_pressed.bind(false))
	
	# Set pivot offset
	button.pivot_offset_ratio = Vector2(0.5, 0.5)
	
	# Get initial values
	init_button_scale = button.scale
	init_button_rotation = button.rotation_degrees
	button.add_theme_color_override("font_outline_color", outline_color)

func _on_mouse_hovered(hovered: bool) -> void:
	reset_tween()
	# Animate scale
	if allow_scale:
		tween.tween_property(button,"scale",
		init_button_scale * scale_amount_hover if hovered else init_button_scale,
		anim_duration)
	
	# Animate rotation
	if allow_rotation:
		tween.tween_property(button,"rotation_degrees",
		init_button_rotation + rotation_amount_hover if hovered else init_button_rotation,
		anim_duration)
	
	# Animate outline
	if allow_outline:
		button.add_theme_constant_override("outline_size",
		outline_thickness if hovered else 0)

func _on_button_pressed(pressed:bool):
	if pressed:
		reset_tween()
		# Animate scale
		if allow_scale:
			tween.tween_property(button,"scale", init_button_scale * scale_amount_pressed, anim_duration)
		
		# Animate rotation
		if allow_rotation:
			tween.tween_property(button,"rotation_degrees", init_button_rotation + rotation_amount_pressed, anim_duration)
	else:
		_on_mouse_hovered(button.is_hovered())

func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(ease_type).set_trans(trans_type).set_parallel(true)
