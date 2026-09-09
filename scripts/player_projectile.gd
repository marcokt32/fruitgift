extends Area2D

@export var speed := 550.0
@export var lifetime := 2.0
@export var blink_interval := 0.1  # segundos entre cada troca de cor

var velocity: Vector2 = Vector2.ZERO
var _blink_timer := 0.0
var _is_yellow := true


func _process(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer >= blink_interval:
		_blink_timer = 0.0
		_is_yellow = not _is_yellow
		modulate = Color.YELLOW if _is_yellow else Color.RED


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
