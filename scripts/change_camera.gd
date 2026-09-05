extends Area2D

func _on_body_entered(body: Node2D) -> void:
	body.get_node("Camera2D").limit_right = 1440
