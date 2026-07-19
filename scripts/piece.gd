extends Node2D
class_name Piece

signal placed(piece: Piece)

const VALID_TINT := Color(0.5, 1.0, 0.5)
const INVALID_TINT := Color(1.0, 0.45, 0.45)

var shape_type: TetrominoData.ShapeType
var building_type: BuildingData.BuildingType
var rotation_state: int = 0
var is_placed: bool = false
var is_dragging: bool = false
var staging_position: Vector2
var drag_grab_offset: Vector2

var _cell_offsets: Array[Vector2i] = []
var _pending_cells: Array[Vector2i] = []
var _pending_valid: bool = false
var _tile_atlas_cache: Dictionary = {} # tile index (1-based) -> AtlasTexture

@onready var cells: Node2D = $Cells


func setup(type: TetrominoData.ShapeType, spawn_pos: Vector2, type_of_building: BuildingData.BuildingType, initial_rotation: int) -> void:
	shape_type = type
	building_type = type_of_building
	staging_position = spawn_pos
	position = spawn_pos
	rotation_state = initial_rotation
	_rebuild_cells()


func _rebuild_cells() -> void:
	for child in cells.get_children():
		child.queue_free()
	_cell_offsets.assign(TetrominoData.SHAPES[shape_type][rotation_state])
	for offset in _cell_offsets:
		var tile_index := TetrominoData.tile_for(offset, _cell_offsets)
		var sprite := Sprite2D.new()
		sprite.texture = _atlas_for(tile_index)
		sprite.centered = false
		sprite.position = Vector2(offset) * GridManager.CELL_SIZE
		sprite.rotation = 0.0
		cells.add_child(sprite)


func _atlas_for(tile_index: int) -> AtlasTexture:
	if not _tile_atlas_cache.has(tile_index):
		var atlas := AtlasTexture.new()
		atlas.atlas = BuildingData.texture_for(building_type)
		var cell_size := GridManager.CELL_SIZE
		atlas.region = Rect2((tile_index - 1) * cell_size, 0, cell_size, cell_size)
		_tile_atlas_cache[tile_index] = atlas
	return _tile_atlas_cache[tile_index]


func get_local_bounds() -> Rect2:
	if _cell_offsets.is_empty():
		return Rect2()
	var cell_size := GridManager.CELL_SIZE
	var min_pt := Vector2(_cell_offsets[0]) * cell_size
	var max_pt := min_pt + Vector2(cell_size, cell_size)
	for offset in _cell_offsets:
		var p := Vector2(offset) * cell_size
		min_pt.x = min(min_pt.x, p.x)
		min_pt.y = min(min_pt.y, p.y)
		max_pt.x = max(max_pt.x, p.x + cell_size)
		max_pt.y = max(max_pt.y, p.y + cell_size)
	return Rect2(min_pt, max_pt - min_pt)


func contains_point(world_pos: Vector2) -> bool:
	return get_local_bounds().has_point(world_pos - position)


func start_drag() -> void:
	is_dragging = true
	drag_grab_offset = position - get_global_mouse_position()


func update_drag() -> void:
	position = get_global_mouse_position() + drag_grab_offset
	_update_preview()


func _update_preview() -> void:
	var anchor_cell := GridManager.snap_anchor_cell(position)
	_pending_cells.clear()
	for offset in _cell_offsets:
		_pending_cells.append(anchor_cell + offset)
	_pending_valid = GridManager.can_stamp(_pending_cells)
	_set_tint(VALID_TINT if _pending_valid else INVALID_TINT)


func end_drag() -> void:
	is_dragging = false
	if _pending_valid:
		GridManager.stamp(_pending_cells, building_type)
		is_placed = true
		hide()
		placed.emit(self)
		queue_free()
	else:
		position = staging_position
		_set_tint(Color.WHITE)


func _set_tint(color: Color) -> void:
	for sprite in cells.get_children():
		sprite.modulate = color


func _unhandled_input(event: InputEvent) -> void:
	if is_placed:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not is_dragging and contains_point(get_global_mouse_position()):
					start_drag()
					get_viewport().set_input_as_handled()
			elif is_dragging:
				end_drag()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if is_dragging:
			update_drag()
