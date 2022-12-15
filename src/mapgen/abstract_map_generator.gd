class_name AbstractMapGenerator
extends Node


# warning-ignore:unused_signal
signal platform_generated(platform)
# warning-ignore:unused_signal
signal finished

var rng := RandomNumberGenerator.new()


func seed_rng(new_seed: int):
	rng.seed = new_seed


func generate() -> void:
	print_debug("Abstract method generate needs to be implemented before it can be called")
