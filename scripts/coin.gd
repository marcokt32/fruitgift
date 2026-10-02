extends Area2D
class_name Coin

@export var level_data: LevelData
@export var coin_id: int = 0

@export_group("Animações")
@export var idle_animation: StringName = &"default"
@export var collected_animation: StringName = &"collected"

@export_group("Flutuar")
@export var float_amplitude: float = 4.0   # quanto sobe e desce (pixels)
@export var float_duration: float = 0.8    # tempo de cada subida/descida

@export_group("Posicionamento")
@export var snap_to_ground: bool = true
@export var hover_height: float = 16.0
@export_group("Já coletada")
@export_range(0.0, 1.0) var ghost_alpha: float = 0.35

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var ground_ray: RayCast2D = $GroundRay
@onready var collected_sfx: AudioStreamPlayer2D = $CollectedSfx

var _collected := false
var _float_tween: Tween
var _is_ghost := false


func _ready() -> void:
	# Pega o level_data do pai (ex: node Coins com script), se não foi definido na moeda
	if level_data == null and get_parent().get("level_data") != null:
		level_data = get_parent().get("level_data")

	if level_data == null:
		push_warning("Coin '%s' sem level_data" % name)
	elif ProgressManager.is_coin_collected(level_data.level_index, coin_id):
		_become_ghost()

	if snap_to_ground:
		_snap_to_ground()

	sprite.play(idle_animation)
	if not _is_ghost:
		body_entered.connect(_on_body_entered)
	_start_floating()

func _become_ghost() -> void:
	_is_ghost = true
	sprite.modulate.a = ghost_alpha
	collision.set_deferred("disabled", true)


func _snap_to_ground() -> void:
	ground_ray.force_raycast_update()
	if ground_ray.is_colliding():
		var ground_y := ground_ray.get_collision_point().y
		global_position.y = ground_y - hover_height


func _start_floating() -> void:
	var base_y := sprite.position.y

	# Atraso aleatório pra moedas não flutuarem todas sincronizadas
	await get_tree().create_timer(randf() * float_duration).timeout
	if _collected or not is_inside_tree():
		return

	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(sprite, "position:y", base_y - float_amplitude, float_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_float_tween.tween_property(sprite, "position:y", base_y + float_amplitude, float_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return
	_collect()


func _collect() -> void:
	_collected = true

	ProgressManager.collect_coin(coin_id)

	collision.set_deferred("disabled", true)
	if _float_tween != null:
		_float_tween.kill()

	collected_sfx.play()

	if sprite.sprite_frames.has_animation(collected_animation):
		sprite.play(collected_animation)
		await sprite.animation_finished
	sprite.hide()

	# Espera o som terminar, se ainda estiver tocando
	if collected_sfx.playing:
		await collected_sfx.finished
	queue_free()
