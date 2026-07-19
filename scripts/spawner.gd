extends Node

signal piece_spawned

var current_piece: Piece = null
var _piece_scene: PackedScene

# BuildingType -> number of spawns since it was last picked. A type's pick
# weight grows the longer it's been skipped, so building types even out
# over time instead of drifting purely on chance.
var _spawns_since_seen: Dictionary = {}

@onready var pieces_container: Node2D = get_node("../PiecesContainer")


func _ready() -> void:
	_piece_scene = load("res://scenes/piece.tscn")
	_reset_building_history()


func spawn_next() -> void:
	var type: TetrominoData.ShapeType = randi() % TetrominoData.ShapeType.size()
	var building_type := _pick_building_type()
	var piece: Piece = _piece_scene.instantiate()
	pieces_container.add_child(piece)
	piece.setup(type, building_type)
	piece.placed.connect(_on_piece_placed)
	current_piece = piece
	piece_spawned.emit()


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

	for i in _spawns_since_seen:
		_spawns_since_seen[i] = 0 if i == picked else _spawns_since_seen[i] + 1

	return picked


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
	spawn_next()
