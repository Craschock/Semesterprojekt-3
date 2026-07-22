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
	
	if player.action_input_buffer_timer > 0.0:
		player.action_input_buffer_timer = 0.0
		transitioned.emit(self, "action")
	
	if player.block_input_buffer_timer > 0.0:
		player.block_input_buffer_timer = 0.0
		transitioned.emit(self, "block")
	
	if player.dig_input_buffer_timer > 0.0 and player.unlocked_digging:
		var target = player.get_dig_target()
		
		if target != Vector2.INF: # If digging possible
			player.dig_target_position = target
			player.dig_input_buffer_timer = 0.0
			transitioned.emit(self, "dig_in")
		else:
			player.dig_input_buffer_timer = 0.0
			# For izzy in the future: kannst ja einen "not possible" sound abspielen
		
