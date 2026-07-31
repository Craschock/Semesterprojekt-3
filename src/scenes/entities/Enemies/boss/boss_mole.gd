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

signal boss_defeated

func _ready() -> void:
	add_to_group("boss")
	
	health_component.health_depleted.connect(die)
	health_component.health_changed.connect(_on_health_changed)
	
	var apply_gravity = false
	var detection = get_node_or_null("WeaponPivot/DetectionComponent")
	if detection:
		detection.player_spotted.connect(_on_player_spotted)
		detection.player_lost.connect(_on_player_lost)
	
	floor_snap_length = step_height

func _physics_process(delta: float) -> void:
	if apply_gravity and not is_on_floor():
		velocity.y += gravity * delta
	
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	if wantsToSwitch_time_timer > 0.0:
		wantsToSwitch_time_timer -= delta
	
	if is_dead and not state_machine.is_physics_processing():
		velocity.x = move_toward(velocity.x, 0, 800 * delta)
	
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

# Triggers when health hits 0
func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	velocity = Vector2.ZERO
	var col_shape = hitbox_component.get_node_or_null("CollisionShape2D")
	
	if col_shape:
		col_shape.set_deferred("disabled", true)
	
	state_machine.set_physics_process(false)
	
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("hit")
		sprite.pause()
	
	boss_defeated.emit()

func finish_death() -> void:
	state_machine.set_physics_process(true)
	
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play()
		
	loot_drop_component._start_drop()
	state_machine.force_transition("enemydeath")
