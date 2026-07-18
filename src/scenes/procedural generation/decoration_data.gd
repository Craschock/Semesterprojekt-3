extends Resource
class_name DecorationData

enum Placement { FLOOR, CEILING }

enum SizeCategory { SMALL, MEDIUM, MEDIUM_PLUS, LARGE, HANGING }

##Texture used for this decoration.
@export var texture: Texture2D

##Size category. Must match the texture size (small: 7x9, medium: 16x22, medium+: 20x22).
@export var size_category: SizeCategory = SizeCategory.MEDIUM

##Whether this decoration attaches to the floor or the ceiling.
@export var placement: Placement = Placement.FLOOR

##Spawn chance per eligible tile.
@export_range(0.0, 1.0) var spawn_chance: float = 0.05

@export_group("Light")

##if true, a PointLight2D gets spawned on top of this decoration
@export var is_light_source: bool = false

##empty radial GradientTexture2D. can leave empty or input any png
@export var light_texture: Texture2D = _get_default_light_texture()

##color tint of the light
@export var light_color: Color = Color(1.0, 0.9, 0.7)

##brightness
@export_range(0.0, 8.0, 0.01) var light_energy: float = 1.0

##radius multiplier
@export_range(0.05, 16.0, 0.01) var light_texture_scale: float = 1.0

##offset from the center of the decoration in pixels in johannas original texture
##(e.g. Vector2(0, -10) to put the glow 10px further to the top of the texture)
##the difference is barely visible so dont feel obliged to change it lowkey
@export var light_offset: Vector2 = Vector2.ZERO



# Code for the Light Node to have a default
static var _default_light_texture: GradientTexture2D = null

static func _get_default_light_texture() -> GradientTexture2D:
	if _default_light_texture == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))   #center: color fully solid
		g.set_color(1, Color(1, 1, 1, 0))   #edge: color fully transparent
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 256
		t.height = 256
		_default_light_texture = t
	return _default_light_texture
