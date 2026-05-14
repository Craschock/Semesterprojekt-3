extends CharacterBody2D
class_name PlayerMovement

# Movement 
@export var speed: float = 70.0
@export var acceleration: float = 600.0
@export var friction: float = 800.0
var stored_velocity: Vector2

#Jump
@export var jump_velocity: float = -250.0
@export var jump_buffer_time = 0.15
var jump_buffer_timer = 0.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var apply_gravity: bool = true


func _ready() -> void:
	# Setup Singleton PlayerManager
	PlayerManager.player = self

func _physics_process(delta: float) -> void:
	# Jump buffer
	if is_on_floor():
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta
	
	# Apply Gravity
	if not is_on_floor() and apply_gravity:
		velocity.y += gravity * delta

	move_and_slide()



# Utility Methods

# Jump functions
func can_jump() -> bool:
	return is_on_floor() or jump_buffer_timer > 0.0 # Returns if player is allowed to jump

func consume_jump() -> void:
	jump_buffer_timer = 0.0 # Removes jump buffer so player cannot double jump

# Attack freeze
func freeze() -> void:
	stored_velocity = velocity
	velocity = Vector2.ZERO
	apply_gravity = false

func unfreeze() -> void:
	velocity = stored_velocity
	apply_gravity = true
