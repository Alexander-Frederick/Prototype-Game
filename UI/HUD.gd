extends CanvasLayer
class_name HUD

@export var player: PlayerCombat
@export var rings: Rings

var _panel: PanelContainer
var _root_vbox: VBoxContainer

var _health_label: Label
var _health_bar: ProgressBar

var _shield_label: Label
var _shield_bar: ProgressBar

var _r1_charge_label: Label
var _r1_charge_bar: ProgressBar
var _r1_cd_label: Label
var _r1_cd_bar: ProgressBar

var _r2_charge_label: Label
var _r2_charge_bar: ProgressBar
var _r2_cd_label: Label
var _r2_cd_bar: ProgressBar

func _ready() -> void:
	_build_ui()

	if player != null:
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)
		if player.has_signal("shields_changed"):
			player.shields_changed.connect(_on_shields_changed)

		# Initialize immediately (safe, no has_variable)
		if player.config != null:
			_on_health_changed(player.health, player.config.max_health)
			_on_shields_changed(player.shields, player.config.max_shields)
		else:
			# Fallback if config is not assigned yet
			_on_health_changed(player.health, 100)
			_on_shields_changed(player.shields, 0)

	_update_rings_ui()


func _process(_delta: float) -> void:
	_update_rings_ui()

# ---------------------------------------------------------------------
# UI BUILD
# ---------------------------------------------------------------------

func _build_ui() -> void:
	_panel = PanelContainer.new()
	add_child(_panel)

	# Anchor to top-left with some margin
	_panel.anchor_left = 0.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = 16
	_panel.offset_top = 16
	_panel.offset_right = 360
	_panel.offset_bottom = 320

	_root_vbox = VBoxContainer.new()
	_root_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(_root_vbox)

	# Health row
	var health_row := _make_row("Health:", 240)
	_root_vbox.add_child(health_row)
	_health_label = health_row.get_node("Left") as Label
	_health_bar = health_row.get_node("Bar") as ProgressBar

	# Shields row
	var shield_row := _make_row("Shields:", 240)
	_root_vbox.add_child(shield_row)
	_shield_label = shield_row.get_node("Left") as Label
	_shield_bar = shield_row.get_node("Bar") as ProgressBar

	_root_vbox.add_child(_make_title("Ring 1"))

	var r1_charge_row := _make_row("Charge:", 240)
	_root_vbox.add_child(r1_charge_row)
	_r1_charge_label = r1_charge_row.get_node("Left") as Label
	_r1_charge_bar = r1_charge_row.get_node("Bar") as ProgressBar

	var r1_cd_row := _make_row("Cooldown:", 240)
	_root_vbox.add_child(r1_cd_row)
	_r1_cd_label = r1_cd_row.get_node("Left") as Label
	_r1_cd_bar = r1_cd_row.get_node("Bar") as ProgressBar

	_root_vbox.add_child(_make_title("Ring 2"))

	var r2_charge_row := _make_row("Charge:", 240)
	_root_vbox.add_child(r2_charge_row)
	_r2_charge_label = r2_charge_row.get_node("Left") as Label
	_r2_charge_bar = r2_charge_row.get_node("Bar") as ProgressBar

	var r2_cd_row := _make_row("Cooldown:", 240)
	_root_vbox.add_child(r2_cd_row)
	_r2_cd_label = r2_cd_row.get_node("Left") as Label
	_r2_cd_bar = r2_cd_row.get_node("Bar") as ProgressBar

func _make_title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	return l

func _make_row(left_text: String, bar_width: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var left := Label.new()
	left.name = "Left"
	left.text = left_text
	left.custom_minimum_size = Vector2(120, 0)
	row.add_child(left)

	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.custom_minimum_size = Vector2(float(bar_width), 18.0)
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	row.add_child(bar)

	return row

# ---------------------------------------------------------------------
# PLAYER SIGNAL HANDLERS
# ---------------------------------------------------------------------

func _on_health_changed(current: int, max_val: int) -> void:
	_health_bar.max_value = max_val
	_health_bar.value = current
	_health_label.text = "Health: %d / %d" % [current, max_val]

func _on_shields_changed(current: int, max_val: int) -> void:
	_shield_bar.max_value = max_val
	_shield_bar.value = current
	_shield_label.text = "Shields: %d / %d" % [current, max_val]

# ---------------------------------------------------------------------
# RINGS UI UPDATE (polling)
# ---------------------------------------------------------------------

func _update_rings_ui() -> void:
	if rings == null:
		return

	# Ring 1 charge
	var r1_req: int = int(rings.get_ring1_charge_required())
	var r1_charge: int = int(rings.get_ring1_charge())
	_r1_charge_bar.max_value = maxi(r1_req, 1)
	_r1_charge_bar.value = r1_charge
	_r1_charge_label.text = "Charge: %d / %d" % [r1_charge, r1_req]

	# Ring 1 cooldown
	var r1_cd_total: float = maxf(float(rings.get_ring1_cd_total()), 0.001)
	var r1_cd_left: float = float(rings.get_ring1_cd_left())
	_r1_cd_bar.max_value = r1_cd_total
	_r1_cd_bar.value = clampf(r1_cd_total - r1_cd_left, 0.0, r1_cd_total)
	_r1_cd_label.text = "Cooldown: %.1fs" % r1_cd_left

	# Ring 2 charge
	var r2_req: int = int(rings.get_ring2_charge_required())
	var r2_charge: int = int(rings.get_ring2_charge())
	_r2_charge_bar.max_value = maxi(r2_req, 1)
	_r2_charge_bar.value = r2_charge
	_r2_charge_label.text = "Charge: %d / %d" % [r2_charge, r2_req]

	# Ring 2 cooldown / active
	var r2_cd_total: float = maxf(float(rings.get_ring2_cd_total()), 0.001)
	var r2_cd_left: float = float(rings.get_ring2_cd_left())
	_r2_cd_bar.max_value = r2_cd_total
	_r2_cd_bar.value = clampf(r2_cd_total - r2_cd_left, 0.0, r2_cd_total)

	if rings.is_ring2_active():
		_r2_cd_label.text = "Active: %.1fs" % float(rings.get_ring2_time_left())
	else:
		_r2_cd_label.text = "Cooldown: %.1fs" % r2_cd_left
