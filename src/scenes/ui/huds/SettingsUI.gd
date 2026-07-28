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



# All button references

# Gameplay

# Video settings
@onready var v_fullscreen_btn: CheckButton = $Settings/P_Video/fullscreen # TODO: Change to optionButton (borderless etc)
@onready var v_res_opt: OptionButton = $Settings/P_Video/resolution 
var available_resolutions: Array[Vector2i] = [
	Vector2i(1280, 720), # Index 0
	Vector2i(1366, 768), # Index 1
	Vector2i(1600, 900), # Index 2
	Vector2i(1920, 1080), # Index 3
	Vector2i(2560, 1440), # Index 4
	Vector2i(4096, 2160) # Index 5
]

# Audio
@onready var master_slider: HSlider = $Settings/P_Sound/HSlider

# Controls










# false = Not showing settings subpanel
# true = showing settings subpannel
var current_state: bool

# Signals
signal settings_closed

func _ready() -> void:
	_initialize_settings()
	_initialize_signals()
	
	_show_buttons()
	_hide_Settings()
	current_state = false

func _initialize_settings() -> void:
	var config = SettingsManager.config
	# Gameplay
	
	# Video settings
	v_fullscreen_btn.button_pressed = config.get_value("Video", "fullscreen", true)
	v_res_opt.clear()
	for res in available_resolutions:
		v_res_opt.add_item(str(res.x) + " x " + str(res.y))
	var current_res_x = config.get_value("Video", "resolution_x", 1920)
	var current_res_y = config.get_value("Video", "resolution_y", 1080)
	var current_res = Vector2i(current_res_x, current_res_y)
	var index = available_resolutions.find(current_res)
	if index != -1:
		v_res_opt.select(index)
	
	# Audio
	master_slider.value = config.get_value("Audio", "master", 1.0)
	
	# Controls
	pass

func _initialize_signals() -> void:
	# Gameplay
	
	# Video settings
	v_fullscreen_btn.toggled.connect(_on_fullscreen_toggled)
	v_res_opt.item_selected.connect(_on_resolution_selected)
	
	# Audio
	master_slider.value_changed.connect(_on_master_volume_changed)
	
	# Controls
	








# All settings buttons functionality

# Gameplay

# Video
func _on_fullscreen_toggled(toggled_on: bool) -> void:
	SettingsManager.config.set_value("Video", "fullscreen", toggled_on)
	SettingsManager.apply_video_settings()
	SettingsManager.save_settings()

func _on_resolution_selected(index: int) -> void:
	var selected_res = available_resolutions[index]#
	
	SettingsManager.config.set_value("Video", "resolution_x", selected_res.x)
	SettingsManager.config.set_value("Video", "resolution_y", selected_res.y)
	
	SettingsManager.apply_video_settings()
	SettingsManager.save_settings()

# Audio
func _on_master_volume_changed(value: float) -> void:
	SettingsManager.config.set_value("Audio", "master", value)
	SettingsManager.apply_audio_settings()
	SettingsManager.save_settings()

# Controls






















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
	p_sound.show()

func _on_b_controls_pressed() -> void:
	_hide_buttons()
	_show_Settings()
	p_controls.show()

func _on_b_return_to_main_pressed() -> void:
	settings_closed.emit()
	hide()



# Panels return
func _on_b_return_pressed() -> void:
	_hide_Settings()
	_show_buttons()
