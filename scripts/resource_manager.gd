extends Node

# Tracks resource extraction. Each placed tile produces balance.base_rate_per_tile
# of its building's resource per second. Tiles of the same building type that
# are orthogonally connected form a group; groups reaching balance's tier
# thresholds get that tier's efficiency multiplier applied to every tile in
# the group. Tunable numbers live in resources/game_balance.tres - edit that
# resource in the editor rather than changing constants here.

signal resources_changed(totals: Dictionary, rates: Dictionary)

enum ResourceType { OXYGEN, COAL, ENERGY }

const RESOURCE_NAMES := {
	ResourceType.OXYGEN: "Oxygen",
	ResourceType.COAL: "Coal",
	ResourceType.ENERGY: "Energy",
}

const RESOURCE_FOR_BUILDING := {
	BuildingData.BuildingType.COAL_PLANT: ResourceType.COAL,
	BuildingData.BuildingType.OXYGEN_FACTORY: ResourceType.OXYGEN,
	BuildingData.BuildingType.STEAM_ENGINE: ResourceType.ENERGY,
}

const BALANCE_PATH := "res://resources/game_balance.tres"

const ORTHOGONAL_DIRS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
]

var balance: GameBalance = load(BALANCE_PATH)

var totals: Dictionary = {}
var rates: Dictionary = {}


func _ready() -> void:
	GridManager.grid_changed.connect(_on_grid_changed)
	reset()


func reset() -> void:
	totals = {
		ResourceType.OXYGEN: balance.starting_stock,
		ResourceType.COAL: balance.starting_stock,
		ResourceType.ENERGY: balance.starting_stock,
	}
	rates = {
		ResourceType.OXYGEN: 0.0,
		ResourceType.COAL: 0.0,
		ResourceType.ENERGY: 0.0,
	}
	_recompute_rates()
	resources_changed.emit(totals, rates)


func _process(delta: float) -> void:
	var changed := false
	for resource in rates:
		var rate: float = rates[resource]
		if rate != 0.0:
			totals[resource] += rate * delta
			changed = true
	if changed:
		resources_changed.emit(totals, rates)


func _on_grid_changed() -> void:
	_recompute_rates()
	resources_changed.emit(totals, rates)


func _recompute_rates() -> void:
	for resource in rates:
		rates[resource] = 0.0

	var building_types := GridManager.get_building_types()
	var visited: Dictionary = {}
	for cell in building_types:
		if visited.has(cell):
			continue
		var group := _flood_fill(cell, building_types, visited)
		var multiplier := balance.multiplier_for_group_size(group.size())
		var resource: ResourceType = RESOURCE_FOR_BUILDING[building_types[cell]]
		rates[resource] += group.size() * balance.base_rate_per_tile * multiplier

	# Producing energy consumes oxygen and coal - energy's own rate is
	# unaffected, it's oxygen/coal that get debited for what energy produced.
	var energy_rate: float = rates[ResourceType.ENERGY]
	rates[ResourceType.OXYGEN] -= energy_rate * balance.energy_oxygen_cost
	rates[ResourceType.COAL] -= energy_rate * balance.energy_coal_cost


func _flood_fill(start: Vector2i, building_types: Dictionary, visited: Dictionary) -> Array[Vector2i]:
	var building_type: int = building_types[start]
	var group: Array[Vector2i] = []
	var stack: Array[Vector2i] = [start]
	visited[start] = true
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		group.append(cell)
		for dir in ORTHOGONAL_DIRS:
			var neighbor := cell + dir
			if visited.has(neighbor):
				continue
			if building_types.get(neighbor, -1) == building_type:
				visited[neighbor] = true
				stack.append(neighbor)
	return group
