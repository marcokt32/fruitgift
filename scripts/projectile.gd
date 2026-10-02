extends StaticBody2D

@export var speed := 300.0
@export var lifetime := 3.0
@export var blink_interval := 0.1  # segundos entre cada troca de cor

var velocity: Vector2 = Vector2.ZERO
var _blink_timer := 0.0
var _is_yellow := true


func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func launch(direction: Vector2) -> void:
	velocity = direction.normalized() * speed
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer >= blink_interval:
		_blink_timer = 0.0
		_is_yellow = not _is_yellow
		modulate = Color.YELLOW if _is_yellow else Color.RED
	global_position += velocity * delta


func _on_area_2d_body_entered(_body: Node2D) -> void:
	queue_free()
