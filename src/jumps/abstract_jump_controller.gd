class_name AbstractJumpController
extends Node


# warning-ignore:unused_signal
signal set_velocity(new_velocity)
# warning-ignore:unused_signal
signal add_velocity(additional_velocity)
# warning-ignore:unused_signal
signal jump_ended


var trying_to_jump := false setget set_trying_to_jump
var direction := 0.0
var current_velocity: Vector2


func set_current_velocity(value: Vector2) -> void:
	current_velocity = value


func set_trying_to_jump(value: bool) -> void:
	trying_to_jump = value


func set_direction(value: float) -> void:
	direction = value


func _on_collision(_floor_angle: float) -> void:
	print_debug("Abstract method end_jump needs to be implemented before it can be called")
