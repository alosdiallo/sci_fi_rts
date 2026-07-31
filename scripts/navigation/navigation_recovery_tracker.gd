class_name NavigationRecoveryTracker
extends RefCounted

enum Action {
	NONE,
	REFRESH_LOCAL_STATE,
	RECALCULATE_ROUTE,
	FAIL_ROUTE,
}

var _observation_window: float
var _minimum_progress: float
var _maximum_replan_attempts: int
var _observation_elapsed := 0.0
var _observation_start_position := Vector2.ZERO
var _observation_start_distance := 0.0
var _has_observation := false
var _local_refresh_used := false
var _replan_attempts := 0
var _recovery_events := 0
var _last_action := Action.NONE


func _init(
	observation_window: float = 1.5,
	minimum_progress: float = 4.0,
	maximum_replan_attempts: int = 2
) -> void:
	_observation_window = maxf(observation_window, 0.001)
	_minimum_progress = maxf(minimum_progress, 0.0)
	_maximum_replan_attempts = maxi(maximum_replan_attempts, 0)


func begin_command(position: Vector2, distance_to_waypoint: float) -> void:
	_local_refresh_used = false
	_replan_attempts = 0
	_recovery_events = 0
	_last_action = Action.NONE
	restart_observation(position, distance_to_waypoint)


func restart_observation(position: Vector2, distance_to_waypoint: float) -> void:
	_observation_elapsed = 0.0
	_observation_start_position = position
	_observation_start_distance = maxf(distance_to_waypoint, 0.0)
	_has_observation = true


func pause(position: Vector2, distance_to_waypoint: float) -> void:
	restart_observation(position, distance_to_waypoint)
	_last_action = Action.NONE


func observe(
	delta: float,
	position: Vector2,
	distance_to_waypoint: float,
	expects_movement: bool = true
) -> Action:
	if not expects_movement:
		pause(position, distance_to_waypoint)
		return Action.NONE
	if not _has_observation:
		restart_observation(position, distance_to_waypoint)

	_observation_elapsed += maxf(delta, 0.0)
	if _observation_elapsed < _observation_window:
		return Action.NONE

	var made_progress := has_meaningful_progress(
		_observation_start_position,
		position,
		_observation_start_distance,
		distance_to_waypoint,
		_minimum_progress
	)
	restart_observation(position, distance_to_waypoint)
	if made_progress:
		_last_action = Action.NONE
		return Action.NONE

	_recovery_events += 1
	if not _local_refresh_used:
		_local_refresh_used = true
		_last_action = Action.REFRESH_LOCAL_STATE
		return _last_action
	if _replan_attempts < _maximum_replan_attempts:
		_replan_attempts += 1
		_last_action = Action.RECALCULATE_ROUTE
		return _last_action

	_last_action = Action.FAIL_ROUTE
	return _last_action


func reset() -> void:
	_observation_elapsed = 0.0
	_observation_start_position = Vector2.ZERO
	_observation_start_distance = 0.0
	_has_observation = false
	_local_refresh_used = false
	_replan_attempts = 0
	_recovery_events = 0
	_last_action = Action.NONE


func get_replan_attempts() -> int:
	return _replan_attempts


func get_recovery_events() -> int:
	return _recovery_events


func get_last_action() -> Action:
	return _last_action


static func has_meaningful_progress(
	start_position: Vector2,
	current_position: Vector2,
	start_distance_to_waypoint: float,
	current_distance_to_waypoint: float,
	minimum_progress: float
) -> bool:
	var threshold := maxf(minimum_progress, 0.0)
	return (
		start_position.distance_squared_to(current_position) >= threshold * threshold
		or start_distance_to_waypoint - current_distance_to_waypoint >= threshold
	)


static func get_action_text(action: Action) -> String:
	match action:
		Action.REFRESH_LOCAL_STATE:
			return "refreshed local movement state"
		Action.RECALCULATE_ROUTE:
			return "recalculated route"
		Action.FAIL_ROUTE:
			return "stuck recovery budget exhausted"
		_:
			return "no recovery action"
