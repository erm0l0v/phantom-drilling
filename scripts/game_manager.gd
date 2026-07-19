extends Node

signal game_over
signal game_restarted


func _ready() -> void:
	ResourceManager.resources_changed.connect(_on_resources_changed)


func start_new_game() -> void:
	# Reset resources/grid while still paused so the stale pre-reset totals
	# (which may be <= 0, e.g. right after a game over) can't immediately
	# re-trigger _on_resources_changed once we unpause below.
	ResourceManager.reset()
	GridManager.clear()
	_place_starting_buildings()
	get_tree().paused = false


func restart() -> void:
	start_new_game()
	game_restarted.emit()


func _place_starting_buildings() -> void:
	var balance := ResourceManager.balance
	var layout := {
		BuildingData.BuildingType.OXYGEN_FACTORY: balance.starting_oxygen_tiles,
		BuildingData.BuildingType.COAL_PLANT: balance.starting_coal_tiles,
		BuildingData.BuildingType.STEAM_ENGINE: balance.starting_energy_tiles,
	}
	var occupied: Array[Vector2i] = []
	for building_type in layout:
		for i in layout[building_type]:
			var cell := _random_empty_cell(occupied)
			occupied.append(cell)
			GridManager.stamp([cell], building_type)


func _random_empty_cell(occupied: Array[Vector2i]) -> Vector2i:
	var cell := Vector2i.ZERO
	while true:
		cell = Vector2i(randi() % GridManager.COLS, randi() % GridManager.ROWS)
		if not occupied.has(cell):
			break
	return cell


func _on_resources_changed(totals: Dictionary, _rates: Dictionary) -> void:
	if get_tree().paused:
		return
	var oxygen: float = totals[ResourceManager.ResourceType.OXYGEN]
	var energy: float = totals[ResourceManager.ResourceType.ENERGY]
	if oxygen <= 0.0 or energy <= 0.0:
		get_tree().paused = true
		game_over.emit()
