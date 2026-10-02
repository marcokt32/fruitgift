extends CharacterBody2D

signal activated
signal health_changed(current: float, max_health: float)
signal defeated
signal boss_reset

enum BossState { IDLE, CHASE, BRAKING, TAUNT, STUNNED, HIT, DEAD }

@export var flying: bool = false

@export var edge_ray_offset_x := 16.0
@export var edge_ray_offset_y := 20.0
@export var wall_ray_offset_x := 20.0
@export var wall_ray_offset_y := 0.0
@export var health := 1.0
@export var speed := 250.0
@export var irritable: bool = false
@export var edge_ray_active: bool = true
@export var shake_area_path: NodePath #define o alcance do shake

@export_group("Boss behavior")
@export var boss_music: AudioStream
@export var player_path: NodePath          # opcional: se nao setar, procura no grupo "player"
@export var trigger_area_path: NodePath    # Area2D que ativa o boss quando o player entra; vazio = comeca ativo
@export var brake_deceleration := 150.0    # quanto a velocidade cai por segundo ao frear
@export var chase_acceleration := 300.0    # quanto a velocidade sobe por segundo ao iniciar a perseguicao
@export var stun_duration := 3.0           # segundos atordoado apos bater na parede em alta velocidade
@export var knockback_force := 350.0       # forca do empurrao no player no 3o stomp do stun
@export var door_paths: Array[NodePath] = []  # portas que fecham ao ativar e abrem ao morrer/resetar
@export var speed_curve: Curve             # eixo x = 0 (vida cheia) -> 1 (vida zero); eixo y = multiplicador de velocidade

const MAX_STUN_HITS := 3

var state = BossState.IDLE
var active := false
var hits_taken := 0
var stun_hits := 0
var angry := false
var direction := -1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player: Node2D = null
var spawn_position: Vector2
var trigger_area: Area2D = null
var shake_area: Area2D = null
var previous_music: AudioStream

@onready var angry_speed = speed * 1.6
@onready var half_life = health / 2
@onready var max_health = health
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var edge_ray: RayCast2D = $EdgeRay
@onready var wall_ray: RayCast2D = $WallRay
@onready var hit_box: Area2D = $HitBox
@onready var reset_speed = speed


func _ready() -> void:
	spawn_position = global_position
	hit_box.monitoring = false
	_connect_trigger_area()
	if shake_area_path != NodePath():
		shake_area = get_node_or_null(shake_area_path)
	if GameEvents.has_signal("player_respawned"):
		GameEvents.player_respawned.connect(reset_boss)
		print("Boss: conectado ao GameEvents.player_respawned")
	else:
		push_warning("Boss: GameEvents nao tem o sinal 'player_respawned' - confira se voce adicionou 'signal player_respawned' no autoload")
	if trigger_area_path == NodePath():
		# sem area de trigger configurada: mantem o comportamento antigo, ja comeca ativo
		_activate()


func _connect_trigger_area() -> void:
	if trigger_area_path == NodePath():
		return
	trigger_area = get_node_or_null(trigger_area_path)
	if trigger_area and trigger_area.has_signal("body_entered"):
		trigger_area.body_entered.connect(_on_trigger_area_body_entered)


func _on_trigger_area_body_entered(body: Node) -> void:
	if active:
		return
	if body.is_in_group("player"):
		player = body
		if trigger_area:
			trigger_area.set_deferred("monitoring", false)
		_activate()


func _activate() -> void:
	active = true
	visible = true
	_set_doors_open(false)
	activated.emit()
	_find_player()
	if player:
		var start_dir: float = sign(player.global_position.x - global_position.x)
		direction = int(start_dir) if start_dir != 0 else -1
	_start_taunt()
	
	if boss_music:
		previous_music = MusicPlayer.player.stream
		MusicPlayer.play_menu_music(boss_music)


func _physics_process(delta: float) -> void:

	if state == BossState.DEAD:
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	if not active:
		velocity.x = 0
		if not is_on_floor() and not flying:
			velocity.y += gravity * delta
		move_and_slide()
		return

	_find_player()
	_update_edge_ray()
	_update_wall_ray()

	match state:
		BossState.CHASE:
			_process_chase(delta)
		BossState.BRAKING:
			_process_braking(delta)
		BossState.TAUNT, BossState.STUNNED, BossState.HIT:
			velocity.x = 0

	if not is_on_floor() and not flying:
		velocity.y += gravity * delta

	sprite.flip_h = direction > 0
	move_and_slide()
	_set_animation()

func _set_doors_open(open: bool) -> void:
	for path in door_paths:
		var door := get_node_or_null(path)
		if door == null:
			push_warning("Boss: door_path invalido ou nao encontrado: %s" % path)
			continue
		if open and door.has_method("open"):
			door.open()
		elif not open and door.has_method("close"):
			door.close()


func reset_boss() -> void:
	print("Boss: reset_boss() chamado, trigger_area = ", trigger_area)
	active = false
	state = BossState.IDLE
	angry = false
	health = max_health
	hits_taken = 0
	stun_hits = 0
	direction = -1
	velocity = Vector2.ZERO
	global_position = spawn_position
	hit_box.monitoring = false
	_set_doors_open(true)
	_reset_trigger()
	boss_reset.emit()


func _reset_trigger() -> void:
	if trigger_area:
		trigger_area.set_deferred("monitoring", true)


func _find_player() -> void:
	if player and is_instance_valid(player):
		return
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	else:
		player = get_tree().get_first_node_in_group("player")


func _get_current_speed() -> float:
	if speed_curve == null:
		return angry_speed if angry else reset_speed
	var health_ratio: float = clamp(health / max_health, 0.0, 1.0)
	var t: float = 1.0 - health_ratio  # 0 = vida cheia, 1 = vida zero
	var multiplier: float = speed_curve.sample(t)
	return reset_speed * multiplier


func _process_chase(delta: float) -> void:
	if player:
		var to_player: float = sign(player.global_position.x - global_position.x)
		# o player passou pelo boss: ele ia pra um lado e agora o alvo esta do lado oposto
		if to_player != 0 and to_player != direction:
			_start_braking()
			return

	if is_on_floor() and not edge_ray.is_colliding() and edge_ray_active:
		_turn_around()

	if flying and not is_on_floor() and not edge_ray.is_colliding() and edge_ray_active:
		_turn_around()

	if wall_ray.is_colliding():
		_start_stun()
		return

	var target_speed = _get_current_speed()
	velocity.x = move_toward(velocity.x, direction * target_speed, chase_acceleration * delta)


func _process_braking(delta: float) -> void:
	if wall_ray.is_colliding():
		_start_stun()
		return
	velocity.x = move_toward(velocity.x, 0, brake_deceleration * delta)
	if is_zero_approx(velocity.x):
		velocity.x = 0
		_start_taunt()


func _start_braking() -> void:
	state = BossState.BRAKING
	$GallopSfx.stop()
	$BrakingSfx.play()
	sprite.play("braking")


func _start_taunt() -> void:
	state = BossState.TAUNT
	if player:
		var to_player: float = sign(player.global_position.x - global_position.x)
		if to_player != 0:
			direction = int(to_player)
	_update_edge_ray()
	_update_wall_ray()
	sprite.play("taunt")


func _start_stun() -> void:
	_turn_around()
	state = BossState.STUNNED
	stun_hits = 0
	velocity.x = 0
	hit_box.monitoring = true
	$GallopSfx.stop()
	$ImpactSfx.play()
	sprite.play("stun")
	
	if _player_in_shake_range():   # NOVO
		GameEvents.boss_stun_shake.emit()
	
	await get_tree().create_timer(stun_duration).timeout
	hit_box.monitoring = false
	if state == BossState.STUNNED:
		_start_taunt()


func _update_edge_ray() -> void:
	edge_ray.target_position = Vector2(0, edge_ray_offset_y)
	edge_ray.force_raycast_update()


func _update_wall_ray() -> void:
	wall_ray.target_position = Vector2(wall_ray_offset_x * direction, wall_ray_offset_y)
	wall_ray.force_raycast_update()


func _turn_around() -> void:
	direction *= -1
	_update_edge_ray()
	_update_wall_ray()


func _set_animation() -> void:
	var anim := "idle"
	match state:
		BossState.IDLE:
			anim = "idle"
		BossState.DEAD, BossState.HIT:
			anim = "hit"
		BossState.BRAKING:
			anim = "braking"
		BossState.TAUNT:
			anim = "taunt"
		BossState.STUNNED:
			anim = "stun"
		BossState.CHASE:
			if abs(velocity.x) > 40:
				anim = "angry" if angry else "run"
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _on_animated_sprite_2d_animation_finished() -> void:
	var anim = sprite.animation
	match anim:
		"hit":
			if health <= 0:
				_spawn_die_puff()
				queue_free()
			elif stun_hits >= MAX_STUN_HITS:
				stun_hits = 0
				_start_taunt()
			else:
				state = BossState.STUNNED
				hit_box.monitoring = true
				sprite.play("stun")
		"taunt":
			$GallopSfx.play()
			$ShriekSfx.play()
			state = BossState.CHASE
			velocity.x = 0  # deixa o _process_chase acelerar suavemente a partir do zero
		# "stun" nao precisa de callback aqui: quem controla é o timer em _start_stun()


func _on_hit_box_area_entered(area: Area2D) -> void:
	print("Boss HitBox detectou: ", area.name, " (owner: ", area.get_parent().name, ")")
	if state == BossState.DEAD:
		return
	if area.name == "HurtBox":
		var p := area.get_parent()
		if p.velocity.y >= 0 and p.global_position.y < global_position.y:
			_hit(p)
		else:
			print("Boss: HurtBox entrou mas condicao de velocidade/posicao falhou. velocity.y=", p.velocity.y, " player.y=", p.global_position.y, " boss.y=", global_position.y)


func _hit(hitter) -> void:
	if state != BossState.STUNNED:
		return
	stun_hits += 1
	hits_taken += 1
	health -= 1
	health_changed.emit(health, max_health)
	if health <= half_life and irritable and not angry:
		angry = true
	velocity = Vector2.ZERO
	$HitSfx.play()
	sprite.play("hit")

	if health <= 0:
		state = BossState.DEAD
		hit_box.set_deferred("monitoring", false)
		var knock_dir: float = sign(hitter.global_position.x - global_position.x)
		if knock_dir == 0:
			knock_dir = 1
		hitter.velocity.x = knock_dir * knockback_force
		hitter.velocity.y = -400
		defeated.emit()
		_set_doors_open(true)
		if previous_music:
			MusicPlayer.play_menu_music(previous_music)
		return

	if stun_hits >= MAX_STUN_HITS:
		hit_box.set_deferred("monitoring", false)
		var knock_dir: float = sign(hitter.global_position.x - global_position.x)
		if knock_dir == 0:
			knock_dir = 1
		hitter.velocity.x = knock_dir * knockback_force
		hitter.velocity.y = -400
	else:
		hitter.velocity.y = -420

	state = BossState.HIT


func take_projectile_hit() -> void:
	if state == BossState.HIT or state == BossState.DEAD:
		return
	hits_taken += 1
	health -= 1
	state = BossState.HIT
	health_changed.emit(health, max_health)
	if health <= half_life and irritable and not angry:
		angry = true
	velocity = Vector2.ZERO
	$HitSfx.play()
	sprite.play("hit")
	if health <= 0:
		state = BossState.DEAD
		defeated.emit()
		_set_doors_open(true)

func is_stunned() -> bool:
	return state == BossState.STUNNED

func is_hitted() -> bool:
	return state == BossState.HIT

const DustPuffScene := preload("res://Prefabs/dust_puff.tscn")
const DiePuffScene := preload("res://Prefabs/die_puff.tscn")
const STEP_FRAMES := [2,8]

func _spawn_die_puff() -> void:
	var puff: Node2D = DiePuffScene.instantiate()
	get_parent().add_child(puff)
	puff.global_position = global_position + Vector2(0,-8)
	puff.scale = Vector2(3,3)

func _on_animated_sprite_2d_frame_changed() -> void:
	if sprite.animation != "angry" and sprite.animation != "run" and sprite.animation != "taunt":
		return

	if sprite.frame in STEP_FRAMES:
		_spawn_dust_puff()

func _spawn_dust_puff() -> void:
	if sprite.animation == "taunt":
		$SteamSfx.play()
	var scene: PackedScene
	if sprite.animation == "angry" or sprite.animation == "run":
		scene = DustPuffScene
		var puff: Node2D = scene.instantiate()
		get_parent().add_child(puff)
		puff.global_position = global_position + Vector2(-48 if direction > 0 else 48, -16)
		puff.flip_h = direction > 0
	elif sprite.animation == "taunt":
		scene = DustPuffScene
		var puff: Node2D = scene.instantiate()
		get_parent().add_child(puff)
		puff.global_position = global_position + Vector2(-32 if direction > 0 else 32, -16)
		puff.flip_h = direction > 0
		
	else:
		return

func _player_in_shake_range() -> bool:   # NOVO
	if shake_area == null or player == null:
		return true  # se nao configurou area, mantem comportamento antigo (sempre treme)
	return shake_area.overlaps_body(player)
