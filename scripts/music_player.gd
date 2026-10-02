extends Node

@onready var player: AudioStreamPlayer = $AudioStreamPlayer
var fade_tween: Tween

func play_menu_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	_cancel_fade()
	if player.stream == stream and player.playing:
		return
	player.stream = stream
	player.volume_db = volume_db
	player.play()

func stop_music(fade_out: float = 0.0) -> void:
	_cancel_fade()
	if fade_out > 0.0:
		fade_tween = create_tween()
		fade_tween.tween_property(player, "volume_db", -40.0, fade_out)
		fade_tween.tween_callback(player.stop)
	else:
		player.stop()

func _cancel_fade() -> void:
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
