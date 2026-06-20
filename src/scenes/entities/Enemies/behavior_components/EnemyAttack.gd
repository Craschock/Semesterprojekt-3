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

var timer: float = 0.0

func _ready() -> void:
	enemy = owner

func enter() -> void:
	enemy.velocity.x = 0 # Stop movement
	enemy.get_node("AnimatedSprite2D").play(animation_name)
	timer = attack_duration
	
	# Enable damage hitbox and clear memory
	var attack_comp = enemy.get_node_or_null("WeaponPivot/AttackComponent")
	if attack_comp:
		attack_comp.clear_hit_list()
		attack_comp.get_node("CollisionShape2D").set_deferred("disabled", false)

func exit() -> void:
	# Disable damage hitbox
	var attack_comp = enemy.get_node_or_null("WeaponPivot/AttackComponent")
	if attack_comp:
		attack_comp.get_node("CollisionShape2D").set_deferred("disabled", true)

func physics_update(delta: float) -> void:
	timer -= delta
	
	if timer <= 0.0 and next_state:
		transitioned.emit(self, next_state.name)
