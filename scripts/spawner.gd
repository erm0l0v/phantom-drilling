extends Node

signal piece_spawned
signal next_piece_changed(shape_type: int, building_type: int)

const OPENING_PIECE_COUNT := 3
# S and Z can create instant unreachable holes if the player hasn't had a
# chance to get a feel for the controls yet, so keep them out of the opening.
const OPENING_ALLOWED_SHAPES: Array[int] = [
	TetrominoData.ShapeType.I,
	TetrominoData.ShapeType.O,
	TetrominoData.ShapeType.T,
	TetrominoData.ShapeType.J,
	TetrominoData.ShapeType.L,
]

var current_piece: Piece = null
var _piece_scene: PackedScene

# Look-ahead: the piece that will actually spawn next time spawn_next() is
# called is decided in advance so it can be shown as a preview.
var _next_shape: int
var _next_building_type: int

# How many pieces have been queued this game - the first OPENING_PIECE_COUNT
# get the "always different building types, never S/Z" opening rules below.
var _pieces_generated: int = 0
var _opening_building_types_used: Array[int] = []

# BuildingType -> number of spawns since it was last picked. A type's pick
# weight grows the longer it's been skipped, so building types even out
# over time instead of drifting purely on chance.
var _spawns_since_seen: Dictionary = {}

@onready var pieces_container: Node2D = get_node("../PiecesContainer")


func _ready() -> void:
	_piece_scene = load("res://scenes/piece.tscn")
	_reset_building_history()


# Called explicitly (not from _ready()) so the caller can wire up
# next_piece_changed listeners first and not miss the initial preview.
func queue_next_preview() -> void:
	if _pieces_generated < OPENING_PIECE_COUNT:
		_next_shape = OPENING_ALLOWED_SHAPES[randi() % OPENING_ALLOWED_SHAPES.size()]
		_next_building_type = _pick_opening_building_type()
		_opening_building_types_used.append(_next_building_type)
	else:
		_next_shape = randi() % TetrominoData.ShapeType.size()
		_next_building_type = _pick_building_type()

	_record_building_pick(_next_building_type)
	_pieces_generated += 1
	next_piece_changed.emit(_next_shape, _next_building_type)


func spawn_next() -> void:
	var type: int = _next_shape
	var building_type: int = _next_building_type
	var piece: Piece = _piece_scene.instantiate()
	pieces_container.add_child(piece)
	piece.setup(type, building_type)
	piece.placed.connect(_on_piece_placed)
	current_piece = piece
	piece_spawned.emit()
	queue_next_preview()


func _pick_opening_building_type() -> int:
	var available: Array[int] = []
	for i in BuildingData.BuildingType.size():
		if not _opening_building_types_used.has(i):
			available.append(i)
	return available[randi() % available.size()]


func _pick_building_type() -> int:
	var growth: float = ResourceManager.balance.building_type_weight_growth
	var weights: Array[float] = []
	var total_weight := 0.0
	for i in BuildingData.BuildingType.size():
		var weight: float = 1.0 + _spawns_since_seen[i] * growth
		weights.append(weight)
		total_weight += weight

	var roll := randf() * total_weight
	var accumulated := 0.0
	var picked := weights.size() - 1
	for i in weights.size():
		accumulated += weights[i]
		if roll < accumulated:
			picked = i
			break

	return picked


func _record_building_pick(picked: int) -> void:
	for i in _spawns_since_seen:
		_spawns_since_seen[i] = 0 if i == picked else _spawns_since_seen[i] + 1


func _reset_building_history() -> void:
	_spawns_since_seen.clear()
	for i in BuildingData.BuildingType.size():
		_spawns_since_seen[i] = 0


func _on_piece_placed(_piece: Piece) -> void:
	if current_piece == _piece:
		current_piece = null
	spawn_next()


func reset() -> void:
	current_piece = null
	for child in pieces_container.get_children():
		child.queue_free()
	_reset_building_history()
	_pieces_generated = 0
	_opening_building_types_used.clear()
	queue_next_preview()
	spawn_next()
