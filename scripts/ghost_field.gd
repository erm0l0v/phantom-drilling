extends Node2D

# Marks empty cells that a falling piece can never reach because something
# solid (a building or a broken tile) is already above them in the same
# column (the classic Tetris "hole"). Rendered with the same connectivity-
# tiling scheme as buildings, just checking "is this neighbor also a ghost".
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
var _ghost_sprites: Dictionary = {} # Vector2i(col,row) -> Sprite2D


func _ready() -> void:
	GridManager.grid_changed.connect(rebuild)
	GridManager.size_changed.connect(rebuild)
	rebuild()


func rebuild() -> void:
	for sprite in _ghost_sprites.values():
		sprite.queue_free()
	_ghost_sprites.clear()

	var ghost_cells := _compute_ghost_cells()
	for cell in ghost_cells:
		_ghost_sprites[cell] = null
	for cell in ghost_cells:
		_ghost_sprites[cell] = _make_ghost_sprite(cell)

	ghost_count_changed.emit(_ghost_sprites.size())


func _make_ghost_sprite(cell: Vector2i) -> Sprite2D:
	var pattern := TetrominoData.neighbor_pattern(cell, func(p): return _ghost_sprites.has(p))
	var tile_index: int = TetrominoData.tile_for_pattern(pattern)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.position = GridManager.cell_to_world(cell)
	sprite.texture = _atlas_for(tile_index)
	add_child(sprite)
	return sprite


func _compute_ghost_cells() -> Array[Vector2i]:
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
