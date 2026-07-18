class_name TestMap
extends Node2D

const MAP_BOUNDS := Rect2(0.0, 0.0, 2048.0, 2048.0)
const GRID_SPACING := 128
const BACKGROUND_COLOR := Color("3f4148")
const GRID_COLOR := Color("555862")
const BORDER_COLOR := Color("d5d8df")


func _draw() -> void:
	draw_rect(MAP_BOUNDS, BACKGROUND_COLOR)

	var x := int(MAP_BOUNDS.position.x) + GRID_SPACING
	while x < int(MAP_BOUNDS.end.x):
		draw_line(
			Vector2(x, MAP_BOUNDS.position.y),
			Vector2(x, MAP_BOUNDS.end.y),
			GRID_COLOR
		)
		x += GRID_SPACING

	var y := int(MAP_BOUNDS.position.y) + GRID_SPACING
	while y < int(MAP_BOUNDS.end.y):
		draw_line(
			Vector2(MAP_BOUNDS.position.x, y),
			Vector2(MAP_BOUNDS.end.x, y),
			GRID_COLOR
		)
		y += GRID_SPACING

	draw_rect(MAP_BOUNDS, BORDER_COLOR, false, 4.0)


func get_map_bounds() -> Rect2:
	return MAP_BOUNDS
