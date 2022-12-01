extends Node


var _blocks := 0


func add_block():
	if _blocks == 0:
		VisualServer.render_loop_enabled = false
	_blocks += 1


func remove_block():
	if _blocks < 0:
		print_debug("Attempted to remove no frame blocks!")
		return
	_blocks -= 1
	if _blocks == 0:
		VisualServer.render_loop_enabled = true
