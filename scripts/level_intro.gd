extends CanvasLayer

@export var level_data: LevelData
@export var fade_duration := 1.0
@export var slide_in_duration := 0.5
@export var hold_duration := 2.0
@export var slide_out_duration := 0.5

@onready var fade_rect: ColorRect = $FadeRect
@onready var banner: Control = $Banner
@onready var name_label: Label = $Banner/PanelContainer/VBoxContainer/Panel/NameLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	name_label.text = level_data.level_name if level_data != null else ""

	# estado inicial: tela preta, banner escondido à esquerda, fora da tela
	fade_rect.modulate.a = 1.0
	banner.position.x = -banner.size.x

	_play_intro()


func _play_intro() -> void:
	# 1. Tela clareia devagar
	var fade_tween := create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	await fade_tween.finished

	# 2. Banner desliza da esquerda pra dentro da tela
	var slide_in := create_tween()
	slide_in.tween_property(banner, "position:x", 0.0, slide_in_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await slide_in.finished

	# 3. Segura o nome na tela por alguns segundos
	await get_tree().create_timer(hold_duration).timeout

	# 4. Banner desliza de volta pra fora, à esquerda
	var slide_out := create_tween()
	slide_out.tween_property(banner, "position:x", -banner.size.x, slide_out_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await slide_out.finished

	queue_free()
