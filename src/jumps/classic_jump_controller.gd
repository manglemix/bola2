class_name ClassicJumpController
extends AbstractJumpController


signal jump_status_changed(current_jumps, used_fraction)
signal reset

export var max_jumps := 2
export var max_floor_angle_degrees := 60.0
export var initial_jump_velocity := 500.0
export var jump_acceleration := 250.0
export var jump_duration := 0.75

var _jumping := false
var _jump_timer := 0.0

onready var _current_jumps := max_jumps


func set_trying_to_jump(value: bool) -> void:
	if value == trying_to_jump:
		return
	
	.set_trying_to_jump(value)
	
	if value:
		if _current_jumps <= 0:
			return
		
		var jump_vector := Vector2.RIGHT.rotated(direction)
		_current_jumps -= 1
		set_process(true)
		_jump_timer = jump_duration
		_jumping = true
		var current_velocity_dot = current_velocity.dot(jump_vector)

		if current_velocity_dot > 0:
			current_velocity = current_velocity.project(jump_vector)
		
		else:
			current_velocity = Vector2.ZERO 
		
		emit_signal("set_velocity", current_velocity + jump_vector * initial_jump_velocity)
		
	elif _jumping:
		_end_jump()


func _end_jump():
	_jumping = false
	set_process(false)
	emit_signal("jump_ended")


func _on_collision(floor_angle: float):
	if floor_angle <= deg2rad(max_floor_angle_degrees):
		emit_signal("reset")
		_current_jumps = max_jumps


func _ready():
	set_process(false)


func _process(delta):
	emit_signal("jump_status_changed", _current_jumps, _jump_timer / jump_duration)
	emit_signal("add_velocity", Vector2.RIGHT.rotated(direction) * jump_acceleration * delta)
	_jump_timer -= delta

	if _jump_timer <= 0:
		_end_jump()
