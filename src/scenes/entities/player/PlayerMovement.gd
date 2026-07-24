extends CharacterBody2D
class_name PlayerMovement

@onready var health_component: HealthComponent = $HealthComponent
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var state_machine: StateMachine = $StateMachine

# Movement 
@export_category("Movement")
## Movement Speed of Player
@export var speed: float = 70.0
## Acceleration of Player
@export var acceleration: float = 600.0#
## Decceleration of Player
@export var friction: float = 800.0
## Maximum step height
@export var step_height: float = 4.0
var stored_velocity: Vector2

# Physics
@export_category("Physics")
## Terminal Velocity for Player
@export var max_fall_velocity: float = 500.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var apply_gravity: bool = true
var is_frozen: bool = false


#Jump
@export_category("Jump")
## Maximum jump height
@export var min_jump_velocity: float = -150.0
## Minimum jump height
@export var max_jump_velocity: float = -350.0
## How many seconds to reach max jump charge
@export var time_to_max_charge: float = 0.4
## How long player can jump after leaving platform
@export var jump_buffer_time: float = 0.15
## How long a jump is a press before it's changing into a charged jumnp
@export var tap_window: float = 0.1
## Double jump height
@export var double_jump_velocity: float = -250.0
## Amount of mid-air jumps (double jump)
@export var max_air_jumps: int = 1

# Input Buffers
@export_category("Input Buffers")
## How early a player can use an action before it actually can happen
@export var action_input_buffer: float = 0.3
## How early a player can block before actually being able to block
@export var block_input_buffer: float = 0.3
## How early a player can jump before landing on a platform that he can jump off
@export var jump_input_buffer: float = 0.3
## How early a player can dig into the ground before being able to perform a dig
@export var dig_input_buffer: float = 0.3

# Unlockables
@export_category("Unlockables")
## Check if player has digging unlocked (1st boss)
@export var unlocked_digging: bool = false

var action_input_buffer_timer: float = 0.0
var block_input_buffer_timer: float = 0.0
var jump_input_buffer_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dig_input_buffer_timer: float = 0.0
var current_jump_charge: float = 0.0
var current_air_jumps: int = 0
var was_interrupted_while_charging: bool = false
var dig_target_position: Vector2 = Vector2.ZERO


# Constants
const ITEM_HOTKEY_OFFSET: int = 1
const INVALID_POS: Vector2 = Vector2(-99999, -99999) # Error check

func _ready() -> void:
	# Setup Singleton PlayerManager
	PlayerManager.player = self
	# Connect signals
	health_component.health_changed.connect(_on_health_changed)
	health_component.health_depleted.connect(_on_health_depleted)
	floor_snap_length = step_height

func _physics_process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	# Input Buffer
	if Input.is_action_just_pressed("attack"):
			action_input_buffer_timer = action_input_buffer
	if Input.is_action_just_pressed("block"):
			block_input_buffer_timer = block_input_buffer
	if Input.is_action_just_pressed("jump"):
			jump_input_buffer_timer = jump_input_buffer
	if Input.is_action_just_pressed("move_dig"):
		dig_input_buffer_timer = dig_input_buffer
	
	# Jump buffer
	if is_frozen:
		return
	
	
	# Decreasing Buffers
	if is_on_floor():
		jump_buffer_timer = jump_buffer_time
		current_air_jumps = 0
	else:
		jump_buffer_timer -= delta
	
	if action_input_buffer_timer > 0.0:
		action_input_buffer_timer -= delta
	if block_input_buffer_timer > 0.0:
		block_input_buffer_timer -= delta
	if jump_input_buffer_timer > 0.0:
		jump_input_buffer_timer -= delta
	if dig_input_buffer_timer > 0.0:
		dig_input_buffer_timer -= delta
	
	# Apply Gravity or Fly Mode
	if apply_gravity:
		if not is_on_floor():
			velocity.y = min(velocity.y + gravity * delta, max_fall_velocity)
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
	# Existing inventory hotkeys
	for i in range(ITEM_HOTKEY_OFFSET, 4):
		if event.is_action_pressed("slot_" + str(i)):
			inventory_component.toggle_slot(i - ITEM_HOTKEY_OFFSET)

	#DEBUG scroll to zoom
	if event is InputEventMouseButton and event.is_pressed():
		var cam := get_viewport().get_camera_2d()
		if cam:
			var zoom_step := Vector2(0.1, 0.1)
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				cam.zoom += zoom_step
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				cam.zoom -= zoom_step
			
			#limit zoom
			cam.zoom = cam.zoom.clamp(Vector2(0.2, 0.2), Vector2(5.0, 5.0))

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

# Dig in Check
func get_dig_target(required_depth: int = 10) -> Vector2:
	var world = get_parent().get_node_or_null("World")
	
	if not world or not world.get("fg_layer"):
		return Vector2.INF
	
	var fg_layer = world.fg_layer
	var tile_pos = fg_layer.local_to_map(fg_layer.to_local(global_position))
	
	for i in range(1, required_depth + 1):
		var check_pos = tile_pos + Vector2i(0, i)
		
		if fg_layer.get_cell_source_id(check_pos) == -1:
			return Vector2.INF
		
	var target_tile = tile_pos + Vector2i(0, 1)
	return fg_layer.to_global(fg_layer.map_to_local(target_tile))

# Dig out Check
func get_dig_out_target(max_upwards_scan: int = 5) -> Vector2:
	var world = get_parent().get_node_or_null("World")
	if not world or not world.get("fg_layer"):
		return INVALID_POS
		
	var fg_layer = world.fg_layer
	var tile_pos = fg_layer.local_to_map(fg_layer.to_local(global_position))
	
	for i in range(0, max_upwards_scan + 1):
		var check_pos = tile_pos - Vector2i(0, i)
		
		if fg_layer.get_cell_source_id(check_pos) == -1:
			return fg_layer.to_global(fg_layer.map_to_local(check_pos))
			
	return INVALID_POS
