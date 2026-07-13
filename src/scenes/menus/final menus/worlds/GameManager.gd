extends Node

class_name GameManager

@export_category("Systems")
@export var world_generator: WorldGenerator
@export var player: CharacterBody2D


func _ready() -> void:
	# Init Player
	if player:
		player.hide()
		player.freeze()
	
	# Init World
	if world_generator:
		world_generator.generate_world()
	await get_tree().process_frame
	
	# TP Player to Spawnpoint
	if player:
		spawn_player()

func spawn_player() -> void:
	var spawn_marker = get_tree().get_first_node_in_group("spawn_point")
	
	if spawn_marker:
		player.global_position = spawn_marker.global_position
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			camera.reset_smoothing()
	else:
		push_warning("GameManager: No spawn marker found")
		
	# Unfreeze and reveal the player
	player.unfreeze()
	player.show()
