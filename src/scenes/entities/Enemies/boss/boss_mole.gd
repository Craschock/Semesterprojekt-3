extends BaseEnemy
class_name boss_mole

@export_category("Boss Values")
## Random Over/Underground switch timer
@export var wantsToSwitch_Time: float = 20.0
@export var attack_range: float = 50.0

var wantsToSwitch_time_timer: float = 0.0
# Wenn is_underground = true ist, dann sollen nur U_ und keine O_ verwendet werden (Underground)
# Wenn is_underground = false ist, dann sollen nur O_ und kein U_ verwendet werden (Overground)
var is_underground: bool = false
var is_playerInArena: bool = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	if wantsToSwitch_time_timer > 0.0:
		wantsToSwitch_time_timer -= delta
	
	move_and_slide()

# Muss das hier überschreiben, weil die sprites wieder falschrum sind.
func update_facing(direction: float) -> void:
	var sprite = get_node_or_null("AnimatedSprite2D")
	var pivot = get_node_or_null("WeaponPivot")
	
	if direction > 0:
		if sprite: sprite.flip_h = true
		if pivot: pivot.scale.x = 1
	elif direction < 0:
		if sprite: sprite.flip_h = false
		if pivot: pivot.scale.x = -1


func dig_in() -> void:
	is_underground = true

func dig_out() -> void:
	is_underground = false

func die() -> void:
	# Add stuff later
	queue_free()
