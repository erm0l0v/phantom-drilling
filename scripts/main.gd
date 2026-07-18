extends Node2D

@onready var spawner: Node = $Spawner
@onready var grid_cells: Node2D = $GridCells


func _ready() -> void:
	GridManager.set_render_container(grid_cells)
	spawner.spawn_next()
