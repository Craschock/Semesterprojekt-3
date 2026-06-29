extends State
class_name PlayerRun

var player: PlayerMovement

func _ready() -> void:
	player = owner

func enter() -> void:
	# Play sprite animation
	player.get_node("AnimatedSprite2D").play("run")

func physics_update(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	# Flip Sprite
	player.update_facing(direction)
	
	# Apply movement
	if direction != 0:
		player.velocity.x = move_toward(player.velocity.x, direction * player.speed, player.acceleration * delta)
	else:
		transitioned.emit(self, "idle")
	
	
	
	
	
	# Other Transitions
	if Input.is_action_just_pressed("jump") and player.can_jump():
		transitioned.emit(self, "jumpcharge")
	
	if Input.is_action_just_pressed("attack"):
		transitioned.emit(self, "action")
