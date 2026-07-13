extends Area2D
class_name AttackComponent


## Amount of Damage an attack deals
@export var damage: int = 10
## Amount of knockback an attack applies
@export var knockback_force: float = 100.0
## Changes attack behavior. True applies damage over attack duration. False applies damage in one instance
@export var continuous_damage: bool = false

# array for "multiple enemies hit"
var hit_entities: Array[Area2D] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if not continuous_damage and area is HitboxComponent and area not in hit_entities:
		area.take_hit(self)
		hit_entities.append(area)

func _physics_process(delta: float) -> void:
	if continuous_damage:
		# Is entity touching?
		for area in get_overlapping_areas():
			if area is HitboxComponent:
				area.take_hit(self)

# call right before attack starts to clear the memory
func clear_hit_list() -> void:
	hit_entities.clear()
