class_name JumpInput
extends AbstractJumpInput


func _input(event):
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("jump"):
			emit_signal(
				"jump_attempted",
				(get_global_mouse_position() - global_position).angle()
			)

	elif event.is_action_pressed("jump"):
		emit_signal(
			"jump_attempted",
			(get_global_mouse_position() - global_position).angle()
		)
		
	elif event.is_action_released("jump"):
		emit_signal("jump_ended")
