extends Resource
class_name DecorationData

enum Placement { FLOOR, CEILING }

enum SizeCategory { SMALL, MEDIUM, MEDIUM_PLUS, LARGE }

##Texture used for this decoration.
@export var texture: Texture2D

##Size category. Must match the texture size (small: 7x9, medium: 16x22, medium+: 20x22).
@export var size_category: SizeCategory = SizeCategory.MEDIUM

##Whether this decoration attaches to the floor or the ceiling.
@export var placement: Placement = Placement.FLOOR

##Spawn chance per eligible tile.
@export_range(0.0, 1.0) var spawn_chance: float = 0.05
