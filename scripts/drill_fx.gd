extends Node2D

# An animated drill sitting right below the game field (over the funnel),
# spinning while energy is actively being produced and sitting still
# otherwise. Reused across expansions - repositions itself on every grid
# size change to stay centered under the field.

const TEXTURE_PATH := "res://assets/drill_animationt.png"
const FRAME_WIDTH := 216
const FRAME_HEIGHT := 57
const FRAME_COUNT := 5
const FRAMES_PER_SECOND := 8.0
const ANIMATION_NAME := "default"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _was_producing := false


func _ready() -> void:
	sprite.centered = false
	sprite.sprite_frames = _build_frames()
	sprite.animation = ANIMATION_NAME
	sprite.frame = 0

	GridManager.size_changed.connect(_reposition)
	ResourceManager.resources_changed.connect(_on_resources_changed)
	_reposition()


func _build_frames() -> SpriteFrames:
	var texture: Texture2D = load(TEXTURE_PATH)
	var frames := SpriteFrames.new()
	if not frames.has_animation(ANIMATION_NAME):
		frames.add_animation(ANIMATION_NAME)
	frames.set_animation_speed(ANIMATION_NAME, FRAMES_PER_SECOND)
	frames.set_animation_loop(ANIMATION_NAME, true)
	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
		frames.add_frame(ANIMATION_NAME, atlas)
	return frames


func _reposition() -> void:
	var center_x: float = GridManager.ORIGIN.x + GridManager.COLS * GridManager.CELL_SIZE / 2.0
	var top_y: float = GridManager.ORIGIN.y + GridManager.ROWS * GridManager.CELL_SIZE
	sprite.position = Vector2(center_x - FRAME_WIDTH / 2.0, top_y)


func _on_resources_changed(_totals: Dictionary, rates: Dictionary) -> void:
	var is_producing: bool = rates[ResourceManager.ResourceType.ENERGY] > 0.0
	if is_producing and not _was_producing:
		sprite.play(ANIMATION_NAME)
	elif not is_producing and _was_producing:
		sprite.stop()
		sprite.frame = 0
	_was_producing = is_producing
