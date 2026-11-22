extends State
class_name FrogTongueAttack

# Disclaimer: wtf.

enum Phase { WINDUP, EXTEND, REEL, RETRACT, RECOVER }

const GROUND_FRICTION: float = 800.0
const ARRIVAL_EPSILON: float = 6.0

var enemy: BaseEnemy

@export_category("Node References")
## Marker2D positioned at the frog mouth
@export var mouth_point: Marker2D
## Line2D used to draw the stretched tongue
@export var tongue_line: Line2D
## TongueTip AttackComponent
@export var tongue_tip: TongueTip
## Attack sound effect
@export var attack_sfx: AudioStreamPlayer2D

@export_category("State Transitions")
## Close-range bite state
@export var bite_followup_state: State
## Chase state to return to
@export var next_state: State

@export_category("Animation Settings")
## Animation played during the tongue attack
@export var animation_name: String = "attack_lick"
## Delay before the tongue shoots out
@export var windup_duration: float = 0.25
## Brief recovery pause if tongue misses
@export var miss_recover_duration: float = 0.35

@export_category("Tongue Physics")
## Speed the tongue shoots outward (px/s)
@export var extend_speed: float = 280.0
## Speed the tongue pulls back when empty (px/s)
@export var retract_speed: float = 340.0
## Speed the player is reeled toward the frog (px/s)
@export var reel_player_speed: float = 240.0
## Maximum reach of the tongue in pixels
@export var max_tongue_length: float = 150.0
## How close to the frog mouth the player is released for the bite combo
@export var release_distance: float = 24.0
## Max time allowed for reeling before forcing release
@export var max_reel_duration: float = 0.85
## Aim offset to target player torso instead of feet
@export var player_aim_offset: Vector2 = Vector2(0.0, -10.0)

var phase: Phase = Phase.WINDUP
var timer: float = 0.0
var shoot_direction: Vector2 = Vector2.RIGHT
var tip_world_pos: Vector2 = Vector2.ZERO
var hooked_player: PlayerMovement = null

func _ready() -> void:
	enemy = owner
	if tongue_tip:
		tongue_tip.player_hooked.connect(_on_player_hooked)
		tongue_tip.wall_hit.connect(_on_wall_hit)
		tongue_tip.parried.connect(_on_tongue_parried)
		tongue_tip.top_level = true
	if tongue_line:
		tongue_line.hide()

func enter() -> void:
	phase = Phase.WINDUP
	timer = windup_duration
	hooked_player = null
	enemy.velocity.x = 0.0
	
	# Face player and lock aim direction
	var target = PlayerManager.player
	if target:
		var mouth_pos: Vector2 = _get_mouth_pos()
		var target_pos: Vector2 = target.global_position + player_aim_offset
		var dir_x: float = sign(target_pos.x - enemy.global_position.x)
		if dir_x != 0.0:
			enemy.update_facing(dir_x)
		mouth_pos = _get_mouth_pos()
		shoot_direction = mouth_pos.direction_to(target_pos)
		
	if enemy.sprite:
		enemy.sprite.play(animation_name)
	if attack_sfx:
		attack_sfx.play()
		
	if tongue_tip:
		tongue_tip.set_active(false)
		tongue_tip.is_extending = false
		tongue_tip.hide()
	if tongue_line:
		tongue_line.hide()

func exit() -> void:
	if hooked_player and is_instance_valid(hooked_player):
		hooked_player.stop_pull()
	hooked_player = null
	
	if tongue_tip:
		tongue_tip.is_extending = false
		tongue_tip.set_active(false)
		tongue_tip.hide()
	if tongue_line:
		tongue_line.hide()

func physics_update(delta: float) -> void:
	enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, GROUND_FRICTION * delta)
	var mouth_pos: Vector2 = _get_mouth_pos()
	
	match phase:
		Phase.WINDUP:
			timer -= delta
			if timer <= 0.0:
				_start_extend(mouth_pos)
				
		Phase.EXTEND:
			tip_world_pos += shoot_direction * extend_speed * delta
			_sync_tongue_visuals(mouth_pos, tip_world_pos)
			
			if mouth_pos.distance_to(tip_world_pos) >= max_tongue_length:
				_start_retract()
				
		Phase.REEL:
			if hooked_player == null or not is_instance_valid(hooked_player) or not hooked_player.is_pulled:
				# Player arrived or was released
				_finish_reel(mouth_pos)
				return
				
			tip_world_pos = hooked_player.global_position + player_aim_offset
			_sync_tongue_visuals(mouth_pos, tip_world_pos)
			
		Phase.RETRACT:
			tip_world_pos = tip_world_pos.move_toward(mouth_pos, retract_speed * delta)
			_sync_tongue_visuals(mouth_pos, tip_world_pos)
			
			if tip_world_pos.distance_to(mouth_pos) <= ARRIVAL_EPSILON:
				phase = Phase.RECOVER
				timer = miss_recover_duration
				if tongue_line:
					tongue_line.hide()
				if tongue_tip:
					tongue_tip.hide()
					
		Phase.RECOVER:
			timer -= delta
			if timer <= 0.0 and next_state:
				transitioned.emit(self, next_state.name)

func _start_extend(mouth_pos: Vector2) -> void:
	phase = Phase.EXTEND
	tip_world_pos = mouth_pos
	
	if tongue_tip:
		tongue_tip.global_position = tip_world_pos
		tongue_tip.show()
		tongue_tip.is_extending = true
		tongue_tip.set_active(true)
	if tongue_line:
		tongue_line.show()
		_sync_tongue_visuals(mouth_pos, tip_world_pos)

func _start_retract() -> void:
	phase = Phase.RETRACT
	if tongue_tip:
		tongue_tip.is_extending = false
		tongue_tip.set_active(false)

func _on_player_hooked(player: PlayerMovement) -> void:
	if phase != Phase.EXTEND:
		return
	phase = Phase.REEL
	hooked_player = player
	player.start_pull(mouth_point if mouth_point else enemy, reel_player_speed, release_distance, max_reel_duration)

func _on_wall_hit() -> void:
	if phase == Phase.EXTEND:
		_start_retract()

func _on_tongue_parried(_defender: Node) -> void:
	# BaseEnemy.on_attack_parried() will transition to EnemyStunned
	# which calls exit() and hides tongue
	if tongue_tip:
		tongue_tip.is_extending = false
		tongue_tip.set_active(false)

func _finish_reel(mouth_pos: Vector2) -> void:
	var dist_to_player: float = INF
	if PlayerManager.player:
		dist_to_player = mouth_pos.distance_to(PlayerManager.player.global_position)
		
	if bite_followup_state and dist_to_player <= release_distance + 18.0:
		enemy.attack_cooldown_timer = enemy.attack_cooldown
		transitioned.emit(self, bite_followup_state.name)
	elif next_state:
		transitioned.emit(self, next_state.name)

func _get_mouth_pos() -> Vector2:
	return mouth_point.global_position if mouth_point else enemy.global_position

func _sync_tongue_visuals(mouth_pos: Vector2, tip_pos: Vector2) -> void:
	if tongue_tip:
		tongue_tip.global_position = tip_pos
	if tongue_line:
		tongue_line.clear_points()
		tongue_line.add_point(tongue_line.to_local(mouth_pos))
		tongue_line.add_point(tongue_line.to_local(tip_pos))
