extends Node2D

@onready var panel: PanelContainer = $PanelContainer
@onready var label: RichTextLabel = $PanelContainer/MarginContainer/Label

var _npc: NPC = null
var _full_text: String = ""
var _typing: bool = false

@export var typewriter_speed: float = 0.03
@export var balloon_bottom_offset: float = -20.0
@export var auto_advance_reading_time_per_char: float = 0.05
@export var auto_advance_min_delay: float = 1.0


func _ready() -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.fit_content = true
	label.scroll_active = false

func setup(npc: NPC) -> void:
	_npc = npc

	if not DialogueManager.line_changed.is_connected(_on_line_changed):
		DialogueManager.line_changed.connect(_on_line_changed)


func _on_line_changed(text: String, speaker_name: String) -> void:
	_full_text = tr(text)

	label.text = _full_text
	label.visible_characters = 0
	_typing = true

	await get_tree().process_frame

	# Atualiza o tamanho do painel de acordo com o texto
	var min_size := panel.get_combined_minimum_size()
	panel.size.y = min_size.y


	_type_text()
	_reposition_balloon()


func _reposition_balloon() -> void:
	var panel_height: float = panel.size.y
	panel.position.y = -panel_height + balloon_bottom_offset


func _type_text() -> void:
	for i in range(_full_text.length() + 1):
		if not _typing:
			label.visible_characters = -1
			return

		label.visible_characters = i
		await get_tree().create_timer(typewriter_speed).timeout

	_typing = false

	if _npc and _npc.interaction_mode == NPC.InteractionMode.AUTOMATIC:
		_auto_advance()


func _auto_advance() -> void:
	var reading_time: float = max(
		auto_advance_min_delay,
		_full_text.length() * auto_advance_reading_time_per_char
	)

	await get_tree().create_timer(reading_time).timeout

	if not is_instance_valid(self) or _typing:
		return

	DialogueManager.advance()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	if _typing:
		_typing = false
		label.visible_characters = -1

	elif _npc and _npc.interaction_mode == NPC.InteractionMode.BUTTON_PROMPT:
		DialogueManager.advance()
