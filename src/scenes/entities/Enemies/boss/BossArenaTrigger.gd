extends Area2D
class_name BossArenaTrigger

@export_category("Cutscene Settings")
@export var dialogue_sequence: Array[DialogueLine] = []

var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	
	if body is PlayerMovement:
		triggered = true
		
		body.freeze()
		
		var hitbox = body.get_node_or_null("HitboxComponent")
		if hitbox:
			hitbox.is_invincible = true
			
		print("Cutscene start")
		
		var boss = get_tree().get_first_node_in_group("boss")
		
		for line in dialogue_sequence:
			var active_bubble: TextBubble = null
			
			if line.speaker == DialogueLine.Speaker.PLAYER:
				active_bubble = body.get_node_or_null("TextBubble")
			elif line.speaker == DialogueLine.Speaker.BOSS and boss:
				active_bubble = boss.get_node_or_null("TextBubble")
			
			if active_bubble:
				active_bubble.play_text(line.text, line.duration)
				await active_bubble.dialogue_finished
			else:
				await get_tree().create_timer(line.duration).timeout
		
		
		print("Cutscene end")
		body.unfreeze()
		
		if hitbox:
			hitbox.is_invincible = false
		
		if boss and boss is boss_mole:
			boss.is_playerInArena = true
			print("Enable boss")
