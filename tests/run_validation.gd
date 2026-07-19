extends SceneTree

const STANDARD_DEFINITION_PATH := "res://data/units/test_unit_standard.tres"
const FAST_DEFINITION_PATH := "res://data/units/test_unit_fast.tres"
const TEST_UNIT_SCENE_PATH := "res://scenes/units/test_unit.tscn"

var _checks_passed := 0
var _failures: PackedStringArray = []


func _initialize() -> void:
	_run_validation.call_deferred()


func _run_validation() -> void:
	_check_unit_definition_validation()
	_check_pure_calculations()
	_check_footprint_calculations()
	_check_navigation_grid()
	_check_health_damage_hostility_and_targeting()

	if OS.get_cmdline_user_args().has("--force-failure"):
		_expect_true("runner forced-failure exit behavior", false, "forced failure requested")

	await process_frame
	_print_summary_and_exit()


func _check_unit_definition_validation() -> void:
	var standard_definition := load(STANDARD_DEFINITION_PATH) as UnitDefinition
	var fast_definition := load(FAST_DEFINITION_PATH) as UnitDefinition
	_expect_true(
		"standard resource loads and validates",
		standard_definition != null and standard_definition.get_validation_errors().is_empty(),
		"expected a valid UnitDefinition"
	)
	_expect_true(
		"fast resource loads and validates",
		fast_definition != null and fast_definition.get_validation_errors().is_empty(),
		"expected a valid UnitDefinition"
	)

	var valid_definition := _make_valid_definition()
	_expect_empty_errors("valid definition", valid_definition)

	var blank_id := _make_valid_definition()
	blank_id.unit_id = &"  "
	_expect_validation_error("blank unit_id", blank_id, "unit_id must not be blank.")

	var blank_name := _make_valid_definition()
	blank_name.display_name = "  "
	_expect_validation_error(
		"blank display_name",
		blank_name,
		"display_name must not be blank."
	)

	var zero_speed := _make_valid_definition()
	zero_speed.movement_speed = 0.0
	_expect_validation_error(
		"nonpositive movement_speed",
		zero_speed,
		"movement_speed must be finite and greater than zero."
	)

	var negative_tolerance := _make_valid_definition()
	negative_tolerance.arrival_tolerance = -1.0
	_expect_validation_error(
		"negative arrival_tolerance",
		negative_tolerance,
		"arrival_tolerance must be finite and zero or greater."
	)

	var zero_health := _make_valid_definition()
	zero_health.max_health = 0.0
	_expect_validation_error(
		"nonpositive max_health",
		zero_health,
		"max_health must be finite and greater than zero."
	)

	var zero_damage := _make_valid_definition()
	zero_damage.attack_damage = 0.0
	_expect_validation_error(
		"nonpositive attack_damage",
		zero_damage,
		"attack_damage must be finite and greater than zero."
	)

	var zero_range := _make_valid_definition()
	zero_range.attack_range = 0.0
	_expect_validation_error(
		"nonpositive attack_range",
		zero_range,
		"attack_range must be finite and greater than zero."
	)

	var zero_cooldown := _make_valid_definition()
	zero_cooldown.attack_cooldown = 0.0
	_expect_validation_error(
		"nonpositive attack_cooldown",
		zero_cooldown,
		"attack_cooldown must be finite and greater than zero."
	)

	var nan_speed := _make_valid_definition()
	nan_speed.movement_speed = NAN
	_expect_validation_error(
		"nonfinite movement_speed",
		nan_speed,
		"movement_speed must be finite and greater than zero."
	)

	var infinite_cooldown := _make_valid_definition()
	infinite_cooldown.attack_cooldown = INF
	_expect_validation_error(
		"nonfinite attack_cooldown",
		infinite_cooldown,
		"attack_cooldown must be finite and greater than zero."
	)


func _check_pure_calculations() -> void:
	_expect_float(
		"preferred firing distance keeps eight-pixel margin",
		TestUnit.calculate_preferred_firing_distance(220.0),
		212.0
	)
	_expect_float(
		"preferred firing distance clamps at zero",
		TestUnit.calculate_preferred_firing_distance(4.0),
		0.0
	)
	_expect_true(
		"target movement below eight pixels does not refresh",
		not TestUnit.has_target_moved_for_approach(Vector2.ZERO, Vector2(7.999, 0.0)),
		"movement below the threshold requested a refresh"
	)
	_expect_true(
		"target movement at eight pixels refreshes",
		TestUnit.has_target_moved_for_approach(Vector2.ZERO, Vector2(8.0, 0.0)),
		"movement at squared distance 64 did not request a refresh"
	)

	_expect_float("one-attacker slot angle", TestUnit.calculate_attack_slot_angle(0, 1), 0.0)
	_expect_float("two-attacker first slot", TestUnit.calculate_attack_slot_angle(0, 2), 0.0)
	_expect_float("two-attacker opposite slot", TestUnit.calculate_attack_slot_angle(1, 2), PI)
	for slot_index in range(3):
		_expect_float(
			"three-attacker slot %d" % slot_index,
			TestUnit.calculate_attack_slot_angle(slot_index, 3),
			TAU * float(slot_index) / 3.0
		)
	for slot_index in range(4):
		_expect_float(
			"four-attacker slot %d" % slot_index,
			TestUnit.calculate_attack_slot_angle(slot_index, 4),
			TAU * float(slot_index) / 4.0
		)


func _check_footprint_calculations() -> void:
	var unit_scene := load(TEST_UNIT_SCENE_PATH) as PackedScene
	var scene_unit := unit_scene.instantiate() as TestUnit if unit_scene != null else null
	var scene_collision_shape := (
		scene_unit.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if scene_unit != null
		else null
	)
	_expect_vector(
		"scene rectangle footprint half-extents",
		TestUnit.calculate_footprint_half_extents(
			scene_collision_shape.shape if scene_collision_shape != null else null
		),
		Vector2(24.0, 24.0)
	)
	if scene_unit != null:
		scene_unit.free()

	var circle := CircleShape2D.new()
	circle.radius = 12.0
	_expect_vector(
		"circle footprint half-extents",
		TestUnit.calculate_footprint_half_extents(circle, Vector2(2.0, 0.5)),
		Vector2(24.0, 6.0)
	)
	_expect_vector(
		"missing footprint shape fallback",
		TestUnit.calculate_footprint_half_extents(null),
		Vector2.ZERO
	)
	_expect_vector(
		"unsupported footprint shape fallback",
		TestUnit.calculate_footprint_half_extents(CapsuleShape2D.new()),
		Vector2.ZERO
	)


func _check_navigation_grid() -> void:
	var navigation_map := NavigationTestMap.new()
	navigation_map.name = "ValidationNavigationMap"
	root.add_child(navigation_map)

	_expect_vector2i(
		"navigation world-to-grid conversion",
		navigation_map.world_to_grid(Vector2(48.0, 80.0)),
		Vector2i(1, 2)
	)
	_expect_vector(
		"navigation grid-to-world conversion",
		navigation_map.grid_to_world(Vector2i(1, 2)),
		Vector2(48.0, 80.0)
	)

	var obstacle_center_cell := navigation_map.world_to_grid(
		NavigationTestMap.STATIC_OBSTACLE_BOUNDS.get_center()
	)
	_expect_true(
		"navigation static obstacle is blocked",
		not navigation_map.is_cell_navigable(obstacle_center_cell),
		"obstacle center cell was navigable"
	)

	var clearance_cell := navigation_map.world_to_grid(Vector2(816.0, 496.0))
	_expect_true(
		"navigation obstacle clearance is blocked",
		not NavigationTestMap.STATIC_OBSTACLE_BOUNDS.has_point(
			navigation_map.grid_to_world(clearance_cell)
		)
		and not navigation_map.is_cell_navigable(clearance_cell),
		"cell outside raw obstacle but inside footprint clearance was navigable"
	)

	var route_start := Vector2(320.0, 1024.0)
	var route_destination := Vector2(1728.0, 1024.0)
	var direct_result := navigation_map.request_navigation(route_start, route_destination)
	var cell_path := navigation_map.request_grid_path(route_start, route_destination)
	_expect_true(
		"navigation valid direct destination accepted",
		direct_result.status == NavigationPathResult.Status.DIRECT
		and direct_result.is_success()
		and not direct_result.path.is_empty(),
		"expected a direct success result with a detour path"
	)

	var path_uses_only_navigable_cells := true
	var path_respects_diagonal_corners := true
	for index in range(cell_path.size()):
		var cell := cell_path[index]
		if not navigation_map.is_cell_navigable(cell):
			path_uses_only_navigable_cells = false
		if index == 0:
			continue
		var previous_cell := cell_path[index - 1]
		var step := cell - previous_cell
		if abs(step.x) == 1 and abs(step.y) == 1:
			if (
				not navigation_map.is_cell_navigable(
					previous_cell + Vector2i(step.x, 0)
				)
				or not navigation_map.is_cell_navigable(
					previous_cell + Vector2i(0, step.y)
				)
			):
				path_respects_diagonal_corners = false

	_expect_true(
		"navigation path excludes blocked cells",
		path_uses_only_navigable_cells,
		"path crossed a blocked or clearance cell"
	)
	_expect_true(
		"navigation diagonal corner cutting is prohibited",
		path_respects_diagonal_corners,
		"diagonal step crossed a blocked orthogonal corner"
	)

	var near_obstacle_position := Vector2(832.0, 488.0)
	var projected_result := navigation_map.request_navigation(
		route_start,
		near_obstacle_position
	)
	var projected_cell := navigation_map.world_to_grid(
		projected_result.accepted_destination
	)
	var requested_cell := navigation_map.world_to_grid(near_obstacle_position)
	var projection_offset := projected_cell - requested_cell
	_expect_true(
		"navigation destination projects within three cells",
		projected_result.status == NavigationPathResult.Status.PROJECTED
		and navigation_map.is_cell_navigable(projected_cell)
		and maxi(abs(projection_offset.x), abs(projection_offset.y))
		<= NavigationTestMap.MAX_DESTINATION_PROJECTION_RADIUS,
		"near-obstacle destination did not resolve within the bounded radius"
	)
	_expect_vector2i(
		"navigation projection tie-breaking is stable",
		projected_cell,
		Vector2i(25, 14)
	)
	_expect_true(
		"navigation projected destination differs from raw click",
		not projected_result.accepted_destination.is_equal_approx(
			projected_result.requested_destination
		),
		"projected result implied that the raw blocked point was accepted"
	)

	var blocked_obstacle_position := NavigationTestMap.STATIC_OBSTACLE_BOUNDS.get_center()
	var blocked_result := navigation_map.request_navigation(
		route_start,
		blocked_obstacle_position
	)
	_expect_true(
		"navigation blocked destination beyond projection radius is rejected",
		blocked_result.status == NavigationPathResult.Status.NO_VALID_DESTINATION
		and not blocked_result.is_success(),
		"deep obstacle destination returned the wrong failure reason"
	)

	var enclosed_destination := Vector2(1440.0, 416.0)
	var enclosed_result := navigation_map.request_navigation(
		route_start,
		enclosed_destination
	)
	_expect_true(
		"navigation enclosed destination is locally valid",
		navigation_map.is_cell_navigable(
			navigation_map.world_to_grid(enclosed_destination)
		),
		"enclosed fixture destination was not a valid cell"
	)
	_expect_true(
		"navigation projection does not cross enclosing barrier",
		enclosed_result.status == NavigationPathResult.Status.NO_PATH
		and not enclosed_result.is_success(),
		"enclosed destination was accepted or projected through its walls"
	)
	_expect_true(
		"navigation valid but unreachable cell is rejected",
		enclosed_result.get_reason_text() == "no reachable path to the destination",
		"unreachable cell did not report the no-path reason"
	)

	var enclosed_blocked_result := navigation_map.request_navigation(
		route_start,
		Vector2(1440.0, 320.0)
	)
	_expect_true(
		"navigation projected candidates require start reachability",
		enclosed_blocked_result.status == NavigationPathResult.Status.NO_PATH
		and not enclosed_blocked_result.is_success(),
		"blocked enclosure wall projected through the enclosing barrier"
	)

	var invalid_start_result := navigation_map.request_navigation(
		Vector2(-32.0, 1024.0),
		route_destination
	)
	_expect_true(
		"navigation invalid start is rejected",
		invalid_start_result.status == NavigationPathResult.Status.INVALID_START
		and not invalid_start_result.is_success(),
		"invalid start returned the wrong result"
	)

	var same_cell_start := Vector2(320.0, 1024.0)
	var same_cell_destination := Vector2(328.0, 1030.0)
	var same_cell_result := navigation_map.request_navigation(
		same_cell_start,
		same_cell_destination
	)
	_expect_true(
		"navigation same-cell command completes without route",
		same_cell_result.status == NavigationPathResult.Status.DIRECT
		and same_cell_result.is_success()
		and same_cell_result.path.is_empty(),
		"same-cell command did not return an immediate successful result"
	)

	var edge_result := navigation_map.request_navigation(
		route_start,
		Vector2(1968.0, 1968.0)
	)
	_expect_true(
		"navigation footprint-valid map-edge destination succeeds",
		edge_result.is_success(),
		"valid near-edge destination was rejected"
	)

	var narrow_gap_cell := navigation_map.world_to_grid(Vector2(464.0, 1504.0))
	_expect_true(
		"navigation current footprint cannot enter narrow gap",
		not navigation_map.is_cell_navigable(narrow_gap_cell),
		"narrow fixture remained traversable for the current footprint"
	)

	var unit_scene := load(TEST_UNIT_SCENE_PATH) as PackedScene
	var route_unit := unit_scene.instantiate() as TestUnit if unit_scene != null else null
	if route_unit != null:
		route_unit.definition = load(STANDARD_DEFINITION_PATH) as UnitDefinition
		root.add_child(route_unit)
		route_unit.set_physics_process(false)
		route_unit.set_movement_route(
			direct_result.path,
			navigation_map.get_map_bounds(),
			route_destination,
			direct_result.accepted_destination,
			direct_result.status
		)
		var accepted_before_failure := route_unit.get_accepted_navigation_destination()
		route_unit.record_navigation_failure(
			blocked_result.status,
			blocked_obstacle_position
		)
		_expect_true(
			"navigation rejected command preserves prior route state",
			route_unit.is_ground_route_active()
			and route_unit.get_accepted_navigation_destination().is_equal_approx(
				accepted_before_failure
			)
			and route_unit.get_last_navigation_result()
			== NavigationPathResult.Status.NO_VALID_DESTINATION,
			"recording a rejected command mutated the active route"
		)
		route_unit.free()
	else:
		_expect_true(
			"navigation rejected command preserves prior route state",
			false,
			"could not instantiate TestUnit route fixture"
		)

	navigation_map.free()


func _check_health_damage_hostility_and_targeting() -> void:
	var standard_definition := load(STANDARD_DEFINITION_PATH) as UnitDefinition
	var attacker := _instantiate_unit("Attacker", standard_definition, 1)
	var friendly := _instantiate_unit("Friendly", standard_definition, 1)
	var hostile := _instantiate_unit("Hostile", standard_definition, 2)
	if attacker == null or friendly == null or hostile == null:
		_expect_true(
			"health and targeting fixtures instantiate",
			false,
			"one or more TestUnit fixtures could not be instantiated"
		)
		_free_if_valid(attacker)
		_free_if_valid(friendly)
		_free_if_valid(hostile)
		return

	_expect_float(
		"current health initializes to maximum",
		attacker.get_current_health(),
		standard_definition.max_health
	)
	_expect_float(
		"maximum health query",
		attacker.get_max_health(),
		standard_definition.max_health
	)
	_expect_true("unit starts alive", attacker.is_alive(), "unit did not initialize alive")

	attacker.take_damage(25.0)
	_expect_float("valid damage reduces health", attacker.get_current_health(), 75.0)
	_expect_true("unit remains alive above zero", attacker.is_alive(), "unit died early")

	var health_before_invalid_damage := attacker.get_current_health()
	var previous_print_error_messages := Engine.print_error_messages
	Engine.print_error_messages = false
	attacker.take_damage(0.0)
	attacker.take_damage(INF)
	Engine.print_error_messages = previous_print_error_messages
	_expect_float(
		"invalid damage preserves health",
		attacker.get_current_health(),
		health_before_invalid_damage
	)

	_expect_true(
		"same team is not hostile",
		not attacker.is_hostile_to(friendly),
		"same-team unit was considered hostile"
	)
	_expect_true(
		"different teams are hostile",
		attacker.is_hostile_to(hostile),
		"different-team living unit was not considered hostile"
	)

	attacker.set_attack_target(attacker)
	_expect_true(
		"unit cannot target itself",
		not attacker.has_valid_attack_target(),
		"self became a valid target"
	)
	attacker.set_attack_target(friendly)
	_expect_true(
		"unit cannot target friendly",
		not attacker.has_valid_attack_target(),
		"friendly unit became a valid target"
	)
	attacker.set_attack_target(hostile)
	_expect_true(
		"hostile living target can be assigned",
		attacker.has_valid_attack_target() and attacker.get_attack_target() == hostile,
		"hostile target assignment was not retained"
	)
	attacker.clear_attack_target()
	_expect_true(
		"clearing attack target removes it",
		not attacker.has_valid_attack_target() and attacker.get_attack_target() == null,
		"target remained valid after clearing"
	)

	attacker.take_damage(1000.0)
	_expect_float("lethal damage clamps health at zero", attacker.get_current_health(), 0.0)
	_expect_true("lethal damage marks unit dead", not attacker.is_alive(), "unit remained alive")
	_expect_true(
		"death queues unit exactly once",
		attacker.is_queued_for_deletion(),
		"dead unit was not queued for deletion"
	)
	previous_print_error_messages = Engine.print_error_messages
	Engine.print_error_messages = false
	attacker.take_damage(1000.0)
	Engine.print_error_messages = previous_print_error_messages
	_expect_float("repeated lethal damage preserves zero health", attacker.get_current_health(), 0.0)
	_expect_true(
		"repeated lethal damage preserves queued death",
		attacker.is_queued_for_deletion(),
		"repeated lethal damage changed queued-death state"
	)

	friendly.set_attack_target(hostile)
	_expect_true(
		"second attacker accepts living hostile target",
		friendly.has_valid_attack_target(),
		"living hostile target was rejected"
	)
	hostile.take_damage(1000.0)
	_expect_true(
		"dead target is invalid immediately",
		not friendly.has_valid_attack_target(),
		"dead target remained valid"
	)
	friendly.clear_attack_target()

	_free_if_valid(friendly)


func _make_valid_definition() -> UnitDefinition:
	var definition := UnitDefinition.new()
	definition.unit_id = &"validation_unit"
	definition.display_name = "Validation Unit"
	definition.movement_speed = 180.0
	definition.arrival_tolerance = 4.0
	definition.max_health = 100.0
	definition.attack_damage = 20.0
	definition.attack_range = 220.0
	definition.attack_cooldown = 1.0
	return definition


func _instantiate_unit(
	unit_name: String,
	unit_definition: UnitDefinition,
	unit_team_id: int
) -> TestUnit:
	var unit_scene := load(TEST_UNIT_SCENE_PATH) as PackedScene
	if unit_scene == null:
		return null
	var unit := unit_scene.instantiate() as TestUnit
	if unit == null:
		return null
	unit.name = unit_name
	unit.definition = unit_definition
	unit.team_id = unit_team_id
	root.add_child(unit)
	unit.set_physics_process(false)
	return unit


func _expect_empty_errors(check_name: String, definition: UnitDefinition) -> void:
	var errors := definition.get_validation_errors()
	_expect_true(check_name, errors.is_empty(), "unexpected errors: %s" % [errors])


func _expect_validation_error(
	check_name: String,
	definition: UnitDefinition,
	expected_error: String
) -> void:
	var errors := definition.get_validation_errors()
	_expect_true(
		check_name,
		errors.has(expected_error),
		"expected '%s', got %s" % [expected_error, errors]
	)


func _expect_float(
	check_name: String,
	actual: float,
	expected: float,
	tolerance: float = 0.0001
) -> void:
	_expect_true(
		check_name,
		is_equal_approx(actual, expected) or absf(actual - expected) <= tolerance,
		"expected %s, got %s" % [expected, actual]
	)


func _expect_vector(
	check_name: String,
	actual: Vector2,
	expected: Vector2,
	tolerance: float = 0.0001
) -> void:
	_expect_true(
		check_name,
		actual.is_equal_approx(expected) or actual.distance_to(expected) <= tolerance,
		"expected %s, got %s" % [expected, actual]
	)


func _expect_vector2i(
	check_name: String,
	actual: Vector2i,
	expected: Vector2i
) -> void:
	_expect_true(
		check_name,
		actual == expected,
		"expected %s, got %s" % [expected, actual]
	)


func _expect_true(check_name: String, condition: bool, reason: String) -> void:
	if condition:
		_checks_passed += 1
		return
	_failures.append("%s: %s" % [check_name, reason])


func _free_if_valid(node: Node) -> void:
	if is_instance_valid(node) and not node.is_queued_for_deletion():
		node.free()


func _print_summary_and_exit() -> void:
	print("Validation summary: %d passed, %d failed." % [_checks_passed, _failures.size()])
	for failure in _failures:
		print("FAIL: %s" % failure)
	quit(0 if _failures.is_empty() else 1)
