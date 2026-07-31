class_name UnitNavigationState
extends RefCounted

const PROGRESS_WINDOW := 1.5
const MINIMUM_PROGRESS := 4.0
const MAXIMUM_REPLAN_ATTEMPTS := 2

var _waypoints := PackedVector2Array()
var _raw_waypoints := PackedVector2Array()
var _route_start := Vector2.ZERO
var _waypoint_index := 0
var _is_route_active := false
var _is_combat_route := false
var _last_result := NavigationPathResult.Status.NONE
var _last_requested_destination := Vector2.ZERO
var _accepted_destination := Vector2.ZERO
var _last_destination_was_projected := false
var _navigation_map: NavigationTestMap
var _command_sequence := -1
var _priority := 0
var _chokepoint_id := -1
var _chokepoint_holding_point := Vector2.ZERO
var _chokepoint_entry_side := 0
var _is_waiting_at_chokepoint := false
var _chokepoint_entry_granted := false
var _recovery := NavigationRecoveryTracker.new(
	PROGRESS_WINDOW,
	MINIMUM_PROGRESS,
	MAXIMUM_REPLAN_ATTEMPTS
)
var _recovery_failed := false


func assign_route(
	waypoints: PackedVector2Array,
	raw_waypoints: PackedVector2Array,
	route_start: Vector2,
	is_combat_route: bool,
	navigation_map: NavigationTestMap,
	command_sequence: int,
	priority: int,
	chokepoint_id: int,
	chokepoint_holding_point: Vector2,
	chokepoint_entry_side: int,
	preserve_recovery_state: bool = false
) -> void:
	clear_route(not preserve_recovery_state)
	_waypoints = waypoints.duplicate()
	_raw_waypoints = raw_waypoints.duplicate()
	_route_start = route_start
	_waypoint_index = 0
	_is_route_active = not _waypoints.is_empty()
	_is_combat_route = is_combat_route and _is_route_active
	_navigation_map = navigation_map
	_command_sequence = command_sequence
	_priority = priority
	_chokepoint_id = chokepoint_id
	_chokepoint_holding_point = chokepoint_holding_point
	_chokepoint_entry_side = chokepoint_entry_side
	_is_waiting_at_chokepoint = false
	_chokepoint_entry_granted = false
	_recovery_failed = false
	if not _is_route_active:
		return

	var first_waypoint_distance := route_start.distance_to(_waypoints[0])
	if preserve_recovery_state:
		_recovery.restart_observation(route_start, first_waypoint_distance)
	else:
		_recovery.begin_command(route_start, first_waypoint_distance)


func clear_route(reset_recovery_state: bool = true) -> void:
	_waypoints = PackedVector2Array()
	_raw_waypoints = PackedVector2Array()
	_route_start = Vector2.ZERO
	_waypoint_index = 0
	_is_route_active = false
	_is_combat_route = false
	_navigation_map = null
	_command_sequence = -1
	_priority = 0
	_chokepoint_id = -1
	_chokepoint_holding_point = Vector2.ZERO
	_chokepoint_entry_side = 0
	_is_waiting_at_chokepoint = false
	_chokepoint_entry_granted = false
	if reset_recovery_state:
		_recovery.reset()
		_recovery_failed = false


func record_success(
	status: NavigationPathResult.Status,
	requested_destination: Vector2,
	accepted_destination: Vector2
) -> void:
	_last_result = status
	_last_requested_destination = requested_destination
	_accepted_destination = accepted_destination
	_last_destination_was_projected = (
		status == NavigationPathResult.Status.PROJECTED
	)


func record_failure(
	status: NavigationPathResult.Status,
	requested_destination: Vector2
) -> void:
	_last_result = status
	_last_requested_destination = requested_destination
	_last_destination_was_projected = false


func get_last_result() -> NavigationPathResult.Status:
	return _last_result


func get_last_requested_destination() -> Vector2:
	return _last_requested_destination


func get_accepted_destination() -> Vector2:
	return _accepted_destination


func set_accepted_destination(destination: Vector2) -> void:
	_accepted_destination = destination


func was_last_destination_projected() -> bool:
	return _last_destination_was_projected


func clear_projection_flag() -> void:
	_last_destination_was_projected = false


func has_active_route() -> bool:
	return _is_route_active


func is_ground_route() -> bool:
	return _is_route_active and not _is_combat_route


func is_combat_route() -> bool:
	return _is_route_active and _is_combat_route


func get_waypoints() -> PackedVector2Array:
	return _waypoints.duplicate()


func get_raw_waypoints() -> PackedVector2Array:
	return _raw_waypoints.duplicate()


func get_route_start() -> Vector2:
	return _route_start


func get_waypoint_index() -> int:
	return _waypoint_index


func has_current_waypoint() -> bool:
	return _is_route_active and _waypoint_index < _waypoints.size()


func get_current_waypoint() -> Vector2:
	if not has_current_waypoint():
		return Vector2.ZERO
	return _waypoints[_waypoint_index]


func advance_waypoint() -> void:
	if has_current_waypoint():
		_waypoint_index += 1


func is_route_complete() -> bool:
	return not _is_route_active or _waypoint_index >= _waypoints.size()


func get_navigation_map() -> NavigationTestMap:
	return _navigation_map


func get_command_sequence() -> int:
	return _command_sequence


func get_priority() -> int:
	return _priority


func get_chokepoint_id() -> int:
	return _chokepoint_id


func get_chokepoint_holding_point() -> Vector2:
	return _chokepoint_holding_point


func get_chokepoint_entry_side() -> int:
	return _chokepoint_entry_side


func is_waiting_at_chokepoint() -> bool:
	return _is_waiting_at_chokepoint


func set_waiting_at_chokepoint(waiting: bool) -> void:
	_is_waiting_at_chokepoint = waiting


func is_chokepoint_entry_granted() -> bool:
	return _chokepoint_entry_granted


func grant_chokepoint_entry() -> void:
	_chokepoint_entry_granted = true


func pause_recovery(position: Vector2, distance_to_waypoint: float) -> void:
	_recovery.pause(position, distance_to_waypoint)


func restart_recovery_observation(
	position: Vector2,
	distance_to_waypoint: float
) -> void:
	_recovery.restart_observation(position, distance_to_waypoint)


func observe_recovery(
	delta: float,
	position: Vector2,
	distance_to_waypoint: float
) -> NavigationRecoveryTracker.Action:
	return _recovery.observe(delta, position, distance_to_waypoint)


func get_recovery_events() -> int:
	return _recovery.get_recovery_events()


func get_replan_attempts() -> int:
	return _recovery.get_replan_attempts()


func get_recovery_action() -> NavigationRecoveryTracker.Action:
	return _recovery.get_last_action()


func has_recovery_failure() -> bool:
	return _recovery_failed


func mark_recovery_failed() -> void:
	_recovery_failed = true
