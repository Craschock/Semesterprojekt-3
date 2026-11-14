extends AttackComponent
class_name WebProjectile

@export_category("Projectile Settings")
## Flying speed of the projectile in pixels per second
@export var speed: float = 160.0
## Maximum time before the projectile despawns automatically
@export var lifetime: float = 4.0
## Whether the projectile rotates to face its flight direction
@export var rotate_with_direction: bool = true

var direction: Vector2 = Vector2.RIGHT
var lifetime_timer: float = 0.0

func _ready() -> void:
	# Call parent AttackComponent._ready() so area_entered is connected
	super._ready()
	lifetime_timer = lifetime
	
	# Connect body_entered to destroy projectile on environment hit
	body_entered.connect(_on_body_entered)
	
	if rotate_with_direction:
		rotation = direction.angle()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	global_position += direction * speed * delta
	
	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		queue_free()

## Override from AttackComponent to destroy projectile on hitting the player
func _on_area_entered(area: Area2D) -> void:
	if not continuous_damage and area is HitboxComponent and area not in hit_entities:
		area.take_hit(self)
		hit_entities.append(area)
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	# Hit a wall or floor tile
	queue_free()
