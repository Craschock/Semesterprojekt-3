extends Area2D
class_name DetectionComponent

signal player_spotted
signal player_lost

# IMPORTANT: Add as a child of Weapon pivot, not root node. Doesn't work otherwise

@export_category("Detection Settings")
## Maximum angle (in degree) enemy can see in front
@export var vision_cone_degrees: float = 90.0
## If player is closer than this, enemy detects instantly
@export var proximity_radius: float = 2.0
## How long enemy remembers player after losing LOS
@export var memory_duration: float = 4.0


@onready var los_raycast: RayCast2D = $RayCast2D

var target: Node2D = null
var is_currently_seeing_player: bool = false
var memory_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	# Off, if no player is in broad phase circle (Ist für optimierung gemacht wegen den vielen gegnern)
	if target == null:
		return
		
	var can_see = _check_line_of_sight()
	
	if can_see:
		memory_timer = memory_duration
		if not is_currently_seeing_player:
			is_currently_seeing_player = true
			player_spotted.emit()
	else:
		if is_currently_seeing_player:
			memory_timer -= delta
			if memory_timer <= 0.0:
				is_currently_seeing_player = false
				player_lost.emit()


func _on_body_entered(body: Node2D) -> void:
	target = body

func _on_body_exited(_body: Node2D) -> void:
	target = null
	if is_currently_seeing_player:
		is_currently_seeing_player = false
		player_lost.emit()

func _check_line_of_sight() -> bool:
	# Aim raycast at the player
	los_raycast.target_position = to_local(target.global_position)
	los_raycast.force_raycast_update()
	
	# Check for walls
	if los_raycast.is_colliding():
		return false
		
	# Check proximity
	var distance_to_target = global_position.distance_to(target.global_position)
	if distance_to_target <= proximity_radius:
		return true
		
	# Check Vision Cone
	var direction_to_target = global_position.direction_to(target.global_position)
	
	# global_transform.x represents forward direction
	var forward_direction = global_transform.x.normalized()
	var angle_to_target = rad_to_deg(forward_direction.angle_to(direction_to_target))
	
	# If angle is less than half, player detected
	if abs(angle_to_target) <= (vision_cone_degrees / 2.0):
		return true
		
	return false
