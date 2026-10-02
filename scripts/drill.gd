extends CharacterBody2D

@export var flying: bool = false

@export var edge_ray_offset_x := 16.0
@export var edge_ray_offset_y := 20.0
@export var wall_ray_offset_x := 20.0
@export var wall_ray_offset_y := 0.0
@export var health := 1.0
@export var irritable : bool = false
@export var edge_ray_active : bool = true

# ================== PATROL ==================
@export var patrol : bool = false
@export var marker_a: Marker2D
@export var marker_b: Marker2D
@export var patrol_arrive_threshold := 4.0

# ================== MOVIMENTO / DASH ==================
@export var speed := 60.0
@export var dash_speed := 220.0
@export var dash_time := 0.3
@export var walk_time_min := 1.0
@export var walk_time_max := 2.5

enum EnemyState { WALK, DASH }
var state: EnemyState = EnemyState.WALK

var angry := false
var direction := -1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dead := false
var hitted := false

# posições fixas no mundo, capturadas uma única vez em _ready().
# Se o marker for filho do próprio inimigo, ler marker.global_position
# a cada frame faria o alvo "andar junto" com o inimigo.
var patrol_point_a: Vector2
var patrol_point_b: Vector2
var patrol_target_pos: Vector2

@onready var angry_speed = speed * 2.5
@onready var angry_dash_speed = dash_speed * 1.3
@onready var half_life = health / 2
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var edge_ray: RayCast2D = $EdgeRay
@onready var wall_ray: RayCast2D = $WallRay
@onready var hitsfx := $HitSfx
@onready var walk_timer: Timer = $WalkTimer
@onready var dash_timer: Timer = $DashTimer
var shriek_sfx: AudioStreamPlayer2D


func _ready() -> void:
	if has_node("ShriekSfx"):
		shriek_sfx = $ShriekSfx

	walk_timer.one_shot = true
	dash_timer.one_shot = true

	if not walk_timer.timeout.is_connected(_on_walk_timer_timeout):
		walk_timer.timeout.connect(_on_walk_timer_timeout)
	if not dash_timer.timeout.is_connected(_on_dash_timer_timeout):
		dash_timer.timeout.connect(_on_dash_timer_timeout)
		
	if patrol and marker_a and marker_b:
		patrol_point_a = marker_a.global_position
		patrol_point_b = marker_b.global_position

		# começa indo em direção ao marker mais distante
		patrol_target_pos = patrol_point_b
		if global_position.distance_to(patrol_point_a) > global_position.distance_to(patrol_point_b):
			patrol_target_pos = patrol_point_a
		direction = 1 if patrol_target_pos.x > global_position.x else -1

	_start_walk()


func _physics_process(delta):
	_set_animation()

	if dead:
		move_and_slide()
		return

	if patrol and marker_a and marker_b:
		_update_patrol_direction()
	else:
		_update_edge_ray()
		_update_wall_ray()

		if is_on_floor() and not edge_ray.is_colliding() and edge_ray_active:
			_turn_around()

		if flying:
			if not is_on_floor() and not edge_ray.is_colliding() and edge_ray_active:
				_turn_around()

		if wall_ray.is_colliding():
			_turn_around()

	if not is_on_floor() and not flying:
		velocity.y += gravity * delta

	if not hitted:
		match state:
			EnemyState.WALK:
				velocity.x = direction * (angry_speed if angry else speed)
			EnemyState.DASH:
				velocity.x = direction * (angry_dash_speed if angry else dash_speed)

	sprite.flip_h = direction > 0
	move_and_slide()


func _update_edge_ray() -> void:
	edge_ray.position.x = edge_ray_offset_x * direction
	edge_ray.target_position = Vector2(0, edge_ray_offset_y)
	edge_ray.force_raycast_update()


func _update_wall_ray() -> void:
	wall_ray.position = Vector2.ZERO
	wall_ray.target_position = Vector2(wall_ray_offset_x * direction, wall_ray_offset_y)
	wall_ray.force_raycast_update()


func _turn_around() -> void:
	direction *= -1
	_update_edge_ray()
	_update_wall_ray()


# ================== CICLO ANDA -> DASH ==================
func _start_walk() -> void:
	state = EnemyState.WALK
	walk_timer.wait_time = randf_range(walk_time_min, walk_time_max)
	walk_timer.start()


func _on_walk_timer_timeout() -> void:
	if dead or hitted:
		return
	_start_dash()


func _start_dash() -> void:
	state = EnemyState.DASH
	dash_timer.wait_time = dash_time
	dash_timer.start()


func _on_dash_timer_timeout() -> void:
	if dead or hitted:
		return
	_start_walk()


func _set_animation() -> void:
	var anim := "idle"
	if dead or hitted:
		anim = "hit"
	elif state == EnemyState.DASH:
		anim = "dash"
	elif abs(velocity.x) > 40:
		anim = "angry" if angry else "run"
	if sprite.animation != anim:
		sprite.play(anim)


func _on_animated_sprite_2d_animation_finished() -> void:
	var anim = sprite.animation
	if anim == "hit":
		if shriek_sfx:
			shriek_sfx.play()
		if health <= 0:
			_spawn_die_puff()
			GameEvents.register_monster_defeated()
			queue_free()
		else:
			hitted = not hitted


func _on_hit_box_area_entered(area: Area2D) -> void:
	if dead:
		return
	if area.name == "HurtBox":
		var player := area.get_parent()
		if player.velocity.y >= 0 and player.global_position.y < global_position.y:
			_hit(player)


func _hit(player) -> void:
	health -= 1
	hitted = not hitted
	if health <= 0:
		dead = true
	if health <= half_life and irritable and not angry:
		angry = true
	velocity = Vector2.ZERO
	player.velocity.y = -420
	hitsfx.play()
	sprite.play("hit")


func take_projectile_hit() -> void:
	health -= 1
	hitted = not hitted
	if health <= 0:
		dead = true
	if health <= half_life and irritable and not angry:
		angry = true
	velocity = Vector2.ZERO
	hitsfx.play()
	sprite.play("hit")


const DustPuffScene := preload("res://Prefabs/dust_puff.tscn")
const DiePuffScene := preload("res://Prefabs/die_puff.tscn")
const STEP_FRAMES := [2, 8]


func _spawn_die_puff() -> void:
	var puff: Node2D = DiePuffScene.instantiate()
	get_parent().add_child(puff)
	puff.global_position = global_position
	puff.flip_h = direction > 0


func _on_animated_sprite_2d_frame_changed() -> void:
	if sprite.animation != "angry" and sprite.animation != "run":
		return
	if sprite.frame in STEP_FRAMES:
		_spawn_dust_puff()


func _spawn_dust_puff() -> void:
	var puff: Node2D = DustPuffScene.instantiate()
	get_parent().add_child(puff)
	puff.global_position = global_position + Vector2(-8 if direction > 0 else 8, 8)
	puff.flip_h = direction > 0

# ================== PATROL ==================
func _update_patrol_direction() -> void:
	var target_x := patrol_target_pos.x
	direction = 1 if target_x > global_position.x else -1

	# o dash é rápido, então garanto que a margem de chegada seja pelo menos
	# o tamanho de um passo por frame, para ele não "pular" o marker
	var step :int = abs(velocity.x) * get_physics_process_delta_time()
	var arrive := maxf(patrol_arrive_threshold, step)

	if abs(target_x - global_position.x) <= arrive:
		patrol_target_pos = patrol_point_a if patrol_target_pos == patrol_point_b else patrol_point_b
