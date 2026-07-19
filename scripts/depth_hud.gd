extends CanvasLayer

@onready var depth_label: Label = $DepthLabel


func _ready() -> void:
	GridManager.size_changed.connect(_update_depth)
	_update_depth()


func _update_depth() -> void:
	depth_label.text = "Depth: %d m" % [GameManager.get_depth_meters()]
