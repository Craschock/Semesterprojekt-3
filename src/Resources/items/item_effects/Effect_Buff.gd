extends ItemEffect
class_name Effect_Buff

enum StatType { MOVE_SPEED, ATTACK_DAMAGE, MAX_HEALTH, ATTACK_SPEED }

@export_category("Buff Settings")
@export var type_stat: StatType = StatType.MOVE_SPEED
@export var multiplier: float = 2.0
@export var duration: float = 5.0

func apply_effect(target: Node) -> void:
	if type_stat == StatType.MOVE_SPEED:
		print("Buffing Move Speed by ", multiplier)
	elif type_stat == StatType.ATTACK_DAMAGE:
		print("Buffing attack damage by ", multiplier)
	
	# TODO expand and implement all cases
