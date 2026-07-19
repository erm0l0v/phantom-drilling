extends Node2D

# Marks empty cells that a falling piece can never reach because something
# is already built above them in the same column (the classic Tetris
# "hole"). Purely visual for now - ghosts don't do anything yet.

signal ghost_count_changed(count: int)

const VISUALS_PATH := "res://resources/ghost_visuals.tres"

var _visuals: GhostVisuals = load(VISUALS_PATH)
var _atlas_cache: Dictionary = {}
var _sprites: Array[Sprite2D] = []


func _ready() -> void:
	GridManager.grid_changed.connect(rebuild)
	GridManager.size_changed.connect(rebuild)
	rebuild()


func rebuild() -> void:
	for sprite in _sprites:
		sprite.queue_free()
	_sprites.clear()

	for cell in _compute_ghost_cells():
		var tile_index := randi() % _visuals.tile_count + 1
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.position = GridManager.cell_to_world(cell)
		sprite.texture = _atlas_for(tile_index)
		add_child(sprite)
		_sprites.append(sprite)

	ghost_count_changed.emit(_sprites.size())


func _compute_ghost_cells() -> Array[Vector2i]:
	var building_types := GridManager.get_building_types()
	var result: Array[Vector2i] = []
	for col in range(GridManager.COLS):
		var seen_building := false
		for row in range(GridManager.ROWS):
			var cell := Vector2i(col, row)
			if building_types.has(cell):
				seen_building = true
			elif seen_building:
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
