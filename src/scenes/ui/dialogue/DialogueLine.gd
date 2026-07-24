extends Resource
class_name DialogueLine

enum Speaker { PLAYER, BOSS }

@export var speaker: Speaker = Speaker.PLAYER
@export_multiline var text: String = "..."
@export var duration: float = 3.0
