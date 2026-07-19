class_name NavigationPathResult
extends RefCounted

enum Status {
	NONE,
	DIRECT,
	PROJECTED,
	NO_VALID_DESTINATION,
	NO_PATH,
	INVALID_START,
}

var status: Status = Status.NONE
var requested_start := Vector2.ZERO
var requested_destination := Vector2.ZERO
var accepted_destination := Vector2.ZERO
var raw_path := PackedVector2Array()
var path := PackedVector2Array()


func is_success() -> bool:
	return status == Status.DIRECT or status == Status.PROJECTED


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
		_:
			return "no navigation result"
