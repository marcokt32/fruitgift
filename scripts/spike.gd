extends CharacterBody2D

enum SpikeState { IDLE, SHAKING, FALLING, LANDED }

@export var trigger_area_path: NodePath
@export var shake_time := 0.4
@export var shake_intensity := 2.0
@export var fall_speed := 600.0
@export var gravity := 1200.0
@export var respawn_delay := 2.0

@onready var sprite: Sprite2D = $Sprite2D

var trigger_area: Area2D
var state: SpikeState = SpikeState.IDLE
var shake_elapsed: float = 0.0
var sprite_origin: Vector2
var spawn_position: Vector2
var respawn_timer: Timer


func _ready() -> void:
	sprite_origin = sprite.position
	spawn_position = global_position

	trigger_area = get_node_or_null(trigger_area_path)
	if trigger_area == null:
		set_physics_process(false)
		return

	trigger_area.body_entered.connect(_on_trigger_area_body_entered)

	respawn_timer = Timer.new()
	respawn_timer.wait_time = respawn_delay
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(respawn_timer)


func _physics_process(delta: float) -> void:
	match state:
		SpikeState.SHAKING:
			shake_elapsed += delta
			sprite.position = sprite_origin + Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)

			if shake_elapsed >= shake_time:
				sprite.position = sprite_origin
				state = SpikeState.FALLING
				trigger_area.set_deferred("monitoring", false)

		SpikeState.FALLING:
			velocity.x = 0.0  # garante que nada nunca empurre lateralmente durante a queda
			velocity.y += gravity * delta
			velocity.y = min(velocity.y, fall_speed)
			move_and_slide()

			if is_on_floor():
				state = SpikeState.LANDED
				velocity = Vector2.ZERO
				respawn_timer.start()


func _on_trigger_area_body_entered(body: Node2D) -> void:
	if state != SpikeState.IDLE:
		return

	if body.is_in_group("player"):
		state = SpikeState.SHAKING


func _on_respawn_timer_timeout() -> void:
	global_position = spawn_position
	shake_elapsed = 0.0
	sprite.position = sprite_origin
	state = SpikeState.IDLE
	trigger_area.set_deferred("monitoring", true)
