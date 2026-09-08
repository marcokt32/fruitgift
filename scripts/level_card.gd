extends Button

var level_data: LevelData
var level_index: int

@onready var name_label: Label = $Panel/MarginContainer/VBoxContainer/NameLabel
@onready var lock_icon: TextureRect = $LockIcon

# NOVO: ajuste os paths pros nós reais da sua cena
@onready var fruits_label: Label = $Panel/MarginContainer/VBoxContainer/FruitsLabel
@onready var monsters_label: Label = $Panel/MarginContainer/VBoxContainer/MonstersLabel
@onready var crates_label: Label = $Panel/MarginContainer/VBoxContainer/CratesLabel
@onready var stars_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/StarsContainer


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

	fruits_label.text = "%d / %d" % [record["fruits"], level_data.total_fruits]
	monsters_label.text = "%d / %d" % [record["monsters"], level_data.total_monsters]
	crates_label.text = "%d / %d" % [record["crates"], level_data.total_crates]

	_set_stars(record["stars"])


func _set_stars(stars: int) -> void:
	for i in range(stars_container.get_child_count()):
		var star_icon: TextureRect = stars_container.get_child(i)
		star_icon.modulate = Color.WHITE if i < stars else Color(1, 1, 1, 0.3)


func _on_pressed() -> void:
	get_tree().change_scene_to_file(level_data.scene_path)
