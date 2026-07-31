extends State
class_name EnemyFrogJump

var enemy: BaseEnemy

@export_category("Animation Names")
@export var anim_charge: String = "jump_charge"
@export var anim_up: String = "jump_up"
@export var anim_down: String = "jump_down"
@export var anim_land: String = "jump_land"

@export_category("Jump Settings")
## Minimum jump height
@export var min_jump_y: float = 200.0
## Maximum jump height
@export var max_jump_y: float = 350.0
## Minimum jump length (X-Achse)
@export var min_jump_x: float = 30.0
## Maximum jump length (X-Achse)
@export var max_jump_x: float = 80.0
## How long the enemy charges the jump (in seconds)
@export var charge_duration: float = 0.4
## How long the enemy pauses after landing (in seconds)
@export var land_duration: float = 0.3

@export_category("Patrol Settings")
## Minimum amount of jumps
@export var min_jumps: int = 1
## Maximum amount of jumps
@export var max_jumps: int = 5

@export_category("Transitions")
@export var next_state: State

var phase: int = 0 # 0 = Charge, 1 = Air, 2 = Land
var timer: float = 0.0
var jump_dir_x: int = 1
var jumps_left: int = 0

func _ready() -> void:
	enemy = owner

func enter() -> void:
	jump_dir_x = [-1, 1].pick_random()
	enemy.update_facing(jump_dir_x)
	jumps_left = randi_range(min_jumps, max_jumps)
	
	_start_charge()

func physics_update(delta: float) -> void:
	match phase:
		0: # Charge
			enemy.velocity.x = move_toward(enemy.velocity.x, 0, 800 * delta)
			timer -= delta
			if timer <= 0.0:
				_jump()
				
		1: # Air
			if enemy.velocity.y < 0:
				enemy.get_node("AnimatedSprite2D").play(anim_up)
			else:
				enemy.get_node("AnimatedSprite2D").play(anim_down)
			
			if enemy.is_on_wall():
				enemy.velocity.x = 0
			
			if enemy.is_on_floor() and enemy.velocity.y >= 0:
				phase = 2
				timer = land_duration
				enemy.velocity.x = 0
				enemy.get_node("AnimatedSprite2D").play(anim_land)
				
		2: # Land
			enemy.velocity.x = move_toward(enemy.velocity.x, 0, 800 * delta)
			timer -= delta
			if timer <= 0.0:
				jumps_left -= 1
				if jumps_left > 0:
					_start_charge()
				else:
					if next_state:
						transitioned.emit(self, next_state.name)

func _start_charge() -> void:
	phase = 0
	timer = charge_duration
	enemy.velocity.x = 0
	enemy.get_node("AnimatedSprite2D").play(anim_charge)

func _jump() -> void:
	phase = 1
	var force_y = randf_range(min_jump_y, max_jump_y)
	var force_x = randf_range(min_jump_x, max_jump_x)
	
	enemy.velocity.y = -force_y
	enemy.velocity.x = jump_dir_x * force_x
