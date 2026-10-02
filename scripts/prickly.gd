extends CharacterBody2D

@export var edge_ray_offset_x := 16.0
@export var edge_ray_offset_y := 20.0
@export var wall_ray_offset_x := 20.0
@export var wall_ray_offset_y := 0.0
@export var edge_ray_active : bool = true

@export var health := 3.0

# ================== MOVIMENTO / CICLO ==================
@export var speed := 40.0
@export var dash_speed := 200.0
@export var idle_time_min := 0.6
@export var idle_time_max := 1.4
@export var walk_time_min := 1.5
@export var walk_time_max := 3.0
@export var dash_time := 1.2
@export var stun_time := 2.0

enum TurtleState { IDLE, WALK, DASH, STUN, SPIKES_OUT }
var state: TurtleState = TurtleState.IDLE

var direction := -1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dead := false
var hitted := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var edge_ray: RayCast2D = $EdgeRay
@onready var wall_ray: RayCast2D = $WallRay
@onready var hitsfx := $HitSfx
@onready var idle_timer: Timer = $IdleTimer
@onready var walk_timer: Timer = $WalkTimer
@onready var dash_timer: Timer = $DashTimer
@onready var stun_timer: Timer = $StunTimer


func _ready() -> void:
	idle_timer.one_shot = true
	walk_timer.one_shot = true
	dash_timer.one_shot = true
	stun_timer.one_shot = true

	if not idle_timer.timeout.is_connected(_on_idle_timer_timeout):
		idle_timer.timeout.connect(_on_idle_timer_timeout)
	if not walk_timer.timeout.is_connected(_on_walk_timer_timeout):
		walk_timer.timeout.connect(_on_walk_timer_timeout)
	if not dash_timer.timeout.is_connected(_on_dash_timer_timeout):
		dash_timer.timeout.connect(_on_dash_timer_timeout)
	if not stun_timer.timeout.is_connected(_on_stun_timer_timeout):
		stun_timer.timeout.connect(_on_stun_timer_timeout)

	_start_idle()


func _physics_process(delta):
	_set_animation()

	if dead:
		move_and_slide()
		return

	_update_edge_ray()
	_update_wall_ray()

	if not is_on_floor():
		velocity.y += gravity * delta

	if state in [TurtleState.WALK, TurtleState.DASH]:
		if is_on_floor() and not edge_ray.is_colliding() and edge_ray_active:
			_turn_around()
		if wall_ray.is_colliding():
			_turn_around()

	if not hitted:
		match state:
			TurtleState.WALK:
				velocity.x = direction * speed
			TurtleState.DASH:
				velocity.x = direction * dash_speed
			TurtleState.IDLE, TurtleState.STUN, TurtleState.SPIKES_OUT:
				velocity.x = 0

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


# ================== CICLO IDLE -> WALK -> DASH -> STUN -> SPIKES_OUT ==================
func _start_idle() -> void:
	state = TurtleState.IDLE
	idle_timer.wait_time = randf_range(idle_time_min, idle_time_max)
	idle_timer.start()


func _on_idle_timer_timeout() -> void:
	if dead or hitted:
		return
	_start_walk()


func _start_walk() -> void:
	state = TurtleState.WALK
	walk_timer.wait_time = randf_range(walk_time_min, walk_time_max)
	walk_timer.start()


func _on_walk_timer_timeout() -> void:
	if dead or hitted:
		return
	_start_dash()


func _start_dash() -> void:
	state = TurtleState.DASH
	dash_timer.wait_time = dash_time
	dash_timer.start()


func _on_dash_timer_timeout() -> void:
	if dead or hitted:
		return
	_start_stun()


func _start_stun() -> void:
	state = TurtleState.STUN
	velocity.x = 0
	stun_timer.wait_time = stun_time
	stun_timer.start()


func _on_stun_timer_timeout() -> void:
	if dead or hitted:
		return
	_start_spikes_out()


func _start_spikes_out() -> void:
	state = TurtleState.SPIKES_OUT
	# a saída desse estado acontece pelo fim da animação "spikesout",
	# tratado em _on_animated_sprite_2d_animation_finished


func _set_animation() -> void:
	var anim := "idle"
	if dead or hitted:
		anim = "hit"
	else:
		match state:
			TurtleState.IDLE:
				anim = "idle"
			TurtleState.WALK:
				anim = "run"
			TurtleState.DASH:
				anim = "dash"
			TurtleState.STUN:
				anim = "stun"
			TurtleState.SPIKES_OUT:
				anim = "spikesout"
	if sprite.animation != anim:
		sprite.play(anim)


func _on_animated_sprite_2d_animation_finished() -> void:
	var anim := sprite.animation
	if anim == "hit":
		if dead:
			_spawn_die_puff()
			GameEvents.register_monster_defeated()
			queue_free()
		else:
			hitted = false
	elif anim == "spikesout":
		if not dead:
			_start_walk()


# ================== DANO ==================
# Casco com espinhos: só toma dano de stomp durante o STUN.
# Fora do stun, só leva dano de projétil.
func _on_hit_box_area_entered(area: Area2D) -> void:
	if dead or state != TurtleState.STUN:
		return
	if area.name == "HurtBox":
		var player := area.get_parent()
		if player.velocity.y >= 0 and player.global_position.y < global_position.y:
			_take_damage(1, player)


func take_projectile_hit() -> void:
	_take_damage(1, null)


func _take_damage(amount, player) -> void:
	if dead or hitted:
		return
	health -= amount
	hitted = true
	if player:
		player.velocity.y = -420
	hitsfx.play()
	if health <= 0:
		dead = true


const DiePuffScene := preload("res://Prefabs/die_puff.tscn")


func _spawn_die_puff() -> void:
	var puff: Node2D = DiePuffScene.instantiate()
	get_parent().add_child(puff)
	puff.global_position = global_position
	puff.flip_h = direction > 0
