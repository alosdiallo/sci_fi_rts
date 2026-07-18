class_name TestUnit
extends CharacterBody2D

@export var definition: UnitDefinition

@onready var selection_indicator: Line2D = $SelectionIndicator

var _is_selected := false
var _movement_target := Vector2.ZERO
var _has_movement_target := false


func _ready() -> void:
	selection_indicator.visible = false
	var validation_errors := _get_definition_validation_errors()
	if validation_errors.is_empty():
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


func _get_definition_validation_errors() -> PackedStringArray:
	if definition == null:
		return PackedStringArray(["definition must be assigned."])
	return definition.get_validation_errors()
