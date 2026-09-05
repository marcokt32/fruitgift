extends StaticBody2D

signal item_spawned

@export_enum("Padrão:0", "Metálica:1", "Coração:2") var box_skin: int = 0
@export var item_scene: PackedScene
@export var item_count := 1
@export var pop_height := 20.0
@export var pop_duration := 0.2
@export var hit_cooldown := 0.3

@export var particle_scene: PackedScene
@export var particle_speed := 150.0
@export var particle_gravity := 700.0
@export var particle_lifetime := 0.6

@export var spawn_all_at_once := false
@export var scatter_horizontal_range := Vector2(80.0, 160.0)  # min/max velocidade horizontal
@export var scatter_vertical_speed := 300.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bump_area_up: Area2D = $BumpAreaUp
@onready var bump_area_down: Area2D = $BumpAreaDown
@onready var spawn_point: Marker2D = $SpawnPoint

var items_remaining: int
var can_hit: bool = true
var finished: bool = false


func _ready() -> void:
	items_remaining = item_count
	if sprite.animation_finished.is_connected(_on_animation_finished) == false:
		sprite.animation_finished.connect(_on_animation_finished)
	_play_if_exists("idle")

func _process(_delta: float) -> void:
	_set_animation()


func _on_bump_area_up_body_entered(body: Node2D) -> void:
	if not can_hit or finished:
		return
	if not body.is_in_group("player"):
		return
	if "velocity" in body and body.velocity.y >= -0.1:
		body.velocity.y = -400
		_hit()


func _on_bump_area_down_body_entered(body: Node2D) -> void:
	if not can_hit or finished:
		return
	if not body.is_in_group("player"):
		return
	if "velocity" in body and body.velocity.y < 0.1:
		_hit()


func _hit() -> void:
	if items_remaining <= 0:
		return

	can_hit = false

	if spawn_all_at_once:
		_spawn_all_scattered()
		_finish()
	else:
		items_remaining -= 1
		var is_last: bool = items_remaining <= 0

		_play_if_exists("hit")
		_spawn_item()

		if is_last:
			_finish()
		else:
			_start_cooldown()


func _spawn_item() -> void:
	if item_scene == null:
		return

	var item := item_scene.instantiate()
	get_tree().current_scene.add_child.call_deferred(item)

	var spawn_position: Vector2 = spawn_point.global_position if spawn_point != null else global_position
	item.global_position = spawn_position

	if item.has_method("pop"):
		item.pop(pop_height, pop_duration)

	if item.has_method("schedule_auto_collect"):
		item.schedule_auto_collect(pop_duration)  # sem "await" aqui -- não bloqueia, não depende da ItemBox

	item_spawned.emit()


func _start_cooldown() -> void:
	await get_tree().create_timer(hit_cooldown).timeout
	can_hit = true


func _finish() -> void:
	finished = true
	bump_area_up.set_deferred("monitoring", false)
	bump_area_down.set_deferred("monitoring", false)
	_spawn_burst_particles()
	queue_free()


func _on_animation_finished() -> void:
	if sprite.animation == "hit" and not finished:
		_play_if_exists("idle")


func _spawn_burst_particles() -> void:
	if particle_scene == null:
		return

	var origin: Vector2 = spawn_point.global_position if spawn_point != null else global_position

	var directions: Array[Vector2] = [
		Vector2(-1, -1).normalized(),
		Vector2(1, -1).normalized(),
		Vector2(1, 1).normalized(),
		Vector2(-1, 1).normalized(),
	]

	for dir in directions:
		var particle := particle_scene.instantiate()
		get_tree().current_scene.add_child(particle)
		particle.global_position = origin

		if "gravity" in particle:
			particle.gravity = particle_gravity
		if "lifetime" in particle:
			particle.lifetime = particle_lifetime

		if particle.has_method("launch"):
			var angular: float = randf_range(-10.0, 10.0)
			particle.launch(dir, particle_speed, angular)


func _default_particle_texture() -> ImageTexture:
	var img := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


func _play_if_exists(anim_name: String) -> void:
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func take_projectile_hit() -> void:
	if not can_hit or finished:
		return
	_hit()

func _spawn_all_scattered() -> void:
	_play_if_exists("hit")

	for i in items_remaining:
		_spawn_scattered_item()

	items_remaining = 0


func _spawn_scattered_item() -> void:
	if item_scene == null:
		return

	var item := item_scene.instantiate()
	get_tree().current_scene.add_child.call_deferred(item)

	var spawn_position: Vector2 = spawn_point.global_position if spawn_point != null else global_position
	item.global_position = spawn_position

	if item.has_method("scatter"):
		var horizontal: float = randf_range(scatter_horizontal_range.x, scatter_horizontal_range.y)
		horizontal *= 1 if randf() > 0.5 else -1  # metade vai pra esquerda, metade pra direita, aleatoriamente
		var impulse: Vector2 = Vector2(horizontal, -scatter_vertical_speed)
		item.scatter(impulse)

	item_spawned.emit()

func _set_animation() -> void:
	var anim: String = "idle"
	
	if box_skin == 0:
		anim = "idle"
	if box_skin == 1:
		anim = "idle1"
	if box_skin == 2:
		anim = "idle2"

	if sprite.animation != anim:
		sprite.play(anim)
