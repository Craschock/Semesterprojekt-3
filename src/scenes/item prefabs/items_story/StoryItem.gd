extends RigidBody2D
class_name StoryItem

@export_category("Story Content")
@export var story_title: String = "Note Titel"
@export_multiline var story_content: String = "Note Contents"
@export var interact_prompt: String = "Read: "

@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_ol: Sprite2D = $Sprite2D_OL
@onready var interactable: InteractableComponent = $InteractableComponent

func _ready() -> void:
	interactable.prompt_message = interact_prompt + story_title
	
	sprite_ol.hide()
	
	interactable.interacted.connect(_on_interacted)
	interactable.body_entered.connect(_on_player_entered)
	interactable.body_exited.connect(_on_player_exited)


func _on_player_entered(body: Node2D) -> void:
	print("player entered")
	sprite_ol.show()
	sprite.hide()

func _on_player_exited(body: Node2D) -> void:
	print("player left")
	sprite_ol.hide()
	sprite.show()

func _on_interacted(_interactor: Node) -> void:
	print("Debug: story found")
	print("Debug: title: ", story_title)
	print("Debug: content: ", story_content)
	
	var hud = get_tree().get_first_node_in_group("HUD")
	
	if hud and hud.has_method("show_story"):
		hud.show_story(story_title, story_content)
	
	queue_free()
