class_name TestUnit
extends CharacterBody2D

@onready var selection_indicator: Line2D = $SelectionIndicator


func _ready() -> void:
	selection_indicator.visible = false


func set_selected(is_selected: bool) -> void:
	selection_indicator.visible = is_selected
