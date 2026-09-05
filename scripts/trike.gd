extends AnimatableBody2D

enum RockState { MOVING, IMPACT, IDLE }

@export var point_a_path: NodePath
@export var point_b_path: NodePath
@export var start_speed := 60.0
@export var max_speed := 400.0
@export var acceleration := 80.0
@export var idle_duration := 0.6
@export var impact_fallback_duration := 0.3

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var pos_a: Vector2
var pos_b: Vector2
var target: Vector2
var current_speed: float
var state: RockState = RockState.MOVING


func _ready() -> void:
	pos_a = get_node(point_a_path).global_position
	pos_b = get_node(point_b_path).global_position

	global_position = pos_a
	target = pos_b
	current_speed = start_speed

	if sprite != null:
		sprite.animation_finished.connect(_on_animation_finished)

	_play_if_exists("move")


func _physics_process(delta: float) -> void:
	if state != RockState.MOVING:
		return

	current_speed = min(current_speed + acceleration * delta, max_speed)

	var to_target: Vector2 = target - global_position
	var distance: float = to_target.length()

	if distance < 2.0:
		global_position = target
		_start_impact()
	else:
		var step: Vector2 = to_target.normalized() * current_speed * delta
		if step.length() > distance:
			step = to_target
		global_position += step


func _start_impact() -> void:
	state = RockState.IMPACT

	if _has_animation("impact"):
		sprite.play("impact")
	else:
		await get_tree().create_timer(impact_fallback_duration).timeout
		_go_idle()


func _on_animation_finished() -> void:
	if state == RockState.IMPACT and sprite.animation == "impact":
		_go_idle()


func _go_idle() -> void:
	state = RockState.IDLE
	_play_if_exists("idle")
	await get_tree().create_timer(idle_duration).timeout
	_start_next_leg()


func _start_next_leg() -> void:
	target = pos_a if target == pos_b else pos_b
	current_speed = start_speed
	state = RockState.MOVING
	_play_if_exists("move")


func _has_animation(anim_name: String) -> bool:
	return sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim_name)


func _play_if_exists(anim_name: String) -> void:
	if _has_animation(anim_name):
		sprite.play(anim_name)
