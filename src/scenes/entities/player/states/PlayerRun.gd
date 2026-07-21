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
		transitioned.emit(self, "idle")
		sfx_player_run.stop()
	
	# Other Transitions
	if player.jump_input_buffer_timer > 0.0 and player.can_jump():
		player.jump_input_buffer_timer = 0.0
		transitioned.emit(self, "jumpcharge")
		#Izzy here: The running sound stops playing when the player jumps (temporary solution)
		sfx_player_run.stop()
		return
	
	if Input.is_action_just_pressed("attack"):
		transitioned.emit(self, "action")
		#Izzy here: The running sound stops playing when the player attacks (temporary solution)
		sfx_player_run.stop()
	
	if Input.is_action_just_pressed("block"):
		transitioned.emit(self, "block")
