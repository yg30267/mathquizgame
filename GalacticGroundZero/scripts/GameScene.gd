extends Node3D

func _ready() -> void:
	GameManager.spawn_game(self)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		GameManager.quit_to_menu()