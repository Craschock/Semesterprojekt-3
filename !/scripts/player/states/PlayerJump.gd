extends State
class_name PlayerJump

var player: PlayerMovement

func _ready() -> void:
	player = owner

func enter() -> void:
	player.velocity.y = player.jump_velocity

func physics_update(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	# Allow horizontal movement in mid-air
	if direction != 0:
		player.velocity.x = move_toward(player.velocity.x, direction * player.speed, player.acceleration * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
		
		
		
		
	# Other Transitions
	if player.is_on_floor():
		if direction != 0:
			transitioned.emit(self, "run")
		else:
			transitioned.emit(self, "idle")
