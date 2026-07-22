extends CharacterBody2D
class_name BaseEnemy

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * 0.67

var apply_gravity: bool = true
var stored_velocity: Vector2
@onready var health_component: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine

@export_category("State Configuration")
## Idle state
@export var idle_state: State
## State for chasing the player
@export var chase_state: State = null

@export_category("Values")
## Maximum step height
@export var step_height: float = 4.0
## Attack Cooldown (in seconds)
@export var attack_cooldown: float = 2.0

var attack_cooldown_timer: float = 0.0

func _ready() -> void:
	# Connect health depleted signal
	health_component.health_depleted.connect(die)
	health_component.health_changed.connect(_on_health_changed)
	
	var detection = get_node_or_null("WeaponPivot/DetectionComponent")
	if detection:
		detection.player_spotted.connect(_on_player_spotted)
		detection.player_lost.connect(_on_player_lost)
	
	floor_snap_length = step_height

func _on_player_spotted() -> void:
	if chase_state:
		state_machine.force_transition(chase_state.name)

func _on_player_lost() -> void:
	state_machine.force_transition(idle_state.name)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	
	try_step_up()
	move_and_slide()

func try_step_up() -> void:
	if not is_on_floor() or abs(velocity.x) < 1.0:
		return
	var forward := Vector2(sign(velocity.x) * 2, 0)

	if test_move(transform, forward) and \
	   not test_move(transform.translated(Vector2(0, -step_height)), forward):
		position.y -= step_height

func freeze() -> void:
	stored_velocity = velocity
	velocity = Vector2.ZERO
	apply_gravity = false

func unfreeze() -> void:
	velocity = stored_velocity
	apply_gravity = true

func _on_health_changed(_current: int, _max: int) -> void:
	state_machine.force_transition("hit")

# Flipping left/right
func update_facing(direction: float) -> void:
	var sprite = get_node_or_null("AnimatedSprite2D")
	var pivot = get_node_or_null("WeaponPivot")
	
	if direction > 0:
		if sprite: sprite.flip_h = false
		if pivot: pivot.scale.x = 1
	elif direction < 0:
		if sprite: sprite.flip_h = true
		if pivot: pivot.scale.x = -1

# Triggers when health hits 0
func die() -> void:
	# Add stuff later
	queue_free()
