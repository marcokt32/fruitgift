extends AnimatableBody2D

@onready var timer: Timer = $Timer

@export var point_a_path: NodePath
@export var point_b_path: NodePath
@export var speed := 100.0
@export var wait_time := 2.0

var is_waiting: bool = false
var pos_a: Vector2
var pos_b: Vector2
var target: Vector2


func _ready() -> void:
	pos_a = get_node(point_a_path).global_position
	pos_b = get_node(point_b_path).global_position

	global_position = pos_a
	target = pos_b

	timer.one_shot = true

	_wait()  # espera 2s antes do primeiro movimento


func _physics_process(delta: float) -> void:
	if is_waiting:
		return  # não anda enquanto estiver esperando

	var to_target: Vector2 = target - global_position
	var distance: float = to_target.length()

	if distance < 2.0:
		global_position = target  # encaixa exatamente no alvo, sem sobra
		_wait()
	else:
		var step: Vector2 = to_target.normalized() * speed * delta
		if step.length() > distance:
			step = to_target
		global_position += step


func _wait() -> void:
	is_waiting = true
	timer.start(wait_time)


func _change_target() -> void:
	target = pos_a if target == pos_b else pos_b


func _on_timer_timeout() -> void:
	is_waiting = false
	_change_target()
