extends Node
class_name Health

@export var max_health: float = 100.0
var current_health: float

signal died
signal health_changed(current: float, max: float)

func _ready() -> void:
	current_health = max_health
	# Mark the owner as damageable for queries
	if owner and not owner.is_in_group("damageable"):
		owner.add_to_group("damageable")

func apply_damage(amount: float, _hit_position: Vector3 = Vector3.ZERO) -> void:
	current_health = max(0.0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	if current_health <= 0.0:
		_emit_and_die()

func _emit_and_die() -> void:
	emit_signal("died")
	if owner:
		owner.queue_free()
	else:
		queue_free()