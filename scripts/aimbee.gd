extends CharacterBody2D

# ================== PATRULHA ==================
enum PatrolPattern { CIRCLE, FIGURE_EIGHT }

@export var patrol_pattern: PatrolPattern = PatrolPattern.CIRCLE
@export var patrol_radius_x := 60.0        # largura da rota
@export var patrol_radius_y := 30.0        # altura da rota (== radius_x => círculo perfeito)
@export var patrol_angular_speed := 1.2    # rad/s (quanto maior, mais rápido ela dá a volta)
@export var clockwise := true
@export var max_speed := 140.0             # limite de velocidade pra seguir a rota

# ================== ATAQUE ==================
@export var stinger_scene: PackedScene     # cena do projétil (ferrão)
@export var attack_cooldown := 2.0
@export var shoot_range := 160.0
@export var shoot_frame := 2               # frame da animação "shoot" em que o ferrão sai
@export var stinger_art_direction := Vector2.RIGHT  # pra onde a PONTA do triângulo aponta na arte (RIGHT, LEFT, UP, DOWN)

# ================== ANIMAÇÕES ==================
@export var fly_anim := "idle"             # troque para "fly" quando criar essa animação
@export var hit_anim := "hit"
@export var shoot_anim := "shoot"
@export var wing_shoot_anim := "shoot"     # animação do sprite da asa
@export var art_faces_right := false       # true se a arte original olha pra direita

# ================== VIDA ==================
@export var health := 1.0
@export var dead_fall_speed := 200.0

enum BeeState { PATROL, ATTACK, HIT, DEAD }

var state: BeeState = BeeState.PATROL
var can_attack := true
var facing_right := false
var player_ref: Node2D = null

var _phase := 0.0
var _center := Vector2.ZERO
var _shot_fired := false
var _wing_base_x := 0.0
var _stinger_base_x := 0.0

@onready var body: AnimatedSprite2D = %BodySprite
@onready var wing: AnimatedSprite2D = %WingSprite
@onready var stinger_point: Marker2D = %StingerPoint
@onready var attack_timer: Timer = $AttackCooldown
@onready var player_detector: Area2D = $PlayerDetector
@onready var hit_box: Area2D = $HitBox
@onready var hit_sfx: AudioStreamPlayer2D = $HitSfx

const DiePuffScene := preload("res://Prefabs/die_puff.tscn")


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	# Guarda a posição X original (como foi desenhada na cena) pra espelhar ao virar
	_wing_base_x = wing.position.x
	_stinger_base_x = stinger_point.position.x

	# O ponto onde a abelha foi colocada no editor vira o começo da rota
	_center = global_position - _path_offset(0.0)

	attack_timer.one_shot = true
	wing.visible = false

	# Conexões feitas por código (não precisa conectar no editor)
	attack_timer.timeout.connect(_on_attack_cooldown_timeout)
	player_detector.body_entered.connect(_on_player_detector_body_entered)
	player_detector.body_exited.connect(_on_player_detector_body_exited)
	hit_box.area_entered.connect(_on_hit_box_area_entered)
	body.animation_finished.connect(_on_body_animation_finished)
	body.frame_changed.connect(_on_body_frame_changed)

	_apply_facing(facing_right)


func _physics_process(delta: float) -> void:
	_set_animation()

	match state:
		BeeState.PATROL:
			_process_patrol(delta)
			if can_attack and player_ref:
				_start_attack()
		BeeState.ATTACK, BeeState.HIT:
			velocity = Vector2.ZERO   # paira no ar
		BeeState.DEAD:
			velocity = Vector2(0, dead_fall_speed)

	move_and_slide()


# ================== PATRULHA ==================
func _process_patrol(delta: float) -> void:
	_phase += patrol_angular_speed * delta * (1.0 if clockwise else -1.0)
	var target := _center + _path_offset(_phase)

	# Vai em direção ao ponto da rota (respeita colisão porque usa velocity)
	velocity = ((target - global_position) / delta).limit_length(max_speed)

	if absf(velocity.x) > 1.0:
		var going_right := velocity.x > 0.0
		if going_right != facing_right:
			_apply_facing(going_right)


func _path_offset(t: float) -> Vector2:
	match patrol_pattern:
		PatrolPattern.FIGURE_EIGHT:
			# "8 deitado" (lemniscata): x oscila 1x, y oscila 2x
			return Vector2(sin(t) * patrol_radius_x, sin(t * 2.0) * patrol_radius_y)
		_:
			return Vector2(cos(t) * patrol_radius_x, sin(t) * patrol_radius_y)


# ================== DIREÇÃO / FLIP ==================
func _apply_facing(face_right: bool) -> void:
	facing_right = face_right
	var flip := face_right != art_faces_right
	body.flip_h = flip
	wing.flip_h = flip

	# Espelha o offset X da asa e do ponto do ferrão
	var m := -1.0 if flip else 1.0
	wing.position.x = _wing_base_x * m
	stinger_point.position.x = _stinger_base_x * m


# ================== ANIMAÇÃO ==================
func _set_animation() -> void:
	var anim := fly_anim
	match state:
		BeeState.DEAD, BeeState.HIT:
			anim = hit_anim
		BeeState.ATTACK:
			anim = shoot_anim
		BeeState.PATROL:
			anim = fly_anim

	if body.animation != anim:
		body.play(anim)

	# A asa só aparece durante o "shoot" (quem inicia a animação dela é o _start_attack)
	var show_wing := state == BeeState.ATTACK
	if wing.visible and not show_wing:
		wing.stop()
	wing.visible = show_wing


# ================== DETECÇÃO DO PLAYER ==================
func _on_player_detector_body_entered(b: Node2D) -> void:
	if b.is_in_group("player"):
		player_ref = b


func _on_player_detector_body_exited(b: Node2D) -> void:
	if b == player_ref:
		player_ref = null


# ================== ATAQUE (FERRÃO) ==================
func _start_attack() -> void:
	if not stinger_scene or not is_instance_valid(player_ref):
		return
	if stinger_point.global_position.distance_to(player_ref.global_position) > shoot_range:
		return   # fora de alcance, nem entra em ATTACK

	can_attack = false
	_shot_fired = false
	state = BeeState.ATTACK
	_apply_facing(player_ref.global_position.x > global_position.x)

	# Corpo e asa começam o "shoot" juntos, sempre do frame 0
	_restart_anim(body, shoot_anim)
	wing.visible = true
	_restart_anim(wing, wing_shoot_anim)


func _restart_anim(sprite: AnimatedSprite2D, anim: StringName) -> void:
	# Reinicia mesmo se a animação já for a atual (ex.: "shoot" definida como padrão no editor)
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation(anim):
		return
	sprite.stop()
	sprite.animation = anim
	sprite.frame = 0
	sprite.frame_progress = 0.0
	sprite.play(anim)


func _on_body_frame_changed() -> void:
	# Dispara o ferrão no frame certo da animação
	if state == BeeState.ATTACK and body.animation == shoot_anim \
			and body.frame == shoot_frame and not _shot_fired:
		_fire_stinger()


func _fire_stinger() -> void:
	_shot_fired = true
	if not stinger_scene:
		return

	var dir := Vector2.RIGHT if facing_right else Vector2.LEFT
	if is_instance_valid(player_ref):
		dir = stinger_point.global_position.direction_to(player_ref.global_position)

	var stinger: Node2D = stinger_scene.instantiate()
	get_parent().add_child(stinger)
	stinger.global_position = stinger_point.global_position
	# Gira o ferrão pra ponta do triângulo apontar na direção do tiro
	stinger.rotation = dir.angle() - stinger_art_direction.angle()
	if stinger.has_method("launch"):
		stinger.launch(dir)


func _on_attack_cooldown_timeout() -> void:
	can_attack = true


# ================== DANO NA ABELHA ==================
func take_hit(amount, player) -> void:
	if state == BeeState.DEAD or state == BeeState.HIT:
		return

	if player:
		player.velocity.y = -420

	# Interrompe qualquer ataque em andamento e reinicia o cooldown
	_shot_fired = true
	can_attack = false
	attack_timer.start(attack_cooldown)

	health -= amount
	state = BeeState.DEAD if health <= 0 else BeeState.HIT
	hit_sfx.play()


func take_projectile_hit() -> void:
	take_hit(1, null)


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "HurtBox":
		var player := area.get_parent()
		if player.velocity.y >= 0 and player.global_position.y < global_position.y:
			take_hit(1, player)


# ================== FIM DE ANIMAÇÃO ==================
func _on_body_animation_finished() -> void:
	match body.animation:
		shoot_anim:
			if state == BeeState.ATTACK:
				if not _shot_fired:
					_fire_stinger()   # garantia caso shoot_frame não tenha sido alcançado
				state = BeeState.PATROL
				attack_timer.start(attack_cooldown)
		hit_anim:
			if state == BeeState.DEAD:
				_spawn_die_puff()
				queue_free()
			elif state == BeeState.HIT:
				state = BeeState.PATROL


func _spawn_die_puff() -> void:
	var puff: Node2D = DiePuffScene.instantiate()
	get_parent().add_child(puff)
	puff.global_position = global_position
	puff.flip_h = facing_right != art_faces_right
