extends Control

@onready var desert_button: Button = $CenterContainer/VBox/DesertButton
@onready var underwater_button: Button = $CenterContainer/VBox/UnderwaterButton
@onready var forest_button: Button = $CenterContainer/VBox/ForestButton
@onready var quit_button: Button = $CenterContainer/VBox/QuitButton

func _ready() -> void:
	desert_button.pressed.connect(_on_desert_pressed)
	underwater_button.pressed.connect(_on_underwater_pressed)
	forest_button.pressed.connect(_on_forest_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_desert_pressed() -> void:
	GameManager.set_selected_map(GameManager.MAP_DESERT)
	GameManager.start_game()

func _on_underwater_pressed() -> void:
	GameManager.set_selected_map(GameManager.MAP_UNDERWATER)
	GameManager.start_game()

func _on_forest_pressed() -> void:
	GameManager.set_selected_map(GameManager.MAP_FOREST)
	GameManager.start_game()

func _on_quit_pressed() -> void:
	get_tree().quit()