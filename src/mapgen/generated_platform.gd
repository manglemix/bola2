class_name GeneratedPlatform
extends Reference


enum PlatformType {
	NORMAL,
	FRAGILE,
	ROTATABLE,
	BOUNCY
}

var start_origin: Vector2
var end_origin: Vector2
var platform_type: int
var thickness: int


func _init(_start_origin: Vector2, _end_origin: Vector2, _platform_type: int, _thickness: int):
	start_origin = _start_origin
	end_origin = _end_origin
	platform_type = _platform_type
	thickness = _thickness
