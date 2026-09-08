extends Control

@export var levels: Array[LevelData] = []
@export var level_card_scene: PackedScene

@onready var grid: GridContainer = $MarginContainer/GridContainer
@onready var back_button: Button = $MarginContainer/BackButton


func _ready() -> void:
	_populate_grid()


func _populate_grid() -> void:
	for i in levels.size():
		var card := level_card_scene.instantiate()
		grid.add_child(card)
		card.setup(levels[i], i)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
