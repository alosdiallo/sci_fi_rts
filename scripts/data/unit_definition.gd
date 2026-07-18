class_name UnitDefinition
extends Resource

@export var unit_id: StringName
@export var display_name: String
@export var movement_speed: float
@export var arrival_tolerance: float
@export var max_health: float
@export var attack_damage: float
@export var attack_range: float
@export var attack_cooldown: float


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()

	if String(unit_id).strip_edges().is_empty():
		errors.append("unit_id must not be blank.")
	if display_name.strip_edges().is_empty():
		errors.append("display_name must not be blank.")
	if not is_finite(movement_speed) or movement_speed <= 0.0:
		errors.append("movement_speed must be finite and greater than zero.")
	if not is_finite(arrival_tolerance) or arrival_tolerance < 0.0:
		errors.append("arrival_tolerance must be finite and zero or greater.")
	if not is_finite(max_health) or max_health <= 0.0:
		errors.append("max_health must be finite and greater than zero.")
	if not is_finite(attack_damage) or attack_damage <= 0.0:
		errors.append("attack_damage must be finite and greater than zero.")
	if not is_finite(attack_range) or attack_range <= 0.0:
		errors.append("attack_range must be finite and greater than zero.")
	if not is_finite(attack_cooldown) or attack_cooldown <= 0.0:
		errors.append("attack_cooldown must be finite and greater than zero.")

	return errors
