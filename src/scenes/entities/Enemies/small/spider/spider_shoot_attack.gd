extends State
class_name SpiderShootAttack

var enemy: BaseEnemy

@export_category("State Configuration")
## Animation to play when shooting
@export var animation_name: String = "attack_string"
## State to return to after shooting
@export var next_state: State

@export_category("Projectile Settings")
## Projectile Scene
@export var projectile_scene: PackedScene
## Marker2D under WeaponPivot where projectile spawns
@export var spawn_point: Marker2D
## Animation frame on which the projectile is fired (attack_string has 10 frames)
@export var shoot_frame: int = 5
## Offset added to player position so spider aims at the player's body instead of feet
@export var aim_offset: Vector2 = Vector2(0.0, -10.0)

var has_shot: bool = false

func _ready() -> void:
	enemy = owner

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	has_shot = false
	
	var sprite: AnimatedSprite2D = enemy.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play(animation_name)
		

func physics_update(_delta: float) -> void:
	enemy.velocity = Vector2.ZERO
	
	var sprite: AnimatedSprite2D = enemy.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
		
	# Face player before shooting
	var target = PlayerManager.player
	if target and not has_shot:
		var dir_x = sign(target.global_position.x - enemy.global_position.x)
		if dir_x != 0:
			enemy.update_facing(dir_x)
	
	# Spawn projectile on the exact animation frame
	if not has_shot and sprite.frame >= shoot_frame:
		has_shot = true
		_fire_projectile()
		
	# Return to idle when animation finishes
	if not sprite.is_playing():
		if next_state:
			transitioned.emit(self, next_state.name)

func _fire_projectile() -> void:
	if not projectile_scene:
		push_warning("SpiderShootAttack: No projectile_scene assigned!")
		return
		
	var target = PlayerManager.player
	if target == null:
		return
		
	var proj = projectile_scene.instantiate() as WebProjectile
	var spawn_pos = spawn_point.global_position if spawn_point else enemy.global_position
	var target_pos = target.global_position + aim_offset
	
	proj.global_position = spawn_pos
	proj.direction = spawn_pos.direction_to(target_pos)
	
	get_tree().current_scene.add_child(proj)
