extends Area2D

@export var forward_speed := 0.0           # NOVO: default 0, já que a fruta não empurra o player
@export var travel_time := 1.5
@export var fade_duration := 1.0
@export var level_data: LevelData          # substitui o level_index solto
@export var power_data: PowerData
@export var collect_popup_scene: PackedScene

@export var rise_height := 40.0
@export var rise_duration := 1.2
@export var rise_ease := Tween.EASE_OUT
@export var rise_trans := Tween.TRANS_SINE

@onready var sprite := $AnimatedSprite2D
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect

var triggered: bool = false


func _ready() -> void:
	fade_rect.modulate.a = 0.0
	monitoring = false
	monitorable = false

	if level_data != null:
		ProgressManager.start_level(level_data.level_index, {
			"fruits": level_data.total_fruits,
			"monsters": level_data.total_monsters,
			"crates": level_data.total_crates,
		})


func collect(player: Node2D = null) -> void:
	if triggered:
		return
	triggered = true
	_start_sequence(player)


func _start_sequence(player: Node2D) -> void:
	await _show_collect_popup()

	if player and player.has_method("start_level_complete"):
		player.start_level_complete(forward_speed)

	_play_sacred_rise()

	await get_tree().create_timer(travel_time).timeout

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished

	if power_data != null and power_data.fruit_id >= 0:
		ProgressManager.collect_golden_fruit(power_data.fruit_id)
		if player and player.has_method("grant_power"):
			player.grant_power(power_data.fruit_id)

	var stars := ProgressManager.finish_level()
	print("Fase %d concluída com %d estrela(s)" % [level_data.level_index, stars])

	ProgressManager.complete_level(level_data.level_index)
	get_tree().change_scene_to_file("res://Prefabs/level_select.tscn")


func _play_sacred_rise() -> void:
	var rise_tween := create_tween()
	rise_tween.set_ease(rise_ease)
	rise_tween.set_trans(rise_trans)
	rise_tween.tween_property(self, "position:y", position.y - rise_height, rise_duration)

	var pulse_tween := create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(sprite, "scale", Vector2(1.08, 1.08), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _show_collect_popup() -> void:
	if collect_popup_scene == null or power_data == null:
		return
	var popup = collect_popup_scene.instantiate()
	get_tree().root.add_child(popup)
	popup.setup(power_data)
	await popup.closed
