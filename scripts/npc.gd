class_name NPC
extends StaticBody2D

enum InteractionMode { BUTTON_PROMPT, AUTOMATIC }
enum DialogueDisplay { HUD, BALLOON }

@export_group("Skin")
@export var skin_texture: Texture2D:
	set(value):
		skin_texture = value
		_update_sprite()
@export var hframes: int = 11:
	set(value):
		hframes = value
		_update_sprite()
@export var vframes: int = 1:
	set(value):
		vframes = value
		_update_sprite()

@export_group("Interação")
@export var interaction_mode: InteractionMode = InteractionMode.BUTTON_PROMPT
@export var dialogue_display: DialogueDisplay = DialogueDisplay.BALLOON
@export var npc_name: String = "NPC"
@export var dialogue_lines: Array[String] = []
@export var can_repeat: bool = true
@export var portrait_texture: Texture2D  # retrato grande pro diálogo

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_area: Area2D = $InteractionArea

var _player_in_range: Node2D = null
var _has_talked: bool = false

signal dialogue_requested(npc: NPC)


func _ready() -> void:
	_update_sprite()

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

	if animation_player.has_animation("idle"):  # ajuste pro nome real da sua animação
		animation_player.play("idle")


## Mantém o Sprite2D sempre sincronizado com texture/hframes/vframes,
## seja no editor (ao trocar valores no Inspector) ou em runtime (_ready)
func _update_sprite() -> void:
	if not sprite:
		return
	if skin_texture:
		sprite.texture = skin_texture
	sprite.hframes = hframes
	sprite.vframes = vframes


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = body

	if interaction_mode == InteractionMode.AUTOMATIC:
		_try_start_dialogue()
	else:
		DialogueManager.player_entered_range.emit(self)  # control_hud escuta isso pra mostrar o botão


func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		DialogueManager.player_exited_range.emit(self)  # control_hud escuta isso pra esconder o botão


func _try_start_dialogue() -> void:
	if _has_talked and not can_repeat:
		return
	if DialogueManager.is_active:
		return
	_has_talked = true
	DialogueManager.start_dialogue(self)


## Chamado externamente (pelo control_hud) quando o player aperta o botão
func request_dialogue() -> void:
	if _player_in_range == null:
		return
	_try_start_dialogue()


func get_dialogue_lines() -> Array[String]:
	return dialogue_lines


func has_player_in_range() -> bool:
	return _player_in_range != null
