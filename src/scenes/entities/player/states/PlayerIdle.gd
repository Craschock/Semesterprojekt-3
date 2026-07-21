extends State
class_name PlayerIdle

var player: PlayerMovement

func _ready() -> void:
	player = owner

func enter() -> void:
	# Play sprite animation
	player.get_node("AnimatedSprite2D").play("idle")

func physics_update(delta: float) -> void:
	# Apply friction
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
	
	
	
	
	# Other Transitions
	if Input.get_axis("move_left", "move_right") != 0:
		transitioned.emit(self, "run")
	
	if player.jump_input_buffer_timer > 0.0 and player.can_jump():
		player.jump_input_buffer_timer = 0.0
		transitioned.emit(self, "jumpcharge")
		return
	
	if Input.is_action_just_pressed("attack"):
		transitioned.emit(self, "action")
	
	if Input.is_action_just_pressed("block"):
		transitioned.emit(self, "block")
