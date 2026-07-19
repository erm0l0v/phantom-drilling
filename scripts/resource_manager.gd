extends Node

# Tracks resource extraction. Each placed tile produces balance.base_rate_per_tile
# of its building's resource per second. Tiles of the same building type that
# are orthogonally connected form a group; groups reaching balance's tier
# thresholds get that tier's efficiency multiplier applied to every tile in
# the group. Tunable numbers live in resources/game_balance.tres - edit that
# resource in the editor rather than changing constants here.
#
# Energy production is stock-capped rather than deficit-based: if there isn't
# enough oxygen/coal on hand to cover what the steam engines could produce,
# they simply produce less energy instead of driving oxygen/coal negative.

signal resources_changed(totals: Dictionary, rates: Dictionary)

enum ResourceType { OXYGEN, COAL, ENERGY }

const RESOURCE_NAMES := {
	ResourceType.OXYGEN: "Oxygen",
	ResourceType.COAL: "Coal",
	ResourceType.ENERGY: "Energy",
}

# Matches the font colors on the Oxygen/Coal/Energy labels in ResourceHUD's
# scene (main.tscn) - kept here too so other effects (e.g. GroupBonusFX) can
# color-match a resource without hardcoding it a second time.
const RESOURCE_COLORS := {
	ResourceType.OXYGEN: Color(0.55, 0.85, 1, 1),
	ResourceType.COAL: Color(0.75, 0.7, 0.65, 1),
	ResourceType.ENERGY: Color(1, 0.85, 0.3, 1),
}

const RESOURCE_FOR_BUILDING := {
	BuildingData.BuildingType.COAL_PLANT: ResourceType.COAL,
	BuildingData.BuildingType.OXYGEN_FACTORY: ResourceType.OXYGEN,
	BuildingData.BuildingType.STEAM_ENGINE: ResourceType.ENERGY,
}

const BALANCE_PATH := "res://resources/game_balance.tres"

var balance: GameBalance = load(BALANCE_PATH)

var totals: Dictionary = {}
var rates: Dictionary = {}

# Raw production per resource from placed building groups, before energy's
# oxygen/coal cost is applied. Recomputed only when the grid changes.
var _gross_rates: Dictionary = {}


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
	_gross_rates = rates.duplicate()
	_recompute_gross_rates()
	resources_changed.emit(totals, rates)


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	if _gross_rates[ResourceType.OXYGEN] == 0.0 and _gross_rates[ResourceType.COAL] == 0.0 and _gross_rates[ResourceType.ENERGY] == 0.0:
		return

	totals[ResourceType.OXYGEN] += _gross_rates[ResourceType.OXYGEN] * delta
	totals[ResourceType.COAL] += _gross_rates[ResourceType.COAL] * delta

	var desired_energy: float = _gross_rates[ResourceType.ENERGY] * delta
	var actual_energy := desired_energy
	if balance.energy_oxygen_cost > 0.0:
		actual_energy = min(actual_energy, totals[ResourceType.OXYGEN] / balance.energy_oxygen_cost)
	if balance.energy_coal_cost > 0.0:
		actual_energy = min(actual_energy, totals[ResourceType.COAL] / balance.energy_coal_cost)
	actual_energy = max(0.0, actual_energy)

	totals[ResourceType.OXYGEN] -= actual_energy * balance.energy_oxygen_cost
	totals[ResourceType.COAL] -= actual_energy * balance.energy_coal_cost
	totals[ResourceType.ENERGY] += actual_energy

	var actual_energy_rate := actual_energy / delta
	rates[ResourceType.ENERGY] = actual_energy_rate
	rates[ResourceType.OXYGEN] = _gross_rates[ResourceType.OXYGEN] - actual_energy_rate * balance.energy_oxygen_cost
	rates[ResourceType.COAL] = _gross_rates[ResourceType.COAL] - actual_energy_rate * balance.energy_coal_cost

	resources_changed.emit(totals, rates)


func _on_grid_changed() -> void:
	_recompute_gross_rates()


func _recompute_gross_rates() -> void:
	for resource in _gross_rates:
		_gross_rates[resource] = 0.0

	var building_types := GridManager.get_building_types()
	var visited: Dictionary = {}
	for cell in building_types:
		if visited.has(cell):
			continue
		var group := GridManager.get_connected_group(cell)
		for member in group:
			visited[member] = true
		var multiplier := balance.multiplier_for_group_size(group.size())
		var resource: ResourceType = RESOURCE_FOR_BUILDING[building_types[cell]]
		_gross_rates[resource] += group.size() * balance.base_rate_per_tile * multiplier
