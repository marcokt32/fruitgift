# dialogue_manager.gd
extends Node

signal dialogue_started(npc: NPC)
signal dialogue_ended(npc: NPC)
signal line_changed(text: String, npc_name: String)
signal dialogue_finished_all_lines
signal player_entered_range(npc: NPC)
signal player_exited_range(npc: NPC)

var current_npc: NPC = null
var _lines: Array[String] = []
var _current_index: int = 0
var is_active: bool = false

@onready var balloon_scene: PackedScene = preload("res://Prefabs/dialogue_balloon.tscn")
var _active_balloon: Node = null


func _ready() -> void:
	player_exited_range.connect(_on_player_exited_range)


func start_dialogue(npc: NPC) -> void:
	if is_active:
		return

	current_npc = npc
	_lines = npc.get_dialogue_lines()
	_current_index = 0
	is_active = true

	dialogue_started.emit(npc)

	match npc.dialogue_display:
		NPC.DialogueDisplay.HUD:
			_show_first_line()
		NPC.DialogueDisplay.BALLOON:
			_open_balloon(npc)


func _on_player_exited_range(npc: NPC) -> void:
	if npc == current_npc and is_active:
		end_dialogue()


func _open_balloon(npc: NPC) -> void:
	_active_balloon = balloon_scene.instantiate()
	npc.add_child(_active_balloon)
	_active_balloon.setup(npc)
	_show_first_line()


func _show_first_line() -> void:
	if _lines.is_empty():
		end_dialogue()
		return
	line_changed.emit(_lines[_current_index], current_npc.npc_name)


func advance() -> void:
	if not is_active:
		return

	_current_index += 1
	if _current_index >= _lines.size():
		dialogue_finished_all_lines.emit()
		end_dialogue()
		return

	line_changed.emit(_lines[_current_index], current_npc.npc_name)


func end_dialogue() -> void:
	if not is_active:
		return

	is_active = false
	if _active_balloon:
		_active_balloon.queue_free()
		_active_balloon = null

	var npc := current_npc
	current_npc = null
	dialogue_ended.emit(npc)
