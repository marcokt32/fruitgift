extends CanvasLayer

@export var flash_duration: float = 0.08   # tempo até o branco sumir
@export var max_alpha: float = 1.0         # opacidade máxima do flash (0.0 a 1.0)

@onready var texture_rect: TextureRect = $TextureRect

var _tween: Tween


func _ready() -> void:
	texture_rect.modulate.a = 0.0
	GameEvents.player_damaged.connect(flash)


func flash() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	texture_rect.modulate.a = max_alpha
	_tween = create_tween()
	_tween.tween_property(texture_rect, "modulate:a", 0.0, flash_duration)
