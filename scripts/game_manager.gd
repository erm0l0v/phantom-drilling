extends Node

signal game_over(depth_meters: float)
signal game_restarted

var _next_expansion_threshold: float = 0.0


func _ready() -> void:
	ResourceManager.resources_changed.connect(_on_resources_changed)


func start_new_game() -> void:
	# Must be set before ResourceManager.reset() below - reset() emits
	# resources_changed synchronously, which runs _on_resources_changed and
	# compares against this threshold immediately.
	_next_expansion_threshold = max(ResourceManager.balance.energy_expansion_threshold, 0.0001)

	ResourceManager.reset()
	GridManager.configure_size(ResourceManager.balance.grid_width, ResourceManager.balance.grid_height)
	GridManager.clear()
	get_tree().paused = false


func restart() -> void:
	start_new_game()
	game_restarted.emit()


# Called by a falling piece when it locks with any cell still above the top
# of the field - the Tetris "topped out" loss condition.
func trigger_game_over() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	game_over.emit(get_depth_meters())


func get_depth_meters() -> float:
	return GridManager.ROWS * ResourceManager.balance.meters_per_tile


func _on_resources_changed(totals: Dictionary, _rates: Dictionary) -> void:
	if get_tree().paused:
		return
	# Guard against a misconfigured (<=1) multiplier or a zero threshold
	# turning this into an infinite loop - it must always strictly increase.
	var multiplier: float = max(ResourceManager.balance.energy_expansion_multiplier, 1.0001)
	var energy: float = totals[ResourceManager.ResourceType.ENERGY]
	while energy >= _next_expansion_threshold:
		GridManager.expand_down()
		_next_expansion_threshold = max(_next_expansion_threshold * multiplier, _next_expansion_threshold + 0.0001)
