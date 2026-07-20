extends State
class_name PlayerDeath

var player: PlayerMovement
#Izzy here: making player_death a variable
@onready var sfx_player_death: AudioStreamPlayer2D = $"../../sfx_player_death"	

func _ready() -> void:
	player = owner

func enter() -> void:
	player.freeze()
	
	# Turn off the hitbox so dead bodies block attacks
	player.get_node("HitboxComponent/CollisionShape2D").set_deferred("disabled", true)
	
	player.get_node("AnimatedSprite2D").play("death")
	#Izzy here: is supposed to play sound upon death
	sfx_player_death.play()
	
	# Reload the game after 5 seconds, change later
	get_tree().create_timer(5).timeout.connect(reload_game)

func reload_game() -> void:
	get_tree().reload_current_scene()
