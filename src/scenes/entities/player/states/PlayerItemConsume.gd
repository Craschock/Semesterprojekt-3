extends State
class_name PlayerItemConsume

var player: PlayerMovement
#Izzy here:made the sound a variable
@onready var sfx_player_consume: AudioStreamPlayer2D = $"../../sfx_player_consume"	


func _ready() -> void:
	player = owner

func enter() -> void:
	player.freeze()
	
	# Get item 
	var held_Item = player.inventory_component.get_active_item()
	
	# Apply effects
	if held_Item != null:
		for effect in held_Item.consume_effects:
			effect.apply_effect(player)
			#Izzy here: plays consume sound upon consuming
			sfx_player_consume.play()
		# Remove 1 Item from Stack
		player.inventory_component.remove_item(held_Item, 1)
	
	# TODO add sprite consume animation
	#var sprite = player.get_node("AnimatedSprite2D")
	#if sprite.sprite_frames.has_animation("consume"):
		#sprite.play("consume")
	#else:
		## Fallback: If no animation exists, return
		#transitioned.emit(self, "idle")

func exit() -> void:
	player.unfreeze()

func physics_update(_delta: float) -> void:
	transitioned.emit(self, "idle")
	
	#var sprite = player.get_node("AnimatedSprite2D")
	## If consume animation finishes, return to idle
	#if sprite.animation == "consume" and not sprite.is_playing():
		#transitioned.emit(self, "idle")
