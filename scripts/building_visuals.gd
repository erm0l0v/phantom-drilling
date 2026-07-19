class_name BuildingVisuals
extends Resource

@export var coal_plant_texture: Texture2D
@export var oxygen_factory_texture: Texture2D
@export var steam_engine_texture: Texture2D


func texture_for(building_type: BuildingData.BuildingType) -> Texture2D:
	match building_type:
		BuildingData.BuildingType.COAL_PLANT:
			return coal_plant_texture
		BuildingData.BuildingType.OXYGEN_FACTORY:
			return oxygen_factory_texture
		BuildingData.BuildingType.STEAM_ENGINE:
			return steam_engine_texture
	return null
