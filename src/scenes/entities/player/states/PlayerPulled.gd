extends State
class_name PlayerPulled

const MIN_PROGRESS_SPEED: float = 12.0
const STUCK_RELEASE_TIME: float = 0.25

var player: PlayerMovement

@export_category("State Configuration")
## Animation played while being reeled in
@export var animation_name: String = "hit"

var pull_target: Node2D = null
var pull_speed: float = 220.0
var stop_distance: float = 20.0
var max_duration_timer: float = 0.0
var stuck_timer: float = 0.0

func _ready() -> void:
	player = owner

func setup_pull(target: Node2D, speed: float, stop_dist: float, max_duration: float) -> void:
	pull_target = target
	pull_speed = speed
	stop_distance = stop_dist
	max_duration_timer = max_duration
	stuck_timer = 0.0

func enter() -> void:
	player.is_pulled = true
	player.allow_input(false)
	
	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play(animation_name)

func exit() -> void:
	player.is_pulled = false
	player.allow_input(true)
	player.velocity = Vector2.ZERO
	pull_target = null

func physics_update(delta: float) -> void:
	max_duration_timer -= delta
	
	if pull_target == null or not is_instance_valid(pull_target) or max_duration_timer <= 0.0:
		transitioned.emit(self, "idle")
		return
		
	var to_target: Vector2 = pull_target.global_position - player.global_position
	var dist: float = to_target.length()
	
	if dist <= stop_distance:
		transitioned.emit(self, "idle")
		return
		
	var dir: Vector2 = to_target.normalized()
	player.velocity = dir * pull_speed
	
	if dir.x != 0.0:
		player.update_facing(dir.x)
	
	# Safety check: if snagged on a rock corner, release so player never gets stuck (This part only works if you truly believe in it)
	if player.get_real_velocity().length() < MIN_PROGRESS_SPEED:
		stuck_timer += delta
		if stuck_timer >= STUCK_RELEASE_TIME:
			transitioned.emit(self, "idle")
	else:
		stuck_timer = 0.0
