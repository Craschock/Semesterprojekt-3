extends State
class_name SpiderTurretIdle

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of the idle animation
@export var animation_name: String = "idle"
## Attack state to transition to when player is in range
@export var attack_state: State

@export_category("Turret Placement")
## How many pixels upwards (into the sky) the spider shifts from its initial spawn point
@export var spawn_height_offset: float = 45.0
## Maximum distance at which the spider will shoot at the player
@export var attack_range: float = 180.0
## Vertical offset when measuring distance to player (aims at chest instead of feet)
@export var target_offset: Vector2 = Vector2(0.0, -10.0)
## If true, the spider needs a clear line of sight (no walls in between) to shoot
@export var require_line_of_sight: bool = true

var anchor_position: Vector2 = Vector2.ZERO
var is_initialized: bool = false

func _ready() -> void:
	enemy = owner

func enter() -> void:
	# Only on first enter, shift spider up into the air and save anchor point
	if not is_initialized:
		is_initialized = true
		enemy.movement_type = BaseEnemy.MovementType.STATIC
		enemy.apply_gravity = false
		enemy.global_position.y -= spawn_height_offset
		anchor_position = enemy.global_position
	
	enemy.velocity = Vector2.ZERO
	enemy.global_position = anchor_position
	
	var sprite = enemy.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play(animation_name)

func physics_update(_delta: float) -> void:
	# Keep spider locked to its web anchor point (for prevents knockback drifting). TODO: Refactor knockback
	enemy.velocity = Vector2.ZERO
	enemy.global_position = anchor_position
	
	var target = PlayerManager.player
	if target == null:
		return
		
	var target_pos = target.global_position + target_offset
	var dist = enemy.global_position.distance_to(target_pos)
	var dir_x = sign(target_pos.x - enemy.global_position.x)
	
	if dir_x != 0:
		enemy.update_facing(dir_x)
	
	# Check range & cooldown
	if dist <= attack_range and enemy.attack_cooldown_timer <= 0.0:
		if require_line_of_sight and not _has_line_of_sight(target_pos):
			return
			
		if attack_state:
			enemy.attack_cooldown_timer = enemy.attack_cooldown
			transitioned.emit(self, attack_state.name)

func _has_line_of_sight(target_pos: Vector2) -> bool:
	var space_state = enemy.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(enemy.global_position, target_pos, 1)
	var result = space_state.intersect_ray(query)
	return result.is_empty()
