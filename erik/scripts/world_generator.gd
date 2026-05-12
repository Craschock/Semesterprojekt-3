extends Node2D
class_name WorldGenerator

#PUBLIC VARIABLES
@export_group("Tile Layers")
@export var fg_layer: TileMapLayer
@export var bg_layer: TileMapLayer

@export_group("World")
@export var world_seed: int = 67

##how many tiles on chunk (square) is long
@export var chunk_size: int = 32

##how many chunks to keep loaded per direction. (e.g: 3 = 7x7 chunks = 49 chunks)
@export var view_radius_chunks: int = 3

##chunks behind this distance get unloaded (gotta be at least view_radius_chunks +1)
@export var unload_radius_chunks: int = 4

##the size of each tile (if you change this make sure to change inside tileset too)
@export var tile_pixel_size: int = 16

@export_group("Biomes")
##array of every biome ressource in the world
@export var biomes: Array[BiomeData] = []
##frequency of biome picker noise (the lower the larger the biomes)
@export_range(0.001, 0.1, 0.001) var biome_selection_frequency: float = 0.005

@export_group("Targeting")
##the player character, the chunks will laod/unload around this node
@export var player: Node2D


#LOCAL VARIABLES
##chunk_pos -> WorldChunk
var _loaded_chunks: Dictionary = {}

##bool, can override corners to force solid
var _corner_overrides: Dictionary = {}

##the fastnoiselite of biome
var _biome_noise_cache: Dictionary = {}

##the Biome Picker Noise (decides the biome of a chunk) (has to be redone better later)
var _biome_picker: FastNoiseLite

##last chunk player was in
var _last_player_chunk: Vector2i = Vector2i(0x7FFFFFFF, 0x7FFFFFFF)


#MAIN
func _ready() -> void:
	_build_biome_picker()


func _process(_delta: float) -> void:
	if player == null or biomes.is_empty():
		return
	var player_chunk = _world_pixel_to_chunk(player.global_position)
	if player_chunk == _last_player_chunk:
		return
	_last_player_chunk = player_chunk
	_stream_chunks(player_chunk)


#CHUNK STREAMING
func _stream_chunks(center: Vector2i) -> void:
	#get all chunks that have to be loaded this wave
	var to_load: Array[Vector2i] = []
	for dy in range(-view_radius_chunks, view_radius_chunks + 1):
		for dx in range(-view_radius_chunks, view_radius_chunks + 1):
			var cp = center + Vector2i(dx, dy)
			if not _loaded_chunks.has(cp):
				to_load.append(cp)

	#generate the new chunks
	for cp in to_load:
		_load_chunk(cp)

	#unload all chunks beyond despawn radius
	var to_unload: Array[Vector2i] = []
	for cp in _loaded_chunks.keys():
		var d: Vector2i = cp - center
		if absi(d.x) > unload_radius_chunks or absi(d.y) > unload_radius_chunks:
			to_unload.append(cp)
	for cp in to_unload:
		_unload_chunk(cp)


func _load_chunk(chunk_pos: Vector2i) -> void:
	var biome = _pick_biome_for_chunk(chunk_pos)
	if biome == null:
		return
	var chunk = WorldChunk.new(chunk_pos, chunk_size, biome)
	_generate_chunk_corners(chunk)
	chunk.state = WorldChunk.State.GENERATED
	_render_chunk(chunk)
	chunk.state = WorldChunk.State.RENDERED
	_loaded_chunks[chunk_pos] = chunk


func _unload_chunk(chunk_pos: Vector2i) -> void:
	var chunk: WorldChunk = _loaded_chunks.get(chunk_pos)
	if chunk == null:
		return
	var origin = chunk.world_origin()
	for ly in range(chunk_size):
		for lx in range(chunk_size):
			var wp = Vector2i(origin.x + lx, origin.y + ly)
			fg_layer.erase_cell(wp)
			bg_layer.erase_cell(wp)
	_loaded_chunks.erase(chunk_pos)



#CHUNK GENERATION
##checknig biome noise at every corner, fills the chunkss corner cache
func _generate_chunk_corners(chunk: WorldChunk) -> void:
	var noise = _get_biome_noise(chunk.biome)
	var origin = chunk.world_origin()
	var thr = chunk.biome.threshold
	for ly in range(chunk_size + 1):
		for lx in range(chunk_size + 1):
			var wx = origin.x + lx
			var wy = origin.y + ly
			var key = Vector2i(wx, wy)
			var solid: bool
			if _corner_overrides.has(key):
				solid = _corner_overrides[key]
			else:
				solid = noise.get_noise_2d(wx, wy) > thr
			chunk.set_corner(lx, ly, solid)


##checks which mask to use for every tile in chunk
##converts mask into atlas coordinates
func _render_chunk(chunk: WorldChunk) -> void:
	var origin = chunk.world_origin()
	var biome = chunk.biome
	var cols = biome.fg_atlas_cols
	for ty in range(chunk_size):
		for tx in range(chunk_size):
			var mask = _corner_mask(chunk, tx, ty)
			var wp = Vector2i(origin.x + tx, origin.y + ty)
			if mask == 0:
				#clear empty cells for rererendering (ich bring mich um)
				fg_layer.erase_cell(wp)
				bg_layer.erase_cell(wp)
				continue
			#fill background where tile solid
			if chunk.get_corner(tx, ty):
				bg_layer.set_cell(wp, biome.bg_source_id, biome.bg_atlas_coord)
			else:
				bg_layer.erase_cell(wp)
			var atlas = Vector2i(mask % cols, mask / cols)
			fg_layer.set_cell(wp, biome.fg_source_id, atlas)



##convert 4 corners of cell (tx, ty) into a binary mask (https://imgur.com/a/mZ8i4yG)
func _corner_mask(chunk: WorldChunk, tx: int, ty: int) -> int:
	var tl = 1 if chunk.get_corner(tx,ty) else 0
	var tr = 1 if chunk.get_corner(tx+1,ty) else 0
	var bl = 1 if chunk.get_corner(tx,ty + 1) else 0
	var br = 1 if chunk.get_corner(tx+1,ty+1) else 0
	return tl|(tr << 1)|(bl << 2)|(br << 3)


#BIOME PICKER (this entire thing could have to be redone later (cooked))
func _build_biome_picker() -> void:
	_biome_picker = FastNoiseLite.new()
	_biome_picker.seed = world_seed
	_biome_picker.noise_type = FastNoiseLite.TYPE_CELLULAR
	_biome_picker.frequency = biome_selection_frequency
	_biome_picker.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	_biome_picker.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE

##keine ahnung, hab die function von gemini
func _pick_biome_for_chunk(chunk_pos: Vector2i) -> BiomeData:
	if biomes.is_empty():
		return null
	var sample_x = chunk_pos.x * chunk_size + chunk_size / 2
	var sample_y = chunk_pos.y * chunk_size + chunk_size / 2
	var v = _biome_picker.get_noise_2d(sample_x, sample_y)
	var t = clamp((v + 1.0) * 0.5, 0.0, 0.999999)
	var idx = int(t * biomes.size())
	return biomes[idx]


func _get_biome_noise(biome: BiomeData) -> FastNoiseLite:
	var key = biome.get_instance_id()
	if not _biome_noise_cache.has(key):
		_biome_noise_cache[key] = biome.create_noise(world_seed)
	return _biome_noise_cache[key]


func _hash_chunk_seed(chunk_pos: Vector2i) -> int:
	return hash(Vector3i(chunk_pos.x, chunk_pos.y, world_seed))

##mark corner as override and adjacent chunk corners fpr rerender
func _set_override(world_corner: Vector2i, solid: bool, out_rerender: Dictionary) -> void:
	_corner_overrides[world_corner] = solid
	var cp = Vector2i(
		floori(float(world_corner.x) / chunk_size),
		floori(float(world_corner.y) / chunk_size)
	)
	for dy in [0, -1]:
		for dx in [0, -1]:
			var ncp: Vector2i = cp + Vector2i(dx, dy)
			if _loaded_chunks.has(ncp):
				out_rerender[ncp] = true

##Helper function that terns world pixel (godot) into chunk
func _world_pixel_to_chunk(pixel_pos: Vector2) -> Vector2i:
	var px_per_chunk = tile_pixel_size * chunk_size
	return Vector2i(
		floori(pixel_pos.x / px_per_chunk),
		floori(pixel_pos.y / px_per_chunk)
	)



# FUNCTIONS TO CALL FROM OUTSIDE. NEVER CALL ANY OTHER FUNCTION FROM OUTSIDE PLS
# AND NEVER NEVER NEVER MODIFY ANY CODE INSIDE THIS FILE AAAAAAAAAAAAAAAAAAA
# (IF YOU DO YOU DO IT ON YOUR OWN FUCKING RISK DONT BLAME ME IF EVERYTGING EXPLODES)
# BITTE MELVIN WENN DU DAS LIEST BITTE FRAG MICH WAS DU MACHEN MUSST ES IST NICHT SO DEEP
# DU BIST NICHT DER MAIN CHARACTER DU KANST EINFACH FRAGEN
# DAS ZU DEBUGGEN TOTARSCH SCHWER SONST DANKE

##forces reload around player chunk (you dont need this normally unless u do some magic idk)
func regenerate() -> void:
	for cp in _loaded_chunks.keys():
		_unload_chunk(cp)
	_loaded_chunks.clear()
	_corner_overrides.clear()
	_biome_noise_cache.clear()
	_build_biome_picker()
	_last_player_chunk = Vector2i(0x7FFFFFFF, 0x7FFFFFFF)


##THIS IS THE ONLY FUNCTION TO CALL IF YOU WANT TO PLACE/BREAK ANY BLOCKS! (and the refresh one but yk) 
##call this function to change any corner (only inside logic)
##afterwards call refresh_chunk_at(world_x, world_y) to also change visuals
##it will adjust to the change inside logic by itself
func override_corner(world_corner: Vector2i, solid: bool) -> void:
	_corner_overrides[world_corner] = solid


##rerenders the chunk that (world_x, world_y) is inside of
##call this function after you make any changes to the world (e.g. player breaking blocks)
func refresh_chunk_at(world_x: int, world_y: int) -> void:
	var cp = Vector2i(floori(float(world_x) / chunk_size), floori(float(world_y) / chunk_size))
	var chunk: WorldChunk = _loaded_chunks.get(cp)
	if chunk == null:
		return
	_generate_chunk_corners(chunk)
	_render_chunk(chunk)
