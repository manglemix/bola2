class_name ClassicJumpController
extends AbstractJumpController


export var max_jumps := 2
export var max_floor_angle_degrees := 60.0
export var initial_jump_velocity := 500.0
export var jump_acceleration := 250.0
export var jump_duration := 0.75

var _jumping := false
var _jump_vector: Vector2
var _jump_timer := 0.0

onready var _current_jumps := max_jumps


func try_jump(direction: float, current_velocity: Vector2):
	_jump_vector = Vector2.RIGHT.rotated(direction)

	if _jumping or _current_jumps <= 0:
		return
	
	_current_jumps -= 1
	set_process(true)
	_jump_timer = jump_duration
	_jumping = true
	var current_velocity_dot = current_velocity.dot(_jump_vector)

	if current_velocity_dot > 0:
		current_velocity = current_velocity.project(_jump_vector)

	else:
		current_velocity = Vector2.ZERO 

	emit_signal("set_velocity", current_velocity + _jump_vector * initial_jump_velocity)


func end_jump():
	_jumping = false
	set_process(false)


func _on_collision(floor_angle: float):
	if floor_angle <= deg2rad(max_floor_angle_degrees):
		_current_jumps = max_jumps


func _ready():
	set_process(false)


func _process(delta):
	emit_signal("add_velocity", _jump_vector * jump_acceleration * delta)
	_jump_timer -= delta

	if _jump_timer <= 0:
		_jumping = false
		set_process(false)
