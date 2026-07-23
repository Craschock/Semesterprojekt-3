extends Node2D
class_name WorldGenerator

# --- Exported configuration ---
@export_group("Tile Layers")
@export var fg_layer: TileMapLayer
@export var bg_layer: TileMapLayer

@export_group("World")
@export var world_seed: int = 67

##Side length of a chunk in tiles. Chunks are square.
@export var chunk_size: int = 32

##How many chunks to keep loaded in each direction (e.g. 3 = 7x7 = 49 chunks).
@export var view_radius_chunks: int = 3

##Chunks beyond this distance are unloaded. Must be at least view_radius_chunks + 1.
@export var unload_radius_chunks: int = 4

##Size of a single tile in pixels. Must match the value configured in the TileSet.
@export var tile_pixel_size: int = 16

@export_group("Biomes")
##Every biome resource in the world. Each one is placed exactly once.
@export var biomes: Array[BiomeData] = []

@export_group("Regions")
##Width and height of a single biome region, in chunks.
@export var region_size_chunks: int = 4

##Thickness, in tiles, of the unbreakable border between and around regions.
@export_range(1, 16) var border_thickness: int = 3

##Atlas source id of the bedrock tileset used for region borders.
@export var border_fg_source_id: int = 2
##Number of columns in the border foreground atlas. Same meaning as BiomeData.fg_atlas_cols.
@export var border_fg_atlas_cols: int = 4
##Background source and coordinate drawn behind solid border tiles (a single solid tile).
@export var border_bg_source_id: int = 2
@export var border_bg_atlas_coord: Vector2i = Vector2i(0, 0)

##Biome used to fill leftover region slots with solid stone.
##If null, leftover slots are filled with the first biome's border tile.
@export var filler_biome: BiomeData

@export_group("Targeting")
##The player node. Chunks load and unload around this node.
@export var player: Node2D

@export_group("Decorations")
##Scale applied to decoration sprites so they match the tile scaling.
@export var decoration_scale: float = 1.6

@export_group("Items")
##List of all Item scenes that can spawn on the floor, each spawn point chooses one randomly
@export var item_scenes: Array[PackedScene] = []
##chance of an item spawning per chunk
@export_range(0.0, 1.0, 0.01) var item_spawn_chance: float = 0.2
##freeze spawned items so they stay exactly where placed instead of falling or rolling away like enemy drops would
@export var freeze_spawned_items: bool = false

@export_group("Depth Shading")
##off by default.
##the depth shading is very laggy and the current version is cooked
##turn on at your own risk (idk maybe u need a quantum computer)
@export var depth_shading_enabled: bool = false
##how many tiles into solid rock until it reaches full darkness
@export_range(1, 32) var depth_darkness_range: int = 6
##0 = no darkening, 1 = pitch black at full depth
@export_range(0.0, 1.0, 0.01) var depth_max_darkness: float = 0.9
##1 = per-tile (sharp, but very slow) 2 = quarter the work
@export_range(1, 4) var depth_shading_downsample: int = 2

@export_group("Spawn Room")
##Scene to show inside the Spawning Area, containing tutorial elements
@export var tutorial_scene: PackedScene
##offset by pixels, (0,0) is the top löeft corner
@export var tutorial_offset: Vector2 = Vector2.ZERO


# --- Internal state ---
const DECO_SIZE: Dictionary = {
	DecorationData.SizeCategory.SMALL: Vector2i(7,  9),
	DecorationData.SizeCategory.MEDIUM: Vector2i(16, 22),
	DecorationData.SizeCategory.MEDIUM_PLUS: Vector2i(20, 22),
	DecorationData.SizeCategory.LARGE: Vector2i(32,32),
	DecorationData.SizeCategory.HANGING: Vector2i(16,64)
}

var _enemy_spawns: Dictionary = {}

##Currently loaded chunks, keyed by chunk position (Vector2i -> WorldChunk).
var _loaded_chunks: Dictionary = {}

##Player edits to the world (Vector2i world corner -> bool solid).
var _corner_overrides: Dictionary = {}

##Cached FastNoiseLite instances, keyed by biome.
var _biome_noise_cache: Dictionary = {}

##World layout: which biome occupies which region cell (Vector2i -> BiomeData).
var _region_layout: Dictionary = {}

##Bounds of the region grid, filled in by _build_world_layout().
var _region_min: Vector2i = Vector2i.ZERO
var _region_max: Vector2i = Vector2i.ZERO

##Prebuilt rooms. Each entry is a Dictionary with the keys:
##  "rect"  (Rect2i)    interior of the room in tile coordinates
##  "wall"  (int)       wall thickness surrounding the interior
##  "biome" (BiomeData) biome the room belongs to
var _rooms: Array[Dictionary] = []

##Tile coordinate of the player spawn point.
var _spawn_tile: Vector2i = Vector2i(0x7FFFFFFF, 0x7FFFFFFF)

##Interior rect of the spawn room (in tiles)
var _spawn_room_rect: Rect2i = Rect2i(0, 0, 0, 0)

##Chunk the player occupied during the previous check.
var _last_player_chunk: Vector2i = Vector2i(0x7FFFFFFF, 0x7FFFFFFF)

# Chunks queued for loading. Processed a few per frame to avoid frame spikes.
var _load_queue: Array[Vector2i] = []


#darkness
var _darkness_overlay: Sprite2D = null
var _darkness_dirty: bool = false

#Chunks whose item has been picked up, prevents respawn on chunk reload
var _taken_items: Dictionary = {}

# --- Lifecycle ---

# Alternative entry point: build the world automatically on _ready() instead of
# waiting for an explicit generate_world() call.
#func _ready() -> void:
	#_build_world_layout()
	##Drop the player into the spawn room. Deferred by one tick so an
	##external spawn routine, if one exists, is not overridden.
	#if player != null and has_spawn_point():
		#_place_player_at_spawn.call_deferred()

##Builds the world layout and places the spawn marker. Call once at startup.
func generate_world() -> void:
	_build_world_layout()
	
	if has_spawn_point():
		_create_spawn_marker()
		_place_tutorial()


func _create_spawn_marker() -> void:
	if not has_spawn_point():
		return
		
	var spawn_marker = Marker2D.new()
	spawn_marker.name = "SpawnMarker"
	spawn_marker.position = get_spawn_position()
	
	# Grouping lets other systems locate spawn points without holding a direct
	# reference, and leaves room for several spawn points later (e.g. checkpoints).
	spawn_marker.add_to_group("spawn_point")
	
	add_child(spawn_marker)


func _process(_delta: float) -> void:
	if player == null or biomes.is_empty():
		return
	_dbg_reset_frame()
	var player_chunk = _world_pixel_to_chunk(to_local(player.global_position))
	if player_chunk != _last_player_chunk:
		_last_player_chunk = player_chunk
		_refresh_load_queue(player_chunk)
		_unload_far_chunks(player_chunk)
	
	var did_load = _process_load_queue()
	if _darkness_dirty and _load_queue.is_empty() and not did_load:
		_update_darkness_overlay()
		_darkness_dirty = false
	
	_dbg_report(_delta)

# --- World layout (runs once) ---
##Decides which biome generates in which region cell, honouring each biome's placement rule.
##Every biome in the biomes array is placed exactly once.
func _build_world_layout() -> void:
	_region_layout.clear()
	if biomes.is_empty():
		return

	# Split the biomes by where they are allowed.
	var surface: Array[BiomeData] = []
	var deep: Array[BiomeData] = []
	var anywhere: Array[BiomeData] = []
	for b in biomes:
		match b.placement:
			BiomeData.Placement.SURFACE_ONLY: surface.append(b)
			BiomeData.Placement.DEEP_ONLY: deep.append(b)
			_: anywhere.append(b)

	# Deterministic shuffle so the layout is fully determined by the seed.
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed
	_shuffle(surface, rng)
	_shuffle(deep, rng)
	_shuffle(anywhere, rng)

	# The grid must be wide enough to fit the widest row as well as the ANYWHERE biomes.
	# At least one surface row and one deep row are needed when biomes exist for them.
	var top_count = surface.size()
	var bottom_count = deep.size()

	# Base the width on the largest group so that no row can overflow.
	var width = maxi(1, maxi(top_count, bottom_count))
	# Lay the ANYWHERE biomes out as a roughly square block. It is intentionally not exact.
	var middle_rows = int(ceil(float(anywhere.size()) / float(width)))
	# With no ANYWHERE biomes there is no middle row at all, so middle_rows stays 0.
	middle_rows = maxi(middle_rows, 0)

	# Widen the grid so the ANYWHERE biomes end up spread fairly evenly.
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

	# Fill rows from top to bottom.
	var row = 0

	# Top / surface row.
	if has_top:
		for col in range(width):
			var b: BiomeData = surface[col] if col < surface.size() else null
			_region_layout[Vector2i(col, row)] = b
		row += 1

	# Middle / ANYWHERE row(s).
	var ai = 0
	for _r in range(middle_rows):
		for col in range(width):
			var b: BiomeData = null
			if ai < anywhere.size():
				b = anywhere[ai]
				ai += 1
			_region_layout[Vector2i(col, row)] = b
		row += 1

	# Bottom / deep row.
	if has_bottom:
		for col in range(width):
			var b: BiomeData = deep[col] if col < deep.size() else null
			_region_layout[Vector2i(col, row)] = b
		row += 1

	_build_rooms()

##Bakes the tile-space rectangles for every prebuilt room (spawn and boss) once,
##based on where each room-bearing biome landed in the region layout.
func _build_rooms() -> void:
	_rooms.clear()
	_spawn_tile = Vector2i(0x7FFFFFFF, 0x7FFFFFFF)
	_spawn_room_rect = Rect2i(0, 0, 0, 0)

	# The first biome flagged as the spawn biome wins; warn if several are flagged.
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

		# Spawn room: only in the chosen spawn biome's region, anchored so its
		# top sits where the cave fade ends.
		if biome == spawn_biome and biome.has_spawn_room:
			var w: int = maxi(1, biome.spawn_room_size.x)
			var h: int = maxi(1, biome.spawn_room_size.y)
			# Use the average surface line of the region, sampling the noise at the centre.
			var surface_y = _surface_height_at(biome, center_x, ry0)
			# Place the top of the interior right where the cave fade starts.
			var interior_x = center_x - w / 2
			var interior_y = surface_y + biome.cave_fade_depth
			_rooms.append({
				"rect": Rect2i(interior_x, interior_y, w, h),
				"wall": biome.room_wall_thickness,
				"biome": biome,
			})
			# Drop the player near the middle of the room's floor.
			_spawn_tile = Vector2i(center_x, interior_y + h - 1)
			_spawn_room_rect = Rect2i(interior_x, interior_y, w, h)

		# Boss room: at the very bottom interior of the region, just above the border.
		if biome.has_boss_room:
			var bw: int = maxi(1, biome.boss_room_size.x)
			var bh: int = maxi(1, biome.boss_room_size.y)
			var ry1 = ry0 + region_tile_size
			# Leave space for the region border and the room's own wall ring.
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

##Returns true if this region cell lies inside the bounds of the world.
func _region_in_world(region_pos: Vector2i) -> bool:
	return region_pos.x >= _region_min.x and region_pos.x <= _region_max.x \
		and region_pos.y >= _region_min.y and region_pos.y <= _region_max.y


##Returns the region a chunk belongs to.
func _chunk_to_region(chunk_pos: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(chunk_pos.x) / region_size_chunks),
		floori(float(chunk_pos.y) / region_size_chunks)
	)


##Returns the biome for a region, or null if the region is solid bedrock.
func _biome_for_region(region_pos: Vector2i) -> BiomeData:
	if not _region_in_world(region_pos):
		return null
	return _region_layout.get(region_pos, null)


##Returns true if the region is on the surface row and its biome has open sky.
func _region_has_open_sky(region_pos: Vector2i) -> bool:
	if region_pos.y != _region_min.y:
		return false
	var b = _biome_for_region(region_pos)
	return b != null and b.has_open_sky

# --- Items ---

func _spawn_items(chunk: WorldChunk) -> void:
	if item_scenes.is_empty():
		return

	var origin = chunk.world_origin()

	# Own hash constants so items don't always land on the enemy marker's tile.
	var h = (origin.x * 374761393 ^ origin.y * 668265263 ^ world_seed) & 0x7FFFFFFF
	if float(h) / float(0x7FFFFFFF) > item_spawn_chance:
		return

	if _taken_items.has(chunk.chunk_pos):
		return

	var near_room = _chunk_touches_room(origin, 2)
	var candidates: Array[Vector2i] = []
	for ty in range(chunk_size):
		for tx in range(chunk_size):
			if chunk.get_corner(tx, ty):
				continue
			if not chunk.get_corner(tx, ty + 1):
				continue
			if ty > 0 and chunk.get_corner(tx, ty - 1):
				continue
			if near_room and _tile_in_any_room(origin.x + tx, origin.y + ty, 1):
				continue
			candidates.append(Vector2i(tx, ty))

	if candidates.is_empty():
		return

	var pick = candidates[h % candidates.size()]
	var scene: PackedScene = item_scenes[(h / 7) % item_scenes.size()]
	var item = scene.instantiate()

	# Sit on top of the floor tile, centred.
	item.position = Vector2(
		(origin.x + pick.x + 0.5) * tile_pixel_size,
		(origin.y + pick.y + 0.5) * tile_pixel_size
	)
	#item.position = Vector2(
		#(origin.x + pick.x + 0.5) * tile_pixel_size,
		#(origin.y + pick.y + 1) * tile_pixel_size
	#)
	item.freeze = freeze_spawned_items
	add_child(item)
	chunk.decorations.append(item)

	item.set_meta("wg_chunk", chunk.chunk_pos)
	item.tree_exiting.connect(_on_item_exiting.bind(item))


func _on_item_exiting(item: Node) -> void:
	# Chunk unload also frees the item; only a real pickup should count.
	if item.has_meta("wg_unloading"):
		return
	_taken_items[item.get_meta("wg_chunk")] = true

# --- Prebuilt rooms ---
##Classifies a tile against all prebuilt rooms.
##Returns: 0 = not part of any room, 1 = room interior (air), 2 = room wall (solid).
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
			return 1
		# Only treat as wall if we're in the TOP or BOTTOM wall band.
		# Left/right bands return 0 so terrain noise fills those sides naturally (open entrance).
		var in_left_band  = tx < interior.position.x
		var in_right_band = tx >= interior.position.x + interior.size.x
		if in_left_band or in_right_band:
			continue   # left/right sides: let terrain decide
		kind = 2
	return kind


##Returns whether the corner at (wx, wy) is controlled by a prebuilt room, and its value.
##Returns: 0 = no room touches this corner, leave the noise alone
##         1 = corner forced solid (wall)
##         2 = corner forced air (interior)
func _room_corner_state(wx: int, wy: int) -> int:
	# The four tiles sharing this corner.
	var k_tl = _room_tile_kind(wx - 1, wy - 1)
	var k_tr = _room_tile_kind(wx,     wy - 1)
	var k_bl = _room_tile_kind(wx - 1, wy)
	var k_br = _room_tile_kind(wx,     wy)

	# If no adjacent tile belongs to a room, no room has a say here.
	if k_tl == 0 and k_tr == 0 and k_bl == 0 and k_br == 0:
		return 0

	# A corner is solid if any adjacent tile is a wall, and air otherwise.
	# This keeps interiors hollow while ringing them with a solid wall.
	if k_tl == 2 or k_tr == 2 or k_bl == 2 or k_br == 2:
		return 1
	return 2


##Returns true if the tile lies in a spawn or boss room. Used, for example, to keep enemies out of them.
func _tile_in_any_room(tx: int, ty: int, padding: int = 0) -> bool:
	var p = Vector2i(tx, ty)
	for room in _rooms:
		var interior: Rect2i = room["rect"]
		var grow: int = room["wall"] + padding
		var outer = Rect2i(
			interior.position - Vector2i(grow, grow),
			interior.size + Vector2i(grow * 2, grow * 2)
		)
		if outer.has_point(p):
			return true
	return false

##Returns true if the chunk overlaps a spawn or boss room. Lets per-tile room checks be skipped entirely.
func _chunk_touches_room(origin: Vector2i, margin: int = 1) -> bool:
	var chunk_rect = Rect2i(
		origin.x - margin, origin.y - margin,
		chunk_size + margin * 2, chunk_size + margin * 2
	)
	for room in _rooms:
		var interior: Rect2i = room["rect"]
		var wall: int = room["wall"]
		var outer = Rect2i(
			interior.position - Vector2i(wall, wall),
			interior.size + Vector2i(wall * 2, wall * 2)
		)
		if outer.intersects(chunk_rect):
			return true
	return false

# --- Chunk streaming ---
func _refresh_load_queue(center: Vector2i) -> void:
	_load_queue.clear()
	for dy in range(-view_radius_chunks, view_radius_chunks + 1):
		for dx in range(-view_radius_chunks, view_radius_chunks + 1):
			var cp = center + Vector2i(dx, dy)
			if not _loaded_chunks.has(cp):
				_load_queue.append(cp)
	# Load the chunks nearest the player first rather than all at once.
	_load_queue.sort_custom(func(a, b):
		return (a - center).length_squared() < (b - center).length_squared())

func _process_load_queue() -> bool:
	var loaded = false
	var budget = 1
	while budget > 0 and not _load_queue.is_empty():
		var cp: Vector2i = _load_queue.pop_front()
		if not _loaded_chunks.has(cp):
			_load_chunk(cp)
			budget -= 1
			loaded = true
	return loaded
			
func _unload_far_chunks(center: Vector2i) -> void:
	var t0 = Time.get_ticks_usec()
	var to_unload: Array[Vector2i] = []
	for cp in _loaded_chunks.keys():
		var d: Vector2i = cp - center
		if absi(d.x) > unload_radius_chunks or absi(d.y) > unload_radius_chunks:
			to_unload.append(cp)
	for cp in to_unload:
		_unload_chunk(cp)
	_dbg_unloaded_this_frame = to_unload.size()
	_dbg_frame_usec += Time.get_ticks_usec() - t0

func _load_chunk(chunk_pos: Vector2i) -> void:
	var region_pos = _chunk_to_region(chunk_pos)
	var biome = _biome_for_region(region_pos)
	var chunk = WorldChunk.new(chunk_pos, chunk_size, biome, region_pos)

	var t0 = Time.get_ticks_usec()
	_generate_chunk_corners(chunk)
	var t1 = Time.get_ticks_usec()
	chunk.state = WorldChunk.State.GENERATED
	_render_chunk(chunk)
	var t2 = Time.get_ticks_usec()
	_spawn_decorations(chunk)
	_spawn_items(chunk)
	var t3 = Time.get_ticks_usec()

	_dbg_gen += t1 - t0
	_dbg_render += t2 - t1
	_dbg_deco += t3 - t2
	_dbg_frame_usec += t3 - t0
	_dbg_loaded_this_frame += 1

	chunk.state = WorldChunk.State.RENDERED
	_loaded_chunks[chunk_pos] = chunk

	_darkness_dirty = true

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
	for node in chunk.decorations:
		if node.has_meta("wg_chunk"):
			node.set_meta("wg_unloading", true)
		node.queue_free()
	chunk.decorations.clear()
	
	_enemy_spawns.erase(chunk_pos)
	_loaded_chunks.erase(chunk_pos)
	
	_darkness_dirty = true


# --- Chunk generation ---
##Fills a chunk's corner data: terrain noise inside the dungeon area, and
##bedrock outside the world border and between regions.
func _generate_chunk_corners(chunk: WorldChunk) -> void:
	var origin = chunk.world_origin()
	var region_pos = chunk.region_pos
	var in_world = _region_in_world(region_pos)
	var biome = chunk.biome

	##If this chunk sits above the world (higher than the surface row) and the
	##surface region directly below has open sky, leave this chunk empty (air).
	var above_open_sky = false
	if not in_world and region_pos.y < _region_min.y \
		and region_pos.x >= _region_min.x and region_pos.x <= _region_max.x:
		var surface_region = Vector2i(region_pos.x, _region_min.y)
		var surface_biome = _biome_for_region(surface_region)
		if surface_biome != null and surface_biome.has_open_sky:
			above_open_sky = true

	# These are tile coordinates, not chunk coordinates.
	var region_tile_origin = region_pos * region_size_chunks * chunk_size
	var region_tile_size = region_size_chunks * chunk_size
	var rx0 = region_tile_origin.x
	var ry0 = region_tile_origin.y
	var rx1 = rx0 + region_tile_size
	var ry1 = ry0 + region_tile_size

	# Only the top row gets open sky, and only if the biome resource allows it.
	var is_surface_region = in_world and region_pos.y == _region_min.y
	var open_sky = is_surface_region and biome != null and biome.has_open_sky

	# Seamless surface walk between biomes: drop the side border between two
	# adjacent surface biomes. Both sides must have open sky for the seam to open.
	var seam_left = open_sky and _region_has_open_sky(region_pos + Vector2i(-1, 0))
	var seam_right = open_sky and _region_has_open_sky(region_pos + Vector2i(1, 0))

	# Cave and terrain noise for this biome.
	var noise: FastNoiseLite = null
	if biome != null:
		noise = _get_biome_noise(biome)
	var thr = biome.threshold if biome != null else 0.0

	# If the chunk touches no room at all, the per-corner room checks can be skipped.
	var chunk_touches_room = false
	var chunk_rect = Rect2i(
		origin.x - 1, origin.y - 1,
		chunk_size + 2, chunk_size + 2   # +1 margin each side for corner sampling
	)
	for room in _rooms:
		var r_interior: Rect2i = room["rect"]
		var r_wall: int = room["wall"]
		var r_outer = Rect2i(
			r_interior.position - Vector2i(r_wall, r_wall),
			r_interior.size + Vector2i(r_wall * 2, r_wall * 2)
		)
		if r_outer.intersects(chunk_rect):
			chunk_touches_room = true
			break

	for ly in range(chunk_size + 1):
		for lx in range(chunk_size + 1):
			var wx = origin.x + lx
			var wy = origin.y + ly

			var solid: bool
			var locked: bool = false

			if above_open_sky:
				# Open air above the surface: nothing solid, fully editable.
				solid = false
				locked = false
			elif not in_world:
				# Outside the world: solid unbreakable rock.
				solid = true
				locked = true
			else:
				# Distance from each region edge.
				var dist_left = wx - rx0
				var dist_right = rx1 - wx
				var dist_top = wy - ry0
				var dist_bottom = ry1 - wy

				# Is this corner inside the border?
				var on_left = dist_left < border_thickness
				var on_right = dist_right <= border_thickness
				var on_top = dist_top < border_thickness
				var on_bottom = dist_bottom <= border_thickness

				# On a surface region with open sky there is no top border.
				if open_sky:
					on_top = false

				# Fade the border out alongside the caves so the surface stays walkable between biomes.
				if (seam_left and on_left) or (seam_right and on_right):
					var seam_surface_y = _surface_height_at(biome, wx, ry0)
					var seam_cutoff = seam_surface_y + int(round(biome.cave_fade_depth * 0.5))
					if wy < seam_cutoff:
						if seam_left and on_left:
							on_left = false
						if seam_right and on_right:
							on_right = false

				if biome == null:
					# No biome: bedrock.
					solid = true
					locked = true
				elif on_left or on_right or on_top or on_bottom:
					# Region border: also bedrock.
					solid = true
					locked = true
				else:
					# Playable dungeon area.
					if open_sky:
						# Hilly surface that fades into caves with depth.
						var surface_y = _surface_height_at(biome, wx, ry0)
						if wy < surface_y:
							solid = false   # open sky / air
						else:
							solid = _solid_with_cave_fade(biome, noise, wx, wy, surface_y, thr)
					else:
						solid = noise.get_noise_2d(wx, wy) > thr

			# Prebuilt rooms override the generated noise, but not player edits, which are
			# applied afterwards so spawn and boss rooms can still be dug through.
			if not locked and chunk_touches_room:
				var rs = _room_corner_state(wx, wy)
				if rs == 1:
					solid = true    # room wall
				elif rs == 2:
					solid = false   # room interior (air)

			# Player edits override the generated world but never the border, which keeps
			# bedrock unbreakable even if override_corner() is called on it.
			if not locked and not _corner_overrides.is_empty():
				var key = Vector2i(wx, wy)
				if _corner_overrides.has(key):
					solid = _corner_overrides[key]

			chunk.set_corner(lx, ly, solid)
			chunk.set_locked(lx, ly, locked)


##Returns the y coordinate, in tiles, where the surface starts.
##Uses a separate noise instance so the result is hills rather than caves.
##The same noise is used across every surface-level biome.
func _surface_height_at(biome: BiomeData, world_x: int, region_top_tile_y: int) -> int:
	var base = region_top_tile_y + border_thickness + biome.surface_air_height
	if biome.surface_variation <= 0:
		return base
	var hn = _get_surface_noise(biome)
	# Sampling along one axis only gives a 1D heightmap.
	var h = hn.get_noise_2d(world_x, 0.0) # min -1 max 1
	return base + int(round(h * biome.surface_variation))


##Decides whether a tile is solid, blending the solid surface crust into the cave noise.
##Near the surface the ground is almost fully solid; at cave_fade_depth it is pure cave noise.
func _solid_with_cave_fade(biome: BiomeData, noise: FastNoiseLite, wx: int, wy: int, surface_y: int, thr: float) -> bool:
	var depth = wy - surface_y
	var fade = float(biome.cave_fade_depth)
	# t = 0 at the surface, 1 at or below cave_fade_depth.
	var t = clampf(float(depth) / maxf(fade, 1.0), 0.0, 1.0)
	# A cell is solid when noise > eff_thr. To make the shallow ground a solid crust,
	# the threshold starts very low (-1 means almost everything is solid) and rises to
	# the biome's real threshold with depth, letting the caves open up gradually.
	var eff_thr = lerpf(-1.0, thr, t)
	return noise.get_noise_2d(wx, wy) > eff_thr


##Renders a chunk: builds a corner mask per tile and converts it into atlas coordinates.
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

			# Border tiles use the shared bedrock atlas; everything else uses the biome atlas.
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
				var bg_pick: Vector2i
				if use_border:
					bg_pick = bg_coord  # The border has a single background tile.
				else:
					var h = (wp.x * 2246822519 ^ wp.y * 3266489917 ^ world_seed) & 0x7FFFFFFF
					var idx = h % 8
					bg_pick = Vector2i(bg_coord.x + idx % 4, bg_coord.y + idx / 4)
				bg_layer.set_cell(wp, bg_src, bg_pick)
			else:
				bg_layer.erase_cell(wp)
				
			var atlas = Vector2i(mask % cols, mask / cols)
			fg_layer.set_cell(wp, src, atlas)


##Returns true if all four corners of a tile are bedrock.
func _tile_is_border(chunk: WorldChunk, tx: int, ty: int) -> bool:
	return chunk.get_locked(tx, ty) and chunk.get_locked(tx + 1, ty) \
		and chunk.get_locked(tx, ty + 1) and chunk.get_locked(tx + 1, ty + 1)


##Converts the four corners of cell (tx, ty) into a 4-bit mask used as an atlas index.
##Reference diagram: https://imgur.com/a/mZ8i4yG
func _corner_mask(chunk: WorldChunk, tx: int, ty: int) -> int:
	var tl = 1 if chunk.get_corner(tx, ty) else 0
	var tr = 1 if chunk.get_corner(tx + 1, ty) else 0
	var bl = 1 if chunk.get_corner(tx, ty + 1) else 0
	var br = 1 if chunk.get_corner(tx + 1, ty + 1) else 0
	return tl | (tr << 1) | (bl << 2) | (br << 3)


# --- Noise and helpers ---
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

##Returns true if the corner at this world position is bedrock.
##Useful for gameplay code, e.g. hiding the mining tooltip on border tiles.
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
	
# --- Vines ---
##true if every tile this pixel rect touches is air and inside the chunks corner cache
func _pixel_rect_is_air(chunk: WorldChunk, origin: Vector2i, rect: Rect2i) -> bool:
	var first_tx = floori(float(rect.position.x) / tile_pixel_size) - origin.x
	var last_tx  = floori(float(rect.position.x + rect.size.x - 1) / tile_pixel_size) - origin.x
	var first_ty = floori(float(rect.position.y) / tile_pixel_size) - origin.y
	var last_ty  = floori(float(rect.position.y + rect.size.y - 1) / tile_pixel_size) - origin.y
	for cx in range(first_tx, last_tx + 1):
		if cx < 0 or cx >= chunk_size:
			return false
		for cy in range(first_ty, last_ty + 1):
			if cy < 0 or cy >= chunk_size:
				return false
			if chunk.get_corner(cx, cy):
				return false
	return true


##grows a vine downwards from the ceiling at tile (tx, ty)
##random length, random parts, random ending. returns true if one got placed
func _try_spawn_vine(chunk: WorldChunk, vine: VineData, tx: int, ty: int, origin: Vector2i, occupied: Array[Rect2i], seed_hash: int) -> bool:
	if vine.segment_textures.is_empty() or vine.end_textures.is_empty():
		return false

	#own rng seeded from the tile, so the exact same vine regrows on every chunk reload
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_hash

	var want = rng.randi_range(vine.min_segments, maxi(vine.min_segments, vine.max_segments))
	var base_center_x = tx * tile_pixel_size + origin.x * tile_pixel_size + tile_pixel_size / 2
	var y = (origin.y + ty) * tile_pixel_size   #vine starts flush at the ceiling
	var pieces: Array[Dictionary] = []

	#grow segment by segment, stop early if we run into terrain / the chunk edge
	for s in range(want):
		var tex: Texture2D = vine.segment_textures[rng.randi() % vine.segment_textures.size()]
		var tsize = Vector2i(tex.get_size())
		var sw = int(ceil(tsize.x * decoration_scale))
		var sh = int(ceil(tsize.y * decoration_scale))
		var jitter = 0
		if vine.wiggle > 0:
			jitter = int(round(rng.randi_range(-vine.wiggle, vine.wiggle) * decoration_scale))
		var rect = Rect2i(base_center_x - sw / 2 + jitter, y, sw, sh)
		if not _pixel_rect_is_air(chunk, origin, rect):
			break
		pieces.append({"tex": tex, "rect": rect})
		y += sh - int(round(vine.segment_overlap * decoration_scale))
		
		#taper off early sometimes so not every vine hits its rolled length
		if pieces.size() >= vine.min_segments and rng.randf() < vine.early_stop_chance:
			break

	#cap it off. if the tip doesnt fit, drop the last segment and try one step higher
	var end_tex: Texture2D = vine.end_textures[rng.randi() % vine.end_textures.size()]
	var e_size = Vector2i(end_tex.get_size())
	var ew = int(ceil(e_size.x * decoration_scale))
	var eh = int(ceil(e_size.y * decoration_scale))
	var capped = false
	while not pieces.is_empty():
		var e_rect = Rect2i(base_center_x - ew / 2, y, ew, eh)
		if _pixel_rect_is_air(chunk, origin, e_rect):
			pieces.append({"tex": end_tex, "rect": e_rect})
			capped = true
			break
		var last: Dictionary = pieces.pop_back()
		var last_rect: Rect2i = last["rect"]
		y = last_rect.position.y

	if not capped:
		return false
	#pieces includes the ending, so -1 = actual segment count
	if pieces.size() - 1 < vine.min_segments:
		return false

	var bounds: Rect2i = pieces[0]["rect"]
	for p in pieces:
		bounds = bounds.merge(p["rect"])
	if not vine.allow_overlap:
		for r in occupied:
			if r.intersects(bounds):
				return false

	#one root node per vine so unloading frees the whole thing in one go
	var root = Node2D.new()
	add_child(root)
	for p in pieces:
		var sprite = Sprite2D.new()
		sprite.texture = p["tex"]
		sprite.centered = false
		sprite.scale = Vector2(decoration_scale, decoration_scale)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2((p["rect"] as Rect2i).position)
		root.add_child(sprite)

	if vine.is_light_source:
		var tip: Rect2i = pieces[pieces.size() - 1]["rect"]
		var light = PointLight2D.new()
		light.texture = vine.light_texture if vine.light_texture != null else DecorationData._get_default_light_texture()
		light.color = vine.light_color
		light.energy = vine.light_energy
		light.texture_scale = vine.light_texture_scale
		light.z_index = 2
		light.position = Vector2(tip.position) + Vector2(tip.size) * 0.5 + vine.light_offset * decoration_scale
		root.add_child(light)

	chunk.decorations.append(root)
	if not vine.allow_overlap:
		occupied.append(bounds)
	return true
	
	
# --- Depth Shading ---
func _darkness_wall_at(wx: int, wy: int) -> bool:
	var cp = Vector2i(floori(float(wx) / chunk_size), floori(float(wy) / chunk_size))
	var chunk: WorldChunk = _loaded_chunks.get(cp)
	if chunk == null:
		return true   # off-screen frontier -> treat as solid
	var origin = chunk.world_origin()
	var lx = wx - origin.x
	var ly = wy - origin.y
	return chunk.get_corner(lx, ly) and chunk.get_corner(lx + 1, ly) \
		and chunk.get_corner(lx, ly + 1) and chunk.get_corner(lx + 1, ly + 1)


##rebuilds ONE darkness texture spanning every loaded chunk. one distance field,
##so there are no per-chunk seams. called at most once per frame when dirty.
func _update_darkness_overlay() -> void:
	if not depth_shading_enabled or _loaded_chunks.is_empty():
		if _darkness_overlay != null:
			_darkness_overlay.visible = false
		return

	var t0 = Time.get_ticks_usec()

	var step = maxi(1, depth_shading_downsample)
	var pad = maxi(1, depth_darkness_range)

	var pc = _last_player_chunk
	var cmin = pc - Vector2i(view_radius_chunks, view_radius_chunks)
	var cmax = pc + Vector2i(view_radius_chunks, view_radius_chunks)

	var tmin = Vector2i(cmin.x * chunk_size - pad, cmin.y * chunk_size - pad)
	var tile_w = (cmax.x - cmin.x + 1) * chunk_size + pad * 2
	var tile_h = (cmax.y - cmin.y + 1) * chunk_size + pad * 2

	#low-res grid: one cell per `step` tiles
	var w = (tile_w + step - 1) / step
	var h = (tile_h + step - 1) / step
	if w <= 0 or h <= 0:
		return

	var big = 1 << 20
	var dist = PackedInt32Array()
	dist.resize(w * h)
	dist.fill(big)

	#seed: a low-res cell is air (0) if ANY tile in its block is air.
	#read corner_solid directly -> no per-tile get_corner() method calls
	for cp in _loaded_chunks.keys():
		if cp.x < cmin.x or cp.x > cmax.x or cp.y < cmin.y or cp.y > cmax.y:
			continue
		var chunk: WorldChunk = _loaded_chunks[cp]
		var cs = chunk.corner_solid
		var stride = chunk_size + 1
		var base_tx = cp.x * chunk_size - tmin.x
		var base_ty = cp.y * chunk_size - tmin.y
		for ly in range(chunk_size):
			var lo_row = ((base_ty + ly) / step) * w
			var row_c = ly * stride
			var row_n = (ly + 1) * stride
			for lx in range(chunk_size):
				#tile is opaque only if all 4 corners solid -> otherwise the block is air
				if cs[row_c + lx] != 0 and cs[row_c + lx + 1] != 0 \
					and cs[row_n + lx] != 0 and cs[row_n + lx + 1] != 0:
					continue
				dist[lo_row + (base_tx + lx) / step] = 0

	#chamfer 3-4 distance transform, in low-res cells
	for y in range(h):
		for x in range(w):
			var i = y * w + x
			var d = dist[i]
			if d == 0: continue
			if x > 0: d = mini(d, dist[i - 1] + 3)
			if y > 0: d = mini(d, dist[i - w] + 3)
			if x > 0 and y > 0: d = mini(d, dist[i - w - 1] + 4)
			if x < w - 1 and y > 0: d = mini(d, dist[i - w + 1] + 4)
			dist[i] = d
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var i = y * w + x
			var d = dist[i]
			if d == 0: continue
			if x < w - 1: d = mini(d, dist[i + 1] + 3)
			if y < h - 1: d = mini(d, dist[i + w] + 3)
			if x < w - 1 and y < h - 1: d = mini(d, dist[i + w + 1] + 4)
			if x > 0 and y < h - 1: d = mini(d, dist[i + w - 1] + 4)
			dist[i] = d

	var range_units = maxf(1.0, float(depth_darkness_range) / float(step) * 3.0)
	var buf = PackedByteArray()
	buf.resize(w * h * 4)
	for i in range(w * h):
		var t = clampf(float(dist[i]) / range_units, 0.0, 1.0)
		buf[i * 4 + 3] = int(round(t * depth_max_darkness * 255.0))

	var img = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, buf)
	var tex = ImageTexture.create_from_image(img)

	if _darkness_overlay == null:
		_darkness_overlay = Sprite2D.new()
		_darkness_overlay.centered = false
		_darkness_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_darkness_overlay.z_index = 2
		add_child(_darkness_overlay)
	_darkness_overlay.texture = tex
	_darkness_overlay.scale = Vector2(tile_pixel_size * step, tile_pixel_size * step)
	_darkness_overlay.position = Vector2(tmin.x * tile_pixel_size, tmin.y * tile_pixel_size)
	_darkness_overlay.visible = true

	var dt = Time.get_ticks_usec() - t0
	_dbg_darkness_usec = dt
	_dbg_frame_usec += dt


# --- Decorations ---
func _spawn_decorations(chunk: WorldChunk) -> void:
	if chunk.biome == null or chunk.biome.decorations.is_empty():
		return

	var origin = chunk.world_origin()

	#pixel rects of decos already placed in this chunk so they dont clip into each other
	var occupied: Array[Rect2i] = []

	for ty in range(chunk_size):
		for tx in range(chunk_size):
			#this tile has to be air
			if chunk.get_corner(tx, ty):
				continue

			#needs solid ground below (floor decos) or a solid ceiling above (hanging decos)
			#ty == 0 has no tile above inside this chunks corner cache -> no ceiling decos there
			var has_floor = chunk.get_corner(tx, ty + 1)
			var has_ceiling = ty > 0 and chunk.get_corner(tx, ty - 1)
			if not has_floor and not has_ceiling:
				continue

			#rng per tile
			var wx = origin.x + tx
			var wy = origin.y + ty
			var h = (wx * 2246822519 ^ wy * 3266489917 ^ world_seed) & 0x7FFFFFFF #holy math

			#pick a decoration out of the list
			#each decoration gets an independent rng roll so weights are independent
			#danke minecraft wow ihr seid die geilsten, komplett abgeschaut
			for i in range(chunk.biome.decorations.size()):
				var deco: DecorationData = chunk.biome.decorations[i]
				
				#vines bring their own textures and build themselves
				if deco is VineData:
					if not has_ceiling:
						continue
					var v_hash = (h ^ (i * 2654435761)) & 0x7FFFFFFF
					var v_roll = float(v_hash) / float(0x7FFFFFFF)
					if v_roll > deco.spawn_chance:
						continue
					if _try_spawn_vine(chunk, deco, tx, ty, origin, occupied, v_hash):
						break
					continue
				
				if deco.texture == null:
					continue

				var is_floor = deco.placement == DecorationData.Placement.FLOOR
				if is_floor and not has_floor:
					continue
				if not is_floor and not has_ceiling:
					continue

				#roll per dec
				var roll_hash = (h ^ (i * 2654435761)) & 0x7FFFFFFF
				var roll = float(roll_hash) / float(0x7FFFFFFF)
				if roll > deco.spawn_chance:
					continue

				var base_size: Vector2i = DECO_SIZE[deco.size_category]
				var size = Vector2i(
					int(ceil(base_size.x * decoration_scale)),
					int(ceil(base_size.y * decoration_scale))
				)

				#FLOOR: bottom of the deco rests on the solid tile below -> grow upwards
				#CEILING: top of the deco sticks to the solid tile above -> hang downwards
				var top_pixel_y: int
				if is_floor:
					top_pixel_y = (wy + 1) * tile_pixel_size - size.y
				else:
					top_pixel_y = wy * tile_pixel_size

				#center the decoration on the tile
				var left_pixel_x = wx * tile_pixel_size + tile_pixel_size / 2 - size.x / 2

				#tile span the deco body covers
				var first_tile_x = floori(float(left_pixel_x) / tile_pixel_size)
				var last_tile_x  = floori(float(left_pixel_x + size.x - 1) / tile_pixel_size)
				var first_tile_y = floori(float(top_pixel_y) / tile_pixel_size)
				var last_tile_y  = floori(float(top_pixel_y + size.y - 1) / tile_pixel_size)

				#local row of the solid surface the deco anchors to
				var lcy_anchor = (ty + 1) if is_floor else (ty - 1)

				#every tile the deco touches needs a solid anchor (danke johannna das alle unterschiedlich groß sind du bist so tuff)
				#same for air across the body
				var fits = true
				for cx in range(first_tile_x, last_tile_x + 1):
					var lcx = cx - origin.x

					#check if anchor tile exists in chnk and is solid
					if lcx < 0 or lcx >= chunk_size or lcy_anchor < 0 or lcy_anchor > chunk_size:
						fits = false
						break
					if not chunk.get_corner(lcx, lcy_anchor):
						fits = false
						break

					#cycle through every tile the deco body covers and check if air
					#so now we can add big decorations without them stuck in ceiling/floor
					for cy in range(first_tile_y - origin.y, last_tile_y - origin.y + 1):
						if cy < 0 or cy > chunk_size:
							continue
						if chunk.get_corner(lcx, cy):
							fits = false
							break
					if not fits:
						break

				if not fits:
					continue

				#dont overlap a deco we already placed in this chunk
				var my_rect = Rect2i(left_pixel_x, top_pixel_y, size.x, size.y)
				var overlaps = false
				for r in occupied:
					if r.intersects(my_rect):
						overlaps = true
						break
				if overlaps:
					continue

				#spawn the sprite
				var sprite = Sprite2D.new()
				sprite.texture = deco.texture
				sprite.centered = false
				sprite.scale = Vector2(decoration_scale, decoration_scale)
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				sprite.position = Vector2(left_pixel_x, top_pixel_y)
				add_child(sprite)
				chunk.decorations.append(sprite)
				occupied.append(my_rect)

				#optional light source
				if deco.is_light_source:
					var light = PointLight2D.new()
					light.texture = deco.light_texture if deco.light_texture != null else DecorationData._get_default_light_texture()
					light.color = deco.light_color
					light.energy = deco.light_energy
					light.texture_scale = deco.light_texture_scale
					light.z_index = 2
					light.position = Vector2(
						left_pixel_x + size.x * 0.5,
						top_pixel_y + size.y * 0.5
					) + deco.light_offset * decoration_scale
					add_child(light)
					chunk.decorations.append(light)

				#only one decoration per tile (first one that gets here wins the seed (sperm race ahh moment))
				break
				

# --- Enemy spawn markers: at most one per chunk ---
	# Deterministic per-chunk hash again, same approach as the decorations.
	var enemy_hash = (origin.x * 2246822519 ^ origin.y * 3266489917 ^ world_seed) & 0x7FFFFFFF
	var enemy_roll = float(enemy_hash) / float(0x7FFFFFFF)
	var near_room = _chunk_touches_room(origin, 2)
	if true:
		# Scan the chunk for tiles an enemy could stand on.
		var candidates: Array[Vector2i] = []
		for ty in range(chunk_size):
			for tx in range(chunk_size):
				# floor tile below must be solid
				if not chunk.get_corner(tx, ty + 1):
					continue
				# tile itself must be air
				if chunk.get_corner(tx, ty):
					continue
				# never spawn enemies inside spawn/boss rooms
				if near_room and _tile_in_any_room(origin.x + tx, origin.y + ty, 1):
					continue
				# left and right floor tiles must be solid (no platform edge)
				if tx == 0 or tx >= chunk_size - 1:
					continue
				if not chunk.get_corner(tx - 1, ty + 1):
					continue
				if not chunk.get_corner(tx + 1, ty + 1):
					continue
				# must have 4 tiles of air clearance above
				var fits = true
				for cy in range(ty - 3, ty + 1):
					if cy < 0 or cy > chunk_size:
						continue
					if chunk.get_corner(tx, cy):
						fits = false
						break
				if not fits:
					continue
				candidates.append(Vector2i(tx, ty))

		if not candidates.is_empty():
			# Pick one candidate deterministically.
			var pick = candidates[enemy_hash % candidates.size()]
			var wx = origin.x + pick.x
			var wy = origin.y + pick.y
			var marker = Marker2D.new()
			marker.name = "EnemySpawn_%d_%d" % [wx, wy]
			marker.position = Vector2(
				(wx + 0.5) * tile_pixel_size,
				(wy + 1) * tile_pixel_size
			)
			marker.add_to_group("enemy_spawn")
			add_child(marker)
			_enemy_spawns[chunk.chunk_pos] = [marker.position]
			chunk.decorations.append(marker)

func debug_draw_enemy_spawns() -> void:
	for positions in _enemy_spawns.values():
		for pos in positions:
			var dot = Node2D.new()
			dot.global_position = pos
			dot.z_index = 100
			add_child(dot) 
			dot.add_to_group("debug_enemy_spawn_dots")
		
			var circle = func():
				dot.draw_circle(Vector2.ZERO, 8, Color.RED)
			dot.connect("draw", circle)
			dot.queue_redraw()

# --- Public API ---
# Only the functions below are intended to be called from outside this file.
# Everything else is internal and may change without notice; if you need
# behaviour that is not exposed here, please open an issue rather than calling
# into the internals, which are difficult to debug once bypassed.

##Forces a full reload of the world around the player. Not needed under normal use.
func regenerate() -> void:
	for cp in _loaded_chunks.keys():
		_unload_chunk(cp)
	_loaded_chunks.clear()
	_corner_overrides.clear()
	_biome_noise_cache.clear()
	_taken_items.clear()
	_build_world_layout()
	_last_player_chunk = Vector2i(0x7FFFFFFF, 0x7FFFFFFF)


##Sets a corner to solid or air. This is the only supported way to place or break blocks.
##Only the world data is updated; call refresh_chunk_at(world_x, world_y) afterwards
##to update the visuals.
##Bedrock cannot be changed; such calls are silently ignored.
##Returns true if the change was applied, false if it was blocked by bedrock.
func override_corner(world_corner: Vector2i, solid: bool) -> bool:
	if is_corner_locked(world_corner):
		return false
	_corner_overrides[world_corner] = solid
	return true


##Re-renders the chunk containing (world_x, world_y).
##Call this after changing the world, e.g. after the player breaks a block.
func refresh_chunk_at(world_x: int, world_y: int) -> void:
	var cp = Vector2i(floori(float(world_x) / chunk_size), floori(float(world_y) / chunk_size))
	var chunk: WorldChunk = _loaded_chunks.get(cp)
	if chunk == null:
		return
	_generate_chunk_corners(chunk)
	_render_chunk(chunk)
	_darkness_dirty = true


##Returns true if a spawn room exists in this world.
func has_spawn_point() -> bool:
	return _spawn_tile.x != 0x7FFFFFFF


##Returns the tile coordinate where the player spawns.
func get_spawn_tile() -> Vector2i:
	if not has_spawn_point():
		return Vector2i.ZERO
	return _spawn_tile


##Returns the pixel coordinate where the player spawns.
func get_spawn_position() -> Vector2:
	if not has_spawn_point():
		return Vector2.ZERO
	
	var local_pos = Vector2(
		(_spawn_tile.x + 0.5) * tile_pixel_size,
		_spawn_tile.y * tile_pixel_size
	)
	
	return local_pos

##Returns the spawn room interior as a pixel-space Rect2 (local coordinates).
##Size is zero if there is no spawn room.
func get_spawn_room_rect_px() -> Rect2:
	return Rect2(
		Vector2(_spawn_room_rect.position) * tile_pixel_size,
		Vector2(_spawn_room_rect.size) * tile_pixel_size
	)

func _place_tutorial() -> void:
	if tutorial_scene == null or not has_spawn_point():
		return
	var node: Node2D = tutorial_scene.instantiate()
	node.position = get_spawn_room_rect_px().position + tutorial_offset
	add_child(node)

# --- Debug timing ---
var _dbg_frame_usec: int = 0
var _dbg_loaded_this_frame: int = 0
var _dbg_unloaded_this_frame: int = 0
# Accumulators for the load sub-phases, in microseconds.
var _dbg_gen: int = 0
var _dbg_render: int = 0
var _dbg_deco: int = 0

var _dbg_worst = 0.0
var _dbg_accum = 0.0

var _dbg_darkness_usec: int = 0
var _dbg_darkness_worst = 0.0


func _dbg_reset_frame() -> void:
	_dbg_frame_usec = 0
	_dbg_loaded_this_frame = 0
	_dbg_unloaded_this_frame = 0
	_dbg_gen = 0
	_dbg_render = 0
	_dbg_deco = 0
	_dbg_darkness_usec = 0

func _dbg_report(delta: float) -> void:
	_dbg_accum += delta
	var frame_ms = _dbg_frame_usec / 1000.0
	if frame_ms > _dbg_worst:
		_dbg_worst = frame_ms
	var dark_ms = _dbg_darkness_usec / 1000.0
	if dark_ms > _dbg_darkness_worst:
		_dbg_darkness_worst = dark_ms
	if _dbg_accum >= 1.0:
		print("[WORLDGEN] worst frame %.2fms | worst darkness %.2fms | unloaded %d" % [_dbg_worst, _dbg_darkness_worst, _dbg_unloaded_this_frame])
		_dbg_worst = 0.0
		_dbg_darkness_worst = 0.0
		_dbg_accum = 0.0
