extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal lifes_changed(current_life: int)
signal ammo_changed(current_ammo: int)
signal died

@export var kb_velocity := 350
@export var max_health := 3
## velocidade de padrão
@export var walk_speed := 230.0
## velocidade de corrida (fator que multiplica a velocidade padrão)
@export var run_speed_multiplier := 1.6
## segundos pra ir de walk até run
@export var speed_ramp_time := 3.0
## suavização pra inciar e parar o player
@export var acceleration_weight := 0.07
## altura do pulo (padrão 4 blocos)
@export var jump_velocity := -420
@export var gravity := 1220.0
@export var invincibility_time := 1.5
@export var blink_interval := 0.1
@export var hurt_duration := 0.4
@export var base_floor_snap := 8.0
@export var floor_max_angle_degrees := 55.0
@export var slingshot_projectile_scene: PackedScene
@export var shoot_cooldown := 0.3

@onready var health := max_health
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shoot_point: Marker2D = $AnimatedSprite2D/ShootPoint
@onready var initial_position = position
@onready var camera := $Camera2D

var is_shooting :bool = false
var level_complete: bool = false
var run_speed: float
var current_max_speed: float
var speed_ramp_elapsed := 0.0
var direction := 0.0
var is_invincible := false
var is_hurt := false
var hurt_timer := 0.0
var is_dead := false
var has_slingshot: bool = false
var can_shoot: bool = true


func _ready() -> void:
	# VERIFICA SE TEM MUNIÇÃO, SE SIM, DA AO PLAYER O SLINGSHOOT
	if GameEvents.ammo > 0:
		equip_slingshot()
	run_speed = walk_speed * run_speed_multiplier
	current_max_speed = walk_speed
	health_changed.emit(health, max_health)
	GameEvents.check_position = initial_position
	if camera != null:
		var saved_zoom := ProgressManager.get_camera_zoom()
		camera.zoom = Vector2(saved_zoom, saved_zoom)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if level_complete:
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		_set_animation()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	_get_input(delta)
	_update_floor_snap(delta)
	move_and_slide()

	if is_hurt:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			is_hurt = false

	if has_slingshot and Input.is_action_just_pressed("shoot") and can_shoot:
		print("shoot pressed")
		_fire_slingshot()

	_set_animation()


func _get_input(delta: float) -> void:
	var move_input: float = Input.get_axis("ui_left", "ui_right")

	if move_input != 0.0:
		direction = sign(move_input)

		# rampa de velocidade: só cresce enquanto o input continua ativo
		speed_ramp_elapsed += delta
		var ramp_t: float = clamp(speed_ramp_elapsed / speed_ramp_time, 0.0, 1.0)
		current_max_speed = lerp(walk_speed, run_speed, ramp_t)

		velocity.x = lerp(velocity.x, move_input * current_max_speed, acceleration_weight)
	else:
		# soltou o input: reseta a rampa pra próxima vez começar em walk de novo
		speed_ramp_elapsed = 0.0
		current_max_speed = walk_speed
		velocity.x = lerp(velocity.x, 0.0, acceleration_weight)

	if direction > 0.0:
		sprite.flip_h = false
		shoot_point.position.x = 15
	elif direction < 0.0:
		sprite.flip_h = true
		shoot_point.position.x = -15

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	if velocity.y < 0.0 and Input.is_action_just_released("jump"):
		velocity.y = lerp(velocity.y, 0.0, 0.5)

func _update_floor_snap(delta: float) -> void:
	var horizontal_speed: float = abs(velocity.x)
	var needed_snap: float = horizontal_speed * delta * tan(floor_max_angle)  # floor_max_angle já é a propriedade nativa em radianos

	floor_snap_length = max(base_floor_snap, needed_snap)


func _set_animation() -> void:
	var anim: String = "idle"

	if is_hurt:
		anim = "hurt"
	elif is_shooting:
		anim = "shoot"
	else:
		var speed_abs: float = abs(velocity.x)
		var is_running: bool = speed_abs > walk_speed * 1.4  # margem pra evitar flicker no limiar

		if speed_abs > 40.0:
			anim = "walk"
		if is_running:
			anim = "run"

		if not is_on_floor():
			if is_running:
				anim = "run_jump"
			else:
				anim = "jump"
				if velocity.y > 10.0:
					anim = "fall"

	if sprite.animation != anim:
		sprite.play(anim)


func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.has_method("is_stunned") and body.is_stunned():
		return
	if body.has_method("is_hitted") and body.is_hitted():
		return
	
	if is_invincible or is_dead:
		return
	
	if "dead" in body and body.dead:
		return
	
	if "hitted"in body and body.hitted:
		return

	health -= 1

	health_changed.emit(health, max_health)

	if health <= 0:
		_die()
		return

	_knockback(body.global_position)
	is_hurt = true
	hurt_timer = hurt_duration
	blink()


func _knockback(source_position: Vector2) -> void:
	var away_from_source: float = sign(global_position.x - source_position.x)

	# fallback: se estiver exatamente alinhado (diferença de X = 0), usa a direção atual como desempate
	if away_from_source == 0.0:
		away_from_source = -direction

	velocity.y = jump_velocity / 2.0
	velocity.x = away_from_source * kb_velocity


func _die() -> void:
	GameEvents.life_count -= 1
	emit_signal("lifes_changed",GameEvents.life_count)
	is_dead = true
	velocity = Vector2.ZERO
	is_invincible = true
	sprite.play("hurt")
	died.emit()


func blink() -> void:
	is_invincible = true
	var elapsed: float = 0.0

	while elapsed < invincibility_time:
		sprite.visible = !sprite.visible
		await get_tree().create_timer(blink_interval).timeout
		elapsed += blink_interval

	sprite.visible = true
	is_invincible = false


func equip_slingshot(ammo_amount: int = 0) -> void:
	has_slingshot = true
	GameEvents.ammo += ammo_amount
	ammo_changed.emit(GameEvents.ammo)


func _fire_slingshot() -> void:
	if GameEvents.ammo <= 0 or slingshot_projectile_scene == null:
		print("ammo<=0 ou a cena do projeto é nula")
		return

	can_shoot = false
	GameEvents.ammo -= 1
	ammo_changed.emit(GameEvents.ammo)
	
	is_shooting = true
	sprite.play("shoot")

	var projectile := slingshot_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = shoot_point.global_position

	if projectile.has_method("launch"):
		projectile.launch(Vector2(direction, 0))

	if GameEvents.ammo <= 0:
		has_slingshot = false

	_start_shoot_cooldown()


func _start_shoot_cooldown() -> void:
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


func start_level_complete(speed: float) -> void:
	if level_complete or is_dead:
		return
		
	level_complete = true
	var camera := get_node_or_null("Camera2D")
	if camera != null:
		var current_global_pos: Vector2 = camera.global_position
		camera.top_level = true
		camera.global_position = current_global_pos
		
	velocity.x = direction * speed


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "shoot":
		is_shooting = false

func _reset_status():
	velocity = Vector2.ZERO
	health = max_health
	health_changed.emit(health, max_health)
	is_invincible = false
	is_dead = false
