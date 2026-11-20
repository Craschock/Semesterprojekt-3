extends CanvasLayer
class_name BossArrow

##leave empty unless u know what u are doing
@export var world_generator: WorldGenerator
@export var arrow_radius: float = 100.0           ##distance between arrow and player
@export var reached_distance: float = 200.0      ##at what distance to bossroom it should hide the arrow

var _arrow: Polygon2D
var _label: Label

func _init() -> void:
	add_to_group("boss_arrow")

func _ready() -> void:
	layer = 100

	if world_generator == null:
		world_generator = get_parent() as WorldGenerator
	if world_generator == null:
		push_warning("No World Generator assigned.")
		set_process(false)
		return

	_arrow = Polygon2D.new()
	_arrow.polygon = PackedVector2Array([Vector2(14, 0), Vector2(-8, -9), Vector2(-3, 0), Vector2(-8, 9)])
	_arrow.color = Color.WHITE
	add_child(_arrow)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 10)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _process(_delta: float) -> void:
	_arrow.visible = false
	_label.visible = false

	var player: Node2D = PlayerManager.player
	if not is_instance_valid(player):
		return

	var targets = world_generator.get_boss_room_positions()
	if targets.is_empty():
		return

	var nearest = Vector2.ZERO
	var best_dist = INF
	for local_pos: Vector2 in targets:
		var global_pos = world_generator.to_global(local_pos)
		var d = player.global_position.distance_to(global_pos)
		if d < best_dist:
			best_dist = d
			nearest = global_pos

	if best_dist < reached_distance:
		return

	var dir = (nearest - player.global_position).normalized()
	var player_screen = get_viewport().get_canvas_transform() * player.global_position

	_arrow.position = player_screen + dir * arrow_radius
	_arrow.rotation = dir.angle()
	_arrow.visible = true

	_label.position = _arrow.position + Vector2(12, 12)
	_label.text = "Boss: %d tiles" % int(best_dist / world_generator.tile_pixel_size)
	_label.visible = true
