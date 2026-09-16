extends Node2D

@onready var panel: PanelContainer = $PanelContainer
@onready var label: RichTextLabel = $PanelContainer/MarginContainer/Label

var _npc: NPC = null
var _full_text: String = ""
var _typing: bool = false

@export var typewriter_speed: float = 0.03
@export var balloon_bottom_offset: float = -20.0
@export var auto_advance_reading_time_per_char: float = 0.05  # segundos por caractere, após terminar de digitar
@export var auto_advance_min_delay: float = 1.0  # tempo mínimo de leitura, mesmo pra falas curtas


func setup(npc: NPC) -> void:
	_npc = npc
	DialogueManager.line_changed.connect(_on_line_changed)


func _on_line_changed(text: String, speaker_name: String) -> void:
	_full_text = text
	label.visible_characters = 0
	label.text = text
	_typing = true
	_type_text()

	await get_tree().process_frame
	_reposition_balloon()


func _reposition_balloon() -> void:
	var panel_height := panel.size.y
	panel.position.y = -panel_height


func _type_text() -> void:
	for i in range(_full_text.length() + 1):
		if not _typing:
			label.visible_characters = -1
			break
		label.visible_characters = i
		await get_tree().create_timer(typewriter_speed).timeout
	_typing = false

	# se o NPC é automático, avança sozinho depois de dar tempo de leitura
	if _npc and _npc.interaction_mode == NPC.InteractionMode.AUTOMATIC:
		_auto_advance()


func _auto_advance() -> void:
	var reading_time: float = max(auto_advance_min_delay, _full_text.length() * auto_advance_reading_time_per_char)
	await get_tree().create_timer(reading_time).timeout

	# proteção: se o diálogo já foi encerrado ou a fala mudou nesse meio tempo, não avança
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
