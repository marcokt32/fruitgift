extends AnimatedSprite2D

## Arraste aqui a wind zone que controla esta biruta.
@export var wind_zone: Area2D


func _ready() -> void:
	play("idle")
	if wind_zone:
		wind_zone.wind_changed.connect(_on_wind_changed)


func _on_wind_changed(active: bool) -> void:
	play("move" if active else "idle")
