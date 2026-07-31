extends Label
class_name TextBubble

signal dialogue_finished

@export_category("Animation Settings")
@export var char_delay: float = 0.05 

var _is_skipping: bool = false

# TODO: create own textbubble scene

func _ready() -> void:
	hide()
	text = ""

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_is_skipping = true

func play_text(content: String, duration: float = 3.0) -> void:
	show()
	text = ""
	_is_skipping = false
	
	for i in range(content.length()):
		if _is_skipping:
			text = content
			break
			
		text += content[i]
		
		if char_delay > 0:
			await get_tree().create_timer(char_delay).timeout
	
	_is_skipping = false
	
	if duration > 0:
		var time_passed: float = 0.0
		while time_passed < duration:
			if _is_skipping:
				break
			
			await get_tree().process_frame
			time_passed += get_process_delta_time()
	
	hide()
	dialogue_finished.emit()
