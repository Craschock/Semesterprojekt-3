extends CharacterBody2D
class_name PlayerMovement

@onready var health_component: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var inventory_component: InventoryComponent = $InventoryComponent

# Movement 
@export var speed: float = 70.0
@export var acceleration: float = 600.0
@export var friction: float = 800.0
##Maximum step height
@export var step_height: float = 8.0
var stored_velocity: Vector2

#Jump
## Maximum jump height
@export var min_jump_velocity: float = -150.0
## Minimum jump height
@export var max_jump_velocity: float = -350.0
## How many seconds to reach max jump charge
@export var time_to_max_charge: float = 0.4
## How long player can jump after leaving platform
@export var jump_buffer_time: float = 0.15

var jump_buffer_timer: float = 0.0
var current_jump_charge: float = 0.0

# Inventory
const ITEM_HOTKEY_OFFSET: int = 5

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var apply_gravity: bool = true
var is_frozen: bool = false


func _ready() -> void:
	# Setup Singleton PlayerManager
	PlayerManager.player = self
	# Connect signals
	health_component.health_changed.connect(_on_health_changed)
	health_component.health_depleted.connect(_on_health_depleted)
	floor_snap_length = step_height
func _physics_process(delta: float) -> void:
	if is_frozen:
		return
	
	var cam := get_viewport().get_camera_2d()
	# Jump buffer
	if is_on_floor():
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta
	
	# Apply Gravity or Fly Mode
	if apply_gravity:
		if not is_on_floor():
			velocity.y += gravity * delta
	else:
		# Debug fly movement
		var vertical_dir := Input.get_axis("move_up", "move_down")
		velocity.y = vertical_dir * speed

	try_step_up()
	move_and_slide()



# Utility Methods

func _on_health_changed(_current: int, _max: int) -> void:
	state_machine.force_transition("hit")

func _on_health_depleted() -> void:
	state_machine.force_transition("death")

func _unhandled_input(event: InputEvent) -> void:
	for i in range(ITEM_HOTKEY_OFFSET, 10):
		if event.is_action_pressed("slot_" + str(i)):
			inventory_component.toggle_slot(i - ITEM_HOTKEY_OFFSET)

# Flip Logic
func update_facing(direction: float) -> void:
	if direction > 0:
		$WeaponPivot.scale.x = 1
		$AnimatedSprite2D.flip_h = false
	elif direction < 0:
		$WeaponPivot.scale.x = -1
		$AnimatedSprite2D.flip_h = true

# Jump functions
func can_jump() -> bool:
	return is_on_floor() or jump_buffer_timer > 0.0 # Returns if player is allowed to jump

func consume_jump() -> void:
	jump_buffer_timer = 0.0 # Removes jump buffer so player cannot double jump

# Step height
func try_step_up() -> void:
	if not is_on_floor() or abs(velocity.x) < 1.0:
		return
	var forward := Vector2(sign(velocity.x) * 2, 0)

	if test_move(transform, forward) and \
	   not test_move(transform.translated(Vector2(0, -step_height)), forward):
		position.y -= step_height

# Attack freeze
func freeze() -> void:
	stored_velocity = velocity
	velocity = Vector2.ZERO
	is_frozen = true

func unfreeze() -> void:
	velocity = stored_velocity
	is_frozen = false
