extends Line2D
class_name SpiderWebThread

@export_category("Web Dimensions")
## Default length of the web going upwards. TODO:raycast for ceiling detection
@export var default_length: float = 60.0
## Width of the web line in pixels
@export var web_width: float = 4.0

func _ready() -> void:
	width = web_width
	texture_mode = Line2D.LINE_TEXTURE_TILE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	
	# Draw initial vertical line from spider (0,0) straight up
	set_web_endpoints(Vector2.ZERO, Vector2(0.0, -default_length))

## TODO: later for raycast to ceiling
func set_web_endpoints(start_local: Vector2, end_local: Vector2) -> void:
	clear_points()
	add_point(start_local)
	add_point(end_local)
