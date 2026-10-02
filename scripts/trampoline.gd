extends StaticBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var jump_force: int = 650


func _set_animation() -> void:
	var anim := "idle"

	if sprite.animation != anim:
		sprite.play(anim)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.velocity.y = -jump_force
		$SpringSfx.play()
		sprite.play("jump")
