extends Node2D

# Draws a resizable box border from a 9-tile strip (corners, edges, center -
# see resources/text_border_visuals.tres): 1/3/7/9 are the four corners
# (fixed size), 2/4/6/8 are the edges (repeated along their length), 5 is the
# center fill (repeated both ways). Same "place many small tiles" approach
# as field_background.gd, just at 16px instead of 32px.

const VISUALS_PATH := "res://resources/text_border_visuals.tres"
const TILE_SIZE := 16

const TILE_TOP_LEFT := 1
const TILE_TOP := 2
const TILE_TOP_RIGHT := 3
const TILE_LEFT := 4
const TILE_CENTER := 5
const TILE_RIGHT := 6
const TILE_BOTTOM_LEFT := 7
const TILE_BOTTOM := 8
const TILE_BOTTOM_RIGHT := 9

# Size this border should cover, in pixels - should be a multiple of
# TILE_SIZE (16) on each axis for a clean fit.
@export var target_size: Vector2 = Vector2(192, 80)

var _visuals: TextBorderVisuals = load(VISUALS_PATH)
var _atlas_cache: Dictionary = {}
var _sprites: Array[Sprite2D] = []


func _ready() -> void:
	build(target_size)


func build(size: Vector2) -> void:
	for sprite in _sprites:
		sprite.queue_free()
	_sprites.clear()

	var cols: int = max(int(round(size.x / TILE_SIZE)), 2)
	var rows: int = max(int(round(size.y / TILE_SIZE)), 2)

	for col in range(cols):
		for row in range(rows):
			var tile_index := _tile_for(col, row, cols, rows)
			_place(tile_index, Vector2(col * TILE_SIZE, row * TILE_SIZE))


func _tile_for(col: int, row: int, cols: int, rows: int) -> int:
	var is_left := col == 0
	var is_right := col == cols - 1
	var is_top := row == 0
	var is_bottom := row == rows - 1

	if is_top and is_left:
		return TILE_TOP_LEFT
	if is_top and is_right:
		return TILE_TOP_RIGHT
	if is_bottom and is_left:
		return TILE_BOTTOM_LEFT
	if is_bottom and is_right:
		return TILE_BOTTOM_RIGHT
	if is_top:
		return TILE_TOP
	if is_bottom:
		return TILE_BOTTOM
	if is_left:
		return TILE_LEFT
	if is_right:
		return TILE_RIGHT
	return TILE_CENTER


func _place(tile_index: int, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.position = pos
	sprite.texture = _atlas_for(tile_index)
	add_child(sprite)
	_sprites.append(sprite)


func _atlas_for(tile_index: int) -> AtlasTexture:
	if not _atlas_cache.has(tile_index):
		var atlas := AtlasTexture.new()
		atlas.atlas = _visuals.tile_sheet
		atlas.region = Rect2((tile_index - 1) * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE)
		_atlas_cache[tile_index] = atlas
	return _atlas_cache[tile_index]
