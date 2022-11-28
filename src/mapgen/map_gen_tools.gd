class_name MapGenTools


static func is_between(from: Vector2, to: Vector2, p: Vector2) -> bool:
	if p.is_equal_approx(from) or p.is_equal_approx(to):
		return true
	
	var from_vec := (p - from).normalized()
	var to_vec := (p - to).normalized()
	
	return is_equal_approx(from_vec.dot(to_vec), -1)


static func is_along(from: Vector2, to: Vector2, p: Vector2) -> bool:
	if p.is_equal_approx(from) or p.is_equal_approx(to):
		return true
	
	var from_vec := (p - from).normalized()
	var to_vec := (p - to).normalized()
	
	return is_equal_approx(abs(from_vec.dot(to_vec)), 1)


func _init():
	print_debug("Abstract class MapGenTools is not to be instantiated")
