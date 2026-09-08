extends CharacterBody2D

enum EnemyState { IDLE, PATROL, CHASING, RETURNING, RETREATING }

@export var health := 1
@export var chase_speed := 120.0
@export var acceleration_weight := 0.08
@export var return_to_start := true

@export var patrol_enabled := false
@export var patrol_point_a_path: NodePath
@export var patrol_point_b_path: NodePath
@export var patrol_speed := 60.0

@export var retreat_duration := 1.0
@export var retreat_speed := 150.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

var dead := false
var hitted := false
var state: EnemyState = EnemyState.IDLE
var player_in_range: Node2D = null
var start_position: Vector2

var patrol_point_a: Vector2
var patrol_point_b: Vector2
var patrol_target: Vector2

var retreat_timer: float = 0.0
var retreat_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	start_position = global_position

	if patrol_enabled:
		var node_a := get_node_or_null(patrol_point_a_path)
		var node_b := get_node_or_null(patrol_point_b_path)
		if node_a != null and node_b != null:
			patrol_point_a = node_a.global_position
			patrol_point_b = node_b.global_position
			patrol_target = patrol_point_b
			state = EnemyState.PATROL
		else:
			push_error("FlyingEnemy: patrol_enabled mas os pontos não estão configurados!")
			state = EnemyState.IDLE
	else:
		state = EnemyState.IDLE


func _physics_process(delta: float) -> void:
	if dead:
		return

	if hitted:
		velocity = velocity.lerp(Vector2.ZERO, acceleration_weight)
		move_and_slide()
		_set_animation()
		return

	match state:
		EnemyState.RETREATING:
			_process_retreat(delta)
		EnemyState.CHASING:
			_process_chasing()
		EnemyState.RETURNING:
			_process_returning()
		EnemyState.PATROL:
			_process_patrol()
		EnemyState.IDLE:
			velocity = velocity.lerp(Vector2.ZERO, acceleration_weight)

	_update_facing()
	move_and_slide()
	_check_player_contact()
	_set_animation()


func _process_chasing() -> void:
	if player_in_range == null:
		return
	var to_target: Vector2 = player_in_range.global_position - global_position
	var desired_velocity: Vector2 = to_target.normalized() * chase_speed
	velocity = velocity.lerp(desired_velocity, acceleration_weight)


func _process_returning() -> void:
	var to_target: Vector2 = start_position - global_position
	var distance: float = to_target.length()

	if distance <= 4.0:
		global_position = start_position
		velocity = Vector2.ZERO
		state = EnemyState.PATROL if patrol_enabled else EnemyState.IDLE
		return

	var desired_velocity: Vector2 = to_target.normalized() * chase_speed
	velocity = velocity.lerp(desired_velocity, acceleration_weight)


func _process_patrol() -> void:
	var to_target: Vector2 = patrol_target - global_position
	var distance: float = to_target.length()

	if distance <= 4.0:
		patrol_target = patrol_point_a if patrol_target == patrol_point_b else patrol_point_b

	var desired_velocity: Vector2 = to_target.normalized() * patrol_speed
	velocity = velocity.lerp(desired_velocity, acceleration_weight)


func _process_retreat(delta: float) -> void:
	retreat_timer -= delta
	var desired_velocity: Vector2 = retreat_direction * retreat_speed
	velocity = velocity.lerp(desired_velocity, acceleration_weight)

	if retreat_timer <= 0.0:
		if player_in_range != null:
			state = EnemyState.CHASING
		elif return_to_start:
			state = EnemyState.RETURNING
		else:
			state = EnemyState.PATROL if patrol_enabled else EnemyState.IDLE


func _check_player_contact() -> void:
	if state == EnemyState.RETREATING:
		return

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider: Object = collision.get_collider()

		if collider is Node and collider.is_in_group("player"):
			_start_retreat(collider)
			return


func _start_retreat(player: Node2D) -> void:
	state = EnemyState.RETREATING
	retreat_timer = retreat_duration
	retreat_direction = (global_position - player.global_position).normalized()
	if retreat_direction == Vector2.ZERO:
		retreat_direction = Vector2.UP


func _update_facing() -> void:
	if abs(velocity.x) > 5.0:
		sprite.flip_h = velocity.x > 0
	if sprite.flip_h == true:
		$CollisionShape2D.position.x = 22
		$HitBox.position.x = 15
	else:
		$CollisionShape2D.position.x = 2
		$HitBox.position.x = 0


func _set_animation() -> void:
	var anim: String = "idle"

	if hitted:
		anim = "hit"
	elif velocity.length() > 10.0:
		anim = "fly"
	
	if !patrol_enabled and velocity == Vector2.ZERO and !hitted:
		anim = "rest"

	if sprite.animation != anim:
		sprite.play(anim)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not hitted:
		player_in_range = body
		if state != EnemyState.RETREATING:
			state = EnemyState.CHASING


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player_in_range and not hitted:
		player_in_range = null
		if state == EnemyState.CHASING:
			if return_to_start:
				state = EnemyState.RETURNING
			else:
				state = EnemyState.PATROL if patrol_enabled else EnemyState.IDLE


func _on_hit_box_area_entered(area: Area2D) -> void:
	if dead:
		return
	if area.name == "HurtBox":
		var player := area.get_parent()
		if player.velocity.y >= 0 and player.global_position.y < global_position.y:
			_hit(player)


func _hit(player) -> void:
	health -= 1
	hitted = true
	if health <= 0:
		dead = true
	velocity = Vector2.ZERO
	player.velocity.y = -400
	sprite.play("hit")


func _on_animated_sprite_2d_animation_finished() -> void:
	var anim = sprite.animation
	if anim == "hit":
		if health <= 0:
			queue_free()
		else:
			hitted = false
