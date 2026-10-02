extends Node2D  # ou o tipo da raiz da sua fase

@export var level_music: AudioStream

func _ready() -> void:
	if level_music:
		MusicPlayer.play_menu_music(level_music)
