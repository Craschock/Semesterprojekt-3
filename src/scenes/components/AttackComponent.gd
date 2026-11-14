extends Area2D
class_name AttackComponent

@export_category("Attack Stats")
## Amount of damage an attack deals
@export var damage: int = 10
## Amount of knockback force an attack applies
@export var knockback_force: float = 100.0

@export_category("Attack Behavior")
## True applies damage continuously while overlapping. False applies damage once per swing.
@export var continuous_damage: bool = false
## Can this attack be parried by the player?
@export var can_be_parried: bool = true

# Stores hitboxes already damaged during a single attack
var hit_entities: Array[Area2D] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(_delta: float) -> void:
	if continuous_damage:
		for area in get_overlapping_areas():
			if area is HitboxComponent:
				area.take_hit(self)

func _on_area_entered(area: Area2D) -> void:
	if not continuous_damage and area is HitboxComponent and area not in hit_entities:
		area.take_hit(self)
		hit_entities.append(area)

## Clear memory of hit entities right before a new attack starts
func clear_hit_list() -> void:
	hit_entities.clear()

## Enables or disables all collision shapes under this AttackComponent.
## Can be called from State scripts OR directly via an AnimationPlayer
func set_active(is_active: bool) -> void:
	if is_active:
		clear_hit_list()
		
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", not is_active)
