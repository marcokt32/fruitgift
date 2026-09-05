extends Node

const SAVE_PATH := "user://progress.save"

var unlocked_levels: int = 1  # quantos níveis já estão liberados (index 0 sempre desbloqueado)


func _ready() -> void:
	_load()


func complete_level(level_index: int) -> void:
	if level_index + 1 >= unlocked_levels:
		unlocked_levels = level_index + 2
		_save()


func is_unlocked(level_index: int) -> bool:
	return level_index < unlocked_levels


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "unlocked_levels", unlocked_levels)
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		unlocked_levels = config.get_value("progress", "unlocked_levels", 1)


func reset_progress() -> void:
	unlocked_levels = 1
	_save()
