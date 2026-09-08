extends Node

const SAVE_PATH := "user://progress.save"

var unlocked_levels: int = 1
var has_seen_intro: bool = false
var camera_zoom: float = 1.0

# Pontuação global (nunca reseta)
var total_fruit_score: int = 0

# Soma de estrelas de todas as fases
var total_stars: int = 0

# level_records["0"] = {"fruits": int, "monsters": int, "crates": int, "stars": int}
var level_records: Dictionary = {}

# Contexto da fase em andamento
var _current_level_index: int = -1
var _current_level_totals: Dictionary = {}


func _ready() -> void:
	_load()
	GameEvents.fruit_collected.connect(_on_fruit_collected)


# Chame no _ready() da fase, informando os totais dela
func start_level(level_index: int, totals: Dictionary) -> void:
	_current_level_index = level_index
	_current_level_totals = totals
	GameEvents.reset()


# Chame quando o jogador terminar a fase (ex: chegou na bandeira/porta final)
func finish_level() -> int:
	if _current_level_index == -1:
		return 0

	var fruits := GameEvents.fruit_count
	var monsters := GameEvents.monster_count
	var crates := GameEvents.crate_count
	var totals := _current_level_totals

	var stars := 0
	if totals.get("fruits", 0) > 0 and fruits >= totals["fruits"]:
		stars += 1
	if totals.get("monsters", 0) > 0 and monsters >= totals["monsters"]:
		stars += 1
	if totals.get("crates", 0) > 0 and crates >= totals["crates"]:
		stars += 1

	_update_level_record(_current_level_index, fruits, monsters, crates, stars)
	_save()

	return stars


func _update_level_record(level_index: int, fruits: int, monsters: int, crates: int, stars: int) -> void:
	var key := str(level_index)
	var previous: Dictionary = level_records.get(key, {"fruits": 0, "monsters": 0, "crates": 0, "stars": 0})

	level_records[key] = {
		"fruits": max(previous.get("fruits", 0), fruits),
		"monsters": max(previous.get("monsters", 0), monsters),
		"crates": max(previous.get("crates", 0), crates),
		"stars": max(previous.get("stars", 0), stars),
	}

	_recalculate_total_stars()


func _recalculate_total_stars() -> void:
	var sum := 0
	for key in level_records.keys():
		sum += level_records[key].get("stars", 0)
	total_stars = sum


# Usado pelo card da fase pra exibir o recorde salvo
func get_level_record(level_index: int) -> Dictionary:
	return level_records.get(str(level_index), {"fruits": 0, "monsters": 0, "crates": 0, "stars": 0})


func _on_fruit_collected() -> void:
	total_fruit_score += 1
	_save()


func complete_level(level_index: int) -> void:
	if level_index + 1 >= unlocked_levels:
		unlocked_levels = level_index + 2
		_save()


func is_unlocked(level_index: int) -> bool:
	return level_index < unlocked_levels


func mark_intro_seen() -> void:
	if not has_seen_intro:
		has_seen_intro = true
		_save()


func reset_progress() -> void:
	unlocked_levels = 1
	level_records.clear()
	total_stars = 0
	total_fruit_score = 0
	camera_zoom = 1
	has_seen_intro = false
	_save()


func set_camera_zoom(value: float) -> void:
	camera_zoom = value
	_save()


func get_camera_zoom() -> float:
	return camera_zoom


func get_camera_zoom_vector() -> Vector2:
	return Vector2(camera_zoom, camera_zoom)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "unlocked_levels", unlocked_levels)
	config.set_value("progress", "has_seen_intro", has_seen_intro)
	config.set_value("progress", "camera_zoom", camera_zoom)
	config.set_value("progress", "total_fruit_score", total_fruit_score)
	config.set_value("progress", "total_stars", total_stars)
	config.set_value("progress", "level_records", level_records)
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		unlocked_levels = config.get_value("progress", "unlocked_levels", 1)
		has_seen_intro = config.get_value("progress", "has_seen_intro", false)
		camera_zoom = config.get_value("progress", "camera_zoom", 1.0)
		total_fruit_score = config.get_value("progress", "total_fruit_score", 0)
		total_stars = config.get_value("progress", "total_stars", 0)
		level_records = config.get_value("progress", "level_records", {})
