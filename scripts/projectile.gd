extends StaticBody2D

@export var speed := 300.0
@export var lifetime := 3.0

var velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func launch(direction: Vector2) -> void:
	velocity = direction.normalized() * speed
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	global_position += velocity * delta


func _on_area_2d_body_entered(_body: Node2D) -> void:
	queue_free()
