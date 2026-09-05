extends Control

@export var level_select_path: String = "res://scenes/level_select.tscn"

@onready var play_button: TextureButton = $MarginContainer/PlayButton
@onready var options_button: TextureButton = $MarginContainer/VBoxContainer/OptionsButton
@onready var quit_button: TextureButton = $MarginContainer/VBoxContainer/QuitButton
@onready var options_menu: CanvasLayer = $Pause  # ou onde você instanciou


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	options_menu.visible = false

	play_button.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(level_select_path)


func _on_options_pressed() -> void:
	options_menu.open_menu()


func _on_options_closed() -> void:
	options_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
