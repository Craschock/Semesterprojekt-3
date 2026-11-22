extends AttackComponent
class_name TongueTip

signal player_hooked(player: PlayerMovement)
signal wall_hit

var is_extending: bool = false

func _ready() -> void:
	super._ready()
	body_entered.connect(_on_body_entered)
	set_active(false)

func _on_area_entered(area: Area2D) -> void:
	if not is_extending:
		return
		
	if area is HitboxComponent and area not in hit_entities:
		# If parried, take_hit() emits parry_triggered and calls notify_parried()
		if area.is_parrying and can_be_parried:
			area.take_hit(self)
			is_extending = false
			set_active(false)
			return
			
		# If player is invincible, no hook 
		if area.is_invincible:
			return
			
		hit_entities.append(area)
		is_extending = false
		set_active(false)
		
		if area.owner is PlayerMovement:
			player_hooked.emit(area.owner)

func _on_body_entered(_body: Node2D) -> void:
	if is_extending:
		is_extending = false
		set_active(false)
		wall_hit.emit()
