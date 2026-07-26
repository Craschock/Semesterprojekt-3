extends Control

class_name MainMenu

@export_category("Animation Values")
## Duration of fade animation
@export var fade_duration: float = 1.0



# ColorRect for creating Fade-in and Fade-Out effects
@onready var BlackoutEffect: ColorRect = $BlackoutEffect


func _ready() -> void:
	BlackoutEffect.visible = true
	fadeEffect(true)



# What happens when "Start" is pressed
func _on_b_start_pressed() -> void:
	fadeEffect(false)
	await get_tree().create_timer(fade_duration).timeout
	get_tree().change_scene_to_file("res://src/scenes/menus/final menus/worlds/game.tscn")



# What happens when "Settings" is pressed
func _on_b_settings_pressed() -> void:
	pass # Replace with function body.



# What happens when "Credits" is pressed
func _on_b_credits_pressed() -> void:
	pass # Replace with function body.



# What happens when "Quit" is pressed
func _on_b_quit_pressed() -> void:
	get_tree().quit()



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
