extends State
class_name PlayerBlock

var player: PlayerMovement

func _ready() -> void:
	player = owner

func enter() -> void:
	player.freeze()
	
	# Play animations
	player.get_node("AnimatedSprite2D").play("block")
	
	player.get_node("HitboxComponent").is_invincible = true

func exit() -> void:
	player.unfreeze()
	
	player.get_node("HitboxComponent").is_invincible = false

func physics_update(_delta: float) -> void:
	if not Input.is_action_pressed("block"):
		transitioned.emit(self, "idle")
