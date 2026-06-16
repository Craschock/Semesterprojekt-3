extends Node

# Preload the UI scene so itÄs in memory
var pause_menu_scene = preload("res://src/scenes/menus/final menus/menus/pause_menu.tscn")
var current_pause_menu: Node = null


func _ready():
	# Allow script to work while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var tree = get_tree()
	tree.paused = !tree.paused # Flips the pause state when pressing escape

	if tree.paused:
		# Instantiate and show the pause menu overlay
		current_pause_menu = pause_menu_scene.instantiate()
		add_child(current_pause_menu)
	else:
		# Destroy the pause menu and resume
		if current_pause_menu:
			current_pause_menu.queue_free()
