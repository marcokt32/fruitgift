extends Node2D

@export var trigger_area_path: NodePath
@export var move_speed = 1
@export var gear_visible = true
@export_enum("Padrão:0", "Block:1") var gate_skin: int = 0

@onready var default_skin = $Body/Node2D
@onready var block_skin = $Body/TextureRect
@onready var animation : AnimationPlayer = $Body/AnimationPlayer
@onready var gear := $Gear

var trigger_area: Area2D

func _ready() -> void:
	if gate_skin == 0:
		default_skin.set_deferred("visible",true)
		block_skin.set_deferred("visible",false)
		
	if gate_skin == 01:
		default_skin.set_deferred("visible",false)
		block_skin.set_deferred("visible",true)
	
	if !gear_visible:
		gear.set_deferred("visible", gear_visible)
		

	trigger_area = get_node_or_null(trigger_area_path)
	if trigger_area == null:
		push_error("FallingPlatform: Trigger Area Path não configurado no Inspector!")
		return

	trigger_area.body_entered.connect(_on_trigger_area_body_entered)

func _on_trigger_area_body_entered(body):
	animation.speed_scale = move_speed
	if animation.assigned_animation == "up":
		animation.play("set_down")
	elif animation.assigned_animation == "down":
		animation.play("set_up")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "set_down":
		animation.play("down")
	if anim_name == "set_up":
		animation.play("up")
