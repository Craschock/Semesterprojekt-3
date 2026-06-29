extends State
class_name PlayerJumpCharge

var player: PlayerMovement

func _ready() -> void:
	player = owner

func enter() -> void:
	player.current_jump_charge = 0.0
	player.get_node("AnimatedSprite2D").play("jump_charging")

func physics_update(delta: float) -> void:
	# Apply friction so player stops
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
	
	# Increase charge timer
	player.current_jump_charge += delta
	var charge_ratio = player.current_jump_charge / player.time_to_max_charge
	
	# Transition to jump when button is released OR max charge is reached
	if Input.is_action_just_released("jump") or charge_ratio >= 1.0:
		transitioned.emit(self, "jump")
