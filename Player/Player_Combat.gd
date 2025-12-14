extends CharacterBody3D
class_name PlayerCombat

signal enemy_hit(target: Node, damage: int, killed: bool)
signal player_damaged(amount: int)
signal shields_changed(current: int, max: int)
signal health_changed(current: int, max: int)

@export var config: CombatConfig
@export var camera: Camera3D

var health: int
var shields: int

var _attack_cd_left := 0.0
var _is_blocking := false
var _block_started_time := -999.0

func _ready() -> void:
	health = config.max_health
	shields = config.max_shields
	_emit_resource_signals()

func _process(delta: float) -> void:
	_attack_cd_left = max(_attack_cd_left - delta, 0.0)

	if Input.is_action_just_pressed("attack"):
		try_attack()

	if Input.is_action_pressed("block"):
		if not _is_blocking:
			_start_block()
	else:
		if _is_blocking:
			_stop_block()

	# Temporary test so you can validate block/perfect timing without enemy AI.
	if Input.is_action_just_pressed("debug_take_damage"):
		receive_incoming_damage(config.test_incoming_damage)

func try_attack() -> void:
	if _attack_cd_left > 0.0:
		return

	_attack_cd_left = config.sword_cooldown_sec

	var target := _ray_pick_damageable(config.sword_range)
	if target == null:
		return

	var killed := false
	if target.has_method("apply_damage"):
		killed = target.apply_damage(config.sword_damage, self)

	enemy_hit.emit(target, config.sword_damage, killed)

func _ray_pick_damageable(max_dist: float) -> Node:
	if camera == null:
		push_warning("PlayerCombat: camera not assigned.")
		return null

	var vp := get_viewport()
	var mouse_pos := vp.get_mouse_position()

	var origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var dir: Vector3 = camera.project_ray_normal(mouse_pos)
	var to: Vector3 = origin + dir * max_dist

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null

	var collider_obj: Object = hit.get("collider", null)
	if collider_obj == null:
		return null

	# collider is usually a Node, but type it safely
	var collider_node: Node = collider_obj as Node
	if collider_node == null:
		return null

	if collider_node.has_method("apply_damage"):
		return collider_node

	var p: Node = collider_node.get_parent()
	while p != null:
		if p.has_method("apply_damage"):
			return p
		p = p.get_parent()

	return null

func _start_block() -> void:
	_is_blocking = true
	_block_started_time = Time.get_ticks_msec() / 1000.0

func _stop_block() -> void:
	_is_blocking = false

func receive_incoming_damage(amount: int) -> void:
	if amount <= 0:
		return

	# Perfect block: within a short window after block starts.
	var now := Time.get_ticks_msec() / 1000.0
	var perfect := _is_blocking and (now - _block_started_time) <= config.perfect_block_window_sec

	if perfect:
		# No shield damage, no health damage.
		return

	if _is_blocking:
		# Blocking consumes shields if available; otherwise health.
		if shields > 0:
			shields = max(shields - config.block_shield_damage_per_hit, 0)
			shields_changed.emit(shields, config.max_shields)
			return
		# No shields left -> take health damage
		_take_health_damage(amount)
		return

	# Not blocking -> take health damage
	_take_health_damage(amount)

func _take_health_damage(amount: int) -> void:
	health = max(health - amount, 0)
	player_damaged.emit(amount)
	health_changed.emit(health, config.max_health)

func _emit_resource_signals() -> void:
	health_changed.emit(health, config.max_health)
	shields_changed.emit(shields, config.max_shields)
