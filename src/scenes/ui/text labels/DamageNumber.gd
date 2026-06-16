extends Marker2D
class_name DamageNumber

@onready var label: Label = $Label
@export var y_offset = 50 # In pixel
@export var display_timer = 0.8 # In seconds

func start(amount: int) -> void:
	label.text = str(amount)
	
	# Tween to handle animatiom
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Float up with offset over 0.8 seconds
	tween.tween_property(self, "position:y", position.y - y_offset, display_timer).set_ease(Tween.EASE_OUT)
	# Fade out (alpha to 0)
	tween.tween_property(self, "modulate:a", 0.0, display_timer).set_ease(Tween.EASE_IN)
	
	# When animations finish, delete node
	tween.chain().tween_callback(queue_free)
