extends Node2D

# Marks empty cells that a falling piece can never reach because something
# solid (a building or a broken tile) is already above them in the same
# column (the classic Tetris "hole"). Rendered with the same connectivity-
# tiling scheme as buildings, just checking "is this neighbor also a ghost".
#
# Ghosts are permanent once discovered: this only ever ADDS newly-found
# holes, never removes existing ones. They must stay put even if the thing
# that originally covered them later goes away (e.g. a broken tile above a
# ghost gets repair_broken()'d back into a ghost itself) - a ghost cell
# should never wink out of existence.
#
# Each time a new piece spawns, every ghost looks at its 4 orthogonal
# neighbors: a building there gets broken (stops producing); failing that, a
# broken tile there turns into a new ghost (the infestation spreads);
# otherwise the ghost does nothing that turn.

signal ghost_count_changed(count: int)

const VISUALS_PATH := "res://resources/ghost_visuals.tres"

const ORTHOGONAL_DIRS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
]

var _visuals: GhostVisuals = load(VISUALS_PATH)
var _atlas_cache: Dictionary = {}
var _ghost_sprites: Dictionary = {} # Vector2i(col,row) -> Sprite2D, persists once created


func _ready() -> void:
	GridManager.grid_changed.connect(_discover_and_refresh)
	GridManager.size_changed.connect(_discover_and_refresh)
	GridManager.origin_row_shifted.connect(_on_origin_row_shifted)
	GameManager.game_restarted.connect(_on_game_restarted)
	_discover_and_refresh()


func _on_game_restarted() -> void:
	for sprite in _ghost_sprites.values():
		sprite.queue_free()
	_ghost_sprites.clear()
	ghost_count_changed.emit(0)


# GridManager.expand_down() moves ORIGIN up by one tile and bumps every
# existing solid cell's row by the same amount to compensate, keeping
# everything visually still (see grid_manager.gd). Ghosts aren't tracked by
# GridManager, so they have to do the same compensation themselves.
func _on_origin_row_shifted(delta: int) -> void:
	var shifted: Dictionary = {}
	for cell in _ghost_sprites:
		shifted[cell + Vector2i(0, delta)] = _ghost_sprites[cell]
	_ghost_sprites = shifted
	_redraw_all()


func _discover_and_refresh() -> void:
	var discovered := false
	for cell in _compute_hole_cells():
		if not _ghost_sprites.has(cell):
			_ghost_sprites[cell] = _make_ghost_sprite(cell)
			discovered = true
	_redraw_all()
	if discovered:
		ghost_count_changed.emit(_ghost_sprites.size())


func _redraw_all() -> void:
	for cell in _ghost_sprites:
		var sprite: Sprite2D = _ghost_sprites[cell]
		sprite.position = GridManager.cell_to_world(cell)
		var pattern := TetrominoData.neighbor_pattern(cell, func(p): return _ghost_sprites.has(p))
		sprite.texture = _atlas_for(TetrominoData.tile_for_pattern(pattern))


func _make_ghost_sprite(cell: Vector2i) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	add_child(sprite)
	return sprite


func _compute_hole_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for col in range(GridManager.COLS):
		var seen_solid := false
		for row in range(GridManager.ROWS):
			var cell := Vector2i(col, row)
			if GridManager.is_occupied(cell):
				seen_solid = true
			elif seen_solid:
				result.append(cell)
	return result


func _atlas_for(tile_index: int) -> AtlasTexture:
	if not _atlas_cache.has(tile_index):
		var atlas := AtlasTexture.new()
		atlas.atlas = _visuals.tile_sheet
		var size := GridManager.CELL_SIZE
		atlas.region = Rect2((tile_index - 1) * size, 0, size, size)
		_atlas_cache[tile_index] = atlas
	return _atlas_cache[tile_index]


func process_turn() -> void:
	for ghost_cell in _ghost_sprites.keys():
		_act_on_ghost(ghost_cell)


func _act_on_ghost(ghost_cell: Vector2i) -> void:
	var building_types := GridManager.get_building_types()
	var building_neighbors: Array[Vector2i] = []
	var broken_neighbors: Array[Vector2i] = []
	for dir in ORTHOGONAL_DIRS:
		var neighbor := ghost_cell + dir
		if building_types.has(neighbor):
			building_neighbors.append(neighbor)
		elif GridManager.is_broken(neighbor):
			broken_neighbors.append(neighbor)

	if not building_neighbors.is_empty():
		var target: Vector2i = building_neighbors[randi() % building_neighbors.size()]
		GridManager.break_cell(target)
		return

	if not broken_neighbors.is_empty():
		var target: Vector2i = broken_neighbors[randi() % broken_neighbors.size()]
		GridManager.repair_broken(target)
