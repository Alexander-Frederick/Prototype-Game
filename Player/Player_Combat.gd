extends CharacterBody3D
class_name PlayerCombat

signal enemy_hit(target: Node, damage: int, killed: bool)
signal player_damaged(amount: int)
signal shields_changed(current: int, max: int)
signal health_changed(current: int, max: int)

@export var config: CombatConfig
@export var camera: Camera3D

@export_category("Animations")
@export var anim_player: AnimationPlayer
@export var anim_attack: StringName = &"attack"
@export var anim_block: StringName = &"block"

var health: int
var shields: int

var _attack_cd_left := 0.0
var _attack_lockout_left := 0.0
var _is_blocking := false
var _block_started_time := -999.0

var _block_buffer_left := 0.0

var _shield_regen_delay_left := 0.0
var _shield_regen_accum := 0.0

func _ready() -> void:
	add_to_group("player")
	health = config.max_health
	shields = config.max_shields

	# Auto-find AnimationPlayer if not assigned in inspector
	if anim_player == null:
		anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer

	_emit_resource_signals()

func _process(delta: float) -> void:
	_attack_cd_left = max(_attack_cd_left - delta, 0.0)
	_attack_lockout_left = max(_attack_lockout_left - delta, 0.0)
	_block_buffer_left = max(_block_buffer_left - delta, 0.0)

	# Shield regen (wait a short delay after taking damage, then regen back to max)
	if shields < config.max_shields:
		_shield_regen_delay_left = max(_shield_regen_delay_left - delta, 0.0)
		if _shield_regen_delay_left <= 0.0 and config.shield_regen_per_sec > 0.0:
			_shield_regen_accum += config.shield_regen_per_sec * delta
			var add: int = int(floor(_shield_regen_accum))
			if add > 0:
				_shield_regen_accum -= float(add)
				var old := shields
				shields = mini(shields + add, config.max_shields)
				if shields != old:
					shields_changed.emit(shields, config.max_shields)
	else:
		# When full, keep timers clean.
		_shield_regen_delay_left = 0.0
		_shield_regen_accum = 0.0

	if Input.is_action_just_pressed("attack"):
		try_attack()

	if Input.is_action_pressed("block"):
		if not _is_blocking:
			# Do not allow block to start during the attack lockout.
			# Buffer the input so block can start shortly after.
			if _is_attacking():
				_block_buffer_left = maxf(_block_buffer_left, config.block_input_buffer_sec)
			else:
				_start_block()
	else:
		if _is_blocking:
			_stop_block()
		_block_buffer_left = 0.0

	# If block was pressed during an attack, start it as soon as we are allowed.
	if not _is_blocking and _block_buffer_left > 0.0 and not _is_attacking() and Input.is_action_pressed("block"):
		_start_block()
		_block_buffer_left = 0.0

	# Temporary test so you can validate block/perfect timing without enemy AI.
	if Input.is_action_just_pressed("debug_take_damage"):
		receive_incoming_damage(config.test_incoming_damage)

func try_attack() -> void:
	# No attacking while blocking.
	if _is_blocking:
		return
	if _attack_cd_left > 0.0:
		return

	# Animation hook: attack
	if anim_player != null and anim_player.has_animation(anim_attack):
		anim_player.play(anim_attack)

	_attack_cd_left = config.sword_cooldown_sec
	_attack_lockout_left = maxf(config.attack_block_lockout_sec, 0.0)

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

	# Animation hook: block
	if anim_player != null and anim_player.has_animation(anim_block):
		anim_player.play(anim_block)

func _stop_block() -> void:
	_is_blocking = false

	# Optional: stop only if we are currently playing the block animation
	if anim_player != null and anim_player.is_playing() and anim_player.current_animation == String(anim_block):
		anim_player.stop()

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
			_reset_shield_regen_timer()
			shields_changed.emit(shields, config.max_shields)
			return
		# No shields left -> take health damage
		_take_health_damage(amount)
		return

	# Not blocking -> take health damage
	_take_health_damage(amount)

func _take_health_damage(amount: int) -> void:
	health = max(health - amount, 0)
	_reset_shield_regen_timer()
	player_damaged.emit(amount)
	health_changed.emit(health, config.max_health)

func _reset_shield_regen_timer() -> void:
	# Whenever we take damage (blocked or not), postpone regen.
	_shield_regen_delay_left = maxf(config.shield_regen_delay_sec, 0.0)
	_shield_regen_accum = 0.0

func _is_attacking() -> bool:
	return _attack_lockout_left > 0.0

func _emit_resource_signals() -> void:
	health_changed.emit(health, config.max_health)
	shields_changed.emit(shields, config.max_shields)
