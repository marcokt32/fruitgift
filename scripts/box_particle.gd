extends Node2D

@export var gravity := 700.0
@export var lifetime := 0.6

var velocity: Vector2 = Vector2.ZERO
var elapsed: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("default"):
		sprite.play("default")  # ajuste pro nome real da sua animação


func launch(direction: Vector2, speed: float, angular_speed: float) -> void:
	velocity = direction * speed
	rotation_degrees = randf_range(0, 360)
	set_meta("angular_speed", angular_speed)


func _physics_process(delta: float) -> void:
	elapsed += delta
	velocity.y += gravity * delta
	global_position += velocity * delta
	rotation += get_meta("angular_speed", 0.0) * delta
	modulate.a = clamp(1.0 - (elapsed / lifetime), 0.0, 1.0)

	if elapsed >= lifetime:
		queue_free()
