extends CharacterBody2D

@export var flying: bool = false

@export var edge_ray_offset_x := 16.0
@export var edge_ray_offset_y := 20.0
@export var wall_ray_offset_x := 20.0
@export var wall_ray_offset_y := 0.0
@export var health := 1.0
@export var speed := 50.0
@export var irritable : bool = false
@export var edge_ray_active : bool = true

var angry := false
var direction := -1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var dead := false
var hitted := false

@onready var angry_speed = speed * 2.5
@onready var half_life = health / 2
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var edge_ray: RayCast2D = $EdgeRay
@onready var wall_ray: RayCast2D = $WallRay
@onready var reset_speed = speed


func _physics_process(delta):
	_set_animation()

	if dead:
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

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
		if health <= 0:
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
	sprite.play("hit")

func take_projectile_hit() -> void:
	health -= 1
	hitted = not hitted
	if health <= 0:
		dead = true
	if health <= half_life and irritable and !angry:
		angry = true
	velocity = Vector2.ZERO
	sprite.play("hit")
