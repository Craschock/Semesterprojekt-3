extends CharacterBody2D
class_name PlayerMovement

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 1500.0
@export var friction: float = 2000.0

# Get default Gravity
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	# Setup Singleton PlayerManager
	PlayerManager.player = self

func _physics_process(delta: float) -> void:
	# Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get Input Direction (-1 left, 1 right, 0 idle)
	var direction := Input.get_axis("move_left", "move_right")
	
	# Apply Horizontal Movement (smooth)
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# Built-in Godot function that physically moves the character and resolves collisions
	move_and_slide()
