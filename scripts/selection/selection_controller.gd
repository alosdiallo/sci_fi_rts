class_name SelectionController
extends CanvasLayer

const DRAG_THRESHOLD := 8.0

@export var selection_rectangle: ColorRect

var _press_position := Vector2.ZERO
var _is_pointer_down := false
var _is_dragging := false


func _ready() -> void:
	_reset_selection_rectangle()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _is_pointer_down:
		_handle_mouse_motion(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		_press_position = event.position
		_is_pointer_down = true
		_is_dragging = false
		_reset_selection_rectangle()
	elif _is_pointer_down:
		if _press_position.distance_to(event.position) >= DRAG_THRESHOLD:
			_is_dragging = true
		if _is_dragging:
			_select_units_in_screen_rect(_normalized_screen_rect(_press_position, event.position))
		else:
			_select_unit_at_screen_position(event.position)
		_is_pointer_down = false
		_is_dragging = false
		_reset_selection_rectangle()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not _is_dragging and _press_position.distance_to(event.position) >= DRAG_THRESHOLD:
		_is_dragging = true

	if _is_dragging:
		var drag_rect := _normalized_screen_rect(_press_position, event.position)
		selection_rectangle.position = drag_rect.position
		selection_rectangle.size = drag_rect.size
		selection_rectangle.visible = true


func _select_unit_at_screen_position(screen_position: Vector2) -> void:
	var world_position := _screen_to_world(screen_position)
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var clicked_units: Array[TestUnit] = []
	var results := get_viewport().world_2d.direct_space_state.intersect_point(query)
	for result: Dictionary in results:
		var clicked_unit := result.get("collider") as TestUnit
		if clicked_unit != null:
			clicked_units.append(clicked_unit)
			break

	_apply_selection(clicked_units)


func _select_units_in_screen_rect(screen_rect: Rect2) -> void:
	var world_start := _screen_to_world(screen_rect.position)
	var world_end := _screen_to_world(screen_rect.end)
	var world_rect := _normalized_world_rect(world_start, world_end)
	var selected_units: Array[TestUnit] = []

	for unit in _get_selectable_units():
		if world_rect.has_point(unit.global_position):
			selected_units.append(unit)

	_apply_selection(selected_units)


func _apply_selection(selected_units: Array[TestUnit]) -> void:
	for unit in _get_selectable_units():
		unit.set_selected(selected_units.has(unit))


func _get_selectable_units() -> Array[TestUnit]:
	var selectable_units: Array[TestUnit] = []
	for node: Node in get_tree().get_nodes_in_group(&"selectable_units"):
		if node is TestUnit:
			selectable_units.append(node)
	return selectable_units


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func _normalized_screen_rect(start: Vector2, finish: Vector2) -> Rect2:
	return Rect2(start.min(finish), (finish - start).abs())


func _normalized_world_rect(start: Vector2, finish: Vector2) -> Rect2:
	return Rect2(start.min(finish), (finish - start).abs())


func _reset_selection_rectangle() -> void:
	selection_rectangle.position = Vector2.ZERO
	selection_rectangle.size = Vector2.ZERO
	selection_rectangle.visible = false
