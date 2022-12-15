class_name PlatformTools


const RECT_SCENE := preload("res://scenes/platforms/rect.tscn")
const SEMICIRCLE_SCENE := preload("res://scenes/platforms/semicircle.tscn")


static func is_platforms_visible() -> bool:
	return ProjectSettings.get_setting("constants/debug_data/visible_platforms")


# TODO Use Polygon2D
static func base_platformify(node: Node2D, start_origin: Vector2, end_origin: Vector2, thickness: int):
	var visible_platforms := is_platforms_visible()
	
	var travel := end_origin - start_origin
	node.position = start_origin + travel / 2
	node.rotation = travel.angle()
	var collision_shape: Shape2D = RectangleShape2D.new()
	var width := travel.length()
	var platform_size := Vector2(width, thickness)
	collision_shape.extents = platform_size / 2
	
	var collision_shape_node := CollisionShape2D.new()
	collision_shape_node.shape = collision_shape
	collision_shape_node.name = "BarShape"
	node.add_child(collision_shape_node)
	
	collision_shape = CircleShape2D.new()
	# warning-ignore:integer_division
	collision_shape.radius = thickness / 2
	
	collision_shape_node = CollisionShape2D.new()
	collision_shape_node.shape = collision_shape
	collision_shape_node.position.x = - width / 2
	collision_shape_node.name = "LeftCapShape"
	node.add_child(collision_shape_node)
	
	collision_shape_node = CollisionShape2D.new()
	collision_shape_node.shape = collision_shape
	collision_shape_node.position.x = width / 2
	collision_shape_node.name = "RightCapShape"
	node.add_child(collision_shape_node)
	
	var mesh_node: Node2D = RECT_SCENE.instance()
	mesh_node.scale = platform_size
	mesh_node.name = "BarMesh"
	mesh_node.visible = visible_platforms
	node.add_child(mesh_node)
	
	mesh_node = SEMICIRCLE_SCENE.instance()
	mesh_node.scale = Vector2(thickness, thickness)
	mesh_node.position.x = - width / 2
	mesh_node.rotation_degrees = 180
	mesh_node.name = "LeftCapMesh"
	mesh_node.visible = visible_platforms
	node.add_child(mesh_node)
	
	mesh_node = SEMICIRCLE_SCENE.instance()
	mesh_node.scale = Vector2(thickness, thickness)
	mesh_node.position.x = width / 2
	mesh_node.name = "RightCapMesh"
	mesh_node.visible = visible_platforms
	node.add_child(mesh_node)


func _init():
	print_debug("Abstract class PlatformTools is not to be instantiated")
