extends Node

signal grid_changed
signal size_changed

const ORIGIN := Vector2(224, 32)
const CELL_SIZE := 32

# Mutable (not const) because the field size is meant to be resizable during
# play in a future update; for now it's just seeded once from
# GameBalance.grid_width/grid_height at game start via configure_size().
var COLS := 6
var ROWS := 6

const NEIGHBOR_DIRS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]

var _building_types: Dictionary = {} # Vector2i(col,row) -> BuildingData.BuildingType
var _cell_sprites: Dictionary = {} # Vector2i(col,row) -> Sprite2D
var _atlas_cache: Dictionary = {} # (building_type*100+tile_index) -> AtlasTexture
var _render_container: Node2D


func set_render_container(container: Node2D) -> void:
	_render_container = container


func cell_to_world(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell) * CELL_SIZE


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS


func is_occupied(cell: Vector2i) -> bool:
	return _building_types.has(cell)


func get_building_types() -> Dictionary:
	return _building_types.duplicate()


func configure_size(width: int, height: int) -> void:
	COLS = width
	ROWS = height
	size_changed.emit()


# Adds a new row of headroom by growing the field by 1 row and shifting every
# already-placed building down by 1 to make room - the field gets one tile
# deeper while everything sinks further into the ground.
func expand_down() -> void:
	ROWS += 1
	var shifted_types: Dictionary = {}
	for cell in _building_types:
		shifted_types[cell + Vector2i(0, 1)] = _building_types[cell]
	_building_types = shifted_types

	var shifted_sprites: Dictionary = {}
	for cell in _cell_sprites:
		var new_cell: Vector2i = cell + Vector2i(0, 1)
		var sprite: Sprite2D = _cell_sprites[cell]
		sprite.position = cell_to_world(new_cell)
		shifted_sprites[new_cell] = sprite
	_cell_sprites = shifted_sprites

	size_changed.emit()
	grid_changed.emit()


func clear() -> void:
	for sprite in _cell_sprites.values():
		sprite.queue_free()
	_cell_sprites.clear()
	_building_types.clear()
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
