extends Control

@export var levels: Array[LevelData] = []
@export var level_card_scene: PackedScene

@onready var grid:= $MarginContainer/HBoxContainer2/VBoxContainer/GridContainer
@onready var back_button: Button = $MarginContainer/HBoxContainer2/VBoxContainer2/BackButton
@onready var fruit_label: Label = %FruitLabel
@onready var star_label: Label = %StarLabel

func _ready() -> void:
	fruit_label.text = str(ProgressManager.total_fruit_score)
	star_label.text = str(ProgressManager.total_stars)
	_validate_level_indices()
	_populate_grid()

func _validate_level_indices() -> void:
	var seen_indices: Dictionary = {}
	for data in levels:
		if data == null:
			push_error("LevelSelect: um item do array 'levels' está vazio (null)")
			continue
		if seen_indices.has(data.level_index):
			push_error("LevelSelect: level_index %d duplicado! Usado em '%s' e '%s'" % [
				data.level_index, seen_indices[data.level_index], data.level_name
			])
		seen_indices[data.level_index] = data.level_name	


func _populate_grid() -> void:
	for i in levels.size():
		var card := level_card_scene.instantiate()
		grid.add_child(card)
		card.setup(levels[i], levels[i].level_index)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Prefabs/slot_select.tscn")


func _on_testes_pressed() -> void:
	get_tree().change_scene_to_file("res://Levels/test_level.tscn")
