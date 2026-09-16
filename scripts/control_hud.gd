extends CanvasLayer

@onready var left_button: Button = $Root/LeftButton
@onready var right_button: Button = $Root/RightButton
@onready var jump_button: Button = $Root/JumpButton
@onready var shoot_button: Button = $Root/ShootButton
@onready var pause_button: Button = $Root/PauseButton
@onready var interact_button: Button = $InteractButton
@onready var full_dialogue_ui: Control = $FullDialogueUI  # cena de HUD cheio, já instanciada e escondida

var _pending_npc: NPC = null

func _ready() -> void:
	visible = true
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

	interact_button.visible = false
	interact_button.pressed.connect(_on_interact_button_pressed)

	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.player_entered_range.connect(show_interact_prompt)
	DialogueManager.player_exited_range.connect(hide_interact_prompt)


## Chamado externamente pelo NPC (via sinal player_entered_range/player_exited_range)
func show_interact_prompt(npc: NPC) -> void:
	if npc.interaction_mode != npc.InteractionMode.BUTTON_PROMPT:
		return
	_pending_npc = npc
	interact_button.visible = true


func hide_interact_prompt(npc: NPC) -> void:
	if _pending_npc == npc:
		_pending_npc = null
		interact_button.visible = false


func _on_interact_button_pressed() -> void:
	if _pending_npc:
		_pending_npc.request_dialogue()


func _on_dialogue_started(npc: NPC) -> void:
	interact_button.visible = false
	if npc.dialogue_display == NPC.DialogueDisplay.HUD:
		full_dialogue_ui.visible = true
		full_dialogue_ui.setup(npc) # a cena de HUD escuta DialogueManager.line_changed


func _on_dialogue_ended(npc: NPC) -> void:
	full_dialogue_ui.visible = false


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
