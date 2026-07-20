extends Node2D
class_name parallax_effect_mine_dungeon

@onready var dust1 = $Dust/Sprite2D1
@onready var dust2 = $Dust/Sprite2D2
@onready var dust3 = $Dust/Sprite2D3
@onready var dust4 = $Dust/Sprite2D4

@export_category("Dust_Animation")
## Minimum visibility
@export var min_alpha = 0.2
## Maximum visibility
@export var max_alpha = 1.0
## Animation duration (max -> min -> max)
@export var anim_duration = 10.0
## Offset of animation start for all layers
@export var anim_offset = 2.5


func _ready() -> void:
	var dust_sprites = [dust1, dust2, dust3, dust4]
	
	for i in range (dust_sprites.size()):
		var delay = i * anim_offset
		_animate_dust(dust_sprites[i], delay)

func _animate_dust(sprite: Sprite2D, delay: float) -> void:
	sprite.modulate.a = min_alpha
	
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	
	if not is_instance_valid(sprite):
		return
	
	var tween = sprite.create_tween()
	tween.set_loops() # Unendlich wiederholen

	var half_duration = anim_duration / 2.0
	
	tween.tween_property(sprite, "modulate:a", max_alpha, half_duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
		
	tween.tween_property(sprite, "modulate:a", min_alpha, half_duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
