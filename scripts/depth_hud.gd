extends CanvasLayer

@onready var depth_label: Label = $DepthLabel
@onready var next_expansion_label: Label = $NextExpansionLabel


func _ready() -> void:
	GridManager.size_changed.connect(_update_depth)
	ResourceManager.resources_changed.connect(_on_resources_changed)
	_update_depth()
	_update_next_expansion(ResourceManager.totals)


func _update_depth() -> void:
	depth_label.text = "Depth: %d m" % [GameManager.get_depth_meters()]
	_update_next_expansion(ResourceManager.totals)


func _on_resources_changed(totals: Dictionary, _rates: Dictionary) -> void:
	_update_next_expansion(totals)


func _update_next_expansion(totals: Dictionary) -> void:
	var threshold: float = GameManager.get_next_expansion_threshold()
	var current: float = totals[ResourceManager.ResourceType.ENERGY]
	var remaining: float = max(0.0, threshold - current)
	next_expansion_label.text = "Next depth: %d energy" % [ceili(remaining)]
