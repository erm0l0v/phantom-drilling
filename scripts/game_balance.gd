class_name GameBalance
extends Resource

@export var base_rate_per_tile: float = 1.0

@export_group("Group Efficiency Tiers")
@export var tier2_group_size: int = 8
@export var tier2_multiplier: float = 2.0
@export var tier3_group_size: int = 10
@export var tier3_multiplier: float = 3.0
@export var tier4_group_size: int = 12
@export var tier4_multiplier: float = 4.0

@export_group("Resources")
@export var starting_stock: float = 10.0
@export var energy_oxygen_cost: float = 1.0
@export var energy_coal_cost: float = 1.0

@export_group("Starting Buildings")
@export var starting_oxygen_tiles: int = 2
@export var starting_coal_tiles: int = 1
@export var starting_energy_tiles: int = 1


func multiplier_for_group_size(size: int) -> float:
	if size >= tier4_group_size:
		return tier4_multiplier
	if size >= tier3_group_size:
		return tier3_multiplier
	if size >= tier2_group_size:
		return tier2_multiplier
	return 1.0
