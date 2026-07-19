extends Node

signal grid_changed
signal size_changed

# Emitted (with the row delta, always +1) whenever expand_down() re-keys
# existing cells to compensate for ORIGIN moving - the currently falling
# piece isn't tracked by GridManager, so it listens for this to shift its
# own anchor_cell by the same amount and stay visually put.
signal origin_row_shifted(delta: int)

# Emitted after stamp() places a piece, with exactly the cells it touched
# (already filtered to in-bounds ones) and their building type.
signal cells_placed(cells: Array[Vector2i], building_type: int)

const DEFAULT_ORIGIN := Vector2(224, 32)
const CELL_SIZE := 32

# Mutable (not const): expand_down() moves this up by one tile per expansion
# so the field grows by extending its top boundary rather than its bottom -
# see expand_down() below. Reset to DEFAULT_ORIGIN on every new game.
var ORIGIN := DEFAULT_ORIGIN

# Mutable (not const) because the field size is meant to be resizable during
# play in a future update; for now it's just seeded once from
# GameBalance.grid_width/grid_height at game start via configure_size().
var COLS := 6
var ROWS := 6

const NEIGHBOR_DIRS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]

# Orthogonal-only - this is what ResourceManager groups tiles by for the
# efficiency bonus (diagonal touches don't count as connected for that).
const ORTHOGONAL_DIRS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
]

const BROKEN_VISUALS_PATH := "res://resources/broken_visuals.tres"

var _building_types: Dictionary = {} # Vector2i(col,row) -> BuildingData.BuildingType
var _cell_sprites: Dictionary = {} # Vector2i(col,row) -> Sprite2D
var _atlas_cache: Dictionary = {} # (building_type*100+tile_index) -> AtlasTexture
var _render_container: Node2D

# Broken buildings: still solid (block pieces), produce nothing, rendered
# with the same connectivity-tiling scheme as buildings but against their
# own "is this neighbor also broken" check.
var _broken_visuals: BrokenVisuals = load(BROKEN_VISUALS_PATH)
var _broken_cells: Dictionary = {} # Vector2i(col,row) -> true
var _broken_sprites: Dictionary = {} # Vector2i(col,row) -> Sprite2D
var _broken_atlas_cache: Dictionary = {} # tile_index -> AtlasTexture


func set_render_container(container: Node2D) -> void:
	_render_container = container


func cell_to_world(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell) * CELL_SIZE


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS


func is_occupied(cell: Vector2i) -> bool:
	return _building_types.has(cell) or _broken_cells.has(cell)


func is_broken(cell: Vector2i) -> bool:
	return _broken_cells.has(cell)


func get_building_types() -> Dictionary:
	return _building_types.duplicate()


func get_cell_sprite(cell: Vector2i) -> Sprite2D:
	return _cell_sprites.get(cell)


# All cells of the same building type as `cell`, connected orthogonally -
# matches how ResourceManager groups tiles for the efficiency bonus. Empty
# if `cell` isn't a building.
func get_connected_group(cell: Vector2i) -> Array[Vector2i]:
	if not _building_types.has(cell):
		return []
	var building_type: int = _building_types[cell]
	var group: Array[Vector2i] = []
	var visited: Dictionary = {cell: true}
	var stack: Array[Vector2i] = [cell]
	while not stack.is_empty():
		var current: Vector2i = stack.pop_back()
		group.append(current)
		for dir in ORTHOGONAL_DIRS:
			var neighbor := current + dir
			if visited.has(neighbor):
				continue
			if _building_types.get(neighbor, -1) == building_type:
				visited[neighbor] = true
				stack.append(neighbor)
	return group


func configure_size(width: int, height: int) -> void:
	ORIGIN = DEFAULT_ORIGIN
	COLS = width
	ROWS = height
	size_changed.emit()


# Adds a new row of headroom by growing the field by 1 row. The bottom of
# the field (funnel) stays exactly where it is; instead ORIGIN moves up by
# one tile and every existing cell's row index is bumped by 1 to match, so
# their world position - and the currently falling piece's, once it
# compensates via origin_row_shifted - is completely unchanged. Only the top
# boundary (tunnel) actually moves, extending upward.
func expand_down() -> void:
	ROWS += 1
	ORIGIN.y -= CELL_SIZE
	_building_types = _shift_keys_down(_building_types)
	_cell_sprites = _shift_keys_down(_cell_sprites)
	_broken_cells = _shift_keys_down(_broken_cells)
	_broken_sprites = _shift_keys_down(_broken_sprites)

	origin_row_shifted.emit(1)
	size_changed.emit()
	grid_changed.emit()


func _shift_keys_down(dict: Dictionary) -> Dictionary:
	var shifted: Dictionary = {}
	for cell in dict:
		shifted[cell + Vector2i(0, 1)] = dict[cell]
	return shifted


func clear() -> void:
	for sprite in _cell_sprites.values():
		sprite.queue_free()
	_cell_sprites.clear()
	_building_types.clear()

	for sprite in _broken_sprites.values():
		sprite.queue_free()
	_broken_sprites.clear()
	_broken_cells.clear()

	grid_changed.emit()


# Overwrites the given cells with building_type (replacing whatever was
# there), then recomputes tile art for those cells and their 8 neighbors
# (orthogonal + diagonal, since corner tiles depend on diagonal occupancy too)
# so same-type borders disappear and newly-exposed edges reappear.
func stamp(cells: Array[Vector2i], building_type: int) -> void:
	var touched: Array[Vector2i] = []
	for cell in cells:
		if not is_in_bounds(cell):
			continue
		_building_types[cell] = building_type
		touched.append(cell)
	for cell in touched:
		_update_cell_sprite(cell)
		for dir in NEIGHBOR_DIRS:
			var neighbor := cell + dir
			if _building_types.has(neighbor):
				_update_cell_sprite(neighbor)
	if not touched.is_empty():
		cells_placed.emit(touched, building_type)
		grid_changed.emit()


# Turns a placed building into a broken tile: still solid, produces nothing.
func break_cell(cell: Vector2i) -> void:
	if not _building_types.has(cell):
		return

	_building_types.erase(cell)
	var old_sprite: Sprite2D = _cell_sprites.get(cell)
	if old_sprite != null:
		old_sprite.queue_free()
		_cell_sprites.erase(cell)

	_broken_cells[cell] = true
	_update_broken_sprite(cell)
	for dir in NEIGHBOR_DIRS:
		var neighbor := cell + dir
		if _building_types.has(neighbor):
			_update_cell_sprite(neighbor)
		if _broken_cells.has(neighbor):
			_update_broken_sprite(neighbor)

	grid_changed.emit()


# Clears a broken tile back to empty - it's no longer solid, so it becomes
# eligible to be picked up as a ghost hole again.
func repair_broken(cell: Vector2i) -> void:
	if not _broken_cells.has(cell):
		return

	_broken_cells.erase(cell)
	var sprite: Sprite2D = _broken_sprites.get(cell)
	if sprite != null:
		sprite.queue_free()
		_broken_sprites.erase(cell)

	for dir in NEIGHBOR_DIRS:
		var neighbor := cell + dir
		if _broken_cells.has(neighbor):
			_update_broken_sprite(neighbor)

	grid_changed.emit()


func _update_cell_sprite(cell: Vector2i) -> void:
	var building_type: int = _building_types[cell]
	var pattern := TetrominoData.neighbor_pattern(cell, func(p): return _building_types.get(p, -1) == building_type)
	var tile_index: int = TetrominoData.tile_for_pattern(pattern)
	var sprite: Sprite2D = _cell_sprites.get(cell)
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.centered = false
		sprite.position = cell_to_world(cell)
		_render_container.add_child(sprite)
		_cell_sprites[cell] = sprite
	sprite.texture = _atlas_for(building_type, tile_index)


func _atlas_for(building_type: int, tile_index: int) -> AtlasTexture:
	var key := building_type * 100 + tile_index
	if not _atlas_cache.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = BuildingData.texture_for(building_type)
		atlas.region = Rect2((tile_index - 1) * CELL_SIZE, 0, CELL_SIZE, CELL_SIZE)
		_atlas_cache[key] = atlas
	return _atlas_cache[key]


func _update_broken_sprite(cell: Vector2i) -> void:
	var pattern := TetrominoData.neighbor_pattern(cell, func(p): return _broken_cells.has(p))
	var tile_index: int = TetrominoData.tile_for_pattern(pattern)
	var sprite: Sprite2D = _broken_sprites.get(cell)
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.centered = false
		sprite.position = cell_to_world(cell)
		_render_container.add_child(sprite)
		_broken_sprites[cell] = sprite
	sprite.texture = _broken_atlas_for(tile_index)


func _broken_atlas_for(tile_index: int) -> AtlasTexture:
	if not _broken_atlas_cache.has(tile_index):
		var atlas := AtlasTexture.new()
		atlas.atlas = _broken_visuals.tile_sheet
		atlas.region = Rect2((tile_index - 1) * CELL_SIZE, 0, CELL_SIZE, CELL_SIZE)
		_broken_atlas_cache[tile_index] = atlas
	return _broken_atlas_cache[tile_index]
