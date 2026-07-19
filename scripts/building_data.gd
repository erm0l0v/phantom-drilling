class_name BuildingData

enum BuildingType { COAL_PLANT, OXYGEN_FACTORY, STEAM_ENGINE }

const VISUALS_PATH := "res://resources/building_visuals.tres"

static var visuals: BuildingVisuals = load(VISUALS_PATH)


static func texture_for(building_type: BuildingType) -> Texture2D:
	return visuals.texture_for(building_type)
