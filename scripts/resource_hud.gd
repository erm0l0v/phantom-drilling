extends CanvasLayer

@onready var oxygen_label: Label = $Panel/VBox/OxygenLabel
@onready var coal_label: Label = $Panel/VBox/CoalLabel
@onready var energy_label: Label = $Panel/VBox/EnergyLabel


func _ready() -> void:
	ResourceManager.resources_changed.connect(_on_resources_changed)
	_on_resources_changed(ResourceManager.totals, ResourceManager.rates)


func _on_resources_changed(totals: Dictionary, rates: Dictionary) -> void:
	oxygen_label.text = _format_line("Oxygen", totals, rates, ResourceManager.ResourceType.OXYGEN)
	coal_label.text = _format_line("Coal", totals, rates, ResourceManager.ResourceType.COAL)
	energy_label.text = _format_line("Energy", totals, rates, ResourceManager.ResourceType.ENERGY)


func _format_line(label: String, totals: Dictionary, rates: Dictionary, resource: int) -> String:
	var total: float = totals[resource]
	var rate: float = rates[resource]
	return "%s: %d (+%.1f/s)" % [label, floori(total), rate]
