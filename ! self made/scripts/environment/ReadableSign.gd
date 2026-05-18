extends Area2D

@export_multiline var sign_text: String = "Default text"
@onready var label: Label = $Label

func _ready() -> void:
	label.text = sign_text
	label.hide() # Invisible until player overlaps
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(_body: Node2D) -> void:
	label.show()

func _on_body_exited(_body: Node2D) -> void:
	label.hide()
