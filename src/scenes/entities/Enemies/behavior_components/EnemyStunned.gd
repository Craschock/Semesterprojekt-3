extends State
class_name EnemyStunned

# TODO: small effect above head too? maybe replace with shader
# tint not working atm TODO: fix
const STUN_FRICTION: float = 800.0
const STUN_TINT_COLOR: Color = Color(1.0, 0.85, 0.35, 1.0)
const NORMAL_TINT_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const SHAKE_SPEED: float = 40.0
const SHAKE_AMPLITUDE: float = 1.5

var enemy: BaseEnemy

@export_category("State Configuration")
## Animation played while stunned ("hit"? or "idle". "hit" has red tint.)
@export var animation_name: String = "hit"
## State to transition to after stun finishes
@export var next_state: State

@export_category("Stun Settings")
## Default stun duration in seconds if no custom duration is passed
@export var default_duration: float = 1.5

var stun_timer: float = 0.0
var custom_duration: float = -1.0
var original_sprite_pos: Vector2 = Vector2.ZERO
var shake_time: float = 0.0

func _ready() -> void:
	enemy = owner

func set_duration(duration: float) -> void:
	custom_duration = duration

func enter() -> void:
	stun_timer = custom_duration if custom_duration > 0.0 else default_duration
	custom_duration = -1.0
	shake_time = 0.0
	
	# Make sure the enemy is vulnerable during the stun window (only if parry also deals dmg)
	if enemy.hitbox_component:
		enemy.hitbox_component.is_invincible = false
	
	if enemy.sprite:
		original_sprite_pos = enemy.sprite.position
		enemy.sprite.modulate = STUN_TINT_COLOR
		if enemy.sprite.sprite_frames and enemy.sprite.sprite_frames.has_animation(animation_name):
			enemy.sprite.play(animation_name)

func exit() -> void:
	if enemy.sprite:
		enemy.sprite.modulate = NORMAL_TINT_COLOR
		enemy.sprite.position = original_sprite_pos

func physics_update(delta: float) -> void:
	if enemy.movement_type == BaseEnemy.MovementType.FLYING:
		enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, STUN_FRICTION * delta)
	else:
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, STUN_FRICTION * delta)
		
	# Subtle dizzy shake so stun is visually obvious even without custom stun sprites. Replace in future
	if enemy.sprite:
		shake_time += delta
		enemy.sprite.position.x = original_sprite_pos.x + sin(shake_time * SHAKE_SPEED) * SHAKE_AMPLITUDE
	
	stun_timer -= delta
	if stun_timer <= 0.0 and next_state:
		transitioned.emit(self, next_state.name)
