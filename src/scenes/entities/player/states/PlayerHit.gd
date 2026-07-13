extends State
class_name PlayerHit

var player: PlayerMovement

func _ready() -> void:
	player = owner

func enter() -> void:
	player.freeze()
	
	if player.state_machine.current_state is PlayerJumpCharge:
		player.was_interrupted_while_charging = true
	else:
		player.was_interrupted_while_charging = false
	
	player.get_node("AnimatedSprite2D").play("hit")

func exit() -> void:
	player.unfreeze()

func physics_update(_delta: float) -> void:
	# Wait for hit animation end, then return jump/idle
	if not player.get_node("AnimatedSprite2D").is_playing():
		if player.was_interrupted_while_charging:
			player.was_interrupted_while_charging = false
			transitioned.emit(self, "jump")
		else:
			transitioned.emit(self, "idle")
