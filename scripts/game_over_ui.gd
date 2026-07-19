extends CanvasLayer

@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var depth_label: Label = $Panel/VBox/DepthLabel


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	visible = false


func show_game_over(depth_meters: float) -> void:
	depth_label.text = "Depth reached: %d m" % [depth_meters]
	visible = true


func hide_game_over() -> void:
	visible = false


func _on_restart_pressed() -> void:
	GameManager.restart()
