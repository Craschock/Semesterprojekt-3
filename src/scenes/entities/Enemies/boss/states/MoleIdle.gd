extends State
class_name MoleIdle

var boss: boss_mole

func _ready() -> void:
	boss = owner as boss_mole

func enter() -> void:
	boss.velocity.x = 0.0
	
	if !boss.is_underground:
		boss.get_node("HitboxComponent").is_invincible = false
	
	if boss.is_underground:
		boss.get_node("AnimatedSprite2D").play("U_idle")
	else:
		boss.get_node("AnimatedSprite2D").play("O_idle")

func physics_update(_delta: float) -> void:
	if !boss.is_playerInArena:
		return
	
	if boss.wantsToSwitch_time_timer <= 0.0:
		boss.wantsToSwitch_time_timer = boss.wantsToSwitch_Time
		if boss.is_underground:
			transitioned.emit(self, "moledigout")
		else:
			transitioned.emit(self, "moledigin")
		return
	
	var target = PlayerManager.player
	if target == null:
		return
	
	var dist = boss.global_position.distance_to(target.global_position)
	var in_range = false
	
	if boss.is_underground:
		if dist <= 15.0:
			in_range = true
	else:
		if dist <= boss.attack_range:
			in_range = true
			
	if in_range:
		if boss.attack_cooldown_timer <= 0.0:
			transitioned.emit(self, "moleaction")
	else:
		transitioned.emit(self, "molemove")
