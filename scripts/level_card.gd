extends Button

var level_data: LevelData
var level_index: int

# Definido pelo LevelSelect: retorna true se o usuário acabou de arrastar
var drag_check: Callable = func() -> bool: return false

@onready var lock_icon: TextureRect = $LockIcon
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var fruits_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/FruitsLabel
@onready var monsters_label: Label = $MarginContainer/VBoxContainer/HBoxContainer2/MonstersLabel
@onready var coins_label: Label = $MarginContainer/VBoxContainer/HBoxContainer3/CratesLabel
@onready var stars_container: HBoxContainer = $MarginContainer/VBoxContainer/StarsContainer
@onready var thumbnail: TextureRect = $MarginContainer/VBoxContainer/Thumb


func setup(data: LevelData, index: int) -> void:
	level_data = data
	level_index = index

	name_label.text = data.level_name

	var unlocked: bool = ProgressManager.is_unlocked(index)
	disabled = not unlocked
	lock_icon.visible = not unlocked

	_update_progress_display()


func _update_progress_display() -> void:
	var record := ProgressManager.get_level_record(level_index)

	thumbnail.texture = level_data.thumbnail
	fruits_label.text = "%d / %d" % [record["fruits"], level_data.total_fruits]
	monsters_label.text = "%d / %d" % [record["monsters"], level_data.total_monsters]
	coins_label.text = "%d / %d" % [
		ProgressManager.get_level_coins_count(level_index),
		level_data.total_coins,
	]

	_set_stars(record["stars"])


func _set_stars(stars: int) -> void:
	for i in range(stars_container.get_child_count()):
		var star_icon: TextureRect = stars_container.get_child(i)
		star_icon.modulate = Color.WHITE if i < stars else Color(1, 1, 1, 0.3)


func _on_pressed() -> void:
	# Se o usuário arrastou, não abre o level
	if drag_check.call():
		return
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	MusicPlayer.stop_music(0.5)
	get_tree().change_scene_to_file(level_data.scene_path)
