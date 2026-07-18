extends Node

const STAGING_ANCHOR := Vector2(480, 96)

var current_piece: Piece = null
var _piece_scene: PackedScene

@onready var pieces_container: Node2D = get_node("../PiecesContainer")


func _ready() -> void:
	_piece_scene = load("res://scenes/piece.tscn")


func spawn_next() -> void:
	var type: TetrominoData.ShapeType = randi() % TetrominoData.ShapeType.size()
	var building_type: BuildingData.BuildingType = randi() % BuildingData.BuildingType.size()
	var rotation: int = randi() % 4
	var piece: Piece = _piece_scene.instantiate()
	pieces_container.add_child(piece)
	piece.setup(type, STAGING_ANCHOR, building_type, rotation)
	piece.placed.connect(_on_piece_placed)
	current_piece = piece


func _on_piece_placed(_piece: Piece) -> void:
	spawn_next()
