extends CanvasLayer

@onready var ammo_label: Label = $Stats/Ammo
@onready var grenades_label: Label = $Stats/Grenades

var player: Node = null

func _ready() -> void:
	await get_tree().process_frame
	for n in get_tree().get_nodes_in_group("player"):
		player = n
		break

func _process(_delta: float) -> void:
	if player == null:
		return
	ammo_label.text = "Ammo: %d/%d" % [player.ammo_in_mag, player.magazine_size]
	grenades_label.text = "  |  Grenades: %d" % player.grenade_count