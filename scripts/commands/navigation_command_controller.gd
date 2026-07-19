class_name NavigationCommandController
extends UnitCommandController


func _issue_movement_command(world_position: Vector2) -> void:
	var navigation_map := test_map as NavigationTestMap
	if navigation_map == null:
		push_error("NavigationCommandController requires a NavigationTestMap reference.")
		return

	var selected_units := _get_selected_units()
	if selected_units.is_empty():
		return

	var issued_route := false
	for unit in selected_units:
		navigation_map.configure_clearance_for_unit(unit)
		var path := navigation_map.request_world_path(unit.global_position, world_position)
		if path.is_empty():
			continue
		unit.set_movement_route(path, navigation_map.get_map_bounds())
		issued_route = true

	if issued_route:
		navigation_map.clear_invalid_destination()
	else:
		navigation_map.show_invalid_destination(world_position)
