class_name PlatformTools


const VISIBLE_MESHES := true


static func base_platformify(node: Node2D, start_origin: Vector2, end_origin: Vector2, thickness: int):
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
	
	var mesh_shape: PrimitiveMesh = QuadMesh.new()
	mesh_shape.size = platform_size
	var mesh_node := MeshInstance2D.new()
	mesh_node.mesh = mesh_shape
	mesh_node.name = "BarMesh"
	mesh_node.visible = VISIBLE_MESHES
	node.add_child(mesh_node)
	
	mesh_shape = SphereMesh.new()
	# warning-ignore:integer_division
	mesh_shape.radius = thickness / 2
	# warning-ignore:integer_division
	mesh_shape.height = thickness / 2
	mesh_shape.rings = 4
	mesh_shape.radial_segments = 8
	mesh_node.visible = VISIBLE_MESHES
	mesh_shape.is_hemisphere = true
	
	mesh_node = MeshInstance2D.new()
	mesh_node.mesh = mesh_shape
	mesh_node.position.x = - width / 2
	mesh_node.rotation_degrees = 90
	mesh_node.name = "LeftCapMesh"
	mesh_node.visible = VISIBLE_MESHES
	node.add_child(mesh_node)
	
	mesh_node = MeshInstance2D.new()
	mesh_node.mesh = mesh_shape
	mesh_node.position.x = width / 2
	mesh_node.rotation_degrees = 270
	mesh_node.name = "RightCapMesh"
	mesh_node.visible = VISIBLE_MESHES
	node.add_child(mesh_node)


func _init():
	print_debug("Abstract class PlatformTools is not to be instantiated")
