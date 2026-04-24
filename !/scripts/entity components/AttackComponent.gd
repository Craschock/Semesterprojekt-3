extends Area2D
class_name AttackComponent

@export var damage: int = 10

func _ready() -> void:
	# Connect Godot signal for when another Area2D enters this one
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	# Check if the area we hit is Hitbox
	if area is HitboxComponent:
		area.take_hit(self)
