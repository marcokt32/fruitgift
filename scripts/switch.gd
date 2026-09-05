extends Area2D

@onready var animation := $AnimationPlayer
@onready var detector := $CollisionShape2D

@export var one_shot = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if "velocity" in body and body.velocity.y > 0:
			body.velocity.y = -400
		if animation.assigned_animation == "off":
			animation.play("on")
		elif animation.assigned_animation == "on":
			animation.play("off")


	if one_shot and detector.disabled == false:
		detector.set_deferred("disabled",true)
