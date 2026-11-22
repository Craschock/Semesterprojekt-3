extends State
class_name EnemyFrogChase

const GROUND_FRICTION: float = 800.0
const HEIGHT_BOOST_MULTIPLIER: float = 1.5
const MAX_HEIGHT_BOOST_RATIO: float = 1.8
const WORLD_COLLISION_MASK: int = 1
const MS_TO_SECONDS: float = 1000.0

var enemy: BaseEnemy

@export_category("Animation Names")
@export var anim_charge: String = "jump_charge"
@export var anim_up: String = "jump_up"
@export var anim_down: String = "jump_down"
@export var anim_land: String = "jump_land"

@export_category("Aggressive Jump Settings")
## Minimum jump height
@export var min_jump_y: float = 120.0
## Maximum jump height
@export var max_jump_y: float = 200.0
## Minimum jump length (X-Achse)
@export var min_jump_x: float = 60.0
## Maximum jump length (X-Achse)
@export var max_jump_x: float = 110.0
## How long the enemy charges the jump (in seconds)
@export var charge_duration: float = 0.15
## How long the enemy pauses after landing (in seconds)
@export var land_duration: float = 0.1

@export_category("combat zopnes")
## Close range threshold for melee
@export var close_bite_range: float = 25.0
## Minimum distance to trigger the mid-range tongue pull
@export var tongue_min_range: float = 45.0
## Maximum distance to trigger the mid-range tongue pull
@export var tongue_max_range: float = 140.0
## Independent cooldown in seconds between tongue pull attempts
@export var tongue_cooldown: float = 5.0
## Aim offset used for Line-of-Sight raycast to player
@export var los_target_offset: Vector2 = Vector2(0.0, -10.0)

@export_category("Transitions")
## Close-range bite state (EnemyAttack)
@export var attack_state: State
## Mid-range tongue pull state (FrogTongueAttack)
@export var tongue_attack_state: State
## State to return to when the player escapes detection
@export var lost_player_state: State

var phase: int = 0 # 0 = Charge, 1 = Air, 2 = Land
var timer: float = 0.0
var jump_dir_x: int = 1
var next_tongue_ready_time: float = 0.0

func _ready() -> void:
	enemy = owner

func enter() -> void:
	_start_charge()

func physics_update(delta: float) -> void:
	var target = PlayerManager.player
	
	match phase:
		0: # Charge
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, GROUND_FRICTION * delta)
			timer -= delta
			
			if timer <= 0.0:
				if target:
					jump_dir_x = sign(target.global_position.x - enemy.global_position.x)
					if jump_dir_x == 0:
						jump_dir_x = 1
					enemy.update_facing(jump_dir_x)
				_jump()
				
		1: # Air
			if enemy.sprite:
				enemy.sprite.play(anim_up if enemy.velocity.y < 0.0 else anim_down)
			
			if enemy.is_on_floor() and enemy.velocity.y >= 0.0:
				phase = 2
				timer = land_duration
				enemy.velocity.x = 0.0
				if enemy.sprite:
					enemy.sprite.play(anim_land)
				
		2: # Land
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, GROUND_FRICTION * delta)
			timer -= delta
			
			if timer <= 0.0:
				if lost_player_state and not enemy.can_see_player():
					transitioned.emit(self, lost_player_state.name)
					return
				
				if target == null:
					return
				
				var dist: float = enemy.global_position.distance_to(target.global_position)
				var now_sec: float = Time.get_ticks_msec() / MS_TO_SECONDS
				
				# Close Range (Meele)
				if dist <= close_bite_range and attack_state and enemy.attack_cooldown_timer <= 0.0:
					enemy.attack_cooldown_timer = enemy.attack_cooldown
					transitioned.emit(self, attack_state.name)
					return
				
				# Mid Range (Tongue Pull) (if off cooldown and clear LOS)
				if dist >= tongue_min_range and dist <= tongue_max_range \
				   and tongue_attack_state and now_sec >= next_tongue_ready_time \
				   and _has_line_of_sight(target.global_position + los_target_offset):
					next_tongue_ready_time = now_sec + tongue_cooldown
					transitioned.emit(self, tongue_attack_state.name)
					return
				
				# Far Range (or attacks on cooldown)
				# jump to player
				_start_charge()

func _start_charge() -> void:
	phase = 0
	timer = charge_duration
	enemy.velocity.x = 0.0
	if enemy.sprite:
		enemy.sprite.play(anim_charge)

func _jump() -> void:
	phase = 1
	var force_y: float
	var force_x: float
	
	var target = PlayerManager.player
	if target:
		var distance_x: float = abs(target.global_position.x - enemy.global_position.x)
		force_x = clamp(distance_x, min_jump_x, max_jump_x)
		
		var jump_ratio: float = (force_x - min_jump_x) / max(max_jump_x - min_jump_x, 0.01)
		force_y = lerp(min_jump_y, max_jump_y, jump_ratio)
		
		var height_diff: float = enemy.global_position.y - target.global_position.y
		if height_diff > 0.0:
			force_y += height_diff * HEIGHT_BOOST_MULTIPLIER
			force_y = min(force_y, max_jump_y * MAX_HEIGHT_BOOST_RATIO)
	else:
		force_x = randf_range(min_jump_x, max_jump_x)
		force_y = randf_range(min_jump_y, max_jump_y)
	
	enemy.velocity.y = -force_y
	enemy.velocity.x = jump_dir_x * force_x

func _has_line_of_sight(target_pos: Vector2) -> bool:
	var space_state = enemy.get_world_2d().direct_space_state
	var origin: Vector2 = enemy.global_position + los_target_offset
	var query = PhysicsRayQueryParameters2D.create(origin, target_pos, WORLD_COLLISION_MASK)
	return space_state.intersect_ray(query).is_empty()
