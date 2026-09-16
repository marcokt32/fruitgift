extends AnimatedSprite2D
# DustPuff.gd

func _ready() -> void:
	animation_finished.connect(queue_free)
