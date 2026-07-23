extends State
class_name MoleMove

var boss: boss_mole

@export var move_speed_o: float = 60.0
@export var move_speed_u: float = 90.0

func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	if !boss.is_underground:
		boss.get_node("HitboxComponent").is_invincible = false
	
	if boss.is_underground:
		boss.get_node("AnimatedSprite2D").play("U_move")
	else:
		boss.get_node("AnimatedSprite2D").play("O_move")

func physics_update(_delta: float) -> void:
	var target = PlayerManager.player
	if target == null:
		transitioned.emit(self, "moleidle")
		return
	
	var dist = boss.global_position.distance_to(target.global_position)
	var dir_x = sign(boss.global_position.direction_to(target.global_position).x)
	
	if dir_x != 0:
		boss.update_facing(dir_x)
	
	if boss.is_underground:
		if dist <= 12.5:
			transitioned.emit(self, "moleidle")
		else:
			boss.velocity.x = dir_x * move_speed_u
	else:
		if dist <= boss.attack_range:
			transitioned.emit(self, "moleidle")
		else:
			boss.velocity.x = dir_x * move_speed_o
