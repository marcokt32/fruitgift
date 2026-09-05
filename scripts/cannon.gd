extends StaticBody2D

enum TurretState { IDLE, SHOOTING }

@export var projectile_scene: PackedScene
@export var shoot_cooldown := 1.2
@export var fire_frame := 3
@export var health := 1
@export var shoot_point_offset_x := 20.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var shoot_point: Marker2D = $ShootPoint
@onready var hit_box: Area2D = $HitBox

var dead := false
var hitted := false
var state: TurretState = TurretState.IDLE
var player_in_range: Node2D = null
var can_shoot: bool = true
var facing_direction: int = -1


func _ready() -> void:
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("idle")


func _physics_process(_delta: float) -> void:
	if player_in_range != null and not hitted and not dead:
		_update_facing()

	if state == TurretState.IDLE and player_in_range != null and can_shoot and not hitted and not dead:
		_start_shooting()


func _update_facing() -> void:
	facing_direction = sign(player_in_range.global_position.x - global_position.x)
	if facing_direction == 0:
		facing_direction = 1

	sprite.flip_h = facing_direction > 0

	if facing_direction == -1:
		hit_box.position.x = 10
	else:
		hit_box.position.x = -10

	shoot_point.position.x = shoot_point_offset_x * facing_direction


func _start_shooting() -> void:
	state = TurretState.SHOOTING
	can_shoot = false
	sprite.play("shoot")


func _on_frame_changed() -> void:
	if state == TurretState.SHOOTING and sprite.animation == "shoot" and sprite.frame == fire_frame:
		_fire_projectile()


func _fire_projectile() -> void:
	if projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = shoot_point.global_position

	if projectile.has_method("launch"):
		projectile.launch(Vector2(facing_direction, 0))


func _on_animation_finished() -> void:
	var anim: String = sprite.animation

	if anim == "shoot":
		state = TurretState.IDLE
		sprite.play("idle")
		_start_cooldown()

	elif anim == "hit":
		if dead:
			queue_free()
		else:
			hitted = false
			hit_box.set_deferred("monitoring", true)
			sprite.play("idle")


func _start_cooldown() -> void:
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = body


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null


func _on_hit_box_area_entered(area: Area2D) -> void:
	if dead or hitted:
		return

	if area.name == "HurtBox":
		var player := area.get_parent()
		if player.velocity.y >= 0 and player.global_position.y < global_position.y:
			_hit(player)


func _hit(player) -> void:
	hitted = true
	hit_box.set_deferred("monitoring", false)

	health -= 1
	if health <= 0:
		dead = true

	player.velocity.y = -400
	sprite.play("hit")


func take_projectile_hit() -> void:
	if hitted or dead:
		return

	hitted = true
	hit_box.set_deferred("monitoring", false)

	health -= 1
	if health <= 0:
		dead = true

	sprite.play("hit")
