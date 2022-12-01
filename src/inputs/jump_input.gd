class_name JumpInput
extends AbstractJumpInput


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("jump"):
			_send_direction()

	if event.is_action_pressed("jump"):
		_send_direction()
		emit_signal("jump_started")
		
	elif event.is_action_released("jump"):
		emit_signal("jump_ended")


func _send_direction():
	emit_signal(
		"direction_changed",
		(get_global_mouse_position() - global_position).angle()
	)
