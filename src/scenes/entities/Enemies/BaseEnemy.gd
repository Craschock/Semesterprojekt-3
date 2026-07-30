extends CharacterBody2D
class_name BaseEnemy

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * 0.67
var is_dead: bool = false
var apply_gravity: bool = true
var stored_velocity: Vector2
@onready var health_component: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var loot_drop_component: LootDropComponent = $LootDropComponent

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
## Check if entity flies (ignores gravity and step up)
@export var is_flying_entity: bool = false

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
	if is_dead:
		return
	
	if chase_state:
		state_machine.force_transition(chase_state.name)

func _on_player_lost() -> void:
	if not is_dead:
		var current = state_machine.current_state
		if current == chase_state:
			state_machine.force_transition(idle_state.name)

func _physics_process(delta: float) -> void:
	
	if not is_flying_entity:
		
		if not is_on_floor():
			velocity.y += gravity * delta
		
		try_step_up()
	
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	
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
	if is_dead:
		return
	
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
	if is_dead:
		return
		
	is_dead = true
	velocity = Vector2.ZERO
	var col_shape = hitbox_component.get_node_or_null("CollisionShape2D")
	
	if col_shape:
		col_shape.set_deferred("disabled", true)
	
	loot_drop_component._start_drop()
	state_machine.force_transition("enemydeath")
