class_name NavigationTestMap
extends TestMap

const CELL_SIZE := 32
const GRID_SIZE := Vector2i(64, 64)
const MAX_DESTINATION_PROJECTION_RADIUS := 3
const STATIC_OBSTACLE_BOUNDS := Rect2(832.0, 512.0, 384.0, 1024.0)
const DEFAULT_CLEARANCE_HALF_EXTENTS := Vector2(24.0, 24.0)
const OBSTACLE_COLOR := Color("242730")
const BLOCKED_CELL_COLOR := Color(0.85, 0.25, 0.2, 0.16)
const INVALID_DESTINATION_COLOR := Color("ff4d5e")

var _astar_grid := AStarGrid2D.new()
var _clearance_half_extents := DEFAULT_CLEARANCE_HALF_EXTENTS
var _invalid_destination := Vector2.ZERO
var _has_invalid_destination := false


func _ready() -> void:
	_rebuild_navigation_grid()
	queue_redraw()


func _draw() -> void:
	super()
	draw_rect(STATIC_OBSTACLE_BOUNDS, OBSTACLE_COLOR)

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

	if _has_invalid_destination:
		var marker_size := 14.0
		draw_line(
			_invalid_destination - Vector2(marker_size, marker_size),
			_invalid_destination + Vector2(marker_size, marker_size),
			INVALID_DESTINATION_COLOR,
			4.0
		)
		draw_line(
			_invalid_destination + Vector2(marker_size, -marker_size),
			_invalid_destination + Vector2(-marker_size, marker_size),
			INVALID_DESTINATION_COLOR,
			4.0
		)


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


func project_destination(
	world_position: Vector2,
	max_radius: int = MAX_DESTINATION_PROJECTION_RADIUS
) -> Vector2i:
	var requested_cell := world_to_grid(world_position)
	var best_cell := Vector2i(-1, -1)
	var best_distance_squared := INF

	for offset_y in range(-max_radius, max_radius + 1):
		for offset_x in range(-max_radius, max_radius + 1):
			var candidate := requested_cell + Vector2i(offset_x, offset_y)
			if not is_cell_navigable(candidate):
				continue

			var distance_squared := world_position.distance_squared_to(
				grid_to_world(candidate)
			)
			if (
				distance_squared < best_distance_squared
				or (
					is_equal_approx(distance_squared, best_distance_squared)
					and _cell_precedes(candidate, best_cell)
				)
			):
				best_cell = candidate
				best_distance_squared = distance_squared

	return best_cell


func request_world_path(
	start_world_position: Vector2,
	destination_world_position: Vector2
) -> PackedVector2Array:
	var start_cell := project_destination(start_world_position)
	var destination_cell := project_destination(destination_world_position)
	if start_cell.x < 0 or destination_cell.x < 0:
		return PackedVector2Array()

	var cell_path := _astar_grid.get_id_path(start_cell, destination_cell)
	if cell_path.is_empty():
		return PackedVector2Array()

	var world_path := PackedVector2Array()
	var first_path_index := 1 if cell_path.size() > 1 else 0
	for index in range(first_path_index, cell_path.size()):
		world_path.append(grid_to_world(cell_path[index]))
	return world_path


func request_grid_path(
	start_world_position: Vector2,
	destination_world_position: Vector2
) -> Array[Vector2i]:
	var start_cell := project_destination(start_world_position)
	var destination_cell := project_destination(destination_world_position)
	if start_cell.x < 0 or destination_cell.x < 0:
		return []
	return _astar_grid.get_id_path(start_cell, destination_cell)


func show_invalid_destination(world_position: Vector2) -> void:
	_invalid_destination = world_position
	_has_invalid_destination = true
	queue_redraw()


func clear_invalid_destination() -> void:
	if not _has_invalid_destination:
		return
	_has_invalid_destination = false
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

	var inflated_obstacle := STATIC_OBSTACLE_BOUNDS.grow_individual(
		_clearance_half_extents.x,
		_clearance_half_extents.y,
		_clearance_half_extents.x,
		_clearance_half_extents.y
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
			var blocked_by_obstacle := inflated_obstacle.has_point(cell_center)
			_astar_grid.set_point_solid(cell, outside_map or blocked_by_obstacle)


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
