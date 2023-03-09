extends Node


const BG_MUSIC := preload("res://music/Project_8.mp3")


func _ready():
	pause_mode = PAUSE_MODE_PROCESS
	var bg_music := AudioStreamPlayer.new()
	bg_music.stream = BG_MUSIC
	bg_music.autoplay = true
	bg_music.bus = "Music"
	add_child(bg_music)
