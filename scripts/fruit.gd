extends Area2D

signal collected

@export var fruit_sprite_frames: Array[SpriteFrames] = []
@export var pickup_sound: AudioStream
@export var pop_gravity := 900.0
@export var spawn_grace_time := 0.15
@export var fly_duration := 0.5
@export var rise_before_fly := 12.0  # sobe um pouco antes de voar pro contador
@export var counter_screen_position := Vector2(0, 0)  # ajuste manual: posição em PIXELS DE TELA (não do mundo)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var world_col: Area2D = $WorldColisor
@onready var ground_ray: RayCast2D = $GroundRay

var collected_flag: bool = false
var is_popping: bool = false
var pop_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	_randomize_sprite()
	body_entered.connect(_on_body_entered)

	set_deferred("monitoring", false)
	await get_tree().create_timer(spawn_grace_time).timeout
	set_deferred("monitoring", true)


func pop(height: float, duration: float) -> void:
	is_popping = true
	var pop_speed: float = (2.0 * height) / duration
	pop_velocity = Vector2(0, -pop_speed)


func auto_collect() -> void:
	# usado pela ItemBox: coleta sem precisar o player tocar
	if collected_flag:
		return
	_collect()


func _physics_process(delta: float) -> void:
	if not is_popping:
		return

	pop_velocity.y += gravity * delta
	global_position.y += clamp(pop_velocity.y * delta,-5,5)
	global_position.x += pop_velocity.x * delta
	
	if pop_velocity.x != 0.0:
		# Retorna uma lista com todos os corpos (TileMap, StaticBody2D, etc.) tocando na área
		var bodies = world_col.get_overlapping_bodies()
		
		# Se a lista não estiver vazia (tamanho maior que 0), há colisão
		if bodies.size() > 0:
			pop_velocity.x = 0
	
	if pop_velocity.y > 0.0:
		if ground_ray.is_colliding():
			ground_ray.force_raycast_update()
			pop_velocity.y = 0
			is_popping = false

func _randomize_sprite() -> void:
	if fruit_sprite_frames.is_empty():
		return
	var random_frames: SpriteFrames = fruit_sprite_frames[randi() % fruit_sprite_frames.size()]
	sprite.sprite_frames = random_frames
	sprite.play("idle")


func _on_body_entered(body: Node2D) -> void:
	if collected_flag:
		return

	if body.is_in_group("player"):
		_collect()


func _collect() -> void:
	if collected_flag:
		return

	collected_flag = true
	is_popping = false
	set_deferred("monitoring", false)

	if pickup_sound != null:
		var audio_player := AudioStreamPlayer2D.new()
		audio_player.stream = pickup_sound
		audio_player.global_position = global_position
		get_tree().current_scene.add_child(audio_player)
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)

	_fly_to_counter()


func _fly_to_counter() -> void:
	var start_pos: Vector2 = global_position
	var rise_pos: Vector2 = start_pos + Vector2(0, -rise_before_fly)
	var target_pos: Vector2 = _get_counter_world_position()

	var tween := create_tween()
	tween.tween_property(self, "global_position", rise_pos, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target_pos, fly_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.3, 0.3), fly_duration).set_delay(0.15)
	tween.tween_callback(_on_fly_finished)


func _on_fly_finished() -> void:
	collected.emit()
	GameEvents.register_fruit_collected()
	queue_free()


func _get_counter_world_position() -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * counter_screen_position


func schedule_auto_collect(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(self) and not collected_flag:
		auto_collect()

func scatter(velocity_impulse: Vector2) -> void:
	is_popping = true
	pop_velocity = velocity_impulse
