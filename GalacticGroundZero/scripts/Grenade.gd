extends RigidBody3D

@export var fuse_time: float = 2.5
@export var explosion_radius: float = 6.0
@export var max_damage: float = 80.0

func _ready() -> void:
	_explode_later()

func _explode_later() -> void:
	await get_tree().create_timer(fuse_time).timeout
	_explode()

func _explode() -> void:
	# Query overlapping bodies using a sphere shape
	var shape := SphereShape3D.new()
	shape.radius = explosion_radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), global_transform.origin)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var space := get_world_3d().direct_space_state
	var hits := space.intersect_shape(params)
	for h in hits:
		var collider := h.get("collider")
		var receiver := _find_damage_receiver(collider)
		if receiver and receiver.has_method("apply_damage"):
			var dist := global_transform.origin.distance_to((collider as Node3D).global_transform.origin)
			var dmg := clamp(max_damage * (1.0 - dist / explosion_radius), 0.0, max_damage)
			receiver.apply_damage(dmg, global_transform.origin)
	queue_free()

func _find_damage_receiver(node: Object) -> Node:
	var n := node as Node
	while n:
		if n.has_method("apply_damage"):
			return n
		n = n.get_parent()
	return null