extends CanvasLayer

@onready var left_button: Button = $Root/LeftButton
@onready var right_button: Button = $Root/RightButton
@onready var jump_button: Button = $Root/JumpButton
@onready var shoot_button: Button = $Root/ShootButton
@onready var pause_button: Button = $Root/PauseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	#visible = DisplayServer.is_touchscreen_available()

	left_button.button_down.connect(_on_left_pressed)
	left_button.button_up.connect(_on_left_released)

	right_button.button_down.connect(_on_right_pressed)
	right_button.button_up.connect(_on_right_released)

	jump_button.button_down.connect(_on_jump_pressed)
	jump_button.button_up.connect(_on_jump_released)

	shoot_button.button_down.connect(_on_shoot_pressed)
	shoot_button.button_up.connect(_on_shoot_released)

	pause_button.pressed.connect(_on_pause_pressed)


func _on_left_pressed() -> void:
	Input.action_press("ui_left")


func _on_left_released() -> void:
	Input.action_release("ui_left")


func _on_right_pressed() -> void:
	Input.action_press("ui_right")


func _on_right_released() -> void:
	Input.action_release("ui_right")


func _on_jump_pressed() -> void:
	Input.action_press("jump")


func _on_jump_released() -> void:
	Input.action_release("jump")


func _on_shoot_pressed() -> void:
	Input.action_press("shoot")


func _on_shoot_released() -> void:
	Input.action_release("shoot")


func _on_pause_pressed() -> void:
	var event := InputEventAction.new()
	event.action = "pause"
	event.pressed = true
	Input.parse_input_event(event)
