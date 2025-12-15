extends Resource
class_name CombatConfig

@export_category("Player Resources")
@export var max_health: int = 5
@export var max_shields: int = 3

@export_category("Shield Regen")
@export var shield_regen_delay_sec: float = 2.0
@export var shield_regen_per_sec: float = 1.0

@export_category("Sword")
@export var sword_damage: int = 1
@export var sword_cooldown_sec: float = 0.35
@export var sword_range: float = 4.0

# You cannot start blocking while this lockout is active after attacking.
@export var attack_block_lockout_sec: float = 0.20

@export_category("Block")
@export var block_shield_damage_per_hit: int = 1
@export var perfect_block_window_sec: float = 0.12

# If block is pressed during attack lockout, allow it to begin shortly after.
@export var block_input_buffer_sec: float = 0.30

# If you press/hold block during an attack, keep it buffered for this long so it can
# begin as soon as the attack lockout ends.
@export var block_buffer_sec: float = 0.30

@export_category("Incoming Damage (for debug/testing)")
@export var test_incoming_damage: int = 1

@export_category("Ring 1: Fireburst")
@export var ring1_damage: int = 1
@export var ring1_cooldown_sec: float = 8.0
@export var ring1_charge_required: int = 4
@export var ring1_charge_per_hit: int = 1

@export_category("Ring 2: Time Slow")
@export var ring2_slow_scale: float = 0.35
@export var ring2_duration_sec: float = 2.5
@export var ring2_cooldown_sec: float = 12.0
@export var ring2_charge_required: int = 2
@export var ring2_charge_per_kill: int = 1
