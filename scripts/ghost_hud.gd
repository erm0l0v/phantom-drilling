extends CanvasLayer

@onready var ghost_label: Label = $GhostLabel


func set_count(count: int) -> void:
	ghost_label.text = "Ghosts: %d" % [count]
