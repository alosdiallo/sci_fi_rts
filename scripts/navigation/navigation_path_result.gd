class_name NavigationPathResult
extends RefCounted

enum Status {
	NONE,
	DIRECT,
	PROJECTED,
	NO_VALID_DESTINATION,
	NO_PATH,
	INVALID_START,
	PREFERRED_FIRING_POSITION,
	ALTERNATE_FIRING_POSITION,
	NO_FIRING_POSITION,
	INVALID_TARGET,
}

var status: Status = Status.NONE
var requested_start := Vector2.ZERO
var requested_destination := Vector2.ZERO
var accepted_destination := Vector2.ZERO
var desired_firing_position := Vector2.ZERO
var raw_path := PackedVector2Array()
var path := PackedVector2Array()


func is_success() -> bool:
	return (
		status == Status.DIRECT
		or status == Status.PROJECTED
		or status == Status.PREFERRED_FIRING_POSITION
		or status == Status.ALTERNATE_FIRING_POSITION
	)


func was_projected() -> bool:
	return status == Status.PROJECTED


func get_reason_text() -> String:
	match status:
		Status.DIRECT:
			return "destination accepted directly"
		Status.PROJECTED:
			return "destination projected to nearby navigable space"
		Status.NO_VALID_DESTINATION:
			return "no valid destination within the three-cell projection radius"
		Status.NO_PATH:
			return "no reachable path to the destination"
		Status.INVALID_START:
			return "start position is outside supported navigation space"
		Status.PREFERRED_FIRING_POSITION:
			return "preferred firing position accepted"
		Status.ALTERNATE_FIRING_POSITION:
			return "alternate firing position accepted"
		Status.NO_FIRING_POSITION:
			return "no reachable firing position"
		Status.INVALID_TARGET:
			return "combat target is invalid or dead"
		_:
			return "no navigation result"
