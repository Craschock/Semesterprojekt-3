class_name WorldChunk
extends RefCounted

#lowkey brauchen wir nix davon
#alles in hier wird nur used wenn der world generator ein chunk abspeichert

enum State {
	PENDING,    ##fresh created, not yet filled with corner data
	GENERATED,  ##corner data filled but not yet drawn
	RENDERED,   ##drawn onto TileMapLayer
}

var chunk_pos: Vector2i        ##coordinate (chunk coordinates NOT tile coordinates)
var size: int                  ##length/height of chunk (should be the same as set in inspector)
var biome: BiomeData           ##which biome the chunk has (decided by region)
var region_pos: Vector2i       ##which region grid cell this chunk belongs to
var state: int = State.PENDING

var corner_solid: PackedByteArray    ##0=air, 1=solid
var corner_locked: PackedByteArray   ##0=normal, 1=bedrock

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

##returns tile coordinate of topleft tile in chunk
func world_origin() -> Vector2i:
	return chunk_pos * size

##get corner from local cache
func get_corner(lx: int, ly: int) -> bool:
	return corner_solid[ly * (size + 1) + lx] != 0

##write corner into local cache
func set_corner(lx: int, ly: int, solid: bool) -> void:
	corner_solid[ly * (size + 1) + lx] = 1 if solid else 0

##is this corner bedrock?
func get_locked(lx: int, ly: int) -> bool:
	return corner_locked[ly * (size + 1) + lx] != 0

##mark a corner as bedrock (or not lol)
func set_locked(lx: int, ly: int, locked: bool) -> void:
	corner_locked[ly * (size + 1) + lx] = 1 if locked else 0
