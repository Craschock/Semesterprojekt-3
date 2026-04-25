extends State
class_name PlayerRun

var player: PlayerMovement

func _ready() -> void:
	player = owner

func physics_update(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	# Apply movement
	if direction != 0:
		player.velocity.x = move_toward(player.velocity.x, direction * player.speed, player.acceleration * delta)
	else:
		transitioned.emit(self, "idle")
		
		
		
		
	# Other Transitions
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		transitioned.emit(self, "jump")
