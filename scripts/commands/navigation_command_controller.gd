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
		var result := navigation_map.request_navigation(unit.global_position, world_position)
		if not result.is_success():
			unit.record_navigation_failure(result.status, world_position)
			navigation_map.show_navigation_failure(result)
			print(
				"Navigation command rejected for %s at %s: requested %s; %s."
				% [unit.name, unit.get_path(), world_position, result.get_reason_text()]
			)
			continue

		if result.path.is_empty():
			unit.complete_navigation_command(
				world_position,
				result.accepted_destination,
				result.status,
				navigation_map.get_map_bounds()
			)
		else:
			unit.set_movement_route(
				result.path,
				navigation_map.get_map_bounds(),
				world_position,
				result.accepted_destination,
				result.status,
				result.raw_path
			)
		print(
			(
				"Navigation route for %s at %s: %s, raw %d waypoints / %.1f px, "
				+ "simplified %d waypoints / %.1f px."
			)
			% [
				unit.name,
				unit.get_path(),
				result.get_reason_text(),
				result.raw_path.size(),
				NavigationTestMap.calculate_world_path_length(
					unit.global_position,
					result.raw_path
				),
				result.path.size(),
				NavigationTestMap.calculate_world_path_length(
					unit.global_position,
					result.path
				),
			]
		)
		issued_route = true

	if issued_route:
		navigation_map.clear_navigation_failure()
