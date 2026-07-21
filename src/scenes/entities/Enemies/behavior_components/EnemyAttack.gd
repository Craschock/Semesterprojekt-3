extends State
class_name EnemyAttack

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of Animation to be played from Animated Sprite 2D (String)
@export var animation_name: String = "idle"
## Next State Node to transition to
@export var next_state: State

@export_category("Attack Settings")
## How long attack lasts. Temp for future animation player
@export var attack_duration: float = 0.5
## Attack Component
@export var attack_component: AttackComponent

var timer: float = 0.0
#Izzy here: establishing the attack sound as a variable
@onready var sfx_enemy_attack: AudioStreamPlayer2D = $"../../sfx_enemy_attack"

func _ready() -> void:
	enemy = owner

func enter() -> void:
	enemy.velocity.x = 0 # Stop movement
	enemy.get_node("AnimatedSprite2D").play(animation_name)
	timer = attack_duration
	#Izzy here: if enemy has sound, it will be played here
	if sfx_enemy_attack:
		sfx_enemy_attack.play()

	# Enable damage hitbox and clear memory
	if attack_component:
		attack_component.clear_hit_list()
		_set_hitbox_disabled(false)

func exit() -> void:
	# Disable damage hitbox
	_set_hitbox_disabled(true)

func physics_update(delta: float) -> void:
	timer -= delta
	
	if timer <= 0.0 and next_state:
		transitioned.emit(self, next_state.name)

func _set_hitbox_disabled(is_disabled: bool) -> void:
	if attack_component:
		for child in attack_component.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", is_disabled)
