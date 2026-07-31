extends State
class_name EnemyFrogChase

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

@export_category("Transitions")
## How close enemy needs to be
@export var attack_range: float = 40.0
## Attack state
@export var attack_state: State

var phase: int = 0 # 0 = Charge, 1 = Air, 2 = Land
var timer: float = 0.0
var jump_dir_x: int = 1

func _ready() -> void:
	enemy = owner

func enter() -> void:
	_start_charge()

func physics_update(delta: float) -> void:
	var target = PlayerManager.player
	
	match phase:
		0: # Charge
			enemy.velocity.x = move_toward(enemy.velocity.x, 0, 800 * delta)
			timer -= delta
			
			if timer <= 0.0:
				if target:
					jump_dir_x = sign(target.global_position.x - enemy.global_position.x)
					if jump_dir_x == 0:
						jump_dir_x = 1
					enemy.update_facing(jump_dir_x)
				
				_jump()
				
		1: # Air
			# Animationen
			if enemy.velocity.y < 0:
				enemy.get_node("AnimatedSprite2D").play(anim_up)
			else:
				enemy.get_node("AnimatedSprite2D").play(anim_down)
			
			if enemy.is_on_floor() and enemy.velocity.y >= 0:
				phase = 2
				timer = land_duration
				enemy.velocity.x = 0
				enemy.get_node("AnimatedSprite2D").play(anim_land)
				
		2: # Land
			enemy.velocity.x = move_toward(enemy.velocity.x, 0, 800 * delta)
			timer -= delta
			
			if timer <= 0.0:
				if target == null:
					return
				
				var dist = enemy.global_position.distance_to(target.global_position)
				if dist <= attack_range and attack_state and enemy.attack_cooldown_timer <= 0.0:
					enemy.attack_cooldown_timer = enemy.attack_cooldown
					transitioned.emit(self, attack_state.name)
				else:
					_start_charge()

func _start_charge() -> void:
	phase = 0
	timer = charge_duration
	enemy.velocity.x = 0
	enemy.get_node("AnimatedSprite2D").play(anim_charge)

func _jump() -> void:
	phase = 1
	var force_y: float
	var force_x: float
	
	var target = PlayerManager.player
	if target:
		var distance_x = abs(target.global_position.x - enemy.global_position.x)
		force_x = clamp(distance_x, min_jump_x, max_jump_x)
		
		var jump_ratio = (force_x - min_jump_x) / (max_jump_x - min_jump_x)
		force_y = lerp(min_jump_y, max_jump_y, jump_ratio)
		
		var height_diff = enemy.global_position.y - target.global_position.y
		
		if height_diff > 0:
			force_y += height_diff * 1.5
			force_y = min(force_y, max_jump_y * 1.8)
			
	else:
		force_x = randf_range(min_jump_x, max_jump_x)
		force_y = randf_range(min_jump_y, max_jump_y)
	
	enemy.velocity.y = -force_y
	enemy.velocity.x = jump_dir_x * force_x
