extends State
class_name BatDiveAttack

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of Animation to be played from Animated Sprite 2D (String)
@export var animation_name: String = "attack"
## Next State Node to transition to (EnemyFlyingChase)
@export var next_state: State
## Attack Component
@export var attack_component: AttackComponent

@export_category("Dive Settings")
## "Hold" frames before bat attacks (in seconds)
@export var windup_time: float = 0.4
## Move Speed of attack
@export var dive_speed: float = 300.0
## How long bat needs to "recover" after attack (in seconds)
@export var recover_time: float = 0.5
## Extra If bat alls die Fledermaus das Ziel verfehlt und ins Leere fliegt
@export var max_dive_time: float = .75
## Offset to aim for body/head instead of feet
@export var target_offset: Vector2 = Vector2(0, -15)

var state_timer: float = 0.0
var target_pos: Vector2 = Vector2.ZERO
var dive_direction: Vector2 = Vector2.ZERO
var phase: int = 0 # 0 = Windup, 1 = Dive, 2 = Recover

@onready var sfx_enemy_attack: AudioStreamPlayer2D = $"../../sfx_enemy_attack"

func _ready() -> void:
	enemy = owner

func enter() -> void:
	phase = 0
	state_timer = windup_time
	enemy.velocity = Vector2.ZERO
	enemy.get_node("AnimatedSprite2D").play(animation_name)
	
	if sfx_enemy_attack:
		sfx_enemy_attack.play()
	
	var target = PlayerManager.player
	if target:
		target_pos = target.global_position + target_offset
		dive_direction = enemy.global_position.direction_to(target_pos)
		
		if dive_direction.x != 0:
			enemy.update_facing(sign(dive_direction.x))

func exit() -> void:
	_set_hitbox_disabled(true)

func physics_update(delta: float) -> void:
	state_timer -= delta
	
	if phase == 0: # WINDUP
		enemy.velocity = Vector2.ZERO
		if state_timer <= 0.0:
			phase = 1
			state_timer = max_dive_time
			
			if attack_component:
				attack_component.clear_hit_list()
				_set_hitbox_disabled(false)
			
	elif phase == 1: # DIVE
		enemy.velocity = dive_direction * dive_speed
		
		if enemy.get_slide_collision_count() > 0 or state_timer <= 0.0:
			phase = 2
			state_timer = recover_time
			enemy.velocity = Vector2.ZERO
			
			if attack_component:
				_set_hitbox_disabled(true)
				
	elif phase == 2:
		enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, 800 * delta)
		
		if state_timer <= 0.0:
			if next_state:
				transitioned.emit(self, next_state.name)

func _set_hitbox_disabled(is_disabled: bool) -> void:
	if attack_component:
		for child in attack_component.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", is_disabled)
