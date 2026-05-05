extends State
class_name PlayerAttack_Scratch

var player: PlayerMovement

func _ready() -> void:
	player = owner

func enter() -> void:
	# Stop horizontal movement 
	player.velocity.x = 0 
	
	# Play sprite animation
	player.get_node("AnimatedSprite2D").play("attack_scratch")
	
	# Play animation (Logic)
	player.get_node("AnimationPlayer").play("scratch")

func physics_update(_delta: float) -> void:
	# Wait for AnimationPlayer
	if not player.get_node("AnimationPlayer").is_playing():
		transitioned.emit(self, "idle")
