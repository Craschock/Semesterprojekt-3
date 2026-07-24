extends Label
class_name TextBubble

signal dialogue_finished

@export_category("Animation Settings")
@export var char_delay: float = 0.05 

# TODO: create own textbubble scene

func _ready() -> void:
	hide()
	text = ""

func play_text(content: String, duration: float = 3.0) -> void:
	show()
	text = ""
	
	for i in range(content.length()):
		text += content[i]
		
		if char_delay > 0:
			await get_tree().create_timer(char_delay).timeout
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
	
	hide()
	dialogue_finished.emit()
