class_name NavigationTestMap
extends TestMap

const CELL_SIZE := 32
const GRID_SIZE := Vector2i(64, 64)
const MAX_DESTINATION_PROJECTION_RADIUS := 3
const STATIC_OBSTACLE_BOUNDS := Rect2(832.0, 512.0, 384.0, 1024.0)
const ENCLOSURE_TOP := Rect2(1248.0, 256.0, 384.0, 128.0)
const ENCLOSURE_BOTTOM := Rect2(1248.0, 512.0, 384.0, 128.0)
const ENCLOSURE_LEFT := Rect2(1248.0, 384.0, 128.0, 128.0)
const ENCLOSURE_RIGHT := Rect2(1504.0, 384.0, 128.0, 128.0)
const DEAD_END_LEFT := Rect2(224.0, 256.0, 64.0, 352.0)
const DEAD_END_RIGHT := Rect2(480.0, 256.0, 64.0, 352.0)
const DEAD_END_CAP := Rect2(224.0, 256.0, 320.0, 64.0)
const NARROW_BARRIER_LEFT := Rect2(128.0, 1408.0, 320.0, 192.0)
const NARROW_BARRIER_RIGHT := Rect2(480.0, 1408.0, 320.0, 192.0)
const DEFAULT_CLEARANCE_HALF_EXTENTS := Vector2(24.0, 24.0)
const OBSTACLE_COLOR := Color("242730")
const BLOCKED_CELL_COLOR := Color(0.85, 0.25, 0.2, 0.16)
const NO_VALID_DESTINATION_COLOR := Color("ff4d5e")
const NO_PATH_COLOR := Color("ff9f43")
const INVALID_START_COLOR := Color("ffe66d")

var _astar_grid := AStarGrid2D.new()
var _clearance_half_extents := DEFAULT_CLEARANCE_HALF_EXTENTS
var _last_failure_result: NavigationPathResult


func _ready() -> void:
	_rebuild_navigation_grid()
	queue_redraw()


func _draw() -> void:
	super()
	for obstacle in _get_static_obstacles():
		draw_rect(obstacle, OBSTACLE_COLOR)

	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			var cell := Vector2i(x, y)
			if not is_cell_navigable(cell):
				draw_rect(
					Rect2(
						MAP_BOUNDS.position + Vector2(cell * CELL_SIZE),
						Vector2.ONE * CELL_SIZE
					),
					BLOCKED_CELL_COLOR
				)

	if _last_failure_result != null:
		_draw_failure_marker(_last_failure_result)


func configure_clearance_for_unit(unit: TestUnit) -> void:
	if unit == null:
		return

	var half_extents := unit.get_footprint_half_extents()
	if half_extents.is_zero_approx() or half_extents.is_equal_approx(_clearance_half_extents):
		return

	_clearance_half_extents = half_extents
	_rebuild_navigation_grid()
	queue_redraw()


func world_to_grid(world_position: Vector2) -> Vector2i:
	var local_position := world_position - MAP_BOUNDS.position
	return Vector2i(
		floori(local_position.x / float(CELL_SIZE)),
		floori(local_position.y / float(CELL_SIZE))
	)


func grid_to_world(cell: Vector2i) -> Vector2:
	return (
		MAP_BOUNDS.position
		+ Vector2(cell * CELL_SIZE)
		+ Vector2.ONE * (float(CELL_SIZE) * 0.5)
	)


func is_cell_navigable(cell: Vector2i) -> bool:
	return _is_cell_in_bounds(cell) and not _astar_grid.is_point_solid(cell)


func request_navigation(
	start_world_position: Vector2,
	destination_world_position: Vector2
) -> NavigationPathResult:
	var result := NavigationPathResult.new()
	result.requested_start = start_world_position
	result.requested_destination = destination_world_position

	var start_cell := world_to_grid(start_world_position)
	if not is_cell_navigable(start_cell):
		result.status = NavigationPathResult.Status.INVALID_START
		return result

	var requested_cell := world_to_grid(destination_world_position)
	if is_cell_navigable(requested_cell):
		var direct_path := _astar_grid.get_id_path(start_cell, requested_cell)
		if direct_path.is_empty():
			result.status = NavigationPathResult.Status.NO_PATH
			return result
		return _complete_success_result(
			result,
			NavigationPathResult.Status.DIRECT,
			requested_cell,
			direct_path
		)

	var projection := _find_reachable_projection(
		start_cell,
		destination_world_position,
		MAX_DESTINATION_PROJECTION_RADIUS
	)
	var projected_cell: Vector2i = projection.cell
	if projected_cell.x < 0:
		result.status = (
			NavigationPathResult.Status.NO_PATH
			if projection.had_local_candidate
			else NavigationPathResult.Status.NO_VALID_DESTINATION
		)
		return result

	return _complete_success_result(
		result,
		NavigationPathResult.Status.PROJECTED,
		projected_cell,
		projection.path
	)


func request_grid_path(
	start_world_position: Vector2,
	destination_world_position: Vector2
) -> Array[Vector2i]:
	var start_cell := world_to_grid(start_world_position)
	var destination_cell := world_to_grid(destination_world_position)
	if not is_cell_navigable(start_cell) or not is_cell_navigable(destination_cell):
		return []
	return _astar_grid.get_id_path(start_cell, destination_cell)


func show_navigation_failure(result: NavigationPathResult) -> void:
	_last_failure_result = result
	queue_redraw()


func clear_navigation_failure() -> void:
	if _last_failure_result == null:
		return
	_last_failure_result = null
	queue_redraw()


func _rebuild_navigation_grid() -> void:
	_astar_grid = AStarGrid2D.new()
	_astar_grid.region = Rect2i(Vector2i.ZERO, GRID_SIZE)
	_astar_grid.cell_size = Vector2.ONE * CELL_SIZE
	_astar_grid.offset = MAP_BOUNDS.position + Vector2.ONE * (float(CELL_SIZE) * 0.5)
	_astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar_grid.update()

	var inflated_obstacles: Array[Rect2] = []
	for obstacle in _get_static_obstacles():
		inflated_obstacles.append(
			obstacle.grow_individual(
				_clearance_half_extents.x,
				_clearance_half_extents.y,
				_clearance_half_extents.x,
				_clearance_half_extents.y
			)
		)
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			var cell := Vector2i(x, y)
			var cell_center := grid_to_world(cell)
			var footprint_bounds := Rect2(
				cell_center - _clearance_half_extents,
				_clearance_half_extents * 2.0
			)
			var outside_map := not MAP_BOUNDS.encloses(footprint_bounds)
			var blocked_by_obstacle := false
			for inflated_obstacle in inflated_obstacles:
				if inflated_obstacle.has_point(cell_center):
					blocked_by_obstacle = true
					break
			_astar_grid.set_point_solid(cell, outside_map or blocked_by_obstacle)


func _complete_success_result(
	result: NavigationPathResult,
	status: NavigationPathResult.Status,
	destination_cell: Vector2i,
	cell_path: Array[Vector2i]
) -> NavigationPathResult:
	result.status = status
	result.accepted_destination = grid_to_world(destination_cell)
	if cell_path.size() <= 1:
		return result

	for index in range(1, cell_path.size()):
		result.path.append(grid_to_world(cell_path[index]))
	return result


func _find_reachable_projection(
	start_cell: Vector2i,
	world_position: Vector2,
	max_radius: int
) -> Dictionary:
	var requested_cell := world_to_grid(world_position)
	var candidates: Array[Vector2i] = []
	for offset_y in range(-max_radius, max_radius + 1):
		for offset_x in range(-max_radius, max_radius + 1):
			var candidate := requested_cell + Vector2i(offset_x, offset_y)
			if is_cell_navigable(candidate):
				candidates.append(candidate)

	candidates.sort_custom(
		func(first: Vector2i, second: Vector2i) -> bool:
			var first_distance := world_position.distance_squared_to(grid_to_world(first))
			var second_distance := world_position.distance_squared_to(grid_to_world(second))
			if not is_equal_approx(first_distance, second_distance):
				return first_distance < second_distance
			return _cell_precedes(first, second)
	)

	for candidate in candidates:
		var candidate_path := _astar_grid.get_id_path(start_cell, candidate)
		if not candidate_path.is_empty():
			return {
				"cell": candidate,
				"path": candidate_path,
				"had_local_candidate": true,
			}

	return {
		"cell": Vector2i(-1, -1),
		"path": [] as Array[Vector2i],
		"had_local_candidate": not candidates.is_empty(),
	}


func _get_static_obstacles() -> Array[Rect2]:
	return [
		STATIC_OBSTACLE_BOUNDS,
		ENCLOSURE_TOP,
		ENCLOSURE_BOTTOM,
		ENCLOSURE_LEFT,
		ENCLOSURE_RIGHT,
		DEAD_END_LEFT,
		DEAD_END_RIGHT,
		DEAD_END_CAP,
		NARROW_BARRIER_LEFT,
		NARROW_BARRIER_RIGHT,
	]


func _draw_failure_marker(result: NavigationPathResult) -> void:
	var marker_position := result.requested_destination
	var marker_size := 16.0
	match result.status:
		NavigationPathResult.Status.NO_VALID_DESTINATION:
			draw_line(
				marker_position - Vector2(marker_size, marker_size),
				marker_position + Vector2(marker_size, marker_size),
				NO_VALID_DESTINATION_COLOR,
				4.0
			)
			draw_line(
				marker_position + Vector2(marker_size, -marker_size),
				marker_position + Vector2(-marker_size, marker_size),
				NO_VALID_DESTINATION_COLOR,
				4.0
			)
		NavigationPathResult.Status.NO_PATH:
			draw_circle(marker_position, marker_size, NO_PATH_COLOR, false, 4.0)
			draw_line(
				marker_position - Vector2(marker_size, 0.0),
				marker_position + Vector2(marker_size, 0.0),
				NO_PATH_COLOR,
				4.0
			)
		NavigationPathResult.Status.INVALID_START:
			marker_position = result.requested_start
			var triangle := PackedVector2Array(
				[
					marker_position + Vector2(0.0, -marker_size),
					marker_position + Vector2(marker_size, marker_size),
					marker_position + Vector2(-marker_size, marker_size),
					marker_position + Vector2(0.0, -marker_size),
				]
			)
			draw_polyline(triangle, INVALID_START_COLOR, 4.0)


func _is_cell_in_bounds(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.y >= 0
		and cell.x < GRID_SIZE.x
		and cell.y < GRID_SIZE.y
	)


func _cell_precedes(first: Vector2i, second: Vector2i) -> bool:
	if second.x < 0:
		return true
	if first.y != second.y:
		return first.y < second.y
	return first.x < second.x
