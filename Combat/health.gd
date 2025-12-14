extends Node
class_name Health

signal died

@export var max_hp: int = 5
var hp: int

func _ready() -> void:
	hp = max_hp

func apply_damage(amount: int) -> bool:
	if amount <= 0:
		return false
	hp = max(hp - amount, 0)
	if hp == 0:
		died.emit()
		return true
	return false

func is_dead() -> bool:
	return hp <= 0
