extends CanvasLayer
class_name MainHUD

@export var fade_duration: float = 2.0

@onready var BlackoutEffect: ColorRect = $BlackoutEffect
@onready var debug_ui: Control = $DebugUI

func _ready() -> void:
	# Hide all UIs (Also auch für die zukunft alle hiden)
	if debug_ui:
		debug_ui.hide()
	
	# Fade-in
	fadeEffect(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		if debug_ui:
			debug_ui.visible = !debug_ui.visible



# Function for animating the Fade Effect
func fadeEffect(fade_in: bool) -> void:
	var tween = create_tween()
	
	if fade_in:
		BlackoutEffect.visible = true
		BlackoutEffect.modulate.a = 1.0
		
		tween.tween_property(BlackoutEffect, 'modulate:a', 0.0, fade_duration)
		tween.tween_callback(BlackoutEffect.hide)
	else:
		BlackoutEffect.visible = true
		BlackoutEffect.modulate.a = 0.0
		
		tween.tween_property(BlackoutEffect, 'modulate:a', 1.0, fade_duration)
