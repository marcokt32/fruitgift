extends Area2D

@onready var detector := $CollisionShape2D

@export var one_shot = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and one_shot and detector.disabled == false:
		detector.set_deferred("disabled",true)
