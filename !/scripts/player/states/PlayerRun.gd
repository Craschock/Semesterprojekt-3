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
	
	# Flip logic
	if direction > 0:
		player.get_node("WeaponPivot").scale.x = 1
		player.get_node("AnimatedSprite2D").flip_h = false
	elif direction < 0:
		player.get_node("WeaponPivot").scale.x = -1
		player.get_node("AnimatedSprite2D").flip_h = true
	
	# Apply movement
	if direction != 0:
		player.velocity.x = move_toward(player.velocity.x, direction * player.speed, player.acceleration * delta)
	else:
		transitioned.emit(self, "idle")
		
		
		
	# Other Transitions
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		transitioned.emit(self, "jump")
	
	if Input.is_action_just_pressed("attack"):
		transitioned.emit(self, "attack_scratch")
