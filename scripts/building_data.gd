class_name BuildingData

enum BuildingType { COAL_PLANT, OXYGEN_FACTORY, STEAM_ENGINE }

static var TEXTURES: Dictionary


static func _static_init() -> void:
	TEXTURES = {
		BuildingType.COAL_PLANT: preload("res://assets/coal_plant-Sheet.png"),
		BuildingType.OXYGEN_FACTORY: preload("res://assets/oxigen_factory-Sheet.png"),
		BuildingType.STEAM_ENGINE: preload("res://assets/steam_engine-Sheet.png"),
	}
