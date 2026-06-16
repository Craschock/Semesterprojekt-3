extends Button

# Scene given in inspector that needs to be switched to
@export var game_scene: PackedScene
# Should unpause when switching scenes?
@export var unpause_on_switch: bool = false

func _ready():
	# Connect button click signal
	pressed.connect(_on_pressed)


func _on_pressed():
	# Open scene given in inspector
	if game_scene:
		
		# If box is checked,unpause and delete menu overlay
		if unpause_on_switch:
			UIManager.toggle_pause() 
			
		get_tree().change_scene_to_packed(game_scene)
