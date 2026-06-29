extends CanvasLayer
class_name MainHUD

@onready var debug_ui: Control = $DebugUI

func _ready() -> void:
	# Hide all UIs (Also auch für die zukunft alle hiden)
	if debug_ui:
		debug_ui.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		if debug_ui:
			debug_ui.visible = !debug_ui.visible
