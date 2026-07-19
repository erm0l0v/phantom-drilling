extends Node2D

@onready var spawner: Node = $Spawner
@onready var grid_cells: Node2D = $GridCells
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var ghost_field: Node2D = $GhostField
@onready var ghost_hud: CanvasLayer = $GhostHUD
@onready var next_piece_hud: CanvasLayer = $NextPieceHUD


func _ready() -> void:
	GridManager.set_render_container(grid_cells)
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_restarted.connect(_on_game_restarted)
	ghost_field.ghost_count_changed.connect(ghost_hud.set_count)
	ghost_hud.set_count(0)
	spawner.piece_spawned.connect(ghost_field.process_turn)
	spawner.next_piece_changed.connect(next_piece_hud.show_next)
	GameManager.start_new_game()
	spawner.queue_next_preview()
	spawner.spawn_next()


func _on_game_over(depth_meters: float) -> void:
	game_over_ui.show_game_over(depth_meters)


func _on_game_restarted() -> void:
	game_over_ui.hide_game_over()
	spawner.reset()
