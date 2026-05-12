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
var biome: BiomeData           ##which biome the chunk has (might change after i add biome blending)
# haha am arsch biome blending ich weiß bei gott nicht wie
var state: int = State.PENDING

var corner_solid: PackedByteArray

func _init(p_chunk_pos: Vector2i, p_size: int, p_biome: BiomeData) -> void:
	chunk_pos = p_chunk_pos
	size = p_size
	biome = p_biome
	corner_solid = PackedByteArray()
	corner_solid.resize((size + 1) * (size + 1))

##returns tile coordinate of topleft tile in chunk
func world_origin() -> Vector2i:
	return chunk_pos * size

##get corner from local cache
func get_corner(lx: int, ly: int) -> bool:
	return corner_solid[ly * (size + 1) + lx] != 0

##write corner into local cache
func set_corner(lx: int, ly: int, solid: bool) -> void:
	corner_solid[ly * (size + 1) + lx] = 1 if solid else 0
