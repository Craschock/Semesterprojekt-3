extends State
class_name PlayerDeath

var player: PlayerMovement

func _ready() -> void:
	player = owner

func enter() -> void:
	player.freeze()
	
	# Turn off the hitbox so dead bodies block attacks
	player.get_node("HitboxComponent/Hitbox").set_deferred("disabled", true)
	
	player.get_node("AnimatedSprite2D").play("death")
	
	# Reload the game after 1.5 seconds, change later
	get_tree().create_timer(1.5).timeout.connect(reload_game)

func reload_game() -> void:
	get_tree().reload_current_scene()
