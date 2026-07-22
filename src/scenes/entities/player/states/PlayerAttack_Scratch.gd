extends State
class_name PlayerAttack_Scratch

var player: PlayerMovement
#Izzy here: made player_attack a variable
@onready var sfx_player_attack: AudioStreamPlayer2D = $"../../sfx_player_attack"

func _ready() -> void:
	player = owner

func enter() -> void:
	if player.velocity.y == 0:
		player.freeze()
	
	#Izzy here: plays sound before animation plays, for timing
	sfx_player_attack.play()
	
	# Play animations
	player.get_node("AnimatedSprite2D").play("attack_scratch")
	player.get_node("AnimationPlayer").play("scratch")


func exit() -> void:
	if player.is_frozen:
		player.unfreeze()

func physics_update(_delta: float) -> void:
	# Wait for AnimationPlayer
	if not player.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, "idle")
