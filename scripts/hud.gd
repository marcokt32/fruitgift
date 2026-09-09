extends CanvasLayer
#SCRIPT DO HUD

@export var full_heart: Texture2D
@export var empty_heart: Texture2D
@export var panel_anim_duration := 0.25  # NOVO

@onready var fruit_label: Label = $MarginContainer/LeftContainer/VBoxContainer/LevelFruitsCounter/FruitLabel
@onready var points_label: Label = $MarginContainer/RightContainer/VBoxContainer/PointsSpan/Label
@onready var hearts: Array[TextureRect] = [
	$MarginContainer/LeftContainer/VBoxContainer/HealthCounter/TextureRect1,
	$MarginContainer/LeftContainer/VBoxContainer/HealthCounter/TextureRect2,
	$MarginContainer/LeftContainer/VBoxContainer/HealthCounter/TextureRect3,
]
@onready var lifes: Array[TextureRect] = [
	$MarginContainer/RightContainer/VBoxContainer/LifesCounter/TextureRect1,
	$MarginContainer/RightContainer/VBoxContainer/LifesCounter/TextureRect2,
	$MarginContainer/RightContainer/VBoxContainer/LifesCounter/TextureRect3,
]
@onready var control_hud := $"../ControlHUD"
@onready var ammo_container: HBoxContainer = $MarginContainer/LeftContainer/VBoxContainer/AmmoCounter
@onready var ammo_label: Label = $MarginContainer/LeftContainer/VBoxContainer/AmmoCounter/Label
@onready var game_over_panel: Control = $MarginContainer/GameOverPanel
@onready var continue_button: Control = $MarginContainer/GameOverPanel/PanelContainer/VBoxContainer/ContinueButton
@onready var player = $"../Player"

var _game_over_tween: Tween  # NOVO


func _process(delta: float) -> void:
	points_label.text = str(ProgressManager.total_fruit_score)
	fruit_label.text = str(GameEvents.fruit_count)


func _ready() -> void:
	var level = get_parent().get_parent()
	var crates = level.get_node("Crates")
	var enemies = level.get_node("Enemies")
	var fruits = level.get_node("Fruits")
	print("Fruits: ", fruits.get_child_count())
	print("Enemies: ", enemies.get_child_count())
	print("Crates: ", crates.get_child_count())

	game_over_panel.visible = false

	# NOVO: estado inicial do painel pra animação (centralizado, invisível, um pouco menor)
	game_over_panel.pivot_offset = game_over_panel.size / 2.0
	game_over_panel.modulate.a = 0.0
	game_over_panel.scale = Vector2(0.9, 0.9)

	ammo_container.visible = false
	var player := get_tree().get_first_node_in_group("player")

	GameEvents.fruit_collected.connect(_on_fruit_collected)
	_on_fruit_collected()

	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.died.connect(_on_player_died)
		player.ammo_changed.connect(_on_ammo_changed)
		player.lifes_changed.connect(_on_lifes_changed)
		ammo_container.visible = false


func _on_player_health_changed(current_health: int, _max_health: int) -> void:
	for i in hearts.size():
		if i < current_health:
			hearts[i].modulate.a = 1.0   # coração visível/opaco
		else:
			hearts[i].modulate.a = 0.2   # quase invisível = "vazio"


func _on_player_died() -> void:
	if GameEvents.life_count <= 0:
		continue_button.set_deferred("disabled", true)

	control_hud.set_deferred("visible", false)
	get_tree().paused = true

	_animate_game_over_in()  # NOVO


func _on_restart_button_pressed() -> void:
	control_hud.set_deferred("visible", true)
	get_tree().paused = false
	GameEvents.life_count = 3
	get_tree().reload_current_scene()


func _on_fruit_collected() -> void:
	fruit_label.text = "x " + str(GameEvents.fruit_count)


func _on_ammo_changed(current_ammo: int) -> void:
	ammo_container.visible = current_ammo > 0
	ammo_label.text = "x " + str(current_ammo)


func _on_lifes_changed(current_life: int) -> void:
	var total := lifes.size()
	for i in lifes.size():
		var reversed_index = total - 1 - i
		if reversed_index < current_life:
			lifes[i].modulate.a = 1.0   # coração diamante/opaco
		else:
			lifes[i].modulate.a = 0.2   # quase invisível = "vazio"


func _on_continue_button_pressed() -> void:
	control_hud.set_deferred("visible", true)
	GameEvents.player_respawned.emit()
	player._reset_status()
	player.global_position = GameEvents.check_position
	player.blink()
	get_tree().paused = false

	_animate_game_over_out()  # NOVO (substitui o "game_over_panel.visible = false" direto)


# NOVO: animação de aparição do game over (fade + scale up)
func _animate_game_over_in() -> void:
	if _game_over_tween != null and _game_over_tween.is_valid():
		_game_over_tween.kill()

	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	game_over_panel.scale = Vector2(0.9, 0.9)

	_game_over_tween = create_tween()
	_game_over_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)  # continua rodando com o jogo pausado
	_game_over_tween.set_parallel(true)
	_game_over_tween.tween_property(game_over_panel, "modulate:a", 1.0, panel_anim_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_game_over_tween.tween_property(game_over_panel, "scale", Vector2.ONE, panel_anim_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# NOVO: animação de saída do game over (fade + scale down)
func _animate_game_over_out() -> void:
	if _game_over_tween != null and _game_over_tween.is_valid():
		_game_over_tween.kill()

	_game_over_tween = create_tween()
	_game_over_tween.set_parallel(true)
	_game_over_tween.tween_property(game_over_panel, "modulate:a", 0.0, panel_anim_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_game_over_tween.tween_property(game_over_panel, "scale", Vector2(0.9, 0.9), panel_anim_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_game_over_tween.chain().tween_callback(func(): game_over_panel.visible = false)
