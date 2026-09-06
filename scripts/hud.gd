extends CanvasLayer

@export var full_heart: Texture2D
@export var empty_heart: Texture2D

@onready var fruit_label: Label = $MarginContainer/VBoxContainer/HBoxContainer2/FruitLabel
@onready var hearts: Array[TextureRect] = [
	$MarginContainer/VBoxContainer/HBoxContainer/TextureRect1,
	$MarginContainer/VBoxContainer/HBoxContainer/TextureRect2,
	$MarginContainer/VBoxContainer/HBoxContainer/TextureRect3,
]
@onready var ammo_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer3
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/HBoxContainer3/Label
@onready var game_over_panel: Control = $GameOverPanel
@onready var continue_button: Control = $GameOverPanel/VBoxContainer/ContinueButton
@onready var player = $"../Player"

func _ready() -> void:
	game_over_panel.visible = false
	ammo_container.visible = false

	var player := get_tree().get_first_node_in_group("player")
	
	GameEvents.fruit_collected.connect(_on_fruit_collected)
	_on_fruit_collected(GameEvents.fruit_count)

	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.died.connect(_on_player_died)
		player.ammo_changed.connect(_on_ammo_changed)
		ammo_container.visible = false

func _on_player_health_changed(current_health: int, _max_health: int) -> void:
	for i in hearts.size():
		if i < current_health:
			hearts[i].modulate.a = 1.0   # coração visível/opaco
		else:
			hearts[i].modulate.a = 0.2   # quase invisível = "vazio"

func _on_player_died() -> void:
	if GameEvents.life_count <= 0:
		continue_button.set_deferred("disabled",true)
	game_over_panel.visible = true
	get_tree().paused = true

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	GameEvents.life_count = 3
	get_tree().reload_current_scene()

func _on_fruit_collected(total: int) -> void:
	fruit_label.text = "x " + str(total)

func _on_ammo_changed(current_ammo: int) -> void:
	ammo_container.visible = current_ammo > 0
	ammo_label.text = "x " + str(current_ammo)

func _on_continue_button_pressed() -> void:
	GameEvents.player_respawned.emit()
	player._reset_status()
	player.global_position = GameEvents.check_position
	player.blink()
	game_over_panel.visible = false
	get_tree().paused = false
