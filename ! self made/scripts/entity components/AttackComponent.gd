extends Area2D
class_name AttackComponent

@export var damage: int = 10

# array for "multiple enemies hit"
var hit_entities: Array[Area2D] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent and area not in hit_entities:
		area.take_hit(self)
		hit_entities.append(area)

# call right before attack starts to clear the memory
func clear_hit_list() -> void:
	hit_entities.clear()
