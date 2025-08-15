extends CharacterBody3D

@onready var camera: Camera3D = $Camera3D
@onready var gun_muzzle: Node3D = $Camera3D/Gun/Muzzle

# Movement
@export var walk_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 5.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_underwater: bool = false
@export var underwater_speed_multiplier: float = 0.6
@export var underwater_gravity_multiplier: float = 0.3

# View
@export var mouse_sensitivity: float = 0.1
@export var fov_normal: float = 75.0
@export var fov_ads: float = 55.0
@export var fov_lerp_speed: float = 12.0
var rotation_x: float = 0.0
var rotation_y: float = 0.0

# Gun
@export var fire_rate: float = 9.0 # bullets per second
@export var bullet_damage: float = 25.0
@export var bullet_range: float = 150.0
@export var spread_degrees: float = 1.2
@export var magazine_size: int = 30
var ammo_in_mag: int = magazine_size
var can_fire: bool = true
var is_reloading: bool = false
var time_since_last_shot: float = 0.0

# Grenades
@export var grenade_scene: PackedScene
@export var grenade_count: int = 3
@export var grenade_throw_force: float = 14.0
@export var grenade_upward_boost: float = 3.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.fov = fov_normal
	if grenade_scene == null:
		grenade_scene = load("res://scenes/Grenade.tscn")

func set_underwater_mode(enabled: bool) -> void:
	is_underwater = enabled

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * mouse_sensitivity * 0.01
		rotation_x -= event.relative.y * mouse_sensitivity * 0.01
		rotation_x = clamp(rotation_x, deg_to_rad(-89), deg_to_rad(89))
		rotation.y = rotation_y
		camera.rotation.x = rotation_x

func _physics_process(delta: float) -> void:
	_update_fov(delta)
	_process_combat(delta)
	var input_dir := _get_input_direction()
	var speed := walk_speed
	if Input.is_action_pressed("sprint"):
		speed = sprint_speed
	if is_underwater:
		speed *= underwater_speed_multiplier
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Gravity and jump
	var applied_gravity := gravity
	if is_underwater:
		applied_gravity *= underwater_gravity_multiplier
	if not is_on_floor():
		velocity.y -= applied_gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

func _update_fov(delta: float) -> void:
	var target_fov := fov_normal
	if Input.is_action_pressed("aim"):
		target_fov = fov_ads
	camera.fov = lerp(camera.fov, target_fov, 1.0 - pow(0.001, delta * fov_lerp_speed))

func _process_combat(delta: float) -> void:
	time_since_last_shot += delta
	if Input.is_action_just_pressed("reload") and not is_reloading and ammo_in_mag < magazine_size:
		_reload()
	if Input.is_action_pressed("fire") and not is_reloading:
		var time_between_shots := 1.0 / fire_rate
		if time_since_last_shot >= time_between_shots:
			_fire()
	if Input.is_action_just_pressed("throw_grenade"):
		_throw_grenade()

func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		dir.y -= 1
	if Input.is_action_pressed("move_back"):
		dir.y += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	return dir.normalized()

func _fire() -> void:
	if ammo_in_mag <= 0:
		_reload()
		return
	ammo_in_mag -= 1
	time_since_last_shot = 0.0
	var from := camera.global_transform.origin
	var dir := -camera.global_transform.basis.z
	# Spread
	var spread_rad := deg_to_rad(spread_degrees)
	dir = dir.rotated(camera.global_transform.basis.x, randf_range(-spread_rad, spread_rad))
	dir = dir.rotated(camera.global_transform.basis.y, randf_range(-spread_rad, spread_rad))
	var to := from + dir * bullet_range
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result := space.intersect_ray(query)
	if result.size() > 0:
		var collider := result["collider"]
		var hit_pos := result["position"]
		var damage_receiver := _find_damage_receiver(collider)
		if damage_receiver and damage_receiver.has_method("apply_damage"):
			damage_receiver.apply_damage(bullet_damage, hit_pos)

func _reload() -> void:
	if is_reloading:
		return
	is_reloading = true
	await get_tree().create_timer(1.7).timeout
	ammo_in_mag = magazine_size
	is_reloading = false

func _throw_grenade() -> void:
	if grenade_count <= 0:
		return
	grenade_count -= 1
	var grenade := grenade_scene.instantiate() as RigidBody3D
	grenade.global_transform = gun_muzzle.global_transform
	get_tree().current_scene.add_child(grenade)
	var forward := -camera.global_transform.basis.z
	grenade.apply_impulse(forward * grenade_throw_force + Vector3.UP * grenade_upward_boost)

func _find_damage_receiver(node: Object) -> Node:
	var n := node as Node
	while n:
		if n.has_method("apply_damage"):
			return n
		n = n.get_parent()
	return null