extends Node

signal game_over(depth_meters: float)
signal game_restarted

var _next_expansion_threshold: float = 0.0
var _next_expansion_increment: float = 0.0


func _ready() -> void:
	ResourceManager.resources_changed.connect(_on_resources_changed)


func start_new_game() -> void:
	# Must be set before ResourceManager.reset() below - reset() emits
	# resources_changed synchronously, which runs _on_resources_changed and
	# compares against this threshold immediately.
	_next_expansion_threshold = max(ResourceManager.balance.energy_expansion_threshold, 0.0001)
	_next_expansion_increment = max(ResourceManager.balance.energy_expansion_increment, 0.0001)

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


func get_next_expansion_threshold() -> float:
	return _next_expansion_threshold


func _on_resources_changed(totals: Dictionary, _rates: Dictionary) -> void:
	if get_tree().paused:
		return
	var decay: float = clamp(ResourceManager.balance.energy_expansion_increment_decay, 0.0, 1.0)
	var energy: float = totals[ResourceManager.ResourceType.ENERGY]
	while energy >= _next_expansion_threshold:
		GridManager.expand_down()
		# The +0.0001 floor guards against the increment decaying toward 0
		# and stalling the threshold forever (which would infinite-loop here).
		_next_expansion_threshold += max(_next_expansion_increment, 0.0001)
		_next_expansion_increment *= decay
