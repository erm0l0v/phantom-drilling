extends CanvasLayer


func _ready() -> void:
	GameManager.pause_toggled.connect(_on_pause_toggled)
	visible = false


func _on_pause_toggled(is_paused: bool) -> void:
	visible = is_paused
