extends CharacterBody3D
class_name Enemy

@export_category("Stats")
@export var max_hp: int = 3
@export var contact_damage: int = 1

@export_category("Targeting")
@export var target_group: StringName = &"player"
@export var aggro_range: float = 14.0
@export var attack_range: float = 2.2

@export_category("Movement")
@export var move_speed: float = 3.0
@export var turn_speed: float = 10.0

@export_category("Attack")
@export var attack_cooldown_sec: float = 1.0
@export var attack_windup_sec: float = 0.18
@export var require_line_of_sight: bool = false

@export_category("Stopping")
@export var stop_distance: float = 1.4

@export_category("Animations")
@export var anim_player: AnimationPlayer
@export var anim_attack: StringName = &"attack"

var hp: int = 0

var _cooldown_left: float = 0.0
var _windup_left: float = 0.0
var _windup_target: Node3D = null

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")

	# Auto-find AnimationPlayer if not assigned in inspector
	if anim_player == null:
		anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer

func _physics_process(delta: float) -> void:
	_cooldown_left = max(_cooldown_left - delta, 0.0)
	_windup_left = max(_windup_left - delta, 0.0)

	if _windup_target != null:
		velocity = Vector3.ZERO
		move_and_slide()
		if _windup_left <= 0.0:
			_commit_attack()
		return

	var target := _get_target()
	if target == null:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var to_target: Vector3 = target.global_position - global_position
	var dist: float = to_target.length()

	if dist > 0.001:
		var desired_yaw: float = atan2(to_target.x, to_target.z)
		rotation.y = lerp_angle(rotation.y, desired_yaw, min(turn_speed * delta, 1.0))

	if dist <= attack_range and _cooldown_left <= 0.0:
		_start_attack(target)
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if dist <= aggro_range and dist > stop_distance:
		velocity = to_target.normalized() * move_speed
	else:
		velocity = Vector3.ZERO

	move_and_slide()

func _get_target() -> Node3D:
	var players := get_tree().get_nodes_in_group(String(target_group))
	var best: Node3D = null
	var best_dist := INF

	for p in players:
		var n := p as Node3D
		if n == null:
			continue
		var d := global_position.distance_squared_to(n.global_position)
		if d < best_dist:
			best_dist = d
			best = n

	if best != null and require_line_of_sight and not _has_line_of_sight(best):
		return null

	return best

func _has_line_of_sight(target: Node3D) -> bool:
	var from := global_position + Vector3.UP * 1.2
	var to := target.global_position + Vector3.UP * 1.2
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true

	var collider := hit.get("collider") as Node
	return collider == target or target.is_ancestor_of(collider)

func _start_attack(target: Node3D) -> void:
	# Animation hook: enemy attack (play at windup start)
	if anim_player != null and anim_player.has_animation(anim_attack):
		anim_player.play(anim_attack)

	_cooldown_left = attack_cooldown_sec
	_windup_left = attack_windup_sec
	_windup_target = target

	if _windup_left <= 0.0:
		_commit_attack()

func _commit_attack() -> void:
	var target := _windup_target
	_windup_target = null

	if target == null or not is_instance_valid(target):
		return

	if global_position.distance_to(target.global_position) > attack_range + 0.25:
		return

	if target.has_method("receive_incoming_damage"):
		target.receive_incoming_damage(contact_damage)
		return

	var p := target.get_parent()
	while p != null:
		if p.has_method("receive_incoming_damage"):
			p.receive_incoming_damage(contact_damage)
			return
		p = p.get_parent()

func apply_damage(amount: int, source: Node = null) -> bool:
	if amount <= 0:
		return false

	hp = max(hp - amount, 0)
	print("Enemy took ", amount, " damage. HP=", hp, "/", max_hp)

	if hp == 0:
		queue_free()
		return true

	return false
