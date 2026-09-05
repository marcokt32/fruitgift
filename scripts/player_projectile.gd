extends Area2D

@export var speed := 550.0
@export var lifetime := 2.0

var velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func launch(direction: Vector2) -> void:
	velocity = direction.normalized() * speed
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	global_position += velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_projectile_hit"):
		body.take_projectile_hit()
		queue_free()
		return

	if body.is_in_group("item_box") and body.has_method("take_projectile_hit"):
		body.take_projectile_hit()
		queue_free()
		return

	queue_free()
