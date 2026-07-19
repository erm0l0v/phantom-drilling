extends Node2D

@onready var spawner: Node = $Spawner
@onready var grid_cells: Node2D = $GridCells
@onready var game_over_ui: CanvasLayer = $GameOverUI


func _ready() -> void:
	GridManager.set_render_container(grid_cells)
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_restarted.connect(_on_game_restarted)
	GameManager.start_new_game()
	spawner.spawn_next()


func _on_game_over() -> void:
	game_over_ui.show_game_over()


func _on_game_restarted() -> void:
	game_over_ui.hide_game_over()
	spawner.reset()
