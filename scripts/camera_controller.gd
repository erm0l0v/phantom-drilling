extends Camera2D

# By default the camera tracks the highest (shallowest) placed building, so
# it follows the stack as it grows. Shift/Ctrl (held) or the mouse wheel
# (per notch) let the player look elsewhere within the playfield (tunnel +
# grid + funnel); once the player has done that, auto-follow stops fighting
# them until the next new game.

const SCROLL_SPEED := 200.0
const WHEEL_STEP := 32.0
const VIEWPORT_SIZE := Vector2(640, 360)
const FUNNEL_HEIGHT_TILES := 2
const RECENTER_DURATION := 0.2

var _min_y: float
var _max_y: float
var _manual_override := false
var _recenter_tween: Tween


func _ready() -> void:
	position = VIEWPORT_SIZE / 2.0
	GridManager.size_changed.connect(_on_grid_updated)
	GridManager.grid_changed.connect(_on_grid_updated)
	GameManager.game_restarted.connect(_on_game_restarted)
	_on_grid_updated()


func _on_game_restarted() -> void:
	_manual_override = false
	_on_grid_updated()


func _on_grid_updated() -> void:
	_recompute_bounds()
	if _manual_override:
		position.y = clamp(position.y, _min_y, _max_y)
	else:
		_recenter_on_highest_building()


func _recompute_bounds() -> void:
	var content_top: float = GridManager.ORIGIN.y - ResourceManager.balance.tunnel_height_tiles * GridManager.CELL_SIZE
	var content_bottom: float = GridManager.ORIGIN.y + GridManager.ROWS * GridManager.CELL_SIZE + FUNNEL_HEIGHT_TILES * GridManager.CELL_SIZE
	var content_height := content_bottom - content_top

	if content_height <= VIEWPORT_SIZE.y:
		_min_y = VIEWPORT_SIZE.y / 2.0
		_max_y = VIEWPORT_SIZE.y / 2.0
	else:
		_min_y = content_top + VIEWPORT_SIZE.y / 2.0
		_max_y = content_bottom - VIEWPORT_SIZE.y / 2.0


func _recenter_on_highest_building() -> void:
	var building_types := GridManager.get_building_types()
	var top_row: int = GridManager.ROWS
	for cell in building_types:
		top_row = min(top_row, cell.y)
	if building_types.is_empty():
		top_row = 0

	var target_y: float = GridManager.ORIGIN.y + top_row * GridManager.CELL_SIZE
	target_y = clamp(target_y, _min_y, _max_y)

	if _recenter_tween != null and _recenter_tween.is_valid():
		_recenter_tween.kill()
	_recenter_tween = create_tween()
	_recenter_tween.tween_property(self, "position:y", target_y, RECENTER_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	var direction := 0.0
	if Input.is_action_pressed("camera_up"):
		direction -= 1.0
	if Input.is_action_pressed("camera_down"):
		direction += 1.0
	if direction != 0.0:
		_manual_scroll(direction * SCROLL_SPEED * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_manual_scroll(-WHEEL_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_manual_scroll(WHEEL_STEP)


func _manual_scroll(amount: float) -> void:
	if not _manual_override and _recenter_tween != null and _recenter_tween.is_valid():
		_recenter_tween.kill()
	_manual_override = true
	position.y = clamp(position.y + amount, _min_y, _max_y)
