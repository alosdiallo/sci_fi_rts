class_name UnitCommandController
extends Node

@export var test_map: TestMap


func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_RIGHT
		and event.pressed
	):
		_handle_contextual_command(event.position)


func _handle_contextual_command(screen_position: Vector2) -> void:
	if test_map == null:
		push_error("UnitCommandController requires a TestMap reference.")
		return

	var world_position := _screen_to_world(screen_position)
	var clicked_unit := _get_unit_at_world_position(world_position)
	if clicked_unit != null:
		_issue_target_command(clicked_unit)
		return

	_issue_movement_command(world_position)


func _issue_target_command(clicked_unit: TestUnit) -> void:
	var map_bounds := test_map.get_map_bounds()
	for unit in _get_selected_units():
		if unit.is_hostile_to(clicked_unit):
			unit.set_attack_target(clicked_unit, map_bounds)


func _issue_movement_command(world_position: Vector2) -> void:
	var map_bounds := test_map.get_map_bounds()
	for unit in _get_selected_units():
		unit.set_movement_target(world_position, map_bounds)


func _get_unit_at_world_position(world_position: Vector2) -> TestUnit:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var results := get_viewport().world_2d.direct_space_state.intersect_point(query)
	for result: Dictionary in results:
		var clicked_unit := result.get("collider") as TestUnit
		if clicked_unit != null:
			return clicked_unit
	return null


func _get_selected_units() -> Array[TestUnit]:
	var selected_units: Array[TestUnit] = []
	for node: Node in get_tree().get_nodes_in_group(&"selectable_units"):
		if node is TestUnit and node.is_selected():
			selected_units.append(node)
	return selected_units


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position
