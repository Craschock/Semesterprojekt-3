extends Resource
class_name DecorationData

enum Placement { FLOOR, CEILING }

enum SizeCategory { SMALL, MEDIUM, MEDIUM_PLUS, LARGE }

##texture of this decoration
@export var texture: Texture2D

##size category (must match the size of the texture (small: 7x9, medium: 16x22, medium+: 20x22))
@export var size_category: SizeCategory = SizeCategory.MEDIUM

##floor or ceiling?
@export var placement: Placement = Placement.FLOOR

##spawn chance per eligible tile
@export_range(0.0, 1.0) var spawn_chance: float = 0.05
