extends Area2D

@onready var detector := $CollisionShape2D

@export var one_shot = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and one_shot and monitoring:
		monitoring = false
	else:
		print(body.get_groups())

func reset():
	print("resetou")
	monitoring = true
