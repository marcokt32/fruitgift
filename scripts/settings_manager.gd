extends Node

# Configurações globais da instalação.
# Não têm relação com os slots de progresso.

const SAVE_PATH := "user://settings.save"

var camera_zoom: float = 1.0
var language: String = "en"


func _ready() -> void:
	_load()
	_apply_language()


# =========================================================
# IDIOMA
# =========================================================

func set_language(value: String) -> void:
	language = value
	TranslationServer.set_locale(language)
	_save()


func get_language() -> String:
	return language


func _apply_language() -> void:
	TranslationServer.set_locale(language)


func _detect_system_language() -> String:
	var locale := OS.get_locale()

	if locale.begins_with("pt"):
		return "pt_BR"
	elif locale.begins_with("es"):
		return "es"
	else:
		return "en"


# =========================================================
# CAMERA
# =========================================================

func set_camera_zoom(value: float) -> void:
	camera_zoom = value
	_save()


func get_camera_zoom() -> float:
	return camera_zoom


func get_camera_zoom_vector() -> Vector2:
	return Vector2(camera_zoom, camera_zoom)


# =========================================================
# SAVE / LOAD
# =========================================================

func _save() -> void:
	var config := ConfigFile.new()

	config.set_value("settings", "camera_zoom", camera_zoom)
	config.set_value("settings", "language", language)

	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()

	var err := config.load(SAVE_PATH)

	if err == OK:
		camera_zoom = config.get_value("settings", "camera_zoom", 1.0)
		language = config.get_value(
			"settings",
			"language",
			_detect_system_language()
		)
	else:
		language = _detect_system_language()
