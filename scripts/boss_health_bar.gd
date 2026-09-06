extends CanvasLayer

## Aponte para o node do boss (CharacterBody2D) na cena.
@export var boss_path: NodePath
@export var fade_duration := 0.4

@onready var bar: ProgressBar = $Control/Bar
@onready var control: Control = $Control

var boss: Node = null


func _ready() -> void:
	control.modulate.a = 0.0
	visible = false
	if boss_path != NodePath():
		boss = get_node_or_null(boss_path)
	if boss:
		boss.activated.connect(_on_boss_activated)
		boss.health_changed.connect(_on_health_changed)
		boss.defeated.connect(_on_boss_defeated)
		boss.boss_reset.connect(_on_boss_defeated)


func _on_boss_activated() -> void:
	if boss:
		bar.max_value = boss.max_health
		bar.value = boss.health
	visible = true
	var tween := create_tween()
	tween.tween_property(control, "modulate:a", 1.0, fade_duration)


func _on_health_changed(current: float, max_health: float) -> void:
	bar.max_value = max_health
	var tween := create_tween()
	tween.tween_property(bar, "value", current, 0.25)


func _on_boss_defeated() -> void:
	var tween := create_tween()
	tween.tween_property(control, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(func(): visible = false)
