extends State
class_name PlayerRun

var player: PlayerMovement
#Izzy here:made player_run a variable
@onready var sfx_player_run: AudioStreamPlayer2D = $"../../sfx_player_run"	


func _ready() -> void:
	player = owner

func enter() -> void:
	# Play sprite animation
	player.get_node("AnimatedSprite2D").play("run")
	#Izzy here: plays run sound as soon as running starts. Problem: Doesn't stop anymore, I am aware
	sfx_player_run.play()

func physics_update(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	
	# Flip Sprite
	player.update_facing(direction)
	
	# Apply movement
	if direction != 0:
		player.velocity.x = move_toward(player.velocity.x, direction * player.speed, player.acceleration * delta)
	else:
		#Izzy here: as animation changes, sound stops
		sfx_player_run.stop()
		transitioned.emit(self, "idle")
	
	
	# Other Transitions
	if player.jump_input_buffer_timer > 0.0 and player.can_jump():
		player.jump_input_buffer_timer = 0.0
		#Izzy here: The running sound stops playing when the player jumps (temporary solution)
		sfx_player_run.stop()
		transitioned.emit(self, "jumpcharge")
		
		return
	
	if player.action_input_buffer_timer > 0.0:
		player.action_input_buffer_timer = 0.0
		#Izzy here: The running sound stops playing when the player attacks (temporary solution)
		sfx_player_run.stop()
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
		
