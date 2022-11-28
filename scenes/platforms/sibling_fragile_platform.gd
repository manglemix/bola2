class_name SiblingFragilePlatform
extends RigidBody2D


var _offset: Vector2
var _is_offset_queued := false
var _tween: Tween


func _integrate_forces(state: Physics2DDirectBodyState):
	if _is_offset_queued:
		_is_offset_queued = false
		state.transform.origin += _offset


func prepare_for_death(offset: Vector2):
	if !is_inside_tree():
		return

	var current_scene := get_tree().current_scene
	
	_is_offset_queued = true
	_offset = offset
	get_parent().remove_child(self)
	current_scene.add_child(self)
	# warning-ignore:return_value_discarded
	_tween.resume_all()


func prepare_for_advancement(offset: Vector2):
	if contact_monitor:
		return
	
	_is_offset_queued = true
	_offset = offset
