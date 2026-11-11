extends State
class_name PlayerBlock

var player: PlayerMovement

@export_category("block settings")
## How long the parry is
@export var parry_window: float = 0.67
## Little window where the parry still counts after it ends
@export var grace_period: float = 0.1

var timer: float = 0.0

func _ready() -> void:
	player = owner

func enter() -> void:
	_toggle_parry(true)
	
	# Play animations
	player.get_node("AnimatedSprite2D").play("block")
	
	timer = parry_window

func exit() -> void:
	_toggle_parry(false)

func physics_update(delta: float) -> void:
	timer -= delta
	
	if timer <= 0.0 or not Input.is_action_pressed("block"):
		transitioned.emit(self, "idle")

func _toggle_parry(value: bool) -> void:
	if value:
		player.freeze()
		player.get_node("HitboxComponent").is_parrying = true
		#TODO: add effect?
	else:
		player.unfreeze()
		get_tree().create_timer(grace_period).timeout.connect(func():
			player.get_node("HitboxComponent").is_parrying = false
		)
	
	
