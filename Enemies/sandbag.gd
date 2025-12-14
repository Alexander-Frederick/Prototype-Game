extends StaticBody3D
class_name Sandbag

@export var max_hp: int = 10
var hp: int

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies") # so Ring 1 can find it

func apply_damage(amount: int, source: Node = null) -> bool:
	if amount <= 0:
		return false

	hp = max(hp - amount, 0)
	print("Sandbag took ", amount, " damage. HP=", hp, "/", max_hp)

	if hp == 0:
		print("Sandbag died.")
		queue_free()
		return true

	return false
