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
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _is_selected := false
var _movement_target := Vector2.ZERO
var _has_movement_target := false
var _current_health := 0.0
var _is_alive := false
var _health_initialized := false
var _attack_target: TestUnit
var _is_approaching_attack_target := false
var _cached_target_position := Vector2.ZERO
var _cached_approach_destination := Vector2.ZERO
var _has_cached_approach_destination := false
var _map_bounds := Rect2()
var _has_map_bounds := false
var _attack_cooldown_remaining := 0.0
var _hit_feedback_remaining := 0.0


func _ready() -> void:
	selection_indicator.visible = false
	target_indicator.visible = false
	hit_indicator.visible = false
	health_bar.visible = false
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
	if not _has_movement_target:
		_move_with_separation(Vector2.ZERO)
		return

	_move_toward_ground_target(delta)


func set_selected(selected: bool) -> void:
	_is_selected = selected
	selection_indicator.visible = selected
	_update_target_indicator()


func is_selected() -> bool:
	return _is_selected


func set_movement_target(target: Vector2, map_bounds: Rect2 = Rect2()) -> void:
	clear_attack_target()
	_set_map_bounds(map_bounds)
	_movement_target = _clamp_to_map_bounds(target)
	_has_movement_target = true


func set_attack_target(target: TestUnit, map_bounds: Rect2 = Rect2()) -> void:
	if target == self or not is_hostile_to(target):
		return

	_set_map_bounds(map_bounds)
	_attack_target = target
	_attack_cooldown_remaining = definition.attack_cooldown
	_refresh_approach_destination()
	_is_approaching_attack_target = (
		global_position.distance_squared_to(target.global_position)
		> definition.attack_range * definition.attack_range
	)
	_has_movement_target = false
	_movement_target = Vector2.ZERO
	velocity = Vector2.ZERO
	_update_target_indicator()


func clear_attack_target() -> void:
	_attack_target = null
	_is_approaching_attack_target = false
	_cached_target_position = Vector2.ZERO
	_cached_approach_destination = Vector2.ZERO
	_has_cached_approach_destination = false
	_attack_cooldown_remaining = 0.0
	velocity = Vector2.ZERO
	_update_target_indicator()


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

	_update_target_indicator()
	var distance_to_target_squared := global_position.distance_squared_to(
		_attack_target.global_position
	)
	var attack_range_squared := definition.attack_range * definition.attack_range
	if distance_to_target_squared > attack_range_squared:
		_attack_cooldown_remaining = definition.attack_cooldown
		_update_approach_destination_if_needed()
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


func _get_preferred_firing_distance() -> float:
	return maxf(definition.attack_range - ATTACK_APPROACH_MARGIN, 0.0)


func _update_approach_destination_if_needed() -> void:
	if not _has_cached_approach_destination:
		_refresh_approach_destination()
		return

	if (
		_cached_target_position.distance_squared_to(_attack_target.global_position)
		>= APPROACH_TARGET_REFRESH_DISTANCE_SQUARED
	):
		_refresh_approach_destination()


func _refresh_approach_destination() -> void:
	_cached_target_position = _attack_target.global_position
	var target_to_attacker := global_position - _cached_target_position
	var direction_from_target := Vector2.RIGHT
	if not target_to_attacker.is_zero_approx():
		direction_from_target = target_to_attacker.normalized()

	_cached_approach_destination = _clamp_to_map_bounds(
		_cached_target_position + direction_from_target * _get_preferred_firing_distance()
	)
	_has_cached_approach_destination = true


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


func _move_with_separation(command_direction: Vector2) -> bool:
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

	velocity = movement_direction * definition.movement_speed * movement_speed_scale
	move_and_slide()
	global_position = _clamp_to_map_bounds(global_position)
	return true


func _calculate_friendly_separation() -> Vector2:
	var own_radius := _get_separation_radius()
	if own_radius <= 0.0:
		return Vector2.ZERO

	var friendly_units: Array[TestUnit] = []
	for node: Node in get_tree().get_nodes_in_group(&"selectable_units"):
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
	if collision_shape == null or collision_shape.shape == null:
		return Vector2.ZERO

	var shape_scale := collision_shape.scale.abs()
	if collision_shape.shape is RectangleShape2D:
		var rectangle_shape := collision_shape.shape as RectangleShape2D
		return rectangle_shape.size * 0.5 * shape_scale
	if collision_shape.shape is CircleShape2D:
		var circle_shape := collision_shape.shape as CircleShape2D
		return Vector2.ONE * circle_shape.radius * shape_scale

	return Vector2.ZERO


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
	_has_movement_target = false
	_movement_target = Vector2.ZERO
	clear_attack_target()
	_hit_feedback_remaining = 0.0
	hit_indicator.visible = false
	velocity = Vector2.ZERO
	remove_from_group(&"selectable_units")
	collision_shape.set_deferred("disabled", true)
	set_physics_process(false)
	queue_free()
