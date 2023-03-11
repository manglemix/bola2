class_name VariableVolume
extends Node


export var max_stimuli_value := 1.0
export var min_stimuli_value := 0.0
export var max_volume_db := 10.0
export var min_volume_db := -10.0


func calculate_volume(value: float) -> float:
	return clamp(lerp(min_volume_db, max_volume_db, inverse_lerp(min_stimuli_value, max_stimuli_value, value)), min_volume_db, max_volume_db)


func produce_player(stream: AudioStream, value: float) -> AudioStreamPlayer2D:
	var stream_player := AudioStreamPlayer2D.new()
	stream_player.bus = "SFX"
	stream_player.stream = stream
	stream_player.volume_db = calculate_volume(value)
	stream_player.autoplay = true
	# warning-ignore:return_value_discarded
	stream_player.connect("finished", stream_player, "queue_free")
	return stream_player
