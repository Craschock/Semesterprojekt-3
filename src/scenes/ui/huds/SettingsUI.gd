extends Control
class_name SettingsUI

# Main panels
@onready var buttons_panel: VBoxContainer = $MainSettingsButtons
@onready var settings_panel: Control = $Settings

# Settings panel
@onready var p_gameplay: Control = $Settings/P_Gameplay
@onready var p_video: Control = $Settings/P_Video
@onready var p_sound: Control = $Settings/P_Sound
@onready var p_controls: Control = $Settings/P_Controls

# false = Not showing settings subpanel
# true = showing settings subpannel
var current_state: bool

# Signals
signal settings_closed

func _ready() -> void:
	_show_buttons()
	_hide_Settings()
	current_state = false

# Buttons
func _show_buttons() -> void:
	buttons_panel.show()

func _hide_buttons() -> void:
	buttons_panel.hide()



# Settings-Panel
func _show_Settings() -> void:
	_reset_panel_display()
	settings_panel.show()
	current_state = true

func _hide_Settings() -> void:
	settings_panel.hide()
	_reset_panel_display()
	current_state = false

func handle_cancel() -> void:
	if current_state == true:
		_on_b_return_pressed()
	else:
		settings_closed.emit()

# Resets all subpanels (just making sure)
func _reset_panel_display() -> void:
	p_gameplay.hide()
	p_video.hide()
	p_sound.hide()
	p_controls.hide()

# Buttons Buttons
func _on_b_gameplay_pressed() -> void:
	_hide_buttons()
	_show_Settings()
	p_gameplay.show()

func _on_b_video_pressed() -> void:
	_hide_buttons()
	_show_Settings()
	p_video.show()

func _on_b_sound_pressed() -> void:
	_hide_buttons()
	_show_Settings()
	p_sound.hide()

func _on_b_controls_pressed() -> void:
	_hide_buttons()
	_show_Settings()
	p_controls.hide()

func _on_b_return_to_main_pressed() -> void:
	settings_closed.emit()
	hide()



# Panels return
func _on_b_return_pressed() -> void:
	_hide_Settings()
	_show_buttons()
