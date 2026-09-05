extends Area2D

@onready var pause_instance = $"../Pause"

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body._die()
		pause_instance.pause_action_enabled = false
