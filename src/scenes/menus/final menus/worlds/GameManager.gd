extends Node

class_name GameManager

@export_category("Systems")
@export var world_generator: WorldGenerator

@export_category("Spawns")
@export var player_scene: PackedScene
@export var parallax_scene: PackedScene
@export var boss_scene: PackedScene



func _ready() -> void:
	# Init World
	if world_generator:
		world_generator.generate_world()
	
	await get_tree().process_frame
	
	spawn_player_and_parallax()
	spawn_boss()

func spawn_player_and_parallax() -> void:
	var spawn_marker = get_tree().get_first_node_in_group("spawn_point")
	
	if spawn_marker:
		# Instance player
		if player_scene:
			var spawned_player = player_scene.instantiate()
			spawned_player.global_position = spawn_marker.global_position
			
			get_parent().add_child(spawned_player)
			
			if world_generator:
				world_generator.player = spawned_player
			
			await get_tree().process_frame 
			var camera = spawned_player.get_node_or_null("Camera2D")
			
			if camera:
				camera.reset_smoothing()
				camera.force_update_scroll()
		else:
			push_warning("GameManager: No Player scene assigned")
		
		# Instance parallax
		if parallax_scene:
			var parallax = parallax_scene.instantiate()
			get_parent().add_child(parallax)
		else:
			push_warning("GameManager: No Parallax scene assigned")
			
	else:
		push_warning("GameManager: No spawn marker found")

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
			get_parent().add_child(boss)
			
	elif not boss_marker:
		push_warning("GameManager: No boss spawn marker found in world")
	elif not boss_scene:
		push_warning("GameManager: No boss scene assigned")
