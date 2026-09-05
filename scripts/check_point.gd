extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("entrou")
		GameEvents.check_position = body.global_position
		set_deferred("monitoring", false)
