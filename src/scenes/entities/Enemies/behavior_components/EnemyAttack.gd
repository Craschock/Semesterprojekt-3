extends State
class_name EnemyAttack

var enemy: BaseEnemy

@export_category("State Configuration")
## Name of Animation to play (Fallback: checks AnimationPlayer first, then AnimatedSprite2D)
@export var animation_name: String = "idle"
## Next State Node to transition to after attack finishes
@export var next_state: State

@export_category("Attack Settings")
## AttackComponent to enable/disable.  keyframe set_active()
@export var attack_component: AttackComponent
## Fallback duration if not using AnimationPlayer
@export var attack_duration: float = 0.5
## If true, automatically enables hitbox on enter() and disables on exit(). If AnimationPlayer: keyframe set false
@export var auto_toggle_hitbox: bool = true
## Optional sound effect to play when attack starts
@export var attack_sfx: AudioStreamPlayer2D

var timer: float = 0.0
var using_anim_player: bool = false

func _ready() -> void:
	enemy = owner
	
	# Fallback for izzy stuff: finding sfx_enemy_attack on root or self if not linked in Inspector
	if not attack_sfx:
		attack_sfx = get_node_or_null("sfx_enemy_attack")
	if not attack_sfx and enemy:
		attack_sfx = enemy.get_node_or_null("sfx_enemy_attack")

func enter() -> void:
	enemy.velocity.x = 0.0
	timer = attack_duration
	
	if attack_sfx:
		attack_sfx.play()
		
	if auto_toggle_hitbox and attack_component:
		attack_component.set_active(true)
		
	# Fallback: Play via AnimationPlayer if available, otherwise AnimatedSprite2D
	if enemy.animation_player and enemy.animation_player.has_animation(animation_name):
		using_anim_player = true
		enemy.animation_player.play(animation_name)
	else:
		using_anim_player = false
		if enemy.sprite:
			enemy.sprite.play(animation_name)

func exit() -> void:
	# Always force-disable hitbox on exit in case enemy was staggered mid-swing
	if attack_component:
		attack_component.set_active(false)

func physics_update(delta: float) -> void:
	if using_anim_player:
		if not enemy.animation_player.is_playing() and next_state:
			transitioned.emit(self, next_state.name)
	else:
		timer -= delta
		if timer <= 0.0 and next_state:
			transitioned.emit(self, next_state.name)
