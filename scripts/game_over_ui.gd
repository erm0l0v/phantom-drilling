extends CanvasLayer

@onready var restart_button: Button = $Panel/VBox/RestartButton


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	visible = false


func show_game_over() -> void:
	visible = true


func hide_game_over() -> void:
	visible = false


func _on_restart_pressed() -> void:
	GameManager.restart()
