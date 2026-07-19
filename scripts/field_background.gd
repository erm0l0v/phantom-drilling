extends Node2D

# Assembles the playfield surroundings (background, side walls, entry
# tunnel, exit funnel) out of the 20-tile strip in game_field-Sheet.png
# (see resources/field_visuals.tres). Rebuilds whenever GridManager's size
# changes.

const VISUALS_PATH := "res://resources/field_visuals.tres"
const TILE_SIZE := 32
const VIEWPORT_SIZE := Vector2(640, 360)

# 1-based tile indices into the sheet's single row of 20 tiles.
const TILE_BACKGROUND := 1
const TILE_FIELD := 2
const TILE_FIELD_LEFT := 3
const TILE_FIELD_RIGHT := 4
const TILE_FIELD_LEFT_BOTTOM := 16
const TILE_FIELD_RIGHT_BOTTOM := 17
const TILE_TUNNEL := 20
const TILE_TUNNEL_LEFT := 18
const TILE_TUNNEL_RIGHT := 19

const FUNNEL_HEIGHT_TILES := 2

# Funnel below the field is field-width + 2 (one extra column overhanging
# each side); rows are hand-authored art tied to that fixed width.
const FUNNEL_ROW_1: Array[int] = [5, 7, 9, 14, 13, 10, 8, 6]
const FUNNEL_ROW_2: Array[int] = [1, 1, 1, 11, 12, 15, 1, 1]

const LANDING_HIGHLIGHT_COLOR := Color(0.65, 0.65, 0.65, 1.0)

var _visuals: FieldVisuals = load(VISUALS_PATH)
var _atlas_cache: Dictionary = {}
var _sprites: Array[Sprite2D] = []

# Only the "игровое поле" (TILE_FIELD) cells - the ones a piece can actually
# land on - tracked separately so the landing preview can modulate them.
var _field_sprites: Dictionary = {} # Vector2i(col,row) -> Sprite2D
var _highlighted_cells: Array[Vector2i] = []


func _ready() -> void:
	GridManager.size_changed.connect(rebuild)
	rebuild()


func rebuild() -> void:
	for sprite in _sprites:
		sprite.queue_free()
	_sprites.clear()
	_field_sprites.clear()
	_highlighted_cells.clear()

	var cols := GridManager.COLS
	var rows := GridManager.ROWS
	var origin := GridManager.ORIGIN

	var tunnel_height: int = ResourceManager.balance.tunnel_height_tiles
	var content_top := origin.y - tunnel_height * TILE_SIZE
	var content_bottom := origin.y + rows * TILE_SIZE + FUNNEL_HEIGHT_TILES * TILE_SIZE

	_paint_background(content_top, content_bottom)
	_paint_tunnel(origin, cols, tunnel_height)
	_paint_field(origin, cols, rows)
	_paint_funnel(origin, rows)


func _paint_background(content_top: float, content_bottom: float) -> void:
	var top: float = min(0.0, content_top) - TILE_SIZE
	var bottom: float = max(VIEWPORT_SIZE.y, content_bottom) + TILE_SIZE
	var y := top
	while y < bottom:
		var x: float = -TILE_SIZE
		while x < VIEWPORT_SIZE.x + TILE_SIZE:
			_place(TILE_BACKGROUND, Vector2(x, y))
			x += TILE_SIZE
		y += TILE_SIZE


func _paint_tunnel(origin: Vector2, cols: int, tunnel_height: int) -> void:
	for row in range(tunnel_height):
		var y := origin.y - (tunnel_height - row) * TILE_SIZE
		_place(TILE_TUNNEL_LEFT, Vector2(origin.x - TILE_SIZE, y))
		_place(TILE_TUNNEL_RIGHT, Vector2(origin.x + cols * TILE_SIZE, y))
		for col in range(cols):
			_place(TILE_TUNNEL, Vector2(origin.x + col * TILE_SIZE, y))


func _paint_field(origin: Vector2, cols: int, rows: int) -> void:
	for row in range(rows):
		var y := origin.y + row * TILE_SIZE
		var is_bottom_row := row == rows - 1
		var left_tile := TILE_FIELD_LEFT_BOTTOM if is_bottom_row else TILE_FIELD_LEFT
		var right_tile := TILE_FIELD_RIGHT_BOTTOM if is_bottom_row else TILE_FIELD_RIGHT
		_place(left_tile, Vector2(origin.x - TILE_SIZE, y))
		_place(right_tile, Vector2(origin.x + cols * TILE_SIZE, y))
		for col in range(cols):
			var cell := Vector2i(col, row)
			var sprite := _place(TILE_FIELD, Vector2(origin.x + col * TILE_SIZE, y))
			_field_sprites[cell] = sprite


func _paint_funnel(origin: Vector2, rows: int) -> void:
	var funnel_rows: Array = [FUNNEL_ROW_1, FUNNEL_ROW_2]
	for row in funnel_rows.size():
		var y := origin.y + rows * TILE_SIZE + row * TILE_SIZE
		var tiles: Array = funnel_rows[row]
		for col in tiles.size():
			var x := origin.x - TILE_SIZE + col * TILE_SIZE
			_place(tiles[col], Vector2(x, y))


func _place(tile_index: int, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.position = pos
	sprite.texture = _atlas_for(tile_index)
	add_child(sprite)
	_sprites.append(sprite)
	return sprite


# Darkens exactly the given field cells (clearing any previous highlight
# first) to preview where the currently falling piece will land.
func highlight_landing(cells: Array[Vector2i]) -> void:
	for cell in _highlighted_cells:
		var sprite: Sprite2D = _field_sprites.get(cell)
		if sprite != null:
			sprite.modulate = Color.WHITE
	_highlighted_cells.clear()

	for cell in cells:
		var sprite: Sprite2D = _field_sprites.get(cell)
		if sprite != null:
			sprite.modulate = LANDING_HIGHLIGHT_COLOR
			_highlighted_cells.append(cell)


func _atlas_for(tile_index: int) -> AtlasTexture:
	if not _atlas_cache.has(tile_index):
		var atlas := AtlasTexture.new()
		atlas.atlas = _visuals.tile_sheet
		atlas.region = Rect2((tile_index - 1) * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE)
		_atlas_cache[tile_index] = atlas
	return _atlas_cache[tile_index]
