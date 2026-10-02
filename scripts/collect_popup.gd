extends CanvasLayer

signal closed

@export var auto_close_time := 5.0

@onready var icon_rect: TextureRect = %Icon
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var desc_label: Label = %Description
@onready var close_button: Button = %CloseButton
@onready var timer: Timer = $AutoCloseTimer

var _closed_emitted := false


func setup(power_data: PowerData) -> void:
	if power_data == null:
		return
	title_label.text = tr("MSG_POWER_ACQUIRED") % tr(power_data.power_name)
	subtitle_label.text = power_data.subtitle
	desc_label.text = power_data.description
	icon_rect.visible = power_data.icon != null
	if power_data.icon:
		icon_rect.texture = power_data.icon


func _ready() -> void:
	$CompleteSfx.play()
	close_button.pressed.connect(_on_close_pressed)
	timer.wait_time = auto_close_time
	timer.one_shot = true
	timer.timeout.connect(_on_timeout)
	timer.start()


func _on_close_pressed() -> void:
	_emit_closed()


func _on_timeout() -> void:
	_emit_closed()


func _emit_closed() -> void:
	if _closed_emitted:
		return
	_closed_emitted = true
	timer.stop()
	closed.emit()
	queue_free()
