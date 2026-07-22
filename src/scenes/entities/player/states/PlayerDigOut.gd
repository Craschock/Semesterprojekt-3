extends State
class_name PlayerDigOut

var player: PlayerMovement

@export_category("State Configuration")
## Name of Animation to be played from Animated Sprite 2D (String)
@export var animation_name: String = "dig_out"

func _ready() -> void:
	player = owner

func enter() -> void:
	player.freeze()
	player.global_position = player.dig_target_position
	player.get_node("AnimatedSprite2D").play(animation_name)

func exit() -> void:
	player.get_node("HitboxComponent").is_invincible = false
	player.velocity.y = 0
	player.apply_gravity = true
	player.unfreeze()

func physics_update(_delta: float) -> void:
	if not player.get_node("AnimatedSprite2D").is_playing():
		transitioned.emit(self, "idle")
