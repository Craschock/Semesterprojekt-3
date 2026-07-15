extends Marker2D
class_name DamageNumber

@onready var label: Label = $Label
@export var y_offset = 50 # In pixel
@export var display_timer = 0.8 # In seconds

func start(amount: int) -> void:
	label.text = str(amount)
	scale = Vector2.ZERO
	
	# Tween to handle animatiom
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Float up
	tween.tween_property(self, "position:y", position.y - y_offset, display_timer).set_ease(Tween.EASE_OUT)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, display_timer).set_ease(Tween.EASE_IN)
	
	# Scale up with bounce
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), display_timer / 2.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Scale down
	tween.tween_property(self, "scale", Vector2.ZERO, display_timer / 2.0).set_delay(display_timer / 2.0).set_ease(Tween.EASE_IN)
	
	# Delete node
	tween.chain().tween_callback(queue_free)
