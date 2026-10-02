extends Control

@export var levels: Array[LevelData] = []
@export var level_card_scene: PackedScene

const DRAG_THRESHOLD := 12.0    # pixels até virar arrasto (abaixo disso é clique)
const INERTIA_FRICTION := 4.0   # maior = para mais rápido
const MIN_VELOCITY := 30.0      # abaixo disso a inércia para

@onready var grid := %LevelsGrid
@onready var scroll: ScrollContainer = grid.get_parent() as ScrollContainer
@onready var back_button: Button = $MarginContainer/HBoxContainer2/VBoxContainer2/BackButton
@onready var fruit_label: Label = %FruitLabel
@onready var star_label: Label = %StarLabel

var _pressing := false
var _drag_moved := false          # true depois de um arrasto, até o próximo press
var _press_pos := Vector2.ZERO
var _velocity := 0.0
var _scroll_f := 0.0              # posição em float para o arrasto/inércia ficarem suaves
var _last_motion_time := 0


func _ready() -> void:
	var menu_music := preload("res://assets/Sounds/Real Mccoy.mp3")
	MusicPlayer.play_menu_music(menu_music)
	fruit_label.text = str(ProgressManager.total_fruit_score)
	star_label.text = str(ProgressManager.total_stars)

	# Desativa o drag nativo do ScrollContainer (evita rolagem dobrada);
	# quem controla o arrasto agora é o _input abaixo. (Godot 4.3+)
	scroll.scroll_deadzone = 100000

	_validate_level_indices()
	_populate_grid()


func _validate_level_indices() -> void:
	var seen_indices: Dictionary = {}
	for data in levels:
		if data == null:
			push_error("LevelSelect: um item do array 'levels' está vazio (null)")
			continue
		if seen_indices.has(data.level_index):
			push_error("LevelSelect: level_index %d duplicado! Usado em '%s' e '%s'" % [
				data.level_index, seen_indices[data.level_index], data.level_name
			])
		seen_indices[data.level_index] = data.level_name


func _populate_grid() -> void:
	for data in levels:
		if data == null:
			continue
		var card := level_card_scene.instantiate()
		grid.add_child(card)
		card.setup(data, data.level_index)
		# O card consulta isso antes de abrir o level
		card.drag_check = func() -> bool: return _drag_moved
		# Teclado/gamepad: rola até o card focado
		card.focus_entered.connect(func(): scroll.ensure_control_visible(card))


# ---------------------------------------------------------------- DRAG

# Trata só eventos de mouse: no mobile o toque já é convertido em mouse
# (Emulate Mouse From Touch, ligado por padrão), então não duplica o movimento.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if scroll.get_global_rect().has_point(event.position):
				_pressing = true
				_drag_moved = false
				_velocity = 0.0
				_press_pos = event.position
				_scroll_f = float(scroll.scroll_horizontal)
				_last_motion_time = Time.get_ticks_msec()
		else:
			_pressing = false
			# Se parou de mexer antes de soltar, não aplica inércia
			if Time.get_ticks_msec() - _last_motion_time > 80:
				_velocity = 0.0

	elif event is InputEventMouseMotion and _pressing:
		if not _drag_moved:
			if absf(event.position.x - _press_pos.x) < DRAG_THRESHOLD:
				return
			_drag_moved = true

		_scroll_by(-event.relative.x)

		var now := Time.get_ticks_msec()
		var dt: float = maxf((now - _last_motion_time) / 1000.0, 0.001)
		_last_motion_time = now
		_velocity = lerpf(_velocity, -event.relative.x / dt, 0.4)


func _process(delta: float) -> void:
	# Inércia depois de soltar
	if _pressing or absf(_velocity) < MIN_VELOCITY:
		return
	_scroll_by(_velocity * delta)
	_velocity = move_toward(_velocity, 0.0, absf(_velocity) * INERTIA_FRICTION * delta + 1.0)


func _scroll_by(amount: float) -> void:
	var h_bar := scroll.get_h_scroll_bar()
	var max_scroll: float = maxf(h_bar.max_value - h_bar.page, 0.0)
	_scroll_f = clampf(_scroll_f + amount, 0.0, max_scroll)
	scroll.scroll_horizontal = int(_scroll_f)
	# Bateu na borda: zera a inércia
	if _scroll_f <= 0.0 or _scroll_f >= max_scroll:
		_velocity = 0.0


# ---------------------------------------------------------------- BOTÕES

func _on_back_button_pressed() -> void:
	$SelectSfx.play()
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://Prefabs/slot_select.tscn")


func _on_testes_pressed() -> void:
	$SelectSfx.play()
	MusicPlayer.stop_music(0.5)
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://Levels/test_level.tscn")
