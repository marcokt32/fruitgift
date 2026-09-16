extends Node

# Configurações globais do DISPOSITIVO/instalação, não do progresso do jogador.
# Não têm relação com slots: valem para quem estiver jogando, em qualquer slot.

const SAVE_PATH := "user://settings.save"

var camera_zoom: float = 1.0
# Adicione aqui outras preferências globais no futuro: volume, idioma, etc.


func _ready() -> void:
	_load()


func set_camera_zoom(value: float) -> void:
	camera_zoom = value
	_save()


func get_camera_zoom() -> float:
	return camera_zoom


func get_camera_zoom_vector() -> Vector2:
	return Vector2(camera_zoom, camera_zoom)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "camera_zoom", camera_zoom)
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		camera_zoom = config.get_value("settings", "camera_zoom", 1.0)
