extends CanvasLayer
class_name MainHUD

@export var fade_duration: float = 2.0

# All main UIs
@onready var player_ui: Control = $PlayerUI
@onready var debug_ui: Control = $DebugUI
@onready var pause_ui: Control = $PauseUI
@onready var settings_ui: Control = $SettingsUI
@onready var story_panel: Control = $StoryPanel

@onready var BlackoutEffect: ColorRect = $BlackoutEffect
@onready var healthBar: TextureProgressBar = $PlayerUI/HealthBar/HealthBarProgressBar

# Story Stuff
@onready var story_title_label: Label = $StoryPanel/TitleLabel
@onready var story_content_label: Label = $StoryPanel/ContentLabel

var isFrozen: bool = false
var isShowing_Story: bool = false
var isShowing_PauseUI: bool = false
var isShowing_settings: bool = false

var player: PlayerMovement

func _ready() -> void:
	pause_ui.pressed_start.connect(close_pauseUI)
	
	pause_ui.pressed_settings.connect(open_settings)
	settings_ui.settings_closed.connect(close_settings)
	
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("HUD")
	
	# Hide all UIs (Also auch für die zukunft alle hiden)
	_hide_all_ui()
	
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
	
	# all escape things
	if event.is_action_pressed("pause"):
		if isShowing_Story:
			close_story()
			return
		
		# All other cancel stuff
		if isShowing_settings:
			settings_ui.handle_cancel()
			return
		
		if isShowing_PauseUI:
			close_pauseUI()
			return
		
		if not isShowing_PauseUI:
			show_pauseUI()
			return


# Hide all UIs on start
func _hide_all_ui() -> void:
	if debug_ui:
		debug_ui.hide()
	
	if story_panel:
		story_panel.hide()
	
	if pause_ui:
		pause_ui.hide()
	
	if settings_ui:
		settings_ui.hide()

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

# Health bar
func drawHealth(_current: int, _max: int) -> void:
	healthBar.value = (float(_current) / float(_max)) * 100



# Story methods
func show_story(title: String, content: String) -> void:
	isShowing_Story = true
	
	story_title_label.text = title
	story_content_label.text = content
	story_panel.show()
	freeze_game(true)

func close_story() -> void:
	isShowing_Story = false
	
	story_panel.hide()
	freeze_game(false)



# Pause UI
func show_pauseUI() -> void:
	isShowing_PauseUI = true
	
	pause_ui.show()
	freeze_game(true)

func close_pauseUI() -> void:
	isShowing_PauseUI = false
	
	pause_ui.hide()
	freeze_game(false)



# Settings
func open_settings() -> void:
	isShowing_settings = true
	settings_ui.show()

func close_settings() -> void:
	isShowing_settings = false
	settings_ui.hide()



# Helper
func freeze_game(variable: bool) -> void:
	get_tree().paused = variable
	isFrozen = variable



# Buttons
func _on_button_pressed() -> void:
	close_story()
