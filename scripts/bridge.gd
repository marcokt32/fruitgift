extends AnimatableBody2D

@export var trigger_area_path: NodePath

@onready var animation : AnimationPlayer = $AnimationPlayer

var trigger_area: Area2D

func _ready() -> void:

	trigger_area = get_node_or_null(trigger_area_path)
	if trigger_area == null:
		push_error("FallingPlatform: Trigger Area Path não configurado no Inspector!")
		return

	trigger_area.body_entered.connect(_on_trigger_area_body_entered)

func _on_trigger_area_body_entered(body):
	if animation.assigned_animation == "up":
		animation.play("set_down")
	elif animation.assigned_animation == "down":
		animation.play("set_up")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "set_down":
		animation.play("down")
	if anim_name == "set_up":
		animation.play("up")
