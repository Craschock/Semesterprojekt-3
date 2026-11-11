extends State
class_name PlayerJump

var player: PlayerMovement
var is_landing: bool = false


func _ready() -> void:
	player = owner

func enter() -> void:
	is_landing = false
	
	# Calculate how close charge is to max time (0.0 to 1.0)
	var charge_ratio = clamp(player.current_jump_charge / player.time_to_max_charge, 0.0, 1.0)
	
	player.velocity.y = lerpf(player.min_jump_velocity, player.max_jump_velocity, charge_ratio)
	player.consume_jump()

func physics_update(delta: float) -> void:
	var sprite = player.get_node("AnimatedSprite2D")
	var direction := Input.get_axis("move_left", "move_right")
	
	# What happens after landing
	if is_landing:
		if direction != 0:
			transitioned.emit(self, "run")
		elif not sprite.is_playing() or sprite.animation != "jump_landing":
			transitioned.emit(self, "idle")
		return
	
	# Wall jump and double jump
	if Input.is_action_just_pressed("jump"):
		# Wall jump Check
		if player.is_on_wall() and direction != 0:
			var wall_normal = player.get_wall_normal()
			
			# Push player away from wall
			player.velocity.y = player.wall_jump_velocity.y
			player.velocity.x = wall_normal.x * player.wall_jump_velocity.x
			
			player.update_facing(wall_normal.x)
			
			# TODO: decide to reset air jumps?
			player.current_air_jumps = 0
			
		# Double jump check
		elif player.current_air_jumps < player.max_air_jumps:
			player.current_air_jumps += 1
			player.velocity.y = player.double_jump_velocity
	
	
	
	# Movement mid-air (left/right)
	if direction != 0:
		player.velocity.x = move_toward(player.velocity.x, direction * player.speed, player.acceleration * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)
	
	player.update_facing(direction)
	
	# TODO: Refactor into player.update_facing
	# velocity.y is negative when goiong up, and positive when falling
	if player.velocity.y < 0:
		sprite.play("jump_up")
	else:
		sprite.play("jump_down")
		
	# Trigger landing if velocity.y >= 0 and touched the floor
	if player.is_on_floor() and player.velocity.y >= 0:
		is_landing = true
		player.velocity.x = 0
		sprite.play("jump_landing")
	
	# Attack Transition
	if player.action_input_buffer_timer > 0.0:
		player.action_input_buffer_timer = 0.0
		transitioned.emit(self, "action")
	
	if player.is_on_floor() and player.block_input_buffer_timer > 0.0:
		player.block_input_buffer_timer = 0.0
		transitioned.emit(self, "block")
