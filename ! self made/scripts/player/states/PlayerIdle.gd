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
	
	if Input.is_action_just_pressed("jump") and player.can_jump():
		transitioned.emit(self, "jump")
	
	if Input.is_action_just_pressed("attack"):
		transitioned.emit(self, "attack_scratch")
