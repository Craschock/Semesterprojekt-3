extends State
class_name EnemyChase

var enemy: BaseEnemy

@export_category("Chase Settings")
## Name of Animation to be played from Animated Sprite 2D (String)
@export var animation_name: String = "walk"
## Speed of "chasing" player
@export var chase_speed: float = 60.0

@export_category("Attack Transition")
## How close enemy needs to be
@export var attack_range: float = 25.0
## Attack state
@export var attack_state: State

func _ready() -> void:
	enemy = owner

func enter() -> void:
	enemy.get_node("AnimatedSprite2D").play(animation_name)

func physics_update(_delta: float) -> void:
	var target = PlayerManager.player
	
	if target != null:
		var dist = enemy.global_position.distance_to(target.global_position)
		var dir_x = sign(enemy.global_position.direction_to(target.global_position).x)
		
		if dir_x != 0:
			enemy.update_facing(dir_x)
		
		if dist <= attack_range:
			if attack_state and enemy.attack_cooldown_timer <= 0.0:
				enemy.attack_cooldown_timer = enemy.attack_cooldown
				transitioned.emit(self, attack_state.name)
			else:
				enemy.velocity.x = 0.0
				enemy.get_node("AnimatedSprite2D").play("idle")
		else:
			if dir_x != 0:
				enemy.velocity.x = dir_x * chase_speed
				enemy.get_node("AnimatedSprite2D").play(animation_name)
