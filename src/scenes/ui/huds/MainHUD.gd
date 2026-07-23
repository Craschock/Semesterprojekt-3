extends CanvasLayer
class_name MainHUD

@export var fade_duration: float = 2.0

@onready var BlackoutEffect: ColorRect = $BlackoutEffect
@onready var debug_ui: Control = $DebugUI
@onready var healthBar: TextureProgressBar = $PlayerUI/TextureProgressBar

var player: PlayerMovement

func _ready() -> void:
	# Hide all UIs (Also auch für die zukunft alle hiden)
	if debug_ui:
		debug_ui.hide()
	
	await get_tree().process_frame
	player = PlayerManager.player
	
	if player:
		player.health_component.health_changed.connect(drawHealth)
	
	
	
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

# TODO: Change healthbar texture. Currently 0-10 and 90-100 
# values are lost due to Healthbar progressbar texture length
func drawHealth(_current: int, _max: int) -> void:
	healthBar.value = (float(_current) / float(_max)) * 100
