extends Node

signal game_over(depth_meters: float)
signal game_restarted
signal pause_toggled(is_paused: bool)

var _next_expansion_threshold: float = 0.0
var _is_game_over := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ResourceManager.resources_changed.connect(_on_resources_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause"):
		toggle_pause()


func start_new_game() -> void:
	# Must be set before ResourceManager.reset() below - reset() emits
	# resources_changed synchronously, which runs _on_resources_changed and
	# compares against this threshold immediately.
	_next_expansion_threshold = max(ResourceManager.balance.energy_expansion_threshold, 0.0001)
	_is_game_over = false

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
	_is_game_over = true
	get_tree().paused = true
	game_over.emit(get_depth_meters())


# Manual pause via the P key - separate from the game-over freeze above, and
# deliberately a no-op once the game's over (only Restart should un-freeze
# that state).
func toggle_pause() -> void:
	if _is_game_over:
		return
	get_tree().paused = not get_tree().paused
	pause_toggled.emit(get_tree().paused)


func get_depth_meters() -> float:
	return GridManager.ROWS * ResourceManager.balance.meters_per_tile


func get_next_expansion_threshold() -> float:
	return _next_expansion_threshold


func _on_resources_changed(totals: Dictionary, _rates: Dictionary) -> void:
	if get_tree().paused:
		return
	var n: float = ResourceManager.balance.energy_expansion_n
	var k: float = ResourceManager.balance.energy_expansion_k
	var energy: float = totals[ResourceManager.ResourceType.ENERGY]
	while energy >= _next_expansion_threshold:
		GridManager.expand_down()
		# The +0.0001 floor guards against a misconfigured n/k combo that
		# doesn't strictly grow the threshold, which would infinite-loop here.
		_next_expansion_threshold = max(_next_expansion_threshold * n + k, _next_expansion_threshold + 0.0001)
