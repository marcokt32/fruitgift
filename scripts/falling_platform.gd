extends CharacterBody2D

enum PlatformState { IDLE, SHAKING, FALLING }

@export var trigger_area_path: NodePath
@export var shake_time := 0.4
@export var shake_intensity := 2.0
@export var gravity := 900.0
@export var fall_max_speed := 500.0
@export var respawn_delay := 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var trigger_area: Area2D
var state: PlatformState = PlatformState.IDLE
var shake_elapsed: float = 0.0
var sprite_origin: Vector2
var spawn_position: Vector2
var respawn_timer: Timer

const WORLD_LAYER_BIT := 1  # ajuste pro número real da sua layer "world" no projeto


func _ready() -> void:
	sprite_origin = sprite.position
	spawn_position = global_position

	trigger_area = get_node_or_null(trigger_area_path)
	if trigger_area == null:
		push_error("FallingPlatform: Trigger Area Path não configurado no Inspector!")
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
		PlatformState.SHAKING:
			shake_elapsed += delta
			sprite.position = sprite_origin + Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)

			if shake_elapsed >= shake_time:
				sprite.position = sprite_origin
				_start_falling()

		PlatformState.FALLING:
			velocity.y = min(velocity.y + gravity * delta, fall_max_speed)
			global_position += velocity * delta  # sem move_and_slide: já não colide com nada


func _start_falling() -> void:
	state = PlatformState.FALLING
	trigger_area.set_deferred("monitoring", false)

	# desliga só o bit de "world" -> passa a atravessar chão/paredes livremente
	set_collision_layer_value(WORLD_LAYER_BIT, false)

	respawn_timer.start()


func _on_trigger_area_body_entered(body: Node2D) -> void:
	if state != PlatformState.IDLE:
		return

	if body.is_in_group("player"):
		if "velocity" in body and body.velocity.y >= -0.1:
			state = PlatformState.SHAKING


func _on_respawn_timer_timeout() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	shake_elapsed = 0.0
	sprite.position = sprite_origin

	set_collision_layer_value(WORLD_LAYER_BIT, true)  # volta a ser sólida
	trigger_area.set_deferred("monitoring", true)

	state = PlatformState.IDLE
