class_name GameBalance
extends Resource

@export var base_rate_per_tile: float = 1.0

@export_group("Group Efficiency Tiers")
# Groups smaller than this get no bonus (multiplier 1x). At and above it, the
# multiplier starts at tier_start_multiplier and climbs by tier_step_multiplier
# for every extra tier_step_size tiles in the group - uncapped, so a big
# enough group keeps getting more efficient forever. Default (8/2/3.0/1.0)
# gives 8->x3, 10->x4, 12->x5, 14->x6, ...
@export var tier_start_size: int = 8
@export var tier_step_size: int = 2
@export var tier_start_multiplier: float = 3.0
@export var tier_step_multiplier: float = 1.0

@export_group("Resources")
@export var starting_stock: float = 0.0
@export var energy_oxygen_cost: float = 1.0
@export var energy_coal_cost: float = 1.0

@export_group("Grid")
@export var grid_width: int = 6
@export var grid_height: int = 6
@export var meters_per_tile: float = 3.0
@export var tunnel_height_tiles: int = 3

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
	if size < tier_start_size or tier_step_size <= 0:
		return 1.0
	var steps: int = int((size - tier_start_size) / float(tier_step_size))
	return tier_start_multiplier + steps * tier_step_multiplier
