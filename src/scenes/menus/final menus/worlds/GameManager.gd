extends Node

class_name GameManager

@export_category("Systems")
@export var world_generator: WorldGenerator
@export var player: CharacterBody2D
@export var parallaxEffect: Node2D

@export_category("Spawns")
@export var boss_scene: PackedScene

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
	
	spawn_boss()

func spawn_player() -> void:
	var spawn_marker = get_tree().get_first_node_in_group("spawn_point")

	if spawn_marker:
		player.global_position = spawn_marker.global_position
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			camera.reset_smoothing()
			camera.force_update_scroll()
	else:
		push_warning("GameManager: No spawn marker found")

	# Unfreeze and reveal the player
	player.unfreeze()
	player.show()

func spawn_boss() -> void:
	var boss_marker = get_tree().get_first_node_in_group("boss_spawn")
	
	if boss_marker and boss_scene:
		var boss = boss_scene.instantiate()
		boss.freeze()
		boss.global_position = boss_marker.global_position
		var enemies_folder = get_node_or_null("../Enemies")
		
		if enemies_folder:
			enemies_folder.add_child(boss)
		else:
			add_child(boss)
			
	elif not boss_marker:
		push_warning("GameManager: No boss spawn marker found in world")
	elif not boss_scene:
		push_warning("GameManager: No boss scene assigned in Inspector")
