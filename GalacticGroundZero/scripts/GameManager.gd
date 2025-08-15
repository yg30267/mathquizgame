extends Node
class_name GameManager

const MAP_DESERT := "Desert"
const MAP_UNDERWATER := "Underwater"
const MAP_FOREST := "Forest"

const MAP_PATHS := {
	MAP_DESERT: "res://maps/Desert.tscn",
	MAP_UNDERWATER: "res://maps/Underwater.tscn",
	MAP_FOREST: "res://maps/Forest.tscn"
}

var selected_map: String = MAP_DESERT

var _player_scene: PackedScene = preload("res://scenes/Player.tscn")
var _hud_scene: PackedScene = preload("res://scenes/UI/HUD.tscn")

func _ready() -> void:
	_setup_default_input_map()
	# Ensure the mouse is visible on menus
	if Engine.is_editor_hint() == false:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_selected_map(map_name: String) -> void:
	if MAP_PATHS.has(map_name):
		selected_map = map_name

func start_game() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func quit_to_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func spawn_game(root: Node) -> void:
	# Load selected map
	var map_path := MAP_PATHS.get(selected_map, "")
	if map_path == "":
		push_error("Invalid map selection: %s" % selected_map)
		return
	var map_scene: PackedScene = load(map_path)
	var map_instance: Node = map_scene.instantiate()
	root.add_child(map_instance)

	# Spawn player
	var player := _player_scene.instantiate()
	player.add_to_group("player")
	var spawn: Node3D = map_instance.get_node_or_null("PlayerSpawn") as Node3D
	if spawn:
		player.global_transform = spawn.global_transform
	else:
		var fallback := Transform3D(Basis(), Vector3(0, 2, 0))
		player.global_transform = fallback
	root.add_child(player)

	# Underwater tweaks
	if selected_map == MAP_UNDERWATER and player.has_method("set_underwater_mode"):
		player.set_underwater_mode(true)

	# HUD
	var hud := _hud_scene.instantiate()
	root.add_child(hud)

func _setup_default_input_map() -> void:
	func ensure_action(action_name: String) -> void:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

	func bind_key(action_name: String, keycode: int) -> void:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		InputMap.action_add_event(action_name, ev)

	func bind_mouse(action_name: String, button_index: int) -> void:
		var ev := InputEventMouseButton.new()
		ev.button_index = button_index
		InputMap.action_add_event(action_name, ev)

	var actions := [
		"move_forward", "move_back", "move_left", "move_right",
		"jump", "sprint", "fire", "aim", "reload", "throw_grenade", "pause"
	]
	for a in actions:
		ensure_action(a)

	# Movement
	bind_key("move_forward", KEY_W)
	bind_key("move_forward", KEY_UP)
	bind_key("move_back", KEY_S)
	bind_key("move_back", KEY_DOWN)
	bind_key("move_left", KEY_A)
	bind_key("move_left", KEY_LEFT)
	bind_key("move_right", KEY_D)
	bind_key("move_right", KEY_RIGHT)

	# Actions
	bind_key("jump", KEY_SPACE)
	bind_key("sprint", KEY_SHIFT)
	bind_key("reload", KEY_R)
	bind_key("throw_grenade", KEY_G)
	bind_key("pause", KEY_ESCAPE)
	bind_mouse("fire", MOUSE_BUTTON_LEFT)
	bind_mouse("aim", MOUSE_BUTTON_RIGHT)