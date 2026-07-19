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
#
# The group efficiency bonus only boosts how much energy comes OUT of steam
# engines - it doesn't make them thirstier. Oxygen/coal consumption is
# always based on the unboosted ("base") production, then the successfully
# consumed amount is scaled up by the group's average boost ratio to get the
# actual energy yield.

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

# Raw production per resource from placed building groups, including the
# group efficiency bonus - this is what actually ends up in the energy
# stockpile (subject to the stock cap below). Recomputed only when the grid
# changes.
var _gross_rates: Dictionary = {}

# Same steam-engine production as _gross_rates[ENERGY], but WITHOUT the group
# bonus applied - this is what oxygen/coal consumption is based on.
var _energy_base_rate: float = 0.0


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
	_energy_base_rate = 0.0
	_recompute_gross_rates()
	resources_changed.emit(totals, rates)


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	if _gross_rates[ResourceType.OXYGEN] == 0.0 and _gross_rates[ResourceType.COAL] == 0.0 and _gross_rates[ResourceType.ENERGY] == 0.0:
		return

	totals[ResourceType.OXYGEN] += _gross_rates[ResourceType.OXYGEN] * delta
	totals[ResourceType.COAL] += _gross_rates[ResourceType.COAL] * delta

	# Stock-cap against the BASE (unboosted) energy production - that's what
	# actually draws down oxygen/coal.
	var desired_base_energy: float = _energy_base_rate * delta
	var actual_base_energy := desired_base_energy
	if balance.energy_oxygen_cost > 0.0:
		actual_base_energy = min(actual_base_energy, totals[ResourceType.OXYGEN] / balance.energy_oxygen_cost)
	if balance.energy_coal_cost > 0.0:
		actual_base_energy = min(actual_base_energy, totals[ResourceType.COAL] / balance.energy_coal_cost)
	actual_base_energy = max(0.0, actual_base_energy)

	# Scale whatever base production actually succeeded by the group bonus's
	# average boost ratio to get the real energy yield.
	var boost_ratio := 1.0
	if _energy_base_rate > 0.0:
		boost_ratio = _gross_rates[ResourceType.ENERGY] / _energy_base_rate
	var actual_energy: float = actual_base_energy * boost_ratio

	totals[ResourceType.OXYGEN] -= actual_base_energy * balance.energy_oxygen_cost
	totals[ResourceType.COAL] -= actual_base_energy * balance.energy_coal_cost
	totals[ResourceType.ENERGY] += actual_energy

	var actual_energy_rate := actual_energy / delta
	var actual_base_energy_rate := actual_base_energy / delta
	rates[ResourceType.ENERGY] = actual_energy_rate
	rates[ResourceType.OXYGEN] = _gross_rates[ResourceType.OXYGEN] - actual_base_energy_rate * balance.energy_oxygen_cost
	rates[ResourceType.COAL] = _gross_rates[ResourceType.COAL] - actual_base_energy_rate * balance.energy_coal_cost

	resources_changed.emit(totals, rates)


func _on_grid_changed() -> void:
	_recompute_gross_rates()


func _recompute_gross_rates() -> void:
	for resource in _gross_rates:
		_gross_rates[resource] = 0.0
	_energy_base_rate = 0.0

	var building_types := GridManager.get_building_types()
	var visited: Dictionary = {}
	for cell in building_types:
		if visited.has(cell):
			continue
		var group := GridManager.get_connected_group(cell)
		for member in group:
			visited[member] = true
		var multiplier := balance.multiplier_for_group_size(group.size())
		var building_type: int = building_types[cell]
		var resource: ResourceType = RESOURCE_FOR_BUILDING[building_type]
		var base_amount: float = group.size() * balance.base_rate_per_tile
		_gross_rates[resource] += base_amount * multiplier
		if building_type == BuildingData.BuildingType.STEAM_ENGINE:
			_energy_base_rate += base_amount
