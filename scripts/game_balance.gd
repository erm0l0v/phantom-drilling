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
@export var starting_stock: float = 0.0
@export var energy_oxygen_cost: float = 1.0
@export var energy_coal_cost: float = 1.0

@export_group("Grid")
@export var grid_width: int = 6
@export var grid_height: int = 6
@export var meters_per_tile: float = 3.0

@export_group("Field Expansion")
@export var energy_expansion_threshold: float = 10.0
@export var energy_expansion_multiplier: float = 2.0

@export_group("Falling Piece")
@export var fall_interval_seconds: float = 0.8
@export var soft_drop_multiplier: float = 6.0

@export_group("Building Variety")
# How much a building type's pick weight grows for each spawn it's skipped -
# higher means types that haven't shown up recently come back around faster.
@export var building_type_weight_growth: float = 1.0


func multiplier_for_group_size(size: int) -> float:
	if size >= tier4_group_size:
		return tier4_multiplier
	if size >= tier3_group_size:
		return tier3_multiplier
	if size >= tier2_group_size:
		return tier2_multiplier
	return 1.0
