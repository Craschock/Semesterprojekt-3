extends State
class_name PlayerJump

var player: PlayerMovement

func _ready() -> void:
	player = owner

func enter() -> void:
	player.velocity.y = player.jump_velocity
	
	# Play sprite animation
	player.get_node("AnimatedSprite2D").play("jump")

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
	
	if Input.is_action_just_pressed("attack"):
		transitioned.emit(self, "attack_scratch")
