extends StaticBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $Area2D
@onready var collision: CollisionShape2D = $CollisionShape2D

@export var golden_apple_scene: PackedScene
@export var apple_spawn_point: Marker2D
@export var power_data_for_this_chest: PowerData
@export var level_data: LevelData
@export var collect_popup_scene: PackedScene

var is_open: bool = false
var locked_player: Node2D = null


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	animated_sprite.play("closed")


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or is_open:
		return

	is_open = true
	locked_player = body
	open_chest()


func open_chest() -> void:
	if locked_player and locked_player.has_method("lock_input"):
		locked_player.lock_input()

	animated_sprite.play("open")
	await animated_sprite.animation_finished
	spawn_golden_apple()


func spawn_golden_apple() -> void:
	if golden_apple_scene == null:
		push_warning("Chest: golden_apple_scene não foi atribuído no Inspector")
		return
	if apple_spawn_point == null:
		push_warning("Chest: apple_spawn_point não foi atribuído no Inspector")
		return

	var apple = golden_apple_scene.instantiate()
	get_parent().add_child(apple)
	apple.global_position = apple_spawn_point.global_position

	apple.level_data = level_data
	apple.power_data = power_data_for_this_chest
	apple.collect_popup_scene = collect_popup_scene

	apple.collect(locked_player)
