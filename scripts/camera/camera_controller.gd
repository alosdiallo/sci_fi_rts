class_name CameraController
extends Camera2D

@export var movement_speed: float = 600.0
@export var test_map: TestMap


func _ready() -> void:
	position_smoothing_enabled = false
	get_viewport().size_changed.connect(_clamp_to_map)
	_clamp_to_map()


func _process(delta: float) -> void:
	var input_direction := Input.get_vector(
		"camera_left",
		"camera_right",
		"camera_up",
		"camera_down"
	)
	global_position += input_direction * movement_speed * delta
	_clamp_to_map()


func _clamp_to_map() -> void:
	if test_map == null:
		push_error("CameraController requires a TestMap reference.")
		return

	var map_bounds := test_map.get_map_bounds()
	var half_viewport := get_viewport_rect().size * 0.5 / zoom
	var minimum_position := map_bounds.position + half_viewport
	var maximum_position := map_bounds.end - half_viewport

	global_position = Vector2(
		_clamp_axis(global_position.x, minimum_position.x, maximum_position.x),
		_clamp_axis(global_position.y, minimum_position.y, maximum_position.y)
	)


func _clamp_axis(value: float, minimum: float, maximum: float) -> float:
	if minimum > maximum:
		return (minimum + maximum) * 0.5
	return clampf(value, minimum, maximum)
