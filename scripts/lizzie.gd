extends CharacterBody2D

# ================== MOVIMENTO ==================
@export var speed := 40.0
@export var stick_force := 40.0
@export var edge_ray_offset_x := 12.0
@export var edge_ray_offset_y := 20.0
@export var wall_ray_offset_x := 12.0
@export var wall_ray_offset_y := 0.0
@export var idle_time_min := 0.6
@export var idle_time_max := 1.4
@export var walk_time_min := 1.0
@export var walk_time_max := 2.5

# ================== CAMUFLAGEM ==================
@export var camo_alpha := 0.35
@export var camo_fade_time := 0.5

# ================== ATAQUE ==================
@export var tongue_scene: PackedScene
@export var attack_cooldown := 1.5
@export var tongue_range := 90.0

# ================== VIDA ==================
@export var health := 1.0

enum LizardState { PATROL, IDLE, ATTACK, HIT, DEAD }


var state: LizardState = LizardState.PATROL
var direction := -1
var can_attack := true
var player_ref: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var edge_ray: RayCast2D = $EdgeRay
@onready var wall_ray: RayCast2D = $WallRay
@onready var tongue_point: Marker2D = $TonguePoint
@onready var idle_timer: Timer = $IdleTimer
@onready var attack_timer: Timer = $AttackCooldown
@onready var walk_timer: Timer = $WalkTimer

var is_hitted = false
var _current_tongue: Node = null  # referência ao ataque em andamento, pra poder cancelar


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_update_edge_ray()
	_update_wall_ray()

	idle_timer.one_shot = true

	walk_timer.one_shot = true

	attack_timer.one_shot = true

	_start_walk_cycle()


func _physics_process(_delta: float) -> void:
	_set_animation()

	if state == LizardState.DEAD:
		move_and_slide()
		return

	_update_edge_ray()
	_update_wall_ray()

	match state:
		LizardState.PATROL:
			_process_patrol()
		LizardState.IDLE, LizardState.ATTACK, LizardState.HIT:
			velocity = transform.y * stick_force

	if state in [LizardState.PATROL, LizardState.IDLE] and can_attack and player_ref:
		_start_attack()

	move_and_slide()


func _process_patrol() -> void:
	var vel_local := Vector2(direction * speed, stick_force)
	if state != LizardState.HIT:
		velocity = transform.x * vel_local.x + transform.y * vel_local.y
	else:
		velocity = Vector2.ZERO

	if wall_ray.is_colliding() or not edge_ray.is_colliding():
		_enter_idle()


func _enter_idle(flip: bool = true) -> void:
	state = LizardState.IDLE
	if flip:
		direction *= -1
		_update_edge_ray()
		_update_wall_ray()
		sprite.flip_h = direction > 0
	_camuflar(true)
	idle_timer.wait_time = randf_range(idle_time_min, idle_time_max)
	idle_timer.start()


func _on_idle_timer_timeout() -> void:
	if state == LizardState.IDLE:
		state = LizardState.PATROL
		_start_walk_cycle()
		_camuflar(false)


func _update_edge_ray() -> void:
	edge_ray.position.x = edge_ray_offset_x * direction
	edge_ray.target_position = Vector2(0, edge_ray_offset_y)
	edge_ray.force_raycast_update()


func _update_wall_ray() -> void:
	wall_ray.position = Vector2.ZERO
	wall_ray.target_position = Vector2(wall_ray_offset_x * direction, wall_ray_offset_y)
	wall_ray.force_raycast_update()


func _set_animation() -> void:
	var anim := "idle"
	match state:
		LizardState.DEAD, LizardState.HIT:
			anim = "hit"
		LizardState.ATTACK:
			anim = "attack"
		LizardState.PATROL:
			anim = "run"
		LizardState.IDLE:
			anim = "idle"
	if sprite.animation != anim:
		sprite.play(anim)


# ================== CAMUFLAGEM ==================
func _camuflar(ativa: bool) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", camo_alpha if ativa else 1.0, camo_fade_time)


# ================== DETECÇÃO DO PLAYER ==================
func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body


func _on_player_detector_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null


# ================== ATAQUE COM A LÍNGUA ==================
func _start_attack() -> void:
	if not tongue_scene or not player_ref or is_hitted:
		return

	var alvo_pos := player_ref.global_position
	var dist := tongue_point.global_position.distance_to(alvo_pos)
	if dist > tongue_range:
		return # fora de alcance real, nem entra em ATTACK

	can_attack = false
	state = LizardState.ATTACK
	_camuflar(false)
	idle_timer.stop()
	sprite.flip_h = alvo_pos.x > global_position.x

	var lingua = tongue_scene.instantiate()
	get_parent().add_child(lingua)
	lingua.global_position = tongue_point.global_position
	lingua.look_at(alvo_pos)
	_current_tongue = lingua
	lingua.disparar(dist)
	await lingua.finalizado
	_current_tongue = null
	if is_instance_valid(lingua):
		lingua.queue_free()

	# só volta pra PATROL se nada mais (hit/morte) já tiver
	# mudado o estado do lagarto enquanto o ataque estava em andamento.
	if state == LizardState.ATTACK:
		state = LizardState.PATROL
		_face_direction()      # <- volta a olhar para onde estava patrulhando
		_start_walk_cycle()    # <- reinicia o timer de caminhada
		attack_timer.wait_time = attack_cooldown
		attack_timer.start()


func _on_attack_cooldown_timeout() -> void:
	can_attack = true

func _face_direction() -> void:
	sprite.flip_h = direction > 0


# ================== DANO NO LAGARTO ==================
func take_hit(amount, player) -> void:
	is_hitted = not is_hitted
	if player:
		player.velocity.y = -420

	if state == LizardState.DEAD:
		return

	# Se o lagarto for atingido durante o ataque, cancela o efeito visual
	# da língua imediatamente (evita ela continuar em cena depois da morte/hit)
	if is_instance_valid(_current_tongue):
		_current_tongue.queue_free()
		_current_tongue = null

	health -= amount
	state = LizardState.DEAD if health <= 0 else LizardState.HIT
	$HitSfx.play()


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation != "hit":
		is_hitted = not is_hitted
		return
	if state == LizardState.DEAD:
		_spawn_die_puff()
		queue_free()
	elif state == LizardState.HIT:
		state = LizardState.PATROL

func _start_walk_cycle() -> void:
	walk_timer.wait_time = randf_range(walk_time_min, walk_time_max)
	walk_timer.start()
	
func _on_walk_timer_timeout() -> void:
	print("walk timer timeout")
	if state == LizardState.PATROL:
		_enter_idle(false)  # false = não flipa


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "HurtBox":
		var player := area.get_parent()
		if player.velocity.y >= 0 and player.global_position.y < global_position.y:
			take_hit(1, player)

func take_projectile_hit() -> void:
	take_hit(1, null)

const DiePuffScene := preload("res://Prefabs/die_puff.tscn")
const STEP_FRAMES := [2,8]

func _spawn_die_puff() -> void:
	var puff: Node2D = DiePuffScene.instantiate()
	get_parent().add_child(puff)
	puff.global_position = global_position
	puff.flip_h = direction > 0
