extends Area2D

@export var forward_speed := 220.0
@export var travel_time := 1.5
@export var fade_duration := 1.0
@export var level_index := 0
@export var level_data: LevelData  # NOVO: mesma resource usada no LevelCard, arraste o .tres correspondente

@onready var sprite := $AnimatedSprite2D
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect

var triggered: bool = false


func _ready() -> void:
	fade_rect.modulate.a = 0.0

	# NOVO: inicia o rastreio da fase assim que ela carrega
	if level_data != null:
		ProgressManager.start_level(level_index, {
			"fruits": level_data.total_fruits,
			"monsters": level_data.total_monsters,
			"crates": level_data.total_crates,
		})


func _on_body_entered(body: Node2D) -> void:
	sprite.play("move")

	if triggered:
		return
	if not body.is_in_group("player"):
		return

	triggered = true
	_start_sequence(body)


func _start_sequence(player: Node2D) -> void:
	if player.has_method("start_level_complete"):
		player.start_level_complete(forward_speed)

	await get_tree().create_timer(travel_time).timeout

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished

	# NOVO: fecha o registro da fase e recebe quantas estrelas o jogador fez
	var stars := ProgressManager.finish_level()
	print("Fase %d concluída com %d estrela(s)" % [level_index, stars])

	ProgressManager.complete_level(level_index)
	get_tree().change_scene_to_file("res://Prefabs/level_select.tscn")
