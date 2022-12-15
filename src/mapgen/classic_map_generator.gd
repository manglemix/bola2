class_name ClassicMapGenerator
extends AbstractMapGenerator


export var map_grid_height := 30
export var map_grid_width := 20
export var grid_cell_size := 50
export var platform_count := 50
export var platform_length_distribution: Curve
export var platform_angle_distribution: Curve
export var normal_platform_probability := 0.5
export var fragile_platform_probability := 0.3
export var rotatable_platform_probability := 0.12
export var bouncy_platform_probability := 0.08
export var platform_thickness := 10


func generate() -> void:
	var i := 0
	var origins := []
	
	while i < platform_count:
		var start_origin := Vector2(
			# warning-ignore:integer_division
			# warning-ignore:integer_division
			rng.randi_range(- map_grid_width / 2, map_grid_width / 2),
			- rng.randi_range(0, map_grid_height)
		)
		
		var angle := deg2rad(platform_angle_distribution.interpolate(rng.randf()))
		if rng.randf() < 0.5:
			angle *= -1
		
		var travel := (Vector2.RIGHT * platform_length_distribution.interpolate(rng.randf())) \
			.rotated(angle) \
			.round()
		
		var end_origin := start_origin + travel
		
		# warning-ignore:integer_division
		if abs(end_origin.x) > map_grid_width / 2 or end_origin.y < - map_grid_height or end_origin.y > 0:
			continue
		
		var failed := false
		for segment in origins:
			var other_start_origin: Vector2 = segment[0]
			var other_end_origin: Vector2 = segment[1]
			
			if MapGenTools.is_between(other_start_origin, other_end_origin, start_origin):
				if MapGenTools.is_along(other_start_origin, other_end_origin, end_origin):
					failed = true
					break
			elif MapGenTools.is_between(other_start_origin, other_end_origin, end_origin):
				if MapGenTools.is_along(other_start_origin, other_end_origin, start_origin):
					failed = true
					break
			if MapGenTools.is_between(start_origin, end_origin, other_start_origin):
				if MapGenTools.is_along(start_origin, end_origin, other_end_origin):
					failed = true
					break
			elif MapGenTools.is_between(start_origin, end_origin, other_end_origin):
				if MapGenTools.is_along(start_origin, end_origin, other_start_origin):
					failed = true
					break
		
		if failed:
			continue
		
		origins.append([start_origin, end_origin])
		var platform_type_sample := rng.randf()
		var platform_type

		if platform_type_sample <= normal_platform_probability:
			platform_type = 0
		
		elif platform_type_sample <= normal_platform_probability + fragile_platform_probability:
			platform_type = 1
		
		elif platform_type_sample <= normal_platform_probability + fragile_platform_probability + rotatable_platform_probability:
			platform_type = 2
		
		else:
			platform_type = 3
		
		emit_signal(
			"platform_generated",
			GeneratedPlatform.new(
				start_origin * grid_cell_size,
				end_origin * grid_cell_size,
				platform_type,
				platform_thickness
			)
		)
		
		i += 1
	
	emit_signal("finished")
