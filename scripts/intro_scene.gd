extends Node2D

## Lista de beats na ordem em que devem tocar.
## Cada item é um Resource do tipo IntroBeat (crie-os pelo Inspector).
@export var beats: Array[IntroBeat] = []

## Caminho da cena para onde ir depois da intro (ou ao pular)
@export_file("*.tscn") var next_scene_path: String = ""

@onready var camera: Camera2D = $Camera2D
@onready var art_sprite: Sprite2D = $ArtSprite
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var text_label: RichTextLabel = $CanvasLayer/TextBox/TextLabel
@onready var skip_button: Button = $CanvasLayer/SkipButton

var _skip_requested := false


func _ready() -> void:
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 1.0  # começa tudo escuro
	text_label.bbcode_enabled = true
	text_label.text = ""
	text_label.visible_ratio = 0.0

	skip_button.pressed.connect(_on_skip_pressed)

	_play_intro()


func _on_skip_pressed() -> void:
	_skip_requested = true
	# mata qualquer tween em andamento imediatamente
	for tw in get_tree().get_processed_tweens():
		tw.kill()
	_go_to_next_scene()


func _play_intro() -> void:
	for beat in beats:
		if _skip_requested:
			return
		await _play_beat(beat)

	if not _skip_requested:
		_go_to_next_scene()


func _go_to_next_scene() -> void:
	ProgressManager.mark_intro_seen()
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)

func _play_beat(beat: IntroBeat) -> void:
	if beat.texture:
		art_sprite.texture = beat.texture

	# 1) calcula quanto tempo a digitação vai levar, pra saber a duração total do beat
	var typing_duration := 0.0
	if beat.text_speed > 0.0:
		typing_duration = beat.text.length() / beat.text_speed

	# 2) dispara o movimento (câmera ou sprite) já de cara, sem esperar o fade in.
	#    Ele roda durante o fade in inteiro + a digitação inteira, percorrendo
	#    exatamente move_distance pixels na direção escolhida.
	var move_node: Node2D = null
	match beat.move_target:
		IntroBeat.MoveTarget.CAMERA:
			move_node = camera
		IntroBeat.MoveTarget.SPRITE:
			move_node = art_sprite

	var move_duration := beat.fade_in_duration + typing_duration

	if move_node != null and beat.direction != Vector2.ZERO and move_duration > 0.0:
		var offset := beat.direction.normalized() * beat.move_distance
		var move_tween := create_tween()
		move_tween.tween_property(
			move_node, "position", move_node.position + offset, move_duration
		)

	# 3) acende lentamente (escuro -> claro) — roda em paralelo com o movimento acima
	await _fade(0.0, beat.fade_in_duration)
	if _skip_requested:
		return

	# 4) digita o texto
	await _type_text(beat.text, beat.text_speed)
	if _skip_requested:
		return

	# 5) segura a cena parada por um tempinho
	if beat.hold_time > 0.0:
		await get_tree().create_timer(beat.hold_time).timeout
		if _skip_requested:
			return

	# 6) escurece de novo e limpa o texto
	# (o movimento já terminou nesse ponto, pois move_duration = fade_in + digitação)
	await _fade(1.0, beat.fade_out_duration)
	text_label.text = ""
	text_label.visible_ratio = 0.0


func _fade(target_alpha: float, duration: float) -> void:
	if duration <= 0.0:
		fade_rect.modulate.a = target_alpha
		return
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", target_alpha, duration)
	await tw.finished


func _type_text(text: String, speed: float) -> void:
	text_label.text = text
	text_label.visible_ratio = 0.0

	if speed <= 0.0 or text.length() == 0:
		text_label.visible_ratio = 1.0
		return

	var duration := text.length() / speed
	var tw := create_tween()
	tw.tween_property(text_label, "visible_ratio", 1.0, duration)
	await tw.finished
