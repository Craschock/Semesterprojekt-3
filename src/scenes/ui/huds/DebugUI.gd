extends Control
class_name DebugUI

# cheats
@onready var fly_btn: CheckButton = $HBoxContainer/Cheats/FlyButton
@onready var noclip_btn: CheckButton = $HBoxContainer/Cheats/NoclipButton
@onready var godmode_btn: CheckButton = $HBoxContainer/Cheats/GodmodeButton

#world seed:
@onready var seed_label: Label = $HBoxContainer/Cheats/Seed

# unlocks
@onready var u_digging_btn: CheckButton = $HBoxContainer/Unlocks/Unlock_Digging

# We store the original collision masks so we can restore them when noclip turns off
var original_layer: int = 2
var original_mask: int = 5
var player: PlayerMovement:
	get:
		return PlayerManager.player

func _ready() -> void:
	fly_btn.focus_mode = Control.FOCUS_NONE
	noclip_btn.focus_mode = Control.FOCUS_NONE
	godmode_btn.focus_mode = Control.FOCUS_NONE
	
	#seed
	seed_label.text = "World Seed: %d" % WorldGenerator.current_seed


# Buttons


# cheats
func _on_fly_button_toggled(toggled_on: bool) -> void:
	if player:
		player.apply_gravity = !toggled_on

func _on_noclip_button_toggled(toggled_on: bool) -> void:
	if player:
		if toggled_on:
			# Save current collisions, then turn off
			original_layer = player.collision_layer
			original_mask = player.collision_mask
			player.collision_layer = 0
			player.collision_mask = 0
			
			# Force fly on, refactor later to use _on_fly_toggled()
			player.apply_gravity = false 
			fly_btn.button_pressed = true 
		else:
			# Restore collisions
			player.collision_layer = original_layer
			player.collision_mask = original_mask
			
			if not fly_btn.button_pressed:
				player.apply_gravity = true

func _on_godmode_button_toggled(toggled_on: bool) -> void:
	if player:
		var hitbox = player.get_node_or_null("HitboxComponent")
		if hitbox:
			hitbox.is_invincible = toggled_on

# unlocks
func _on_unlock_digging_toggled(toggled_on: bool) -> void:
	if player:
		player.unlocked_digging = toggled_on
