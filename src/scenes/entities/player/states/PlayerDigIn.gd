extends State
class_name PlayerDigIn

var player: PlayerMovement

@export_category("State Configuration")
## Name of Animation to be played from Animated Sprite 2D (String)
@export var animation_name: String = "dig_in"

func _ready() -> void:
	player = owner

func enter() -> void:
	player.freeze()
	player.get_node("HitboxComponent").is_invincible = true
	player.get_node("AnimatedSprite2D").play(animation_name)

func exit() -> void:
	player.unfreeze()

func physics_update(_delta: float) -> void:
	if not player.get_node("AnimatedSprite2D").is_playing():
		player.global_position = player.dig_target_position + Vector2(0, 20)
		transitioned.emit(self, "dig_move")
