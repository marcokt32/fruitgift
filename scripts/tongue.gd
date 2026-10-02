extends Node2D

signal finalizado

@export var extend_time := 0.15
@export var hold_time := 0.1
@export var retract_time := 0.15
@export var dano := 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Sprite2D/Area2D


func disparar(alcance: float) -> void:
	sprite.scale.x = 0.0
	area.monitoring = false
	area.body_entered.connect(_on_body_entered)

	var tween := create_tween()
	tween.tween_property(sprite, "scale:x", alcance / sprite.texture.get_width(), extend_time)
	tween.tween_callback(func(): area.monitoring = true)
	tween.tween_interval(hold_time)
	tween.tween_callback(func(): area.monitoring = false)
	tween.tween_property(sprite, "scale:x", 0.0, retract_time)
	await tween.finished
	finalizado.emit()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(self)
