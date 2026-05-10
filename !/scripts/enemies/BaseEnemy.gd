extends CharacterBody2D
class_name BaseEnemy

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	# Connect health depleted signal
	health_component.health_depleted.connect(die)
	health_component.health_changed.connect(_on_health_changed)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		
	move_and_slide()


func _on_health_changed(_current: int, _max: int) -> void:
	if has_node("StateMachine"):
		$StateMachine.force_transition("hit")

# Triggers when health hits 0
func die() -> void:
	# Add stuff later
	queue_free()
