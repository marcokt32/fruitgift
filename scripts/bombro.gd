extends CharacterBody2D

# ================== MOVIMENTO (desligado por padrão) ==================
@export var move_enabled := false
@export var speed := 40.0
@export var use_gravity := true
@export var edge_ray_offset_x := 12.0
@export var edge_ray_offset_y := 20.0
@export var wall_ray_offset_x := 12.0
@export var wall_ray_offset_y := 0.0

# ================== EXPLOSÃO ==================
@export var fuse_time := 1.5                 # tempo entre ativar e explodir
@export var damage_method := "take_damage"  # método chamado no player (ajuste pro nome do seu)
@export var explosion_scene: PackedScene     # efeito visual/sonoro extra (opcional)

# ================== ANIMAÇÕES ==================
@export var idle_anim := "idle"
@export var explode_anim := "explode"        # toca quando começa a piscar

# ================== PISCAR ==================
@export var blink_color := Color(1.0, 0.3, 0.3)
@export var blink_freq_start := 3.0          # piscadas por segundo no começo do pavio
@export var blink_freq_end := 12.0           # piscadas por segundo perto de explodir

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction := -1
var armed := false
var fuse_left := 0.0

var _exploded := false
var _blink_phase := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_detector: Area2D = $PlayerDetector
@onready var explosion_area: Area2D = $ExplosionArea
# opcionais: só são usados se existirem na cena
@onready var edge_ray := get_node_or_null("EdgeRay") as RayCast2D
@onready var wall_ray := get_node_or_null("WallRay") as RayCast2D
@onready var fuse_sfx := get_node_or_null("FuseSfx") as AudioStreamPlayer2D


func _ready() -> void:
	# Conexão por código (não precisa conectar no editor)
	player_detector.body_entered.connect(_on_player_detector_body_entered)
	sprite.play(idle_anim)


func _physics_process(delta: float) -> void:
	if armed:
		_process_fuse(delta)
		if _exploded:
			return

	if use_gravity and not is_on_floor():
		velocity.y += gravity * delta

	if move_enabled and not armed:
		_process_movement()
	else:
		velocity.x = 0.0

	move_and_slide()


# ================== MOVIMENTO ==================
func _process_movement() -> void:
	if edge_ray:
		edge_ray.position.x = edge_ray_offset_x * direction
		edge_ray.target_position = Vector2(0, edge_ray_offset_y)
		edge_ray.force_raycast_update()
	if wall_ray:
		wall_ray.position = Vector2.ZERO
		wall_ray.target_position = Vector2(wall_ray_offset_x * direction, wall_ray_offset_y)
		wall_ray.force_raycast_update()

	if is_on_floor() and edge_ray and not edge_ray.is_colliding():
		direction *= -1
	elif wall_ray and wall_ray.is_colliding():
		direction *= -1

	velocity.x = direction * speed
	sprite.flip_h = direction > 0


# ================== ATIVAÇÃO ==================
func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_arm()


func _arm() -> void:
	if armed:
		return
	$SearSfx.play()
	armed = true
	fuse_left = maxf(fuse_time, 0.01)
	velocity.x = 0.0

	# Começa a piscar e a animar "explode" ao mesmo tempo
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(explode_anim):
		sprite.play(explode_anim)
	if fuse_sfx:
		fuse_sfx.play()


# ================== PAVIO / PISCAR ==================
func _process_fuse(delta: float) -> void:
	fuse_left -= delta
	# Pisca cada vez mais rápido conforme o pavio acaba
	var progress := 1.0 - clampf(fuse_left / maxf(fuse_time, 0.01), 0.0, 1.0)
	var freq := lerpf(blink_freq_start, blink_freq_end, progress)
	_blink_phase += freq * TAU * delta
	var t := (sin(_blink_phase) + 1.0) * 0.5
	sprite.modulate = Color.WHITE.lerp(blink_color, t)

	if fuse_left <= 0.0:
		_explode()


# ================== EXPLOSÃO ==================
func _explode() -> void:
	if _exploded:
		return
	_exploded = true

	# Dano em área: tudo que estiver dentro do ExplosionArea nesse momento.
	# O take_damage do player espera a ORIGEM do dano (um nó), então passamos "self".
	for body in explosion_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method(damage_method):
			body.call(damage_method, self)

	if explosion_scene:
		var fx: Node2D = explosion_scene.instantiate()
		get_parent().add_child(fx)
		fx.global_position = global_position

	queue_free()   # a bomba só some


# Se um projétil do player acertar a bomba, ela é ativada
func take_projectile_hit() -> void:
	_arm()
