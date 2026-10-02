extends Control

@onready var name_label: Label = $DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var dialogue_text: RichTextLabel = $DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/DialogueText
@onready var portrait: TextureRect = $DialogueBox/MarginContainer/HBoxContainer/PortraitTexture

var _npc: NPC = null
var _full_text: String = ""
var _typing: bool = false

@export var typewriter_speed: float = 0.03


func setup(npc: NPC) -> void:
	_npc = npc
	if not DialogueManager.line_changed.is_connected(_on_line_changed):
		DialogueManager.line_changed.connect(_on_line_changed)

	# retrato é fixo por NPC, atualiza uma vez ao abrir o diálogo
	portrait.texture = npc.portrait_texture
	portrait.visible = npc.portrait_texture != null


func _on_line_changed(text: String, speaker_name: String) -> void:
	name_label.text = tr(speaker_name)
	_full_text = tr(text)

	dialogue_text.text = _full_text
	dialogue_text.visible_characters = 0
	_typing = true

	_type_text()


func _type_text() -> void:
	for i in range(_full_text.length() + 1):
		if not _typing:
			dialogue_text.visible_characters = -1
			return
		dialogue_text.visible_characters = i
		await get_tree().create_timer(typewriter_speed).timeout
	_typing = false


func _advance_or_skip() -> void:
	if _typing:
		_typing = false
		dialogue_text.visible_characters = -1
	else:
		DialogueManager.advance()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not event.is_action_pressed("interact"):
		return
	_advance_or_skip()


func _on_skip_button_pressed() -> void:
	_advance_or_skip()
