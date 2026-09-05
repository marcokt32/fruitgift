extends CanvasLayer

@onready var pause_menu: VBoxContainer = $PanelContainer/PauseMenu
@onready var options_menu: VBoxContainer = $PanelContainer/OptionsMenu
@onready var camera_menu: VBoxContainer = $PanelContainer/CameraMenu
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog

@onready var options_button: Button = $PanelContainer/PauseMenu/HBoxContainer/OptionsButton
@onready var continue_button: Button = $PanelContainer/PauseMenu/HBoxContainer/ContinueButton
@onready var replay_button: Button = $PanelContainer/PauseMenu/HBoxContainer/ReplayButton
@onready var quit_button: Button = $PanelContainer/PauseMenu/HBoxContainer/QuitButton

@onready var camera_button: Button = $PanelContainer/OptionsMenu/HBoxContainer/CameraButton
@onready var progress_button: Button = $PanelContainer/OptionsMenu/HBoxContainer/ProgressButton
@onready var options_back_button: Button = $PanelContainer/OptionsMenu/HBoxContainer/BackButton

@onready var camera_back_button: Button = $PanelContainer/CameraMenu/HBoxContainer/BackButton
@onready var zoom_slider: HSlider = $PanelContainer/CameraMenu/HBoxContainer/HBoxContainer/HSlider

@export var level_select_path: String = "res://Prefabs/level_select.tscn"
@export var start_on_options: bool = false
@export var show_progress_button: bool = true
@export var pause_action_enabled: bool = true

var is_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	pause_menu.visible = false
	options_menu.visible = false
	camera_menu.visible = false
	confirm_dialog.visible = false

	progress_button.visible = show_progress_button

	zoom_slider.min_value = 1.0
	zoom_slider.max_value = 1.3
	zoom_slider.step = 0.01

	options_button.pressed.connect(_on_options_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	camera_button.pressed.connect(_on_camera_pressed)
	progress_button.pressed.connect(_on_progress_pressed)
	options_back_button.pressed.connect(_on_options_back_pressed)

	camera_back_button.pressed.connect(_on_camera_back_pressed)
	zoom_slider.value_changed.connect(_on_zoom_changed)

	confirm_dialog.confirmed.connect(_on_progress_reset_confirmed)


func _unhandled_input(event: InputEvent) -> void:
	if not pause_action_enabled:
		return

	if event.is_action_pressed("pause"):
		if is_paused:
			_close_pause()
		else:
			_open_pause()


func _open_pause() -> void:
	open_menu()


func open_menu() -> void:
	is_paused = true
	get_tree().paused = true  # sem efeito real no MainMenu (nada pra pausar), mas inofensivo

	visible = true

	if start_on_options:
		_show_only(options_menu)
	else:
		_show_only(pause_menu)


func _close_pause() -> void:
	is_paused = false
	get_tree().paused = false
	visible = false


func _show_only(menu: Control) -> void:
	pause_menu.visible = menu == pause_menu
	options_menu.visible = menu == options_menu
	camera_menu.visible = menu == camera_menu


func _on_continue_pressed() -> void:
	_close_pause()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(level_select_path)


func _on_options_pressed() -> void:
	_show_only(options_menu)


func _on_options_back_pressed() -> void:
	if start_on_options:
		_close_pause()
	else:
		_show_only(pause_menu)


func _on_camera_pressed() -> void:
	_show_only(camera_menu)


func _on_camera_back_pressed() -> void:
	_show_only(options_menu)


func _on_progress_pressed() -> void:
	confirm_dialog.popup_centered()


func _on_progress_reset_confirmed() -> void:
	ProgressManager.reset_progress()


func _on_zoom_changed(value: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if camera != null:
		camera.zoom = Vector2(value, value)

func _on_replay_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
