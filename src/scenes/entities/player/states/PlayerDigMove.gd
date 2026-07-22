extends State
class_name PlayerDigMove

var player: PlayerMovement

@export_category("State Configuration")
## Name of Idle Animation
@export var animation_name_idle: String = "dig_idle"
## Name of Move Animation
@export var animation_name_move: String = "dig_move"
## Next State Node to transition to
@export var next_state: State

func _ready() -> void:
	player = owner

func enter() -> void:
	player.apply_gravity = false
	player.velocity.y = 0
	player.get_node("AnimatedSprite2D").play(animation_name_idle)

func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		player.update_facing(direction)
		player.velocity.x = move_toward(player.velocity.x, direction * player.speed, player.acceleration * delta)
		player.get_node("AnimatedSprite2D").play(animation_name_move)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
		player.get_node("AnimatedSprite2D").play(animation_name_idle)
		
	#  TODO: Wie kommt man wieder raus?
	if Input.is_action_just_pressed("jump"):
		var target = player.get_dig_out_target()
		
		if target != player.INVALID_POS:
			player.dig_target_position = target
			transitioned.emit(self, "dig_out")
		else:
			# For izzy in the future: kannst ja einen "not possible" sound abspielen
			pass
