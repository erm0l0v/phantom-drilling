extends Node2D
class_name Piece

signal placed(piece: Piece)

var shape_type: TetrominoData.ShapeType
var building_type: BuildingData.BuildingType
var rotation_state: int = 0
var is_placed: bool = false
var anchor_cell: Vector2i

var _tile_atlas_cache: Dictionary = {} # tile index (1-based) -> AtlasTexture
var _fall_timer: float = 0.0

@onready var cells: Node2D = $Cells


func setup(type: TetrominoData.ShapeType, type_of_building: BuildingData.BuildingType) -> void:
	shape_type = type
	building_type = type_of_building
	rotation_state = 0
	anchor_cell = _spawn_anchor()
	_rebuild_cells()
	_update_position()


# Shapes live inside a 4x4 box; spawn horizontally centered and fully above
# row 0 (max offset row in the box is 3) so it never overlaps the stack.
func _spawn_anchor() -> Vector2i:
	var col := int((GridManager.COLS - 4) / 2.0)
	return Vector2i(col, -4)


func _rebuild_cells() -> void:
	for child in cells.get_children():
		child.queue_free()
	var offsets: Array[Vector2i] = []
	offsets.assign(TetrominoData.SHAPES[shape_type][rotation_state])
	for offset in offsets:
		var tile_index := TetrominoData.tile_for(offset, offsets)
		var sprite := Sprite2D.new()
		sprite.texture = _atlas_for(tile_index)
		sprite.centered = false
		sprite.position = Vector2(offset) * GridManager.CELL_SIZE
		cells.add_child(sprite)


func _atlas_for(tile_index: int) -> AtlasTexture:
	if not _tile_atlas_cache.has(tile_index):
		var atlas := AtlasTexture.new()
		atlas.atlas = BuildingData.texture_for(building_type)
		var cell_size := GridManager.CELL_SIZE
		atlas.region = Rect2((tile_index - 1) * cell_size, 0, cell_size, cell_size)
		_tile_atlas_cache[tile_index] = atlas
	return _tile_atlas_cache[tile_index]


func _update_position() -> void:
	position = GridManager.cell_to_world(anchor_cell)


func _process(delta: float) -> void:
	if is_placed:
		return

	if Input.is_action_just_pressed("ui_left"):
		_try_move(Vector2i(-1, 0))
	if Input.is_action_just_pressed("ui_right"):
		_try_move(Vector2i(1, 0))
	if Input.is_action_just_pressed("ui_up"):
		_try_rotate()

	_fall_timer += delta
	var fall_interval: float = ResourceManager.balance.fall_interval_seconds
	if Input.is_action_pressed("ui_down"):
		fall_interval /= ResourceManager.balance.soft_drop_multiplier
	if _fall_timer >= fall_interval:
		_fall_timer -= fall_interval
		_try_fall()


func _try_move(offset: Vector2i) -> void:
	var new_anchor := anchor_cell + offset
	if _fits(new_anchor, rotation_state):
		anchor_cell = new_anchor
		_update_position()


func _try_rotate() -> void:
	var new_rotation := (rotation_state + 1) % 4
	if _fits(anchor_cell, new_rotation):
		rotation_state = new_rotation
		_rebuild_cells()
		_update_position()


func _try_fall() -> void:
	var new_anchor := anchor_cell + Vector2i(0, 1)
	if _fits(new_anchor, rotation_state):
		anchor_cell = new_anchor
		_update_position()
	else:
		_lock()


# Column must stay in bounds and cells can't overlap the stack; no lower
# bound on row - pieces start above the field and fall into it.
func _fits(candidate_anchor: Vector2i, candidate_rotation: int) -> bool:
	for offset in TetrominoData.SHAPES[shape_type][candidate_rotation]:
		var cell: Vector2i = candidate_anchor + offset
		if cell.x < 0 or cell.x >= GridManager.COLS:
			return false
		if cell.y >= GridManager.ROWS:
			return false
		if GridManager.is_occupied(cell):
			return false
	return true


func _lock() -> void:
	is_placed = true
	var cells_to_stamp: Array[Vector2i] = []
	var overflowed := false
	for offset in TetrominoData.SHAPES[shape_type][rotation_state]:
		var cell: Vector2i = anchor_cell + offset
		if cell.y < 0:
			overflowed = true
		cells_to_stamp.append(cell)

	if overflowed:
		GameManager.trigger_game_over()
		queue_free()
		return

	GridManager.stamp(cells_to_stamp, building_type)
	placed.emit(self)
	queue_free()
