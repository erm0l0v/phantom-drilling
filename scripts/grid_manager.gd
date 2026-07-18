extends Node

const ORIGIN := Vector2(224, 32)
const CELL_SIZE := 32
const COLS := 6
const ROWS := 6

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


func snap_anchor_cell(world_pos: Vector2) -> Vector2i:
	var local := (world_pos - ORIGIN) / CELL_SIZE
	return Vector2i(round(local.x), round(local.y))


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS


func can_stamp(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if not is_in_bounds(cell):
			return false
	return true


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


func _update_cell_sprite(cell: Vector2i) -> void:
	var building_type: int = _building_types[cell]
	var mask := _connectivity_mask(cell, building_type)
	var diagonal_filled := true
	if TetrominoData.DIAGONAL_OFFSET.has(mask):
		var diagonal_cell: Vector2i = cell + TetrominoData.DIAGONAL_OFFSET[mask]
		diagonal_filled = _building_types.get(diagonal_cell, -1) == building_type
	var tile_index: int = TetrominoData.tile_for_mask(mask, diagonal_filled)
	var sprite: Sprite2D = _cell_sprites.get(cell)
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.centered = false
		sprite.position = cell_to_world(cell)
		_render_container.add_child(sprite)
		_cell_sprites[cell] = sprite
	sprite.texture = _atlas_for(building_type, tile_index)


func _connectivity_mask(cell: Vector2i, building_type: int) -> int:
	var mask := 0
	if _building_types.get(cell + Vector2i(0, -1), -1) == building_type:
		mask |= 1
	if _building_types.get(cell + Vector2i(0, 1), -1) == building_type:
		mask |= 2
	if _building_types.get(cell + Vector2i(-1, 0), -1) == building_type:
		mask |= 4
	if _building_types.get(cell + Vector2i(1, 0), -1) == building_type:
		mask |= 8
	return mask


func _atlas_for(building_type: int, tile_index: int) -> AtlasTexture:
	var key := building_type * 100 + tile_index
	if not _atlas_cache.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = BuildingData.TEXTURES[building_type]
		atlas.region = Rect2((tile_index - 1) * CELL_SIZE, 0, CELL_SIZE, CELL_SIZE)
		_atlas_cache[key] = atlas
	return _atlas_cache[key]
