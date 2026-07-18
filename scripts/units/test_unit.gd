class_name TestUnit
extends CharacterBody2D

@export var movement_speed: float = 180.0
@export var arrival_tolerance: float = 4.0

@onready var selection_indicator: Line2D = $SelectionIndicator

var _is_selected := false
var _movement_target := Vector2.ZERO
var _has_movement_target := false


func _ready() -> void:
	selection_indicator.visible = false


func _physics_process(delta: float) -> void:
	if not _has_movement_target:
		velocity = Vector2.ZERO
		return

	var offset_to_target := _movement_target - global_position
	var distance_to_target := offset_to_target.length()
	var maximum_step := movement_speed * delta

	if distance_to_target <= arrival_tolerance or distance_to_target <= maximum_step:
		global_position = _movement_target
		velocity = Vector2.ZERO
		_has_movement_target = false
		return

	velocity = offset_to_target / distance_to_target * movement_speed
	move_and_slide()


func set_selected(is_selected: bool) -> void:
	_is_selected = is_selected
	selection_indicator.visible = is_selected


func is_selected() -> bool:
	return _is_selected


func set_movement_target(target: Vector2) -> void:
	_movement_target = target
	_has_movement_target = true
