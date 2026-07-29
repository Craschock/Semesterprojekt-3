extends Control

class_name MainMenu

@export_category("Animation Values")
## Duration of fade animation
@export var fade_duration: float = 1.0



# ColorRect for creating Fade-in and Fade-Out effects
@onready var BlackoutEffect: ColorRect = $BlackoutEffect
@onready var title: TextureRect = $Title
@onready var button_panel: VBoxContainer = $VBoxContainer
@onready var settings_panel: Control = $SettingsUI
@onready var credits_panel: Control = $CreditsUI

var is_showing_settings: bool = false
var is_showing_credits: bool = false

func _ready() -> void:
	settings_panel.settings_closed.connect(_close_settings)
	
	settings_panel.hide()
	credits_panel.hide()
	
	BlackoutEffect.visible = true
	fadeEffect(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_showing_credits:
			_close_credits()
			return
		
		if is_showing_settings:
			settings_panel.handle_cancel()
			return


# What happens when "Start" is pressed
func _on_b_start_pressed() -> void:
	fadeEffect(false)
	await get_tree().create_timer(fade_duration).timeout
	get_tree().change_scene_to_file("res://src/scenes/menus/final menus/worlds/game.tscn")



# What happens when "Settings" is pressed
func _on_b_settings_pressed() -> void:
	_toggle_ui_elements(false)
	is_showing_settings = true
	settings_panel.show()

func _close_settings() -> void:
	settings_panel.hide()
	is_showing_settings = false
	_toggle_ui_elements(true)



# What happens when "Credits" is pressed
func _on_b_credits_pressed() -> void:
	_toggle_ui_elements(false)
	is_showing_credits = true
	credits_panel.show()

func _on_b_close_credits_pressed() -> void:
	_close_credits()

func _close_credits() -> void:
	credits_panel.hide()
	is_showing_credits = false
	_toggle_ui_elements(true)


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

# Toggle Title and Button on/off
func _toggle_ui_elements(value: bool) -> void:
	if value:
		title.show()
		button_panel.show()
	else:
		title.hide()
		button_panel.hide()
