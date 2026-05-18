extends State
class_name PlayerHit

var player: PlayerMovement

func _ready() -> void:
	player = owner

func enter() -> void:
	player.freeze()
	player.get_node("AnimatedSprite2D").play("hit")

func exit() -> void:
	player.unfreeze()

func physics_update(_delta: float) -> void:
	# Wait for hit animation end, then return idle
	if not player.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, "idle")
