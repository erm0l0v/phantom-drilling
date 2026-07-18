extends Node

const PieceScene := preload("res://scenes/piece.tscn")
const STAGING_ANCHOR := Vector2(480, 96)

var current_piece: Piece = null

@onready var pieces_container: Node2D = get_node("../PiecesContainer")


func spawn_next() -> void:
	var type: TetrominoData.ShapeType = randi() % TetrominoData.ShapeType.size()
	var building_type: BuildingData.BuildingType = randi() % BuildingData.BuildingType.size()
	var rotation: int = randi() % 4
	var piece: Piece = PieceScene.instantiate()
	pieces_container.add_child(piece)
	piece.setup(type, STAGING_ANCHOR, building_type, rotation)
	piece.placed.connect(_on_piece_placed)
	current_piece = piece


func _on_piece_placed(_piece: Piece) -> void:
	spawn_next()
