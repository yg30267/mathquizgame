extends Node3D
class_name Damageable

func apply_damage(amount: float, hit_position: Vector3 = Vector3.ZERO) -> void:
	var health: Node = get_node_or_null("Health")
	if health and health.has_method("apply_damage"):
		health.apply_damage(amount, hit_position)