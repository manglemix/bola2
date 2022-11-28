class_name ActiveAgent
extends RigidBody2D


const THUMP_SOUND := preload("res://sfx/536789__egomassive__thumps.wav")

signal position_set

export var default_jump_controller_path: NodePath

var _velocity_set_is_queued := false
var _queued_velocity_set: Vector2
var _queued_velocity_addition: Vector2
var _position_set_is_queued := false
var _queued_position_set: Vector2

onready var _variable_volume: VariableVolume = $VariableVolume
onready var _default_jump_controller: ClassicJumpController = get_node(default_jump_controller_path)
onready var _current_jump_controller: AbstractJumpController = _default_jump_controller


func try_jump(direction: float):
	_current_jump_controller.try_jump(direction, linear_velocity)


func end_jump():
	_current_jump_controller.end_jump()


func add_child(node: Node, legible_unique_name:=false):
	if node is AbstractJumpController:
		_current_jump_controller.disconnect("add_velocity", self, "queue_velocity_addition")
		_current_jump_controller.disconnect("set_velocity", self, "queue_velocity_set")
		_current_jump_controller.disconnect("tree_exited", self, "_reset_jump_controller")
		_current_jump_controller.end_jump()
		
		_current_jump_controller = node
		# warning-ignore:return_value_discarded
		node.connect("tree_exited", self, "_reset_jump_controller")
		# warning-ignore:return_value_discarded
		node.connect("add_velocity", self, "queue_velocity_addition")
		# warning-ignore:return_value_discarded
		node.connect("set_velocity", self, "queue_velocity_set")
	
	.add_child(node, legible_unique_name)


func _reset_jump_controller():
	_current_jump_controller.disconnect("add_velocity", self, "queue_velocity_addition")
	_current_jump_controller.disconnect("set_velocity", self, "queue_velocity_set")
	_current_jump_controller = _default_jump_controller


func queue_position_set(new_position: Vector2):
	_queued_position_set = new_position
	_position_set_is_queued = true


func queue_velocity_addition(velocity_addition: Vector2):
	_queued_velocity_addition += velocity_addition


func queue_velocity_set(new_velocity: Vector2):
	_queued_velocity_set = new_velocity
	_velocity_set_is_queued = true


func _ready():
	# warning-ignore:return_value_discarded
	_default_jump_controller.connect("add_velocity", self, "queue_velocity_addition")
	# warning-ignore:return_value_discarded
	_default_jump_controller.connect("set_velocity", self, "queue_velocity_set")


func _integrate_forces(state: Physics2DDirectBodyState):
	if _position_set_is_queued:
		state.transform.origin = _queued_position_set
		_position_set_is_queued = false
		emit_signal("position_set")
		
	if _velocity_set_is_queued:
		state.linear_velocity = _queued_velocity_set
		_velocity_set_is_queued = false

	state.linear_velocity += _queued_velocity_addition
	_queued_velocity_addition = Vector2.ZERO
	
	var normal_sum := Vector2.ZERO
#	var velocity_sum := Vector2.ZERO
	for i in range(state.get_contact_count()):
		normal_sum += state.get_contact_local_normal(i)
#		velocity_sum += state.get_velocity_at_local_position(state.get_contact_collider_position(0))
	
	if normal_sum.length_squared() > 0:
		_current_jump_controller._on_collision(abs(normal_sum.angle_to(Vector2.UP)))
	
		var collision_speed := abs(linear_velocity.dot(normal_sum.normalized()))
		if collision_speed > _variable_volume.min_stimuli_value:
			add_child(_variable_volume.produce_player(THUMP_SOUND, collision_speed))
	
