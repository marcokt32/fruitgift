extends Control

@export var level_select_path: String = ""
@export var intro_scene_path: String = ""

@onready var play_button:= $MarginContainer/VBoxContainer2/HBoxContainer/PlayButton
@onready var options_button: TextureButton = $MarginContainer/VBoxContainer/OptionsButton
@onready var quit_button: TextureButton = $MarginContainer/VBoxContainer/QuitButton
@onready var options_menu: CanvasLayer = $Pause  # ou onde você instanciou
@onready var main_texture:= $MarginContainer/VBoxContainer2/MainTexture

# Configurações do efeito (ajuste como preferir)
var velocidade_pulso: float = 4.5  # Quão rápido ele pulsa
var intensidade_pulso: float = 0.03  # Quão grande/pequeno ele fica (0.1 = varia 10%)

var tempo: float = 0.0


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	options_menu.visible = false

	play_button.grab_focus()

func _process(delta: float) -> void:
	# Acumula o tempo decorrido multiplicado pela velocidade
	tempo += delta * velocidade_pulso
	
	# O seno varia de -1 a 1. Multiplicado pela intensidade, varia de -0.1 a 0.1
	# Somando 1.0, a escala final vai oscilar suavemente entre 0.9 e 1.1
	var nova_escala: float = 1.0 + (sin(tempo) * intensidade_pulso)
	
	# Aplica a nova escala nos eixos X e Y
	main_texture.offset_transform_scale = Vector2(nova_escala, nova_escala)


func _on_play_pressed() -> void:
	if ProgressManager.has_seen_intro:
		get_tree().change_scene_to_file(level_select_path)
	else:
		get_tree().change_scene_to_file(intro_scene_path)
	

func _on_options_pressed() -> void:
	options_menu.open_menu()


func _on_options_closed() -> void:
	options_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
