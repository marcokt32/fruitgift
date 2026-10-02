extends Area2D

## Área de vento: empurra corpos (CharacterBody2D) que entram nela.
## Anexe este script a um nó Area2D. A CollisionShape2D pode ter
## qualquer tamanho/forma — só arraste ela no campo "Collision Shape" abaixo.

signal wind_changed(active: bool)
enum WindDirection { CIMA, BAIXO, ESQUERDA, DIREITA }

##Quabtidade de particulas
@export var particle_ammount : int = 150

## Direção pra onde o vento empurra o player
@export var direction: WindDirection = WindDirection.CIMA:
	set(value):
		direction = value
		_update_particles()

## Velocidade-alvo que o vento tenta impor no eixo (px/s).
## Pra CIMA/BAIXO isso é a velocidade vertical final; pra ESQUERDA/DIREITA, a horizontal.
@export var force_amount: float = 400.0:
	set(value):
		force_amount = value
		_update_particles()

## Quão rápido a velocidade sobe até chegar no "force_amount" (px/s²).
## Quanto maior, mais rápido o vento atinge a velocidade máxima e mais difícil de resistir.
## Pra vento vertical não "cair no meio do caminho", deixe esse valor MAIOR que a
## gravidade do seu player (ex: player com gravity=1220 → use 1500+ aqui).
@export var push_acceleration: float = 900.0

## Se true, o player ainda participa da física normalmente nesse eixo (pode tentar
## andar contra o vento, e dependendo da força de cada um, consegue avançar devagar).
## Se false, o vento IGNORA totalmente o input/física do player nesse eixo e força
## a velocidade-alvo sempre — impossível de vencer.
@export var can_be_overcome: bool = true

## Se true, o vento fica sempre ativo enquanto o player estiver dentro.
## Se false, o vento alterna entre ativo/inativo usando os tempos abaixo.
@export var continuous: bool = true

## --- Usado só quando "continuous" = false ---
@export_group("Timer (liga/desliga)")
@export var active_time: float = 2.0
@export var inactive_time: float = 2.0

@export_group("Referências")
## Arraste aqui a CollisionShape2D filha desta área.
## Necessário pra poder desativar a colisão quando o vento "desliga", e também
## usada pra fazer o emission_shape das partículas bater com essa colisão.
@export var collision_shape: CollisionShape2D:
	set(value):
		collision_shape = value
		_update_particles()

## Arraste aqui o CPUParticles2D filho desta área (opcional).
## A direção e a força das partículas são ajustadas automaticamente
## pra combinar com a direção/força do vento configurada acima.
@export var particles: CPUParticles2D:
	set(value):
		particles = value
		_update_particles()

var _bodies_inside: Array[CharacterBody2D] = []
var _is_active: bool = true
var _timer: Timer


func _ready() -> void:
	wind_changed.emit(_is_active)
	$CPUParticles2D.amount = particle_ammount
	if _is_active:
		$AudioStreamPlayer2D.play()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_particles()

	if not continuous:
		_timer = Timer.new()
		add_child(_timer)
		_timer.one_shot = true
		_timer.timeout.connect(_on_timer_timeout)
		_set_active(true)
		_timer.start(active_time)


## Vetor unitário da direção do vento (útil pra partículas, setas indicativas, etc.)
func _get_wind_unit_vector() -> Vector2:
	match direction:
		WindDirection.CIMA:
			return Vector2.UP
		WindDirection.BAIXO:
			return Vector2.DOWN
		WindDirection.ESQUERDA:
			return Vector2.LEFT
		WindDirection.DIREITA:
			return Vector2.RIGHT
	return Vector2.ZERO


## Alinha as partículas com a direção/força do vento configurada, e faz a
## área de emissão bater com o formato/tamanho da CollisionShape2D.
## Chamado automaticamente sempre que "direction", "force_amount",
## "particles" ou "collision_shape" mudam (inclusive no editor, pra preview).
func _update_particles() -> void:
	if not particles:
		return
	var vec: Vector2 = _get_wind_unit_vector()
	particles.direction = vec
	particles.gravity = vec * force_amount
	# espalha um pouco as partículas em volta do eixo principal do vento
	particles.spread = 15.0
	_sync_emission_shape()


## Copia posição, rotação e forma da CollisionShape2D pro emission_shape das partículas.
func _sync_emission_shape() -> void:
	if not particles or not collision_shape or not collision_shape.shape:
		return

	# alinha a origem/rotação da emissão com a da colisão
	particles.position = collision_shape.position
	particles.rotation = collision_shape.rotation

	var shape: Shape2D = collision_shape.shape

	if shape is RectangleShape2D:
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = shape.size / 2.0

	elif shape is CircleShape2D:
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = shape.radius

	elif shape is CapsuleShape2D:
		# CPUParticles2D não tem forma de cápsula nativa; aproxima pelo
		# retângulo que envolve a cápsula (largura = raio*2, altura = height)
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(shape.radius, shape.height / 2.0)

	else:
		# fallback pra formas não mapeadas (polígono, segmento, etc.):
		# usa a caixa delimitadora (bounding box) da forma
		var rect: Rect2 = shape.get_rect()
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.position += rect.get_center()
		particles.emission_rect_extents = rect.size / 2.0


## Retorna qual eixo o vento afeta ("x" ou "y") e a velocidade-alvo nesse eixo.
func _get_target() -> Dictionary:
	match direction:
		WindDirection.CIMA:
			return {"axis": "y", "target": -force_amount}
		WindDirection.BAIXO:
			return {"axis": "y", "target": force_amount}
		WindDirection.ESQUERDA:
			return {"axis": "x", "target": -force_amount}
		WindDirection.DIREITA:
			return {"axis": "x", "target": force_amount}
	return {"axis": "y", "target": 0.0}


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_bodies_inside.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and _bodies_inside.has(body):
		_bodies_inside.erase(body)


func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	var info: Dictionary = _get_target()
	var axis: String = info["axis"]
	var target: float = info["target"]

	for body in _bodies_inside:
		if can_be_overcome:
			# aproxima a velocidade do alvo de forma constante (não exponencial),
			# então ela chega e SE MANTÉM lá, em vez de oscilar/cair
			var current: float = body.velocity.x if axis == "x" else body.velocity.y
			var new_value: float = move_toward(current, target, push_acceleration * delta)
			if axis == "x":
				body.velocity.x = new_value
			else:
				body.velocity.y = new_value
		else:
			# vento imbatível: força a velocidade-alvo direto, ignorando o player
			if axis == "x":
				body.velocity.x = target
			else:
				body.velocity.y = target


func _on_timer_timeout() -> void:
	_set_active(not _is_active)
	_timer.start(active_time if _is_active else inactive_time)


func _set_active(value: bool) -> void:
	_is_active = value
	if _is_active:
		$AudioStreamPlayer2D.play()
	else:
		$AudioStreamPlayer2D.stop()
	monitoring = value
	monitorable = value
	if collision_shape:
		collision_shape.disabled = not value
	if particles:
		particles.emitting = value
	wind_changed.emit(value)
