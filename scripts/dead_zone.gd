extends Area2D

@onready var pause_instance = $"../Pause"

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not body.is_dead:
		print(body.is_dead)
		body._die()
		pause_instance.pause_action_enabled = false
