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
##array of every biome ressource in the world. ALL of these will be placed exactly once.
@export var biomes: Array[BiomeData] = []

@export_group("Regions")
##how many chunks wide/tall a single biome region is in chunks
@export var region_size_chunks: int = 4

##thickness in TILES of the unbreakable border between/around regions
@export_range(1, 16) var border_thickness: int = 3

##bedrock tileset, used for the border (foreground is buggy sry)
@export var border_fg_source_id: int = 2
##number of columns in the border foreground atlas (same meaning as biome fg_atlas_cols)
@export var border_fg_atlas_cols: int = 4
##background source/coord drawn behind solid border tiles (single solid tile)
@export var border_bg_source_id: int = 2
@export var border_bg_atlas_coord: Vector2i = Vector2i(0, 0)

##biome used to fill leftover region slots with solid stone
##if null, leftover slots are filled with the first biomes border tile
@export var filler_biome: BiomeData

@export_group("Targeting")
##the player character, the chunks will laod/unload around this node
@export var player: Node2D


#LOCAL VARIABLES
##chunk_pos -> WorldChunk
var _loaded_chunks: Dictionary = {}

##world_corner (Vector2i) -> bool
##player edits (break/place)
var _corner_overrides: Dictionary = {}

##the fastnoiselite of biome
var _biome_noise_cache: Dictionary = {}

##region_pos (Vector2i) -> BiomeData
##world layout
var _region_layout: Dictionary = {}

##bounds of the region grid filled by _build_world_layout.
var _region_min: Vector2i = Vector2i.ZERO
var _region_max: Vector2i = Vector2i.ZERO

##last chunk player was in
var _last_player_chunk: Vector2i = Vector2i(0x7FFFFFFF, 0x7FFFFFFF)


#MAIN
func _ready() -> void:
	_build_world_layout()


func _process(_delta: float) -> void:
	if player == null or biomes.is_empty():
		return
	var player_chunk = _world_pixel_to_chunk(player.global_position)
	if player_chunk == _last_player_chunk:
		return
	_last_player_chunk = player_chunk
	_stream_chunks(player_chunk)


#WORLD LAYOUT (runs once)
##decides which biome generates in which region cell, obeys the placement rules like a good boy
##every biome in biomes array is placed exactly once
func _build_world_layout() -> void:
	_region_layout.clear()
	if biomes.is_empty():
		return

	#split biomes by where they are allowed
	var surface: Array[BiomeData] = []
	var deep: Array[BiomeData] = []
	var anywhere: Array[BiomeData] = []
	for b in biomes:
		match b.placement:
			BiomeData.Placement.SURFACE_ONLY: surface.append(b)
			BiomeData.Placement.DEEP_ONLY: deep.append(b)
			_: anywhere.append(b)

	#deterministic shuffle so the layout is seed based
	#if the whole world is deterministic, does anything we do even matter...
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed
	_shuffle(surface, rng)
	_shuffle(deep, rng)
	_shuffle(anywhere, rng)

	#grid width gotta be wide enough to fit the widest row and the "anywhere"
	#need at least 1 surface row and 1 deep row when a biome exists there
	var top_count = surface.size()
	var bottom_count = deep.size()

	#choose a width, based it on the largest of the three groups so there cant be overflow
	var width = maxi(1, maxi(top_count, bottom_count))
	#make anywhere middle square (yes this wont be a perfect square but its not a bug i just dont care)
	var middle_rows = int(ceil(float(anywhere.size()) / float(width)))
	#if thjere is no anywhere biome but a top and a deep row we need smth in the middle still
	#if not we can just put it as 0
	middle_rows = maxi(middle_rows, 0)

	#spread out anywhere so its kinda evenly spread (good thing is for our prototype no one will ntocie anyways haha)
	if anywhere.size() > 0:
		var ideal_width = int(ceil(sqrt(float(anywhere.size()))))
		width = maxi(width, ideal_width)
		middle_rows = int(ceil(float(anywhere.size()) / float(width)))

	var has_top = top_count > 0
	var has_bottom = bottom_count > 0

	var total_rows = middle_rows + (1 if has_top else 0) + (1 if has_bottom else 0)
	total_rows = maxi(total_rows, 1)

	_region_min = Vector2i(0, 0)
	_region_max = Vector2i(width - 1, total_rows - 1)

	#fill rows from top to bottom
	var row = 0

	#TOP/SURFACE ROW
	if has_top:
		for col in range(width):
			var b: BiomeData = surface[col] if col < surface.size() else null
			_region_layout[Vector2i(col, row)] = b
		row += 1

	#MIDDLE/ANYWHERE ROW(S)
	var ai = 0
	for _r in range(middle_rows):
		for col in range(width):
			var b: BiomeData = null
			if ai < anywhere.size():
				b = anywhere[ai]
				ai += 1
			_region_layout[Vector2i(col, row)] = b
		row += 1

	#BOTTOM/DEEP ROW
	if has_bottom:
		for col in range(width):
			var b: BiomeData = deep[col] if col < deep.size() else null
			_region_layout[Vector2i(col, row)] = b
		row += 1


func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


##is this region cell inside the boundings of thr world
func _region_in_world(region_pos: Vector2i) -> bool:
	return region_pos.x >= _region_min.x and region_pos.x <= _region_max.x \
		and region_pos.y >= _region_min.y and region_pos.y <= _region_max.y


##which region a chunk belongs to
func _chunk_to_region(chunk_pos: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(chunk_pos.x) / region_size_chunks),
		floori(float(chunk_pos.y) / region_size_chunks)
	)


##biome for a region (null = bedrock)
func _biome_for_region(region_pos: Vector2i) -> BiomeData:
	if not _region_in_world(region_pos):
		return null
	return _region_layout.get(region_pos, null)


##true if region is on surface row AND biome has open sky
func _region_has_open_sky(region_pos: Vector2i) -> bool:
	if region_pos.y != _region_min.y:
		return false
	var b = _biome_for_region(region_pos)
	return b != null and b.has_open_sky


#CHUNK STREAMING
func _stream_chunks(center: Vector2i) -> void:
	var to_load: Array[Vector2i] = []
	for dy in range(-view_radius_chunks, view_radius_chunks + 1):
		for dx in range(-view_radius_chunks, view_radius_chunks + 1):
			var cp = center + Vector2i(dx, dy)
			if not _loaded_chunks.has(cp):
				to_load.append(cp)

	for cp in to_load:
		_load_chunk(cp)

	var to_unload: Array[Vector2i] = []
	for cp in _loaded_chunks.keys():
		var d: Vector2i = cp - center
		if absi(d.x) > unload_radius_chunks or absi(d.y) > unload_radius_chunks:
			to_unload.append(cp)
	for cp in to_unload:
		_unload_chunk(cp)


func _load_chunk(chunk_pos: Vector2i) -> void:
	var region_pos = _chunk_to_region(chunk_pos)
	var biome = _biome_for_region(region_pos)
	#chunks outside the world just render bedrock everywhere
	var chunk = WorldChunk.new(chunk_pos, chunk_size, biome, region_pos)
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
##terrain noise inside the dungeon area
##and outside worldborder or between dungeons some bedrock
func _generate_chunk_corners(chunk: WorldChunk) -> void:
	var origin = chunk.world_origin()
	var region_pos = chunk.region_pos
	var in_world = _region_in_world(region_pos)
	var biome = chunk.biome

	##if this chunk is ABOVE world (higher than surface row) and 
	##surface region directly below it has open sky make chunk above empty (air)
	var above_open_sky = false
	if not in_world and region_pos.y < _region_min.y \
		and region_pos.x >= _region_min.x and region_pos.x <= _region_max.x:
		var surface_region = Vector2i(region_pos.x, _region_min.y)
		var surface_biome = _biome_for_region(surface_region)
		if surface_biome != null and surface_biome.has_open_sky:
			above_open_sky = true

	#das hier ist in tile coords nicht chunk coords
	var region_tile_origin = region_pos * region_size_chunks * chunk_size
	var region_tile_size = region_size_chunks * chunk_size
	var rx0 = region_tile_origin.x
	var ry0 = region_tile_origin.y
	var rx1 = rx0 + region_tile_size
	var ry1 = ry0 + region_tile_size

	#give open sky to top row only and only if biome ressource allows it (rememebr we wanna be good boys)
	var is_surface_region = in_world and region_pos.y == _region_min.y
	var open_sky = is_surface_region and biome != null and biome.has_open_sky

	#seamless surface walk between biomes
	#remove side border between biomes on sirface
	#both sides have to agree to remove border or yea
	var seam_left = open_sky and _region_has_open_sky(region_pos + Vector2i(-1, 0))
	var seam_right = open_sky and _region_has_open_sky(region_pos + Vector2i(1, 0))

	#noise 1
	var noise: FastNoiseLite = null
	if biome != null:
		noise = _get_biome_noise(biome)
	var thr = biome.threshold if biome != null else 0.0

	for ly in range(chunk_size + 1):
		for lx in range(chunk_size + 1):
			var wx = origin.x + lx
			var wy = origin.y + ly
			var key = Vector2i(wx, wy)

			var solid: bool
			var locked: bool = false

			if above_open_sky:
				#open air above the surface, nothing solid, fully editable
				solid = false
				locked = false
			elif not in_world:
				#solid unbreakable rock everywhere
				solid = true
				locked = true
			else:
				#distance from each region edge
				var dist_left = wx - rx0
				var dist_right = rx1 - wx
				var dist_top = wy - ry0
				var dist_bottom = ry1 - wy

				#is this corner inside the broder?
				var on_left = dist_left < border_thickness
				var on_right = dist_right <= border_thickness
				var on_top = dist_top < border_thickness
				var on_bottom = dist_bottom <= border_thickness

				#on a surface region with open sky, remove top border
				if open_sky:
					on_top = false

				#fade border alongside caves so at top u can just walk into next biome
				if (seam_left and on_left) or (seam_right and on_right):
					var seam_surface_y = _surface_height_at(biome, wx, ry0)
					var seam_cutoff = seam_surface_y + int(round(biome.cave_fade_depth * 0.5))
					if wy < seam_cutoff:
						if seam_left and on_left:
							on_left = false
						if seam_right and on_right:
							on_right = false

				if biome == null:
					#bedrock
					solid = true
					locked = true
				elif on_left or on_right or on_top or on_bottom:
					#also bedrock but only between
					solid = true
					locked = true
				else:
					#playable dungeo area
					if open_sky:
						#create a hilly looking surface
						#fade into caves the deeper u go (bro liegt das nur an der uhrzeit oder hören sich frfr alle meine kommentare so sus an)
						var surface_y = _surface_height_at(biome, wx, ry0)
						if wy < surface_y:
							solid = false   # open sky / air
						else:
							solid = _solid_with_cave_fade(biome, noise, wx, wy, surface_y, thr)
					else:
						solid = noise.get_noise_2d(wx, wy) > thr

			#player edits override normal world but NEVER override border (this makes them unbreakable even if we break them via code/bugusing)
			if not locked and _corner_overrides.has(key):
				solid = _corner_overrides[key]

			chunk.set_corner(lx, ly, solid)
			chunk.set_locked(lx, ly, locked)


##y coordinate (tiles) where surface starts
##uses custom noise so we dont get caves but hills
##that noise should be the same on every surface level biome
func _surface_height_at(biome: BiomeData, world_x: int, region_top_tile_y: int) -> int:
	var base = region_top_tile_y + border_thickness + biome.surface_air_height
	if biome.surface_variation <= 0:
		return base
	var hn = _get_surface_noise(biome)
	#1D noise = hills
	var h = hn.get_noise_2d(world_x, 0.0) # min -1 max 1
	return base + int(round(h * biome.surface_variation))


##decides if a tile is cave-noise generated or surface-noise generated
##near the surface ground is almost fully solid, at cave_fade_depth it's full cave noise.
func _solid_with_cave_fade(biome: BiomeData, noise: FastNoiseLite, wx: int, wy: int, surface_y: int, thr: float) -> bool:
	var depth = wy - surface_y
	var fade = float(biome.cave_fade_depth)
	#t = 0 at the surface, 1 once we're at/below cave_fade_depth
	var t = clampf(float(depth) / maxf(fade, 1.0), 0.0, 1.0)
	#a cell is solid when noise > eff_thr. to make the shallow ground a solid crust,
	#the threshold starts very LOW (-1 => almost everything solid) and rises to the
	#biome's real threshold as we go deeper, letting the caves open up gradually.
	var eff_thr = lerpf(-1.0, thr, t)
	return noise.get_noise_2d(wx, wy) > eff_thr


##checks which mask to use for every tile in chunk, converts mask into atlas coordinates
func _render_chunk(chunk: WorldChunk) -> void:
	var origin = chunk.world_origin()
	var biome = chunk.biome

	for ty in range(chunk_size):
		for tx in range(chunk_size):
			var wp = Vector2i(origin.x + tx, origin.y + ty)
			var mask = _corner_mask(chunk, tx, ty)

			if mask == 0:
				fg_layer.erase_cell(wp)
				bg_layer.erase_cell(wp)
				continue

			#schwöre zu schwer in einem kommentar zu erklären
			var use_border = biome == null or _tile_is_border(chunk, tx, ty)

			var src: int
			var cols: int
			var bg_src: int
			var bg_coord: Vector2i
			if use_border:
				src = border_fg_source_id
				cols = border_fg_atlas_cols
				bg_src = border_bg_source_id
				bg_coord = border_bg_atlas_coord
			else:
				src = biome.fg_source_id
				cols = biome.fg_atlas_cols
				bg_src = biome.bg_source_id
				bg_coord = biome.bg_atlas_coord

			if chunk.get_corner(tx, ty):
				bg_layer.set_cell(wp, bg_src, bg_coord)
			else:
				bg_layer.erase_cell(wp)
			var atlas = Vector2i(mask % cols, mask / cols)
			fg_layer.set_cell(wp, src, atlas)


##true if all four courners of a tile are bedrock
func _tile_is_border(chunk: WorldChunk, tx: int, ty: int) -> bool:
	return chunk.get_locked(tx, ty) and chunk.get_locked(tx + 1, ty) \
		and chunk.get_locked(tx, ty + 1) and chunk.get_locked(tx + 1, ty + 1)


##convert 4 corners of cell (tx, ty) into a binary mask (https://imgur.com/a/mZ8i4yG)
func _corner_mask(chunk: WorldChunk, tx: int, ty: int) -> int:
	var tl = 1 if chunk.get_corner(tx, ty) else 0
	var tr = 1 if chunk.get_corner(tx + 1, ty) else 0
	var bl = 1 if chunk.get_corner(tx, ty + 1) else 0
	var br = 1 if chunk.get_corner(tx + 1, ty + 1) else 0
	return tl | (tr << 1) | (bl << 2) | (br << 3)


#NOISE / HELPERS
func _get_biome_noise(biome: BiomeData) -> FastNoiseLite:
	var key = biome.get_instance_id()
	if not _biome_noise_cache.has(key):
		_biome_noise_cache[key] = biome.create_noise(world_seed)
	return _biome_noise_cache[key]


func _get_surface_noise(biome: BiomeData) -> FastNoiseLite:
	var key = -biome.get_instance_id()
	if not _biome_noise_cache.has(key):
		_biome_noise_cache[key] = biome.create_surface_noise(world_seed)
	return _biome_noise_cache[key]


func _world_pixel_to_chunk(pixel_pos: Vector2) -> Vector2i:
	var px_per_chunk = tile_pixel_size * chunk_size
	return Vector2i(
		floori(pixel_pos.x / px_per_chunk),
		floori(pixel_pos.y / px_per_chunk)
	)

##is the corner at this world position bedrock?
##could be useful for melvin (e.g. disabling mining tooltip on borders)
func is_corner_locked(world_corner: Vector2i) -> bool:
	var cp = Vector2i(
		floori(float(world_corner.x) / chunk_size),
		floori(float(world_corner.y) / chunk_size)
	)
	var chunk: WorldChunk = _loaded_chunks.get(cp)
	if chunk == null:
		return false
	var origin = chunk.world_origin()
	var lx = world_corner.x - origin.x
	var ly = world_corner.y - origin.y
	if lx < 0 or ly < 0 or lx > chunk_size or ly > chunk_size:
		return false
	return chunk.get_locked(lx, ly)


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
	_build_world_layout()
	_last_player_chunk = Vector2i(0x7FFFFFFF, 0x7FFFFFFF)


##THIS IS THE ONLY FUNCTION TO CALL IF YOU WANT TO PLACE/BREAK ANY BLOCKS! (and the refresh one but yk)
##call this function to change any corner (only inside logic)
##afterwards call refresh_chunk_at(world_x, world_y) to also change visuals
##it will adjust to the change inside logic by itself.
##bedrock can NOT be changed and will be silently ignored.
##returns true if the change was applied, false if it was blocked (bedrock)
func override_corner(world_corner: Vector2i, solid: bool) -> bool:
	if is_corner_locked(world_corner):
		return false
	_corner_overrides[world_corner] = solid
	return true


##rerenders the chunk that (world_x, world_y) is inside of
##call this function after you make any changes to the world (e.g. player breaking blocks)
func refresh_chunk_at(world_x: int, world_y: int) -> void:
	var cp = Vector2i(floori(float(world_x) / chunk_size), floori(float(world_y) / chunk_size))
	var chunk: WorldChunk = _loaded_chunks.get(cp)
	if chunk == null:
		return
	_generate_chunk_corners(chunk)
	_render_chunk(chunk)
