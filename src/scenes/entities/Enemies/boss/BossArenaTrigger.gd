extends Area2D
class_name BossArenaTrigger

@export_category("Cutscene Settings")
@export var dialogue_sequence: Array[DialogueLine] = []
@export var death_dialogue_sequence: Array[DialogueLine] = []

var triggered: bool = false
var boss_reference: Node = null

#Izzy here: boss_music added as variable
@onready var mine_boss_theme_music: AudioStreamPlayer2D = $"../mine_boss_theme_music"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	await get_tree().process_frame
	boss_reference = get_tree().get_first_node_in_group("boss")
	
	if boss_reference and boss_reference is boss_mole:
		boss_reference.boss_defeated.connect(_on_boss_defeated)

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	
	if body is PlayerMovement:
		triggered = true
		
		await _play_cutscene(body, dialogue_sequence)
		
		if boss_reference and boss_reference is boss_mole:
			boss_reference.unfreeze()
			boss_reference.is_playerInArena = true
			#Izzy here: Starting to play boss music
			mine_boss_theme_music.play()
			print("Enable boss")

func _on_boss_defeated() -> void:
	var player = PlayerManager.player
	if player:
		await _play_cutscene(player, death_dialogue_sequence)
	if boss_reference and boss_reference.has_method("finish_death"):
		boss_reference.finish_death()

func _play_cutscene(player: PlayerMovement, sequence: Array[DialogueLine]) -> void:
	player.allow_input(false)
	
	var hitbox = player.get_node_or_null("HitboxComponent")
	if hitbox:
		hitbox.is_invincible = true
		
	print("Cutscene start")
	
	for line in sequence:
		var active_bubble: TextBubble = null
		
		if line.speaker == DialogueLine.Speaker.PLAYER:
			active_bubble = player.get_node_or_null("TextBubble")
		elif line.speaker == DialogueLine.Speaker.BOSS and boss_reference:
			active_bubble = boss_reference.get_node_or_null("TextBubble")
		
		if active_bubble:
			active_bubble.play_text(line.text, line.duration)
			await active_bubble.dialogue_finished
		else:
			await get_tree().create_timer(line.duration).timeout
	
	print("Cutscene end")
	player.allow_input(true)
	
	if hitbox:
		hitbox.is_invincible = false
