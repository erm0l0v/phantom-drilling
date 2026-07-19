extends Node2D

# Whenever a placed piece connects into a same-type group large enough to
# earn an efficiency bonus (GameBalance.multiplier_for_group_size() > 1x),
# flash every tile in that group green and fly an "xN" popup (colored like
# that resource, matching ResourceHUD) over to the resource counters.

const HIGHLIGHT_COLOR := Color(0.4, 1.0, 0.4, 1.0)
const HIGHLIGHT_DURATION := 0.6

const POPUP_FONT_SIZE := 32
const POPUP_DURATION := 0.9

# Screen-space landing spots matching the Oxygen/Coal/Energy rows in
# ResourceHUD's panel (main.tscn: Panel at offset 8,8 - 200,84).
const POPUP_TARGETS := {
	ResourceManager.ResourceType.OXYGEN: Vector2(90, 24),
	ResourceManager.ResourceType.COAL: Vector2(90, 46),
	ResourceManager.ResourceType.ENERGY: Vector2(90, 68),
}

@onready var popup_layer: CanvasLayer = $PopupLayer


func _ready() -> void:
	GridManager.cells_placed.connect(_on_cells_placed)


func _on_cells_placed(cells: Array[Vector2i], building_type: int) -> void:
	if cells.is_empty():
		return

	var group := GridManager.get_connected_group(cells[0])
	var multiplier := ResourceManager.balance.multiplier_for_group_size(group.size())
	if multiplier <= 1.0:
		return

	_highlight_group(group)
	_spawn_popup(group, multiplier, building_type)


func _highlight_group(group: Array[Vector2i]) -> void:
	for cell in group:
		var sprite := GridManager.get_cell_sprite(cell)
		if sprite == null:
			continue
		sprite.modulate = HIGHLIGHT_COLOR
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, HIGHLIGHT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _spawn_popup(group: Array[Vector2i], multiplier: float, building_type: int) -> void:
	var world_center := Vector2.ZERO
	for cell in group:
		world_center += GridManager.cell_to_world(cell)
	world_center /= group.size()
	world_center += Vector2(GridManager.CELL_SIZE, GridManager.CELL_SIZE) / 2.0

	# Convert to screen space once at spawn so the flight target (a fixed HUD
	# spot) and the whole animation are unaffected by camera movement.
	var start_pos: Vector2 = get_viewport().get_canvas_transform() * world_center

	var resource: int = ResourceManager.RESOURCE_FOR_BUILDING[building_type]
	var color: Color = ResourceManager.RESOURCE_COLORS[resource]
	var target_pos: Vector2 = POPUP_TARGETS[resource]

	var multiplier_text: String
	if is_equal_approx(multiplier, round(multiplier)):
		multiplier_text = "x%d" % int(round(multiplier))
	else:
		multiplier_text = "x%.1f" % multiplier

	var label := Label.new()
	label.text = multiplier_text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", POPUP_FONT_SIZE)
	label.position = start_pos
	popup_layer.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", target_pos, POPUP_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "scale", Vector2(0.4, 0.4), POPUP_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "modulate:a", 0.0, POPUP_DURATION * 0.35).set_delay(POPUP_DURATION * 0.65)
	tween.chain().tween_callback(label.queue_free)
