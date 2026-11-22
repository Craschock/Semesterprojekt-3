extends AttackComponent
class_name WebProjectile

const ENEMY_ATTACK_LAYER: int = 128
const ENEMY_ATTACK_MASK: int = 17 # World (1) + Player Hitbox (16)

const PLAYER_ATTACK_LAYER: int = 32
const PLAYER_ATTACK_MASK: int = 65 # World (1) + Enemy Hitbox (64)

@export_category("Projectile Settings")
## Flying speed of the projectile in pixels per second
@export var speed: float = 160.0
## Maximum time before the projectile despawns automatically
@export var lifetime: float = 4.0
## Whether the projectile rotates to face its flight direction
@export var rotate_with_direction: bool = true

@export_category("Parry Deflection Settings")
## Speed multiplier applied when the player parries the projectile
@export var deflect_speed_multiplier: float = 1.6
## Damage multiplier applied when deflected back at enemies
@export var deflect_damage_multiplier: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var lifetime_timer: float = 0.0
var is_deflected: bool = false

func _ready() -> void:
	# Call parent AttackComponent._ready() so area_entered is connected
	super._ready()
	lifetime_timer = lifetime
	
	collision_layer = ENEMY_ATTACK_LAYER
	collision_mask = ENEMY_ATTACK_MASK
	
	body_entered.connect(_on_body_entered)
	
	if rotate_with_direction:
		rotation = direction.angle()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	global_position += direction * speed * delta
	
	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not continuous_damage and area is HitboxComponent and area not in hit_entities:
		# If player parries the projectile, deflect it instead of destroying it
		if not is_deflected and area.is_parrying and can_be_parried:
			area.take_hit(self) # Triggers parry_triggered signal on player's hitbox
			deflect()
			return
			
		area.take_hit(self)
		hit_entities.append(area)
		queue_free()

func deflect() -> void:
	is_deflected = true
	
	# Reverse flight direction and update rotation
	direction = -direction
	if rotate_with_direction:
		rotation = direction.angle()
		
	# Boost speed and damage for a rewarding parry payoff
	speed *= deflect_speed_multiplier
	damage = int(round(damage * deflect_damage_multiplier))
	
	# Reset timer and hit list so it can travel all the way
	lifetime_timer = lifetime
	clear_hit_list()
	
	# Switch from Enemy Attack to Player Attack layers
	collision_layer = PLAYER_ATTACK_LAYER
	collision_mask = PLAYER_ATTACK_MASK

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
