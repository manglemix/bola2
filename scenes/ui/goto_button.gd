class_name GotoButton
extends Button


export(String, FILE, "*.tscn") var path: String


func _ready():
	# warning-ignore:return_value_discarded
	connect("pressed", self, "_on_pressed")


func _on_pressed():
	# warning-ignore:return_value_discarded
	get_tree().change_scene(path)
