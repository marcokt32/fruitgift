extends CanvasLayer

@export var record: LevelData
@export var fade_duration := 1.0
@export var slide_in_duration := 0.5
@export var hold_duration := 2.0
@export var slide_out_duration := 0.5

@onready var fade_rect: ColorRect = $FadeRect
@onready var banner: Control = $Banner
@onready var name_label: Label = %NameLabel
@onready var fruits_label: Label = %FruitLabel
@onready var monsters_label: Label = %MonsterLabel
@onready var coins_label: Label = %CoinsLabel


func _ready() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	_update_progress_display()

	# estado inicial: tela preta, banner escondido à esquerda, fora da tela
	fade_rect.modulate.a = 1.0
	banner.position.x = -banner.size.x

	_play_intro()


func _play_intro() -> void:
	# 1. Tela clareia E banner desliza pra dentro, ao mesmo tempo
	var fade_tween := create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	await get_tree().create_timer(.5).timeout

	var slide_in := create_tween()
	slide_in.tween_property(banner, "position:x", 0.0, slide_in_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# espera o mais longo dos dois terminar
	await get_tree().create_timer(max(fade_duration, slide_in_duration)).timeout

	# 2. Segura o nome na tela por alguns segundos
	await get_tree().create_timer(hold_duration).timeout

	# 3. Banner desliza de volta pra fora, à esquerda
	var slide_out := create_tween()
	slide_out.tween_property(banner, "position:x", -banner.size.x, slide_out_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await slide_out.finished

	queue_free()


func _update_progress_display() -> void:
	if record == null:
		name_label.text = ""
		fruits_label.text = ""
		monsters_label.text = ""
		coins_label.text = ""
		return

	name_label.text = tr(record.level_name)
	fruits_label.text = "%s: %d" % [tr("HUD_FRUITS"), record.total_fruits]
	monsters_label.text = "%s: %d" % [tr("HUD_MONSTERS"), record.total_monsters]
	coins_label.text = "%s: %d/%d" % [
		tr("HUD_COINS"),
		ProgressManager.get_level_coins_count(record.level_index),
		record.total_coins,
	]
