extends CharacterBody2D
class_name BaseEnemy

enum MovementType { GROUND, FLYING, STATIC }

const GRAVITY_MULTIPLIER: float = 0.67
const STEP_FORWARD_CHECK_DIST: float = 2.0
const MIN_STEP_VELOCITY_X: float = 1.0

@export_category("Movement & Physics")
## Determines whether the enemy walks on floors, flies freely, or stays anchored in place
@export var movement_type: MovementType = MovementType.GROUND
## Maximum step height in pixels for climbing small terrain ledges (GROUND only)
@export var step_height: float = 5.0
## Enable if the sprite artwork was drawn facing left instead of right
@export var sprite_faces_left_by_default: bool = false

@export_category("Combat Settings")
## Cooldown in seconds between enemy attacks
@export var attack_cooldown: float = 2.0
## If true, taking damage forces the enemy into its "Hit" state
@export var can_be_staggered: bool = true
## Name of the Hit state node in the StateMachine
@export var hit_state_name: String = "hit"
## Name of the Death state node in the StateMachine
@export var death_state_name: String = "enemydeath"

# Cached Node References for States to use cleanly
@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var loot_drop_component: LootDropComponent = $LootDropComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var detection_component: DetectionComponent = get_node_or_null("WeaponPivot/DetectionComponent")
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * GRAVITY_MULTIPLIER
var is_dead: bool = false
var apply_gravity: bool = true
var stored_velocity: Vector2 = Vector2.ZERO
var attack_cooldown_timer: float = 0.0

## Backwards-compatibility property so existing states checking `enemy.is_flying_entity` still work!
var is_flying_entity: bool:
	get:
		return movement_type == MovementType.FLYING
	set(value):
		movement_type = MovementType.FLYING if value else MovementType.GROUND

func _ready() -> void:
	health_component.health_depleted.connect(die)
	health_component.health_changed.connect(_on_health_changed)
	
	floor_snap_length = step_height
	
	if movement_type == MovementType.STATIC:
		hitbox_component.can_receive_knockback = false

func _physics_process(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
		
	if movement_type == MovementType.STATIC:
		velocity = Vector2.ZERO
		return
		
	if movement_type == MovementType.GROUND and apply_gravity:
		if not is_on_floor():
			velocity.y += gravity * delta
		try_step_up()
	
	move_and_slide()

func try_step_up() -> void:
	if not is_on_floor() or abs(velocity.x) < MIN_STEP_VELOCITY_X:
		return
	var forward := Vector2(sign(velocity.x) * STEP_FORWARD_CHECK_DIST, 0.0)

	if test_move(transform, forward) and \
	   not test_move(transform.translated(Vector2(0.0, -step_height)), forward):
		position.y -= step_height

## Called automatically by HitboxComponent when hit
func apply_knockback(source_pos: Vector2, force: float, upward_pop_ratio: float) -> void:
	if movement_type == MovementType.STATIC or is_dead:
		return
		
	if movement_type == MovementType.FLYING:
		var knockback_dir: Vector2 = source_pos.direction_to(global_position)
		velocity = knockback_dir * force
	else:
		var dir_x: float = sign(global_position.x - source_pos.x)
		if dir_x == 0.0:
			dir_x = 1.0
		velocity = Vector2(dir_x * force, -force * upward_pop_ratio)

## Flips both the sprite and the WeaponPivot (vision cone, attack hitboxes, muzzle)
func update_facing(direction: float) -> void:
	if direction == 0.0:
		return
		
	var facing_right: bool = direction > 0.0
	if sprite:
		sprite.flip_h = facing_right if sprite_faces_left_by_default else not facing_right
	if weapon_pivot:
		weapon_pivot.scale.x = 1.0 if facing_right else -1.0

## Helper for states to check if the player is currently detected
func can_see_player() -> bool:
	return detection_component != null and detection_component.is_currently_seeing_player

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
	if can_be_staggered:
		state_machine.force_transition(hit_state_name)

func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	velocity = Vector2.ZERO
	hitbox_component.set_deferred("monitoring", false)
	hitbox_component.set_deferred("monitorable", false)
	
	var col_shape = hitbox_component.get_node_or_null("CollisionShape2D")
	if col_shape:
		col_shape.set_deferred("disabled", true)
	
	loot_drop_component._start_drop()
	state_machine.force_transition(death_state_name)
