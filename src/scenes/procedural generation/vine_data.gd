@tool
class_name VineData
extends DecorationData

#vines bring their own textures, size themselves off them and always hang from
#the ceiling -> hide the parent fields that do nothing here
func _validate_property(property: Dictionary) -> void:
	if property.name in ["texture", "size_category", "placement"]:
		property.usage = PROPERTY_USAGE_NONE

##the middle parts (V1-V6)
@export var segment_textures: Array[Texture2D] = []

##the vine endings (VE1-VE6). only one gets picked to cap the vine off
@export var end_textures: Array[Texture2D] = []

##how many segments a vine has minimum (not inclusive the ending)
##it can end up shorter if it runs into terrain
@export_range(1, 32) var min_segments: int = 1

##how many segments a vine has minimum (not inclusive the ending)
@export_range(1, 32) var max_segments: int = 8

##due to rescaling, it's possible that vines sometimes will leave a gap, even with perfect textures
##to fix this adjust this number. It will move the texture up by given pixel amount
##best to leave between 1-3
@export_range(0, 16) var segment_overlap: int = 1

##max random sideways offset per segment in pixels
##you probably want to leave this at 0, unless your vine textures are made extra for this
@export_range(0, 16) var wiggle: int = 0

##should vines are allowed to bypass the 1 per tile limit
##vines will still not be placed exactly ontop of each other, but rather form a curtain
@export var allow_overlap: bool = true

##chance per segment to just stop growing early (only kicks in once min_segments is reached)
##0 = always grow to the rolled length, 0.15 = a bit of taper, 0.4 = mostly stubby
@export_range(0.0, 1.0, 0.01) var early_stop_chance: float = 0.15
