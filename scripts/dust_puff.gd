extends AnimatedSprite2D
# DustPuff.gd

func _ready() -> void:
	play("default")
	if has_node("ExplosionSfx"):
		$ExplosionSfx.play()
		$ExplosionSfx.finished.connect(queue_free)
		return
	if has_node("CollectSfx"):
		$CollectSfx.play()
	animation_finished.connect(queue_free)
