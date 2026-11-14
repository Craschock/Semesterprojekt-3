extends State
class_name EnemyChase

var enemy: BaseEnemy

@export_category("Chase Settings")
## Name of Animation to be played while chasing
@export var animation_name: String = "walk"
## Name of Animation to be played while waiting for attack cooldown in range
@export var idle_animation_name: String = "idle"
## Horizontal movement speed while chasing the player
@export var chase_speed: float = 60.0

@export_category("State Transitions")
## Distance at which the enemy triggers its attack
@export var attack_range: float = 25.0
## Attack State Node to transition to when in range
@export var attack_state: State
## State to return to when the player escapes detection
@export var lost_player_state: State

func _ready() -> void:
	enemy = owner

func enter() -> void:
	if enemy.sprite:
		enemy.sprite.play(animation_name)

func physics_update(_delta: float) -> void:
	# If DetectionComponent lost the player, return to lost_player_state
	if lost_player_state and not enemy.can_see_player():
		transitioned.emit(self, lost_player_state.name)
		return
		
	var target = PlayerManager.player
	if target == null:
		return
		
	var dist: float = enemy.global_position.distance_to(target.global_position)
	var dir_x: float = sign(enemy.global_position.direction_to(target.global_position).x)
	
	if dir_x != 0.0:
		enemy.update_facing(dir_x)
	
	if dist <= attack_range:
		if attack_state and enemy.attack_cooldown_timer <= 0.0:
			enemy.attack_cooldown_timer = enemy.attack_cooldown
			transitioned.emit(self, attack_state.name)
		else:
			enemy.velocity.x = 0.0
			if enemy.sprite:
				enemy.sprite.play(idle_animation_name)
	else:
		if dir_x != 0.0:
			enemy.velocity.x = dir_x * chase_speed
			if enemy.sprite:
				enemy.sprite.play(animation_name)
