extends CanvasLayer

@onready var panel_container: PanelContainer = $PanelContainer  # NOVO
@onready var pause_menu: VBoxContainer = $PanelContainer/PauseMenu
@onready var options_menu: VBoxContainer = $PanelContainer/OptionsMenu

@onready var options_button: Button = $PanelContainer/PauseMenu/HBoxContainer/OptionsButton
@onready var continue_button: Button = $PanelContainer/PauseMenu/HBoxContainer/ContinueButton
@onready var replay_button: Button = $PanelContainer/PauseMenu/HBoxContainer/ReplayButton
@onready var quit_button: Button = $PanelContainer/PauseMenu/HBoxContainer/QuitButton

@onready var options_back_button: Button = %BackButton

@onready var zoom_slider: HSlider = %ZoomSlider

@onready var background_scroll: Control = $Banner/BackgroundScroll
@onready var background_rect: Control = $Banner/TextureRect

@export var level_select_path: String = "res://Prefabs/level_select.tscn"
@export var start_on_options: bool = false
@export var show_progress_button: bool = true
@export var pause_action_enabled: bool = true
@export var open_close_duration := 0.25  # NOVO

var is_paused: bool = false
var _bg_tween: Tween
var _panel_tween: Tween  # NOVO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	pause_menu.visible = false
	options_menu.visible = false

	zoom_slider.min_value = 1.0
	zoom_slider.max_value = 1.3
	zoom_slider.step = 0.01
	zoom_slider.value = SettingsManager.get_camera_zoom()

	# NOVO: estado inicial do painel para a animação (invisível, um pouco menor)
	panel_container.pivot_offset = panel_container.size / 2.0
	panel_container.modulate.a = 0.0
	panel_container.scale = Vector2(0.9, 0.9)

	options_button.pressed.connect(_on_options_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	options_back_button.pressed.connect(_on_options_back_pressed)

	zoom_slider.value_changed.connect(_on_zoom_changed)
	
	#FUNÇÃO ESMAECER FUNDO DESCONTINUADA
	#zoom_slider.drag_started.connect(_on_zoom_drag_started)
	#zoom_slider.drag_ended.connect(_on_zoom_drag_ended)

	GameEvents.player_respawned.connect(_on_player_respawned)


func _unhandled_input(event: InputEvent) -> void:
	if not pause_action_enabled:
		return

	if event.is_action_pressed("pause"):
		$PauseSfx.play()
		if is_paused:
			_close_pause()
		else:
			_open_pause()


func _open_pause() -> void:
	open_menu()


func open_menu() -> void:
	is_paused = true
	get_tree().paused = true

	visible = true

	if start_on_options:
		_show_only(options_menu)
	else:
		_show_only(pause_menu)

	_animate_panel_in()  # NOVO


func _close_pause() -> void:
	is_paused = false
	_animate_panel_out()  # NOVO (o unpause e o visible=false acontecem no final da animação)


func _show_only(menu: Control) -> void:
	pause_menu.visible = menu == pause_menu
	options_menu.visible = menu == options_menu


func _on_continue_pressed() -> void:
	$PauseSfx.play()
	await get_tree().create_timer(0.4).timeout
	_close_pause()


func _on_quit_pressed() -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file(level_select_path)


func _on_options_pressed() -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	_show_only(options_menu)


func _on_options_back_pressed() -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	if start_on_options:
		_close_pause()
	else:
		_show_only(pause_menu)


func _on_camera_pressed() -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout


func _on_camera_back_pressed() -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	_show_only(options_menu)


func _on_progress_pressed() -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout


func _on_progress_reset_confirmed() -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	ProgressManager.reset_progress()


func _on_zoom_changed(value: float) -> void:
	SettingsManager.set_camera_zoom(value)

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera != null:
		camera.zoom = Vector2(value, value)


func _on_replay_pressed() -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()

#FUNÇÃO DE ESMAECER FUNDO DESCONTINUADA
#func _on_zoom_drag_started() -> void:
#	_fade_background(0.0)


#func _on_zoom_drag_ended(_value_changed: bool) -> void:
#	_fade_background(1.0)


func _fade_background(target_alpha: float) -> void:
	if background_rect == null and background_scroll == null:
		return

	if _bg_tween != null and _bg_tween.is_valid():
		_bg_tween.kill()

	_bg_tween = create_tween()
	_bg_tween.set_parallel(true)

	if background_rect != null:
		_bg_tween.tween_property(background_rect, "modulate:a", target_alpha, 0.15)
	if background_scroll != null:
		_bg_tween.tween_property(background_scroll, "modulate:a", target_alpha, 0.15)


func _on_player_respawned() -> void:
	pause_action_enabled = true


# NOVO: animação de abertura do painel (fade + scale up)
func _animate_panel_in() -> void:
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()

	panel_container.modulate.a = 0.0
	panel_container.scale = Vector2(0.9, 0.9)

	_panel_tween = create_tween()
	_panel_tween.set_parallel(true)
	_panel_tween.tween_property(panel_container, "modulate:a", 1.0, open_close_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_panel_tween.tween_property(panel_container, "scale", Vector2.ONE, open_close_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# NOVO: animação de fechamento do painel (fade + scale down), depois desativa o pause
func _animate_panel_out() -> void:
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()

	_panel_tween = create_tween()
	_panel_tween.set_parallel(true)
	_panel_tween.tween_property(panel_container, "modulate:a", 0.0, open_close_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_panel_tween.tween_property(panel_container, "scale", Vector2(0.9, 0.9), open_close_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_panel_tween.chain().tween_callback(_finish_close)


func _finish_close() -> void:
	get_tree().paused = false
	visible = false
