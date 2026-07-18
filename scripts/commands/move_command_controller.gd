class_name MoveCommandController
extends Node

@export var test_map: TestMap


func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_RIGHT
		and event.pressed
	):
		_issue_movement_command(event.position)


func _issue_movement_command(screen_position: Vector2) -> void:
	if test_map == null:
		push_error("MoveCommandController requires a TestMap reference.")
		return

	var world_position := _screen_to_world(screen_position)
	var movement_target := _clamp_to_map_bounds(world_position)

	for unit in _get_selected_units():
		unit.set_movement_target(movement_target)


func _get_selected_units() -> Array[TestUnit]:
	var selected_units: Array[TestUnit] = []
	for node: Node in get_tree().get_nodes_in_group(&"selectable_units"):
		if node is TestUnit and node.is_selected():
			selected_units.append(node)
	return selected_units


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func _clamp_to_map_bounds(world_position: Vector2) -> Vector2:
	var map_bounds := test_map.get_map_bounds()
	return Vector2(
		clampf(world_position.x, map_bounds.position.x, map_bounds.end.x),
		clampf(world_position.y, map_bounds.position.y, map_bounds.end.y)
	)
