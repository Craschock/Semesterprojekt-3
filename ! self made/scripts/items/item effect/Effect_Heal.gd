extends ItemEffect
class_name Effect_Heal

@export_category("Healing Settings")
@export var heal_amount: int = 20
@export var isRegen: bool = false

func apply_effect(target: Node) -> void:
	var health = target.get_node_or_null("HealthComponent")
	if health:
		if !isRegen:
			health.heal(heal_amount)
			print("Healed for ", heal_amount, " HP")
		else:
			print("Healing for ", heal_amount, " over X seconds")
			return
			# TODO add regen logic later
