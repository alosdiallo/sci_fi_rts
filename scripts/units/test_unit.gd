class_name TestUnit
extends CharacterBody2D

const HIT_FEEDBACK_DURATION := 0.12
const ATTACK_APPROACH_MARGIN := 8.0
const APPROACH_TARGET_REFRESH_DISTANCE := 8.0
const APPROACH_TARGET_REFRESH_DISTANCE_SQUARED := (
	APPROACH_TARGET_REFRESH_DISTANCE * APPROACH_TARGET_REFRESH_DISTANCE
)
const SEPARATION_DEAD_ZONE := 0.5
const MAX_SEPARATION_CONTRIBUTION := 0.35

@export var definition: UnitDefinition
@export var team_id: int = 0

@onready var selection_indicator: Line2D = $SelectionIndicator
@onready var target_indicator: Line2D = $TargetIndicator
@onready var hit_indicator: Line2D = $HitIndicator
@onready var health_bar: Control = $HealthBar
@onready var health_fill: ColorRect = $HealthBar/Fill
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

var _is_selected := false
var _movement_target := Vector2.ZERO
var _has_movement_target := false
var _navigation_state := UnitNavigationState.new()
var _current_health := 0.0
var _is_alive := false
var _health_initialized := false
var _attack_target: TestUnit
var _is_approaching_attack_target := false
var _cached_target_position := Vector2.ZERO
var _cached_approach_destination := Vector2.ZERO
var _has_cached_approach_destination := false
var _cached_attack_slot_index := -1
var _cached_attack_slot_count := 0
var _combat_navigation_map: NavigationTestMap
var _has_combat_navigation_request := false
var _combat_navigation_failed := false
var _combat_navigation_failure_status := NavigationPathResult.Status.NONE
var _combat_desired_firing_position := Vector2.ZERO
var _combat_resolved_firing_position := Vector2.ZERO
var _combat_used_alternate_firing_position := false
var _map_bounds := Rect2()
var _has_map_bounds := false
var _attack_cooldown_remaining := 0.0
var _hit_feedback_remaining := 0.0
var _footprint_warning_reported := false


func _ready() -> void:
	selection_indicator.visible = false
	target_indicator.visible = false
	hit_indicator.visible = false
	health_bar.visible = false
	_get_footprint_half_extents()
	var validation_errors := _get_definition_validation_errors()
	if validation_errors.is_empty():
		_current_health = definition.max_health
		_is_alive = true
		_health_initialized = true
		_update_health_bar()
		return

	for validation_error in validation_errors:
		push_error(
			"%s at %s has an invalid unit definition: %s"
			% [name, get_path(), validation_error]
		)
	velocity = Vector2.ZERO
	set_physics_process(false)


func _process(delta: float) -> void:
	if _hit_feedback_remaining <= 0.0:
		return

	_hit_feedback_remaining = maxf(_hit_feedback_remaining - delta, 0.0)
	if is_zero_approx(_hit_feedback_remaining):
		hit_indicator.visible = false


func _physics_process(delta: float) -> void:
	if _update_attack_target_state(delta):
		return
	if _navigation_state.has_active_route():
		_move_toward_ground_route(delta)
		return
	if not _has_movement_target:
		_move_with_separation(Vector2.ZERO)
		return

	_move_toward_ground_target(delta)


func set_selected(selected: bool) -> void:
	_is_selected = selected
	selection_indicator.visible = selected
	_update_target_indicator()
	queue_redraw()


func is_selected() -> bool:
	return _is_selected


func set_movement_target(target: Vector2, map_bounds: Rect2 = Rect2()) -> void:
	clear_attack_target()
	_clear_ground_route()
	_set_map_bounds(map_bounds)
	_movement_target = _clamp_to_map_bounds(target)
	_has_movement_target = true


func set_movement_route(
	waypoints: PackedVector2Array,
	map_bounds: Rect2 = Rect2(),
	requested_destination: Vector2 = Vector2.ZERO,
	accepted_destination: Vector2 = Vector2.ZERO,
	result_status: NavigationPathResult.Status = NavigationPathResult.Status.DIRECT,
	raw_waypoints: PackedVector2Array = PackedVector2Array(),
	navigation_map: NavigationTestMap = null,
	command_sequence: int = -1,
	priority: int = 0,
	chokepoint_id: int = -1,
	chokepoint_holding_point: Vector2 = Vector2.ZERO,
	chokepoint_entry_side: int = 0
) -> void:
	if waypoints.is_empty():
		return

	clear_attack_target()
	_assign_navigation_route(
		waypoints,
		raw_waypoints,
		map_bounds,
		false,
		navigation_map,
		command_sequence,
		priority,
		chokepoint_id,
		chokepoint_holding_point,
		chokepoint_entry_side
	)
	_record_navigation_success(
		result_status,
		requested_destination,
		accepted_destination
	)


func _assign_navigation_route(
	waypoints: PackedVector2Array,
	raw_waypoints: PackedVector2Array,
	map_bounds: Rect2,
	is_combat_route: bool,
	navigation_map: NavigationTestMap = null,
	command_sequence: int = -1,
	priority: int = 0,
	chokepoint_id: int = -1,
	chokepoint_holding_point: Vector2 = Vector2.ZERO,
	chokepoint_entry_side: int = 0,
	preserve_recovery_state: bool = false
) -> void:
	_clear_ground_route(not preserve_recovery_state)
	_set_map_bounds(map_bounds)
	var clamped_waypoints := waypoints.duplicate()
	for index in range(clamped_waypoints.size()):
		clamped_waypoints[index] = _clamp_to_map_bounds(clamped_waypoints[index])
	_navigation_state.assign_route(
		clamped_waypoints,
		raw_waypoints,
		global_position,
		is_combat_route,
		navigation_map,
		command_sequence,
		priority,
		chokepoint_id,
		chokepoint_holding_point,
		chokepoint_entry_side,
		preserve_recovery_state
	)
	_has_movement_target = false
	_movement_target = Vector2.ZERO
	queue_redraw()


func complete_navigation_command(
	requested_destination: Vector2,
	accepted_destination: Vector2,
	result_status: NavigationPathResult.Status,
	map_bounds: Rect2 = Rect2()
) -> void:
	clear_attack_target()
	_clear_ground_route()
	_set_map_bounds(map_bounds)
	_has_movement_target = false
	_movement_target = Vector2.ZERO
	velocity = Vector2.ZERO
	_record_navigation_success(
		result_status,
		requested_destination,
		accepted_destination
	)


func record_navigation_failure(
	result_status: NavigationPathResult.Status,
	requested_destination: Vector2
) -> void:
	_navigation_state.record_failure(result_status, requested_destination)
	queue_redraw()


func get_last_navigation_result() -> NavigationPathResult.Status:
	return _navigation_state.get_last_result()


func get_accepted_navigation_destination() -> Vector2:
	return _navigation_state.get_accepted_destination()


func was_last_navigation_destination_projected() -> bool:
	return _navigation_state.was_last_destination_projected()


func is_ground_route_active() -> bool:
	return _navigation_state.is_ground_route()


func is_combat_route_active() -> bool:
	return _navigation_state.is_combat_route()


func has_combat_navigation_failure() -> bool:
	return _combat_navigation_failed


func get_combat_navigation_failure_status() -> NavigationPathResult.Status:
	return _combat_navigation_failure_status


func get_combat_resolved_firing_position() -> Vector2:
	return _combat_resolved_firing_position


func used_alternate_combat_firing_position() -> bool:
	return _combat_used_alternate_firing_position


func get_navigation_command_sequence() -> int:
	return _navigation_state.get_command_sequence()


func get_navigation_priority() -> int:
	return _navigation_state.get_priority()


func is_waiting_for_navigation_chokepoint(chokepoint_id: int) -> bool:
	return (
		_navigation_state.has_active_route()
		and _navigation_state.get_chokepoint_id() == chokepoint_id
		and _navigation_state.is_waiting_at_chokepoint()
	)


func holds_navigation_chokepoint_reservation(chokepoint_id: int) -> bool:
	var navigation_map := _navigation_state.get_navigation_map()
	return (
		_navigation_state.has_active_route()
		and navigation_map != null
		and _navigation_state.get_chokepoint_id() == chokepoint_id
		and _navigation_state.is_chokepoint_entry_granted()
		and not navigation_map.has_position_cleared_chokepoint(
			global_position,
			chokepoint_id,
			_navigation_state.get_chokepoint_entry_side()
		)
	)


func get_navigation_recovery_events() -> int:
	return _navigation_state.get_recovery_events()


func get_navigation_replan_attempts() -> int:
	return _navigation_state.get_replan_attempts()


func get_navigation_recovery_action() -> NavigationRecoveryTracker.Action:
	return _navigation_state.get_recovery_action()


func has_navigation_recovery_failure() -> bool:
	return _navigation_state.has_recovery_failure()


func _record_navigation_success(
	result_status: NavigationPathResult.Status,
	requested_destination: Vector2,
	accepted_destination: Vector2
) -> void:
	_navigation_state.record_success(
		result_status,
		requested_destination,
		accepted_destination
	)
	queue_redraw()


func set_attack_target(target: TestUnit, map_bounds: Rect2 = Rect2()) -> void:
	_assign_attack_target(target, map_bounds, null)


func set_navigation_attack_target(
	target: TestUnit,
	navigation_map: NavigationTestMap,
	map_bounds: Rect2 = Rect2()
) -> void:
	_assign_attack_target(target, map_bounds, navigation_map)


func _assign_attack_target(
	target: TestUnit,
	map_bounds: Rect2,
	navigation_map: NavigationTestMap
) -> void:
	if target == self or not is_hostile_to(target):
		return

	_clear_ground_route()
	_clear_combat_navigation_state()
	_set_map_bounds(map_bounds)
	_clear_approach_cache()
	_attack_target = target
	_combat_navigation_map = navigation_map
	_attack_cooldown_remaining = definition.attack_cooldown
	if navigation_map == null:
		_refresh_approach_destination()
	_is_approaching_attack_target = (
		global_position.distance_squared_to(target.global_position)
		> definition.attack_range * definition.attack_range
	)
	_has_movement_target = false
	_movement_target = Vector2.ZERO
	_navigation_state.clear_projection_flag()
	velocity = Vector2.ZERO
	_update_target_indicator()
	if navigation_map != null and _is_approaching_attack_target:
		_refresh_combat_navigation_route()


func clear_attack_target() -> void:
	_clear_combat_navigation_state()
	_attack_target = null
	_is_approaching_attack_target = false
	_clear_approach_cache()
	_attack_cooldown_remaining = 0.0
	velocity = Vector2.ZERO
	_update_target_indicator()


func _clear_combat_navigation_state() -> void:
	if _navigation_state.is_combat_route():
		_clear_ground_route()
	_combat_navigation_map = null
	_has_combat_navigation_request = false
	_combat_navigation_failed = false
	_combat_navigation_failure_status = NavigationPathResult.Status.NONE
	_combat_desired_firing_position = Vector2.ZERO
	_combat_resolved_firing_position = Vector2.ZERO
	_combat_used_alternate_firing_position = false
	queue_redraw()


func _clear_approach_cache() -> void:
	_cached_target_position = Vector2.ZERO
	_cached_approach_destination = Vector2.ZERO
	_has_cached_approach_destination = false
	_cached_attack_slot_index = -1
	_cached_attack_slot_count = 0


func get_attack_target() -> TestUnit:
	if not has_valid_attack_target():
		return null
	return _attack_target


func has_valid_attack_target() -> bool:
	return (
		is_instance_valid(_attack_target)
		and _attack_target != self
		and _attack_target.is_inside_tree()
		and _attack_target.is_alive()
		and is_hostile_to(_attack_target)
	)


func is_hostile_to(other: TestUnit) -> bool:
	return (
		is_instance_valid(other)
		and other != self
		and other.is_alive()
		and team_id != other.team_id
	)


func take_damage(amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		push_warning(
			"%s at %s rejected invalid damage amount: %s"
			% [name, get_path(), amount]
		)
		return
	if not _health_initialized or not _is_alive:
		push_warning("%s at %s cannot take damage without active health." % [name, get_path()])
		return

	_current_health = clampf(_current_health - amount, 0.0, definition.max_health)
	_show_hit_feedback()
	_update_health_bar()
	if is_zero_approx(_current_health):
		_die()


func get_current_health() -> float:
	return _current_health


func get_max_health() -> float:
	if not _health_initialized:
		return 0.0
	return definition.max_health


func is_alive() -> bool:
	return _is_alive


func _get_definition_validation_errors() -> PackedStringArray:
	if definition == null:
		return PackedStringArray(["definition must be assigned."])
	return definition.get_validation_errors()


func _update_health_bar() -> void:
	if not _health_initialized:
		health_bar.visible = false
		return

	var health_ratio := clampf(_current_health / definition.max_health, 0.0, 1.0)
	health_fill.size.x = (health_bar.size.x - 4.0) * health_ratio
	health_bar.visible = health_ratio < 1.0


func _update_attack_target_state(delta: float) -> bool:
	if not has_valid_attack_target():
		clear_attack_target()
		return false

	if _combat_navigation_map != null:
		return _update_navigation_attack_target_state(delta)

	_update_target_indicator()
	_update_approach_destination_if_needed()
	var distance_to_target_squared := global_position.distance_squared_to(
		_attack_target.global_position
	)
	var attack_range_squared := definition.attack_range * definition.attack_range
	if distance_to_target_squared > attack_range_squared:
		_attack_cooldown_remaining = definition.attack_cooldown
		if not _is_approaching_attack_target:
			_is_approaching_attack_target = true
		var reached_destination := _move_toward_approach_destination(delta)
		if (
			reached_destination
			and global_position.distance_squared_to(_attack_target.global_position)
			> _get_preferred_firing_distance() * _get_preferred_firing_distance()
		):
			_refresh_approach_destination()
			_is_approaching_attack_target = (
				global_position.distance_squared_to(_cached_approach_destination)
				> definition.arrival_tolerance * definition.arrival_tolerance
			)
		return true

	_is_approaching_attack_target = false
	velocity = Vector2.ZERO
	_move_with_separation(Vector2.ZERO)
	distance_to_target_squared = global_position.distance_squared_to(
		_attack_target.global_position
	)
	if distance_to_target_squared > attack_range_squared:
		_attack_cooldown_remaining = definition.attack_cooldown
		_is_approaching_attack_target = true
		return true

	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	if not is_zero_approx(_attack_cooldown_remaining):
		return true

	var target := _attack_target
	target.take_damage(definition.attack_damage)
	if not target.is_alive():
		clear_attack_target()
		return true
	_attack_cooldown_remaining = definition.attack_cooldown
	return true


func _update_navigation_attack_target_state(delta: float) -> bool:
	_update_target_indicator()
	var distance_to_target_squared := global_position.distance_squared_to(
		_attack_target.global_position
	)
	var attack_range_squared := definition.attack_range * definition.attack_range
	if distance_to_target_squared > attack_range_squared:
		_attack_cooldown_remaining = definition.attack_cooldown
		if _should_refresh_combat_navigation_route():
			_refresh_combat_navigation_route()

		if _navigation_state.is_combat_route():
			var route_completed := _move_toward_ground_route(delta)
			if (
				route_completed
				and has_valid_attack_target()
				and global_position.distance_squared_to(_attack_target.global_position)
				> attack_range_squared
			):
				_refresh_combat_navigation_route()
		else:
			velocity = Vector2.ZERO
		return true

	if _navigation_state.is_combat_route():
		_clear_ground_route()
	velocity = Vector2.ZERO
	_move_with_separation(Vector2.ZERO)
	distance_to_target_squared = global_position.distance_squared_to(
		_attack_target.global_position
	)
	if distance_to_target_squared > attack_range_squared:
		_attack_cooldown_remaining = definition.attack_cooldown
		return true

	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	if not is_zero_approx(_attack_cooldown_remaining):
		return true

	var target := _attack_target
	target.take_damage(definition.attack_damage)
	if not target.is_alive():
		clear_attack_target()
		return true
	_attack_cooldown_remaining = definition.attack_cooldown
	return true


func _should_refresh_combat_navigation_route() -> bool:
	if not _has_combat_navigation_request:
		return true

	var slot_state := _get_attack_slot_state()
	if should_refresh_combat_navigation_route(
		_cached_target_position,
		_attack_target.global_position,
		Vector2i(_cached_attack_slot_index, _cached_attack_slot_count),
		slot_state
	):
		return true

	if (
		not _combat_resolved_firing_position.is_zero_approx()
		and not _combat_navigation_map.is_cell_navigable(
			_combat_navigation_map.world_to_grid(_combat_resolved_firing_position)
		)
	):
		return true

	if (
		_navigation_state.is_combat_route()
		and _navigation_state.has_current_waypoint()
		and not _combat_navigation_map.is_world_segment_navigable(
			global_position,
			_navigation_state.get_current_waypoint()
		)
	):
		return true

	return false


func _refresh_combat_navigation_route(
	preserve_recovery_state: bool = false
) -> bool:
	if _combat_navigation_map == null or not has_valid_attack_target():
		return false

	var slot_state := _get_attack_slot_state()
	var slot_angle := calculate_attack_slot_angle(slot_state.x, slot_state.y)
	var result := _combat_navigation_map.request_firing_position(
		global_position,
		_attack_target,
		definition.attack_range,
		_get_preferred_firing_distance(),
		slot_angle
	)
	_has_combat_navigation_request = true
	_cached_target_position = _attack_target.global_position
	_cached_attack_slot_index = slot_state.x
	_cached_attack_slot_count = slot_state.y
	_combat_desired_firing_position = result.desired_firing_position
	_combat_resolved_firing_position = result.accepted_destination
	_combat_used_alternate_firing_position = (
		result.status == NavigationPathResult.Status.ALTERNATE_FIRING_POSITION
	)

	if not result.is_success():
		_clear_ground_route()
		_combat_navigation_failed = true
		_combat_navigation_failure_status = result.status
		velocity = Vector2.ZERO
		print(
			"Combat navigation rejected for %s at %s targeting %s: %s."
			% [name, get_path(), _attack_target.get_path(), result.get_reason_text()]
		)
		queue_redraw()
		return false

	_combat_navigation_failed = false
	_combat_navigation_failure_status = NavigationPathResult.Status.NONE
	_navigation_state.set_accepted_destination(result.accepted_destination)
	_assign_navigation_route(
		result.path,
		result.raw_path,
		_combat_navigation_map.get_map_bounds(),
		true,
		_combat_navigation_map,
		-1,
		0,
		-1,
		Vector2.ZERO,
		0,
		preserve_recovery_state
	)
	print(
		(
			"Combat navigation route for %s at %s: %s, raw %d waypoints, "
			+ "simplified %d waypoints."
		)
		% [
			name,
			get_path(),
			result.get_reason_text(),
			result.raw_path.size(),
			result.path.size(),
		]
	)
	return true


func _get_preferred_firing_distance() -> float:
	return calculate_preferred_firing_distance(definition.attack_range)


func _update_approach_destination_if_needed() -> void:
	var slot_state := _get_attack_slot_state()
	if not _has_cached_approach_destination:
		_refresh_approach_destination(slot_state)
		return

	if (
		has_target_moved_for_approach(
			_cached_target_position,
			_attack_target.global_position
		)
		or _cached_attack_slot_index != slot_state.x
		or _cached_attack_slot_count != slot_state.y
	):
		_refresh_approach_destination(slot_state)


func _refresh_approach_destination(slot_state: Vector2i = Vector2i(-1, 0)) -> void:
	if slot_state.x < 0 or slot_state.y <= 0:
		slot_state = _get_attack_slot_state()

	_cached_target_position = _attack_target.global_position
	_cached_attack_slot_index = slot_state.x
	_cached_attack_slot_count = slot_state.y
	var slot_angle := calculate_attack_slot_angle(slot_state.x, slot_state.y)
	var direction_from_target := Vector2.RIGHT.rotated(slot_angle)

	_cached_approach_destination = _clamp_to_map_bounds(
		_cached_target_position + direction_from_target * _get_preferred_firing_distance()
	)
	_has_cached_approach_destination = true


func _get_attack_slot_state() -> Vector2i:
	var attackers: Array[TestUnit] = []
	for node: Node in get_tree().get_nodes_in_group(&"test_units"):
		var candidate := node as TestUnit
		if (
			candidate != null
			and is_instance_valid(candidate)
			and candidate.is_inside_tree()
			and candidate.is_alive()
			and candidate.team_id == team_id
			and candidate.has_valid_attack_target()
			and candidate.get_attack_target() == _attack_target
		):
			attackers.append(candidate)
	attackers.sort_custom(_unit_path_precedes)

	var slot_index := attackers.find(self)
	if slot_index < 0:
		return Vector2i(0, 1)
	return Vector2i(slot_index, attackers.size())


func _move_toward_approach_destination(delta: float) -> bool:
	var offset_to_destination := _cached_approach_destination - global_position
	var distance_to_destination := offset_to_destination.length()
	var maximum_step := definition.movement_speed * delta

	if (
		distance_to_destination <= definition.arrival_tolerance
		or distance_to_destination <= maximum_step
	):
		global_position = _clamp_to_map_bounds(_cached_approach_destination)
		velocity = Vector2.ZERO
		_is_approaching_attack_target = false
		return true

	_move_with_separation(offset_to_destination / distance_to_destination)
	return false


func _move_toward_ground_target(delta: float) -> void:
	var offset_to_target := _movement_target - global_position
	var distance_to_target := offset_to_target.length()
	var maximum_step := definition.movement_speed * delta

	if (
		distance_to_target <= definition.arrival_tolerance
		or distance_to_target <= maximum_step
	):
		global_position = _clamp_to_map_bounds(_movement_target)
		velocity = Vector2.ZERO
		_has_movement_target = false
		return

	_move_with_separation(offset_to_target / distance_to_target)


func _move_toward_ground_route(delta: float) -> bool:
	if not _navigation_state.has_active_route():
		_clear_ground_route()
		return true

	var advanced_waypoint := false
	while _navigation_state.has_current_waypoint():
		if (
			global_position.distance_to(_navigation_state.get_current_waypoint())
			> definition.arrival_tolerance
		):
			break
		if _should_wait_at_navigation_chokepoint():
			_navigation_state.set_waiting_at_chokepoint(true)
			velocity = Vector2.ZERO
			var navigation_map := _navigation_state.get_navigation_map()
			if not navigation_map.can_unit_enter_chokepoint(
				self,
				_navigation_state.get_chokepoint_id()
			):
				_navigation_state.pause_recovery(global_position, 0.0)
				queue_redraw()
				return false
			_navigation_state.set_waiting_at_chokepoint(false)
			_navigation_state.grant_chokepoint_entry()
		_navigation_state.advance_waypoint()
		advanced_waypoint = true

	if _navigation_state.is_route_complete():
		global_position = _clamp_to_map_bounds(
			_navigation_state.get_accepted_destination()
		)
		velocity = Vector2.ZERO
		_clear_ground_route()
		return true

	var waypoint := _navigation_state.get_current_waypoint()
	var offset_to_waypoint := waypoint - global_position
	var distance_to_waypoint := offset_to_waypoint.length()
	var maximum_step := definition.movement_speed * delta
	if advanced_waypoint:
		_navigation_state.restart_recovery_observation(
			global_position,
			distance_to_waypoint
		)

	if distance_to_waypoint <= maximum_step:
		global_position = _clamp_to_map_bounds(waypoint)
		velocity = Vector2.ZERO
		_navigation_state.advance_waypoint()
		if _navigation_state.is_route_complete():
			global_position = _clamp_to_map_bounds(
				_navigation_state.get_accepted_destination()
			)
			_clear_ground_route()
		else:
			_navigation_state.restart_recovery_observation(
				global_position,
				global_position.distance_to(_navigation_state.get_current_waypoint())
			)
			queue_redraw()
		return _navigation_state.is_route_complete()

	if _handle_navigation_recovery(delta, distance_to_waypoint):
		return false

	var waypoint_speed := minf(
		definition.movement_speed,
		distance_to_waypoint / maxf(delta, 0.000001)
	)
	_move_with_separation(offset_to_waypoint / distance_to_waypoint, waypoint_speed)
	queue_redraw()
	return false


func _handle_navigation_recovery(
	delta: float,
	distance_to_waypoint: float
) -> bool:
	var action := _navigation_state.observe_recovery(
		delta,
		global_position,
		distance_to_waypoint
	)
	if action == NavigationRecoveryTracker.Action.NONE:
		return false

	velocity = Vector2.ZERO
	queue_redraw()
	print(
		"Navigation recovery for %s at %s: %s (event %d, replan %d/%d)."
		% [
			name,
			get_path(),
			NavigationRecoveryTracker.get_action_text(action),
			_navigation_state.get_recovery_events(),
			_navigation_state.get_replan_attempts(),
			UnitNavigationState.MAXIMUM_REPLAN_ATTEMPTS,
		]
	)
	match action:
		NavigationRecoveryTracker.Action.REFRESH_LOCAL_STATE:
			return true
		NavigationRecoveryTracker.Action.RECALCULATE_ROUTE:
			_attempt_navigation_replan()
			return true
		NavigationRecoveryTracker.Action.FAIL_ROUTE:
			_fail_stuck_navigation()
			return true
		_:
			return false


func _attempt_navigation_replan() -> bool:
	var navigation_map := _navigation_state.get_navigation_map()
	if navigation_map == null:
		return false
	if _navigation_state.is_combat_route():
		return _refresh_combat_navigation_route(true)

	var command_sequence := _navigation_state.get_command_sequence()
	var priority := _navigation_state.get_priority()
	var destination := _navigation_state.get_accepted_destination()
	var result := navigation_map.request_navigation(global_position, destination)
	if not result.is_success():
		return false
	if result.path.is_empty():
		global_position = _clamp_to_map_bounds(result.accepted_destination)
		velocity = Vector2.ZERO
		_clear_ground_route()
		return true

	_assign_navigation_route(
		result.path,
		result.raw_path,
		navigation_map.get_map_bounds(),
		false,
		navigation_map,
		command_sequence,
		priority,
		result.chokepoint_id,
		result.chokepoint_holding_point,
		result.chokepoint_entry_side,
		true
	)
	_navigation_state.set_accepted_destination(result.accepted_destination)
	return true


func _fail_stuck_navigation() -> void:
	var navigation_map := _navigation_state.get_navigation_map()
	var was_combat_route := _navigation_state.is_combat_route()
	var result := NavigationPathResult.new()
	result.status = NavigationPathResult.Status.STUCK_RECOVERY_EXHAUSTED
	result.requested_start = global_position
	result.requested_destination = (
		_combat_desired_firing_position
		if was_combat_route
		else _navigation_state.get_last_requested_destination()
	)
	result.accepted_destination = _navigation_state.get_accepted_destination()

	velocity = Vector2.ZERO
	_clear_ground_route(false)
	_navigation_state.mark_recovery_failed()
	_navigation_state.record_failure(result.status, result.requested_destination)
	if was_combat_route:
		_combat_navigation_failed = true
		_combat_navigation_failure_status = result.status
		_has_combat_navigation_request = true
	if navigation_map != null:
		navigation_map.show_navigation_failure(result)
	queue_redraw()


func _should_wait_at_navigation_chokepoint() -> bool:
	return (
		_navigation_state.get_navigation_map() != null
		and _navigation_state.get_chokepoint_id() >= 0
		and not _navigation_state.is_chokepoint_entry_granted()
		and _navigation_state.has_current_waypoint()
		and _navigation_state.get_current_waypoint().is_equal_approx(
			_navigation_state.get_chokepoint_holding_point()
		)
	)


func _clear_ground_route(reset_recovery_state: bool = true) -> void:
	_navigation_state.clear_route(reset_recovery_state)
	queue_redraw()


func _move_with_separation(
	command_direction: Vector2,
	maximum_speed: float = -1.0
) -> bool:
	var separation := _calculate_friendly_separation()
	var movement_direction := Vector2.ZERO
	var movement_speed_scale := 1.0

	if not command_direction.is_zero_approx():
		movement_direction = (command_direction.normalized() + separation).normalized()
	elif not separation.is_zero_approx():
		movement_direction = separation.normalized()
		movement_speed_scale = separation.length()
	else:
		velocity = Vector2.ZERO
		return false

	var movement_speed := (
		definition.movement_speed
		if maximum_speed < 0.0
		else minf(maximum_speed, definition.movement_speed)
	)
	velocity = movement_direction * movement_speed * movement_speed_scale
	var movement_start := global_position
	var navigation_map := _navigation_state.get_navigation_map()
	if _navigation_state.has_active_route() and navigation_map != null:
		var physics_delta := get_physics_process_delta_time()
		if physics_delta > 0.0:
			var separated_endpoint := _clamp_to_map_bounds(
				movement_start + velocity * physics_delta
			)
			var command_endpoint := movement_start
			if not command_direction.is_zero_approx():
				command_endpoint = _clamp_to_map_bounds(
					movement_start
					+ command_direction.normalized() * movement_speed * physics_delta
				)
			var safe_endpoint := choose_navigation_safe_endpoint(
				navigation_map,
				movement_start,
				separated_endpoint,
				command_endpoint
			)
			if safe_endpoint.is_equal_approx(movement_start):
				velocity = Vector2.ZERO
				return false
			velocity = (safe_endpoint - movement_start) / physics_delta
	move_and_slide()
	global_position = _clamp_to_map_bounds(global_position)
	if (
		_navigation_state.has_active_route()
		and navigation_map != null
		and not navigation_map.is_world_segment_navigable(
			movement_start,
			global_position
		)
	):
		global_position = movement_start
		velocity = Vector2.ZERO
		return false
	return true


func _calculate_friendly_separation() -> Vector2:
	var own_radius := _get_separation_radius()
	if own_radius <= 0.0:
		return Vector2.ZERO

	var friendly_units: Array[TestUnit] = []
	for node: Node in get_tree().get_nodes_in_group(&"test_units"):
		if (
			node is TestUnit
			and node != self
			and is_instance_valid(node)
			and node.is_inside_tree()
			and node.is_alive()
			and node.team_id == team_id
		):
			friendly_units.append(node)
	friendly_units.sort_custom(_unit_path_precedes)

	var separation := Vector2.ZERO
	for friendly_unit in friendly_units:
		var preferred_spacing := own_radius + friendly_unit._get_separation_radius()
		if preferred_spacing <= 0.0:
			continue

		var offset_from_neighbor := global_position - friendly_unit.global_position
		var distance_squared := offset_from_neighbor.length_squared()
		var minimum_active_distance := maxf(
			preferred_spacing - SEPARATION_DEAD_ZONE,
			0.0
		)
		if distance_squared >= minimum_active_distance * minimum_active_distance:
			continue

		var direction_from_neighbor: Vector2
		var distance_to_neighbor: float
		if is_zero_approx(distance_squared):
			direction_from_neighbor = _get_coincident_separation_direction(friendly_unit)
			distance_to_neighbor = 0.0
		else:
			distance_to_neighbor = sqrt(distance_squared)
			direction_from_neighbor = offset_from_neighbor / distance_to_neighbor

		var spacing_deficit := preferred_spacing - distance_to_neighbor
		if spacing_deficit <= SEPARATION_DEAD_ZONE:
			continue
		separation += direction_from_neighbor * spacing_deficit / preferred_spacing

	return separation.limit_length(MAX_SEPARATION_CONTRIBUTION)


func _get_separation_radius() -> float:
	var footprint_half_extents := _get_footprint_half_extents()
	return maxf(footprint_half_extents.x, footprint_half_extents.y)


func _get_coincident_separation_direction(other: TestUnit) -> Vector2:
	var path_comparison := String(get_path()).naturalnocasecmp_to(String(other.get_path()))
	return Vector2.LEFT if path_comparison < 0 else Vector2.RIGHT


func _unit_path_precedes(first: TestUnit, second: TestUnit) -> bool:
	return (
		String(first.get_path()).naturalnocasecmp_to(String(second.get_path()))
		< 0
	)


func _set_map_bounds(map_bounds: Rect2) -> void:
	_has_map_bounds = map_bounds.size.x > 0.0 and map_bounds.size.y > 0.0
	_map_bounds = map_bounds if _has_map_bounds else Rect2()


func _clamp_to_map_bounds(world_position: Vector2) -> Vector2:
	if not _has_map_bounds:
		return world_position

	var footprint_half_extents := _get_footprint_half_extents()
	var minimum_position := _map_bounds.position + footprint_half_extents
	var maximum_position := _map_bounds.end - footprint_half_extents
	return Vector2(
		_clamp_axis(world_position.x, minimum_position.x, maximum_position.x),
		_clamp_axis(world_position.y, minimum_position.y, maximum_position.y)
	)


func _get_footprint_half_extents() -> Vector2:
	if collision_shape == null:
		_report_footprint_fallback("CollisionShape2D is missing")
		return Vector2.ZERO
	if collision_shape.shape == null:
		_report_footprint_fallback("CollisionShape2D has no assigned shape")
		return Vector2.ZERO

	if (
		collision_shape.shape is RectangleShape2D
		or collision_shape.shape is CircleShape2D
	):
		return calculate_footprint_half_extents(
			collision_shape.shape,
			collision_shape.scale
		)

	_report_footprint_fallback(
		"CollisionShape2D uses unsupported shape type %s"
		% collision_shape.shape.get_class()
	)
	return Vector2.ZERO


func _report_footprint_fallback(reason: String) -> void:
	if _footprint_warning_reported:
		return

	_footprint_warning_reported = true
	push_warning(
		(
			"%s at %s cannot derive a movement footprint because %s; "
			+ "using center-only map clamping and no separation radius."
		)
		% [name, get_path(), reason]
	)


static func calculate_preferred_firing_distance(attack_range: float) -> float:
	return maxf(attack_range - ATTACK_APPROACH_MARGIN, 0.0)


static func has_target_moved_for_approach(
	cached_position: Vector2,
	current_position: Vector2
) -> bool:
	return (
		cached_position.distance_squared_to(current_position)
		>= APPROACH_TARGET_REFRESH_DISTANCE_SQUARED
	)


static func should_refresh_combat_navigation_route(
	cached_target_position: Vector2,
	current_target_position: Vector2,
	cached_slot_state: Vector2i,
	current_slot_state: Vector2i
) -> bool:
	return (
		has_target_moved_for_approach(
			cached_target_position,
			current_target_position
		)
		or cached_slot_state != current_slot_state
	)


static func calculate_attack_slot_angle(slot_index: int, slot_count: int) -> float:
	if slot_index < 0 or slot_count <= 0 or slot_index >= slot_count:
		return 0.0
	return TAU * float(slot_index) / float(slot_count)


static func calculate_footprint_half_extents(
	shape: Shape2D,
	shape_scale: Vector2 = Vector2.ONE
) -> Vector2:
	if shape == null:
		return Vector2.ZERO

	var absolute_scale := shape_scale.abs()
	if shape is RectangleShape2D:
		var rectangle_shape := shape as RectangleShape2D
		return rectangle_shape.size * 0.5 * absolute_scale
	if shape is CircleShape2D:
		var circle_shape := shape as CircleShape2D
		return Vector2.ONE * circle_shape.radius * absolute_scale
	return Vector2.ZERO


static func choose_navigation_safe_endpoint(
	navigation_map: NavigationTestMap,
	start_position: Vector2,
	separated_endpoint: Vector2,
	command_endpoint: Vector2
) -> Vector2:
	if navigation_map == null:
		return separated_endpoint
	if navigation_map.is_world_segment_navigable(
		start_position,
		separated_endpoint
	):
		return separated_endpoint
	if navigation_map.is_world_segment_navigable(
		start_position,
		command_endpoint
	):
		return command_endpoint
	return start_position


func get_footprint_half_extents() -> Vector2:
	return _get_footprint_half_extents()


func _draw() -> void:
	if not _is_selected:
		return

	if _navigation_state.has_active_route():
		var route_waypoints := _navigation_state.get_waypoints()
		var raw_route_waypoints := _navigation_state.get_raw_waypoints()
		var route_waypoint_index := _navigation_state.get_waypoint_index()
		if not raw_route_waypoints.is_empty():
			var raw_local_path := PackedVector2Array(
				[to_local(_navigation_state.get_route_start())]
			)
			for raw_waypoint in raw_route_waypoints:
				raw_local_path.append(to_local(raw_waypoint))
			if raw_local_path.size() >= 2:
				var raw_color := (
					Color(0.85, 0.3, 0.55, 0.65)
					if _navigation_state.is_combat_route()
					else Color(0.45, 0.52, 0.58, 0.7)
				)
				draw_polyline(raw_local_path, raw_color, 1.0)

		var local_path := PackedVector2Array([Vector2.ZERO])
		for index in range(route_waypoint_index, route_waypoints.size()):
			local_path.append(to_local(route_waypoints[index]))

		if local_path.size() >= 2:
			var route_color := (
				Color("ff5fa2")
				if _navigation_state.is_combat_route()
				else Color("35d9ff")
			)
			draw_polyline(local_path, route_color, 3.0)

		var active_waypoint := to_local(route_waypoints[route_waypoint_index])
		var final_destination := to_local(route_waypoints[route_waypoints.size() - 1])
		draw_circle(active_waypoint, 7.0, Color("ff9f43"))
		draw_circle(final_destination, 10.0, Color("9b6cff"), false, 3.0)
		if _navigation_state.get_chokepoint_id() >= 0:
			var holding_point := to_local(
				_navigation_state.get_chokepoint_holding_point()
			)
			var holding_color := (
				Color("ffcf4d")
				if _navigation_state.is_waiting_at_chokepoint()
				else Color("8ad8ff")
			)
			draw_rect(
				Rect2(holding_point - Vector2.ONE * 6.0, Vector2.ONE * 12.0),
				holding_color,
				false,
				2.0
			)

	var recovery_events := _navigation_state.get_recovery_events()
	if recovery_events > 0:
		var recovery_color := (
			Color("ff4d5e")
			if _navigation_state.has_recovery_failure()
			else Color("ff9f43")
		)
		var visible_events := mini(recovery_events, 4)
		for event_index in range(visible_events):
			draw_circle(
				Vector2(-9.0 + float(event_index) * 6.0, -50.0),
				2.5,
				recovery_color
			)

	if (
		_combat_navigation_map != null
		and _has_combat_navigation_request
		and has_valid_attack_target()
	):
		var desired_position := to_local(_combat_desired_firing_position)
		var resolved_position := to_local(_combat_resolved_firing_position)
		draw_circle(desired_position, 9.0, Color("4dd8ff"), false, 2.0)
		if not _combat_resolved_firing_position.is_zero_approx():
			var resolved_color := (
				Color("ffcf4d")
				if _combat_used_alternate_firing_position
				else Color("72f1a4")
			)
			draw_rect(
				Rect2(resolved_position - Vector2.ONE * 7.0, Vector2.ONE * 14.0),
				resolved_color,
				false,
				2.0
			)
		if _combat_navigation_failed:
			draw_line(
				desired_position - Vector2(10.0, 10.0),
				desired_position + Vector2(10.0, 10.0),
				Color("ff3b6b"),
				3.0
			)
			draw_line(
				desired_position + Vector2(10.0, -10.0),
				desired_position + Vector2(-10.0, 10.0),
				Color("ff3b6b"),
				3.0
			)

	if _navigation_state.was_last_destination_projected():
		var raw_click := to_local(_navigation_state.get_last_requested_destination())
		var accepted_destination := to_local(
			_navigation_state.get_accepted_destination()
		)
		draw_dashed_line(raw_click, accepted_destination, Color("f7d154"), 2.0, 6.0)
		draw_circle(raw_click, 7.0, Color("f7d154"), false, 2.0)
		draw_circle(accepted_destination, 7.0, Color("56e39f"), false, 2.0)


func _clamp_axis(value: float, minimum: float, maximum: float) -> float:
	if minimum > maximum:
		return (minimum + maximum) * 0.5
	return clampf(value, minimum, maximum)


func _update_target_indicator() -> void:
	if not _is_selected or not has_valid_attack_target():
		target_indicator.visible = false
		target_indicator.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
		return

	target_indicator.points = PackedVector2Array(
		[Vector2.ZERO, to_local(_attack_target.global_position)]
	)
	target_indicator.visible = true


func _show_hit_feedback() -> void:
	_hit_feedback_remaining = HIT_FEEDBACK_DURATION
	hit_indicator.visible = true


func _die() -> void:
	if not _is_alive:
		return

	_is_alive = false
	_is_selected = false
	selection_indicator.visible = false
	_clear_ground_route()
	_has_movement_target = false
	_movement_target = Vector2.ZERO
	clear_attack_target()
	_hit_feedback_remaining = 0.0
	hit_indicator.visible = false
	velocity = Vector2.ZERO
	remove_from_group(&"selectable_units")
	remove_from_group(&"test_units")
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	queue_free()
