extends CharacterBody2D

@export var flying: bool = false

@export var edge_ray_offset_x := 16.0
@export var edge_ray_offset_y := 20.0
@export var wall_ray_offset_x := 20.0
@export var wall_ray_offset_y := 0.0
@export var health := 1.0
@export var speed := 60.0
@export var irritable : bool = false
@export var edge_ray_active : bool = true

# ================== PATROL ==================
@export var patrol : bool = false
@export var marker_a: Marker2D
@export var marker_b: Marker2D
@export var patrol_arrive_threshold := 4.0

var angry := false
var direction := -1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dead := false
var hitted := false

# posições fixas no mundo, capturadas uma única vez em _ready().
# Se o marker for filho do próprio inimigo, ler marker.global_position
# a cada frame faria o alvo "andar junto" com o inimigo e nunca ser alcançado.
var patrol_point_a: Vector2
var patrol_point_b: Vector2
var patrol_target_pos: Vector2

@onready var angry_speed = speed * 2.5
@onready var half_life = health / 2
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var edge_ray: RayCast2D = $EdgeRay
@onready var wall_ray: RayCast2D = $WallRay
@onready var reset_speed = speed
@onready var hitsfx := $HitSfx
var shriek_sfx: AudioStreamPlayer2D

func _ready() -> void:
	if has_node("ShriekSfx"):
		shriek_sfx = $ShriekSfx

	if patrol and marker_a and marker_b:
		patrol_point_a = marker_a.global_position
		patrol_point_b = marker_b.global_position

		# começa indo em direção ao marker mais distante
		patrol_target_pos = patrol_point_b
		if global_position.distance_to(patrol_point_a) > global_position.distance_to(patrol_point_b):
			patrol_target_pos = patrol_point_a
		direction = 1 if patrol_target_pos.x > global_position.x else -1

func _physics_process(delta):
	_set_animation()

	if dead:
		#if not is_on_floor():
		#	velocity.y += gravity * delta
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
	
	if angry and not hitted:
		velocity.x = direction * angry_speed
	elif not hitted:
		velocity.x = direction * speed
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
	speed = 0


# ================== PATROL ==================
func _update_patrol_direction() -> void:
	var target_x := patrol_target_pos.x
	direction = 1 if target_x > global_position.x else -1

	if abs(target_x - global_position.x) <= patrol_arrive_threshold:
		patrol_target_pos = patrol_point_a if patrol_target_pos == patrol_point_b else patrol_point_b


func _set_animation() -> void:
	var anim := "idle"
	if dead or hitted:
		anim = "hit"
	elif abs(velocity.x) > 40:
		if angry:
			anim = "angry"
		else:
			anim = "run"
	if sprite.animation != anim:
		sprite.play(anim)


func _on_animated_sprite_2d_animation_finished() -> void:
	var anim = sprite.animation
	if anim == "idle":
		if angry:
			speed = angry_speed
		else:
			speed = reset_speed

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

func _hit(player):
	health -= 1
	hitted = not hitted
	if health <= 0:
		dead = true
	if health <= half_life and irritable and !angry:
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
	if health <= half_life and irritable and !angry:
		angry = true
	velocity = Vector2.ZERO
	hitsfx.play()
	sprite.play("hit")

const DustPuffScene := preload("res://Prefabs/dust_puff.tscn")
const DiePuffScene := preload("res://Prefabs/die_puff.tscn")
const STEP_FRAMES := [2,8]

func _spawn_die_puff() -> void:
	var puff: Node2D = DiePuffScene.instantiate()
	get_parent().add_child(puff)
	puff.global_position = global_position
	puff.flip_h = direction > 0

func _on_animated_sprite_2d_frame_changed() -> void:
	if sprite.animation != "angry":
		return

	if sprite.frame in STEP_FRAMES:
		_spawn_dust_puff()

func _spawn_dust_puff() -> void:
	var scene: PackedScene
	if sprite.animation == "angry":
		scene = DustPuffScene
	else:
		return

	var puff: Node2D = scene.instantiate()
	get_parent().add_child(puff)
	puff.global_position = global_position + Vector2(-8 if direction > 0 else 8, 8)
	puff.flip_h = direction > 0
