extends Node
class_name Rings

@export var config: CombatConfig
@export var player: PlayerCombat

var _ring1_cd := 0.0
var _ring2_cd := 0.0

var _ring1_charge := 0
var _ring2_charge := 0

var _ring2_active := false
var _ring2_left := 0.0

func _ready() -> void:
	if player != null:
		player.enemy_hit.connect(_on_player_enemy_hit)

	# Start rings fully charged (for testing)
	_ring1_charge = config.ring1_charge_required
	_ring2_charge = config.ring2_charge_required

func _process(delta: float) -> void:
	_ring1_cd = max(_ring1_cd - delta, 0.0)
	_ring2_cd = max(_ring2_cd - delta, 0.0)

	if _ring2_active:
		_ring2_left -= delta
		if _ring2_left <= 0.0:
			_end_time_slow()

	if Input.is_action_just_pressed("ring_1"):
		try_ring_1()

	if Input.is_action_just_pressed("ring_2"):
		try_ring_2()

func _on_player_enemy_hit(target: Node, damage: int, killed: bool) -> void:
	# Ring 1 recharges by hits.
	if _ring1_cd <= 0.0 and _ring1_charge < config.ring1_charge_required:
		_ring1_charge = min(_ring1_charge + config.ring1_charge_per_hit, config.ring1_charge_required)

	# Ring 2 recharges by kills.
	if killed and _ring2_cd <= 0.0 and _ring2_charge < config.ring2_charge_required:
		_ring2_charge = min(_ring2_charge + config.ring2_charge_per_kill, config.ring2_charge_required)

func try_ring_1() -> void:
	if _ring1_cd > 0.0:
		return
	if _ring1_charge < config.ring1_charge_required:
		return
	print("Casting Fire Burst")
	_ring1_charge = 0
	_ring1_cd = config.ring1_cooldown_sec

	# Minimal “hit all enemies”: anything in group "enemies" with apply_damage.
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e != null and e.has_method("apply_damage"):
			e.apply_damage(config.ring1_damage, player)

func try_ring_2() -> void:
	
	if _ring2_cd > 0.0 or _ring2_active:
		return
	if _ring2_charge < config.ring2_charge_required:
		return
		
	print("Casting Time Slow")
	_ring2_charge = 0
	_ring2_cd = config.ring2_cooldown_sec
	_start_time_slow()

func _start_time_slow() -> void:
	_ring2_active = true
	_ring2_left = config.ring2_duration_sec

	# Global slow time (simple prototype).
	Engine.time_scale = config.ring2_slow_scale

func _end_time_slow() -> void:
	_ring2_active = false
	Engine.time_scale = 1.0

# rings.gd (append to the bottom)

func get_ring1_charge() -> int:
	return _ring1_charge

func get_ring2_charge() -> int:
	return _ring2_charge

func get_ring1_charge_required() -> int:
	return config.ring1_charge_required

func get_ring2_charge_required() -> int:
	return config.ring2_charge_required

func get_ring1_cd_left() -> float:
	return _ring1_cd

func get_ring2_cd_left() -> float:
	return _ring2_cd

func get_ring1_cd_total() -> float:
	return config.ring1_cooldown_sec

func get_ring2_cd_total() -> float:
	return config.ring2_cooldown_sec

func is_ring2_active() -> bool:
	return _ring2_active

func get_ring2_time_left() -> float:
	return _ring2_left
