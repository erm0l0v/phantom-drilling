extends CanvasLayer

const PREVIEW_SCALE := 0.5

@onready var preview_container: Node2D = $PreviewContainer

var _tile_atlas_cache: Dictionary = {}
var _sprites: Array[Sprite2D] = []


func show_next(shape_type: int, building_type: int) -> void:
	for sprite in _sprites:
		sprite.queue_free()
	_sprites.clear()

	var offsets: Array[Vector2i] = []
	offsets.assign(TetrominoData.SHAPES[shape_type][0])
	var cell_size := GridManager.CELL_SIZE
	for offset in offsets:
		var tile_index := TetrominoData.tile_for(offset, offsets)
		var sprite := Sprite2D.new()
		sprite.texture = _atlas_for(tile_index, building_type)
		sprite.centered = false
		sprite.scale = Vector2(PREVIEW_SCALE, PREVIEW_SCALE)
		sprite.position = Vector2(offset) * cell_size * PREVIEW_SCALE
		preview_container.add_child(sprite)
		_sprites.append(sprite)


func _atlas_for(tile_index: int, building_type: int) -> AtlasTexture:
	var key := building_type * 100 + tile_index
	if not _tile_atlas_cache.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = BuildingData.texture_for(building_type)
		var cell_size := GridManager.CELL_SIZE
		atlas.region = Rect2((tile_index - 1) * cell_size, 0, cell_size, cell_size)
		_tile_atlas_cache[key] = atlas
	return _tile_atlas_cache[key]
