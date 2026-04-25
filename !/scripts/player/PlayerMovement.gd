extends CharacterBody2D
class_name PlayerMovement

@export var speed: float = 70.0
@export var jump_velocity: float = -250.0
@export var acceleration: float = 600.0
@export var friction: float = 800.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	# Setup Singleton PlayerManager
	PlayerManager.player = self

func _physics_process(delta: float) -> void:
	# Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
