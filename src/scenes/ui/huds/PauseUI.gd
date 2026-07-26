extends Control
class_name PauseUI

# Buttons
@onready var start_btn: Button = $B_Start
@onready var settings_btn: Button = $B_Settings
@onready var quit_btn: Button = $B_Quit

var hud: MainHUD:
	get:
		return get_tree().get_first_node_in_group("HUD")

func _ready() -> void:
	start_btn.focus_mode = Control.FOCUS_NONE
	settings_btn.focus_mode = Control.FOCUS_NONE
	quit_btn.focus_mode = Control.FOCUS_NONE



# Button functionality
func _on_b_start_pressed() -> void:
	if hud and hud.has_method("close_pauseUI"):
		hud.close_pauseUI()

func _on_b_settings_pressed() -> void:
	# nothing
	pass

func _on_b_quit_pressed() -> void:
	if hud:
		hud.fadeEffect(false)
		await get_tree().create_timer(hud.fade_duration, true).timeout
		hud.freeze_game(false)
	
	get_tree().change_scene_to_file("res://src/scenes/menus/final menus/menus/main_menu.tscn")
	
