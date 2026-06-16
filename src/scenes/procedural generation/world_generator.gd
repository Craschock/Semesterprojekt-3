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

##list of prebuilt rooms in the following format:
##ja hier halt format rein nachher
var _rooms: Array[Dictionary] = []

##tile coordinate of player spawn
var _spawn_tile: Vector2i = Vector2i(0x7FFFFFFF, 0x7FFFFFFF)
#schwöre ich bin langsam zu müde für kommentare ich häng mich bald vllt auf

##last chunk player was in
var _last_player_chunk: Vector2i = Vector2i(0x7FFFFFFF, 0x7FFFFFFF)


#MAIN

# Function von Erik
#func _ready() -> void:
	#_build_world_layout()
	##drop player into spawn room
	##called with one tick delay so if melvin has his own spawn function, i
	##dont override anything (at least normally this should work like that)
	#if player != null and has_spawn_point():
		#_place_player_at_spawn.call_deferred()

# Function von Melvin
func generate_world() -> void:
	_build_world_layout()
	
	if has_spawn_point():
		_create_spawn_marker()


func _create_spawn_marker() -> void:
	if not has_spawn_point():
		return
		
	var spawn_marker = Marker2D.new()
	spawn_marker.name = "SpawnMarker"
	spawn_marker.position = get_spawn_position()
	
	# Add it to a group for future it can easily find it 
	# (können dann halt mehrere spawnpunkte haben, ohne 
	# den direkt referencen zu müssen. mal schauen, ob das 
	# relevant wird für "checkpoints" oder so)
	spawn_marker.add_to_group("spawn_point")
	
	add_child(spawn_marker)


func _process(_delta: float) -> void:
	if player == null or biomes.is_empty():
		return
	var local_player_pos = to_local(player.global_position)
	var player_chunk = _world_pixel_to_chunk(local_player_pos)
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

	_build_rooms()

#die nächsten 165 zeilen sind von gemini generated kussi
##bakes the tile-space rectangles for every prebuilt room (spawn + boss) once,
##based on where each room-bearing biome landed in the region layout.
func _build_rooms() -> void:
	_rooms.clear()
	_spawn_tile = Vector2i(0x7FFFFFFF, 0x7FFFFFFF)

	#which biome is the spawn biome? first flagged one wins, warn if several.
	var spawn_biome: BiomeData = null
	var spawn_flag_count = 0
	for b in biomes:
		if b != null and b.is_spawn_biome:
			spawn_flag_count += 1
			if spawn_biome == null:
				spawn_biome = b
	if spawn_flag_count > 1:
		push_warning("WorldGenerator: %d biomes flagged is_spawn_biome; using the first one." % spawn_flag_count)

	var region_tile_size = region_size_chunks * chunk_size

	for region_pos in _region_layout.keys():
		var biome: BiomeData = _region_layout[region_pos]
		if biome == null:
			continue

		var region_tile_origin: Vector2i = region_pos * region_tile_size
		var rx0 = region_tile_origin.x
		var ry0 = region_tile_origin.y
		var center_x = rx0 + region_tile_size / 2

		#SPAWN ROOM: only in the chosen spawn biomes region, anchored so its
		#TOP sits where the cave fade ends
		if biome == spawn_biome and biome.has_spawn_room:
			var w: int = maxi(1, biome.spawn_room_size.x)
			var h: int = maxi(1, biome.spawn_room_size.y)
			#use the average surface line of the region (noise sampled at center).
			var surface_y = _surface_height_at(biome, center_x, ry0)
			#top of the interior right at the start of the cave fade
			var interior_x = center_x - w / 2
			var interior_y = surface_y + biome.cave_fade_depth
			_rooms.append({
				"rect": Rect2i(interior_x, interior_y, w, h),
				"wall": biome.room_wall_thickness,
				"biome": biome,
			})
			#drop the player near the middle-bottom of the room (on the floor)
			_spawn_tile = Vector2i(center_x, interior_y + h - 1)

		#BOSS ROOM: at the very bottom interior of the region, above the border.
		if biome.has_boss_room:
			var bw: int = maxi(1, biome.boss_room_size.x)
			var bh: int = maxi(1, biome.boss_room_size.y)
			var ry1 = ry0 + region_tile_size
			#leave room for the region border + the rooms own wall ring
			var bottom_interior = ry1 - border_thickness - biome.room_wall_thickness
			var b_interior_y = bottom_interior - bh
			var b_interior_x = center_x - bw / 2
			_rooms.append({
				"rect": Rect2i(b_interior_x, b_interior_y, bw, bh),
				"wall": biome.room_wall_thickness,
				"biome": biome,
			})


func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
#die letzten 165 zeilen waren von gemini generiert :)

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


#PREBUILT ROOMS (der teil auch von gemini habs lwk nicht hinbekommen mit den pre generated rooms)
##classify a TILE against all rooms.
## returns: 0 = not part of any room, 1 = room interior (air), 2 = room wall (solid)
func _room_tile_kind(tx: int, ty: int) -> int:
	var kind = 0
	for room in _rooms:
		var interior: Rect2i = room["rect"]
		var wall: int = room["wall"]
		var outer = Rect2i(
			interior.position - Vector2i(wall, wall),
			interior.size + Vector2i(wall * 2, wall * 2)
		)
		if not outer.has_point(Vector2i(tx, ty)):
			continue
		if interior.has_point(Vector2i(tx, ty)):
			#interior wins outright; an air tile carves through any nearby wall
			return 1
		#inside the wall ring of this room
		kind = 2
	return kind


##is the CORNER at (wx, wy) controlled by a prebuilt room, and whats its value?
## returns: 0 = room doesnt touch this corner (leave noise alone)
##          1 = corner forced solid (wall)
##          2 = corner forced air (interior)
func _room_corner_state(wx: int, wy: int) -> int:
	#the four tiles sharing this corner
	var k_tl = _room_tile_kind(wx - 1, wy - 1)
	var k_tr = _room_tile_kind(wx,     wy - 1)
	var k_bl = _room_tile_kind(wx - 1, wy)
	var k_br = _room_tile_kind(wx,     wy)

	#if no touching tile belongs to a room, the room has no say here
	if k_tl == 0 and k_tr == 0 and k_bl == 0 and k_br == 0:
		return 0

	#a corner is solid if ANY touching tile is a wall; otherwise its air.
	#(this keeps interiors hollow while ringing them with a solid wall)
	if k_tl == 2 or k_tr == 2 or k_bl == 2 or k_br == 2:
		return 1
	return 2

#ab jetzt wieder "mein" code (also alles was mein code ist ist ja auch 50% copy pasted irgendwo aber du checkst ja eh)

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

			#PREBUILT ROOMS override the generated noise
			#but dont override player made corner overrides so player can break
			#spawn and boss roms if he feels like it or maybe bombs or idk
			if not locked:
				var rs = _room_corner_state(wx, wy)
				if rs == 1:
					solid = true    # room wall
				elif rs == 2:
					solid = false   # room interior (air)

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
##near the surface ground is almost fully solid, at cave_fade_depth its full cave noise.
func _solid_with_cave_fade(biome: BiomeData, noise: FastNoiseLite, wx: int, wy: int, surface_y: int, thr: float) -> bool:
	var depth = wy - surface_y
	var fade = float(biome.cave_fade_depth)
	#t = 0 at the surface, 1 once were at/below cave_fade_depth
	var t = clampf(float(depth) / maxf(fade, 1.0), 0.0, 1.0)
	#a cell is solid when noise > eff_thr. to make the shallow ground a solid crust,
	#the threshold starts very LOW (-1 => almost everything solid) and rises to the
	#biomes real threshold as we go deeper, letting the caves open up gradually
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


##does a spawn room exist in this world?
func has_spawn_point() -> bool:
	return _spawn_tile.x != 0x7FFFFFFF


##tile coordinate where player spawns
func get_spawn_tile() -> Vector2i:
	if not has_spawn_point():
		return Vector2i.ZERO
	return _spawn_tile


##PIXEL coordinate where player spaens
func get_spawn_position() -> Vector2:
	if not has_spawn_point():
		return Vector2.ZERO
	
	var local_pos = Vector2(
		(_spawn_tile.x + 0.5) * tile_pixel_size,
		_spawn_tile.y * tile_pixel_size
	)
	
	return local_pos
