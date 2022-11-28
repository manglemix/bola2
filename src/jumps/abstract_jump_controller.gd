class_name AbstractJumpController
extends Node


# warning-ignore:unused_signal
signal set_velocity(new_velocity)
# warning-ignore:unused_signal
signal add_velocity(additional_velocity)


func try_jump(_direction: float, _current_velocity: Vector2) -> void:
	print_debug("Abstract method try_jump needs to be implemented before it can be called")


func end_jump() -> void:
	print_debug("Abstract method end_jump needs to be implemented before it can be called")


func _on_collision(_floor_angle: float) -> void:
	print_debug("Abstract method end_jump needs to be implemented before it can be called")
