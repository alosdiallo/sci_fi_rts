class_name TestUnit
extends CharacterBody2D

@export var definition: UnitDefinition

@onready var selection_indicator: Line2D = $SelectionIndicator
@onready var health_bar: Control = $HealthBar
@onready var health_fill: ColorRect = $HealthBar/Fill
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _is_selected := false
var _movement_target := Vector2.ZERO
var _has_movement_target := false
var _current_health := 0.0
var _is_alive := false
var _health_initialized := false


func _ready() -> void:
	selection_indicator.visible = false
	health_bar.visible = false
	var validation_errors := _get_definition_validation_errors()
	if validation_errors.is_empty():
		_current_health = definition.max_health
		_is_alive = true
		_health_initialized = true
		_update_health_bar()
		return

	for validation_error in validation_errors:
		push_error(
			"%s at %s has an invalid unit definition: %s"
			% [name, get_path(), validation_error]
		)
	velocity = Vector2.ZERO
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not _has_movement_target:
		velocity = Vector2.ZERO
		return

	var offset_to_target := _movement_target - global_position
	var distance_to_target := offset_to_target.length()
	var maximum_step := definition.movement_speed * delta

	if (
		distance_to_target <= definition.arrival_tolerance
		or distance_to_target <= maximum_step
	):
		global_position = _movement_target
		velocity = Vector2.ZERO
		_has_movement_target = false
		return

	velocity = offset_to_target / distance_to_target * definition.movement_speed
	move_and_slide()


func set_selected(is_selected: bool) -> void:
	_is_selected = is_selected
	selection_indicator.visible = is_selected


func is_selected() -> bool:
	return _is_selected


func set_movement_target(target: Vector2) -> void:
	_movement_target = target
	_has_movement_target = true


func take_damage(amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		push_warning(
			"%s at %s rejected invalid damage amount: %s"
			% [name, get_path(), amount]
		)
		return
	if not _health_initialized or not _is_alive:
		push_warning("%s at %s cannot take damage without active health." % [name, get_path()])
		return

	_current_health = clampf(_current_health - amount, 0.0, definition.max_health)
	_update_health_bar()
	if is_zero_approx(_current_health):
		_die()


func get_current_health() -> float:
	return _current_health


func get_max_health() -> float:
	if not _health_initialized:
		return 0.0
	return definition.max_health


func is_alive() -> bool:
	return _is_alive


# TEMPORARY: Call from the debugger to verify damage and death before attacks exist.
func debug_take_damage(amount: float = 25.0) -> void:
	take_damage(amount)


func _get_definition_validation_errors() -> PackedStringArray:
	if definition == null:
		return PackedStringArray(["definition must be assigned."])
	return definition.get_validation_errors()


func _update_health_bar() -> void:
	if not _health_initialized:
		health_bar.visible = false
		return

	var health_ratio := clampf(_current_health / definition.max_health, 0.0, 1.0)
	health_fill.size.x = (health_bar.size.x - 4.0) * health_ratio
	health_bar.visible = health_ratio < 1.0


func _die() -> void:
	if not _is_alive:
		return

	_is_alive = false
	_is_selected = false
	selection_indicator.visible = false
	_has_movement_target = false
	_movement_target = Vector2.ZERO
	velocity = Vector2.ZERO
	remove_from_group(&"selectable_units")
	collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	queue_free()
