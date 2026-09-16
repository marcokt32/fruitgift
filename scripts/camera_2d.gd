extends Camera2D

## Configurações padrão do shake (podem ser sobrescritas ao chamar shake_camera)
@export var default_strength: float = 16.0
@export var default_duration: float = 0.4
@export var trauma_falloff: float = 1.0  # velocidade com que o trauma decai (por segundo)

var _trauma: float = 0.0
var _rng := RandomNumberGenerator.new()
var _shake_offset: Vector2 = Vector2.ZERO
var _shake_rotation: float = 0.0

@export var max_offset: Vector2 = Vector2(24, 16)
@export var max_rotation: float = 0.05  # em radianos

## Configurações da vibração do celular (Android/iOS - ignorado em outras plataformas)
@export var vibrate_enabled: bool = true
@export var vibrate_duration_ms: int = 100
@export var vibrate_amplitude: float = 0.7  # 0.0 a 1.0


func _ready() -> void:
	_rng.randomize()
	GameEvents.boss_stun_shake.connect(shake_camera)


func _process(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = max(_trauma - trauma_falloff * delta, 0.0)
		_apply_shake()
	elif _shake_offset != Vector2.ZERO or _shake_rotation != 0.0:
		# zera suavemente quando o trauma acabou
		_shake_offset = Vector2.ZERO
		_shake_rotation = 0.0
		offset = Vector2.ZERO
		rotation = 0.0


func _apply_shake() -> void:
	# trauma ao quadrado deixa o shake mais suave no início e mais forte no pico
	var amount := _trauma * _trauma

	_shake_offset = Vector2(
		max_offset.x * amount * _rng.randf_range(-1.0, 1.0),
		max_offset.y * amount * _rng.randf_range(-1.0, 1.0)
	)
	_shake_rotation = max_rotation * amount * _rng.randf_range(-1.0, 1.0)

	offset = _shake_offset
	rotation = _shake_rotation


## Função principal a ser chamada (diretamente ou conectada a um signal).
## strength: intensidade do shake (0.0 a 1.0 recomendado, mas aceita qualquer valor)
## duration: não é usada para timer, e sim para controlar o falloff automaticamente
func shake_camera(strength: float = -1.0, duration: float = -1.0) -> void:
	var final_strength := default_strength if strength < 0.0 else strength
	var final_duration := default_duration if duration < 0.0 else duration

	# ajusta o falloff para que o shake dure aproximadamente "final_duration" segundos
	if final_duration > 0.0:
		trauma_falloff = 1.0 / final_duration

	# soma trauma (limitado a 1.0) ao invés de sobrescrever,
	# assim shakes que se sobrepõem se somam naturalmente
	_trauma = clamp(_trauma + final_strength / 20.0, 0.0, 1.0)

	_vibrate(final_strength)


## Alternativa caso queira controlar o trauma diretamente (0.0 a 1.0)
func add_trauma(amount: float) -> void:
	_trauma = clamp(_trauma + amount, 0.0, 1.0)


func _vibrate(strength: float) -> void:
	if not vibrate_enabled:
		return
	var scaled_amplitude: float = clampf(vibrate_amplitude * (strength / default_strength), 0.0, 1.0)
	Input.vibrate_handheld(vibrate_duration_ms, scaled_amplitude)
