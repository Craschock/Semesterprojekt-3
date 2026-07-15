class_name WorldChunk
extends RefCounted

# Plain data container for a single chunk. Everything here is only used while
# the WorldGenerator keeps the chunk loaded.

enum State {
	PENDING,    ##Freshly created, not yet filled with corner data.
	GENERATED,  ##Corner data filled, not yet drawn.
	RENDERED,   ##Drawn onto the TileMapLayer.
}

var chunk_pos: Vector2i        ##Position of the chunk in chunk coordinates, not tile coordinates.
var size: int                  ##Side length of the chunk in tiles. Must match the value set in the inspector.
var biome: BiomeData           ##Biome of this chunk, determined by the region it falls into.
var region_pos: Vector2i       ##Region grid cell this chunk belongs to.
var state: int = State.PENDING

var corner_solid: PackedByteArray    ##Corner solidity: 0 = air, 1 = solid.
var corner_locked: PackedByteArray   ##Corner lock state: 0 = editable, 1 = bedrock.

var decorations: Array[Node] = []

func _init(p_chunk_pos: Vector2i, p_size: int, p_biome: BiomeData, p_region_pos: Vector2i) -> void:
	chunk_pos = p_chunk_pos
	size = p_size
	biome = p_biome
	region_pos = p_region_pos
	corner_solid = PackedByteArray()
	corner_solid.resize((size + 1) * (size + 1))
	corner_locked = PackedByteArray()
	corner_locked.resize((size + 1) * (size + 1))

##Returns the tile coordinate of the top-left tile in this chunk.
func world_origin() -> Vector2i:
	return chunk_pos * size

##Reads a corner from the local cache.
func get_corner(lx: int, ly: int) -> bool:
	return corner_solid[ly * (size + 1) + lx] != 0

##Writes a corner into the local cache.
func set_corner(lx: int, ly: int, solid: bool) -> void:
	corner_solid[ly * (size + 1) + lx] = 1 if solid else 0

##Returns true if this corner is bedrock.
func get_locked(lx: int, ly: int) -> bool:
	return corner_locked[ly * (size + 1) + lx] != 0

##Marks a corner as bedrock, or clears the flag.
func set_locked(lx: int, ly: int, locked: bool) -> void:
	corner_locked[ly * (size + 1) + lx] = 1 if locked else 0
